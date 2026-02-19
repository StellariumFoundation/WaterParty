package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"
)

func main() {
	// 1. Configuration (Use environment variables for production)
	connStr := getEnv("DATABASE_URL", "postgres://postgres:password@localhost:5432/partyapp?sslmode=disable")
	port := getEnv("PORT", "8080")

	// 2. Initialize Database (pgxpool from database.go)
	InitDB(connStr)
	log.Println("✅ Database connection pool established")

	// 3. Initialize Firebase
	InitFirebase()

	// 4. Initialize and start the WebSocket Hub
	hub := NewHub()
	go hub.Run()
	log.Println("✅ WebSocket Hub started (Room-based routing enabled)")

	// 5. Image/Asset Handler (Wrapped with Auth)
	http.HandleFunc("/assets/", AuthMiddleware(func(w http.ResponseWriter, r *http.Request) {
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

	// 6. High-Performance WebSocket Route (Wrapped with Auth)
	http.HandleFunc("/ws", AuthMiddleware(func(w http.ResponseWriter, r *http.Request) {
		ServeWs(hub, w, r)
	}))

	// 6. Health Check (Useful for Load Balancers/K8s)
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	// 7. Start Server with optimized timeouts
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