# Changelog

Alle bemerkenswerten Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.0.0/),
und dieses Projekt folgt [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### 🔮 Planned
- Mobile App (iOS/Android) mit Flutter
- Push-Benachrichtigungen für neue Umfragen
- Benutzer-Authentifizierung und Profile
- Umfrage-Kategorien und Tags
- Export-Funktionen (PDF, CSV)
- Umfrage-Templates
- Kommentar-System für Umfragen

## [0.1.0] - 2025-10-07 - Alpha Release

### 🚀 Added
- **Like System**: Vollständige Like-Funktionalität für Umfragen
  - Lokale Speicherung mit Hive statt SharedPreferences
  - Anonyme Likes ohne Benutzerregistrierung
  - Live-Updates der Like-Counts
  - Optimistische UI-Updates
  - Database Functions für increment/decrement
- **I18n Unterstützung**: Mehrsprachige Unterstützung
  - Deutsch, Englisch, Französisch, Spanisch, Japanisch, Arabisch
  - Automatische Systemspracherkennung
  - Live-Sprachenwechsel ohne App-Neustart
  - Reaktive Locale-Updates mit StreamController
- **Automatische Poll-Bereinigung**: 
  - Docker Container-basierte Cleanup-Jobs alle 15 Minuten
  - Database Triggers für automatisches Löschen abgelaufener Umfragen
  - Konfigurierbare auto_delete_after_expiry Option
  - Logging aller Cleanup-Operationen
- **Navigation Verbesserungen**:
  - Schutz vor doppelter Navigation nach dem Abstimmen
  - PopScope für saubere Hardware-Zurück-Button-Behandlung
  - Optimierte Pagination ohne Endlos-Loading
  - Visuelles Feedback bei Navigation-Sperren

### 🎨 Changed
- **UI Vereinfachung**: Entfernung unnötiger Tabs (Startseite, Dateien, Fotos)
  - Fokus auf Umfrage-Funktionalität
  - Reduzierte UI-Komplexität
  - Klarere Navigation
- **Clean Architecture**: Implementierung von Domain-Driven Design (DDD)
  - Repository Pattern mit Clean Architecture Prinzipien  
  - BLoC State Management für bessere Testbarkeit
  - Dependency Injection mit GetIt
  - Trennung von Business Logic und UI
- **Umfrage-Features**:
  - Multiple Choice Abstimmungen
  - Anonyme und namentliche Abstimmungen
  - Umfrage-Erstellung mit Ablaufzeiten
  - Real-time Vote-Updates via Supabase Realtime
  - Ablaufzeit-Anzeige mit Live-Countdown

### 🔧 Fixed
- **Navigation**: Verhindert "Nirvana" white screen durch doppelte Navigation
  - Implementierung von Navigation-Guards
  - Korrekte PopScope-Behandlung
  - Race Condition Schutz
- **Pagination**: CircularProgressIndicator stoppt korrekt bei Ende der Liste
  - Synchronisierte Count-Queries mit Filterbedingungen
  - Korrekte hasMore-Berechnung
  - Optimierte Poll-Loading-Logic
- **UI**: Overflow-Probleme in verschiedenen Bildschirmgrößen
- **Database**: Konsistente Timezone-Behandlung für Umfrage-Ablaufzeiten
  - UTC-basierte Speicherung
  - Lokale Timezone-Konvertierung im Frontend
  - TimezoneHelper für konsistente Berechnungen

### 🏗️ Technical
- **Database**: PostgreSQL mit Supabase RLS (Row Level Security)
  - Automatische Poll-Cleanup Functions
  - Like-System mit increment/decrement Functions
  - Erweiterte Trigger-Logik
- **Frontend**: Flutter 3.27.1 Web mit optimiertem Build
  - Hive für lokale Datenspeicherung
  - BLoC für State Management
  - Freezed für immutable Data Classes
- **Backend**: Supabase Stack mit Edge Functions
  - Real-time Updates
  - Row Level Security
  - Auto-generated REST API
- **DevOps**: Vollständige Docker-Containerisierung
  - Multi-stage Builds
  - Health Checks
  - Automated Cleanup Services

## [0.0.1] - 2025-10-06 - Initial Alpha

### 🚀 Added
- **Grundlegende Umfrage-Funktionalität**:
  - Umfragen erstellen und anzeigen
  - Einfache Abstimmungen
  - Supabase Integration
  - Basic CRUD Operations
- **Docker Setup**: Vollständige Containerisierung
  - Docker Compose mit allen Services
  - Entwicklungs- und Produktions-Konfigurationen
  - Automatisierte Service-Orchestrierung
- **Projekt Setup**: Flutter Web + Supabase Backend
  - Flutter Web für responsive UI
  - Supabase für Backend-as-a-Service
  - PostgreSQL als primäre Datenbank
- **Basis UI**: Grundlegende Benutzeroberfläche
  - Material Design 3
  - Responsive Layout
  - Poll-Karten Design

### 🏗️ Infrastructure
- **Supabase Stack**: Auth, Database, Real-time, Storage
  - GoTrue für Authentifizierung
  - PostgREST für automatische REST API
  - Realtime für Live-Updates
- **Flutter Web**: Responsive Design
  - Single Page Application
  - Material Design Components
  - State Management Setup
- **Docker Compose**: Multi-Service Setup
  - Development und Production Konfigurationen
  - Persistent Volumes
  - Service Dependencies
- **Kong Gateway**: API Management
  - Reverse Proxy
  - Rate Limiting
  - Security Headers
- **PostgreSQL**: Relationale Datenbank
  - Strukturierte Datenmodelle
  - Foreign Key Constraints
  - Indexing für Performance

### 📝 Documentation
- **README**: Umfassende Projektdokumentation
- **Docker**: Setup und Deployment Guides
- **Architecture**: System Design Diagramme
- **Database**: Schema Dokumentation

---

## Semantic Versioning Erklärung

**MAJOR.MINOR.PATCH** Format:

- **MAJOR** (0 → 1): Breaking changes, nicht rückwärts kompatibel
- **MINOR** (0.0 → 0.1): Neue Features, rückwärts kompatibel  
- **PATCH** (0.1.0 → 0.1.1): Bug fixes, rückwärts kompatibel

**Pre-Release Kennzeichnungen:**
- `alpha`: Sehr frühe Version, instabil
- `beta`: Feature-komplett, aber noch in Testing
- `rc`: Release Candidate, stabil und bereit für Release

**Build Metadata:**
- `+1`: Build-Nummer für interne Versionierung