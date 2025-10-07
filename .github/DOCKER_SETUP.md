# Docker Hub GitHub Actions Setup

## Benötigte GitHub Secrets

Um die automatischen Docker Builds zu aktivieren, müssen folgende Secrets in den GitHub Repository Settings konfiguriert werden:

### 1. DOCKERHUB_USERNAME

- **Wert**: [Docker Username]
- **Beschreibung**: Ihr Docker Hub Benutzername

### 2. DOCKERHUB_TOKEN

- **Wert**: Ihr Docker Hub Access Token
- **Beschreibung**: Persönlicher Access Token für Docker Hub Authentication

## Setup-Anweisungen

### Docker Hub Access Token erstellen:

1. Gehen Sie zu [Docker Hub](https://hub.docker.com/)
2. Loggen Sie sich mit Ihrem Account `ahmadre` ein
3. Navigieren Sie zu **Account Settings** → **Security**
4. Klicken Sie auf **New Access Token**
5. Geben Sie einen Namen ein (z.B. "GitHub Actions Pollino")
6. Wählen Sie die Berechtigung **Read, Write, Delete**
7. Kopieren Sie den generierten Token (wird nur einmal angezeigt!)

### GitHub Secrets konfigurieren:

1. Gehen Sie zu Ihrem GitHub Repository: `https://github.com/Ahmadre/Pollino`
2. Navigieren Sie zu **Settings** → **Secrets and variables** → **Actions**
3. Klicken Sie auf **New repository secret**
4. Erstellen Sie folgende Secrets:
   - **Name**: `DOCKERHUB_USERNAME`, **Secret**: `ahmadre`
   - **Name**: `DOCKERHUB_TOKEN`, **Secret**: `[Ihr Access Token]`

## Docker Images

Die GitHub Actions erstellen folgende Docker Images:

### Frontend (Flutter Web App)

- **Repository**: `ahmadre/pollino-frontend`
- **Trigger**: Änderungen im `frontend/` Ordner
- **Tags**:
  - `latest` (für main branch)
  - `develop` (für develop branch)
  - `sha-<commit-hash>` (für alle commits)

### Poll-Cleanup Service

- **Repository**: `ahmadre/pollino-cleanup`
- **Trigger**: Änderungen im `poll-cleanup/` Ordner
- **Tags**:
  - `latest` (für main branch)
  - `develop` (für develop branch)
  - `sha-<commit-hash>` (für alle commits)

## Workflow-Features

- ✅ **Multi-Platform Builds**: Unterstützt AMD64 und ARM64
- ✅ **Build Cache**: Verwendet GitHub Actions Cache für schnellere Builds
- ✅ **Pull Request Builds**: Testet Builds bei Pull Requests (ohne Push)
- ✅ **Branch-spezifische Tags**: Unterschiedliche Tags für main/develop
- ✅ **Security**: Secrets werden nur bei Push-Events verwendet, nicht bei PRs

## Verwendung in Docker Compose

Nach dem Setup können Sie die Images in Ihrer `docker-compose.yml` verwenden:

```yaml
services:
  frontend:
    image: ahmadre/pollino-frontend:latest
    # oder für develop branch:
    # image: ahmadre/pollino-frontend:develop
  
  poll-cleanup:
    image: ahmadre/pollino-cleanup:latest
    # oder für develop branch:
    # image: ahmadre/pollino-cleanup:develop
```
