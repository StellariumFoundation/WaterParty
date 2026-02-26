package main

import (
	"context"
	"fmt"
	"os"
	"strings"

	"github.com/jackc/pgx/v5"
)

func Migrate() {
	fmt.Println("🗄️  Database Migration Script")
	fmt.Println("==============================")

	// Get DATABASE_URL from environment
	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		fmt.Println("❌ Error: DATABASE_URL environment variable not set")
		os.Exit(1)
	}

	fmt.Printf("📡 Connecting to database...\n")

	// Connect to database
	conn, err := pgx.Connect(context.Background(), databaseURL)
	if err != nil {
		fmt.Printf("❌ Failed to connect to database: %v\n", err)
		os.Exit(1)
	}
	defer conn.Close(context.Background())

	fmt.Printf("✅ Connected successfully!\n\n")

	// Migration: Convert NULL text values to empty strings for users table
	fmt.Println("🔄 Converting NULL values to empty strings in users table...")
	nullColumns := []string{"real_name", "phone_number", "gender", "drinking_pref", "smoking_pref",
		"job_title", "company", "school", "degree", "instagram_handle",
		"linkedin_handle", "x_handle", "tiktok_handle", "bio", "thumbnail"}
	for _, col := range nullColumns {
		updateSQL := fmt.Sprintf("UPDATE users SET %s = '' WHERE %s IS NULL", col, col)
		_, err = conn.Exec(context.Background(), updateSQL)
		if err != nil {
			fmt.Printf("   ⚠️  Warning: Could not update %s: %v\n", col, err)
		} else {
			fmt.Printf("   ✅ Updated %s\n", col)
		}
	}

	// Define expected schema - tables and their columns
	// Format: tableName -> columnName -> columnType
	schema := map[string]map[string]string{
		"users": {
			"real_name":        "TEXT",
			"phone_number":     "TEXT",
			"email":            "TEXT",
			"password_hash":    "TEXT",
			"profile_photos":   "TEXT[] DEFAULT '{}'",
			"age":              "INTEGER",
			"date_of_birth":    "TIMESTAMP WITH TIME ZONE",
			"height_cm":        "INTEGER",
			"gender":           "TEXT",
			"drinking_pref":    "TEXT",
			"smoking_pref":     "TEXT",
			"top_artists":      "TEXT[] DEFAULT '{}'",
			"job_title":        "TEXT",
			"company":          "TEXT",
			"school":           "TEXT",
			"degree":           "TEXT",
			"instagram_handle": "TEXT",
			"linkedin_handle":  "TEXT",
			"x_handle":         "TEXT",
			"tiktok_handle":    "TEXT",
			"is_verified":      "BOOLEAN DEFAULT FALSE",
			"trust_score":      "DOUBLE PRECISION DEFAULT 0.0",
			"elo_score":        "DOUBLE PRECISION DEFAULT 0.0",
			"parties_hosted":   "INTEGER DEFAULT 0",
			"flake_count":      "INTEGER DEFAULT 0",
			"wallet_data":      "JSONB DEFAULT '{}'",
			"location_lat":     "DOUBLE PRECISION",
			"location_lon":     "DOUBLE PRECISION",
			"bio":              "TEXT",
			"updated_at":       "TIMESTAMP WITH TIME ZONE DEFAULT NOW()",
			"created_at":       "TIMESTAMP WITH TIME ZONE DEFAULT NOW()",
			"thumbnail":        "TEXT",
		},
		"parties": {
			"host_id":              "UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE",
			"title":                "TEXT NOT NULL",
			"description":          "TEXT",
			"party_photos":         "TEXT[] DEFAULT '{}'",
			"start_time":           "TIMESTAMP WITH TIME ZONE NOT NULL",
			"duration_hours":       "INTEGER DEFAULT 2",
			"status":               "TEXT NOT NULL DEFAULT 'OPEN'",
			"is_location_revealed": "BOOLEAN DEFAULT FALSE",
			"address":              "TEXT",
			"city":                 "TEXT",
			"geo_lat":              "DOUBLE PRECISION",
			"geo_lon":              "DOUBLE PRECISION",
			"max_capacity":         "INTEGER DEFAULT 0",
			"current_guest_count":  "INTEGER DEFAULT 0",
			"auto_lock_on_full":    "BOOLEAN DEFAULT FALSE",
			"vibe_tags":            "TEXT[] DEFAULT '{}'",
			"rules":                "TEXT[] DEFAULT '{}'",
			"chat_room_id":         "UUID",
			"thumbnail":            "TEXT",
		},
		"party_applications": {
			"party_id":   "UUID NOT NULL REFERENCES parties(id) ON DELETE CASCADE",
			"user_id":    "UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE",
			"status":     "TEXT NOT NULL DEFAULT 'PENDING'",
			"applied_at": "TIMESTAMP WITH TIME ZONE DEFAULT NOW()",
		},
		"crowdfunding": {
			"party_id":       "UUID UNIQUE NOT NULL REFERENCES parties(id) ON DELETE CASCADE",
			"target_amount":  "DOUBLE PRECISION DEFAULT 0.0",
			"current_amount": "DOUBLE PRECISION DEFAULT 0.0",
			"currency":       "TEXT DEFAULT 'USD'",
			"contributors":   "JSONB DEFAULT '[]'",
			"is_funded":      "BOOLEAN DEFAULT FALSE",
		},
		"chat_rooms": {
			"party_id":        "UUID REFERENCES parties(id) ON DELETE CASCADE",
			"host_id":         "UUID NOT NULL REFERENCES users(id)",
			"title":           "TEXT",
			"image_url":       "TEXT",
			"is_group":        "BOOLEAN DEFAULT TRUE",
			"participant_ids": "UUID[] DEFAULT '{}'",
			"is_active":       "BOOLEAN DEFAULT TRUE",
			"created_at":      "TIMESTAMP WITH TIME ZONE DEFAULT NOW()",
		},
		"chat_messages": {
			"chat_id":       "UUID NOT NULL",
			"sender_id":     "UUID NOT NULL REFERENCES users(id)",
			"type":          "TEXT NOT NULL DEFAULT 'TEXT'",
			"content":       "TEXT",
			"media_url":     "TEXT",
			"thumbnail_url": "TEXT",
			"metadata":      "JSONB DEFAULT '{}'",
			"reply_to_id":   "UUID",
			"created_at":    "TIMESTAMP WITH TIME ZONE DEFAULT NOW()",
		},
		"assets": {
			"hash":       "TEXT PRIMARY KEY",
			"data":       "BYTEA",
			"mime_type":  "TEXT",
			"created_at": "TIMESTAMP WITH TIME ZONE DEFAULT NOW()",
		},
		"blocked_users": {
			"blocker_id": "UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE",
			"blocked_id": "UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE",
			"created_at": "TIMESTAMP WITH TIME ZONE DEFAULT NOW()",
		},
		"user_reports": {
			"reporter_id": "UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE",
			"reported_id": "UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE",
			"reason":      "TEXT NOT NULL",
			"details":     "TEXT",
			"created_at":  "TIMESTAMP WITH TIME ZONE DEFAULT NOW()",
		},
		"party_reports": {
			"reporter_id": "UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE",
			"party_id":    "UUID NOT NULL REFERENCES parties(id) ON DELETE CASCADE",
			"reason":      "TEXT NOT NULL",
			"details":     "TEXT",
			"created_at":  "TIMESTAMP WITH TIME ZONE DEFAULT NOW()",
		},
		"notifications": {
			"user_id":    "UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE",
			"type":       "TEXT NOT NULL",
			"title":      "TEXT NOT NULL",
			"body":       "TEXT",
			"data":       "TEXT",
			"is_read":    "BOOLEAN DEFAULT FALSE",
			"created_at": "TIMESTAMP WITH TIME ZONE DEFAULT NOW()",
		},
	}

	totalMigrations := 0
	migrationsPerformed := []string{}

	// Process each table
	for tableName, columns := range schema {
		fmt.Printf("\n📋 Checking table: %s\n", tableName)

		// Check if table exists
		var tableExists bool
		err := conn.QueryRow(context.Background(),
			"SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = $1)",
			tableName).Scan(&tableExists)

		if err != nil {
			fmt.Printf("   ⚠️  Error checking table: %v\n", err)
			continue
		}

		if !tableExists {
			fmt.Printf("   ❌ Table does not exist - creating table...\n")
			// Create table with all columns
			var colDefs []string
			for colName, colType := range columns {
				colDefs = append(colDefs, fmt.Sprintf("%s %s", colName, colType))
			}
			createSQL := fmt.Sprintf("CREATE TABLE IF NOT EXISTS %s (%s)", tableName, strings.Join(colDefs, ", "))
			_, err = conn.Exec(context.Background(), createSQL)
			if err != nil {
				fmt.Printf("   ❌ Failed to create table: %v\n", err)
			} else {
				fmt.Printf("   ✅ Table created with %d columns\n", len(columns))
				totalMigrations++
				migrationsPerformed = append(migrationsPerformed, fmt.Sprintf("Created table %s", tableName))
			}
			continue
		}

		fmt.Printf("   ✓ Table exists - checking columns...\n")

		// Get existing columns
		rows, err := conn.Query(context.Background(),
			"SELECT column_name FROM information_schema.columns WHERE table_name = $1",
			tableName)
		if err != nil {
			fmt.Printf("   ⚠️  Error getting columns: %v\n", err)
			continue
		}

		existingCols := make(map[string]bool)
		for rows.Next() {
			var colName string
			rows.Scan(&colName)
			existingCols[colName] = true
		}
		rows.Close()

		// Check each expected column
		for colName, colType := range columns {
			if existingCols[colName] {
				continue // Column exists, skip
			}

			// Add missing column
			fmt.Printf("   ➕ Adding missing column: %s (%s)\n", colName, colType)
			alterSQL := fmt.Sprintf("ALTER TABLE %s ADD COLUMN IF NOT EXISTS %s %s",
				tableName, colName, colType)

			_, err = conn.Exec(context.Background(), alterSQL)
			if err != nil {
				fmt.Printf("   ❌ Failed to add column %s: %v\n", colName, err)
			} else {
				fmt.Printf("   ✅ Added column: %s\n", colName)
				totalMigrations++
				migrationsPerformed = append(migrationsPerformed,
					fmt.Sprintf("Added column %s.%s", tableName, colName))
			}
		}
	}

	// Drop end_time column from parties table
	err = dropEndTimeColumnFromParties(conn)
	if err != nil {
		fmt.Printf("   ⚠️  Error dropping end_time column: %v\n", err)
	}

	// Create indexes if they don't exist
	fmt.Println("\n📊 Checking indexes...")
	indexes := []string{
		"CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)",
		"CREATE INDEX IF NOT EXISTS idx_parties_status ON parties(status)",
		"CREATE INDEX IF NOT EXISTS idx_parties_host_id ON parties(host_id)",
		"CREATE INDEX IF NOT EXISTS idx_chat_messages_chat_id ON chat_messages(chat_id)",
		"CREATE INDEX IF NOT EXISTS idx_assets_hash ON assets(hash)",
	}

	for _, idxSQL := range indexes {
		_, err = conn.Exec(context.Background(), idxSQL)
		if err != nil {
			// Index might already exist or have issues, just log
			fmt.Printf("   ⚠️  Index issue: %v\n", err)
		} else {
			idxName := extractIndexName(idxSQL)
			fmt.Printf("   ✅ Index: %s\n", idxName)
			totalMigrations++
			migrationsPerformed = append(migrationsPerformed, fmt.Sprintf("Created index %s", idxName))
		}
	}

	// Summary
	fmt.Println("\n" + strings.Repeat("=", 30))
	fmt.Println("📊 MIGRATION SUMMARY")
	fmt.Println(strings.Repeat("=", 30))

	if totalMigrations == 0 {
		fmt.Println("✅ No migrations needed - database is up to date!")
	} else {
		fmt.Printf("✅ Completed %d migrations:\n", totalMigrations)
		for i, m := range migrationsPerformed {
			fmt.Printf("   %d. %s\n", i+1, m)
		}
	}

	fmt.Println("\n🗑️  Deleting migration script in 3 seconds...")
	fmt.Println("(Press Ctrl+C to cancel if needed)")

	// Small delay to show message

	if err != nil {
		fmt.Printf("⚠️  Could not delete self: %v\n", err)
		fmt.Println("Please manually delete the migration script.")
	} else {
		fmt.Println("✅ Script deleted successfully!")
	}
}

func extractIndexName(sql string) string {
	parts := strings.Split(sql, " ")
	if len(parts) >= 3 {
		return parts[2]
	}
	return sql
}

// dropEndTimeColumnFromParties drops the end_time column from the parties table
func dropEndTimeColumnFromParties(conn *pgx.Conn) error {
	fmt.Println("\n🗑️  Dropping end_time column from parties table...")

	// First check if the column exists
	var columnExists bool
	err := conn.QueryRow(context.Background(),
		"SELECT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'parties' AND column_name = 'end_time')").Scan(&columnExists)

	if err != nil {
		return fmt.Errorf("error checking if end_time column exists: %w", err)
	}

	if !columnExists {
		fmt.Println("   ℹ️  end_time column does not exist, skipping")
		return nil
	}

	// Drop the column
	_, err = conn.Exec(context.Background(), "ALTER TABLE parties DROP COLUMN IF EXISTS end_time")
	if err != nil {
		return fmt.Errorf("failed to drop end_time column: %w", err)
	}

	fmt.Println("   ✅ Dropped end_time column from parties table")
	return nil
}
