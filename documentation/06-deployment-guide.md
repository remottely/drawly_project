# Deployment Guide

## Overview

This guide covers deployment strategies for the Drawly application across different environments and platforms. The application consists of a Go backend server and a Flutter frontend application.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter Web   │    │  Flutter Mobile │    │ Flutter Desktop │
│   (Browser)     │    │   (iOS/Android) │    │ (macOS/Windows) │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                         WebSocket/HTTP
                                 │
                    ┌─────────────▼─────────────┐
                    │      Load Balancer       │
                    │      (nginx/HAProxy)     │
                    └─────────────┬─────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │     Go Backend Server     │
                    │    (Socket.IO + HTTP)     │
                    └─────────────┬─────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │      Database Layer       │
                    │   (PostgreSQL/Redis)      │
                    └───────────────────────────┘
```

## Environment Types

### 1. Development Environment
- **Backend**: Local Go server (localhost:5555)
- **Frontend**: Flutter development server (localhost:8081)
- **Database**: In-memory storage
- **Authentication**: Firebase development project

### 2. Staging Environment
- **Backend**: Single instance deployment
- **Frontend**: Static build served by CDN
- **Database**: Shared PostgreSQL instance
- **Authentication**: Firebase staging project

### 3. Production Environment
- **Backend**: Multiple instances with load balancing
- **Frontend**: CDN deployment with multiple regions
- **Database**: Managed PostgreSQL with replicas
- **Authentication**: Firebase production project

## Backend Deployment

### 1. Docker Deployment

#### Dockerfile
```dockerfile
# Build stage
FROM golang:1.23.1-alpine AS builder

WORKDIR /app
COPY backend-go/ .

# Download dependencies
RUN go mod download

# Build binary
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main src/main.go

# Runtime stage  
FROM alpine:latest

RUN apk --no-cache add ca-certificates
WORKDIR /root/

# Copy binary from builder stage
COPY --from=builder /app/main .

# Expose port
EXPOSE 5555

# Run the binary
CMD ["./main"]
```

#### Docker Compose (Development)
```yaml
version: '3.8'

services:
  drawly-backend:
    build:
      context: .
      dockerfile: backend-go/Dockerfile
    ports:
      - "5555:5555"
    environment:
      - PORT=5555
      - DEBUG=true
      - DATABASE_URL=postgres://user:pass@db:5432/drawly
    depends_on:
      - db
      - redis
    networks:
      - drawly-network

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: drawly
      POSTGRES_USER: drawly_user
      POSTGRES_PASSWORD: drawly_pass
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - drawly-network

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    networks:
      - drawly-network

volumes:
  postgres_data:
  redis_data:

networks:
  drawly-network:
    driver: bridge
```

#### Build and Run
```bash
# Build image
docker build -t drawly-backend -f backend-go/Dockerfile .

# Run with Docker Compose
docker-compose up -d

# View logs
docker-compose logs -f drawly-backend
```

### 2. Cloud Deployment Options

#### Google Cloud Platform (Cloud Run)

**Build Configuration (cloudbuild.yaml):**
```yaml
steps:
  # Build the container image
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/$PROJECT_ID/drawly-backend', '-f', 'backend-go/Dockerfile', '.']
  
  # Push the container image to Container Registry
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/drawly-backend']
  
  # Deploy container image to Cloud Run
  - name: 'gcr.io/cloud-builders/gcloud'
    args:
    - 'run'
    - 'deploy'
    - 'drawly-backend'
    - '--image'
    - 'gcr.io/$PROJECT_ID/drawly-backend'
    - '--region'
    - 'us-central1'
    - '--platform'
    - 'managed'
    - '--allow-unauthenticated'
```

**Deploy Commands:**
```bash
# Set project
gcloud config set project YOUR_PROJECT_ID

# Build and deploy
gcloud builds submit --config cloudbuild.yaml

# Update environment variables
gcloud run services update drawly-backend \
  --set-env-vars="DATABASE_URL=postgresql://...,REDIS_URL=redis://..."
```

#### AWS (Elastic Container Service)

**Task Definition (task-definition.json):**
```json
{
  "family": "drawly-backend",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::ACCOUNT:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "drawly-backend",
      "image": "ACCOUNT.dkr.ecr.REGION.amazonaws.com/drawly-backend:latest",
      "portMappings": [
        {
          "containerPort": 5555,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "PORT",
          "value": "5555"
        },
        {
          "name": "DATABASE_URL",
          "value": "postgresql://..."
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/drawly-backend",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

#### Heroku

**Procfile:**
```
web: ./main
```

**Deploy Commands:**
```bash
# Login to Heroku
heroku login

# Create app
heroku create drawly-backend

# Set buildpack
heroku buildpacks:set heroku/go

# Deploy
git push heroku main

# Set environment variables
heroku config:set DATABASE_URL=postgresql://...
heroku config:set PORT=5555
```

### 3. Load Balancing Configuration

#### Nginx Configuration
```nginx
upstream drawly_backend {
    server backend1:5555;
    server backend2:5555;
    server backend3:5555;
}

server {
    listen 80;
    server_name api.drawly.com;

    # WebSocket support
    location /socket.io/ {
        proxy_pass http://drawly_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket timeout settings
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://drawly_backend;
        proxy_set_header Host $host;
    }
}
```

## Frontend Deployment

### 1. Web Deployment

#### Build for Production
```bash
# Build optimized web app
flutter build web --release --web-renderer html

# Output will be in build/web/
```

#### Static Hosting Options

**Firebase Hosting:**
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(eot|otf|ttf|ttc|woff|font.css)",
        "headers": [
          {
            "key": "Access-Control-Allow-Origin",
            "value": "*"
          }
        ]
      }
    ]
  }
}
```

Deploy to Firebase:
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login and initialize
firebase login
firebase init hosting

# Deploy
firebase deploy --only hosting
```

**Vercel Deployment:**
```json
{
  "name": "drawly-web",
  "version": 2,
  "builds": [
    {
      "src": "build/web/**",
      "use": "@vercel/static"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "/index.html"
    }
  ]
}
```

**Netlify Deployment:**
```toml
[build]
  publish = "build/web"
  command = "flutter build web --release"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

### 2. Mobile App Deployment

#### iOS App Store

**Build for iOS:**
```bash
# Build iOS app
flutter build ios --release

# Or build IPA
flutter build ipa --release
```

**Deployment Steps:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Configure signing certificates
3. Archive the project
4. Upload to App Store Connect
5. Submit for review

#### Google Play Store

**Build for Android:**
```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended)
flutter build appbundle --release
```

**Deployment Steps:**
1. Sign the APK/AAB with release key
2. Upload to Google Play Console
3. Configure store listing
4. Submit for review

#### Code Signing Setup

**Android Signing (android/key.properties):**
```properties
storePassword=myStorePassword
keyPassword=myKeyPassword
keyAlias=myKeyAlias
storeFile=my-release-key.keystore
```

**iOS Signing:**
- Use Xcode automatic signing
- Or configure manual signing with provisioning profiles

### 3. Desktop App Deployment

#### Windows
```bash
# Build Windows app
flutter build windows --release

# Create installer with NSIS or Inno Setup
```

#### macOS
```bash
# Build macOS app
flutter build macos --release

# Create DMG installer
create-dmg --volname "Drawly" --window-pos 200 120 \
  --window-size 600 300 --icon-size 100 --app-drop-link 425 120 \
  "drawly.dmg" "build/macos/Build/Products/Release/"
```

#### Linux
```bash
# Build Linux app
flutter build linux --release

# Create AppImage or snap package
```

## Database Deployment

### 1. Managed Database Services

#### Google Cloud SQL
```bash
# Create instance
gcloud sql instances create drawly-db \
  --database-version=POSTGRES_15 \
  --tier=db-f1-micro \
  --region=us-central1

# Create database
gcloud sql databases create drawly --instance=drawly-db

# Create user
gcloud sql users create drawly_user \
  --instance=drawly-db \
  --password=secure_password
```

#### AWS RDS
```bash
# Create RDS instance
aws rds create-db-instance \
  --db-instance-identifier drawly-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --master-username drawly_user \
  --master-user-password secure_password \
  --allocated-storage 20
```

### 2. Redis Deployment

#### Redis Cloud
```bash
# Create Redis instance via dashboard or CLI
redis-cli -h your-redis-host -p port -a password
```

#### Self-hosted Redis
```yaml
# docker-compose.yml
redis:
  image: redis:7-alpine
  ports:
    - "6379:6379"
  volumes:
    - redis_data:/data
  command: redis-server --appendonly yes
```

## Environment Configuration

### 1. Environment Variables

**Backend (.env):**
```bash
# Server Configuration
PORT=5555
DEBUG=false
LOG_LEVEL=info

# Database
DATABASE_URL=postgresql://user:pass@host:5432/drawly
REDIS_URL=redis://host:6379

# CORS
ALLOWED_ORIGINS=https://drawly.com,https://app.drawly.com

# Firebase
FIREBASE_PROJECT_ID=drawly-prod
FIREBASE_PRIVATE_KEY_ID=...
FIREBASE_PRIVATE_KEY=...
```

**Frontend (environment configuration):**
```dart
// lib/env/prod.dart
class Environment {
  static const String apiUrl = 'https://api.drawly.com';
  static const String socketUrl = 'https://api.drawly.com';
  static const bool isProduction = true;
}
```

### 2. Configuration Management

#### Backend Configuration
```go
package config

import (
    "os"
    "strconv"
)

type Config struct {
    Port        int
    DatabaseURL string
    RedisURL    string
    Debug       bool
}

func Load() *Config {
    port, _ := strconv.Atoi(getEnv("PORT", "5555"))
    debug, _ := strconv.ParseBool(getEnv("DEBUG", "false"))
    
    return &Config{
        Port:        port,
        DatabaseURL: getEnv("DATABASE_URL", ""),
        RedisURL:    getEnv("REDIS_URL", ""),
        Debug:       debug,
    }
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}
```

## Monitoring and Logging

### 1. Application Monitoring

#### Prometheus Metrics
```go
// metrics.go
var (
    activeConnections = prometheus.NewGauge(prometheus.GaugeOpts{
        Name: "drawly_active_connections",
        Help: "Number of active WebSocket connections",
    })
    
    roomsActive = prometheus.NewGauge(prometheus.GaugeOpts{
        Name: "drawly_active_rooms",
        Help: "Number of active game rooms",
    })
)

func init() {
    prometheus.MustRegister(activeConnections)
    prometheus.MustRegister(roomsActive)
}
```

#### Health Check Endpoint
```go
func healthCheck(w http.ResponseWriter, r *http.Request) {
    status := map[string]interface{}{
        "status":     "healthy",
        "timestamp":  time.Now().Unix(),
        "version":    Version,
        "connections": len(roomUsers),
        "rooms":      len(rooms),
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(status)
}
```

### 2. Logging Configuration

#### Structured Logging
```go
import "github.com/sirupsen/logrus"

func init() {
    logrus.SetFormatter(&logrus.JSONFormatter{})
    logrus.SetLevel(logrus.InfoLevel)
    
    if os.Getenv("DEBUG") == "true" {
        logrus.SetLevel(logrus.DebugLevel)
    }
}
```

### 3. Error Tracking

#### Sentry Integration
```go
import "github.com/getsentry/sentry-go"

func init() {
    sentry.Init(sentry.ClientOptions{
        Dsn: os.Getenv("SENTRY_DSN"),
        Environment: os.Getenv("ENVIRONMENT"),
    })
}
```

## CI/CD Pipeline

### 1. GitHub Actions

**.github/workflows/deploy.yml:**
```yaml
name: Deploy to Production

on:
  push:
    branches: [ main ]

jobs:
  test:
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
        go test ./...
        
    - name: Set up Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.29.2'
        
    - name: Run frontend tests
      run: |
        flutter test

  deploy-backend:
    needs: test
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Deploy to Cloud Run
      uses: google-github-actions/deploy-cloudrun@v1
      with:
        service: drawly-backend
        image: gcr.io/${{ secrets.GCP_PROJECT_ID }}/drawly-backend
        region: us-central1
        
  deploy-frontend:
    needs: test
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.29.2'
        
    - name: Build web app
      run: flutter build web --release
      
    - name: Deploy to Firebase
      uses: FirebaseExtended/action-hosting-deploy@v0
      with:
        repoToken: '${{ secrets.GITHUB_TOKEN }}'
        firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
        projectId: drawly-prod
```

## Security Considerations

### 1. Network Security
- **HTTPS/WSS**: Enforce encrypted connections
- **CORS**: Restrict origins to known domains
- **Rate Limiting**: Implement per-client limits
- **DDoS Protection**: Use cloud provider DDoS protection

### 2. Application Security
- **Input Validation**: Sanitize all user inputs
- **Authentication**: Verify Firebase tokens
- **Authorization**: Check user permissions
- **Data Encryption**: Encrypt sensitive data at rest

### 3. Infrastructure Security
- **Firewall**: Restrict database access
- **VPC**: Use private networks
- **Secrets Management**: Use cloud secret managers
- **Regular Updates**: Keep dependencies updated

## Performance Optimization

### 1. Backend Optimization
- **Connection Pooling**: Database connection pools
- **Caching**: Redis for session and room state
- **Load Balancing**: Distribute traffic across instances
- **Resource Limits**: Set appropriate CPU/memory limits

### 2. Frontend Optimization
- **Code Splitting**: Lazy load features
- **Asset Optimization**: Compress images and fonts
- **CDN**: Use CDN for static assets
- **Caching**: Implement browser caching strategies

## Disaster Recovery

### 1. Backup Strategy
- **Database Backups**: Automated daily backups
- **Configuration Backups**: Version controlled configs
- **Asset Backups**: Backup user-generated content

### 2. Recovery Procedures
- **Database Recovery**: Point-in-time recovery
- **Application Recovery**: Blue-green deployments
- **Monitoring**: Health checks and alerting