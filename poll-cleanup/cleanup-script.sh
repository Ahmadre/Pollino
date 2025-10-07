#!/bin/bash
# Cleanup Script für abgelaufene Umfragen
# Läuft alle 15 Minuten via CRON

# Database connection parameters from environment
DB_HOST=${POSTGRES_HOST:-db}
DB_PORT=${POSTGRES_PORT:-5432}
DB_NAME=${POSTGRES_DB:-postgres}
DB_USER=${POSTGRES_USER:-postgres}
DB_PASSWORD=${POSTGRES_PASSWORD}

# Log-Datei
LOG_FILE="/var/log/poll-cleanup.log"

# Funktion zum Loggen mit Timestamp
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Prüfe ob alle nötigen Umgebungsvariablen gesetzt sind
if [ -z "$DB_PASSWORD" ]; then
    log_message "ERROR: POSTGRES_PASSWORD environment variable is not set"
    exit 1
fi

log_message "Starting poll cleanup process"

# Warte kurz um sicherzustellen dass die DB bereit ist
sleep 2

# Führe das Cleanup über die PostgreSQL Funktion aus
cleanup_result=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT cleanup_expired_polls();" 2>&1)
exit_code=$?

# Prüfe ob der Befehl erfolgreich war
if [ $exit_code -eq 0 ]; then
    deleted_count=$(echo "$cleanup_result" | tr -d ' \n\r' | grep -E '^[0-9]+$')
    if [ ! -z "$deleted_count" ] && [ "$deleted_count" -gt 0 ]; then
        log_message "SUCCESS: Cleanup completed - $deleted_count expired polls deleted"
    else
        log_message "INFO: No expired polls found for cleanup (result: $cleanup_result)"
    fi
else
    log_message "ERROR: Database cleanup failed (exit code: $exit_code) - $cleanup_result"
fi

log_message "Poll cleanup process finished"