#!/bin/bash
set -e
REPO_DIR="/home/deploy/company"
API_DIR="$REPO_DIR/api"
LOG="[$(date '+%Y-%m-%d %H:%M:%S')]"

echo "$LOG Deploy gestartet"
cd $REPO_DIR || exit 1
git pull origin main

cd $API_DIR || exit 1
npm ci --legacy-peer-deps
npm run build

pm2 reload company-api --update-env
pm2 save

sleep 3
curl -sf http://localhost:3002/health > /dev/null && echo "$LOG Health-Check OK" || (echo "$LOG Health-Check FEHLGESCHLAGEN"; pm2 logs company-api --lines 30 --nostream; exit 1)

echo "$LOG Deploy erfolgreich"
