<div align="center">
  <img src="frontend/web/logo.svg" width="120" height="120" alt="Pollino Logo"/>

# Pollino

> **Your comprehensive Poll App by your side**

</div>

[![CI Build](https://github.com/Ahmadre/Pollino/actions/workflows/frontend-docker-build.yml/badge.svg)](https://github.com/Ahmadre/Pollino/actions/workflows/frontend-docker-build.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.27.1-blue.svg)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-2.x-green.svg)](https://supabase.com)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Eine moderne, vollständig containerisierte Umfrage-Anwendung, entwickelt mit Flutter für das Frontend und Supabase als Backend-as-a-Service. Pollino ermöglicht es Benutzern, einfach Umfragen zu erstellen, zu verwalten und daran teilzunehmen.

<div align="center">
  <img src="frontend/assets/images/screenshots/poll.jpg" height="500" alt="Pollino - Interactive Poll Interface"/>
</div>

> **📸 Visuelle Dokumentation**: Das Interface zeigt die hauptsächliche Umfrage-Funktionalität mit Echtzeit-Abstimmungen, Like- und Kommentar-System und responsivem Design.

## 🆕 Was ist neu in 1.0.1

- Einheitliches Popup-Menü-Design: abgerundete Ecken und weißer Hintergrund app-weit
- Konsistente Dialoge (Alert/Simple), DatePicker und TimePicker: weißer Hintergrund, runde Ecken
- Zentrale maximale Dialogbreite über Theme (`DialogTheme.insetPadding`) – angenehme Darstellung auf großen Bildschirmen
- I18n: Harte Texte in Poll- und Home-Screen durch Übersetzungs-Keys ersetzt; neue Keys in allen 6 Sprachen ergänzt

## 🆕 Was ist neu in 1.0.0

- Drag & Drop Sortierung der Antwortoptionen mit persistenter Reihenfolge (option_order)
- Anonyme Umfragen erscheinen nicht mehr auf der Startseite; Zugriff nur per Direktlink (z. B. /poll/5)
- Tooltips zeigen Namen der Teilnehmenden, sofern diese nicht anonym abgestimmt haben
- Verbesserte Edit-Funktion und stabilere Speicherung (Hive-Adapter für order-Feld)

## 🚀 Features

### Frontend (Flutter Web)

- **🎨 Responsive Design**: Optimiert für Desktop und Mobile
- **⚡ State Management**: BLoC Pattern mit flutter_bloc
- **💾 Offline Support**: Lokale Datenspeicherung mit Hive
- **🔄 Real-time Updates**: Live-Synchronisation mit Supabase
- **🧭 Navigation**: Routemaster für deklaratives Routing
- **📊 Interaktive Umfragen**: Echtzeit-Abstimmungen mit sofortigen Ergebnissen
- **↕️ Drag & Drop Reihenfolge**: Antwortoptionen per Drag & Drop sortieren (persistente Reihenfolge)
- **💬 Kommentarsystem**: Benutzer können Kommentare zu Umfragen hinzufügen und bearbeiten
- **🔧 Admin-Panel**: Umfangreiche Administrationsfunktionen für Umfrage-Verwaltung
- **✏️ Poll-Bearbeitung**: Vollständige Bearbeitung bestehender Umfragen mit Admin-Token
- **🌍 Mehrsprachigkeit**: Unterstützung für 6 Sprachen (DE, EN, FR, ES, JA, AR)
- **🔒 Anonymitätslogik**: Anonyme Umfragen werden nicht gelistet (nur Direktlink), Tooltips zeigen Namen nur bei nicht-anonymen Stimmen

### Backend (Supabase Stack)

- **🗄️ PostgreSQL Datenbank**: Relationale Datenbank mit RLS
- **🔐 Authentication**: Supabase Auth mit JWT
- **🌐 REST API**: PostgREST für automatische API-Generierung
- **⚡ Realtime**: WebSocket-basierte Live-Updates
- **📁 Storage**: Datei-Upload und -verwaltung
- **🔧 Edge Functions**: Serverless Deno-basierte Functions
- **📈 Analytics**: Integrierte Logflare Analytics
- **🔐 Admin-Funktionen**: Token-basierte Administratorrechte
- **🔄 Sequenz-Management**: Automatische Datenbank-Sequenz-Synchronisation
- **🗄️ Poll-Optionen-Order**: Neues Feld `option_order` in `poll_options` mit Indizes und konsistenter Sortierung

### DevOps & Infrastruktur

- **🐳 Docker**: Vollständig containerisiert
- **🚀 Multi-Stage Builds**: Optimierte Production Builds
- **🔄 Reverse Proxy**: Kong Gateway für API-Management
- **📊 Monitoring**: Health Checks und Logging
- **🔒 Security**: Nginx Security Headers

## 🏗️ Architektur

```mermaid
graph TB
    %% Client Layer
    subgraph "Client Layer"
        WEB[Flutter Web App<br/>Port: 3001]
        MOBILE[Flutter Mobile App<br/>Future Extension]
    end

    %% Reverse Proxy Layer
    subgraph "API Gateway"
        KONG[Kong Gateway<br/>Port: 8000<br/>API Management & Routing]
    end

    %% Application Services Layer
    subgraph "Supabase Services"
        AUTH[GoTrue Auth<br/>Port: 9999<br/>JWT Authentication]
        REST[PostgREST API<br/>Port: 3000<br/>Auto-generated REST API]
        REALTIME[Realtime<br/>Port: 4000<br/>WebSocket Updates]
        STORAGE[Storage API<br/>Port: 5000<br/>File Management]
        FUNCTIONS[Edge Functions<br/>Deno Runtime<br/>Serverless Logic]
        STUDIO[Supabase Studio<br/>Database Admin UI]
    end

    %% Data Layer
    subgraph "Data & Storage Layer"
        DB[(PostgreSQL Database<br/>Port: 5432<br/>Primary Data Store)]
        POOLER[Supavisor<br/>Connection Pooler<br/>Ports: 6543/5432]
        VOLUMES[Docker Volumes<br/>Persistent Storage]
    end

    %% Support Services
    subgraph "Infrastructure Services"
        ANALYTICS[Logflare Analytics<br/>Port: 4000<br/>Logs & Metrics]
        META[Postgres Meta<br/>Port: 8080<br/>DB Schema Management]
        IMGPROXY[Image Proxy<br/>Port: 5001<br/>Image Processing]
        VECTOR[Vector Logging<br/>Port: 9001<br/>Log Aggregation]
        CLEANUP[Poll Cleanup Service<br/>Automated Cleanup<br/>15min Intervals]
    end

    %% Data Flow Connections
    WEB --> KONG
    MOBILE -.-> KONG
  
    KONG --> AUTH
    KONG --> REST
    KONG --> REALTIME
    KONG --> STORAGE
    KONG --> FUNCTIONS
    KONG --> STUDIO

    AUTH --> DB
    REST --> DB
    REALTIME --> DB
    STORAGE --> DB
    FUNCTIONS --> DB
    STUDIO --> META
    META --> DB

    DB --> POOLER
    POOLER --> DB

    STORAGE --> IMGPROXY
    IMGPROXY --> VOLUMES

    %% Analytics & Monitoring
    AUTH -.-> ANALYTICS
    REST -.-> ANALYTICS
    REALTIME -.-> ANALYTICS
    FUNCTIONS -.-> ANALYTICS

    VECTOR -.-> ANALYTICS
  
    %% Cleanup Service Connections
    CLEANUP --> DB
    CLEANUP -.-> ANALYTICS
  
    %% Styling
    classDef frontend fill:#e1f5fe
    classDef gateway fill:#f3e5f5
    classDef service fill:#e8f5e8
    classDef database fill:#fff3e0
    classDef infrastructure fill:#fce4ec

    class WEB,MOBILE frontend
    class KONG gateway
    class AUTH,REST,REALTIME,STORAGE,FUNCTIONS,STUDIO service
    class DB,POOLER,VOLUMES database
    class ANALYTICS,META,IMGPROXY,VECTOR,CLEANUP infrastructure
```

## 📋 Voraussetzungen

- **Docker** & **Docker Compose** (v2.0+)
- **Git** für Repository-Management
- **Flutter SDK** 3.27.1+ (für lokale Entwicklung)
- **Dart SDK** 3.6.0+

## 🔧 Installation & Setup

### 1. Repository klonen

```bash
git clone https://github.com/Ahmadre/Pollino.git
cd Pollino
```

### 2. Umgebungsvariablen konfigurieren

```bash
# .env Datei erstellen (Beispiel)
cp .env.example .env

# Wichtige Variablen anpassen:
# POSTGRES_PASSWORD=your_secure_password
# JWT_SECRET=your_jwt_secret
# SUPABASE_PUBLIC_URL=http://localhost:8000
```

### 3. Services starten

```bash
# Alle Services starten
docker compose up -d

# Nur spezifische Services
docker compose up -d db auth rest flutter-web

# Mit Entwicklungstools
docker compose -f docker-compose.yml -f ./dev/docker-compose.dev.yml up -d
```

### 4. Datenbank initialisieren

```bash
# Die Datenbank wird automatisch mit Beispieldaten initialisiert
# Schema: volumes/db/init/polls_schema.sql

```

### 5. Upgrade auf 1.0.0

Falls du von einer älteren Version kommst (z. B. 0.2.0):

1. Datenbankmigration anwenden (neues Feld `option_order`):

```bash
docker compose down
docker compose up -d
```

1. Frontend neu generieren (Freezed/Build Runner):

```bash
cd frontend
dart run build_runner build --delete-conflicting-outputs
```

1. Optional Caches leeren (empfohlen bei Schema-/Adapter-Updates):

```bash
cd frontend
flutter clean
flutter pub get
```

## 🌐 Zugriff auf die Anwendung

| Service                   | URL                    | Beschreibung       |
| ------------------------- | ---------------------- | ------------------ |
| **Flutter Web App** | [http://localhost:3001](http://localhost:3001)  | Hauptanwendung     |
| **Supabase Studio** | [http://localhost:54323](http://localhost:54323) | Datenbank-Admin    |
| **API Gateway**     | [http://localhost:8000](http://localhost:8000)  | REST API Endpoint  |
| **Analytics**       | [http://localhost:4000](http://localhost:4000)  | Logflare Dashboard |

## 🏃‍♂️ Entwicklung

### Flutter Web lokal entwickeln

```bash
cd frontend

# Dependencies installieren
flutter pub get

# Development Server starten
flutter run -d web-server --web-port 3000

# Build für Produktion
flutter build web --release --web-renderer canvaskit
```

### Datenbank-Migrationen

```bash
# Schema ändern
# 1. SQL in volumes/db/init/polls_schema.sql anpassen
# 2. Services neu starten
docker compose down
docker compose up -d

# Relevante Migrationen für 1.0.0:
# volumes/db/migrations/004_add_poll_options_order.sql
```

### Logs anzeigen

```bash
# Alle Services
docker compose logs -f

# Spezifischer Service
docker compose logs -f flutter-web
docker compose logs -f db
docker compose logs -f auth
```

## 🧪 Testing

### Flutter Tests

```bash
cd frontend
flutter test
```

### API Tests

```bash
# Health Checks
curl http://localhost:3001/health
curl http://localhost:8000/health

# API Endpoints testen
curl http://localhost:8000/rest/v1/polls
```

## 📦 Deployment

### Entwicklungsumgebung

```bash
# Flutter Web optimiert bauen
docker compose build flutter-web

# Production Stack
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Environment Konfiguration

```bash
# Produktive Umgebungsvariablen setzen
export SUPABASE_PUBLIC_URL=https://your-domain.com
export POSTGRES_PASSWORD=secure_production_password
export JWT_SECRET=your_production_jwt_secret
```

## 📁 Projektstruktur

```text
Pollino/
├── 📱 frontend/                    # Flutter Web Application
│   ├── lib/
│   │   ├── bloc/                  # BLoC State Management
│   │   ├── core/                  # Core Architecture
│   │   │   ├── error/             # Error Handling
│   │   │   ├── localization/      # I18n Service & Language Support
│   │   │   ├── network/           # Network Utilities
│   │   │   ├── usecase/           # Use Case Abstractions
│   │   │   └── utils/             # Timezone & Helper Functions
│   │   ├── features/              # Feature-based Architecture
│   │   │   └── polls/             # Poll Feature Module
│   │   │       ├── data/          # Data Layer (Models, DataSources, Repositories)
│   │   │       └── domain/        # Domain Layer (Entities, UseCases, Interfaces)
│   │   ├── screens/               # UI Screens (Home, Poll Detail, Create, Edit, Admin)
│   │   ├── services/              # Application Services (Supabase, Like System)
│   │   └── widgets/               # Reusable UI Components (PollForm, etc.)
│   ├── assets/                    # Static Assets & Translations (6 Languages)
│   ├── web/                       # Web-specific Files & PWA Configuration
│   ├── test/                      # Unit & Widget Tests
│   └── build/                     # Flutter Build Output
├── 🗄️ volumes/                    # Persistent Data & Configuration
│   ├── db/                        # Database Configuration
│   │   ├── init/                  # Database Initialization Scripts
│   │   ├── migrations/            # Database Schema Migrations (7+ Files)
│   │   └── data/                  # PostgreSQL Data Directory
│   ├── functions/                 # Supabase Edge Functions
│   ├── api/                       # API Gateway Configuration
│   ├── logs/                      # Logging Configuration
│   ├── pooler/                    # Connection Pooling
│   └── storage/                   # File Storage
├── 🧹 poll-cleanup/               # Automated Poll Cleanup Service
│   ├── cleanup-script.sh          # Cleanup Logic Script
│   ├── start.sh                   # Service Startup Script
│   └── Dockerfile                 # Cleanup Service Container
├── 🔧 dev/                        # Development Tools
│   ├── docker-compose.dev.yml     # Development Override
│   └── data.sql                   # Development Sample Data
├── 🐳 docker-compose.s3.yml       # S3 Storage Extension
├── 🐳 docker-compose.yml          # Main Services Definition
├── 🔄 reset.sh                    # Database Reset Script
├── 📋 README.md                   # This Documentation
├── 📝 CHANGELOG.md                # Version History & Changes
├── 🔧 .env.example                # Environment Variables Template
├── 🔧 .env.prod                   # Production Environment Configuration
└── 📊 .vscode/                    # VS Code Configuration
    └── launch.json                # Debug Configuration
```

## 🤝 Beitragen

1. **Fork** das Repository
2. **Feature Branch** erstellen (`git checkout -b feature/amazing-feature`)
3. **Commit** deine Änderungen (`git commit -m 'Add amazing feature'`)
4. **Push** zum Branch (`git push origin feature/amazing-feature`)
5. **Pull Request** erstellen

## 🐛 Troubleshooting

### Häufige Probleme

**Docker Build Fehler:**

```bash
# Cache löschen und neu bauen
docker compose down
docker system prune -a
docker compose build --no-cache
docker compose up -d
```

**Datenbank-Verbindungsfehler:**

```bash
# Datenbank Status prüfen
docker compose ps
docker compose logs db

# Reset der Datenbank
./reset.sh
```

**Flutter Dependencies:**

```bash
cd frontend
flutter clean
flutter pub get
```

## 📄 Lizenz

Dieses Projekt ist unter der [MIT Lizenz](LICENSE) lizenziert.

## 👥 Team

- **Entwicklung**: [Ahmadre](https://github.com/Ahmadre)
- **Architektur**: Flutter + Supabase Stack
- **DevOps**: Docker + Kong + Nginx

## 📊 Tech Stack Übersicht

| Kategorie             | Technologie | Version | Zweck                |
| --------------------- | ----------- | ------- | -------------------- |
| **Frontend**    | Flutter     | 3.27.1  | Web & Mobile UI      |
| **Backend**     | Supabase    | 2.x     | Backend-as-a-Service |
| **Datenbank**   | PostgreSQL  | 15.8    | Primary Data Store   |
| **API Gateway** | Kong        | 2.8.1   | Routing & Security   |
| **Web Server**  | Nginx       | 1.25    | Static File Serving  |
| **Analytics**   | Logflare    | 1.14.2  | Logging & Monitoring |
| **Container**   | Docker      | Latest  | Containerization     |

