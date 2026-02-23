package main

import (
	"encoding/json"
	"net/http"
	"testing"
	"time"
)

// ==================== HUB TESTS ====================

func TestNewHub(t *testing.T) {
	hub := NewHub()

	if hub == nil {
		t.Fatal("Hub should not be nil")
	}

	if hub.clients == nil {
		t.Error("Clients map should be initialized")
	}

	if hub.rooms == nil {
		t.Error("Rooms map should be initialized")
	}

	if hub.broadcast == nil {
		t.Error("Broadcast channel should be initialized")
	}

	if hub.globalBroadcast == nil {
		t.Error("Global broadcast channel should be initialized")
	}

	if hub.register == nil {
		t.Error("Register channel should be initialized")
	}

	if hub.unregister == nil {
		t.Error("Unregister channel should be initialized")
	}
}

func TestHubBroadcastGlobal(t *testing.T) {
	hub := NewHub()

	// Test broadcastGlobal sends to globalBroadcast channel
	msg := []byte(`{"Event":"TEST","Payload":{}}`)

	done := make(chan bool)
	go func() {
		select {
		case received := <-hub.globalBroadcast:
			if string(received) != string(msg) {
				t.Errorf("Expected message %s, got %s", msg, received)
			}
		case <-time.After(100 * time.Millisecond):
			t.Error("Timeout waiting for global broadcast")
		}
		done <- true
	}()

	hub.broadcastGlobal(msg)

	<-done
}

func TestHubRoomManagement(t *testing.T) {
	hub := NewHub()

	// Create mock client (simplified - without rooms field)
	client := &Client{
		UID:  "test-user",
		send: make(chan []byte, 10),
		hub:  hub,
	}

	// Test register
	hub.register <- client

	// Give time for goroutine to process
	time.Sleep(10 * time.Millisecond)

	hub.mu.RLock()
	_, exists := hub.clients["test-user"]
	hub.mu.RUnlock()

	if !exists {
		t.Error("Client should be registered")
	}

	// Test unregister
	hub.unregister <- client

	// Give time for goroutine to process
	time.Sleep(10 * time.Millisecond)

	hub.mu.RLock()
	_, exists = hub.clients["test-user"]
	hub.mu.RUnlock()

	if exists {
		t.Error("Client should be unregistered")
	}
}

// ==================== CLIENT TESTS ====================

func TestClientCreation(t *testing.T) {
	hub := NewHub()

	client := &Client{
		UID:  "user-123",
		send: make(chan []byte, 256),
		hub:  hub,
	}

	if client.UID != "user-123" {
		t.Errorf("Expected UID 'user-123', got '%s'", client.UID)
	}

	if client.send == nil {
		t.Error("Send channel should be initialized")
	}
}

// ==================== WEBSOCKET MESSAGE TESTS ====================

func TestWSMessageParsing(t *testing.T) {
	tests := []struct {
		name     string
		jsonData string
		wantErr  bool
	}{
		{
			name:     "Valid message with event and payload",
			jsonData: `{"Event":"TEST_EVENT","Payload":{"key":"value"}}`,
			wantErr:  false,
		},
		{
			name:     "Valid message with token",
			jsonData: `{"Event":"TEST","Payload":{},"Token":"abc123"}`,
			wantErr:  false,
		},
		{
			name:     "Empty event",
			jsonData: `{"Event":"","Payload":{}}`,
			wantErr:  false,
		},
		{
			name:     "Null payload",
			jsonData: `{"Event":"TEST","Payload":null}`,
			wantErr:  false,
		},
		{
			name:     "Invalid JSON",
			jsonData: `{invalid`,
			wantErr:  true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var msg WSMessage
			err := json.Unmarshal([]byte(tt.jsonData), &msg)

			if tt.wantErr && err == nil {
				t.Error("Expected error, got nil")
			}
			if !tt.wantErr && err != nil {
				t.Errorf("Unexpected error: %v", err)
			}
		})
	}
}

func TestWSMessageEventTypes(t *testing.T) {
	// Test all WebSocket event types from the API
	eventTypes := []string{
		// Party Management
		"GET_FEED",
		"GET_MY_PARTIES",
		"GET_MATCHED_PARTIES",
		"GET_PARTY_DETAILS",
		"CREATE_PARTY",
		"UPDATE_PARTY",
		"DELETE_PARTY",
		"LEAVE_PARTY",
		"UPDATE_PARTY_STATUS",

		// Applications
		"GET_APPLICANTS",
		"GET_MATCHED_USERS",
		"UPDATE_APPLICATION",
		"APPLY_TO_PARTY",
		"REJECT_PARTY",
		"UNMATCH_USER",
		"SWIPE",

		// Chat
		"GET_CHATS",
		"GET_CHAT_HISTORY",
		"SEND_MESSAGE",
		"JOIN_ROOM",

		// DM
		"GET_DMS",
		"GET_DM_MESSAGES",
		"SEND_DM",
		"DELETE_DM_MESSAGE",

		// User
		"GET_USER",
		"UPDATE_PROFILE",
		"DELETE_USER",

		// Fundraising
		"GET_FUNDRAISER_STATE",
		"ADD_CONTRIBUTION",

		// Notifications
		"GET_NOTIFICATIONS",
		"MARK_NOTIFICATION_READ",
		"MARK_ALL_NOTIFICATIONS_READ",

		// Search & Blocking
		"SEARCH_USERS",
		"BLOCK_USER",
		"UNBLOCK_USER",
		"GET_BLOCKED_USERS",

		// Reporting
		"REPORT_USER",
		"REPORT_PARTY",

		// Analytics
		"GET_PARTY_ANALYTICS",
	}

	for _, event := range eventTypes {
		t.Run(event, func(t *testing.T) {
			msg := WSMessage{
				Event:   event,
				Payload: map[string]string{"test": "value"},
			}

			data, err := json.Marshal(msg)
			if err != nil {
				t.Fatalf("Failed to marshal message: %v", err)
			}

			var unmarshaled WSMessage
			err = json.Unmarshal(data, &unmarshaled)
			if err != nil {
				t.Fatalf("Failed to unmarshal message: %v", err)
			}

			if unmarshaled.Event != event {
				t.Errorf("Expected event '%s', got '%s'", event, unmarshaled.Event)
			}
		})
	}
}

// ==================== RESPONSE EVENT TESTS ====================

func TestWSResponseEvents(t *testing.T) {
	responseEvents := []string{
		// Party responses
		"FEED_UPDATE",
		"MY_PARTIES",
		"PARTY_DETAILS",
		"PARTY_CREATED",
		"PARTY_UPDATED",
		"PARTY_DELETED",
		"PARTY_LEFT",
		"PARTY_STATUS_UPDATED",

		// Application responses
		"APPLICANTS_LIST",
		"MATCHED_USERS",
		"APPLICATION_SUBMITTED",
		"APPLICATION_UPDATED",
		"APPLICATION_REJECTED",
		"USER_UNMATCHED",

		// Chat responses
		"CHATS_LIST",
		"CHAT_HISTORY",
		"NEW_MESSAGE",

		// DM responses
		"DMS_LIST",
		"DM_MESSAGES",
		"MESSAGE_DELETED",

		// User responses
		"PROFILE_UPDATED",
		"USER_DELETED",

		// Fundraising responses
		"FUNDRAISER_STATE",
		"FUNDRAISER_UPDATED",

		// Notification responses
		"NOTIFICATIONS_LIST",
		"NOTIFICATION_MARKED_READ",
		"ALL_NOTIFICATIONS_MARKED_READ",

		// Search responses
		"USERS_SEARCH_RESULTS",
		"USER_BLOCKED",
		"USER_UNBLOCKED",
		"BLOCKED_USERS_LIST",

		// Reporting responses
		"USER_REPORTED",
		"PARTY_REPORTED",

		// Analytics responses
		"PARTY_ANALYTICS",

		// Error
		"ERROR",
	}

	for _, event := range responseEvents {
		t.Run(event, func(t *testing.T) {
			msg := WSMessage{
				Event:   event,
				Payload: map[string]string{"status": "success"},
			}

			data, err := json.Marshal(msg)
			if err != nil {
				t.Fatalf("Failed to marshal response: %v", err)
			}

			if len(data) == 0 {
				t.Error("Response should not be empty")
			}
		})
	}
}

// ==================== PAYLOAD SERIALIZATION TESTS ====================

func TestPartyPayloadSerialization(t *testing.T) {
	party := CreateTestParty("party-payload", "host-123")

	data, err := json.Marshal(party)
	if err != nil {
		t.Fatalf("Failed to marshal party: %v", err)
	}

	var unmarshaled Party
	err = json.Unmarshal(data, &unmarshaled)
	if err != nil {
		t.Fatalf("Failed to unmarshal party: %v", err)
	}

	if unmarshaled.ID != party.ID {
		t.Errorf("ID mismatch")
	}
}

func TestUserPayloadSerialization(t *testing.T) {
	user := CreateTestUser("user-payload")

	data, err := json.Marshal(user)
	if err != nil {
		t.Fatalf("Failed to marshal user: %v", err)
	}

	var unmarshaled User
	err = json.Unmarshal(data, &unmarshaled)
	if err != nil {
		t.Fatalf("Failed to unmarshal user: %v", err)
	}

	if unmarshaled.ID != user.ID {
		t.Errorf("ID mismatch")
	}
}

func TestChatMessagePayloadSerialization(t *testing.T) {
	msg := CreateTestMessage("msg-payload", "chat-123", "user-456")

	data, err := json.Marshal(msg)
	if err != nil {
		t.Fatalf("Failed to marshal message: %v", err)
	}

	var unmarshaled ChatMessage
	err = json.Unmarshal(data, &unmarshaled)
	if err != nil {
		t.Fatalf("Failed to unmarshal message: %v", err)
	}

	if unmarshaled.ID != msg.ID {
		t.Errorf("ID mismatch")
	}
}

func TestNotificationPayloadSerialization(t *testing.T) {
	notif := CreateTestNotification("notif-payload", "user-123")

	data, err := json.Marshal(notif)
	if err != nil {
		t.Fatalf("Failed to marshal notification: %v", err)
	}

	var unmarshaled Notification
	err = json.Unmarshal(data, &unmarshaled)
	if err != nil {
		t.Fatalf("Failed to unmarshal notification: %v", err)
	}

	if unmarshaled.ID != notif.ID {
		t.Errorf("ID mismatch")
	}
}

func TestAnalyticsPayloadSerialization(t *testing.T) {
	analytics := PartyAnalytics{
		PartyID:           "party-123",
		TotalViews:        100,
		TotalApplications: 50,
		AcceptedCount:     25,
		PendingCount:      15,
		DeclinedCount:     10,
		CurrentGuestCount: 20,
	}

	data, err := json.Marshal(analytics)
	if err != nil {
		t.Fatalf("Failed to marshal analytics: %v", err)
	}

	var unmarshaled PartyAnalytics
	err = json.Unmarshal(data, &unmarshaled)
	if err != nil {
		t.Fatalf("Failed to unmarshal analytics: %v", err)
	}

	if unmarshaled.PartyID != analytics.PartyID {
		t.Errorf("PartyID mismatch")
	}
}

func TestCrowdfundingPayloadSerialization(t *testing.T) {
	pool := Crowdfunding{
		ID:            "pool-123",
		PartyID:       "party-456",
		TargetAmount:  1000.0,
		CurrentAmount: 500.0,
		Currency:      "USD",
		Contributors: []Contribution{
			{UserID: "user1", Amount: 100.0, PaidAt: time.Now()},
			{UserID: "user2", Amount: 200.0, PaidAt: time.Now()},
		},
		IsFunded: false,
	}

	data, err := json.Marshal(pool)
	if err != nil {
		t.Fatalf("Failed to marshal pool: %v", err)
	}

	var unmarshaled Crowdfunding
	err = json.Unmarshal(data, &unmarshaled)
	if err != nil {
		t.Fatalf("Failed to unmarshal pool: %v", err)
	}

	if unmarshaled.ID != pool.ID {
		t.Errorf("ID mismatch")
	}
	if len(unmarshaled.Contributors) != len(pool.Contributors) {
		t.Errorf("Contributors count mismatch")
	}
}

// ==================== ROOM EVENT TESTS ====================

func TestRoomEventSerialization(t *testing.T) {
	event := RoomEvent{
		RoomID:  "room-123",
		Message: []byte(`{"Event":"TEST","Payload":{}}`),
	}

	// Test that Message field is properly set
	if len(event.Message) == 0 {
		t.Error("Message should not be empty")
	}

	// Test JSON serialization of event
	data, err := json.Marshal(event)
	if err != nil {
		t.Fatalf("Failed to marshal RoomEvent: %v", err)
	}

	if len(data) == 0 {
		t.Error("Serialized event should not be empty")
	}
}

// ==================== WEBSOCKET CONSTANTS TESTS ====================

func TestWebSocketConstants(t *testing.T) {
	// Verify constants are defined
	if writeWait == 0 {
		t.Error("writeWait should be defined")
	}

	if pongWait == 0 {
		t.Error("pongWait should be defined")
	}

	if pingPeriod == 0 {
		t.Error("pingPeriod should be defined")
	}

	if maxMessageSize == 0 {
		t.Error("maxMessageSize should be defined")
	}

	// Verify reasonable values
	if writeWait < 0 {
		t.Error("writeWait should be positive")
	}

	if pongWait < 0 {
		t.Error("pongWait should be positive")
	}

	if pingPeriod < 0 {
		t.Error("pingPeriod should be positive")
	}

	if maxMessageSize <= 0 {
		t.Error("maxMessageSize should be positive")
	}
}

// ==================== UPGRADER TESTS ====================

func TestWebSocketUpgrader(t *testing.T) {
	// Test that upgrader is properly configured
	if upgrader.ReadBufferSize <= 0 {
		t.Error("ReadBufferSize should be positive")
	}

	if upgrader.WriteBufferSize <= 0 {
		t.Error("WriteBufferSize should be positive")
	}

	if upgrader.CheckOrigin == nil {
		t.Error("CheckOrigin should be defined")
	}

	// Test CheckOrigin allows all origins (current configuration)
	req, _ := http.NewRequest("GET", "http://localhost:8080", nil)
	result := upgrader.CheckOrigin(req)
	if !result {
		t.Error("CheckOrigin should return true for testing")
	}
}

// ==================== MESSAGE BUFFER TESTS ====================

func TestMessageBufferSize(t *testing.T) {
	// Test that the hub broadcast channels have appropriate buffer sizes
	hub := NewHub()

	// These should be buffered channels
	// We can't directly check buffer size, but we can verify they were created
	if hub.broadcast == nil {
		t.Error("Broadcast channel should exist")
	}

	if hub.globalBroadcast == nil {
		t.Error("Global broadcast channel should exist")
	}

	// Test client send channel buffer
	client := &Client{
		UID:  "test",
		send: make(chan []byte, 256),
		hub:  hub,
	}

	if client.send == nil {
		t.Error("Client send channel should exist")
	}
}

// ==================== CONCURRENT ACCESS TESTS ====================

func TestHubConcurrentAccess(t *testing.T) {
	hub := NewHub()

	// Test concurrent read/write
	done := make(chan bool)

	go func() {
		for i := 0; i < 100; i++ {
			hub.mu.Lock()
			hub.clients["user-"+string(rune(i))] = &Client{
				UID:  "user-" + string(rune(i)),
				send: make(chan []byte),
				hub:  hub,
			}
			hub.mu.Unlock()
		}
		done <- true
	}()

	go func() {
		for i := 0; i < 100; i++ {
			hub.mu.RLock()
			_ = len(hub.clients)
			hub.mu.RUnlock()
		}
		done <- true
	}()

	<-done
	<-done

	// Verify no race conditions occurred
	if len(hub.clients) != 100 {
		t.Errorf("Expected 100 clients, got %d", len(hub.clients))
	}
}

// ==================== HUB RUN TESTS ====================

func TestHubRunRegisterUnregister(t *testing.T) {
	hub := NewHub()

	// Start hub in background
	go hub.Run()

	// Create and register a client
	client := &Client{
		UID:  "test-client",
		send: make(chan []byte, 10),
		hub:  hub,
	}

	hub.register <- client

	// Wait for registration
	time.Sleep(10 * time.Millisecond)

	hub.mu.RLock()
	_, exists := hub.clients["test-client"]
	hub.mu.RUnlock()

	if !exists {
		t.Error("Client should be registered")
	}

	// Unregister the client
	hub.unregister <- client

	// Wait for unregistration
	time.Sleep(10 * time.Millisecond)

	hub.mu.RLock()
	_, exists = hub.clients["test-client"]
	hub.mu.RUnlock()

	if exists {
		t.Error("Client should be unregistered")
	}
}

func TestHubRunGlobalBroadcast(t *testing.T) {
	hub := NewHub()

	// Start hub in background
	go hub.Run()

	// Create and register a client
	client := &Client{
		UID:  "broadcast-client",
		send: make(chan []byte, 10),
		hub:  hub,
	}

	hub.register <- client
	time.Sleep(10 * time.Millisecond)

	// Send global broadcast
	testMsg := []byte(`{"Event":"TEST","Payload":{}}`)
	hub.globalBroadcast <- testMsg

	// Client should receive the message
	select {
	case received := <-client.send:
		if string(received) != string(testMsg) {
			t.Errorf("Expected %s, got %s", testMsg, received)
		}
	case <-time.After(100 * time.Millisecond):
		t.Error("Timeout waiting for message")
	}
}

func TestHubRunRoomBroadcast(t *testing.T) {
	hub := NewHub()

	// Start hub in background
	go hub.Run()

	// Create and register clients
	client1 := &Client{
		UID:  "room-client-1",
		send: make(chan []byte, 10),
		hub:  hub,
	}

	client2 := &Client{
		UID:  "room-client-2",
		send: make(chan []byte, 10),
		hub:  hub,
	}

	hub.register <- client1
	hub.register <- client2
	time.Sleep(10 * time.Millisecond)

	// Add both clients to a room
	roomID := "test-room"
	hub.mu.Lock()
	if hub.rooms[roomID] == nil {
		hub.rooms[roomID] = make(map[*Client]bool)
	}
	hub.rooms[roomID][client1] = true
	hub.rooms[roomID][client2] = true
	hub.mu.Unlock()

	// Send room broadcast
	testMsg := []byte(`{"Event":"ROOM_TEST","Payload":{}}`)
	roomEvent := RoomEvent{
		RoomID:  roomID,
		Message: testMsg,
	}

	hub.broadcast <- roomEvent

	// Both clients should receive the message
	for i, client := range []*Client{client1, client2} {
		select {
		case received := <-client.send:
			if string(received) != string(testMsg) {
				t.Errorf("Client %d: Expected %s, got %s", i, testMsg, received)
			}
		case <-time.After(100 * time.Millisecond):
			t.Errorf("Client %d: Timeout waiting for message", i)
		}
	}
}
