package main

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

var db *pgxpool.Pool

// InitDB initializes the connection pool
func InitDB(connString string) {
	var err error
	config, err := pgxpool.ParseConfig(connString)
	if err != nil {
		log.Fatalf("Unable to parse connection string: %v", err)
	}

	db, err = pgxpool.NewWithConfig(context.Background(), config)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v", err)
	}
	
	// Run the schema setup
	if err := runMigrations(); err != nil {
		log.Fatalf("Failed to run migrations: %v", err)
	}

	fmt.Println("✅ Database initialized and schema verified.")
}

func runMigrations() error {
	script := `-- ==========================================
-- EXTENSIONS
-- ==========================================
-- Enable UUID support for primary keys
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================================
-- ASSET STORAGE (The "Hash" System)
-- ==========================================
CREATE TABLE IF NOT EXISTS assets (
    hash TEXT PRIMARY KEY,           -- The SHA256/MD5 hash used in URLs
    data BYTEA NOT NULL,             -- Actual binary image data
    mime_type TEXT NOT NULL,         -- e.g., 'image/jpeg', 'image/png'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- USERS TABLE
-- ==========================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    real_name TEXT,
    phone_number TEXT,
    email TEXT UNIQUE,
    password_hash TEXT,
    
    -- Visuals: Stores an array of hashes referencing the assets table
    profile_photos TEXT[] DEFAULT '{}', 
    
    -- Demographics
    age INTEGER,
    date_of_birth TIMESTAMP WITH TIME ZONE,
    height_cm INTEGER,
    gender TEXT,
    
    -- Vibe & Matching
    looking_for TEXT[] DEFAULT '{}',
    drinking_pref TEXT,
    smoking_pref TEXT,
    cannabis_pref TEXT,
    music_genres TEXT[] DEFAULT '{}',
    top_artists TEXT[] DEFAULT '{}',
    
    -- Professional
    job_title TEXT,
    company TEXT,
    school TEXT,
    degree TEXT,
    
    -- Social Handles
    instagram_handle TEXT,
    twitter_handle TEXT,
    linkedin_handle TEXT,
    x_handle TEXT,
    tiktok_handle TEXT,
    
    -- Safety & Stats
    is_verified BOOLEAN DEFAULT FALSE,
    trust_score DOUBLE PRECISION DEFAULT 0.0,
    elo_score DOUBLE PRECISION DEFAULT 0.0,
    parties_hosted INTEGER DEFAULT 0,
    flake_count INTEGER DEFAULT 0,
    
    -- Financial & Geo
    wallet_data JSONB DEFAULT '{}',
    location_lat DOUBLE PRECISION,
    location_lon DOUBLE PRECISION,
    
    -- Bio
    bio TEXT,
    interests TEXT[] DEFAULT '{}',
    
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ensure password_hash column exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='password_hash') THEN
        ALTER TABLE users ADD COLUMN password_hash TEXT;
    END IF;
END $$;

-- Ensure wallet_data column exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='wallet_data') THEN
        ALTER TABLE users ADD COLUMN wallet_data JSONB DEFAULT '{}';
    END IF;
END $$;

-- Drop obsolete username column if it exists to prevent NULL constraint errors
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='username') THEN
        ALTER TABLE users DROP COLUMN username;
    END IF;
END $$;

-- Fix potentially misnamed column from previous attempts
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='wallet data') THEN
        ALTER TABLE users RENAME COLUMN "wallet data" TO wallet_data;
    END IF;
END $$;

-- ==========================================
-- PARTIES TABLE
-- ==========================================
CREATE TABLE IF NOT EXISTS parties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    host_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    party_photos TEXT[] DEFAULT '{}', -- Array of asset hashes
    
    -- Logistics
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT NOT NULL DEFAULT 'OPEN', -- OPEN, LOCKED, LIVE, COMPLETED, CANCELLED
    
    -- Location Privacy
    is_location_revealed BOOLEAN DEFAULT FALSE,
    address TEXT,
    city TEXT,
    geo_lat DOUBLE PRECISION,
    geo_lon DOUBLE PRECISION,
    
    -- Slot Mechanics
    max_capacity INTEGER DEFAULT 0,
    current_guest_count INTEGER DEFAULT 0,
    -- JSONB for map[string]int (e.g., {"girls": 10, "guys": 5})
    slot_requirements JSONB DEFAULT '{}', 
    auto_lock_on_full BOOLEAN DEFAULT FALSE,
    
    -- Curation
    vibe_tags TEXT[] DEFAULT '{}',
    music_genres TEXT[] DEFAULT '{}',
    mood TEXT,
    rules TEXT[] DEFAULT '{}',
    
    -- Social
    chat_room_id UUID, 
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- PARTY APPLICATIONS (The Swipe logic)
-- ==========================================
CREATE TABLE IF NOT EXISTS party_applications (
    party_id UUID NOT NULL REFERENCES parties(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'PENDING', -- PENDING, ACCEPTED, DECLINED, WAITLIST
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (party_id, user_id)
);

-- ==========================================
-- CROWDFUNDING (Rotation Pools)
-- ==========================================
CREATE TABLE IF NOT EXISTS crowdfunding (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    party_id UUID UNIQUE NOT NULL REFERENCES parties(id) ON DELETE CASCADE,
    target_amount DOUBLE PRECISION DEFAULT 0.0,
    current_amount DOUBLE PRECISION DEFAULT 0.0,
    currency TEXT DEFAULT 'USD',
    -- JSONB for slice of Contribution structs
    contributors JSONB DEFAULT '[]', 
    is_funded BOOLEAN DEFAULT FALSE
);

-- ==========================================
-- CHAT SYSTEM
-- ==========================================
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chat_id UUID NOT NULL, -- Logical ID grouping messages for a specific party
    sender_id UUID NOT NULL REFERENCES users(id),
    type TEXT NOT NULL DEFAULT 'TEXT', -- TEXT, IMAGE, VIDEO, AUDIO, SYSTEM, AI, PAYMENT
    content TEXT,
    
    -- Media (Stores hashes/urls)
    media_url TEXT,
    thumbnail_url TEXT,
    
    -- JSONB for map[string]interface{} (AI context or payment metadata)
    metadata JSONB DEFAULT '{}',
    
    reply_to_id UUID, -- References another message ID
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- INDEXES FOR HIGH EFFICIENCY
-- ==========================================
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_parties_status ON parties(status);
CREATE INDEX IF NOT EXISTS idx_parties_host_id ON parties(host_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_chat_id ON chat_messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_assets_hash ON assets(hash);

-- ==========================================
-- TRIGGERS & FUNCTIONS
-- ==========================================

-- Create or Replace the function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger creation logic (Checks if trigger exists first)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_party_modtime') THEN
        CREATE TRIGGER update_party_modtime
            BEFORE UPDATE ON parties
            FOR EACH ROW
            EXECUTE PROCEDURE update_updated_at_column();
    END IF;
END $$;
`
_, err := db.Exec(context.Background(), script)
	return err
}
// ==========================================
// ASSET / FILE METHODS
// ==========================================

// SaveAsset stores binary data, returns the SHA256 hash.
func SaveAsset(data []byte, mimeType string) (string, error) {
	hashBytes := sha256.Sum256(data)
	hashStr := hex.EncodeToString(hashBytes[:])

	_, err := db.Exec(context.Background(),
		"INSERT INTO assets (hash, data, mime_type) VALUES ($1, $2, $3) ON CONFLICT (hash) DO NOTHING",
		hashStr, data, mimeType)
	return hashStr, err
}

// GetAsset retrieves binary data and mime type by hash.
func GetAsset(hash string) ([]byte, string, error) {
	var data []byte
	var mimeType string
	err := db.QueryRow(context.Background(),
		"SELECT data, mime_type FROM assets WHERE hash = $1", hash).Scan(&data, &mimeType)
	return data, mimeType, err
}

// ==========================================
// USER CRUD
// ==========================================

func CreateUser(u User) (string, error) {
	walletJSON, _ := json.Marshal(u.WalletData)
	query := `INSERT INTO users (
		real_name, phone_number, email, profile_photos, age, date_of_birth,
		height_cm, gender, looking_for, drinking_pref, smoking_pref, cannabis_pref,
		music_genres, top_artists, job_title, company, school, degree,
		instagram_handle, twitter_handle, linkedin_handle, x_handle, tiktok_handle,
		is_verified, trust_score, elo_score, parties_hosted, flake_count,
		wallet_data, location_lat, location_lon, bio, interests, last_active_at
	) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, 
		$19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34) 
	RETURNING id`

	var id string
	now := time.Now()
	err := db.QueryRow(context.Background(), query,
		u.RealName, u.PhoneNumber, u.Email, u.ProfilePhotos, u.Age, u.DateOfBirth,
		u.HeightCm, u.Gender, u.LookingFor, u.DrinkingPref, u.SmokingPref, u.CannabisPref,
		u.MusicGenres, u.TopArtists, u.JobTitle, u.Company, u.School, u.Degree,
		u.InstagramHandle, u.TwitterHandle, u.LinkedinHandle, u.XHandle, u.TikTokHandle,
		u.IsVerified, u.TrustScore, u.EloScore, u.PartiesHosted, u.FlakeCount,
		walletJSON, u.LocationLat, u.LocationLon, u.Bio, u.Interests, &now,
	).Scan(&id)
	return id, err
}

func GetUser(id string) (User, error) {
	var u User
	var walletJSON []byte
	query := `SELECT id, real_name, phone_number, email, profile_photos, age, date_of_birth,
		height_cm, gender, looking_for, drinking_pref, smoking_pref, cannabis_pref, music_genres,
		top_artists, job_title, company, school, degree, instagram_handle, twitter_handle,
		linkedin_handle, x_handle, tiktok_handle, is_verified, trust_score, elo_score,
		parties_hosted, flake_count, wallet_data, location_lat, location_lon, bio,
		interests, last_active_at, created_at FROM users WHERE id = $1`

	err := db.QueryRow(context.Background(), query, id).Scan(
		&u.ID, &u.RealName, &u.PhoneNumber, &u.Email, &u.ProfilePhotos, &u.Age, &u.DateOfBirth,
		&u.HeightCm, &u.Gender, &u.LookingFor, &u.DrinkingPref, &u.SmokingPref, &u.CannabisPref, &u.MusicGenres,
		&u.TopArtists, &u.JobTitle, &u.Company, &u.School, &u.Degree, &u.InstagramHandle, &u.TwitterHandle,
		&u.LinkedinHandle, &u.XHandle, &u.TikTokHandle, &u.IsVerified, &u.TrustScore, &u.EloScore,
		&u.PartiesHosted, &u.FlakeCount, &walletJSON, &u.LocationLat, &u.LocationLon, &u.Bio,
		&u.Interests, &u.LastActiveAt, &u.CreatedAt,
	)
	if err == nil {
		json.Unmarshal(walletJSON, &u.WalletData)
	}
	return u, err
}

func GetUserByEmail(email string) (User, string, error) {
	var u User
	var passwordHash string
	var walletJSON []byte
	query := `SELECT id, real_name, phone_number, email, password_hash, profile_photos, age, 
		date_of_birth, height_cm, gender, looking_for, drinking_pref, smoking_pref, cannabis_pref, 
		music_genres, top_artists, job_title, company, school, degree, instagram_handle, 
		twitter_handle, linkedin_handle, x_handle, tiktok_handle, is_verified, trust_score, 
		elo_score, parties_hosted, flake_count, wallet_data, location_lat, location_lon, 
		last_active_at, created_at, bio, interests 
		FROM users WHERE email = $1`

	err := db.QueryRow(context.Background(), query, email).Scan(
		&u.ID, &u.RealName, &u.PhoneNumber, &u.Email, &passwordHash, &u.ProfilePhotos, &u.Age,
		&u.DateOfBirth, &u.HeightCm, &u.Gender, &u.LookingFor, &u.DrinkingPref, &u.SmokingPref, &u.CannabisPref,
		&u.MusicGenres, &u.TopArtists, &u.JobTitle, &u.Company, &u.School, &u.Degree, &u.InstagramHandle,
		&u.TwitterHandle, &u.LinkedinHandle, &u.XHandle, &u.TikTokHandle, &u.IsVerified, &u.TrustScore,
		&u.EloScore, &u.PartiesHosted, &u.FlakeCount, &walletJSON, &u.LocationLat, &u.LocationLon,
		&u.LastActiveAt, &u.CreatedAt, &u.Bio, &u.Interests,
	)
	if err == nil {
		json.Unmarshal(walletJSON, &u.WalletData)
	}
	return u, passwordHash, err
}

func UpdateUser(u User) error {
	walletJSON, _ := json.Marshal(u.WalletData)
	query := `UPDATE users SET 
		real_name=$1, phone_number=$2, profile_photos=$3, bio=$4, 
		location_lat=$5, location_lon=$6, last_active_at=$7, 
		interests=$8, instagram_handle=$9, twitter_handle=$10, 
		linkedin_handle=$11, x_handle=$12, tiktok_handle=$13, wallet_data=$14
		WHERE id=$15`
	_, err := db.Exec(context.Background(), query, u.RealName, u.PhoneNumber, u.ProfilePhotos, 
		u.Bio, u.LocationLat, u.LocationLon, time.Now(), u.Interests, 
		u.InstagramHandle, u.TwitterHandle, u.LinkedinHandle, u.XHandle, 
		u.TikTokHandle, walletJSON, u.ID)
	return err
}

func DeleteUser(id string) error {
	_, err := db.Exec(context.Background(), "DELETE FROM users WHERE id = $1", id)
	return err
}

// ==========================================
// PARTY CRUD
// ==========================================

func CreateParty(p Party) (string, error) {
	slotReq, _ := json.Marshal(p.SlotRequirements)
	query := `INSERT INTO parties (
		host_id, title, description, party_photos, start_time, end_time, status,
		is_location_revealed, address, city, geo_lat, geo_lon, max_capacity,
		slot_requirements, vibe_tags, music_genres, mood, rules, chat_room_id
	) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19) 
	RETURNING id`

	var id string
	err := db.QueryRow(context.Background(), query,
		p.HostID, p.Title, p.Description, p.PartyPhotos, p.StartTime, p.EndTime, p.Status,
		p.IsLocationRevealed, p.Address, p.City, p.GeoLat, p.GeoLon, p.MaxCapacity,
		slotReq, p.VibeTags, p.MusicGenres, p.Mood, p.Rules, p.ChatRoomID,
	).Scan(&id)

	if err == nil && p.RotationPool != nil {
		p.RotationPool.PartyID = id
		_, poolErr := CreateRotationPool(*p.RotationPool)
		if poolErr != nil {
			log.Printf("Warning: Failed to create rotation pool for party: %v", poolErr)
		}
	}

	return id, err
}

func GetParty(id string) (Party, error) {
	var p Party
	var slotReq []byte
	query := `SELECT id, host_id, title, description, party_photos, start_time, end_time, status,
		is_location_revealed, address, city, geo_lat, geo_lon, max_capacity, current_guest_count,
		slot_requirements, auto_lock_on_full, vibe_tags, music_genres, mood, rules, chat_room_id,
		created_at, updated_at FROM parties WHERE id = $1`

	err := db.QueryRow(context.Background(), query, id).Scan(
		&p.ID, &p.HostID, &p.Title, &p.Description, &p.PartyPhotos, &p.StartTime, &p.EndTime, 
		&p.Status, &p.IsLocationRevealed, &p.Address, &p.City, &p.GeoLat, &p.GeoLon, 
		&p.MaxCapacity, &p.CurrentGuestCount, &slotReq, &p.AutoLockOnFull, &p.VibeTags, 
		&p.MusicGenres, &p.Mood, &p.Rules, &p.ChatRoomID, &p.CreatedAt, &p.UpdatedAt,
	)
	if err == nil {
		json.Unmarshal(slotReq, &p.SlotRequirements)
	}
	return p, err
}

func UpdateParty(p Party) error {
	slotReq, _ := json.Marshal(p.SlotRequirements)
	query := `UPDATE parties SET 
		title=$1, description=$2, status=$3, is_location_revealed=$4, address=$5,
		city=$6, max_capacity=$7, slot_requirements=$8, updated_at=NOW()
		WHERE id=$9`
	_, err := db.Exec(context.Background(), query, p.Title, p.Description, p.Status, 
		p.IsLocationRevealed, p.Address, p.City, p.MaxCapacity, slotReq, p.ID)
	return err
}

func UpdatePartyStatus(partyID string, status PartyStatus) error {
	_, err := db.Exec(context.Background(), "UPDATE parties SET status = $1, updated_at = NOW() WHERE id = $2", status, partyID)
	return err
}

func DeleteParty(id string) error {
	_, err := db.Exec(context.Background(), "DELETE FROM parties WHERE id = $1", id)
	return err
}

// ==========================================
// CHANNEL / CHAT METHODS
// ==========================================

func SaveMessage(m ChatMessage) (string, error) {
	meta, _ := json.Marshal(m.Metadata)
	query := `INSERT INTO chat_messages (chat_id, sender_id, type, content, media_url, 
		thumbnail_url, metadata, reply_to_id) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING id`
	
	var id string
	var replyID interface{} = nil
	if m.ReplyToID != "" {
		replyID = m.ReplyToID
	}

	err := db.QueryRow(context.Background(), query, m.ChatID, m.SenderID, m.Type, m.Content, 
		m.MediaURL, m.ThumbnailURL, meta, replyID).Scan(&id)
	return id, err
}

func GetChatHistory(chatID string, limit int) ([]ChatMessage, error) {
	query := `SELECT id, sender_id, type, content, media_url, thumbnail_url, metadata, reply_to_id, created_at 
		FROM chat_messages WHERE chat_id = $1 ORDER BY created_at DESC LIMIT $2`
	
	rows, err := db.Query(context.Background(), query, chatID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var msgs []ChatMessage
	for rows.Next() {
		var m ChatMessage
		var meta []byte
		var replyID *string // Handle potential nulls
		err := rows.Scan(&m.ID, &m.SenderID, &m.Type, &m.Content, &m.MediaURL, &m.ThumbnailURL, &meta, &replyID, &m.CreatedAt)
		if err != nil {
			return nil, err
		}
		m.ChatID = chatID
		json.Unmarshal(meta, &m.Metadata)
		if replyID != nil {
			m.ReplyToID = *replyID
		}
		msgs = append(msgs, m)
	}
	return msgs, nil
}

// ==========================================
// CROWDFUNDING / ROTATION POOL
// ==========================================

func CreateRotationPool(pool Crowdfunding) (string, error) {
	contribs, _ := json.Marshal(pool.Contributors)
	query := `INSERT INTO crowdfunding (party_id, target_amount, current_amount, currency, contributors, is_funded) 
	          VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`
	
	var id string
	err := db.QueryRow(context.Background(), query, pool.PartyID, pool.TargetAmount, 
		pool.CurrentAmount, pool.Currency, contribs, pool.IsFunded).Scan(&id)
	return id, err
}

func GetRotationPool(partyID string) (Crowdfunding, error) {
	var c Crowdfunding
	var contribs []byte
	query := `SELECT id, party_id, target_amount, current_amount, currency, contributors, is_funded 
		FROM crowdfunding WHERE party_id = $1`
	
	err := db.QueryRow(context.Background(), query, partyID).Scan(
		&c.ID, &c.PartyID, &c.TargetAmount, &c.CurrentAmount, &c.Currency, &contribs, &c.IsFunded,
	)
	if err == nil {
		json.Unmarshal(contribs, &c.Contributors)
	}
	return c, err
}

func AddContribution(partyID string, contrib Contribution) error {
	// 1. Atomically update Amount, 2. Append to Contributors JSONB array using Postgres concat operator ||
	query := `UPDATE crowdfunding SET 
		current_amount = current_amount + $1,
		contributors = contributors || $2::jsonb
		WHERE party_id = $3`
	
	contribJSON, _ := json.Marshal(contrib)
	result, err := db.Exec(context.Background(), query, contrib.Amount, contribJSON, partyID)
	if err != nil {
		return err
	}
	if result.RowsAffected() == 0 {
		return errors.New("no rotation pool found for this party")
	}
	return nil
}