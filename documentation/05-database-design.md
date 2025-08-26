# Database Design

## Current Implementation

**Status**: In-Memory Storage  
**Backend**: Go with in-memory maps and slices  
**Persistence**: None (data lost on server restart)

The current implementation uses in-memory data structures for rapid development and testing. This document outlines the current data models and future database architecture plans.

## Current Data Models

### 1. In-Memory Storage Structure

```go
// Global storage maps
var rooms = make(map[string]*Room)                    // roomName -> Room
var roomUsers = make(map[string]*RoomUser)            // socketId -> RoomUser  
var roomDrawings = make(map[string]*Drawing)          // roomName -> Drawing
```

### 2. Core Data Structures

#### Room Model
```go
type Room struct {
    Name                             string
    Participants                     map[string]*Participant  // userId -> Participant
    TurnQueue                        []*Participant
    CurrentDrawerTurnIndex           int8
    CurrentWord                      string
    TurnCount                        uint8
    ParticipantsWhoAnsweredCorrectly map[string]bool
    ActiveTimer                      *time.Timer
    IsGameStarted                    bool
}
```

#### Participant Model
```go
type Participant struct {
    UserId        string  `json:"userId"`
    Username      string  `json:"username"`
    UserAvatar    *string `json:"userAvatar"`
    IsLogged      bool    `json:"isLogged"`
    IsConnected   bool    `json:"isConnected"`
    Score         uint16  `json:"score"`
    PreviousOrder uint8   `json:"-"`
}
```

#### Drawing Model
```go
type Drawing struct {
    Strokes     []*Stroke
    UndoStack   []*Stroke
}

type Stroke struct {
    Points      []Offset
    Color       string
    StrokeWidth float64
    Tool        string
    IsFilled    bool
}

type Offset struct {
    Dx float64 `json:"dx"`
    Dy float64 `json:"dy"`
}
```

#### Message Models
```go
type Message struct {
    Icon     *string `json:"icon"`
    UserId   string  `json:"userId"`
    Username string  `json:"username"`
    Text     string  `json:"text"`
}

type Answer struct {
    Icon      *string `json:"icon"`
    UserId    string  `json:"userId"`
    Username  string  `json:"username"`
    Text      string  `json:"text"`
    IsCorrect bool    `json:"isCorrect"`
}
```

## Planned Database Architecture

### Technology Selection

**Primary Option**: PostgreSQL
- ACID compliance
- JSON support for flexible schemas
- Excellent Go integration
- Horizontal scaling capabilities

**Alternative Option**: MongoDB
- Document-oriented (natural JSON mapping)
- Flexible schema
- Real-time capabilities
- Easy scaling

### Database Schema (PostgreSQL)

#### 1. Users Table
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) NOT NULL,
    email VARCHAR(255) UNIQUE,
    avatar_url TEXT,
    firebase_uid VARCHAR(128) UNIQUE,
    is_logged BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    last_active TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX idx_users_username ON users(username);
```

#### 2. Rooms Table
```sql
CREATE TABLE rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    max_players INTEGER DEFAULT 4,
    min_players INTEGER DEFAULT 2,
    is_private BOOLEAN DEFAULT false,
    password_hash VARCHAR(255),
    created_by UUID REFERENCES users(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_rooms_name ON rooms(name);
CREATE INDEX idx_rooms_active ON rooms(is_active);
```

#### 3. Games Table
```sql
CREATE TABLE games (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID REFERENCES rooms(id) ON DELETE CASCADE,
    current_word VARCHAR(100),
    current_drawer_id UUID REFERENCES users(id),
    turn_count INTEGER DEFAULT 0,
    turn_duration INTEGER DEFAULT 60, -- seconds
    is_started BOOLEAN DEFAULT false,
    is_finished BOOLEAN DEFAULT false,
    started_at TIMESTAMP,
    finished_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_games_room_id ON games(room_id);
CREATE INDEX idx_games_active ON games(is_started, is_finished);
```

#### 4. Game Participants Table
```sql
CREATE TABLE game_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id UUID REFERENCES games(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    score INTEGER DEFAULT 0,
    turn_order INTEGER,
    is_connected BOOLEAN DEFAULT true,
    joined_at TIMESTAMP DEFAULT NOW(),
    left_at TIMESTAMP,
    
    UNIQUE(game_id, user_id)
);

CREATE INDEX idx_game_participants_game_id ON game_participants(game_id);
CREATE INDEX idx_game_participants_user_id ON game_participants(user_id);
```

#### 5. Drawings Table
```sql
CREATE TABLE drawings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id UUID REFERENCES games(id) ON DELETE CASCADE,
    turn_number INTEGER,
    strokes JSONB NOT NULL DEFAULT '[]',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_drawings_game_id ON drawings(game_id);
CREATE INDEX idx_drawings_turn ON drawings(game_id, turn_number);
```

#### 6. Messages Table
```sql
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id UUID REFERENCES games(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    message_type VARCHAR(20) DEFAULT 'chat', -- 'chat', 'system', 'answer'
    text TEXT NOT NULL,
    is_correct_answer BOOLEAN DEFAULT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_messages_game_id ON messages(game_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);
```

#### 7. Game Stats Table
```sql
CREATE TABLE game_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    games_played INTEGER DEFAULT 0,
    games_won INTEGER DEFAULT 0,
    total_score INTEGER DEFAULT 0,
    best_score INTEGER DEFAULT 0,
    words_guessed INTEGER DEFAULT 0,
    words_drawn INTEGER DEFAULT 0,
    average_guess_time DECIMAL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(user_id)
);

CREATE INDEX idx_game_stats_user_id ON game_stats(user_id);
```

### Data Access Layer (Go)

#### Database Connection
```go
package db

import (
    "database/sql"
    "time"
    
    _ "github.com/lib/pq"
)

type DB struct {
    *sql.DB
}

func New(databaseURL string) (*DB, error) {
    db, err := sql.Open("postgres", databaseURL)
    if err != nil {
        return nil, err
    }
    
    db.SetMaxOpenConns(25)
    db.SetMaxIdleConns(25)
    db.SetConnMaxLifetime(5 * time.Minute)
    
    return &DB{db}, nil
}
```

#### Repository Pattern
```go
type RoomRepository interface {
    Create(room *Room) error
    GetByName(name string) (*Room, error)
    Update(room *Room) error
    Delete(id string) error
    ListActive() ([]*Room, error)
}

type PostgresRoomRepository struct {
    db *DB
}

func (r *PostgresRoomRepository) Create(room *Room) error {
    query := `
        INSERT INTO rooms (name, max_players, min_players, is_private, created_by)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING id, created_at`
    
    return r.db.QueryRow(query, 
        room.Name, room.MaxPlayers, room.MinPlayers, 
        room.IsPrivate, room.CreatedBy).Scan(&room.ID, &room.CreatedAt)
}
```

#### Service Layer
```go
type GameService struct {
    roomRepo RoomRepository
    gameRepo GameRepository
    userRepo UserRepository
}

func (s *GameService) JoinRoom(userID, roomName string) (*Room, error) {
    room, err := s.roomRepo.GetByName(roomName)
    if err != nil {
        return nil, err
    }
    
    // Business logic for joining room
    participants, err := s.gameRepo.GetParticipants(room.ID)
    if err != nil {
        return nil, err
    }
    
    if len(participants) >= room.MaxPlayers {
        return nil, errors.New("room is full")
    }
    
    return room, s.gameRepo.AddParticipant(room.ID, userID)
}
```

## Caching Strategy

### Redis Integration
```go
type CacheService struct {
    client *redis.Client
}

func (c *CacheService) CacheRoomState(roomID string, state *RoomState) error {
    data, err := json.Marshal(state)
    if err != nil {
        return err
    }
    
    return c.client.Set(
        fmt.Sprintf("room:%s", roomID), 
        data, 
        15*time.Minute,
    ).Err()
}
```

### Cache Keys Strategy
```
room:{roomId}                    # Complete room state
game:{gameId}:drawing           # Current drawing data
game:{gameId}:participants      # Active participants
user:{userId}:session           # User session data
room:{roomId}:messages          # Recent messages (last 50)
```

## Migration Strategy

### Phase 1: Database Setup
1. **Setup PostgreSQL instance**
2. **Create database schema**
3. **Implement repository layer**
4. **Add database migrations**

### Phase 2: Hybrid Approach
1. **Keep in-memory for active games**
2. **Persist completed games to database**
3. **Cache frequently accessed data**
4. **Implement background sync**

### Phase 3: Full Database Integration
1. **Move all operations to database**
2. **Implement real-time subscriptions**
3. **Add comprehensive indexing**
4. **Optimize query performance**

## Data Consistency

### Transaction Management
```go
func (s *GameService) StartNewTurn(gameID string) error {
    tx, err := s.db.Begin()
    if err != nil {
        return err
    }
    defer tx.Rollback()
    
    // Update game state
    if err := s.updateGameTurn(tx, gameID); err != nil {
        return err
    }
    
    // Clear drawing
    if err := s.clearDrawing(tx, gameID); err != nil {
        return err
    }
    
    // Reset participant answers
    if err := s.resetAnswers(tx, gameID); err != nil {
        return err
    }
    
    return tx.Commit()
}
```

### Event Sourcing (Future Enhancement)
```sql
CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_id UUID NOT NULL,
    aggregate_type VARCHAR(50) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB NOT NULL,
    version INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);
```

## Performance Considerations

### Indexing Strategy
- **Primary Keys**: UUID with appropriate indexes
- **Foreign Keys**: All relationships indexed
- **Query Patterns**: Index common WHERE clauses
- **JSON Queries**: GIN indexes on JSONB columns

### Partitioning (Future)
```sql
-- Partition messages by month
CREATE TABLE messages_y2024m01 PARTITION OF messages
FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
```

### Read Replicas
- **Master**: Write operations
- **Replicas**: Read-heavy operations (stats, history)
- **Connection Pooling**: pgbouncer for connection management

## Backup and Recovery

### Automated Backups
```bash
# Daily full backup
pg_dump drawly_db > backup_$(date +%Y%m%d).sql

# Point-in-time recovery setup
archive_mode = on
archive_command = 'cp %p /backup/archive/%f'
```

### Data Retention
- **Active Games**: Unlimited retention
- **Completed Games**: 1 year retention
- **Messages**: 6 months retention
- **User Sessions**: 30 days retention

## Security Considerations

### Data Protection
- **Encryption at Rest**: Database encryption
- **Encryption in Transit**: SSL connections
- **PII Handling**: Minimal personal information storage
- **GDPR Compliance**: User data deletion capabilities

### Access Control
```sql
-- Create application user with limited permissions
CREATE USER drawly_app WITH PASSWORD 'secure_password';
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO drawly_app;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO drawly_app;
```

## Monitoring and Metrics

### Database Metrics
- **Connection Pool**: Active/idle connections
- **Query Performance**: Slow query log
- **Storage**: Disk usage and growth
- **Replication Lag**: Master-replica synchronization

### Application Metrics
- **Active Rooms**: Current room count
- **Concurrent Users**: Real-time user count
- **Game Duration**: Average game length
- **Drawing Complexity**: Stroke count per game