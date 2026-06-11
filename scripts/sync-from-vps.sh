#!/bin/bash
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
echo "Sync nach $ROOT (read-only vom VPS)"

echo "==> SQL Migrationen"
scp -q vps:/home/deploy/sql/*.sql "$ROOT/sql/"

echo "==> Scripts"
scp -q vps:/home/deploy/scripts/backup.sh "$ROOT/scripts/"
scp -q vps:/home/deploy/scripts/monitor.sh "$ROOT/scripts/"
scp -q vps:/home/deploy/health-check.sh "$ROOT/scripts/"
ssh vps "cat /home/deploy/scripts/deploy-api.sh" > "$ROOT/scripts/deploy-api.sh"
ssh vps "cat /home/deploy/scripts/deploy-company-api.sh" > "$ROOT/scripts/deploy-company-api.sh"
chmod +x "$ROOT"/scripts/*.sh

echo "==> Caddy"
ssh vps "cat /etc/caddy/Caddyfile" > "$ROOT/caddy/Caddyfile"

echo "==> PM2 Ecosystem Configs"
scp -q vps:/home/deploy/freyone/apps/api/ecosystem.config.cjs "$ROOT/pm2/ecosystem.freyone-api.cjs"
scp -q vps:/home/deploy/company/api/ecosystem.config.cjs "$ROOT/pm2/ecosystem.company-api.cjs"

echo "==> .env Keys (Platzhalter, KEINE echten Werte)"
ssh vps "grep -oP '^[A-Z_]+(?==)' /home/deploy/company/api/.env | sed 's/\$/=CHANGE_ME/'" > "$ROOT/.env.example.company-api"
ssh vps "grep -oP '^[A-Z_]+(?==)' /home/deploy/freyone/apps/api/.env | sed 's/\$/=CHANGE_ME/'" > "$ROOT/.env.example.freyone-api"

echo "==> PgBouncer / Postgres (NOPASSWD sudo)"
ssh vps "sudo cat /etc/pgbouncer/pgbouncer.ini" > "$ROOT/pgbouncer/pgbouncer.ini"
ssh vps "sudo cat /etc/postgresql/16/main/postgresql.conf" > "$ROOT/postgresql/postgresql.conf"
ssh vps "sudo cat /etc/pgbouncer/userlist.txt" | cut -d'"' -f2 > "$ROOT/pgbouncer/userlist.usernames.txt"

echo "==> Crontab + UFW (Doku)"
ssh vps "crontab -l" > "$ROOT/docs/crontab.txt" 2>/dev/null || echo "kein crontab" > "$ROOT/docs/crontab.txt"
ssh vps "sudo ufw status numbered" > "$ROOT/docs/ufw-status.txt" 2>/dev/null || true

echo ""
echo "Fertig. Jetzt: cd $ROOT && git status && git diff --stat"
