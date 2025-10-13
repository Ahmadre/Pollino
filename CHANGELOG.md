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

## [1.0.0] - 2025-10-13 - First Stable Release

### 🚀 Added (1.0.0)

- Drag & Drop für Antwortoptionen in Erstellen- und Bearbeiten-Flow
  - Reorder per ReorderableListView mit eigenem Linke-Seiten-Handle
  - Persistente Reihenfolge über neues Feld `option_order`
- Tooltips zeigen die Namen von Teilnehmenden an, sofern diese nicht anonym abgestimmt haben
  - Gilt auf Startseite (Karten) und Detailseite (Diagramme)
- Beschreibung der Umfrage in der UI (ergänzend zur DB)

### 🎨 Changed (1.0.0)

- Anonyme Umfragen werden auf der Startseite nicht mehr gelistet
  - Zugriff nur noch per Direktlink (/poll/:id)
- Sortierlogik der Optionen:
  - Ohne Stimmen: Reihenfolge gemäß `option_order`
  - Mit Stimmen: Sortierung wie bisher nach Anzahl der Stimmen (absteigend)
- UI-Bedienung: Ein einziger Drag-Handle links; der automatische rechte Handle wurde entfernt

### 🐛 Fixed (1.0.0)

- Hive-Deserialisierung für neues Feld `order` abgesichert
  - Einführung eines `SafeOptionAdapter`, der Null-Werte für `order` auf 0 setzt
- Entferntes doppeltes Drag-Icon, das das Schließen (X) blockierte

### 🗄️ Database / Migration (1.0.0)

- Neue Migration: `004_add_poll_options_order.sql`
  - Spalte `option_order INTEGER` in `poll_options`
  - Initiale Befüllung/Indexierung und Query-Anpassungen

### 🔧 Upgrade Notes (1.0.0)

- Datenbankmigration anwenden (siehe volumes/db/migrations/004_add_poll_options_order.sql)
- Frontend neu bauen und Generatoren ausführen:
  - `dart run build_runner build --delete-conflicting-outputs`
- Optional Caches bereinigen:
  - `flutter clean` (besonders nach Schema-/Adapter-Updates)

## [0.2.0] - 2025-10-10 - Admin & Stability Release

### 🚀 Added
- **🔧 Admin-Edit-Feature**: Vollständige Umfrage-Bearbeitungsfunktionalität
  - Neue `EditPollScreen` für Administratoren
  - Wiederverwendbare `PollForm` Widget-Komponente
  - Admin-Token basierte Berechtigung
  - Vollständige Bearbeitung aller Umfrage-Eigenschaften
  - Routing-Integration für Edit-Funktionalität
- **📸 Screenshot-Dokumentation**: Visuelle Projektdokumentation
  - High-Quality Screenshots der wichtigsten App-Bereiche
  - Poll-Ansicht, Admin-Dashboard, und Management-Interface
  - Optimierte Bildgrößen für README-Integration

### 🌐 Enhanced
- **🌍 Erweiterte I18n-Unterstützung**: Vollständige Übersetzungen
  - Admin-Edit-Interface in allen 6 unterstützten Sprachen
  - Arabisch (ar_SA): 50+ neue Übersetzungsschlüssel
  - Englisch (en_GB): Komplette Admin-Interface-Übersetzungen
  - Japanisch (ja_JP): 50+ neue Übersetzungsschlüssel
  - Deutsche, Französische, Spanische Übersetzungen erweitert
  - Konsistente Terminologie über alle Sprachen hinweg

### 🐛 Fixed
- **🔢 Datenbank-Sequenz-Fixes**: Kritische ID-Generierungsprobleme behoben
  - Neue Migration `001_fix_poll_options_sequence.sql` für Sequenz-Synchronisation
  - PostgreSQL-Funktion `fix_poll_options_sequence()` für automatische Reparatur
  - Behebt "duplicate key value violates unique constraint poll_options_pkey" Fehler
  - Robuste Sequenz-Verwaltung für poll_options Tabelle
- **⚡ Retry-Mechanismus**: Verbesserte Fehlerbehandlung
  - Implementierung eines Retry-Mechanismus für poll_options Insertion
  - Automatische Wiederholung bei Sequenz-Konflikten
  - Verbesserte Robustheit bei simultanen Umfrage-Erstellungen
- **🧹 UI-Bereinigung**: Interface-Optimierungen
  - Entfernung toter Buttons in der Poll-Screen
  - Saubere Routing-Pfade ohne Duplikate
  - Verbesserte Datenintegrität bei Updates (keine Datenverluste)

### 🎨 Changed
- **📱 README-Optimierung**: Fokussierte Dokumentation
  - Entfernung redundanter Screenshots (admin.jpg, dashboard.jpg)
  - Konzentration auf die wichtigste Poll-Ansicht
  - Optimierte Dateigröße und Ladezeiten
  - Klarere visuelle Hierarchie in der Dokumentation

### 🏗️ Technical
- **🏗️ Code-Refaktorierung**: Verbesserte Architektur
  - Extraktion der `PollForm` als wiederverwendbare Komponente
  - Separation of Concerns zwischen Create und Edit-Funktionalität
  - Optimierte Service-Layer für Umfrage-Operationen
  - Erweiterte Error-Handling-Mechanismen

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