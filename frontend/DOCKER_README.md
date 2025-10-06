# Flutter Web Docker Integration

Diese Konfiguration fügt Flutter Web als Service zur Supabase Docker Compose Umgebung hinzu.

## Service Details

### Flutter Web Service (`flutter-web`)
- **Container Name**: `pollino-flutter-web`
- **Port**: `3001` (Host) → `8080` (Container)
- **Build Context**: `./frontend`
- **Web Renderer**: CanvasKit für optimale Performance
- **Base URL**: `/` (Root-Pfad)

### Nginx Konfiguration
- **Webserver**: Nginx 1.25-alpine
- **Features**:
  - Gzip-Kompression für bessere Performance
  - Caching-Strategien für statische Assets
  - SPA-Routing Support (alle Routen → index.html)
  - Sicherheits-Header
  - Health Check Endpoint (`/health`)

## Umgebung & Konfiguration

### Build Arguments
Die folgenden Supabase-Konfigurationen werden zur Build-Zeit übertragen:
- `SUPABASE_URL`: http://kong:8000 (interner Kong Service)
- `SUPABASE_ANON_KEY`: ${ANON_KEY} (aus .env)
- `SUPABASE_SERVICE_ROLE_KEY`: ${SERVICE_ROLE_KEY} (aus .env)

### Environment-Klasse
Die `Environment`-Klasse in `lib/env.dart` unterstützt:
- Compile-time Konfiguration über Build-Args
- Runtime-Konfiguration für lokale Entwicklung
- Automatische Fallback-Werte

## Verwendung

### Services starten
```bash
# Alle Services inklusive Flutter Web starten
docker compose up

# Mit Development-Helpers
docker compose -f docker-compose.yml -f ./dev/docker-compose.dev.yml up

# Nur Flutter Web neu builden
docker compose build flutter-web
docker compose up flutter-web
```

### Zugriff
- **Flutter Web App**: http://localhost:3001
- **Supabase Studio**: http://localhost:54323
- **Kong API Gateway**: http://localhost:8000

### Health Checks
- Flutter Web Health: http://localhost:3001/health
- Automatische Health Checks alle 10s

## Architektur

```
Internet → Flutter Web (Port 3001) → Kong (Port 8000) → Supabase Services
                ↓
            Direct DB Access via Supabase Client
                ↓
           PostgreSQL (Port 5432)
```

### Netzwerk-Kommunikation
- Flutter Web kommuniziert über Kong API Gateway
- Direkte Datenbankverbindung via Supabase Client
- Real-time Updates über WebSocket (Realtime Service)

## Optimierungen

### Performance
- Multi-Stage Docker Build für minimale Image-Größe
- Nginx mit optimierten Caching-Einstellungen
- Gzip-Kompression für alle Text-Assets
- CanvasKit Renderer für bessere Web-Performance

### Sicherheit
- Non-root User in Nginx Container
- Sicherheits-Header (CSP, XSS-Protection, etc.)
- Minimales Alpine Linux Base Image
- Health Checks für Container-Überwachung

### Development
- Hot Reload Support für lokale Entwicklung
- Separate Docker Compose Profile
- Volume Mounts für schnelle Entwicklung
- Detaillierte Logs und Debug-Informationen

## Troubleshooting

### Common Issues
1. **Build Fehler**: Überprüfe Flutter/Dart SDK Versionen
2. **Supabase Connection**: Überprüfe Kong Service Status
3. **Asset Loading**: Prüfe Nginx Logs: `docker compose logs flutter-web`

### Debug Commands
```bash
# Service Status prüfen
docker compose ps

# Logs anzeigen
docker compose logs flutter-web

# In Container shell
docker compose exec flutter-web sh

# Service neu starten
docker compose restart flutter-web
```