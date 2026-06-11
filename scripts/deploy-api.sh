#!/bin/bash
REPO_DIR="/home/deploy/freyone"
API_DIR="$REPO_DIR/apps/api"
LOG="[$(date '+%Y-%m-%d %H:%M:%S')]"

echo "$LOG Deploy gestartet"

cd $REPO_DIR || exit 1
git pull origin main

cd $API_DIR || exit 1
npm ci
npm run build

pm2 reload freyone-api --update-env
pm2 save

echo "$LOG Deploy erfolgreich"
