# Alpine Linux mit curl und postgresql-client für Datenbank-Maintenance
FROM alpine:3.19

# Installiere notwendige Pakete
RUN apk --no-cache add curl postgresql-client bash

# Erstelle Verzeichnis für Scripts
WORKDIR /app

# Kopiere die Scripts
COPY cleanup-script.sh /app/cleanup-script.sh
COPY start.sh /app/start.sh

# Mache Scripts ausführbar
RUN chmod +x /app/cleanup-script.sh /app/start.sh

# Aktiviere Logging
RUN mkdir -p /var/log
RUN touch /var/log/poll-cleanup.log

# Starte über das Startup-Script
CMD ["/app/start.sh"]