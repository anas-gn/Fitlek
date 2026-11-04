// UTC calendar days, shared by the API and admin. No photos or nutrition stored here.
export function scanDay(now = new Date()) {
  const day = now.toISOString().slice(0, 10);
  return { day, resetsAt: new Date(Date.parse(`${day}T00:00:00Z`) + 86400000).toISOString() };
}

export function validLimit(value) {
  return Number.isInteger(value) && value >= 0 && value <= 1000;
}

export class MealQuotaError extends Error {
  constructor(allowance) {
    super(`You've used today's ${allowance.limit} meal scans. Your allowance resets at midnight UTC.`);
    this.status = 429;
    this.code = 'MEAL_SCAN_DAILY_LIMIT';
    this.allowance = allowance;
  }
}

export async function readMealAllowance(db, userID, now = new Date()) {
  const { day, resetsAt } = scanDay(now);
  const [[settings]] = await db.execute('SELECT dailyLimit FROM meal_scan_settings WHERE id=1');
  if (!settings) throw new Error('Meal scan settings are not installed');
  const [[policy]] = await db.execute('SELECT dailyLimit FROM meal_scan_clients WHERE userID=?', [userID]);
  const [[usage]] = await db.execute('SELECT used,bonus FROM meal_scan_usage WHERE userID=? AND scanDay=?', [userID, day]);
  const dailyLimit = Number(policy?.dailyLimit ?? settings.dailyLimit);
  const bonus = Number(usage?.bonus ?? 0), used = Number(usage?.used ?? 0);
  return { dailyLimit, globalLimit: Number(settings.dailyLimit), override: policy?.dailyLimit == null ? null : Number(policy.dailyLimit),
    bonus, limit: dailyLimit + bonus, used, remaining: Math.max(0, dailyLimit + bonus - used), day, resetsAt, timezone: 'UTC' };
}

// All quota writers lock the singleton first. This serializes short transactions,
// including concurrent requests on different Heroku instances and admin grants.
export async function lockMealSettings(tx) {
  const [[row]] = await tx.execute('SELECT dailyLimit FROM meal_scan_settings WHERE id=1 FOR UPDATE');
  if (!row) throw new Error('Meal scan settings are not installed');
}

export async function reserveMealScan(pool, userID, now = new Date()) {
  const tx = await pool.getConnection();
  try {
    await tx.beginTransaction();
    await lockMealSettings(tx);
    const allowance = await readMealAllowance(tx, userID, now);
    if (!allowance.remaining) throw new MealQuotaError(allowance);
    await tx.execute(`INSERT INTO meal_scan_usage (userID,scanDay,used) VALUES (?,?,1)
      ON DUPLICATE KEY UPDATE used=used+1`, [userID, allowance.day]);
    await tx.commit();
    return { ...allowance, used: allowance.used + 1, remaining: allowance.remaining - 1 };
  } catch (error) {
    await tx.rollback();
    throw error;
  } finally { tx.release(); }
}

export async function refundMealScan(pool, userID, day) {
  await pool.execute('UPDATE meal_scan_usage SET used=GREATEST(used,1)-1 WHERE userID=? AND scanDay=?', [userID, day]);
}

export async function updateMealPolicy(tx, userID, { dailyLimit, extraScans }, now = new Date()) {
  if (dailyLimit !== null && !validLimit(dailyLimit)) throw new TypeError('Invalid daily limit');
  if (!validLimit(extraScans)) throw new TypeError('Invalid extra scans');
  await lockMealSettings(tx);
  await tx.execute(`INSERT INTO meal_scan_clients (userID,dailyLimit) VALUES (?,?)
    ON DUPLICATE KEY UPDATE dailyLimit=VALUES(dailyLimit)`, [userID, dailyLimit]);
  if (extraScans) {
    await tx.execute(`INSERT INTO meal_scan_usage (userID,scanDay,bonus) VALUES (?,?,?)
      ON DUPLICATE KEY UPDATE bonus=bonus+VALUES(bonus)`, [userID, scanDay(now).day, extraScans]);
  }
}
