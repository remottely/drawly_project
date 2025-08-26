# API Documentation - Socket.IO Events

## Overview

The Drawly application uses **Socket.IO** for real-time communication between the Flutter frontend and Go backend. All communication is event-based with structured JSON payloads.

## Connection Configuration

### Client Configuration (Flutter)
```dart
IO.Socket socket = IO.io('http://localhost:5555', <String, dynamic>{
  'transports': ['websocket'],
  'autoConnect': false,
  'timeout': 1000,
});
```

### Server Configuration (Go)
```go
c.SetCors(&types.Cors{
    Origin:      "http://localhost:8081 http://localhost:8082 ...",
    Credentials: true,
    Headers:     []string{"Content-Type", "Authorization"},
})
c.SetPingInterval(300 * time.Millisecond)
c.SetPingTimeout(200 * time.Millisecond)
```

## Room Management Events

### 1. Create Room

**Event**: `room:create`  
**Direction**: Client → Server  
**Purpose**: Create a new game room

**Payload**:
```json
{
  "roomName": "string" // minimum 3 characters
}
```

**Server Response**: None (fire-and-forget)

**Server Emits**: Updates room list to all clients

---

### 2. Join Room

**Event**: `room:join`  
**Direction**: Client → Server  
**Purpose**: Join an existing room or reconnect to a room

**Payload**:
```json
{
  "roomName": "string",
  "userId": "string",
  "username": "string", // minimum 3 characters
  "userAvatar": "string|null", // optional avatar path
  "isLogged": "boolean"
}
```

**Server Response** (with acknowledgment):
```json
{
  "success": "boolean",
  "message": "string", // error message if success is false
  "turn": "number", // current turn number
  "isGameStarted": "boolean",
  "currentDrawerUserId": "string"
}
```

**Server Emits**: 
- `room:participants:update` to room
- `chat:message` (join notification) to room
- `drawing:state` (current drawing) to joining client

---

### 3. Leave Room

**Event**: `room:leave`  
**Direction**: Client → Server  
**Purpose**: Leave current room

**Payload**:
```json
{
  "roomName": "string",
  "userId": "string",
  "username": "string",
  "userAvatar": "string|null",
  "isLogged": "boolean"
}
```

**Server Response**: None

**Server Emits**: 
- `room:participants:update` to room
- Removes room if empty

---

## Drawing Events

### 1. Start Stroke

**Event**: `drawing:stroke:start`  
**Direction**: Client → Server  
**Purpose**: Begin a new drawing stroke

**Payload**:
```json
{
  "roomName": "string",
  "stroke": {
    "points": [
      {"dx": "number", "dy": "number"}
    ],
    "color": "string", // hex color
    "strokeWidth": "number",
    "tool": "string", // "brush", "eraser", "line", "circle", etc.
    "isFilled": "boolean"
  }
}
```

**Server Broadcasts**: Same payload to all room clients except sender

---

### 2. Stroke Last Points

**Event**: `drawing:stroke:lastPoints`  
**Direction**: Client → Server  
**Purpose**: Update stroke with additional points

**Payload**:
```json
{
  "roomName": "string",
  "strokeLastPoints": [
    {"dx": "number", "dy": "number"},
    {"dx": "number", "dy": "number"}
  ]
}
```

**Server Broadcasts**: Same payload to all room clients except sender

---

### 3. Clear Drawing

**Event**: `drawing:clear`  
**Direction**: Client → Server  
**Purpose**: Clear entire drawing canvas

**Payload**:
```json
{
  "roomName": "string"
}
```

**Server Broadcasts**: `drawing:clear` (no payload) to all room clients

---

### 4. Undo Drawing

**Event**: `drawing:undo`  
**Direction**: Client → Server  
**Purpose**: Undo last drawing stroke

**Payload**:
```json
{
  "roomName": "string"
}
```

**Server Broadcasts**:
```json
{
  "stroke": {
    // stroke object that was undone
  }
}
```

---

### 5. Redo Drawing

**Event**: `drawing:redo`  
**Direction**: Client → Server  
**Purpose**: Redo previously undone stroke

**Payload**:
```json
{
  "roomName": "string"
}
```

**Server Broadcasts**:
```json
{
  "stroke": {
    // stroke object that was redone
  }
}
```

---

## Chat Events

### 1. Send Message

**Event**: `chat:message`  
**Direction**: Client → Server  
**Purpose**: Send a chat message to the room

**Payload**:
```json
{
  "roomName": "string",
  "userId": "string",
  "username": "string",
  "text": "string"
}
```

**Server Broadcasts**:
```json
{
  "icon": "string|null", // optional icon ("info", etc.)
  "userId": "string",
  "username": "string",
  "text": "string"
}
```

---

### 2. Guess Answer

**Event**: `chat:answer:guess`  
**Direction**: Client → Server  
**Purpose**: Submit an answer guess during the game

**Payload**:
```json
{
  "roomName": "string",
  "userId": "string",
  "username": "string",
  "text": "string" // the guessed word
}
```

**Server Broadcasts**:
```json
{
  "icon": "string|null", // "check" if correct, null if incorrect
  "userId": "string",
  "username": "string",
  "text": "string",
  "isCorrect": "boolean"
}
```

**Side Effects**: 
- Updates participant scores
- May trigger turn advance if all guessed correctly

---

## Game Events

### 1. Start Game Turns

**Event**: `game:turns:start`  
**Direction**: Client → Server  
**Purpose**: Start the turn-based gameplay

**Payload**:
```json
{
  "roomName": "string"
}
```

**Server Response**: Error if insufficient players (minimum 2)

**Server Emits**: `game:turn:new` to all room clients

---

### 2. New Turn (Server Event)

**Event**: `game:turn:new`  
**Direction**: Server → Client  
**Purpose**: Notify clients of a new turn starting

**Payload**:
```json
{
  "word": "string", // word to draw (only sent to drawer)
  "turn": "number", // turn counter
  "totalDuration": "number", // turn duration in milliseconds
  "currentDrawerUserId": "string",
  "currentDrawerUsername": "string",
  "isGameStarted": "boolean"
}
```

---

### 3. Request Ranking

**Event**: `game:ranking`  
**Direction**: Client → Server  
**Purpose**: Request current game ranking/scores

**Payload**:
```json
{
  "roomName": "string"
}
```

**Server Response**: Current participant list with scores

---

## System Events

### 1. Connection

**Event**: `connect`  
**Direction**: Server → Client  
**Purpose**: Notification when client connects to server

**Payload**: None

**Client Action**: Typically triggers room rejoin attempt

---

### 2. Disconnection

**Event**: `disconnect`  
**Direction**: Client → Server (automatic)  
**Purpose**: Handle client disconnection

**Server Actions**: 
- Marks participant as disconnected
- Emits leave message to room
- Starts 5-second grace period
- Removes participant if still disconnected after grace period

---

### 3. Error

**Event**: `error`  
**Direction**: Server → Client  
**Purpose**: Send error information to client

**Payload**:
```json
{
  "message": "string", // human-readable error message
  "action": "string" // suggested action: "nothing", "retry", "ignore", "log", "pop", "dialog"
}
```

---

## Server Broadcast Events

### 1. Participants Update

**Event**: `room:participants:update`  
**Direction**: Server → All room clients  
**Purpose**: Update participant list and scores

**Payload**:
```json
{
  "participants": [
    {
      "userId": "string",
      "username": "string",
      "userAvatar": "string|null",
      "isLogged": "boolean",
      "isConnected": "boolean",
      "score": "number"
    }
  ]
}
```

---

### 2. Drawing State

**Event**: `drawing:state`  
**Direction**: Server → Client  
**Purpose**: Send current drawing state to newly joined client

**Payload**:
```json
{
  "strokes": [
    {
      "points": [{"dx": "number", "dy": "number"}],
      "color": "string",
      "strokeWidth": "number",
      "tool": "string",
      "isFilled": "boolean"
    }
  ]
}
```

---

## Error Handling

### Client-Side Error Handling

```dart
SocketManager.instance.onEvent('error', (data) {
  final error = ErrorDTO.fromJson(data as Map<String, dynamic>);
  
  switch (error.action) {
    case ErrorActionType.retry:
      // Retry the last operation
      break;
    case ErrorActionType.dialog:
      // Show error dialog
      break;
    case ErrorActionType.pop:
      // Navigate back
      break;
    default:
      // Log or ignore
  }
});
```

### Common Error Scenarios

1. **Room Full**: Maximum 4 players reached
2. **Room Not Found**: Attempting to join non-existent room
3. **Invalid Data**: Malformed request payload
4. **Game Not Started**: Trying to guess before game begins
5. **Connection Lost**: Network connectivity issues

---

## Rate Limiting & Performance

### Current Limits
- **Drawing Points**: No explicit limit (memory bounded)
- **Message Length**: No explicit limit
- **Connection Timeout**: 1 second
- **Ping Interval**: 300ms

### Performance Considerations
- Drawing events are broadcast to all room participants
- Large rooms (4 players) generate more network traffic
- Stroke points are accumulated and sent in batches

---

## Development & Testing

### Mock Events (Development Only)
```dart
// Testing disconnection
Tests.testDisconnectionThenReconnection4s();

// Creating test rooms
Tests.createRoom('test-room');
```

### Event Debugging
```go
log.DEBUG = true // Enable server-side logging
```

```dart
developer.log('Socket event: $eventName, data: $data'); // Client-side logging
```

---

## Security Considerations

### Input Validation
- All string inputs are validated for length and format
- Room names and usernames have minimum length requirements
- Numeric values are bounds-checked

### Authentication
- Currently uses Firebase custom tokens
- User avatars are validated paths only
- No persistent session management

### Rate Limiting
- No explicit rate limiting implemented
- Relies on WebSocket connection limits
- Future implementation should include per-client limits