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
- Export-Funktion (CSV)
- Umfrage-Templates

## [2.1.0] - 2026-02-26 - Poll Types, AI Summary & Email Notifications

### 🚀 Added (2.1.0)

- 🗳️ **Poll-Typen (STANDARD & FEEDBACK)**
  - Neues Modell `PollType` mit den Typen `STANDARD` und `FEEDBACK`
  - STANDARD-Polls: Klassische Abstimmung mit Antwortoptionen
  - FEEDBACK-Polls: Freitext-basierte Umfragen mit konfigurierbaren Fragen
  - Typen bei Erstellung wählbar, separate UI-Flows je Typ
  - I18n-Übersetzungen für Poll-Typen in allen 6 Sprachen
- ❓ **Feedback-Fragen (Feedback Polls)**
  - Neues Modell `FeedbackQuestion` mit `QuestionType` (Text, Skala, Mehrfachauswahl etc.)
  - `FeedbackQuestionRequest` / `FeedbackQuestionResponse` DTOs
  - Fragen beim Erstellen und Bearbeiten einer Umfrage konfigurierbar
  - IDs bestehender Fragen werden bei Updates erhalten (`fccf96a`)
  - `FeedbackResultsWidget` für strukturierte Ergebnisdarstellung
  - `FeedbackPublicSummaryWidget` für öffentliche Zusammenfassungen
  - `FeedbackAnswerWidget` für die Antwort-Eingabe in der Poll-Ansicht
- 🤖 **KI-Zusammenfassung (AI Summary)**
  - Neuer `AiSummaryService` und `AiSummaryRepository` im Backend
  - Automatische KI-generierte Zusammenfassung für FEEDBACK-Polls
  - Asynchrones Generieren mit `generating`-Status und Polling für Updates
  - AI-Summary-Vorschau in der `PollCard` auf der Startseite
  - Öffentliche AI-Summary in der Detail-Ansicht (nach Ablauf / Admin-Ansicht)
  - Prompt begrenzt auf max. 1000 Zeichen
  - Markdown-Rendering der KI-Zusammenfassungen (`flutter_markdown`)
  - CommandLineRunner zeigt beim Start Verbindungsstatus zum AI-Server
- 📧 **E-Mail-Benachrichtigungen bei Poll-Erstellung**
  - Neuer `EmailService` im Backend mit SMTP-Unterstützung
  - HTML-E-Mail-Template `poll-created.html` via Thymeleaf
  - E-Mail-Versand nur beim Erstellen (nicht beim Bearbeiten) einer Umfrage
  - SMTP-Konfiguration via Umgebungsvariablen (`.env.example` aktualisiert)
- ⏱️ **Ablauf-Presets im Poll-Formular**
  - Schnellauswahl für gängige Ablaufzeiten (z. B. 1 h, 1 d, 1 Woche)
  - E-Mail-Adresse nur im Erstellungs-Formular sichtbar (nicht im Bearbeitungs-Formular)
- ☑️ **Multiple Choice für STANDARD-Polls**
  - Mehrere Antwortoptionen gleichzeitig auswählbar
  - Einstellbar per Toggle im Poll-Formular
- ⚡ **Vote-Caching**
  - Vote-Daten werden in `PollCard` und `PollScreen` gecacht, um redundante API-Aufrufe zu reduzieren
- 🛡️ **Rate-Limiting-Verbesserungen**
  - Rate-Limiting-Konfiguration direkt in `docker-compose.yml` und `docker-compose.local.yml` konfigurierbar
  - Enable/Disable-Option für lokale Entwicklung
  - CommandLineRunner gibt Konfiguration beim Start aus
  - Erhöhte Standardlimits (allgemein und Votes)

### 🎨 Changed (2.1.0)

- **Flutter SDK**: Version `3.27.1` → `3.41.2` (Dockerfile gepinnt auf Stable)
- **PDF-Export**: Nur noch für FEEDBACK-Polls verfügbar (Admin- und öffentliche Ansicht), entfernt für STANDARD-Polls
- **Anzeige Antworten**: FEEDBACK-Polls zeigen Response-Anzahl statt Vote-Buttons; Vote-Daten werden nur für STANDARD-Polls geladen
- **`PollResponse`**: Enthält nun `feedbackQuestions`-Liste
- **`CreatePollRequest` / `UpdatePollRequest`**: Erweitert um `pollType` und `feedbackQuestions`
- **I18n**: `question`-Feld zu allen Sprach-JSONs hinzugefügt; Poll-Typ-Übersetzungen ergänzt
- **`home_screen.dart`**: Dynamische Typen durch `Poll`/`Option` ersetzt; fehlender i18n-Key `create.success.withAdmin` ergänzt

### 🐛 Fixed (2.1.0)

- **Flutter Dockerfile**: BOM aus `entrypoint.sh` entfernt; Flutter auf `3.27.1 stable` gepinnt (behebt `CupertinoPageTransitionsBuilder`-Fehler); danach Update auf `3.41.2`
- **ENTRYPOINT**: Expliziter `/bin/sh`-Interpreter verhindert Exec-Fehler auf NAS-Systemen
- **`mvnw` / `maven-wrapper.properties`**: Zeilenenden normalisiert (CRLF → LF)
- **`.env.example`**: Abschließende Kommas in SMTP-Konfiguration entfernt

### 🔧 Upgrade Notes (2.1.0)

1. **`.env` anpassen** – neue SMTP- und AI-Server-Variablen eintragen (siehe `.env.example`):
   ```
   SMTP_HOST=smtp.example.com
   SMTP_PORT=587
   SMTP_USERNAME=...
   SMTP_PASSWORD=...
   AI_SERVER_URL=http://localhost:11434
   ```
2. **Stack neu starten**:
   ```bash
   docker compose pull
   docker compose up -d
   ```
3. **Frontend-Code-Generator** nach Änderungen ausführen:
   ```bash
   cd frontend
   dart run build_runner build --delete-conflicting-outputs
   ```

## [2.0.0] - 2026-02-24 - Architecture Migration (Spring Boot + MongoDB)

### 💥 Breaking Changes (2.0.0)

- **Backend komplett neu**: Migration von Supabase (PostgreSQL, Kong, GoTrue, PostgREST, Realtime, Edge Functions) auf **Spring Boot 3.3 + MongoDB 7**
- **Datenbank gewechselt**: Von PostgreSQL (relational, RLS) auf MongoDB (NoSQL, Document Store)
- **Keine Rückwärtskompatibilität**: Daten aus dem alten Supabase-Stack müssen manuell migriert werden
- **API-Endpunkte geändert**: Neue REST API unter `/api/polls` und `/api/comments` (statt PostgREST `/rest/v1/`)

### 🚀 Added (2.0.0)

- ☕ **Spring Boot 3.3 Backend** mit Java 21
  - Eigene REST Controllers für Polls und Comments
  - API-Key-Authentifizierung via `ApiKeyAuthFilter`
  - Rate Limiting (60 req/min allgemein, 10 req/min für Votes)
  - Spring Actuator für `/health` und `/info` Endpoints
  - CORS konfigurierbar über Umgebungsvariablen
- 🍃 **MongoDB 7** als Datenbank
  - Flexible Document-basierte Datenstruktur
  - Spring Data MongoDB Repositories
  - Auto-Index-Erstellung
- 🧹 **Integrierter Cleanup-Service** im Backend
  - `@Scheduled` Cron-Job für automatische Bereinigung abgelaufener Umfragen
  - Stündlich (konfigurierbar via `CLEANUP_CRON`)
  - Ersetzt den separaten `pollino-cleanup` Docker Container
- 🚀 **CI/CD für Backend**
  - Neuer GitHub Actions Workflow `backend-docker-build.yml`
  - Automatischer Docker-Image-Build und Push auf DockerHub (`ahmadre/pollino-backend`) bei Änderungen auf `main`
- 🐳 **Neues `docker-compose.local.yml`** für lokale Entwicklung
  - Baut alle Images lokal statt sie von Docker Hub zu pullen

### 🎨 Changed (2.0.0)

- **Vereinfachte Infrastruktur**: Nur noch 3 Container (MongoDB, Backend, Frontend) statt 15+ Supabase-Services
- **Frontend Services**: API-Aufrufe gehen direkt an Spring Boot statt über Kong/PostgREST
- **GitHub Actions aufgeräumt**:
  - Frontend-Workflow: `develop`-Branch und PR-Trigger entfernt, nur `main` + `workflow_dispatch`
  - `poll-cleanup-docker-build.yml` entfernt (nicht mehr benötigt)
  - Alle Workflows: Tags vereinfacht (`sha-` + `latest`), Build-Step-IDs korrigiert
- **Docker Compose**: Production-Stack (`docker-compose.yml`) zieht Images von DockerHub (`ahmadre/pollino-backend`, `ahmadre/pollino-frontend`)

### 🐛 Fixed (2.0.0)

- **TimePicker-Validierung**: „Geben Sie eine gültige Uhrzeit ein"-Fehler bei benutzerdefinierter Ablaufzeit behoben (Material 3 Input-Modus Bug)
- **Docker CRLF-Fixes**: Windows-Zeilenenden (`\r\n`) in `mvnw`, `maven-wrapper.properties` und `entrypoint.sh` werden automatisch im Dockerfile bereinigt
- **Frontend Compile-Fehler**: 5 Fehler in `poll_bloc.dart`, `admin_screen.dart`, `poll_screen.dart` und `timezone_demo.dart` behoben (fehlende Parameter, Typ-Mismatch)

### 🗑️ Removed (2.0.0)

- Supabase Stack (GoTrue Auth, PostgREST, Realtime, Storage, Edge Functions, Supabase Studio)
- Kong API Gateway
- Logflare Analytics
- Supavisor Connection Pooler
- Image Proxy
- Vector Logging
- Separater `pollino-cleanup` Docker Container
- PostgreSQL und zugehörige SQL-Migrationen (werden als Legacy-Referenz im `volumes/` Ordner behalten)

### 🔧 Upgrade Notes (2.0.0)

> ⚠️ Dies ist ein Major Release mit Breaking Changes.

1. **Alte Container stoppen und entfernen**:
   ```bash
   docker compose down -v --remove-orphans
   ```
2. **Neuen Stack starten**:
   ```bash
   docker compose up -d
   ```
3. **Frontend neu generieren**:
   ```bash
   cd frontend
   dart run build_runner build --delete-conflicting-outputs
   ```
4. **Daten-Migration**: Bestehende Umfragen aus PostgreSQL müssen manuell nach MongoDB überführt werden.

## [1.0.1] - 2025-10-13 - UI Polish & i18n

### 🚀 Added (1.0.1)

- Globales Popup-Menü-Theme: Abgerundete Ecken und weißer Hintergrund in der gesamten App
- Globale Dialog-Themes (Alert/Simple), DatePicker und TimePicker: Weißer Hintergrund, runde Ecken, konsistenter Look
- Zentrale Breitenbegrenzung für Dialoge via `DialogTheme.insetPadding` für angenehme Maximalbreite auf großen Bildschirmen
- PDF-Export: Umfragen als PDF herunterladen (Aktion im Drei-Punkte-Menü)

### 🎨 Changed (1.0.1)

- Harte Text-Strings in Poll- und Home-Screen durch i18n-Keys ersetzt
- Neue Übersetzungs-Keys hinzugefügt und in allen 6 Sprachen gepflegt:
  - `actions.more`, `actions.exportPdf`
  - `poll.noData`
  - `poll.voting.validation.selectAtLeastOne`, `poll.voting.validation.enterName`
  - `poll.voting.successSingle`, `poll.voting.successMultiple`
  - `poll.votingExpiredDetailed`

### 🐛 Fixed (1.0.1)

- Dialoge waren auf großen Displays zu breit – nun konsistent begrenzt
- Fehlende Übersetzungen (u. a. Share-Fehler, „Abgelaufen“/Auto-Delete-Hinweis) ergänzt

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

### 🚀 Added (0.2.0)

- 🔧 Admin-Edit-Feature: Vollständige Umfrage-Bearbeitungsfunktionalität
  - Neue `EditPollScreen` für Administratoren
  - Wiederverwendbare `PollForm` Widget-Komponente
  - Admin-Token basierte Berechtigung
  - Vollständige Bearbeitung aller Umfrage-Eigenschaften
  - Routing-Integration für Edit-Funktionalität
- 📸 Screenshot-Dokumentation: Visuelle Projektdokumentation
  - High-Quality Screenshots der wichtigsten App-Bereiche
  - Poll-Ansicht, Admin-Dashboard, und Management-Interface
  - Optimierte Bildgrößen für README-Integration

### 🌐 Enhanced (0.2.0)

- 🌍 Erweiterte I18n-Unterstützung: Vollständige Übersetzungen
  - Admin-Edit-Interface in allen 6 unterstützten Sprachen
  - Arabisch (ar_SA): 50+ neue Übersetzungsschlüssel
  - Englisch (en_GB): Komplette Admin-Interface-Übersetzungen
  - Japanisch (ja_JP): 50+ neue Übersetzungsschlüssel
  - Deutsche, Französische, Spanische Übersetzungen erweitert
  - Konsistente Terminologie über alle Sprachen hinweg

### 🐛 Fixed (0.2.0)

- 🔢 Datenbank-Sequenz-Fixes: Kritische ID-Generierungsprobleme behoben
  - Neue Migration `001_fix_poll_options_sequence.sql` für Sequenz-Synchronisation
  - PostgreSQL-Funktion `fix_poll_options_sequence()` für automatische Reparatur
  - Behebt „duplicate key value violates unique constraint poll_options_pkey“ Fehler
  - Robuste Sequenz-Verwaltung für `poll_options` Tabelle
- ⚡ Retry-Mechanismus: Verbesserte Fehlerbehandlung
  - Implementierung eines Retry-Mechanismus für `poll_options` Insertion
  - Automatische Wiederholung bei Sequenz-Konflikten
  - Verbesserte Robustheit bei simultanen Umfrage-Erstellungen
- 🧹 UI-Bereinigung: Interface-Optimierungen
  - Entfernung toter Buttons in der Poll-Screen
  - Saubere Routing-Pfade ohne Duplikate
  - Verbesserte Datenintegrität bei Updates (keine Datenverluste)

### 🎨 Changed (0.2.0)

- 📱 README-Optimierung: Fokussierte Dokumentation
  - Entfernung redundanter Screenshots (admin.jpg, dashboard.jpg)
  - Konzentration auf die wichtigste Poll-Ansicht
  - Optimierte Dateigröße und Ladezeiten
  - Klarere visuelle Hierarchie in der Dokumentation

### 🏗️ Technical (0.2.0)

- 🏗️ Code-Refaktorierung: Verbesserte Architektur
  - Extraktion der `PollForm` als wiederverwendbare Komponente
  - Separation of Concerns zwischen Create und Edit-Funktionalität
  - Optimierte Service-Layer für Umfrage-Operationen
  - Erweiterte Error-Handling-Mechanismen

## [0.1.0] - 2025-10-07 - Alpha Release

### 🚀 Added (0.1.0)

- Like System: Vollständige Like-Funktionalität für Umfragen
  - Lokale Speicherung mit Hive statt SharedPreferences
  - Anonyme Likes ohne Benutzerregistrierung
  - Live-Updates der Like-Counts
  - Optimistische UI-Updates
  - Database Functions für increment/decrement
- I18n Unterstützung: Mehrsprachige Unterstützung
  - Deutsch, Englisch, Französisch, Spanisch, Japanisch, Arabisch
  - Automatische Systemspracherkennung
  - Live-Sprachenwechsel ohne App-Neustart
  - Reaktive Locale-Updates mit StreamController
- Automatische Poll-Bereinigung:
  - Docker Container-basierte Cleanup-Jobs alle 15 Minuten
  - Database Triggers für automatisches Löschen abgelaufener Umfragen
  - Konfigurierbare `auto_delete_after_expiry` Option
  - Logging aller Cleanup-Operationen
- Navigation Verbesserungen:
  - Schutz vor doppelter Navigation nach dem Abstimmen
  - PopScope für saubere Hardware-Zurück-Button-Behandlung
  - Optimierte Pagination ohne Endlos-Loading
  - Visuelles Feedback bei Navigation-Sperren

### 🎨 Changed (0.1.0)

- UI Vereinfachung: Entfernung unnötiger Tabs (Startseite, Dateien, Fotos)
  - Fokus auf Umfrage-Funktionalität
  - Reduzierte UI-Komplexität
  - Klarere Navigation
- Clean Architecture: Implementierung von Domain-Driven Design (DDD)
  - Repository Pattern mit Clean Architecture Prinzipien
  - BLoC State Management für bessere Testbarkeit
  - Dependency Injection mit GetIt
  - Trennung von Business Logic und UI
- Umfrage-Features:
  - Multiple Choice Abstimmungen
  - Anonyme und namentliche Abstimmungen
  - Umfrage-Erstellung mit Ablaufzeiten
  - Real-time Vote-Updates via Supabase Realtime
  - Ablaufzeit-Anzeige mit Live-Countdown

### 🔧 Fixed (0.1.0)

- Navigation: Verhindert „Nirvana“ white screen durch doppelte Navigation
  - Implementierung von Navigation-Guards
  - Korrekte PopScope-Behandlung
  - Race Condition Schutz
- Pagination: CircularProgressIndicator stoppt korrekt bei Ende der Liste
  - Synchronisierte Count-Queries mit Filterbedingungen
  - Korrekte `hasMore`-Berechnung
  - Optimierte Poll-Loading-Logic
- UI: Overflow-Probleme in verschiedenen Bildschirmgrößen
- Database: Konsistente Timezone-Behandlung für Umfrage-Ablaufzeiten
  - UTC-basierte Speicherung
  - Lokale Timezone-Konvertierung im Frontend
  - TimezoneHelper für konsistente Berechnungen

### 🏗️ Technical (0.1.0)

- Database: PostgreSQL mit Supabase RLS (Row Level Security)
  - Automatische Poll-Cleanup Functions
  - Like-System mit increment/decrement Functions
  - Erweiterte Trigger-Logik
- Frontend: Flutter 3.27.1 Web mit optimiertem Build
  - Hive für lokale Datenspeicherung
  - BLoC für State Management
  - Freezed für immutable Data Classes
- Backend: Supabase Stack mit Edge Functions
  - Real-time Updates
  - Row Level Security
  - Auto-generated REST API
- DevOps: Vollständige Docker-Containerisierung
  - Multi-stage Builds
  - Health Checks
  - Automated Cleanup Services

## [0.0.1] - 2025-10-06 - Initial Alpha

### 🚀 Added (0.0.1)

- Grundlegende Umfrage-Funktionalität:
  - Umfragen erstellen und anzeigen
  - Einfache Abstimmungen
  - Supabase Integration
  - Basic CRUD Operations
- Docker Setup: Vollständige Containerisierung
  - Docker Compose mit allen Services
  - Entwicklungs- und Produktions-Konfigurationen
  - Automatisierte Service-Orchestrierung
- Projekt Setup: Flutter Web + Supabase Backend
  - Flutter Web für responsive UI
  - Supabase für Backend-as-a-Service
  - PostgreSQL als primäre Datenbank
- Basis UI: Grundlegende Benutzeroberfläche
  - Material Design 3
  - Responsive Layout
  - Poll-Karten Design

### 🏗️ Infrastructure (0.0.1)

- Supabase Stack: Auth, Database, Real-time, Storage
  - GoTrue für Authentifizierung
  - PostgREST für automatische REST API
  - Realtime für Live-Updates
- Flutter Web: Responsive Design
  - Single Page Application
  - Material Design Components
  - State Management Setup
- Docker Compose: Multi-Service Setup
  - Development und Production Konfigurationen
  - Persistent Volumes
  - Service Dependencies
- Kong Gateway: API Management
  - Reverse Proxy
  - Rate Limiting
  - Security Headers
- PostgreSQL: Relationale Datenbank
  - Strukturierte Datenmodelle
  - Foreign Key Constraints
  - Indexing für Performance

### 📝 Documentation (0.0.1)

- README: Umfassende Projektdokumentation
- Docker: Setup und Deployment Guides
- Architecture: System Design Diagramme
- Database: Schema Dokumentation

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
