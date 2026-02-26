package main

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"image"
	_ "image/gif"
	"image/jpeg"
	_ "image/png"
	"log"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/nfnt/resize"
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
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================================
-- ASSET STORAGE
-- ==========================================
CREATE TABLE IF NOT EXISTS assets (
    hash TEXT PRIMARY KEY,
    data BYTEA NOT NULL,
    mime_type TEXT NOT NULL,
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
    profile_photos TEXT[] DEFAULT '{}',
    age INTEGER,
    date_of_birth TIMESTAMP WITH TIME ZONE,
    height_cm INTEGER,
    gender TEXT,
    drinking_pref TEXT,
    smoking_pref TEXT,
    top_artists TEXT[] DEFAULT '{}',
    job_title TEXT,
    company TEXT,
    school TEXT,
    degree TEXT,
    instagram_handle TEXT,
    linkedin_handle TEXT,
    x_handle TEXT,
    tiktok_handle TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    trust_score DOUBLE PRECISION DEFAULT 0.0,
    elo_score DOUBLE PRECISION DEFAULT 0.0,
    parties_hosted INTEGER DEFAULT 0,
    flake_count INTEGER DEFAULT 0,
    wallet_data JSONB DEFAULT '{}',
    location_lat DOUBLE PRECISION,
    location_lon DOUBLE PRECISION,
    bio TEXT,
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    thumbnail TEXT
);

-- ==========================================
-- PARTIES TABLE
-- ==========================================
CREATE TABLE IF NOT EXISTS parties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    host_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    party_photos TEXT[] DEFAULT '{}',
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_hours INTEGER DEFAULT 2,
    status TEXT NOT NULL DEFAULT 'OPEN',
    is_location_revealed BOOLEAN DEFAULT FALSE,
    address TEXT,
    city TEXT,
    geo_lat DOUBLE PRECISION,
    geo_lon DOUBLE PRECISION,
    max_capacity INTEGER DEFAULT 0,
    current_guest_count INTEGER DEFAULT 0,
    auto_lock_on_full BOOLEAN DEFAULT FALSE,
    vibe_tags TEXT[] DEFAULT '{}',
    rules TEXT[] DEFAULT '{}',
    chat_room_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    thumbnail TEXT
);

-- ==========================================
-- PARTY APPLICATIONS
-- ==========================================
CREATE TABLE IF NOT EXISTS party_applications (
    party_id UUID NOT NULL REFERENCES parties(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'PENDING',
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (party_id, user_id)
);

-- ==========================================
-- CROWDFUNDING
-- ==========================================
CREATE TABLE IF NOT EXISTS crowdfunding (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    party_id UUID UNIQUE NOT NULL REFERENCES parties(id) ON DELETE CASCADE,
    target_amount DOUBLE PRECISION DEFAULT 0.0,
    current_amount DOUBLE PRECISION DEFAULT 0.0,
    currency TEXT DEFAULT 'USD',
    contributors JSONB DEFAULT '[]',
    is_funded BOOLEAN DEFAULT FALSE
);

-- ==========================================
-- CHAT SYSTEM
-- ==========================================
CREATE TABLE IF NOT EXISTS chat_rooms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    party_id UUID REFERENCES parties(id) ON DELETE CASCADE,
    host_id UUID NOT NULL REFERENCES users(id),
    title TEXT,
    image_url TEXT,
    is_group BOOLEAN DEFAULT TRUE,
    participant_ids UUID[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chat_id UUID NOT NULL,
    sender_id UUID NOT NULL REFERENCES users(id),
    type TEXT NOT NULL DEFAULT 'TEXT',
    content TEXT,
    media_url TEXT,
    thumbnail_url TEXT,
    metadata JSONB DEFAULT '{}',
    reply_to_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- BLOCKED USERS
-- ==========================================
CREATE TABLE IF NOT EXISTS blocked_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blocker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(blocker_id, blocked_id)
);

-- ==========================================
-- USER REPORTS
-- ==========================================
CREATE TABLE IF NOT EXISTS user_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reported_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    details TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- PARTY REPORTS
-- ==========================================
CREATE TABLE IF NOT EXISTS party_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    party_id UUID NOT NULL REFERENCES parties(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    details TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- NOTIFICATIONS
-- ==========================================
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT,
    data TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- INDEXES
-- ==========================================
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_parties_status ON parties(status);
CREATE INDEX IF NOT EXISTS idx_parties_host_id ON parties(host_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_chat_id ON chat_messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_assets_hash ON assets(hash);
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocker ON blocked_users(blocker_id);
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocked ON blocked_users(blocked_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_user_reports_reported ON user_reports(reported_id);
CREATE INDEX IF NOT EXISTS idx_party_reports_party ON party_reports(party_id);

-- ==========================================
-- TRIGGERS & FUNCTIONS
-- ==========================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $func$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$func$ language 'plpgsql';

DO $trigger$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_party_modtime') THEN
        CREATE TRIGGER update_party_modtime
            BEFORE UPDATE ON parties
            FOR EACH ROW
            EXECUTE PROCEDURE update_updated_at_column();
    END IF;
END $trigger$;
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

// CreateThumbnail generates a 150x150 thumbnail from image data.
func CreateThumbnail(data []byte) ([]byte, error) {
	img, _, err := image.Decode(bytes.NewReader(data))
	if err != nil {
		return nil, err
	}
	// Resize to 150x150
	m := resize.Resize(150, 0, img, resize.Lanczos3)
	buf := new(bytes.Buffer)
	err = jpeg.Encode(buf, m, nil)
	return buf.Bytes(), err
}

// ==========================================
// USER CRUD
// ==========================================

func CreateUser(u User) (string, error) {
	walletJSON, _ := json.Marshal(u.WalletData)
	query := `INSERT INTO users (
		real_name, phone_number, email, profile_photos, age, date_of_birth,
		height_cm, gender, drinking_pref, smoking_pref,
		top_artists, job_title, company, school, degree,
		instagram_handle, linkedin_handle, x_handle, tiktok_handle,
		is_verified, trust_score, elo_score, parties_hosted, flake_count,
		wallet_data, location_lat, location_lon, bio, last_active_at, thumbnail
	) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, 
		$13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32) 
	RETURNING id`

	var id string
	now := time.Now()
	err := db.QueryRow(context.Background(), query,
		u.RealName, u.PhoneNumber, u.Email, u.ProfilePhotos, u.Age, u.DateOfBirth,
		u.HeightCm, u.Gender, u.DrinkingPref, u.SmokingPref,
		u.TopArtists, u.JobTitle, u.Company, u.School, u.Degree,
		u.InstagramHandle, u.LinkedinHandle, u.XHandle, u.TikTokHandle,
		u.IsVerified, u.TrustScore, u.EloScore, u.PartiesHosted, u.FlakeCount,
		walletJSON, u.LocationLat, u.LocationLon, u.Bio, &now, u.Thumbnail,
	).Scan(&id)
	return id, err
}

func GetUser(id string) (User, error) {
	var u User
	var walletJSON []byte
	query := `SELECT id, real_name, phone_number, email, profile_photos, age, date_of_birth,
		height_cm, gender, drinking_pref, smoking_pref,
		top_artists, job_title, company, school, degree, instagram_handle, 
		linkedin_handle, x_handle, tiktok_handle, is_verified, trust_score, elo_score,
		parties_hosted, flake_count, wallet_data, location_lat, location_lon, COALESCE(bio, ''),
		last_active_at, created_at, COALESCE(thumbnail, '') FROM users WHERE id = $1`

	err := db.QueryRow(context.Background(), query, id).Scan(
		&u.ID, &u.RealName, &u.PhoneNumber, &u.Email, &u.ProfilePhotos, &u.Age, &u.DateOfBirth,
		&u.HeightCm, &u.Gender, &u.DrinkingPref, &u.SmokingPref,
		&u.TopArtists, &u.JobTitle, &u.Company, &u.School, &u.Degree, &u.InstagramHandle,
		&u.LinkedinHandle, &u.XHandle, &u.TikTokHandle, &u.IsVerified, &u.TrustScore, &u.EloScore,
		&u.PartiesHosted, &u.FlakeCount, &walletJSON, &u.LocationLat, &u.LocationLon, &u.Bio,
		&u.LastActiveAt, &u.CreatedAt, &u.Thumbnail,
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
		date_of_birth, height_cm, gender, drinking_pref, smoking_pref, 
		top_artists, job_title, company, school, degree, instagram_handle, 
		linkedin_handle, x_handle, tiktok_handle, is_verified, trust_score, 
		elo_score, parties_hosted, flake_count, wallet_data, location_lat, location_lon, 
		last_active_at, created_at, COALESCE(bio, ''), COALESCE(thumbnail, '') 
		FROM users WHERE email = $1`

	err := db.QueryRow(context.Background(), query, email).Scan(
		&u.ID, &u.RealName, &u.PhoneNumber, &u.Email, &passwordHash, &u.ProfilePhotos, &u.Age,
		&u.DateOfBirth, &u.HeightCm, &u.Gender, &u.DrinkingPref, &u.SmokingPref,
		&u.TopArtists, &u.JobTitle, &u.Company, &u.School, &u.Degree, &u.InstagramHandle,
		&u.LinkedinHandle, &u.XHandle, &u.TikTokHandle, &u.IsVerified, &u.TrustScore,
		&u.EloScore, &u.PartiesHosted, &u.FlakeCount, &walletJSON, &u.LocationLat, &u.LocationLon,
		&u.LastActiveAt, &u.CreatedAt, &u.Bio, &u.Thumbnail,
	)
	if err == nil {
		json.Unmarshal(walletJSON, &u.WalletData)
	}
	return u, passwordHash, err
}

func UpdateUser(u User) error {
	walletJSON, _ := json.Marshal(u.WalletData)

	// Debug logging to diagnose parameter type issues
	log.Printf("DEBUG UpdateUser: RealName=%q, PhoneNumber=%q, ProfilePhotos=%v, Thumbnail=%q",
		u.RealName, u.PhoneNumber, u.ProfilePhotos, u.Thumbnail)
	log.Printf("DEBUG UpdateUser: DrinkingPref=%q, SmokingPref=%q, JobTitle=%q",
		u.DrinkingPref, u.SmokingPref, u.JobTitle)

	// Handle empty strings by using NULL for TEXT columns when empty
	// This fixes "could not determine data type of parameter" error
	phoneNumber := nullString(u.PhoneNumber)
	drinkingPref := nullString(u.DrinkingPref)
	smokingPref := nullString(u.SmokingPref)
	jobTitle := nullString(u.JobTitle)
	company := nullString(u.Company)
	school := nullString(u.School)
	degree := nullString(u.Degree)
	instagramHandle := nullString(u.InstagramHandle)
	linkedinHandle := nullString(u.LinkedinHandle)
	xHandle := nullString(u.XHandle)
	tiktokHandle := nullString(u.TikTokHandle)
	thumbnail := nullString(u.Thumbnail)
	bio := nullString(u.Bio)

	query := `UPDATE users SET 
		real_name=CAST($1 AS TEXT), 
		phone_number=CAST($2 AS TEXT), 
		profile_photos=CAST($3 AS TEXT[]), 
		bio=CAST($4 AS TEXT),
		location_lat=$5, 
		location_lon=$6, 
		updated_at=$7,
		instagram_handle=CAST($8 AS TEXT), 
		linkedin_handle=CAST($9 AS TEXT), 
		x_handle=CAST($10 AS TEXT), 
		tiktok_handle=CAST($11 AS TEXT), 
		wallet_data=$12,
		job_title=CAST($13 AS TEXT), 
		company=CAST($14 AS TEXT), 
		school=CAST($15 AS TEXT), 
		degree=CAST($16 AS TEXT), 
		age=$17,
		height_cm=$18, 
		gender=CAST($19 AS TEXT), 
		drinking_pref=CAST($20 AS TEXT), 
		smoking_pref=CAST($21 AS TEXT), 
		thumbnail=CAST($22 AS TEXT)
		WHERE id=$23`
	_, err := db.Exec(context.Background(), query,
		u.RealName, phoneNumber, u.ProfilePhotos, bio,
		u.LocationLat, u.LocationLon, time.Now(),
		instagramHandle, linkedinHandle, xHandle,
		tiktokHandle, walletJSON, jobTitle, company, school,
		degree, u.Age, u.HeightCm, u.Gender, drinkingPref,
		smokingPref, thumbnail, u.ID)
	return err
}

// nullString converts empty string to nil for proper NULL handling in PostgreSQL
func nullString(s string) interface{} {
	if s == "" {
		return nil
	}
	return s
}

func DeleteUser(id string) error {
	if db == nil {
		return fmt.Errorf("database not initialized")
	}

	// Delete related records first to avoid foreign key constraint violations
	// Delete blocked user relationships
	_, err := db.Exec(context.Background(),
		"DELETE FROM blocked_users WHERE blocker_id = $1 OR blocked_id = $1", id)
	if err != nil {
		return err
	}

	// Delete user reports
	_, err = db.Exec(context.Background(),
		"DELETE FROM user_reports WHERE reporter_id = $1 OR reported_id = $1", id)
	if err != nil {
		return err
	}

	// Delete party reports by this user
	_, err = db.Exec(context.Background(),
		"DELETE FROM party_reports WHERE reporter_id = $1", id)
	if err != nil {
		return err
	}

	// Delete notifications
	_, err = db.Exec(context.Background(),
		"DELETE FROM notifications WHERE user_id = $1", id)
	if err != nil {
		return err
	}

	// Delete chat messages where user is sender
	_, err = db.Exec(context.Background(),
		"DELETE FROM chat_messages WHERE sender_id = $1", id)
	if err != nil {
		return err
	}

	// Delete party applications
	_, err = db.Exec(context.Background(),
		"DELETE FROM party_applications WHERE user_id = $1", id)
	if err != nil {
		return err
	}

	// Delete chat rooms where user is host
	_, err = db.Exec(context.Background(),
		"DELETE FROM chat_rooms WHERE host_id = $1", id)
	if err != nil {
		return err
	}

	// Delete parties hosted by user
	_, err = db.Exec(context.Background(),
		"DELETE FROM parties WHERE host_id = $1", id)
	if err != nil {
		return err
	}

	// Finally delete the user
	_, err = db.Exec(context.Background(), "DELETE FROM users WHERE id = $1", id)
	return err
}

// ==========================================
// PARTY CRUD
// ==========================================

func CreateParty(p Party) (string, error) {
	query := `INSERT INTO parties (
		host_id, title, description, party_photos, start_time, duration_hours, status,
		is_location_revealed, address, city, geo_lat, geo_lon, max_capacity,
		vibe_tags, rules, chat_room_id, thumbnail
	) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17) 
	RETURNING id`

	var id string
	err := db.QueryRow(context.Background(), query,
		p.HostID, p.Title, p.Description, p.PartyPhotos, p.StartTime, p.DurationHours, p.Status,
		p.IsLocationRevealed, p.Address, p.City, p.GeoLat, p.GeoLon, p.MaxCapacity,
		p.VibeTags, p.Rules, p.ChatRoomID, p.Thumbnail,
	).Scan(&id)

	if err == nil {
		// Create ChatRoom for the party
		_, chatErr := CreateChatRoom(ChatRoom{
			ID:             p.ChatRoomID,
			PartyID:        id,
			HostID:         p.HostID,
			Title:          p.Title,
			IsGroup:        true,
			ParticipantIDs: []string{p.HostID},
		})
		if chatErr != nil {
			log.Printf("Warning: Failed to create chat room for party: %v", chatErr)
		}

		if p.RotationPool != nil {
			p.RotationPool.PartyID = id
			_, poolErr := CreateRotationPool(*p.RotationPool)
			if poolErr != nil {
				log.Printf("Warning: Failed to create rotation pool for party: %v", poolErr)
			}
		}
	}

	return id, err
}

func GetParty(id string) (Party, error) {
	var p Party
	query := `SELECT id, host_id, title, description, party_photos, start_time, duration_hours, status,
		is_location_revealed, address, city, geo_lat, geo_lon, max_capacity, current_guest_count,
		auto_lock_on_full, vibe_tags, rules, chat_room_id,
		created_at, updated_at, thumbnail FROM parties WHERE id = $1`

	err := db.QueryRow(context.Background(), query, id).Scan(
		&p.ID, &p.HostID, &p.Title, &p.Description, &p.PartyPhotos, &p.StartTime, &p.DurationHours,
		&p.Status, &p.IsLocationRevealed, &p.Address, &p.City, &p.GeoLat, &p.GeoLon,
		&p.MaxCapacity, &p.CurrentGuestCount, &p.AutoLockOnFull, &p.VibeTags,
		&p.Rules, &p.ChatRoomID, &p.CreatedAt, &p.UpdatedAt, &p.Thumbnail,
	)
	return p, err
}

func UpdateParty(p Party) error {
	query := `UPDATE parties SET 
		title=$1, description=$2, status=$3, is_location_revealed=$4, address=$5,
		city=$6, max_capacity=$7, thumbnail=$8, updated_at=NOW()
		WHERE id=$9`
	_, err := db.Exec(context.Background(), query, p.Title, p.Description, p.Status,
		p.IsLocationRevealed, p.Address, p.City, p.MaxCapacity, p.Thumbnail, p.ID)
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

func GetApplicantsForParty(partyID string) ([]map[string]interface{}, error) {
	query := `SELECT pa.party_id, pa.user_id, pa.status, pa.applied_at,
		u.real_name, u.profile_photos, u.age, u.elo_score, COALESCE(u.bio, ''), u.trust_score, COALESCE(u.thumbnail, '')
		FROM party_applications pa
		JOIN users u ON pa.user_id = u.id
		WHERE pa.party_id = $1
		ORDER BY u.elo_score DESC`

	rows, err := db.Query(context.Background(), query, partyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var apps []map[string]interface{}
	for rows.Next() {
		var appID, userID, status, realName, bio string
		var appliedAt time.Time
		var profilePhotos []string
		var age int
		var eloScore, trustScore float64
		var thumbnail string

		err := rows.Scan(&appID, &userID, &status, &appliedAt, &realName, &profilePhotos, &age, &eloScore, &bio, &trustScore, &thumbnail)
		if err != nil {
			return nil, err
		}

		apps = append(apps, map[string]interface{}{
			"PartyID":   appID,
			"UserID":    userID,
			"Status":    status,
			"AppliedAt": appliedAt,
			"User": map[string]interface{}{
				"ID":            userID,
				"RealName":      realName,
				"ProfilePhotos": profilePhotos,
				"Age":           age,
				"EloScore":      eloScore,
				"Bio":           bio,
				"TrustScore":    trustScore,
				"Thumbnail":     thumbnail,
			},
		})
	}
	return apps, nil
}

// GetAcceptedApplicants returns users who have been accepted to a party
func GetAcceptedApplicants(partyID string) ([]map[string]interface{}, error) {
	query := `SELECT pa.party_id, pa.user_id, pa.status, pa.applied_at,
		u.real_name, u.profile_photos, u.age, u.elo_score, COALESCE(u.bio, ''), u.trust_score, COALESCE(u.thumbnail, '')
		FROM party_applications pa
		JOIN users u ON pa.user_id = u.id
		WHERE pa.party_id = $1 AND pa.status = 'ACCEPTED'
		ORDER BY u.elo_score DESC`

	rows, err := db.Query(context.Background(), query, partyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var apps []map[string]interface{}
	for rows.Next() {
		var appID, userID, status, realName, bio string
		var appliedAt time.Time
		var profilePhotos []string
		var age int
		var eloScore, trustScore float64
		var thumbnail string

		err := rows.Scan(&appID, &userID, &status, &appliedAt, &realName, &profilePhotos, &age, &eloScore, &bio, &trustScore, &thumbnail)
		if err != nil {
			return nil, err
		}

		apps = append(apps, map[string]interface{}{
			"PartyID":   appID,
			"UserID":    userID,
			"Status":    status,
			"AppliedAt": appliedAt,
			"User": map[string]interface{}{
				"ID":            userID,
				"RealName":      realName,
				"ProfilePhotos": profilePhotos,
				"Age":           age,
				"EloScore":      eloScore,
				"Bio":           bio,
				"TrustScore":    trustScore,
				"Thumbnail":     thumbnail,
			},
		})
	}
	return apps, nil
}

func UpdateApplicationStatus(partyID, userID, status string) error {
	tx, err := db.Begin(context.Background())
	if err != nil {
		return err
	}
	defer tx.Rollback(context.Background())

	_, err = tx.Exec(context.Background(),
		"UPDATE party_applications SET status = $1 WHERE party_id = $2 AND user_id = $3",
		status, partyID, userID)
	if err != nil {
		return err
	}

	if status == "ACCEPTED" {
		// Also add the user to the chat room participants
		_, err = tx.Exec(context.Background(),
			"UPDATE chat_rooms SET participant_ids = array_append(participant_ids, $1) WHERE party_id = $2 AND NOT ($1 = ANY(participant_ids))",
			userID, partyID)
		if err != nil {
			return err
		}
	}

	return tx.Commit(context.Background())
}

func CreateChatRoom(cr ChatRoom) (string, error) {
	query := `INSERT INTO chat_rooms (id, party_id, host_id, title, image_url, is_group, participant_ids) 
	          VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id`

	var id string
	err := db.QueryRow(context.Background(), query, cr.ID, cr.PartyID, cr.HostID, cr.Title, cr.ImageUrl, cr.IsGroup, cr.ParticipantIDs).Scan(&id)
	return id, err
}

func GetChatRoom(id string) (ChatRoom, error) {
	var cr ChatRoom
	var partyID, title, imageURL *string
	var partyStartTime *time.Time
	query := `
		SELECT cr.id, cr.party_id, cr.host_id, COALESCE(cr.title, p.title, '') as title, cr.image_url, cr.is_group, cr.participant_ids, cr.is_active, cr.created_at, p.start_time
		FROM chat_rooms cr
		LEFT JOIN parties p ON cr.party_id = p.id
		WHERE cr.id = $1`
	err := db.QueryRow(context.Background(), query, id).Scan(
		&cr.ID, &partyID, &cr.HostID, &title, &imageURL, &cr.IsGroup, &cr.ParticipantIDs, &cr.IsActive, &cr.CreatedAt, &partyStartTime,
	)
	if err == nil {
		if partyID != nil {
			cr.PartyID = *partyID
		}
		if title != nil {
			cr.Title = *title
		}
		if imageURL != nil {
			cr.ImageUrl = *imageURL
		}
		cr.PartyStartTime = partyStartTime
	}
	return cr, err
}

func GetChatRoomByParty(partyID string) (ChatRoom, error) {
	var cr ChatRoom
	var pID, title, imageURL *string
	var partyStartTime *time.Time
	query := `
		SELECT cr.id, cr.party_id, cr.host_id, COALESCE(cr.title, p.title, '') as title, cr.image_url, cr.is_group, cr.participant_ids, cr.is_active, cr.created_at, p.start_time
		FROM chat_rooms cr
		LEFT JOIN parties p ON cr.party_id = p.id
		WHERE cr.party_id = $1`
	err := db.QueryRow(context.Background(), query, partyID).Scan(
		&cr.ID, &pID, &cr.HostID, &title, &imageURL, &cr.IsGroup, &cr.ParticipantIDs, &cr.IsActive, &cr.CreatedAt, &partyStartTime,
	)
	if err == nil {
		if pID != nil {
			cr.PartyID = *pID
		}
		if title != nil {
			cr.Title = *title
		}
		if imageURL != nil {
			cr.ImageUrl = *imageURL
		}
		cr.PartyStartTime = partyStartTime
	}
	return cr, err
}

func GetChatRoomsForUser(userID string) ([]map[string]interface{}, error) {
	query := `
		SELECT cr.id, cr.party_id, cr.host_id, COALESCE(cr.title, p.title, '') as room_title, cr.image_url, cr.is_group, cr.participant_ids, cr.is_active, cr.created_at,
		       (SELECT content FROM chat_messages WHERE chat_id = cr.id ORDER BY created_at DESC LIMIT 1) as last_message_content,
		       (SELECT created_at FROM chat_messages WHERE chat_id = cr.id ORDER BY created_at DESC LIMIT 1) as last_message_at,
		       p.thumbnail as party_thumbnail,
		       (SELECT u.thumbnail FROM users u WHERE u.id = ANY(cr.participant_ids) AND u.id != $1 LIMIT 1) as dm_thumbnail,
		       p.title as p_title,
		       p.start_time as party_start_time
		FROM chat_rooms cr
		LEFT JOIN parties p ON cr.party_id = p.id
		WHERE $1::UUID = ANY(cr.participant_ids)
		ORDER BY last_message_at DESC NULLS LAST, cr.created_at DESC`

	rows, err := db.Query(context.Background(), query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var rooms []map[string]interface{}
	for rows.Next() {
		var id, hostID string
		var partyID, title, imageURL *string
		var isGroup, isActive bool
		var participantIDs []string
		var createdAt time.Time
		var lastMsgContent *string
		var lastMsgAt *time.Time
		var partyThumbnail, dmThumbnail *string
		var pTitle *string
		var partySTime *time.Time

		err := rows.Scan(&id, &partyID, &hostID, &title, &imageURL, &isGroup, &participantIDs, &isActive, &createdAt,
			&lastMsgContent, &lastMsgAt, &partyThumbnail, &dmThumbnail, &pTitle, &partySTime)
		if err != nil {
			return nil, err
		}

		room := map[string]interface{}{
			"ID":             id,
			"PartyID":        "",
			"HostID":         hostID,
			"Title":          "",
			"ImageUrl":       "",
			"IsGroup":        isGroup,
			"ParticipantIDs": participantIDs,
			"IsActive":       isActive,
			"CreatedAt":      createdAt,
			"RecentMessages": []interface{}{}, // Initial list empty
			"UnreadCount":    0,               // Placeholder
		}

		if partyID != nil {
			room["PartyID"] = *partyID
		}
		if title != nil {
			room["Title"] = *title
		}

		finalImageUrl := ""
		if imageURL != nil {
			finalImageUrl = *imageURL
		}

		// Prioritise thumbnails
		if isGroup && partyThumbnail != nil && *partyThumbnail != "" {
			finalImageUrl = *partyThumbnail
		} else if !isGroup && dmThumbnail != nil && *dmThumbnail != "" {
			finalImageUrl = *dmThumbnail
		}
		room["ImageUrl"] = finalImageUrl

		// Prioritize party title for group chats
		if isGroup && pTitle != nil && *pTitle != "" {
			room["Title"] = *pTitle
		}

		if partySTime != nil {
			room["StartTime"] = *partySTime
		}

		if lastMsgContent != nil {
			room["LastMessageContent"] = *lastMsgContent
		} else {
			room["LastMessageContent"] = "No messages yet"
		}
		if lastMsgAt != nil {
			room["LastMessageAt"] = *lastMsgAt
		}

		rooms = append(rooms, room)
	}
	return rooms, nil
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
	query := `SELECT m.id, m.sender_id, m.type, m.content, m.media_url, m.thumbnail_url, m.metadata, m.reply_to_id, m.created_at,
		u.real_name as sender_name, COALESCE(u.thumbnail, '') as sender_thumbnail
		FROM chat_messages m
		JOIN users u ON m.sender_id = u.id
		WHERE m.chat_id = $1 ORDER BY m.created_at DESC LIMIT $2`

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
		err := rows.Scan(&m.ID, &m.SenderID, &m.Type, &m.Content, &m.MediaURL, &m.ThumbnailURL, &meta, &replyID, &m.CreatedAt, &m.SenderName, &m.SenderThumbnail)
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

// GetDMsForUser returns direct message chats for a user (pair-wise DMs)
func GetDMsForUser(userID string) ([]map[string]interface{}, error) {
	query := `
		SELECT DISTINCT
			CASE WHEN c.participant_ids[1] = $1 THEN c.participant_ids[2] ELSE c.participant_ids[1] END as other_user_id,
			u.real_name as other_user_name, COALESCE(u.thumbnail, '') as other_user_thumbnail,
			(
				SELECT content FROM chat_messages 
				WHERE chat_id = c.id 
				ORDER BY created_at DESC LIMIT 1
			) as last_message,
			(
				SELECT created_at FROM chat_messages 
				WHERE chat_id = c.id 
				ORDER BY created_at DESC LIMIT 1
			) as last_message_at
		FROM chat_rooms c
		JOIN users u ON u.id = CASE WHEN c.participant_ids[1] = $1 THEN c.participant_ids[2] ELSE c.participant_ids[1] END
		WHERE c.is_group = false 
		  AND $1 = ANY(c.participant_ids)
		ORDER BY last_message_at DESC
	`

	rows, err := db.Query(context.Background(), query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var dms []map[string]interface{}
	for rows.Next() {
		var otherUserID, otherUserName, otherUserThumbnail, lastMessage string
		var lastMessageAt *time.Time

		err := rows.Scan(&otherUserID, &otherUserName, &otherUserThumbnail, &lastMessage, &lastMessageAt)
		if err != nil {
			return nil, err
		}

		dms = append(dms, map[string]interface{}{
			"OtherUserID":        otherUserID,
			"OtherUserName":      otherUserName,
			"OtherUserThumbnail": otherUserThumbnail,
			"LastMessage":        lastMessage,
			"LastMessageAt":      lastMessageAt,
		})
	}
	return dms, nil
}

// GetDMMessages returns messages between two users
func GetDMMessages(userID, otherUserID string, limit int) ([]ChatMessage, error) {
	// Generate the deterministic DM chat ID
	u1, u2 := userID, otherUserID
	if u1 > u2 {
		u1, u2 = u2, u1
	}
	dmChatID := u1 + "_" + u2

	return GetChatHistory(dmChatID, limit)
}

// DeleteMessage deletes a chat message
func DeleteMessage(messageID, userID string) error {
	// Only allow the sender to delete their own message
	_, err := db.Exec(context.Background(),
		"DELETE FROM chat_messages WHERE id = $1 AND sender_id = $2",
		messageID, userID)
	return err
}

// ==========================================
// NOTIFICATIONS
// ==========================================

// CreateNotification creates a new notification
func CreateNotification(n Notification) (string, error) {
	query := `INSERT INTO notifications (user_id, type, title, body, data) 
			  VALUES ($1, $2, $3, $4, $5) RETURNING id`
	var id string
	err := db.QueryRow(context.Background(), query, n.UserID, n.Type, n.Title, n.Body, n.Data).Scan(&id)
	return id, err
}

// GetNotifications returns notifications for a user
func GetNotifications(userID string, limit int) ([]Notification, error) {
	if limit <= 0 {
		limit = 20
	}
	query := `SELECT id, user_id, type, title, body, data, is_read, created_at 
			  FROM notifications WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2`

	rows, err := db.Query(context.Background(), query, userID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var notifs []Notification
	for rows.Next() {
		var n Notification
		err := rows.Scan(&n.ID, &n.UserID, &n.Type, &n.Title, &n.Body, &n.Data, &n.IsRead, &n.CreatedAt)
		if err != nil {
			return nil, err
		}
		notifs = append(notifs, n)
	}
	return notifs, nil
}

// MarkNotificationRead marks a notification as read
func MarkNotificationRead(notifID, userID string) error {
	_, err := db.Exec(context.Background(),
		"UPDATE notifications SET is_read = true WHERE id = $1 AND user_id = $2",
		notifID, userID)
	return err
}

// MarkAllNotificationsRead marks all notifications as read for a user
func MarkAllNotificationsRead(userID string) error {
	_, err := db.Exec(context.Background(),
		"UPDATE notifications SET is_read = true WHERE user_id = $1",
		userID)
	return err
}

// ==========================================
// USER SEARCH & BLOCKING
// ==========================================

// SearchUsers searches for users by name or handle
func SearchUsers(query string, limit int) ([]User, error) {
	if limit <= 0 {
		limit = 20
	}
	searchQuery := `%` + query + `%`
	sqlQuery := `SELECT id, real_name, profile_photos, age, bio, elo_score, trust_score, thumbnail
				FROM users 
				WHERE real_name ILIKE $1 OR instagram_handle ILIKE $1 OR x_handle ILIKE $1
				ORDER BY elo_score DESC LIMIT $2`

	rows, err := db.Query(context.Background(), sqlQuery, searchQuery, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var users []User
	for rows.Next() {
		var u User
		err := rows.Scan(&u.ID, &u.RealName, &u.ProfilePhotos, &u.Age, &u.Bio, &u.EloScore, &u.TrustScore, &u.Thumbnail)
		if err != nil {
			return nil, err
		}
		users = append(users, u)
	}
	return users, nil
}

// BlockUser blocks a user
func BlockUser(blockerID, blockedID string) error {
	query := `INSERT INTO blocked_users (blocker_id, blocked_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`
	_, err := db.Exec(context.Background(), query, blockerID, blockedID)
	return err
}

// UnblockUser unblocks a user
func UnblockUser(blockerID, blockedID string) error {
	query := `DELETE FROM blocked_users WHERE blocker_id = $1 AND blocked_id = $2`
	_, err := db.Exec(context.Background(), query, blockerID, blockedID)
	return err
}

// IsBlocked checks if user is blocked
func IsBlocked(blockerID, checkedID string) (bool, error) {
	var exists bool
	query := `SELECT EXISTS(SELECT 1 FROM blocked_users WHERE blocker_id = $1 AND blocked_id = $2)`
	err := db.QueryRow(context.Background(), query, blockerID, checkedID).Scan(&exists)
	return exists, err
}

// GetBlockedUsers returns list of blocked user IDs
func GetBlockedUsers(userID string) ([]string, error) {
	query := `SELECT blocked_id FROM blocked_users WHERE blocker_id = $1`
	rows, err := db.Query(context.Background(), query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var blockedIDs []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		blockedIDs = append(blockedIDs, id)
	}
	return blockedIDs, nil
}

// ==========================================
// REPORTING
// ==========================================

// ReportUser creates a user report
func ReportUser(reporterID, reportedID, reason, details string) error {
	query := `INSERT INTO user_reports (reporter_id, reported_id, reason, details) VALUES ($1, $2, $3, $4)`
	_, err := db.Exec(context.Background(), query, reporterID, reportedID, reason, details)
	return err
}

// ReportParty creates a party report
func ReportParty(reporterID, partyID, reason, details string) error {
	query := `INSERT INTO party_reports (reporter_id, party_id, reason, details) VALUES ($1, $2, $3, $4)`
	_, err := db.Exec(context.Background(), query, reporterID, partyID, reason, details)
	return err
}

// ==========================================
// PARTY ANALYTICS
// ==========================================

// GetPartyAnalytics returns analytics for a party
func GetPartyAnalytics(partyID string) (PartyAnalytics, error) {
	var analytics PartyAnalytics
	analytics.PartyID = partyID

	// Get application counts
	appQuery := `SELECT 
			COUNT(*) as total,
			SUM(CASE WHEN status = 'ACCEPTED' THEN 1 ELSE 0 END) as accepted,
			SUM(CASE WHEN status = 'PENDING' THEN 1 ELSE 0 END) as pending,
			SUM(CASE WHEN status = 'DECLINED' THEN 1 ELSE 0 END) as declined
			FROM party_applications WHERE party_id = $1`

	err := db.QueryRow(context.Background(), appQuery, partyID).Scan(
		&analytics.TotalApplications, &analytics.AcceptedCount,
		&analytics.PendingCount, &analytics.DeclinedCount)
	if err != nil {
		return analytics, err
	}

	// Get current guest count from party
	partyQuery := `SELECT current_guest_count FROM parties WHERE id = $1`
	err = db.QueryRow(context.Background(), partyQuery, partyID).Scan(&analytics.CurrentGuestCount)
	if err != nil {
		return analytics, err
	}

	return analytics, nil
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

// GetMyParties returns parties where user is host or has accepted application
func GetMyParties(userID string) ([]Party, error) {
	query := `
		SELECT id, host_id, title, description, party_photos, start_time, duration_hours, status,
		       is_location_revealed, address, city, geo_lat, geo_lon, max_capacity, current_guest_count,
		       auto_lock_on_full, vibe_tags, rules, chat_room_id, created_at, updated_at, thumbnail
		FROM parties
		WHERE host_id = $1
		   OR id IN (SELECT party_id FROM party_applications WHERE user_id = $1 AND status = 'ACCEPTED')
		ORDER BY created_at DESC
	`

	rows, err := db.Query(context.Background(), query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var parties []Party
	for rows.Next() {
		var p Party
		err := rows.Scan(
			&p.ID, &p.HostID, &p.Title, &p.Description, &p.PartyPhotos, &p.StartTime, &p.DurationHours,
			&p.Status, &p.IsLocationRevealed, &p.Address, &p.City, &p.GeoLat, &p.GeoLon,
			&p.MaxCapacity, &p.CurrentGuestCount, &p.AutoLockOnFull, &p.VibeTags,
			&p.Rules, &p.ChatRoomID, &p.CreatedAt, &p.UpdatedAt, &p.Thumbnail,
		)
		if err != nil {
			log.Printf("GetMyParties Scan Error: %v", err)
			continue
		}
		parties = append(parties, p)
	}
	return parties, nil
}
