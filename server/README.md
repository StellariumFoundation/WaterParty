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

## 📡 API Specification

### WebSocket Connection
```
ws://host:port/ws?uid={user_id}
```

All WebSocket messages use the following envelope format:
```json
{
  "Event": "EVENT_NAME",
  "Payload": { },
  "Token": "optional-auth-token"
}
```

---

### WebSocket Events

#### Party Management

| Event | Description | Payload |
|-------|-------------|---------|
| `GET_FEED` | Get parties around user | `{"Lat": 0.0, "Lon": 0.0, "RadiusKm": 50}` |
| `GET_MY_PARTIES` / `GET_MATCHED_PARTIES` | Get user's parties (host + accepted) | (none) |
| `GET_PARTY_DETAILS` | Get full party details | `{"PartyID": "uuid"}` |
| `CREATE_PARTY` | Create a new party | Party object |
| `UPDATE_PARTY` | Update party details | Party object with ID |
| `DELETE_PARTY` | Delete a party (host only) | `{"PartyID": "uuid"}` |
| `LEAVE_PARTY` | Leave/cancel application | `{"PartyID": "uuid"}` |

#### Applications

| Event | Description | Payload |
|-------|-------------|---------|
| `GET_APPLICANTS` | Get applicants for party | `{"PartyID": "uuid"}` |
| `UPDATE_APPLICATION` | Accept/reject applicant | `{"PartyID": "uuid", "UserID": "uuid", "Status": "ACCEPTED|DECLINED"}` |
| `GET_MATCHED_USERS` | Get accepted users for party | `{"PartyID": "uuid"}` |
| `APPLY_TO_PARTY` | Apply to join party | `{"PartyID": "uuid"}` |
| `REJECT_PARTY` | Reject/hide party | `{"PartyID": "uuid"}` |
| `UNMATCH_USER` | Remove user from party | `{"PartyID": "uuid", "UserID": "uuid"}` |
| `SWIPE` | Swipe on party | `{"PartyID": "uuid", "Direction": "right|left"}` |

#### Chat & Messaging

| Event | Description | Payload |
|-------|-------------|---------|
| `GET_CHATS` | Get all chat rooms | (none) |
| `GET_CHAT_HISTORY` | Get messages for room | `{"ChatID": "uuid", "Limit": 50}` |
| `SEND_MESSAGE` | Send message to room | ChatMessage object |
| `JOIN_ROOM` | Join a chat room | `{"RoomID": "uuid"}` |
| `GET_DMS` | Get DM conversations | (none) |
| `GET_DM_MESSAGES` | Get messages with user | `{"OtherUserID": "uuid", "Limit": 50}` |
| `SEND_DM` | Send direct message | `{"RecipientID": "uuid", "Content": "text"}` |
| `DELETE_DM_MESSAGE` | Delete own message | `{"MessageID": "uuid"}` |

#### User Management

| Event | Description | Payload |
|-------|-------------|---------|
| `GET_USER` | Get current user profile | (none) |
| `UPDATE_PROFILE` | Update user profile | User object |
| `DELETE_USER` | Delete own account | `{"UserID": "uuid"}` |

#### Fundraising

| Event | Description | Payload |
|-------|-------------|---------|
| `GET_FUNDRAISER_STATE` | Get party fundraiser status | `{"PartyID": "uuid"}` |
| `ADD_CONTRIBUTION` | Add to fundraiser | `{"PartyID": "uuid", "Amount": 10.00}` |

#### Notifications

| Event | Description | Payload |
|-------|-------------|---------|
| `GET_NOTIFICATIONS` | Get user notifications | (none) |
| `MARK_NOTIFICATION_READ` | Mark notification as read | `{"NotificationID": "uuid"}` |
| `MARK_ALL_NOTIFICATIONS_READ` | Mark all as read | (none) |

#### User Search & Blocking

| Event | Description | Payload |
|-------|-------------|---------|
| `SEARCH_USERS` | Search users by name/handle | `{"Query": "string", "Limit": 20}` |
| `BLOCK_USER` | Block a user | `{"UserID": "uuid"}` |
| `UNBLOCK_USER` | Unblock a user | `{"UserID": "uuid"}` |
| `GET_BLOCKED_USERS` | Get blocked user IDs | (none) |

#### Reporting

| Event | Description | Payload |
|-------|-------------|---------|
| `REPORT_USER` | Report a user | `{"UserID": "uuid", "Reason": "...", "Details": "..."}` |
| `REPORT_PARTY` | Report a party | `{"PartyID": "uuid", "Reason": "...", "Details": "..."}` |

#### Analytics

| Event | Description | Payload |
|-------|-------------|---------|
| `GET_PARTY_ANALYTICS` | Get party stats | `{"PartyID": "uuid"}` |
| `UPDATE_PARTY_STATUS` | Update party status | `{"PartyID": "uuid", "Status": "LIVE|COMPLETED|CANCELLED"}` |

---

### WebSocket Response Events

| Event | Description |
|-------|-------------|
| `FEED_UPDATE` | Parties around user |
| `MY_PARTIES` | User's parties |
| `PARTY_DETAILS` | Full party object |
| `PARTY_CREATED` | Created party confirmation |
| `PARTY_UPDATED` | Updated party object |
| `PARTY_DELETED` | Deletion confirmation |
| `PARTY_LEFT` | Leave confirmation |
| `APPLICANTS_LIST` | Party applicants |
| `MATCHED_USERS` | Accepted users |
| `APPLICATION_SUBMITTED` | Application confirmation |
| `APPLICATION_UPDATED` | Status change notification |
| `USER_UNMATCHED` | Unmatch confirmation |
| `CHATS_LIST` | User's chat rooms |
| `CHAT_HISTORY` | Messages array |
| `NEW_MESSAGE` | Incoming message |
| `DMS_LIST` | DM conversations |
| `DM_MESSAGES` | DM message array |
| `MESSAGE_DELETED` | Deletion confirmation |
| `PROFILE_UPDATED` | User object |
| `USER_DELETED` | Deletion confirmation |
| `FUNDRAISER_STATE` | Fundraiser object |
| `FUNDRAISER_UPDATED` | Updated fundraiser |
| `NOTIFICATIONS_LIST` | Array of notifications |
| `NOTIFICATION_MARKED_READ` | Marked read confirmation |
| `ALL_NOTIFICATIONS_MARKED_READ` | All marked read confirmation |
| `USERS_SEARCH_RESULTS` | Array of users |
| `USER_BLOCKED` | Block confirmation |
| `USER_UNBLOCKED` | Unblock confirmation |
| `BLOCKED_USERS_LIST` | Array of blocked user IDs |
| `USER_REPORTED` | Report confirmation |
| `PARTY_REPORTED` | Report confirmation |
| `PARTY_ANALYTICS` | Party analytics object |
| `PARTY_STATUS_UPDATED` | Updated party with new status |
| `ERROR` | Error message |

---

### HTTP REST Endpoints

| Method | Endpoint | Description | Body |
|--------|----------|-------------|------|
| POST | `/register` | Register new user | `{"user": {...}, "password": "..."}` |
| POST | `/login` | User login | `{"email": "...", "password": "..."}` |
| GET | `/profile` | Get user profile | `?id={user_id}` |
| POST | `/upload` | Upload image | Multipart form |
| GET | `/assets/{hash}` | Serve asset | (none) |
| GET | `/health` | Health check | (none) |

---

### Data Models

#### Party
```json
{
  "ID": "uuid",
  "HostID": "uuid",
  "Title": "string",
  "Description": "string",
  "PartyPhotos": ["hash1", "hash2"],
  "StartTime": "ISO8601",
  "DurationHours": 2,
  "Status": "OPEN|LOCKED|LIVE|COMPLETED|CANCELLED",
  "IsLocationRevealed": false,
  "Address": "string",
  "City": "string",
  "GeoLat": 0.0,
  "GeoLon": 0.0,
  "MaxCapacity": 10,
  "CurrentGuestCount": 0,
  "AutoLockOnFull": false,
  "VibeTags": ["tag1"],
  "Rules": ["rule1"],
  "RotationPool": {...},
  "ChatRoomID": "uuid",
  "Thumbnail": "hash",
  "CreatedAt": "ISO8601",
  "UpdatedAt": "ISO8601"
}
```

#### User
```json
{
  "ID": "uuid",
  "RealName": "string",
  "Email": "string",
  "ProfilePhotos": ["hash1"],
  "Age": 25,
  "HeightCm": 170,
  "Gender": "string",
  "DrinkingPref": "string",
  "SmokingPref": "string",
  "TopArtists": ["artist1"],
  "JobTitle": "string",
  "Company": "string",
  "EloScore": 1200.0,
  "TrustScore": 95.5,
  "LocationLat": 0.0,
  "LocationLon": 0.0,
  "Bio": "string",
  "Thumbnail": "hash"
}
```

#### ChatMessage
```json
{
  "ID": "uuid",
  "ChatID": "uuid",
  "SenderID": "uuid",
  "Type": "TEXT|IMAGE|VIDEO|AUDIO|SYSTEM|AI|PAYMENT",
  "Content": "string",
  "MediaURL": "hash",
  "ThumbnailURL": "hash",
  "CreatedAt": "ISO8601",
  "SenderName": "string",
  "SenderThumbnail": "hash"
}
```

#### Notification
```json
{
  "ID": "uuid",
  "UserID": "uuid",
  "Type": "string",
  "Title": "string",
  "Body": "string",
  "Data": "json-string",
  "IsRead": false,
  "CreatedAt": "ISO8601"
}
```

#### PartyAnalytics
```json
{
  "PartyID": "uuid",
  "TotalViews": 0,
  "TotalApplications": 0,
  "AcceptedCount": 0,
  "PendingCount": 0,
  "DeclinedCount": 0,
  "CurrentGuestCount": 0
}
```
