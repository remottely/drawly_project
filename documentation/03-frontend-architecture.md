# Frontend Architecture (Flutter)

## Overview

The Drawly frontend is built with **Flutter 3.29.2+** using **Dart 3.7.2+**. The architecture follows MVVM pattern with reactive programming, custom packages, and a modular design approach.

## Project Structure

```
lib/
├── main.dart                    # Application entry point
├── drawly_app.dart             # Main app widget with global state
├── core/                       # Core utilities and widgets
│   ├── logged_area/
│   │   └── widgets/
│   │       └── profile_pick_avatar.dart
│   └── widgets/
│       ├── avatar.dart
│       └── session_pick_avatar.dart
├── features/                   # Feature-based modules
│   ├── auth/
│   │   └── auth_page.dart      # Authentication screen
│   └── draw_game/              # Main game feature
│       ├── models/             # Data models
│       ├── chats/              # Chat components
│       ├── participants/       # Participant management
│       ├── draw_game_room_page.dart
│       └── draw_game_room_selection_page.dart
├── firebase_options.dart       # Firebase configuration
└── testing/                    # Development utilities
    ├── golang/
    ├── tests.dart
    └── main_dev_game_page_*.dart
```

## Custom Packages

### 1. Drawing Board Package (`packages/drawing_board/`)

**Purpose**: Advanced drawing canvas with multiple tools and real-time synchronization.

```
drawing_board/
├── lib/
│   ├── drawing_board.dart      # Public API
│   └── src/
│       ├── domain/             # Business logic
│       │   ├── models/         # Drawing models
│       │   └── dtos/           # Data transfer objects
│       ├── presentation/       # UI components
│       │   ├── views/          # Main drawing board widget
│       │   ├── widgets/        # Canvas, toolbar, color palette
│       │   └── notifiers/      # State management
│       ├── extensions/         # Utility extensions
│       └── util/              # Algorithms (bucket fill, etc.)
```

**Key Features:**
- **Multi-tool Support**: Brush, eraser, shapes, bucket fill
- **Real-time Sync**: WebSocket integration for collaborative drawing
- **Undo/Redo Stack**: Complete history management
- **Performance Optimized**: Efficient rendering and memory usage
- **Touch/Mouse Support**: Cross-platform input handling

**Core Models:**
```dart
class Stroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final ToolType tool;
  final bool isFilled;
}

class DrawingCanvasOptions {
  final Color backgroundColor;
  final Size canvasSize;
  final bool isEnabled;
  final ToolType currentTool;
}

class UndoRedoStack {
  final List<Stroke> undoStack;
  final List<Stroke> redoStack;
}
```

### 2. Drawly Core Package (`packages/drawly_core/`)

**Purpose**: Business logic, data models, and network communication.

```
drawly_core/
├── lib/
│   ├── drawly_core.dart        # Public API
│   └── src/
│       ├── managers/           # Service managers
│       │   └── socket_manager.dart # Socket.IO management
│       └── dtos/              # Data transfer objects
│           └── socket_dtos.dart # Socket communication DTOs
```

**Socket Manager:**
```dart
class SocketManager {
  static final SocketManager instance = SocketManager._internal();
  IO.Socket? _socket;
  
  void connect() {
    _socket = IO.io('http://localhost:5555', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    _socket!.connect();
  }
  
  Future<Map<String, dynamic>> emitWithAck(String event, dynamic data) async {
    final completer = Completer<Map<String, dynamic>>();
    _socket!.emitWithAck(event, data, ack: (data) {
      completer.complete(data[0] as Map<String, dynamic>);
    });
    return completer.future;
  }
  
  void onEvent(String event, Function(dynamic) handler) {
    _socket!.on(event, handler);
  }
}
```

**Data Transfer Objects:**
```dart
class RoomUserDTO {
  final String roomName;
  final String userId;
  final String username;
  final String? userAvatar;
  final bool isLogged;
  
  Map<String, dynamic> toJson() => {
    'roomName': roomName,
    'userId': userId,
    'username': username,
    'userAvatar': userAvatar,
    'isLogged': isLogged,
  };
}

class ErrorDTO {
  final String message;
  final ErrorActionType action;
  
  factory ErrorDTO.fromJson(Map<String, dynamic> json) => ErrorDTO(
    message: json['message'] as String,
    action: ErrorActionType.values.firstWhere(
      (e) => e.name == json['action'],
      orElse: () => ErrorActionType.nothing,
    ),
  );
}
```

### 3. Design System Package (`packages/drawly_design_system/`)

**Purpose**: UI components, theming, and visual consistency.

```
drawly_design_system/
├── lib/
│   ├── drawly_design_system.dart # Public API
│   └── src/
│       ├── presentation/
│       │   └── theme/           # App theming
│       │       ├── app_colors.dart
│       │       └── app_theme.dart
│       └── widgets/            # Reusable UI components
│           ├── drawly_container.dart
│           ├── drawly_back_filter.dart
│           ├── drawly_chat_textfield.dart
│           └── meteor_shower.dart
```

**Theme System:**
```dart
class AppColors {
  static const Color primary = Color(0xFF6366F1);
  static const Color lightPrimary = Color(0xFFEEF2FF);
  static const Color greenAccent = Color(0xFF10B981);
  static const Color yellowAccent = Color(0xFFF59E0B);
  static const Color redAccent = Color(0xFFEF4444);
  static const Color black = Color(0xFF111827);
  static const Color lightGrey300 = Color(0xFFD1D5DB);
}

ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
  textTheme: GoogleFonts.interTextTheme(),
);
```

## Main Application Architecture

### 1. App Entry Point (`main.dart`)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const DrawlyApp(home: AuthPage()));
}
```

### 2. Main App Widget (`drawly_app.dart`)

**Features:**
- Global error handling with reactive UI
- Socket.IO initialization
- Material Design 3 theming
- Firebase integration

**Architecture Pattern:**
```dart
class DrawlyApp extends StatefulWidget {
  const DrawlyApp({required this.home, super.key});
  final Widget home;
  static bool isDebugMode = true;
}

class _DrawlyAppState extends State<DrawlyApp> {
  final rxError = ValueNotifier<ErrorDTO?>(null);
  late final void Function(dynamic) _onErrorEvent;
  
  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }
  
  Future<void> _initializeSocket() async {
    _onErrorEvent = (data) {
      rxError.value = ErrorDTO.fromJson(data as Map<String, dynamic>);
    };
    SocketManager.instance.onEvent('error', _onErrorEvent);
  }
}
```

### 3. Game Room Architecture (`draw_game_room_page.dart`)

**MVVM Pattern Implementation:**
```dart
abstract class GamePageViewModel extends State<DrawGameRoomPage> {
  // Reactive State
  final rxWord = ValueNotifier<String?>(null);
  final rxCurrentDrawerUserId = ValueNotifier<String?>(null);
  final rxIsCurrentDrawerUserId = ValueNotifier<bool>(false);
  final rxTotalDuration = ValueNotifier<int>(0);
  final rxTimeLeft = ValueNotifier<int>(0);
  final rxIsGameStarted = ValueNotifier<bool>(false);
  
  // Timer Management
  Timer? _countdownTimer;
  
  // Socket Event Handlers
  late final void Function(dynamic) _onConnectEvent;
  late final void Function(dynamic) _onNewTurnEvent;
}
```

**State Management Pattern:**
- **ValueNotifier**: For reactive UI updates
- **AnimatedBuilder**: For efficient rebuilds
- **Listenable.merge**: For multiple state dependencies

**Socket Integration:**
```dart
Future<void> _joinGameRoom() async {
  final payload = RoomUserDTO(
    roomName: widget.roomName,
    userId: widget.userId,
    username: widget.username,
    userAvatar: userAvatar,
    isLogged: false,
  ).toJson();
  
  try {
    final responseData = await SocketManager.instance.emitWithAck(
      'room:join',
      payload,
    );
    
    if (responseData['success'] == false) {
      if (mounted) Navigator.of(context).pop();
    } else {
      rxTurn.value = responseData['turn'] as int;
      rxIsGameStarted.value = responseData['isGameStarted'] as bool;
      rxCurrentDrawerUserId.value = responseData['currentDrawerUserId'] as String;
    }
  } catch (e) {
    developer.log('Error joining room: $e');
  }
}
```

## Feature Modules

### 1. Authentication (`features/auth/`)

**Current Implementation:**
- Firebase Authentication integration
- Anonymous and logged-in user support
- Avatar selection system

### 2. Draw Game Feature (`features/draw_game/`)

#### Chat System (`chats/`)

**Answers Chat (`answers_chat/`):**
- Real-time guess submission
- Correct/incorrect answer feedback
- Disabled during drawing turn

**Messages Chat (`messages_chat/`):**
- General chat functionality
- System messages (join/leave)
- Icon support for special messages

#### Models (`models/`)

```dart
class Participant {
  final String userId;
  final String username;
  final String? userAvatar;
  final bool isLogged;
  final bool isConnected;
  final int score;
  
  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
    userId: json['userId'] as String,
    username: json['username'] as String,
    userAvatar: json['userAvatar'] as String?,
    isLogged: json['isLogged'] as bool,
    isConnected: json['isConnected'] as bool,
    score: json['score'] as int,
  );
}

class Message {
  final String? icon;
  final String userId;
  final String username;
  final String text;
}

class Answer {
  final String? icon;
  final String userId;
  final String username;
  final String text;
  final bool isCorrect;
}
```

#### Participants Management (`participants/`)

- Real-time participant list updates
- Connection status tracking
- Score display and ranking
- Current drawer highlighting

## State Management Strategy

### 1. Reactive Programming

**ValueNotifier Pattern:**
```dart
class GameViewModel {
  final rxGameState = ValueNotifier<GameState>(GameState.initial());
  final rxPlayers = ValueNotifier<List<Player>>([]);
  final rxCurrentDrawer = ValueNotifier<Player?>(null);
  
  void updateGameState(GameState newState) {
    rxGameState.value = newState;
  }
}
```

**UI Binding:**
```dart
AnimatedBuilder(
  animation: Listenable.merge([rxWord, rxCurrentDrawer]),
  builder: (context, _) {
    return Text(
      rxWord.value ?? 'Waiting...',
      style: Theme.of(context).textTheme.headlineMedium,
    );
  },
)
```

### 2. Lifecycle Management

**Proper Disposal:**
```dart
@override
void dispose() {
  SocketManager.instance.offEvent('connect', _onConnectEvent);
  SocketManager.instance.offEvent('game:turn:new', _onNewTurnEvent);
  _countdownTimer?.cancel();
  rxCurrentDrawerUserId.dispose();
  rxIsCurrentDrawerUserId.dispose();
  super.dispose();
}
```

## Performance Optimizations

### 1. Widget Efficiency
- **const constructors** for immutable widgets
- **AnimatedBuilder** for selective rebuilds
- **RepaintBoundary** for isolated rendering

### 2. Memory Management
- Proper ValueNotifier disposal
- Timer cancellation
- Socket event cleanup

### 3. Drawing Performance
- Efficient path rendering
- Point sampling for large strokes
- Canvas caching for static elements

## Cross-Platform Considerations

### 1. Platform Detection
```dart
import 'package:universal_platform/universal_platform.dart';

if (UniversalPlatform.isWeb) {
  // Web-specific implementation
} else if (UniversalPlatform.isMobile) {
  // Mobile-specific implementation
}
```

### 2. Input Handling
- Touch events for mobile
- Mouse events for desktop/web
- Keyboard shortcuts for desktop

### 3. Storage
- SharedPreferences for user settings
- Firebase for cloud data
- Local storage for offline capabilities

## Testing Strategy

### 1. Unit Tests
```dart
// drawing_board package tests
testWidgets('DrawingCanvas should handle touch input', (tester) async {
  await tester.pumpWidget(DrawingCanvas());
  await tester.tap(find.byType(DrawingCanvas));
  // Verify stroke creation
});
```

### 2. Integration Tests
- End-to-end game flow
- Socket.IO communication
- Cross-platform compatibility

### 3. Widget Tests
- UI component behavior
- State management validation
- Error handling scenarios

## Build Configuration

### 1. Dependencies (`pubspec.yaml`)

**Core Dependencies:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_auth: ^5.5.2
  firebase_core: ^3.10.0
  socket_io_client: ^3.0.2
  shared_preferences: ^2.3.4
  image_picker: ^1.1.2
  uuid: ^4.5.1
  equatable: ^2.0.7

  # Custom packages
  drawing_board:
    path: packages/drawing_board
  drawly_core:
    path: packages/drawly_core
  drawly_design_system:
    path: packages/drawly_design_system
```

**Development Dependencies:**
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  very_good_analysis: ^7.0.0
```

### 2. Platform-Specific Configuration

**Android (`android/app/build.gradle`):**
```gradle
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

**iOS (`ios/Runner/Info.plist`):**
```xml
<key>CFBundleDisplayName</key>
<string>Drawly</string>
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take profile pictures</string>
```

## Development Workflow

### 1. Hot Reload Support
- Stateful widget architecture
- Proper state preservation
- Development-time optimizations

### 2. Debug Tools
- Flutter Inspector
- Performance overlay
- Network debugging

### 3. Testing Utilities (`testing/`)
- Mock data generators
- Development-only features
- Connection simulation

## Security Considerations

### 1. Input Validation
- Client-side validation for UX
- Server-side validation for security
- Sanitization of user-generated content

### 2. Firebase Security
- Authentication rules
- Firestore security rules
- Secure token management

### 3. Network Security
- HTTPS enforcement
- Certificate pinning (production)
- Input sanitization