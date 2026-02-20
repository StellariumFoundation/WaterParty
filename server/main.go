package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"
)

func main() {
	// 1. Configuration (Use environment variables for production)
	connStr := strings.TrimSpace(getEnv("DATABASE_URL", ""))
	if connStr == "" {
		// Fallback to Render's internal database URL if DATABASE_URL is not set
		connStr = strings.TrimSpace(getEnv("INTERNAL_DATABASE_URL", ""))
	}

	if connStr == "" {
		log.Fatal("❌ DATABASE_URL or INTERNAL_DATABASE_URL environment variable is required")
	}
	port := strings.TrimSpace(getEnv("PORT", "8080"))

	// 2. Initialize Database (pgxpool from database.go)
	InitDB(connStr)
	log.Println("✅ Database connection pool established")

	// 3. Initialize and start the WebSocket Hub
	hub := NewHub()
	go hub.Run()
	log.Println("✅ WebSocket Hub started (Room-based routing enabled)")

	// 4. Wrap handlers with CORS middleware
	http.HandleFunc("/register", corsMiddleware(handleRegister))
	http.HandleFunc("/login", corsMiddleware(handleLogin))
	http.HandleFunc("/upload", corsMiddleware(handleUpload))

	// 5. Image/Asset Handler
	http.HandleFunc("/assets/", corsMiddleware(func(w http.ResponseWriter, r *http.Request) {
		// Only allow GET requests for assets
		if r.Method != http.MethodGet {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		hash := strings.TrimPrefix(r.URL.Path, "/assets/")
		if hash == "" {
			http.Error(w, "Asset hash required", http.StatusBadRequest)
			return
		}

		// Fetch binary data directly from Postgres (database.go)
		data, mime, err := GetAsset(hash)
		if err != nil {
			http.Error(w, "Asset not found", http.StatusNotFound)
			return
		}

		w.Header().Set("Content-Type", mime)
		w.Header().Set("Content-Length", fmt.Sprintf("%d", len(data)))
		w.Header().Set("Cache-Control", "public, max-age=31536000, immutable")
		w.Header().Set("ETag", hash)
		
		w.Write(data)
	}))

	// 6. High-Performance WebSocket Route
	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		ServeWs(hub, w, r)
	})

	// 7. Health Check (Useful for Load Balancers/K8s)
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	// 8. Start Server with optimized timeouts
	server := &http.Server{
		Addr:         ":" + port,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  120 * time.Second,
	}

	fmt.Printf("🚀 Party Ecosystem Server running on port %s\n", port)
	if err := server.ListenAndServe(); err != nil {
		log.Fatalf("Critical server error: %v", err)
	}
}

// Helper to handle environment variables
func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}

func handleRegister(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		User     User   `json:"user"`
		Password string `json:"password"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	hash, _ := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	
	u := req.User
	
	// Extrapolate Age and CreatedAt
	now := time.Now()
	if u.DateOfBirth != nil {
		dob := *u.DateOfBirth
		age := now.Year() - dob.Year()
		if now.YearDay() < dob.YearDay() {
			age--
		}
		u.Age = age
	}
	u.CreatedAt = &now

	walletJSON, _ := json.Marshal(u.WalletData)

	query := `INSERT INTO users (
		real_name, phone_number, email, password_hash, profile_photos, age, date_of_birth,
		height_cm, gender, looking_for, drinking_pref, smoking_pref, cannabis_pref,
		music_genres, top_artists, job_title, company, school, degree,
		instagram_handle, twitter_handle, linkedin_handle, x_handle, tiktok_handle,
		is_verified, trust_score, elo_score, parties_hosted, flake_count,
		wallet_data, location_lat, location_lon, bio, interests, last_active_at, created_at
	) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, 
		$19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36) 
	RETURNING id, last_active_at`

	var lastActiveAt time.Time
	err := db.QueryRow(context.Background(), query,
		u.RealName, u.PhoneNumber, u.Email, string(hash), u.ProfilePhotos, u.Age, u.DateOfBirth,
		u.HeightCm, u.Gender, u.LookingFor, u.DrinkingPref, u.SmokingPref, u.CannabisPref,
		u.MusicGenres, u.TopArtists, u.JobTitle, u.Company, u.School, u.Degree,
		u.InstagramHandle, u.TwitterHandle, u.LinkedinHandle, u.XHandle, u.TikTokHandle,
		u.IsVerified, u.TrustScore, u.EloScore, u.PartiesHosted, u.FlakeCount,
		walletJSON, u.LocationLat, u.LocationLon, u.Bio, u.Interests, now, now,
	).Scan(&u.ID, &lastActiveAt)

	if err != nil {
		http.Error(w, "Failed to register user: "+err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(u)
}

func handleLogin(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		Email    string `json:"email"`
		Password string `json:"password"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	user, hash, err := GetUserByEmail(req.Email)
	if err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(map[string]string{"error": "User not found"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(req.Password)); err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(map[string]string{"error": "Invalid credentials"})
		return
	}

	user.PasswordHash = "" // Clear hash before sending
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}

func corsMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS, PUT, DELETE")
		w.Header().Set("Access-Control-Allow-Headers", "Accept, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	}
}

func handleUpload(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// 10MB max
	r.ParseMultipartForm(10 << 20)

	file, header, err := r.FormFile("file")
	if err != nil {
		http.Error(w, "Invalid file", http.StatusBadRequest)
		return
	}
	defer file.Close()

	data := make([]byte, header.Size)
	file.Read(data)

	// Save to Postgres (database.go)
	hash, err := SaveAsset(data, header.Header.Get("Content-Type"))
	if err != nil {
		http.Error(w, "Upload failed: "+err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"hash": hash})
}
