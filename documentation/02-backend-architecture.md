# Backend Architecture (Golang)

## Overview

The Drawly backend is built with **Go 1.23.1** and uses **Socket.IO** for real-time communication. The architecture follows a modular design with clear separation of concerns and efficient resource management.

## Directory Structure

```
backend-go/
├── src/
│   ├── main.go              # Application entry point
│   ├── types.go             # Core data structures
│   ├── room.go              # Room management logic
│   ├── room_game.go         # Game mechanics
│   ├── rooms_manager.go     # Room state management
│   ├── events.go            # Socket.IO event handlers
│   ├── client_emiters.go    # Client-side event emitters
│   ├── io_emiters.go        # Server-side event emitters
│   ├── drawing.go           # Drawing state management
│   ├── stroke.go            # Drawing stroke operations
│   └── helpers.go           # Utility functions
├── external/
│   └── socket.io/           # Custom Socket.IO library
├── tests/
│   └── room_leave_test.go   # Unit tests
├── go.mod                   # Go module definition
└── go.sum                   # Go module checksums
```

## Core Components

### 1. Server Setup (`main.go`)

```go
const Version = "0.51.5"

func main() {
    log.DEBUG = true
    io := setupServer()
    io.On("connection", handleConnection)
    handleGracefulShutdown(io)
}
```

**Key Features:**
- Socket.IO server with CORS configuration
- Graceful shutdown handling
- Connection state recovery
- Configurable ping intervals and timeouts

**Configuration:**
- **Port**: 5555
- **Ping Interval**: 300ms
- **Ping Timeout**: 200ms
- **Max HTTP Buffer**: 1MB
- **Connect Timeout**: 1s

### 2. Data Models (`types.go`)

#### Core Structures

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

type Room struct {
    Name                             string
    Participants                     map[string]*Participant
    TurnQueue                        []*Participant
    CurrentDrawerTurnIndex           int8
    CurrentWord                      string
    TurnCount                        uint8
    ParticipantsWhoAnsweredCorrectly map[string]bool
    ActiveTimer                      *time.Timer
    IsGameStarted                    bool
}

type Turn struct {
    Word                  string `json:"word"`
    Turn                  uint8  `json:"turn"`
    TotalDuration         uint32 `json:"totalDuration"`
    CurrentDrawerUserId   string `json:"currentDrawerUserId"`
    CurrentDrawerUsername string `json:"currentDrawerUsername"`
    IsGameStarted         bool   `json:"isGameStarted"`
}
```

#### Communication Models

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

type ErrorDTO struct {
    Message string          `json:"message"`
    Action  ErrorActionType `json:"action"`
}
```

### 3. Room Management (`room.go`)

#### Key Operations

**Participant Management:**
- `addParticipant(participant *Participant)`: Adds new player to room
- `removeParticipant(userId string)`: Removes player and adjusts turn queue
- `getParticipants() []*Participant`: Returns sorted participant list

**Game Flow:**
- `advanceTurn()`: Rotates to next connected drawer
- `getCurrentDrawer() *Participant`: Gets current drawing player
- `hasEveryoneAnsweredCorrectly() bool`: Checks round completion

**Scoring System:**
- `getCorrectAnswerRank(userId string) uint8`: Determines answer position
- `participantCorrectAnswer(userId string)`: Marks correct guess
- `resetCorrectAnswers()`: Clears answers for new round

#### Turn Management Logic

```go
func (r *Room) advanceTurn() {
    if len(r.TurnQueue) == 0 {
        return
    }
    
    r.TurnCount++
    startIdx := r.CurrentDrawerTurnIndex
    
    for {
        r.CurrentDrawerTurnIndex = (r.CurrentDrawerTurnIndex + 1) % int8(len(r.TurnQueue))
        currentDrawer := r.TurnQueue[r.CurrentDrawerTurnIndex]
        
        if currentDrawer.IsConnected {
            break
        }
        
        if r.CurrentDrawerTurnIndex == startIdx {
            r.CurrentDrawerTurnIndex = -1
            return
        }
    }
}
```

### 4. Event Handling (`events.go`)

#### Socket.IO Events

**Room Events:**
- `room:create` - Create new game room
- `room:join` - Join existing room with callback
- `room:leave` - Leave current room

**Drawing Events:**
- `drawing:stroke:start` - Begin new drawing stroke
- `drawing:stroke:lastPoints` - Update stroke points
- `drawing:clear` - Clear entire canvas
- `drawing:undo` - Undo last stroke
- `drawing:redo` - Redo undone stroke

**Chat Events:**
- `chat:message` - Send chat message
- `chat:answer:guess` - Submit answer guess

**Game Events:**
- `game:turns:start` - Start turn-based gameplay
- `game:ranking` - Request current scores

**Connection Events:**
- `disconnect` - Handle client disconnection

#### Event Handler Example

```go
func handleJoinRoom(io *socket.Server, client *socket.Socket, args ...interface{}) {
    // Extract and validate request data
    data, ok := args[0].(map[string]interface{})
    callback := args[1].(func([]interface{}, error))
    
    roomName := data["roomName"].(string)
    userId := data["userId"].(string)
    username := data["username"].(string)
    
    room, exists := rooms[roomName]
    if !exists {
        callback([]interface{}{map[string]interface{}{
            "success": false,
            "message": "Room does not exist",
        }}, nil)
        return
    }
    
    // Handle reconnection or new participant
    if participant, alreadyInRoom := room.Participants[userId]; alreadyInRoom {
        participant.IsConnected = true
        // ... reconnection logic
    } else {
        // ... new participant logic
    }
}
```

### 5. Drawing System (`drawing.go`, `stroke.go`)

#### Drawing State Management

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
}
```

**Operations:**
- `addStroke(stroke *Stroke)`: Add new drawing stroke
- `addStrokeLastPoints(points []Offset)`: Update stroke points
- `undo() *Stroke`: Remove last stroke, add to undo stack
- `redo() *Stroke`: Restore stroke from undo stack
- `clear()`: Remove all strokes

### 6. Game Timer System (`room_game.go`)

#### Turn Timer Management

```go
func startTurnTimer(io *socket.Server, roomName string, seconds int) {
    room := rooms[roomName]
    if room.ActiveTimer != nil {
        room.ActiveTimer.Stop()
    }
    
    // Advance turn and select new word
    room.advanceTurn()
    room.resetCorrectAnswers()
    room.CurrentWord = getRandomWord()
    
    // Clear drawing canvas
    if drawing, exists := roomDrawings[roomName]; exists {
        drawing.clear()
        emitDrawingClear(io, roomName)
    }
    
    // Emit new turn to all clients
    emitNewTurn(io, roomName, room)
    
    // Set timer for turn duration
    room.ActiveTimer = time.AfterFunc(time.Duration(seconds)*time.Second, func() {
        startTurnTimer(io, roomName, seconds)
    })
}
```

## Performance Optimizations

### Connection Management
- **Connection State Recovery**: Automatic reconnection with state preservation
- **Heartbeat System**: 300ms ping interval for connection monitoring
- **Graceful Disconnection**: 5-second grace period before participant removal

### Memory Management
- **Room Cleanup**: Automatic room deletion when empty
- **Timer Management**: Proper timer cancellation to prevent leaks
- **Resource Pooling**: Efficient map usage for lookups

### Scaling Considerations
- **In-Memory State**: Current implementation uses in-memory storage
- **Horizontal Scaling**: Architecture supports distributed deployment
- **Load Balancing**: Socket.IO sessions can be distributed

## Security Features

### Input Validation
- Type assertion for all incoming data
- Bounds checking for arrays and strings
- Error handling with proper client feedback

### CORS Configuration
```go
c.SetCors(&types.Cors{
    Origin:      "http://localhost:8081 http://localhost:8082 ...",
    Credentials: true,
    Headers:     []string{"Content-Type", "Authorization"},
})
```

### Error Handling
- Structured error responses with action hints
- Client-side error categorization
- Logging for debugging and monitoring

## API Constraints

### Room Limits
- **Minimum Players**: 2
- **Maximum Players**: 4
- **Room Name**: Minimum 3 characters
- **Username**: Minimum 3 characters

### Performance Limits
- **Max HTTP Buffer**: 1MB
- **Connect Timeout**: 1 second
- **Drawing Points**: Unlimited (with memory considerations)

## Testing Strategy

### Unit Tests
- Room leave functionality (`room_leave_test.go`)
- Core business logic validation
- Edge case handling

### Integration Tests
- Socket.IO event flow
- Multi-client scenarios
- Connection resilience

## Deployment Configuration

### Environment Requirements
- **Go Version**: 1.23.1+
- **Port**: 5555 (configurable)
- **Memory**: Minimum 256MB
- **CPU**: Single core sufficient for development

### Docker Support
```dockerfile
FROM golang:1.23.1-alpine
WORKDIR /app
COPY . .
RUN go mod download
RUN go build -o main src/main.go
EXPOSE 5555
CMD ["./main"]
```