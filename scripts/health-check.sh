#!/bin/bash

# API Status
API_STATUS=$(curl -s http://localhost:3001/health | jq -r '.status')

# DB Status
DB_STATUS=$(sudo -u postgres psql -c "SELECT 1" > /dev/null 2>&1 && echo "ok" || echo "error")

# PM2 Status
PM2_STATUS=$(pm2 status freyone-api | grep -q "online" && echo "ok" || echo "error")

# Disk Usage
DISK_USAGE=$(df /home | awk 'NR==2 {print $5}' | sed 's/%//')

# Backup Status (letztes Backup < 25h)
LATEST_BACKUP=$(rclone ls r2:freyone-backups/daily/freyone_prod --max-age 25h | wc -l)

echo "{
  \"api\": \"$API_STATUS\",
  \"database\": \"$DB_STATUS\",
  \"pm2\": \"$PM2_STATUS\",
  \"disk_usage_percent\": $DISK_USAGE,
  \"recent_backup\": \"$([ $LATEST_BACKUP -gt 0 ] && echo 'ok' || echo 'stale')\",
  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
}"
