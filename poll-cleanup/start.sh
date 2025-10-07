#!/bin/bash
# Startup script für den Poll Cleanup Container

echo "Starting Poll Cleanup Service..."
echo "$(date): Poll Cleanup Service started" >> /var/log/poll-cleanup.log

# Führe initial einen Test durch
echo "Running initial cleanup Test..."
/app/cleanup-script.sh

# Starte eine endlos Schleife die alle 15 Minuten läuft (900 Sekunden)
echo "Starting cleanup loop (every 15 minutes)..."
while true; do
    echo "$(date): Waiting 15 minutes until next cleanup..."
    sleep 900  # 15 Minuten
    echo "$(date): Running scheduled cleanup..."
    /app/cleanup-script.sh
done