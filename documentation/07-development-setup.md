# Development Setup Guide

## Prerequisites

### System Requirements

**Backend (Go):**
- Go 1.23.1 or higher
- Git for version control
- Code editor (VS Code, GoLand, or similar)

**Frontend (Flutter):**
- Flutter SDK 3.29.2 or higher
- Dart SDK 3.7.2 or higher
- Android Studio / Xcode (for mobile development)
- Chrome (for web development)

**Firebase:**
- Firebase project with Authentication enabled
- Firebase CLI (optional, for deployment)

### Installation Steps

#### 1. Install Go
```bash
# macOS (using Homebrew)
brew install go

# Linux
wget https://go.dev/dl/go1.23.1.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.23.1.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Windows
# Download and install from https://go.dev/dl/
```

Verify installation:
```bash
go version
# Should output: go version go1.23.1 ...
```

#### 2. Install Flutter
```bash
# macOS
brew install --cask flutter

# Linux/Windows
# Download from https://flutter.dev/docs/get-started/install
```

Verify installation:
```bash
flutter doctor
# Should show all checkmarks or manageable issues
```

#### 3. Clone Repository
```bash
git clone https://github.com/Remottely/drawly_project.git
cd drawly_project/external/apps/drawly
```

## Backend Setup

### 1. Navigate to Backend Directory
```bash
cd backend-go
```

### 2. Install Dependencies
```bash
go mod download
```

### 3. Verify Dependencies
```bash
go mod verify
```

### 4. Run Tests (Optional)
```bash
go test ./tests/...
```

### 5. Start Development Server
```bash
go run src/main.go
```

The server will start on `http://localhost:5555`

**Expected Output:**
```
2024/01/XX XX:XX:XX Client connected: [socket-id]
[DEBUG] Server listening on :5555
```

### 6. Development Configuration

**Environment Variables (.env):**
```bash
# Create .env file in backend-go directory
PORT=5555
DEBUG=true
LOG_LEVEL=debug
```

**CORS Configuration:**
The server is configured to accept connections from multiple localhost ports for development:
```go
Origin: "http://localhost:8081 http://localhost:8082 http://localhost:8083 ..."
```

### 7. Hot Reloading (Optional)

Install Air for hot reloading:
```bash
go install github.com/cosmtrek/air@latest
```

Create `.air.toml`:
```toml
root = "."
testdata_dir = "testdata"
tmp_dir = "tmp"

[build]
  args_bin = []
  bin = "./tmp/main"
  cmd = "go build -o ./tmp/main ./src"
  delay = 1000
  exclude_dir = ["assets", "tmp", "vendor", "testdata"]
  exclude_file = []
  exclude_regex = ["_test.go"]
  exclude_unchanged = false
  follow_symlink = false
  full_bin = ""
  include_dir = []
  include_ext = ["go", "tpl", "tmpl", "html"]
  kill_delay = "0s"
  log = "build-errors.log"
  send_interrupt = false
  stop_on_root = false

[color]
  app = ""
  build = "yellow"
  main = "magenta"
  runner = "green"
  watcher = "cyan"

[log]
  time = false

[misc]
  clean_on_exit = false
```

Run with hot reload:
```bash
air
```

## Frontend Setup

### 1. Navigate to Project Root
```bash
cd .. # from backend-go directory
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Verify Custom Packages
```bash
# Check custom packages
cd packages/drawing_board && flutter pub get && cd ../..
cd packages/drawly_core && flutter pub get && cd ../..
cd packages/drawly_design_system && flutter pub get && cd ../..
```

### 4. Firebase Configuration

#### Option A: Use Existing Configuration
The project includes Firebase configuration files:
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

#### Option B: Create New Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create new project
3. Enable Authentication
4. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```
5. Login and configure:
   ```bash
   firebase login
   firebase init
   ```
6. Generate configuration:
   ```bash
   flutterfire configure
   ```

### 5. Run Development Server

#### Web Development
```bash
flutter run -d chrome --web-port=8081
```

#### Mobile Development (Android)
```bash
flutter run -d android
```

#### Mobile Development (iOS)
```bash
flutter run -d ios
```

#### Desktop Development
```bash
# macOS
flutter run -d macos

# Linux
flutter run -d linux

# Windows
flutter run -d windows
```

### 6. Development Tools

#### Flutter Inspector
Enable in your IDE or run:
```bash
flutter run --enable-software-rendering
```

#### Hot Reload
Press `r` in the terminal or save files in your IDE for hot reload.
Press `R` for hot restart.

## Database Setup (Future)

Currently, the application uses in-memory storage. For production:

### PostgreSQL Setup (Planned)
```sql
-- Create database
CREATE DATABASE drawly_db;

-- Create user
CREATE USER drawly_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE drawly_db TO drawly_user;
```

### MongoDB Setup (Alternative)
```bash
# Install MongoDB
brew install mongodb/brew/mongodb-community

# Start MongoDB
brew services start mongodb/brew/mongodb-community
```

## Development Workflow

### 1. Start Backend Server
```bash
cd backend-go
go run src/main.go
```

### 2. Start Frontend Application
```bash
# In another terminal
flutter run -d chrome --web-port=8081
```

### 3. Access Application
Open browser to `http://localhost:8081`

### 4. Development Testing

#### Create Test Room
1. Open application
2. Enter username (minimum 3 characters)
3. Enter room name (minimum 3 characters)
4. Click "Create Room" or "Join Room"

#### Multi-Client Testing
Open multiple browser tabs/windows:
- `http://localhost:8081`
- `http://localhost:8082`
- `http://localhost:8083`
- `http://localhost:8084`

### 5. Debug Mode Features

**Testing Utilities:**
```dart
// Enable testing mode in DrawlyApp
static bool isDebugMode = true;

// Test disconnection
Tests.testDisconnectionThenReconnection4s();

// Create test room
Tests.createRoom('test-room');
```

**Backend Logging:**
```go
log.DEBUG = true // Already enabled in main.go
```

## IDE Configuration

### Visual Studio Code

**Extensions:**
- Go (for backend)
- Flutter (for frontend)
- Dart (for frontend)
- GitLens (for version control)

**Settings (.vscode/settings.json):**
```json
{
  "go.toolsManagement.checkForUpdates": "local",
  "go.useLanguageServer": true,
  "flutter.sdkPath": "/path/to/flutter",
  "dart.previewFlutterUiGuides": true,
  "dart.debugExternalLibraries": false
}
```

**Launch Configuration (.vscode/launch.json):**
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Launch Flutter",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "args": ["--web-port=8081"]
    },
    {
      "name": "Launch Go Server",
      "type": "go",
      "request": "launch",
      "mode": "auto",
      "program": "${workspaceFolder}/backend-go/src/main.go"
    }
  ]
}
```

### Android Studio / IntelliJ

**Plugins:**
- Flutter plugin
- Dart plugin
- Go plugin

## Troubleshooting

### Common Backend Issues

**Port Already in Use:**
```bash
# Find process using port 5555
lsof -i :5555

# Kill process
kill -9 <PID>
```

**Module Issues:**
```bash
# Clean module cache
go clean -modcache

# Re-download dependencies
go mod download
```

**CORS Issues:**
Check that the frontend port is included in the CORS configuration in `main.go:42`

### Common Frontend Issues

**Package Issues:**
```bash
# Clean packages
flutter clean
flutter pub get

# Clean custom packages
cd packages/drawing_board && flutter clean && flutter pub get
```

**Build Issues:**
```bash
# Reset Flutter
flutter doctor
flutter upgrade

# Clear cache
flutter pub cache repair
```

**WebSocket Connection Issues:**
- Ensure backend server is running on localhost:5555
- Check browser console for connection errors
- Verify firewall/antivirus isn't blocking connections

### Firebase Issues

**Authentication Errors:**
- Check Firebase project configuration
- Verify API keys in `firebase_options.dart`
- Ensure Authentication is enabled in Firebase Console

**Platform Configuration:**
- Android: Verify `google-services.json` in `android/app/`
- iOS: Verify `GoogleService-Info.plist` in `ios/Runner/`

## Performance Optimization

### Backend
```bash
# Build optimized binary
go build -ldflags="-s -w" -o drawly-server src/main.go

# Run with profiling
go run src/main.go -cpuprofile=cpu.prof -memprofile=mem.prof
```

### Frontend
```bash
# Build for production
flutter build web --release
flutter build apk --release
flutter build ios --release

# Analyze bundle size
flutter build web --analyze-size
```

## Next Steps

1. **Set up your development environment** using this guide
2. **Read the API Documentation** to understand the event system
3. **Review the Architecture Documents** for detailed implementation understanding
4. **Start developing** by modifying existing features or adding new ones
5. **Write tests** for any new functionality
6. **Follow the contribution guidelines** for code quality and consistency

For questions or issues, refer to the project documentation or create an issue in the repository.