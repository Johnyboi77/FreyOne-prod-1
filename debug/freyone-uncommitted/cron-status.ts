import fs from 'fs/promises';
import path from 'path';

const STATUS_FILE = '/var/log/freyone/cron-status.json';

export interface CronJobStatus {
  name: string;
  lastRun: string;
  status: 'ok' | 'error';
  message?: string;
  duration?: number;
}

export async function logCronRun(name: string, status: 'ok' | 'error', message?: string, duration?: number) {
  try {
    let jobs: Record<string, CronJobStatus> = {};
    
    try {
      const content = await fs.readFile(STATUS_FILE, 'utf-8');
      jobs = JSON.parse(content);
    } catch {
      // File doesn't exist yet
    }
    
    jobs[name] = {
      name,
      lastRun: new Date().toISOString(),
      status,
      message,
      duration,
    };
    
    await fs.mkdir(path.dirname(STATUS_FILE), { recursive: true });
    await fs.writeFile(STATUS_FILE, JSON.stringify(jobs, null, 2));
  } catch (err) {
    console.error(`[cron-status] Failed to log ${name}:`, err);
  }
}

export async function getCronStatus() {
  try {
    const content = await fs.readFile(STATUS_FILE, 'utf-8');
    return JSON.parse(content);
  } catch {
    return {};
  }
}
