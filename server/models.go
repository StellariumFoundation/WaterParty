package models

import (
	"time"
)

// ==========================================
// ENUMS & CONSTANTS
// ==========================================

type PartyStatus string
type ApplicantStatus string
type MessageType string

const (
	// Party Lifecycle
	PartyStatusOpen      PartyStatus = "OPEN"      
	PartyStatusLocked    PartyStatus = "LOCKED"    
	PartyStatusLive      PartyStatus = "LIVE"      
	PartyStatusCompleted PartyStatus = "COMPLETED" 
	PartyStatusCancelled PartyStatus = "CANCELLED"

	// Match/Swipe Lifecycle
	ApplicantPending  ApplicantStatus = "PENDING"
	ApplicantAccepted ApplicantStatus = "ACCEPTED"
	ApplicantDeclined ApplicantStatus = "DECLINED"
	ApplicantWaitlist ApplicantStatus = "WAITLIST"

	// Message Classification
	MsgText    MessageType = "TEXT"
	MsgImage   MessageType = "IMAGE"
	MsgVideo   MessageType = "VIDEO"
	MsgAudio   MessageType = "AUDIO"
	MsgSystem  MessageType = "SYSTEM"  // e.g., "The location is revealed!"
	MsgWingman MessageType = "AI"      // AI generated icebreakers
	MsgPayment MessageType = "PAYMENT" // Rotation pool updates
)

// ==========================================
// WEBSOCKET ENVELOPE
// ==========================================

// WSMessage is the generic container for all websocket traffic.
type WSMessage struct {
	Event   string      
	Payload interface{} 
	Token   string      
}

// ==========================================
// CORE ENTITIES
// ==========================================

// User represents a participant in the ecosystem.
type User struct {
	// --- Core Identity ---
	ID          string
	Username    string
	RealName    string
	PhoneNumber string
	Email       string 
	
	// --- Visuals (Binary data from Postgres) ---
	ProfilePhotos [][]byte

	// --- Demographics ---
	Age         int
	DateOfBirth time.Time 
	HeightCm    int
	Gender      string

	// --- The "Vibe" & Matching ---
	LookingFor   []string 
	DrinkingPref string   
	SmokingPref  string   
	CannabisPref string   
	
	MusicGenres []string 
	TopArtists  []string 

	// --- Professional & Education ---
	JobTitle string 
	Company  string 
	School   string 
	Degree   string 
	
	// --- Social Proof ---
	InstagramHandle string
	TwitterHandle   string
	LinkedinHandle  string
	XHandle         string
	TikTokHandle    string

	// --- Safety & The Trust Protocol ---
	IsVerified bool
	
	// --- Stats & Reputation ---
	TrustScore      float64
	EloScore        float64
	PartiesAttended []Party // Historical references
	PartiesHosted   int
	FlakeCount      int 

	// --- Financial ---
	WalletAddress string 

	// --- Geolocation & System ---
	LocationLat  float64
	LocationLon  float64
	LastActiveAt time.Time 
	CreatedAt    time.Time
	
	Bio       string
	Interests []string
	VibeTags  []string
}

// Party represents the "Micro-Organization" event.
type Party struct {
	// --- Core Identity ---
	ID          string
	HostID      string
	Title       string
	Description string 
	
	// Visuals
	PartyPhotos [][]byte 
	
	// --- Logistics & Lifecycle ---
	StartTime time.Time
	EndTime   time.Time
	Status    PartyStatus 

	// --- Location Privacy (The "Locked" Mechanic) ---
	IsLocationRevealed bool
	Address            string 
	City               string
	GeoLat             float64
	GeoLon             float64

	// --- The "Slot" Mechanics ---
	MaxCapacity       int
	CurrentGuestCount int
	SlotRequirements  map[string]int 
	AutoLockOnFull    bool 

	// --- The "Vibe" & Curation ---
	VibeTags    []string 
	MusicGenres []string 
	Mood        string   
	Rules       []string 
	
	// The crowd-fund for supplies
	RotationPool *Crowdfunding

	// --- Social Graph & Tech ---
	ChatRoomID string 
	CreatedAt  time.Time
	UpdatedAt  time.Time
}

// PartyApplication represents the "Swipe/Request" protocol.
type PartyApplication struct {
	PartyID   string          
	UserID    string          
	Status    ApplicantStatus 
	AppliedAt time.Time       
	
	// Snapshot for host review
	UserSnapshot User 
}

// ==========================================
// CHAT SYSTEM
// ==========================================

// ChatRoom is the real-time social hub for a party.
type ChatRoom struct {
	ID      string
	PartyID string
	HostID  string

	// --- Participants ---
	ParticipantIDs []string

	// --- State ---
	IsActive  bool
	IsMuted   bool
	CreatedAt time.Time
	UpdatedAt time.Time

	// --- Message History ---
	RecentMessages []ChatMessage

	// --- Previews ---
	LastMessageID      string
	LastMessageContent string    
	LastMessageType    MessageType
	LastMessageAt      time.Time

	// --- Financials ---
	RotationPoolID string
}

// ChatMessage is the unit of communication.
type ChatMessage struct {
	ID       string
	ChatID   string
	SenderID string 

	Type    MessageType 
	Content string

	// Media Handling
	MediaURL     string 
	ThumbnailURL string 
	MediaData    []byte // Used only during initial upload transition

	// --- Dynamic Attributes ---
	// Flexible storage for AI context or payment details
	Metadata map[string]interface{}

	// --- Interactions ---
	ReplyToID string 
	
	CreatedAt time.Time
}

// ==========================================
// FINANCIALS
// ==========================================

// Crowdfunding (Rotation Pool) manages group funds.
type Crowdfunding struct {
	ID            string  
	PartyID       string  
	TargetAmount  float64 
	CurrentAmount float64 
	Currency      string  
	
	Contributors []Contribution 
	IsFunded     bool           
}

type Contribution struct {
	UserID string  
	Amount float64 
	PaidAt time.Time 
}