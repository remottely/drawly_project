# Testing Strategy

## Overview

The Drawly project employs a comprehensive testing strategy covering unit tests, integration tests, and end-to-end tests for both backend (Go) and frontend (Flutter) components. This document outlines the testing approaches, tools, and best practices.

## Testing Philosophy

### Principles
1. **Test Pyramid**: More unit tests, fewer integration tests, minimal E2E tests
2. **Fast Feedback**: Tests should run quickly in development
3. **Reliable**: Tests should be deterministic and stable
4. **Maintainable**: Tests should be easy to read and update
5. **Coverage**: Focus on critical paths and edge cases

### Test Types
- **Unit Tests**: Individual functions and methods
- **Widget Tests**: Flutter UI components
- **Integration Tests**: Component interactions
- **End-to-End Tests**: Complete user workflows
- **Performance Tests**: Load and stress testing

## Backend Testing (Go)

### 1. Test Structure

```
backend-go/
├── src/
│   ├── main.go
│   ├── room.go
│   ├── events.go
│   └── ...
├── tests/
│   ├── unit/
│   │   ├── room_test.go
│   │   ├── events_test.go
│   │   └── helpers_test.go
│   ├── integration/
│   │   ├── socket_test.go
│   │   └── game_flow_test.go
│   └── fixtures/
│       ├── rooms.json
│       └── participants.json
└── go.mod
```

### 2. Unit Testing

#### Testing Framework
```go
import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)
```

#### Room Logic Tests
```go
// tests/unit/room_test.go
func TestRoom_AddParticipant(t *testing.T) {
    room := &Room{
        Name:         "test-room",
        Participants: make(map[string]*Participant),
        TurnQueue:    []*Participant{},
        CurrentDrawerTurnIndex: -1,
    }
    
    participant := &Participant{
        UserId:      "user1",
        Username:    "testuser",
        IsConnected: true,
        Score:       0,
    }
    
    room.addParticipant(participant)
    
    assert.Len(t, room.Participants, 1)
    assert.Len(t, room.TurnQueue, 1)
    assert.Equal(t, participant, room.Participants["user1"])
    assert.Equal(t, participant, room.TurnQueue[0])
}

func TestRoom_AdvanceTurn(t *testing.T) {
    room := &Room{
        Name:         "test-room",
        Participants: make(map[string]*Participant),
        TurnQueue: []*Participant{
            {UserId: "user1", IsConnected: true},
            {UserId: "user2", IsConnected: false}, // Disconnected
            {UserId: "user3", IsConnected: true},
        },
        CurrentDrawerTurnIndex: -1,
        TurnCount: 0,
    }
    
    room.advanceTurn()
    
    assert.Equal(t, int8(0), room.CurrentDrawerTurnIndex)
    assert.Equal(t, uint8(1), room.TurnCount)
    
    // Should skip disconnected user
    room.advanceTurn()
    assert.Equal(t, int8(2), room.CurrentDrawerTurnIndex)
}

func TestRoom_HasEveryoneAnsweredCorrectly(t *testing.T) {
    room := &Room{
        Name: "test-room",
        Participants: map[string]*Participant{
            "drawer": {UserId: "drawer", IsConnected: true},
            "user1":  {UserId: "user1", IsConnected: true},
            "user2":  {UserId: "user2", IsConnected: true},
        },
        TurnQueue: []*Participant{
            {UserId: "drawer", IsConnected: true},
            {UserId: "user1", IsConnected: true},
            {UserId: "user2", IsConnected: true},
        },
        CurrentDrawerTurnIndex: 0,
        ParticipantsWhoAnsweredCorrectly: map[string]bool{
            "user1": true,
            "user2": true,
        },
    }
    
    result := room.hasEveryoneAnsweredCorrectly()
    assert.True(t, result)
}
```

#### Drawing System Tests
```go
// tests/unit/drawing_test.go
func TestDrawing_AddStroke(t *testing.T) {
    drawing := &Drawing{
        Strokes:   []*Stroke{},
        UndoStack: []*Stroke{},
    }
    
    stroke := &Stroke{
        Points: []Offset{
            {Dx: 10.0, Dy: 20.0},
            {Dx: 15.0, Dy: 25.0},
        },
        Color:       "#FF0000",
        StrokeWidth: 2.0,
        Tool:        "brush",
    }
    
    drawing.addStroke(stroke)
    
    assert.Len(t, drawing.Strokes, 1)
    assert.Equal(t, stroke, drawing.Strokes[0])
}

func TestDrawing_UndoRedo(t *testing.T) {
    drawing := &Drawing{
        Strokes: []*Stroke{
            {Color: "#FF0000", Tool: "brush"},
            {Color: "#00FF00", Tool: "brush"},
        },
        UndoStack: []*Stroke{},
    }
    
    // Test undo
    undoneStroke := drawing.undo()
    assert.Len(t, drawing.Strokes, 1)
    assert.Len(t, drawing.UndoStack, 1)
    assert.Equal(t, "#00FF00", undoneStroke.Color)
    
    // Test redo
    redoneStroke := drawing.redo()
    assert.Len(t, drawing.Strokes, 2)
    assert.Len(t, drawing.UndoStack, 0)
    assert.Equal(t, "#00FF00", redoneStroke.Color)
}
```

### 3. Integration Testing

#### Socket.IO Integration Tests
```go
// tests/integration/socket_test.go
func TestSocketIntegration_JoinRoom(t *testing.T) {
    // Setup test server
    server := setupTestServer()
    defer server.Close()
    
    // Create test client
    client := setupTestClient(server.URL)
    defer client.Close()
    
    // Test room join
    roomData := map[string]interface{}{
        "roomName":   "test-room",
        "userId":     "test-user",
        "username":   "TestUser",
        "userAvatar": nil,
        "isLogged":   false,
    }
    
    // Create room first
    rooms["test-room"] = &Room{
        Name:         "test-room",
        Participants: make(map[string]*Participant),
        TurnQueue:    []*Participant{},
    }
    
    // Emit join event with callback
    var response map[string]interface{}
    client.EmitWithAck("room:join", roomData, func(args []interface{}) {
        response = args[0].(map[string]interface{})
    })
    
    // Wait for response
    time.Sleep(100 * time.Millisecond)
    
    assert.True(t, response["success"].(bool))
    assert.Contains(t, response, "turn")
    assert.Contains(t, response, "isGameStarted")
}
```

#### Game Flow Integration Tests
```go
func TestGameFlow_CompleteRound(t *testing.T) {
    server := setupTestServer()
    defer server.Close()
    
    // Setup multiple clients
    client1 := setupTestClient(server.URL)
    client2 := setupTestClient(server.URL)
    defer client1.Close()
    defer client2.Close()
    
    roomName := "integration-test-room"
    
    // Both clients join room
    joinRoom(t, client1, roomName, "user1", "Player1")
    joinRoom(t, client2, roomName, roomName, "user2", "Player2")
    
    // Start game
    gameData := map[string]interface{}{"roomName": roomName}
    client1.Emit("game:turns:start", gameData)
    
    // Wait for turn to start
    time.Sleep(100 * time.Millisecond)
    
    // Player 2 makes correct guess
    guessData := map[string]interface{}{
        "roomName": roomName,
        "userId":   "user2",
        "username": "Player2",
        "text":     getCurrentWord(roomName), // Helper function
    }
    client2.Emit("chat:answer:guess", guessData)
    
    // Verify game state changes
    time.Sleep(100 * time.Millisecond)
    
    room := rooms[roomName]
    assert.True(t, room.ParticipantsWhoAnsweredCorrectly["user2"])
    assert.Greater(t, room.Participants["user2"].Score, uint16(0))
}
```

### 4. Test Utilities

#### Test Server Setup
```go
func setupTestServer() *socket.Server {
    io := socket.NewServer(nil, nil)
    
    // Setup test routes
    io.On("connection", func(clients ...any) {
        client := clients[0].(*socket.Socket)
        handleConnection(io, client)
    })
    
    go http.ListenAndServe(":0", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        io.ServeHandler(nil).ServeHTTP(w, r)
    }))
    
    return io
}

func setupTestClient(serverURL string) *socketio_client.Client {
    client, _ := socketio_client.NewClient(serverURL, nil)
    client.Connect()
    return client
}
```

#### Test Data Factories
```go
func createTestRoom(name string, participantCount int) *Room {
    room := &Room{
        Name:         name,
        Participants: make(map[string]*Participant),
        TurnQueue:    []*Participant{},
        CurrentDrawerTurnIndex: -1,
        IsGameStarted: false,
        ParticipantsWhoAnsweredCorrectly: make(map[string]bool),
    }
    
    for i := 0; i < participantCount; i++ {
        participant := &Participant{
            UserId:      fmt.Sprintf("user%d", i+1),
            Username:    fmt.Sprintf("Player%d", i+1),
            IsConnected: true,
            Score:       0,
        }
        room.addParticipant(participant)
    }
    
    return room
}
```

### 5. Performance Testing

#### Load Testing with Go
```go
func TestLoad_ConcurrentConnections(t *testing.T) {
    server := setupTestServer()
    defer server.Close()
    
    numClients := 100
    var wg sync.WaitGroup
    results := make(chan bool, numClients)
    
    for i := 0; i < numClients; i++ {
        wg.Add(1)
        go func(clientID int) {
            defer wg.Done()
            
            client := setupTestClient(server.URL)
            defer client.Close()
            
            // Simulate user behavior
            success := simulateUserSession(client, clientID)
            results <- success
        }(i)
    }
    
    wg.Wait()
    close(results)
    
    successCount := 0
    for success := range results {
        if success {
            successCount++
        }
    }
    
    successRate := float64(successCount) / float64(numClients)
    assert.Greater(t, successRate, 0.95) // 95% success rate
}
```

## Frontend Testing (Flutter)

### 1. Test Structure

```
lib/
├── features/
│   └── draw_game/
│       ├── draw_game_room_page.dart
│       └── models/
test/
├── unit/
│   ├── models/
│   │   ├── participant_test.dart
│   │   └── message_test.dart
│   └── services/
│       └── socket_manager_test.dart
├── widget/
│   ├── draw_game/
│   │   ├── draw_game_room_page_test.dart
│   │   └── participants/
│   │       └── all_participants_test.dart
│   └── core/
│       └── widgets/
│           └── avatar_test.dart
├── integration/
│   └── app_test.dart
└── mocks/
    ├── mock_socket_manager.dart
    └── mock_firebase_auth.dart
```

### 2. Unit Testing

#### Model Tests
```dart
// test/unit/models/participant_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drawly/features/draw_game/models/participants.dart';

void main() {
  group('Participant', () {
    test('should create participant from JSON', () {
      final json = {
        'userId': 'user1',
        'username': 'TestUser',
        'userAvatar': 'avatar.png',
        'isLogged': true,
        'isConnected': true,
        'score': 100,
      };

      final participant = Participant.fromJson(json);

      expect(participant.userId, 'user1');
      expect(participant.username, 'TestUser');
      expect(participant.userAvatar, 'avatar.png');
      expect(participant.isLogged, true);
      expect(participant.isConnected, true);
      expect(participant.score, 100);
    });

    test('should handle null avatar', () {
      final json = {
        'userId': 'user1',
        'username': 'TestUser',
        'userAvatar': null,
        'isLogged': false,
        'isConnected': true,
        'score': 0,
      };

      final participant = Participant.fromJson(json);

      expect(participant.userAvatar, null);
    });

    test('should convert to JSON', () {
      final participant = Participant(
        userId: 'user1',
        username: 'TestUser',
        userAvatar: 'avatar.png',
        isLogged: true,
        isConnected: true,
        score: 100,
      );

      final json = participant.toJson();

      expect(json['userId'], 'user1');
      expect(json['username'], 'TestUser');
      expect(json['userAvatar'], 'avatar.png');
      expect(json['isLogged'], true);
      expect(json['isConnected'], true);
      expect(json['score'], 100);
    });
  });
}
```

#### Service Tests
```dart
// test/unit/services/socket_manager_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:drawly_core/drawly_core.dart';

import '../../mocks/mock_socket.dart';

void main() {
  group('SocketManager', () {
    late SocketManager socketManager;
    late MockSocket mockSocket;

    setUp(() {
      mockSocket = MockSocket();
      socketManager = SocketManager.instance;
      socketManager.setSocket(mockSocket); // For testing
    });

    test('should emit event with data', () {
      final eventData = {'test': 'data'};
      
      socketManager.emit('test-event', eventData);
      
      verify(mockSocket.emit('test-event', eventData)).called(1);
    });

    test('should emit with acknowledgment', () async {
      final eventData = {'test': 'data'};
      final responseData = {'success': true};
      
      when(mockSocket.emitWithAck('test-event', eventData, ack: anyNamed('ack')))
          .thenAnswer((invocation) {
        final ack = invocation.namedArguments[Symbol('ack')] as Function;
        ack([responseData]);
      });
      
      final result = await socketManager.emitWithAck('test-event', eventData);
      
      expect(result, responseData);
    });

    test('should register event listener', () {
      void eventHandler(dynamic data) {}
      
      socketManager.onEvent('test-event', eventHandler);
      
      verify(mockSocket.on('test-event', eventHandler)).called(1);
    });

    test('should unregister event listener', () {
      void eventHandler(dynamic data) {}
      
      socketManager.offEvent('test-event', eventHandler);
      
      verify(mockSocket.off('test-event', eventHandler)).called(1);
    });
  });
}
```

### 3. Widget Testing

#### Page Widget Tests
```dart
// test/widget/draw_game/draw_game_room_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:drawly/features/draw_game/draw_game_room_page.dart';

import '../../mocks/mock_socket_manager.dart';

void main() {
  group('DrawGameRoomPage Widget Tests', () {
    late MockSocketManager mockSocketManager;

    setUp(() {
      mockSocketManager = MockSocketManager();
    });

    testWidgets('should display room name and turn count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DrawGameRoomPage(
            userId: 'test-user',
            username: 'TestUser',
            roomName: 'test-room',
          ),
        ),
      );

      expect(find.text('test-room | 0'), findsOneWidget);
    });

    testWidgets('should show start game button when turn is 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DrawGameRoomPage(
            userId: 'test-user',
            username: 'TestUser',
            roomName: 'test-room',
          ),
        ),
      );

      expect(find.text('Start Game'), findsOneWidget);
    });

    testWidgets('should hide start game button when game started', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DrawGameRoomPage(
            userId: 'test-user',
            username: 'TestUser',
            roomName: 'test-room',
          ),
        ),
      );

      // Simulate game start
      final state = tester.state<_DrawGameRoomPageState>(
          find.byType(DrawGameRoomPage));
      state.rxTurn.value = 1;
      state.rxIsGameStarted.value = true;

      await tester.pump();

      expect(find.text('Start Game'), findsNothing);
    });

    testWidgets('should display current drawer info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DrawGameRoomPage(
            userId: 'test-user',
            username: 'TestUser',
            roomName: 'test-room',
          ),
        ),
      );

      final state = tester.state<_DrawGameRoomPageState>(
          find.byType(DrawGameRoomPage));
      state.rxCurrentDrawerUsername.value = 'CurrentDrawer';
      state.rxCurrentDrawerUserId.value = 'drawer-id';

      await tester.pump();

      expect(find.text('Vez de CurrentDrawer'), findsOneWidget);
    });

    testWidgets('should show word when user is current drawer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DrawGameRoomPage(
            userId: 'test-user',
            username: 'TestUser',
            roomName: 'test-room',
          ),
        ),
      );

      final state = tester.state<_DrawGameRoomPageState>(
          find.byType(DrawGameRoomPage));
      state.rxWord.value = 'SECRET_WORD';
      state.rxCurrentDrawerUserId.value = 'test-user';
      state.rxIsCurrentDrawerUserId.value = true;

      await tester.pump();

      expect(find.text('SECRET_WORD'), findsOneWidget);
    });
  });
}
```

#### Custom Widget Tests
```dart
// test/widget/core/widgets/avatar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawly/core/widgets/avatar.dart';

void main() {
  group('Avatar Widget Tests', () {
    testWidgets('should display avatar image when path provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Avatar(
              avatarPath: 'assets/avatars/1.webp',
              size: 50,
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should display default avatar when no path', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Avatar(
              avatarPath: null,
              size: 50,
            ),
          ),
        ),
      );

      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('should apply correct size', (tester) async {
      const size = 100.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Avatar(
              avatarPath: null,
              size: size,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.constraints?.maxWidth, size);
      expect(container.constraints?.maxHeight, size);
    });
  });
}
```

### 4. Integration Testing

#### Full App Integration Test
```dart
// test/integration/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:drawly/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('complete user flow - join room and draw', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Enter username
      await tester.enterText(find.byType(TextField).first, 'TestUser');
      await tester.pumpAndSettle();

      // Enter room name
      await tester.enterText(find.byType(TextField).last, 'TestRoom');
      await tester.pumpAndSettle();

      // Tap join room button
      await tester.tap(find.text('Join Room'));
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Verify we're in the game room
      expect(find.text('TestRoom'), findsOneWidget);
      expect(find.text('Start Game'), findsOneWidget);

      // Start the game
      await tester.tap(find.text('Start Game'));
      await tester.pumpAndSettle(Duration(seconds: 1));

      // Verify game started
      expect(find.text('Start Game'), findsNothing);
      
      // Test drawing functionality
      final drawingArea = find.byType(GestureDetector).first;
      await tester.drag(drawingArea, Offset(50, 50));
      await tester.pumpAndSettle();

      // Verify drawing occurred (this would need more specific checks)
      // expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('multiple users can join same room', (tester) async {
      // This would require running multiple app instances
      // or mocking multiple clients
    });
  });
}
```

### 5. Test Utilities and Mocks

#### Mock Socket Manager
```dart
// test/mocks/mock_socket_manager.dart
import 'package:mockito/mockito.dart';
import 'package:drawly_core/drawly_core.dart';

class MockSocketManager extends Mock implements SocketManager {
  final Map<String, List<Function>> _eventListeners = {};

  @override
  void emit(String event, dynamic data) {
    // Mock implementation
  }

  @override
  Future<Map<String, dynamic>> emitWithAck(String event, dynamic data) async {
    // Mock implementation
    return {'success': true};
  }

  @override
  void onEvent(String event, Function(dynamic) handler) {
    _eventListeners[event] ??= [];
    _eventListeners[event]!.add(handler);
  }

  @override
  void offEvent(String event, Function(dynamic) handler) {
    _eventListeners[event]?.remove(handler);
  }

  // Helper method for testing
  void simulateEvent(String event, dynamic data) {
    _eventListeners[event]?.forEach((handler) => handler(data));
  }
}
```

#### Test Data Builders
```dart
// test/utils/test_data_builders.dart
import 'package:drawly/features/draw_game/models/participants.dart';

class ParticipantBuilder {
  String _userId = 'default-user';
  String _username = 'DefaultUser';
  String? _userAvatar;
  bool _isLogged = false;
  bool _isConnected = true;
  int _score = 0;

  ParticipantBuilder withUserId(String userId) {
    _userId = userId;
    return this;
  }

  ParticipantBuilder withUsername(String username) {
    _username = username;
    return this;
  }

  ParticipantBuilder withAvatar(String avatar) {
    _userAvatar = avatar;
    return this;
  }

  ParticipantBuilder asLogged() {
    _isLogged = true;
    return this;
  }

  ParticipantBuilder asDisconnected() {
    _isConnected = false;
    return this;
  }

  ParticipantBuilder withScore(int score) {
    _score = score;
    return this;
  }

  Participant build() {
    return Participant(
      userId: _userId,
      username: _username,
      userAvatar: _userAvatar,
      isLogged: _isLogged,
      isConnected: _isConnected,
      score: _score,
    );
  }
}
```

## Test Execution

### Running Tests

#### Backend Tests
```bash
# Run all tests
cd backend-go
go test ./...

# Run tests with coverage
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out

# Run specific test
go test -run TestRoom_AddParticipant ./tests/

# Run with verbose output
go test -v ./...

# Run benchmarks
go test -bench=. ./...
```

#### Frontend Tests
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Run specific test file
flutter test test/unit/models/participant_test.dart

# Run widget tests only
flutter test test/widget/

# Run integration tests
flutter test integration_test/

# Run tests on device
flutter test integration_test/ -d chrome
```

### Continuous Integration

#### GitHub Actions for Testing
```yaml
# .github/workflows/test.yml
name: Test Suite

on: [push, pull_request]

jobs:
  backend-tests:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Go
      uses: actions/setup-go@v3
      with:
        go-version: 1.23.1
        
    - name: Run backend tests
      run: |
        cd backend-go
        go test -v -coverprofile=coverage.out ./...
        
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: ./backend-go/coverage.out

  frontend-tests:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.29.2'
        
    - name: Get dependencies
      run: flutter pub get
      
    - name: Run tests
      run: flutter test --coverage
      
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage/lcov.info

  integration-tests:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Start backend server
      run: |
        cd backend-go
        go run src/main.go &
        sleep 5
        
    - name: Set up Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.29.2'
        
    - name: Run integration tests
      run: flutter test integration_test/
```

## Test Quality Metrics

### Coverage Goals
- **Backend**: Minimum 80% code coverage
- **Frontend**: Minimum 75% code coverage
- **Critical Paths**: 95% coverage for core game logic

### Performance Benchmarks
- **Unit tests**: < 100ms per test
- **Widget tests**: < 500ms per test
- **Integration tests**: < 5 seconds per test

### Test Reliability
- **Flaky test rate**: < 1%
- **Test execution time**: Consistent within 10%
- **Success rate**: > 99% on CI

## Best Practices

### Test Writing Guidelines
1. **Arrange-Act-Assert**: Clear test structure
2. **Descriptive Names**: Test names should explain what they test
3. **Single Responsibility**: One assertion per test when possible
4. **Test Data**: Use builders and factories for complex data
5. **Cleanup**: Proper setup and teardown

### Maintainability
1. **DRY Principle**: Reuse test utilities and helpers
2. **Test Documentation**: Comment complex test scenarios
3. **Regular Review**: Periodically review and refactor tests
4. **Update Tests**: Keep tests in sync with code changes

### Performance Testing
1. **Load Testing**: Test concurrent user scenarios
2. **Stress Testing**: Test system limits
3. **Memory Testing**: Check for memory leaks
4. **Latency Testing**: Measure response times