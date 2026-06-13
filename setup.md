# FreyOne-prod-1 — Server-Setup Übersicht

Stand: 2026-06-13

> Detaillierter Migrationsplan mit SQL und Code: `Umbau V3.0`

---

## Architektur

```
Internet
  |
  +-- www.frey-one.com     -> Vercel (Next.js, FreyOne Repo)
  +-- admin.frey-one.com   -> Vercel (Next.js, FreyOne_admin Repo)
  |
  +-- api.frey-one.com     -> Caddy (VPS :443 / TLS auto via Let's Encrypt)
        +-- /admin/*       -> PM2: company-api  (localhost:3002)
        +-- /*             -> PM2: freyone-api  (localhost:3001)
```

### PM2-Prozesse

| Prozess | Port | Repo | Env-Datei |
|---|---|---|---|
| `freyone-api` | 3001 | `/home/deploy/freyone` | `apps/api/.env` |
| `company-api` | 3002 | `/home/deploy/company` | `api/.env` |

Config: `pm2/ecosystem.freyone-api.cjs`, `pm2/ecosystem.company-api.cjs`

### Datenbank

- PostgreSQL 16 + pgBouncer (:6432) — nur localhost erreichbar
- Schema `freyone_prod` für FreyOne, Schema `company_internal` fur FreyOne_admin
- User-Isolation: `freyone_api` kann NICHT auf `company_internal` zugreifen (und umgekehrt)

---

## Deploy

### Automatisch (GitHub Actions via SSH)

| Repo | Trigger | Was passiert |
|---|---|---|
| FreyOne | Push `main` + `apps/api/**` | `npm ci` (Root), `cd apps/api && build`, `pm2 reload freyone-api` |
| FreyOne_admin | Push `main` + `api/**` | `cd api && npm ci --legacy-peer-deps && build`, `pm2 reload company-api` |

Frontends (Next.js) deployen automatisch auf Vercel — kein GitHub Actions nötig.

### Manuell (VPS-Skripte)

```bash
./scripts/deploy-api.sh           # freyone-api neu deployen
./scripts/deploy-company-api.sh   # company-api neu deployen
```

### VPS <-> lokal synchronisieren

```bash
./scripts/sync-from-vps.sh   # VPS -> lokal (Configs, Scripts)
./Push.sh                    # lokal -> VPS
```

### NVM in Deploy-Skripten (wichtig!)

```bash
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```
Dieser Pattern funktioniert sicher unter `set -e` — bricht NICHT ab wenn nvm fehlt.

---

## Cron-Jobs

### OS-Level (root crontab)

| Schedule | Script | Zweck |
|---|---|---|
| `*/15 * * * *` | `scripts/monitor.sh` | Health-Check + Alert |
| `0 2 * * *` | `scripts/backup.sh` | DB-Backup -> Cloudflare R2 |

Verifikation (2026-06-11): Beide Crons aktiv, Logs vorhanden.

### App-Level (node-cron in freyone-api)

21 interne Jobs — Details: `docs/cron-jobs.md`

---

## Abgeschlossene Phasen

| Phase | Inhalt | Status |
|---|---|---|
| 0 | Server Grundsetup (SSH, UFW, Node, PM2, Caddy, pgBouncer) | DONE |
| 1 | DB Setup freyone_prod (Schema, Auth-Tabellen, Indexes, Tuning) | DONE |
| 2 | Hono Backend (Auth, JWT, Refresh-Token-Rotation, Rate Limiting) | DONE |
| 3 | Cron Jobs (intern via node-cron, kein cron-jobs.org mehr) | DONE |
| 5 | CI/CD Pipeline (GitHub Actions fur beide Repos) | DONE |
| 6 | Backups GFS -> R2 (tägl. 02:00, Cron aktiv) | DONE |
| 7 | Monitoring (Monitor-Cron alle 15 min, Logs aktiv) | DONE |
| Deploy-Fix | Resiliente NVM-Initialisierung in YAMLs + VPS-Skripten | DONE 2026-06-12 |
| Next.js-Fix | support/tickets route.ts, /api/conversations, CSP-Fix | DONE 2026-06-12 |

---

## Offene Punkte

| Prio | Aufgabe |
|---|---|
| HOCH | Stripe Connect Produktiv-Setup (aktuell Testmodus) |
| HOCH | Phase 1b: company_internal DB + Admin-User Passworter migrieren |
| HOCH | Phase 4b: FreyOne_admin -> VPS (Supabase ablosen fur Admin-Panel) |
| MITTEL | Phase 4a: FreyOne Web Supabase-Datenzugriffe entfernen |
| MITTEL | Admin-Freischaltung fur erste Provider-Accounts |
| NIEDRIG | E-Mail-Provider: DKIM + SPF-Records verifizieren |
| NIEDRIG | pgBouncer-Config auf Produktionslast tunen |
| NIEDRIG | Log-Rotation prufen (/var/log/freyone/, /var/log/company/) |

---

## Cloudflare absichern

> LETZTER SCHRITT — erst durchfuhren wenn alle Phasen oben stabil laufen.

### Ziel

Alle Requests an `api.frey-one.com` nur noch uber Cloudflare erlauben.
Direkte VPS-IP-Anfragen blockieren.

### Schritt 1 — Domain zu Cloudflare

- DNS `api.frey-one.com` -> VPS-IP mit Proxy aktiviert (orange Wolke)
- Cloudflare SSL/TLS auf **Full (strict)** stellen
- Origin-Zertifikat in Cloudflare ausstellen, in Caddy einbinden

### Schritt 2 — UFW nur fur Cloudflare-IPs offnen

```bash
# Cloudflare IPv4 (aktuelle Liste: https://www.cloudflare.com/ips/)
CF_IPS="173.245.48.0/20 103.21.244.0/22 103.22.200.0/22 103.31.4.0/22
         141.101.64.0/18 108.162.192.0/18 190.93.240.0/20 188.114.96.0/20
         197.234.240.0/22 198.41.128.0/17 162.158.0.0/15 104.16.0.0/13
         104.24.0.0/14 172.64.0.0/13 131.0.72.0/22"
for ip in $CF_IPS; do
  ufw allow from $ip to any port 443
  ufw allow from $ip to any port 80
done

# Alte offene Regeln entfernen
ufw delete allow 80
ufw delete allow 443
ufw reload
```

### Schritt 3 — Cloudflare WAF

- OWASP-Ruleset: Medium aktivieren
- Rate Limiting auf `/api/*`: max. 100 req/min pro IP
- Bot Fight Mode: an

### Schritt 4 — Verifikation

```bash
# Direkte VPS-IP darf nicht mehr antworten
curl -k https://<VPS-IP>/health       # -> Timeout oder Connection refused

# Uber Cloudflare muss es funktionieren
curl https://api.frey-one.com/health  # -> {"status":"ok"}
```
