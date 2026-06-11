#!/bin/bash

ENV_FILE="/home/deploy/freyone/apps/api/.env"

# Sicheres Parsen (funktioniert auch mit Sonderzeichen im Passwort)
get_env() { grep "^${1}=" $ENV_FILE | sed "s/^${1}=//"; }

DB_USER=$(get_env DB_USER)
DB_PASSWORD=$(get_env DB_PASSWORD)
DB_NAME=$(get_env DB_NAME)

COMPANY_DB_USER=$(get_env COMPANY_DB_USER)
COMPANY_DB_PASSWORD=$(get_env COMPANY_DB_PASSWORD)
COMPANY_DB_NAME=$(get_env COMPANY_DB_NAME)

R2_BUCKET="r2:freyone-backups"
DATE=$(date +%Y%m%d)
DOW=$(date +%u)
DOM=$(date +%d)
TMP="/tmp/backups"
mkdir -p $TMP

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup gestartet"

dump_db() {
  local USER=$1
  local PASS=$2
  local DB=$3
  local FILE=$4
  PGPASSWORD="$PASS" pg_dump -h localhost -p 5432 -U "$USER" "$DB" | gzip > "$FILE"
}

run_backup() {
  local LABEL=$1
  local SUBDIR=$2

  # freyone_prod
  FILE="$TMP/${DB_NAME}_${LABEL}.sql.gz"
  dump_db "$DB_USER" "$DB_PASSWORD" "$DB_NAME" "$FILE"
  rclone copy "$FILE" "${R2_BUCKET}/${SUBDIR}/${DB_NAME}/" --quiet
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $DB_NAME $SUBDIR → R2"

  # company_internal
  FILE="$TMP/${COMPANY_DB_NAME}_${LABEL}.sql.gz"
  dump_db "$COMPANY_DB_USER" "$COMPANY_DB_PASSWORD" "$COMPANY_DB_NAME" "$FILE"
  rclone copy "$FILE" "${R2_BUCKET}/${SUBDIR}/${COMPANY_DB_NAME}/" --quiet
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $COMPANY_DB_NAME $SUBDIR → R2"
}

# Täglich
run_backup "$DATE" "daily"

# Wöchentlich
[ "$DOW" = "7" ] && run_backup "weekly_$(date +%Y-KW%V)" "weekly"

# Monatlich
[ "$DOM" = "01" ] && run_backup "monthly_$(date +%Y-%m)" "monthly"

# Rotation
rclone delete "${R2_BUCKET}/daily/"   --min-age 7d   --quiet
rclone delete "${R2_BUCKET}/weekly/"  --min-age 28d  --quiet
rclone delete "${R2_BUCKET}/monthly/" --min-age 365d --quiet

rm -f $TMP/*.sql.gz
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup abgeschlossen"
