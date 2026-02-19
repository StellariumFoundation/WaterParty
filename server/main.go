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
	connStr := getEnv("DATABASE_URL", "postgresql://waterpartydb_user:w1byijILsoURYmv8IaWRq8KAsudEkAuw@dpg-d6bnb73uibrs73clenig-a.oregon-postgres.render.com/waterpartydb")
	port := getEnv("PORT", "8080")

	// 2. Initialize Database (pgxpool from database.go)
	InitDB(connStr)
	log.Println("✅ Database connection pool established")

	// 3. Initialize and start the WebSocket Hub
	hub := NewHub()
	go hub.Run()
	log.Println("✅ WebSocket Hub started (Room-based routing enabled)")

	// 4. Image/Asset Handler
	http.HandleFunc("/assets/", func(w http.ResponseWriter, r *http.Request) {
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
	})

	// 5. High-Performance WebSocket Route
	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		ServeWs(hub, w, r)
	})

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