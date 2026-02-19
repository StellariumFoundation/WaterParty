package main

import (
	"encoding/json"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/gorilla/websocket"
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
	broadcast chan RoomEvent

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
		broadcast:  make(chan RoomEvent, 1024), // Large buffer for high throughput
		register:   make(chan *Client),
		unregister: make(chan *Client),
		clients:    make(map[string]*Client),
		rooms:      make(map[string]map[*Client]bool),
	}
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