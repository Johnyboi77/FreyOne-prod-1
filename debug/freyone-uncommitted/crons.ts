import { Hono } from 'hono';
import { authMiddleware, requireRole } from '../middleware/auth.js';
import { logCronRun, getCronStatus } from '../lib/cron-status.js';
import { runHealthCheck } from '../crons/jobs/health-check.js';
import { runBookingReminders } from '../crons/jobs/booking-reminders.js';
import { runProcessFailedEmails } from '../crons/jobs/process-failed-emails.js';
import { runCheckServiceLimits } from '../crons/jobs/check-service-limits.js';
import { runAutoCompleteBookings } from '../crons/jobs/auto-complete-bookings.js';
import { runCleanupOldRecords } from '../crons/jobs/cleanup-old-records.js';
import { runSystemMonitor } from '../crons/jobs/system-monitor.js';
import { runPlatformStats } from '../crons/jobs/platform-stats.js';
import { runDailyReport } from '../crons/jobs/daily-report.js';
import { runCheckConnectDeadline } from '../crons/jobs/check-connect-deadline.js';
import { runPaymentReminders } from '../crons/jobs/payment-reminders.js';
import { runCheckProviderApprovals } from '../crons/jobs/check-provider-approvals.js';
import { runInstallments } from '../crons/jobs/installments.js';
import { runKeepCompanyAlive } from '../crons/jobs/keep-company-alive.js';
import { runNotificationNudges } from '../crons/jobs/notification-nudges.js';
import { runWeeklyLimitReport } from '../crons/jobs/weekly-limit-report.js';
import { runMonthlyReport } from '../crons/jobs/monthly-report.js';
import { runMonthlyFinancial } from '../crons/jobs/monthly-financial.js';
import { runYearlyTaxExport } from '../crons/jobs/yearly-tax-export.js';
import { runDsgvoExport } from '../crons/jobs/dsgvo-export.js';
import { runTranslate } from '../crons/jobs/translate.js';
import { runCheckTempPlanExpiry } from '../crons/jobs/check-temp-plan-expiry.js';

const cron = new Hono();

// Job mapping
const JOBS: Record<string, () => Promise<unknown>> = {
  'health-check': runHealthCheck,
  'booking-reminders': runBookingReminders,
  'process-failed-emails': runProcessFailedEmails,
  'check-service-limits': runCheckServiceLimits,
  'auto-complete-bookings': runAutoCompleteBookings,
  'cleanup-old-records': runCleanupOldRecords,
  'system-monitor': runSystemMonitor,
  'platform-stats': runPlatformStats,
  'daily-report': runDailyReport,
  'check-connect-deadline': runCheckConnectDeadline,
  'payment-reminders': runPaymentReminders,
  'check-provider-approvals': runCheckProviderApprovals,
  'installments': runInstallments,
  'keep-company-alive': runKeepCompanyAlive,
  'notification-nudges': runNotificationNudges,
  'weekly-limit-report': runWeeklyLimitReport,
  'monthly-report': runMonthlyReport,
  'monthly-financial': runMonthlyFinancial,
  'yearly-tax-export': runYearlyTaxExport,
  'dsgvo-export': runDsgvoExport,
  'translate': runTranslate,
  'check-temp-plan-expiry': runCheckTempPlanExpiry,
};

// ─── GET /cron/status ──────────────────────────────────
cron.get('/status', async (c) => {
  const status = await getCronStatus();
  return c.json(status);
});

// ─── POST /cron/:jobName (manual trigger) ──────────────
cron.post('/:jobName', authMiddleware, requireRole(['admin']), async (c) => {
  const jobName = c.req.param('jobName');
  const jobFn = JOBS[jobName];

  if (!jobFn) {
    return c.json({ error: `Job "${jobName}" not found` }, 404);
  }

  try {
    const start = Date.now();
    const result = await jobFn();
    const duration = Date.now() - start;
    
    await logCronRun(jobName, 'ok', String(result), duration);
    
    return c.json({
      job: jobName,
      status: 'ok',
      result,
      duration,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    await logCronRun(jobName, 'error', message);
    
    return c.json(
      {
        job: jobName,
        status: 'error',
        error: message,
      },
      500
    );
  }
});

export default cron;
