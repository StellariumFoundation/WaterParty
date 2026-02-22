package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	"github.com/jackc/pgx/v5"
)

const (
	writeWait      = 10 * time.Second
	pongWait       = 60 * time.Second
	pingPeriod     = (pongWait * 9) / 10
	maxMessageSize = 4096 // Adjust based on your average ChatMessage size
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  2048,
	WriteBufferSize: 2048,
	CheckOrigin:     func(r *http.Request) bool { return true },
}

// Hub maintains the set of active clients and broadcasts messages to rooms.
type Hub struct {
	// Registered clients mapped by UserID
	clients map[string]*Client

	// Room mapping: RoomID -> Set of Clients in that room
	rooms map[string]map[*Client]bool

	// Inbound messages from the clients.
	broadcast       chan RoomEvent
	globalBroadcast chan []byte

	register   chan *Client
	unregister chan *Client
	
	mu sync.RWMutex
}

// RoomEvent wraps a message with its target room
type RoomEvent struct {
	RoomID  string
	Message []byte
}

func NewHub() *Hub {
	return &Hub{
		broadcast:       make(chan RoomEvent, 1024),
		globalBroadcast: make(chan []byte, 1024),
		register:        make(chan *Client),
		unregister:      make(chan *Client),
		clients:         make(map[string]*Client),
		rooms:           make(map[string]map[*Client]bool),
	}
}

func (h *Hub) broadcastGlobal(msg []byte) {
	h.globalBroadcast <- msg
}

func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			h.clients[client.UID] = client
			h.mu.Unlock()

		case client := <-h.unregister:
			h.mu.Lock()
			if _, ok := h.clients[client.UID]; ok {
				delete(h.clients, client.UID)
				// Remove client from all rooms they were in
				for roomID := range h.rooms {
					delete(h.rooms[roomID], client)
				}
				close(client.send)
			}
			h.mu.Unlock()

		case msg := <-h.globalBroadcast:
			h.mu.RLock()
			for _, client := range h.clients {
				select {
				case client.send <- msg:
				default:
					go func(c *Client) { h.unregister <- c }(client)
				}
			}
			h.mu.RUnlock()

		case ev := <-h.broadcast:
			h.mu.RLock()
			// Ultra-efficient routing: only iterate over clients in the specific room
			if clients, ok := h.rooms[ev.RoomID]; ok {
				for client := range clients {
					select {
					case client.send <- ev.Message:
					default:
						// If client buffer is full, drop them to prevent hub lag
						go func(c *Client) { h.unregister <- c }(client)
					}
				}
			}
			h.mu.RUnlock()
		}
	}
}

// JoinRoom adds a client to a specific room map
func (h *Hub) JoinRoom(roomID string, client *Client) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if h.rooms[roomID] == nil {
		h.rooms[roomID] = make(map[*Client]bool)
	}
	h.rooms[roomID][client] = true
}

type Client struct {
	hub  *Hub
	conn *websocket.Conn
	send chan []byte // Buffered channel for outbound messages
	UID  string
}

func (c *Client) readPump() {
	defer func() {
		c.hub.unregister <- c
		c.conn.Close()
	}()

	c.conn.SetReadLimit(maxMessageSize)
	c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error { 
		c.conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil 
	})

	for {
		_, message, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("error: %v", err)
			}
			break
		}

		// Handle the message efficiently
		c.handleIncomingMessage(message)
	}
}

func (c *Client) handleIncomingMessage(raw []byte) {
	var wsMsg WSMessage
	if err := json.Unmarshal(raw, &wsMsg); err != nil {
		return
	}

	switch wsMsg.Event {
	case "JOIN_ROOM":
		// Payload: {"RoomID": "uuid"}
		roomID, _ := wsMsg.Payload.(map[string]interface{})["RoomID"].(string)
		if roomID != "" {
			c.hub.JoinRoom(roomID, c)
		}

	case "SEND_MESSAGE":
		// 1. Convert payload to ChatMessage struct
		payloadBytes, _ := json.Marshal(wsMsg.Payload)
		var chatMsg ChatMessage
		json.Unmarshal(payloadBytes, &chatMsg)
		
		chatMsg.SenderID = c.UID
		chatMsg.CreatedAt = time.Now()

		// 2. Save to Postgres (database.go) asynchronously to not block WS
		go func(m ChatMessage) {
			_, err := SaveMessage(m)
			if err != nil {
				log.Printf("DB Save Error: %v", err)
			}
		}(chatMsg)

		// 3. Broadcast to Room
		outgoing, _ := json.Marshal(WSMessage{
			Event:   "NEW_MESSAGE",
			Payload: chatMsg,
		})
		c.hub.broadcast <- RoomEvent{RoomID: chatMsg.ChatID, Message: outgoing}

	case "SEND_DM":
		// Payload: {"RecipientID": "uuid", "Content": "text"}
		var dmReq struct {
			RecipientID string `json:"RecipientID"`
			Content     string `json:"Content"`
		}
		payloadBytes, _ := json.Marshal(wsMsg.Payload)
		json.Unmarshal(payloadBytes, &dmReq)

		// Create a synthetic ChatID for the DM (deterministic pair-wise ID)
		u1, u2 := c.UID, dmReq.RecipientID
		if u1 > u2 {
			u1, u2 = u2, u1
		}
		dmChatID := u1 + "_" + u2

		msg := ChatMessage{
			ChatID:    dmChatID,
			SenderID:  c.UID,
			Content:   dmReq.Content,
			Type:      MsgText,
			CreatedAt: time.Now(),
		}

		// 1. Save to DB
		SaveMessage(msg)

		// 2. Broadcast to Recipient and Sender (Private)
		outgoingDM, _ := json.Marshal(WSMessage{
			Event:   "NEW_MESSAGE",
			Payload: msg,
		})
		
		c.hub.mu.RLock()
		if recipient, ok := c.hub.clients[dmReq.RecipientID]; ok {
			recipient.send <- outgoingDM
		}
		c.send <- outgoingDM // Send back to self for sync
		c.hub.mu.RUnlock()

	case "CREATE_PARTY":
		payloadBytes, _ := json.Marshal(wsMsg.Payload)
		var p Party
		json.Unmarshal(payloadBytes, &p)
		
		p.HostID = c.UID
		now := time.Now()
		p.CreatedAt = &now
		p.UpdatedAt = &now

		// Auto-extrapolate address/city from coordinates if using "My Location"
		if p.GeoLat != 0 && p.GeoLon != 0 && (p.Address == "MY CURRENT LOCATION" || p.City == "DETECTED ON PUBLISH") {
			addr, city, err := ReverseGeocode(p.GeoLat, p.GeoLon)
			if err == nil {
				if p.Address == "MY CURRENT LOCATION" {
					p.Address = addr
				}
				if p.City == "DETECTED ON PUBLISH" {
					p.City = city
				}
			}
		}

		id, err := CreateParty(p)
		if err != nil {
			log.Printf("Create Party DB Error: %v", err)
			// Send error feedback to client
			errorMsg, _ := json.Marshal(WSMessage{
				Event: "ERROR",
				Payload: map[string]string{
					"message": "Failed to create party: " + err.Error(),
				},
			})
			c.send <- errorMsg
			return
		}
		p.ID = id

		// Send confirmation back to creator
		confirmationMsg, _ := json.Marshal(WSMessage{
			Event:   "PARTY_CREATED",
			Payload: p,
		})
		c.send <- confirmationMsg

		// Also send the new ChatRoom to the creator immediately
		newRoom, err := GetChatRoom(p.ChatRoomID)
		if err == nil {
			newRoomMsg, _ := json.Marshal(WSMessage{
				Event:   "NEW_CHAT_ROOM",
				Payload: newRoom,
			})
			c.send <- newRoomMsg
		}

		broadcastMsg, _ := json.Marshal(WSMessage{
			Event:   "NEW_PARTY",
			Payload: p,
		})
		c.hub.broadcastGlobal(broadcastMsg)

	case "GET_CHATS":
		rooms, err := GetChatRoomsForUser(c.UID)
		if err != nil {
			log.Printf("Get Chats DB Error: %v", err)
			return
		}
		response, _ := json.Marshal(WSMessage{
			Event:   "CHATS_LIST",
			Payload: rooms,
		})
		c.send <- response

	case "UPDATE_PROFILE":
		payloadBytes, _ := json.Marshal(wsMsg.Payload)
		var u User
		json.Unmarshal(payloadBytes, &u)
		
		// Ensure the user is updating their own profile
		u.ID = c.UID

		err := UpdateUserFull(u)
		if err != nil {
			log.Printf("Update Profile DB Error: %v", err)
			return
		}

		// Optional: broadcast update or send confirmation back to client
		response, _ := json.Marshal(WSMessage{
			Event:   "PROFILE_UPDATED",
			Payload: u,
		})
		c.send <- response

	case "GET_USER":
		u, err := GetUser(c.UID)
		if err != nil {
			log.Printf("Get User DB Error: %v", err)
			return
		}
		response, _ := json.Marshal(WSMessage{
			Event:   "PROFILE_UPDATED",
			Payload: u,
		})
		c.send <- response

	case "SWIPE":
		// Payload: {"PartyID": "uuid", "Direction": "right/left"}
		var swipe struct {
			PartyID   string `json:"PartyID"`
			Direction string `json:"Direction"`
		}
		payloadBytes, _ := json.Marshal(wsMsg.Payload)
		json.Unmarshal(payloadBytes, &swipe)

		status := "PENDING"
		if swipe.Direction == "left" {
			status = "DECLINED"
		}

		// Save swipe to party_applications table
		query := `INSERT INTO party_applications (party_id, user_id, status) 
				  VALUES ($1, $2, $3) ON CONFLICT (party_id, user_id) 
				  DO UPDATE SET status = $3`
		_, err := db.Exec(context.Background(), query, swipe.PartyID, c.UID, status)
		if err != nil {
			log.Printf("Swipe Save Error: %v", err)
		}

	case "GET_FEED":
		// Payload: {"Lat": 0.0, "Lon": 0.0, "RadiusKm": 50}
		var loc struct {
			Lat      float64 `json:"Lat"`
			Lon      float64 `json:"Lon"`
			RadiusKm float64 `json:"RadiusKm"`
		}
		payloadBytes, _ := json.Marshal(wsMsg.Payload)
		json.Unmarshal(payloadBytes, &loc)

		if loc.RadiusKm <= 0 {
			loc.RadiusKm = 50.0
		}

		// Simple bounding box calculation
		// 1 degree lat ~= 111km
		latDelta := loc.RadiusKm / 111.0
		// 1 degree lon ~= 111km * cos(lat)
		lonDelta := loc.RadiusKm / (111.0 * 0.7) // Roughly estimate for mid-latitudes

		query := `
			SELECT id, host_id, title, description, party_photos, start_time, end_time, status, 
			       is_location_revealed, address, city, geo_lat, geo_lon, max_capacity, 
			       current_guest_count, vibe_tags, rules, chat_room_id, created_at
			FROM parties 
			WHERE status = 'OPEN' 
			  AND host_id != $1
			  AND id NOT IN (SELECT party_id FROM party_applications WHERE user_id = $1)
		`
		
		var rows pgx.Rows
		var err error
		
		if loc.Lat != 0 || loc.Lon != 0 {
			query += ` AND geo_lat BETWEEN $2 AND $3 AND geo_lon BETWEEN $4 AND $5`
			query += ` ORDER BY created_at DESC LIMIT 50`
			rows, err = db.Query(context.Background(), query, 
				c.UID, 
				loc.Lat-latDelta, loc.Lat+latDelta, 
				loc.Lon-lonDelta, loc.Lon+lonDelta)
		} else {
			query += ` ORDER BY created_at DESC LIMIT 50`
			rows, err = db.Query(context.Background(), query, c.UID)
		}

		if err != nil {
			log.Printf("Feed Query Error: %v", err)
			return
		}
		defer rows.Close()

		var parties []Party
		for rows.Next() {
			var p Party
			err := rows.Scan(
				&p.ID, &p.HostID, &p.Title, &p.Description, &p.PartyPhotos, &p.StartTime, &p.EndTime,
				&p.Status, &p.IsLocationRevealed, &p.Address, &p.City, &p.GeoLat, &p.GeoLon,
				&p.MaxCapacity, &p.CurrentGuestCount, &p.VibeTags, &p.Rules, &p.ChatRoomID, &p.CreatedAt,
			)
			if err != nil {
				log.Printf("Feed Scan Error: %v", err)
				continue
			}
			parties = append(parties, p)
		}

		response, _ := json.Marshal(WSMessage{
			Event:   "FEED_UPDATE",
			Payload: parties,
		})
		c.send <- response

	case "GET_APPLICANTS":
		// Payload: {"PartyID": "uuid"}
		partyID, _ := wsMsg.Payload.(map[string]interface{})["PartyID"].(string)
		if partyID == "" {
			return
		}

		apps, err := GetApplicantsForParty(partyID)
		if err != nil {
			log.Printf("Get Applicants DB Error: %v", err)
			return
		}

		response, _ := json.Marshal(WSMessage{
			Event:   "APPLICANTS_LIST",
			Payload: map[string]interface{}{
				"PartyID":    partyID,
				"Applicants": apps,
			},
		})
		c.send <- response

	case "UPDATE_APPLICATION":
		// Payload: {"PartyID": "uuid", "UserID": "uuid", "Status": "ACCEPTED/DECLINED"}
		var req struct {
			PartyID string `json:"PartyID"`
			UserID  string `json:"UserID"`
			Status  string `json:"Status"`
		}
		payloadBytes, _ := json.Marshal(wsMsg.Payload)
		json.Unmarshal(payloadBytes, &req)

		err := UpdateApplicationStatus(req.PartyID, req.UserID, req.Status)
		if err != nil {
			log.Printf("Update Application DB Error: %v", err)
			return
		}

		// Broadcast update to the host (self) and maybe the user?
		// For now just notify host success
		response, _ := json.Marshal(WSMessage{
			Event:   "APPLICATION_UPDATED",
			Payload: req,
		})
		c.send <- response
	
	case "ADD_CONTRIBUTION":
		// Handle financial updates, save to DB, broadcast pool update to room
		// ... logic for AddContribution ...
	}
}

func (c *Client) writePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			w, err := c.conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			w.Write(message)

			// Add queued chat messages to the current websocket message to reduce overhead
			n := len(c.send)
			for i := 0; i < n; i++ {
				w.Write([]byte{'\n'})
				w.Write(<-c.send)
			}

			if err := w.Close(); err != nil {
				return
			}
		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

// ServeWs handles websocket requests from the peer.
func ServeWs(hub *Hub, w http.ResponseWriter, r *http.Request) {
	// Extract UID from context or query parameter
	uid, ok := r.Context().Value("uid").(string)
	if !ok || uid == "" {
		// Fallback to query parameter for non-firebase auth
		uid = r.URL.Query().Get("uid")
	}

	if uid == "" {
		// For now, allow anonymous or handle as needed for Render deployment
		uid = "anonymous_" + time.Now().Format("150405")
	}

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println(err)
		return
	}

	client := &Client{
		hub:  hub,
		conn: conn,
		send: make(chan []byte, 256), // Buffered to handle spikes
		UID:  uid,
	}
	client.hub.register <- client

	// Start goroutines for high-performance concurrent I/O
	go client.writePump()
	go client.readPump()
}

// ReverseGeocode uses Nominatim (OpenStreetMap) to convert coordinates to an address and city.
func ReverseGeocode(lat, lon float64) (string, string, error) {
	url := fmt.Sprintf("https://nominatim.openstreetmap.org/reverse?format=json&lat=%f&lon=%f", lat, lon)
	
	client := &http.Client{Timeout: 5 * time.Second}
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Set("User-Agent", "WaterParty-App") // Required by Nominatim policy

	resp, err := client.Do(req)
	if err != nil {
		return "", "", err
	}
	defer resp.Body.Close()

	var result struct {
		DisplayName string `json:"display_name"`
		Address     struct {
			City    string `json:"city"`
			Town    string `json:"town"`
			Village string `json:"village"`
			Suburb  string `json:"suburb"`
		} `json:"address"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", "", err
	}

	city := result.Address.City
	if city == "" {
		city = result.Address.Town
	}
	if city == "" {
		city = result.Address.Village
	}
	if city == "" {
		city = result.Address.Suburb
	}

	return result.DisplayName, city, nil
}

