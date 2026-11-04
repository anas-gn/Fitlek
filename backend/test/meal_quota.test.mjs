import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import express from 'express';
import sharp from 'sharp';
import { readMealAllowance, reserveMealScan, refundMealScan, updateMealPolicy, scanDay, validLimit } from '../services/mealQuota.js';
import { MealError } from '../services/mealAnalysis.js';

// Transaction-aware database double: independent connections share the same lock.
export function quotaDatabase() {
  const state = { limit: 3, policies: new Map(), days: new Map(), tail: Promise.resolve() };
  const execute = async (sql, p = []) => {
    if (sql.startsWith('SELECT dailyLimit FROM meal_scan_settings')) return [[{ dailyLimit: state.limit }]];
    if (sql.startsWith('SELECT dailyLimit FROM meal_scan_clients')) return [[state.policies.has(p[0]) ? { dailyLimit: state.policies.get(p[0]) } : undefined].filter(Boolean)];
    if (sql.startsWith('SELECT used,bonus')) return [[state.days.get(`${p[0]}:${p[1]}`)].filter(Boolean)];
    if (sql.startsWith('INSERT INTO meal_scan_clients')) { state.policies.set(p[0], p[1]); return [{}]; }
    if (sql.startsWith('INSERT INTO meal_scan_usage')) {
      const key = `${p[0]}:${p[1]}`, day = state.days.get(key) ?? { used: 0, bonus: 0 };
      if (sql.includes('scanDay,used')) day.used++; else day.bonus += p[2];
      state.days.set(key, day); return [{}];
    }
    if (sql.startsWith('UPDATE meal_scan_usage')) { state.days.get(`${p[0]}:${p[1]}`).used--; return [{}]; }
    throw new Error(`Unexpected SQL: ${sql}`);
  };
  return { state, execute, async getConnection() {
    let unlock;
    return { async beginTransaction() {}, async execute(sql, params) {
      if (sql.endsWith('FOR UPDATE')) {
        const previous = state.tail; state.tail = new Promise(resolve => { unlock = resolve; }); await previous;
      }
      return execute(sql, params);
    }, async commit() {}, async rollback() {}, release() { unlock?.(); } };
  } };
}
const today = new Date('2026-10-15T23:59:59Z');
test('default allows exactly three scans and rejects the fourth, including another server connection', async () => {
  const db = quotaDatabase();
  for (let i = 0; i < 3; i++) assert.equal((await reserveMealScan(db, 7, today)).remaining, 2 - i);
  await assert.rejects(reserveMealScan(db, 7, today), error => error.code === 'MEAL_SCAN_DAILY_LIMIT' && error.allowance.limit === 3);
  assert.equal((await readMealAllowance(db, 8, today)).remaining, 3);
});
test('parallel submissions cannot overspend the daily allowance', async () => {
  const db = quotaDatabase();
  const attempts = await Promise.allSettled(Array.from({ length: 24 }, () => reserveMealScan(db, 7, today)));
  assert.equal(attempts.filter(a => a.status === 'fulfilled').length, 3);
  assert.equal((await readMealAllowance(db, 7, today)).used, 3);
});
test('global changes, client override, bonus expiry and restoring inheritance', async () => {
  const db = quotaDatabase(); db.state.limit = 2;
  assert.equal((await readMealAllowance(db, 7, today)).limit, 2);
  const tx = await db.getConnection(); await tx.beginTransaction();
  await updateMealPolicy(tx, 7, { dailyLimit: 5, extraScans: 4 }, today); await tx.commit(); tx.release();
  const policy = await readMealAllowance(db, 7, today);
  assert.equal(policy.limit, 9); assert.equal(policy.override, 5);
  assert.equal((await readMealAllowance(db, 7, new Date('2026-10-16T00:00:00Z'))).limit, 5);
  const tx2 = await db.getConnection(); await tx2.beginTransaction();
  await updateMealPolicy(tx2, 7, { dailyLimit: null, extraScans: 0 }, today); tx2.release();
  assert.equal((await readMealAllowance(db, 7, today)).limit, 6);
});
test('UTC midnight resets usage and refunds stay on the original day', async () => {
  const db = quotaDatabase(); await reserveMealScan(db, 7, today);
  const tomorrow = new Date('2026-10-16T00:00:00Z');
  await reserveMealScan(db, 7, tomorrow);
  await refundMealScan(db, 7, '2026-10-15');
  assert.equal((await readMealAllowance(db, 7, today)).used, 0);
  assert.equal((await readMealAllowance(db, 7, tomorrow)).used, 1);
  assert.equal(scanDay(today).resetsAt, '2026-10-16T00:00:00.000Z');
});
test('zero allowance disables scans; malformed and unbounded admin limits are rejected', async () => {
  const db = quotaDatabase(); db.state.limit = 0;
  await assert.rejects(reserveMealScan(db, 7, today), { code: 'MEAL_SCAN_DAILY_LIMIT' });
  for (const value of [-1, 1.5, '3', null, undefined, Infinity, 1001]) assert.equal(validLimit(value), false);
  for (const value of [0, 3, 1000]) assert.equal(validLimit(value), true);
});

test('HTTP guard blocks scan four before Azure, disallows coaches, and only refunds known service rejections', async () => {
  const db = quotaDatabase();
  let paidCalls = 0;
  globalThis.mealQuotaHTTPTest = { db, analyze: async (jpeg, { notes }) => { paidCalls++;
    if (notes === 'unavailable') throw new MealError(503, 'Not configured');
    throw new MealError(422, 'No food recognized');
  } };
  const sourceURL = new URL('../routes/anas/meals.js', import.meta.url);
  let source = await fs.readFile(sourceURL, 'utf8');
  source = source.replace("import pool from '../../config/db.js';", 'const pool=globalThis.mealQuotaHTTPTest.db;')
    .replace("import { requireAuth, requireRole } from '../../middleware/auth.js';", `import {requireRole} from '${new URL('../middleware/auth.js', import.meta.url).href}';
      const requireAuth=(req,res,next)=>{const role=req.headers['x-test-role'];if(!role)return res.status(401).end();req.user={id:Number(req.headers['x-test-id']??7),role};next();};`)
    .replace("import { analyzeMeal, MealError } from '../../services/mealAnalysis.js';", `import {MealError} from '${new URL('../services/mealAnalysis.js', import.meta.url).href}'; const analyzeMeal=globalThis.mealQuotaHTTPTest.analyze;`)
    .replace("new URL('../../public/ingredients', import.meta.url)", `new URL('${new URL('../public/ingredients', import.meta.url).href}')`)
    .replace(/from '([^']+)'/g, (_, specifier) => `from '${specifier.startsWith('.') ? new URL(specifier, sourceURL).href : import.meta.resolve(specifier)}'`);
  const { default: router } = await import('data:text/javascript;base64,' + Buffer.from(source).toString('base64'));
  const app = express(); app.use(router);
  const server = app.listen(0, '127.0.0.1'); await new Promise(resolve => server.once('listening', resolve));
  const base = `http://127.0.0.1:${server.address().port}`;
  try {
    const day = scanDay().day;
    db.state.days.set(`7:${day}`, { used: 3, bonus: 0 });
    const blocked = await fetch(base + '/analyze', { method: 'POST', headers: { 'x-test-role': 'client' } });
    assert.equal(blocked.status, 429);
    const body = await blocked.json(); assert.equal(body.code, 'MEAL_SCAN_DAILY_LIMIT'); assert.equal(body.allowance.limit, 3);
    assert.ok(Number(blocked.headers.get('retry-after')) > 0); assert.equal(paidCalls, 0);
    for (const path of ['/analyze', '/allowance']) {
      const method = path === '/analyze' ? 'POST' : 'GET';
      assert.equal((await fetch(base + path, { method })).status, 401);
      assert.equal((await fetch(base + path, { method, headers: { 'x-test-role': 'coach' } })).status, 403);
    }
    const invalid = await fetch(base + '/analyze', { method: 'POST', headers: { 'x-test-role': 'client', 'x-test-id': '8' } });
    assert.equal(invalid.status, 400); assert.equal(paidCalls, 0); assert.equal((await readMealAllowance(db, 8)).used, 0);
    const jpeg = await sharp({ create: { width: 8, height: 8, channels: 3, background: '#ffffff' } }).jpeg().toBuffer();
    const form = new FormData(); form.append('photo', new Blob([jpeg]), 'meal.jpg');
    const failed = await fetch(base + '/analyze', { method: 'POST', headers: { 'x-test-role': 'client', 'x-test-id': '9' }, body: form });
    assert.equal(failed.status, 422); assert.equal(paidCalls, 1); assert.equal((await readMealAllowance(db, 9)).used, 1);
    form.append('notes', 'unavailable');
    const unavailable = await fetch(base + '/analyze', { method: 'POST', headers: { 'x-test-role': 'client', 'x-test-id': '10' }, body: form });
    assert.equal(unavailable.status, 503); assert.equal((await readMealAllowance(db, 10)).used, 0);
  } finally { await new Promise(resolve => server.close(resolve)); delete globalThis.mealQuotaHTTPTest; }
});
