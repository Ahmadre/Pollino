#!/bin/bash
# Startup script für den Poll Cleanup Container

echo "Starting Poll Cleanup Service..."
echo "$(date): Poll Cleanup Service started" >> /var/log/poll-cleanup.log

# Führe initial einen Test durch
echo "Running initial cleanup Test..."
/app/cleanup-script.sh

# Starte eine Endlosschleife, die einmal pro Tag läuft (86400 Sekunden)
echo "Starting cleanup loop (every 24 hours)..."
while true; do
    echo "$(date): Waiting 24 hours until next cleanup..."
    sleep 86400  # 24 Stunden
    echo "$(date): Running scheduled daily cleanup..."
    /app/cleanup-script.sh
done