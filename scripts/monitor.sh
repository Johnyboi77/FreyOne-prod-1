#!/bin/bash

LOG_FILE="/var/log/freyone/health-check.log"
STATUS_FILE="/tmp/freyone-health-status.json"

# Health-Check ausführen
API_RESPONSE=$(curl -s http://localhost:3001/health 2>/dev/null)
API_STATUS=$(echo "$API_RESPONSE" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
[ -z "$API_STATUS" ] && API_STATUS="error"

DB_STATUS=$(sudo -u postgres psql -c "SELECT 1" > /dev/null 2>&1 && echo "ok" || echo "error")
PM2_STATUS=$(pm2 status freyone-api 2>/dev/null | grep -q "online" && echo "ok" || echo "error")
DISK_USAGE=$(df /home | awk 'NR==2 {print $5}' | sed 's/%//')
MEMORY_FREE=$(free | awk 'NR==2 {printf "%.0f", ($7/$2)*100}')

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
OVERALL_STATUS="ok"

# Status bestimmen
if [[ "$API_STATUS" != "ok" ]] || [[ "$DB_STATUS" != "ok" ]] || [[ "$PM2_STATUS" != "ok" ]]; then
  OVERALL_STATUS="error"
fi

if [[ $DISK_USAGE -gt 80 ]]; then
  OVERALL_STATUS="warning"
fi

# JSON speichern
cat > "$STATUS_FILE" << JSONEOF
{
  "timestamp": "$TIMESTAMP",
  "overall_status": "$OVERALL_STATUS",
  "services": {
    "api": "$API_STATUS",
    "database": "$DB_STATUS",
    "pm2": "$PM2_STATUS"
  },
  "resources": {
    "disk_usage_percent": $DISK_USAGE,
    "memory_free_percent": $MEMORY_FREE
  }
}
JSONEOF

# Log speichern
echo "[$TIMESTAMP] Status: $OVERALL_STATUS | API: $API_STATUS | DB: $DB_STATUS | PM2: $PM2_STATUS | Disk: ${DISK_USAGE}%" >> "$LOG_FILE"

# Alert bei Problemen
if [[ "$OVERALL_STATUS" = "error" ]]; then
  logger -t freyone-monitor "ALERT: $OVERALL_STATUS - API: $API_STATUS, DB: $DB_STATUS, PM2: $PM2_STATUS"
fi

# Status ausgeben
cat "$STATUS_FILE"
