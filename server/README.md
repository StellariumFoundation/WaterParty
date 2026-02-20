# WaterParty Server

The backend for WaterParty, a "Tinder for parties" application. This server handles user authentication, party discovery (swiping), real-time messaging, and crowdfunding for events.

## 🚀 Tech Stack

- **Language:** Go (Golang)
- **Database:** PostgreSQL (using `pgxpool` for high-performance connection pooling)
- **Real-time:** WebSockets (`gorilla/websocket`) with a custom Room-based Hub
- **Authentication:** Password hashing with `bcrypt`
- **Containerization:** Docker & Dockerfile included
- **Storage:** Internal DB-based binary asset storage (SHA256 indexed)

## 🏗 Architecture

The server follows a hybrid architecture combining traditional RESTful endpoints for stateless operations and a robust WebSocket-based system for real-time interactions.

### 1. Database Schema
The database uses PostgreSQL with UUIDs and JSONB for flexibility. Key tables include:
- `users`: Detailed profiles including social handles, vibe tags, and ELO scores.
- `assets`: Binary storage for photos (indexed by SHA256 hash to avoid duplicates).
- `parties`: Event metadata, location data, and slot requirements.
- `party_applications`: Tracks "swipes" and application statuses (Pending, Accepted, etc.).
- `chat_messages`: High-speed message storage with support for media and metadata.
- `crowdfunding`: Manages "Rotation Pools" for party funding.

### 2. WebSocket Hub (`websocket.go`)
A centralized `Hub` manages all active connections. It supports:
- **Global Broadcasts:** New party announcements.
- **Room-based Routing:** Private chat rooms for specific parties.
- **Private DMs:** Direct messaging between users using deterministic pair-wise IDs.
- **Event-driven Logic:** Handlers for `SWIPE`, `JOIN_ROOM`, `SEND_MESSAGE`, and `GET_FEED`.

### 3. REST API (`main.go`)
Exposes endpoints for:
- `/register` & `/login`: User lifecycle management.
- `/upload`: Multipart form upload for images, which are hashed and stored in the `assets` table.
- `/assets/{hash}`: High-performance asset serving with cache-control headers.
- `/health`: Service health checks.

## 🛠 Key Features

### Tinder-style Matching
Users can "swipe" on parties. A `SWIPE` event over WebSockets triggers a record in the `party_applications` table. If the host accepts, the user gets access to the party's private chat.

### Real-time Messaging
- **Party Chat:** Every party has a logical `ChatRoomID`.
- **Private DMs:** Secure one-on-one communication.
- **Asynchronous Persistence:** Messages are saved to the database in background goroutines to ensure the WebSocket loop remains non-blocking and ultra-responsive.

### Asset Management
Instead of relying on S3 or local storage, the server implements an internal content-addressable storage system within PostgreSQL.
- Files are hashed (SHA256).
- Duplicate uploads consume no extra space.
- Assets are served directly via the `/assets/` endpoint.

### Crowdfunding (Rotation Pools)
Parties can have an associated `RotationPool` where guests contribute funds to reach a target amount (e.g., for drinks, venue, or DJs).

## 📱 Frontend Highlights

- **Custom Frutiger Theme:** The Flutter application now utilizes a unified design system centered around the `Frutiger` font family.
- **Standardized Typography:** Implementation of `small`, `medium`, and `title` styles across all screens for a premium, consistent user experience.
- **Glassmorphic UI:** Extensive use of `WaterGlass` containers for a modern, immersive aesthetic.

## 🚦 Getting Started

### Prerequisites
- Go 1.21+
- PostgreSQL instance

### Environment Variables
- `DATABASE_URL`: Postgres connection string (Primary).
- `INTERNAL_DATABASE_URL`: Fallback for Render internal database connections.
- `PORT`: Server port (defaults to 8080).

### Run
```bash
go run .
```

### Docker
```bash
docker build -t waterparty-server .
docker run -p 8080:8080 -e DATABASE_URL=your_db_url waterparty-server
```
