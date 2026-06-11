# Cron-Jobs Übersicht – Trennung für Company-OS-Umzug

## company (OS-Level Cron, VPS-gebunden – /home/deploy/scripts/)
| Schedule | Script | Zweck | Log |
|---|---|---|---|
| */15 * * * * | monitor.sh | Health-Check | /var/log/freyone/monitor-cron.log |
| 0 2 * * *    | backup.sh  | DB-Backups → R2 | /var/log/backups.log |

## freyone (internes node-cron, läuft IN freyone-api Prozess, portabel)
Quelle: `apps/api/src/crons/index.ts` (21 Jobs)

| Schedule | Job |
|---|---|
| */5 * * * * | health-check |
| */5 * * * * | keep-company-alive |
| */10 * * * * | dsgvo-export |
| */5 * * * * | translate |
| 0 * * * * | booking-reminders |
| 0 */2 * * * | process-failed-emails |
| 0 */6 * * * | check-service-limits |
| 0 */6 * * * | auto-complete-bookings |
| 0 2 * * * | cleanup-old-records |
| 0 6 * * * | system-monitor |
| 0 6 * * * | platform-stats |
| 0 7 * * * | daily-report |
| 30 7 * * * | check-connect-deadline |
| 30 7 * * * | check-temp-plan-expiry |
| 0 8 * * * | payment-reminders |
| 30 8 * * * | check-provider-approvals |
| 0 9 * * * | installments |
| 0 10 * * * | notification-nudges |
| 0 7 * * 1 | weekly-limit-report |
| 0 8 1 * * | monthly-report |
| 0 9 1 * * | monthly-financial |
| 0 6 1 1 * | yearly-tax-export |
