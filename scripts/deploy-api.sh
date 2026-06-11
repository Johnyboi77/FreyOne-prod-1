#!/bin/bash
set -e
REPO_DIR="/home/deploy/freyone"
API_DIR="$REPO_DIR/apps/api"
LOG="[$(date '+%Y-%m-%d %H:%M:%S')]"

echo "$LOG Deploy gestartet"

cd $REPO_DIR || exit 1
git pull origin main
git clean -f apps/api/src/routes/

npm ci
cd $API_DIR || exit 1
npm run build

pm2 reload freyone-api --update-env
pm2 save

echo "$LOG Deploy erfolgreich"
