#!/bin/bash
set -e
OUT=~/Workspace/FreyOne-prod-1/debug/latest.md
mkdir -p ~/Workspace/FreyOne-prod-1/debug

echo "# Debug Bundle - $(date)" > "$OUT"

ssh vps bash << 'EOF' >> "$OUT"
echo ""
echo "## PM2 Status"
pm2 jlist | jq '.[] | {name, pid, status: .pm2_env.status, restarts: .pm2_env.restart_time, uptime: .pm2_env.pm_uptime}'

echo ""
echo "## company-api - letzte 100 Zeilen (out + error)"
pm2 logs company-api --lines 100 --nostream

echo ""
echo "## freyone-api - letzte 30 Zeilen"
pm2 logs freyone-api --lines 30 --nostream

echo ""
echo "## .env Keys company/api (keine Werte)"
grep -oP '^[A-Z_]+(?==)' /home/deploy/company/api/.env

echo ""
echo "## Git Status"
for d in /home/deploy/freyone /home/deploy/company/api; do
  if [ -d "$d" ]; then
    echo "### $d"
    cd "$d" && git status --short && git log -1 --oneline
  fi
done

echo ""
echo "## Caddyfile"
cat /etc/caddy/Caddyfile

echo ""
echo "## Health Check freyone-api"
curl -s https://api.frey-one.com/health
echo ""

echo ""
echo "## Login-Versuch company-api (erwartet 401 wegen Dummy-Daten, aber zeigt Fehlerformat)"
curl -s -i -X POST https://api.frey-one.com/admin/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test"}'
echo ""

echo '# Login Versuch Admin Panel'
curl -i -X POST https://admin.frey-one.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"jonasfrey1206@gmail.com","password":"Admin123!Temp"}'
EOF

echo "" >> "$OUT"
echo "Bundle geschrieben nach $OUT"
