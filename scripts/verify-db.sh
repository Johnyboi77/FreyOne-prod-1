#!/bin/bash
F_ENV=/home/deploy/freyone/apps/api/.env
C_ENV=/home/deploy/company/api/.env

DB_USER=$(grep '^DB_USER=' $F_ENV | cut -d= -f2-)
DB_NAME=$(grep '^DB_NAME=' $F_ENV | cut -d= -f2-)
DB_PASS=$(grep '^DB_PASSWORD=' $F_ENV | cut -d= -f2-)
A_USER=$(grep '^DB_ADMIN_APP_USER=' $C_ENV | cut -d= -f2-)
A_NAME=$(grep '^DB_ADMIN_APP_NAME=' $C_ENV | cut -d= -f2-)
A_PASS=$(grep '^DB_ADMIN_APP_PASSWORD=' $C_ENV | cut -d= -f2-)

echo "## freyone_prod tables"
PGPASSWORD=$DB_PASS psql -h 127.0.0.1 -p 6432 -U $DB_USER -d $DB_NAME -tAc "SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_name IN ('users','refresh_tokens','password_resets','provider_profiles','provider_business_details','email_otp_codes','platform_stats')"
echo "## provider_profiles cols (47?)"
PGPASSWORD=$DB_PASS psql -h 127.0.0.1 -p 6432 -U $DB_USER -d $DB_NAME -tAc "SELECT COUNT(*) FROM information_schema.columns WHERE table_name='provider_profiles'"
echo "## provider_business_details cols (22?)"
PGPASSWORD=$DB_PASS psql -h 127.0.0.1 -p 6432 -U $DB_USER -d $DB_NAME -tAc "SELECT COUNT(*) FROM information_schema.columns WHERE table_name='provider_business_details'"
echo "## indexes (40+?)"
PGPASSWORD=$DB_PASS psql -h 127.0.0.1 -p 6432 -U $DB_USER -d $DB_NAME -tAc "SELECT COUNT(*) FROM pg_indexes WHERE schemaname='public'"
echo "## fk profiles->users"
PGPASSWORD=$DB_PASS psql -h 127.0.0.1 -p 6432 -U $DB_USER -d $DB_NAME -tAc "SELECT conname FROM pg_constraint WHERE conname='fk_profiles_users'"
echo "## isolation: freyone_api -> company_internal (soll denied)"
PGPASSWORD=$DB_PASS psql -h 127.0.0.1 -p 6432 -U $DB_USER -d $A_NAME -c "SELECT 1" 2>&1 | tail -1
echo "## platform_stats Zeilen (für UserGrowthSection)"
PGPASSWORD=$DB_PASS psql -h 127.0.0.1 -p 6432 -U $DB_USER -d $DB_NAME -tAc "SELECT COUNT(*) FROM platform_stats" 2>&1 | tail -1