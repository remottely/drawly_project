# Drawly - Gartic.io Clone Documentation

## Overview

Drawly is a modern implementation of a real-time drawing and guessing game similar to Gartic.io, built with a modern tech stack featuring **Golang** for the backend and **Flutter** for the frontend. This project aims to create a startup-quality application using best practices and cutting-edge technologies.

## Project Structure

```
drawly/
├── backend-go/          # Golang backend server
├── lib/                 # Flutter frontend application
├── packages/            # Custom Flutter packages
├── documentation/       # Project documentation
├── assets/             # Static assets (avatars, SVGs)
├── backend/            # Node.js backend (deprecated)
└── docs/               # Legacy documentation
```

## Tech Stack

### Backend
- **Language**: Go 1.23.1
- **WebSocket Library**: Socket.IO for Go (v2.3.6)
- **Real-time Communication**: WebSocket-based

### Frontend
- **Framework**: Flutter 3.29.2+
- **Language**: Dart 3.7.2+
- **Architecture**: MVVM pattern
- **State Management**: ValueNotifier and custom reactive patterns
- **Authentication**: Firebase Auth
- **Real-time Communication**: Socket.IO client

### Custom Packages
- `drawing_board`: Custom drawing canvas implementation
- `drawly_core`: Core business logic and socket management
- `drawly_design_system`: UI components and theming

## Key Features

- **Real-time multiplayer gameplay** (2-4 players)
- **Interactive drawing canvas** with multiple tools
- **Live chat system** with guess validation
- **Turn-based gameplay** with automatic rotation
- **Scoring system** with time-based bonuses
- **Room management** (create/join/leave)
- **Participant management** with connection state tracking
- **Drawing tools**: Brush, eraser, shapes, bucket fill
- **Undo/Redo functionality**
- **Cross-platform support** (iOS, Android, Web, Desktop)

## Documentation Structure

- [Project Overview](./01-project-overview.md) - High-level project description
- [Backend Architecture](./02-backend-architecture.md) - Golang server implementation
- [Frontend Architecture](./03-frontend-architecture.md) - Flutter app structure
- [API Documentation](./04-api-documentation.md) - Socket.IO events and protocols
- [Database Design](./05-database-design.md) - Data models and structures
- [Deployment Guide](./06-deployment-guide.md) - How to deploy the application
- [Development Setup](./07-development-setup.md) - Local development environment
- [Testing Strategy](./08-testing-strategy.md) - Testing approaches and tools

## Quick Start

### Prerequisites
- Go 1.23.1+
- Flutter 3.29.2+
- Firebase project setup

### Backend Setup
```bash
cd backend-go
go mod download
go run src/main.go
```

### Frontend Setup
```bash
flutter pub get
flutter run
```

## Project Status

**Version**: 0.53.4+4 (Flutter) / 0.51.5 (Backend)
**Branch**: codex/fix-bucket-tool-edge-pixel-issue
**Status**: Active development

The project is currently in active development with focus on improving the drawing tools and user experience.