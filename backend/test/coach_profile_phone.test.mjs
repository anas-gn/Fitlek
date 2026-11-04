import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import express from 'express';

test('coach profile reload reads the saved account phone and retains legacy fallback', async () => {
  const sourceUrl = new URL('../routes/pahae/coachProfile.js', import.meta.url);
  let source = await fs.readFile(sourceUrl, 'utf8');
  let phoneNumber = '+212612345678';
  globalThis.coachPhoneTestPool = { query: async (sql, args) => {
    assert.match(sql, /u\.phoneNumber/);
    assert.match(sql, /COALESCE\(NULLIF\(TRIM\(u\.phoneNumber\), ''\), cp\.tel\) AS tel/);
    assert.deepEqual(args, [7]);
    return [[{ id: 7, phoneNumber, tel: phoneNumber?.trim() || '+212699999999' }]];
  }};
  source = source.replace("import pool from '../../config/db.js';", 'const pool = globalThis.coachPhoneTestPool;')
    .replace("import { requireAuth, requireRole } from '../../middleware/auth.js';",
      'const requireAuth = (req, res, next) => { req.user = { id: 7 }; next(); }; const requireRole = () => (req, res, next) => next();')
    .replace("from 'express'", `from '${new URL('../node_modules/express/index.js', import.meta.url).href}'`);
  const { default: router } = await import('data:text/javascript;base64,' + Buffer.from(source).toString('base64'));
  const app = express(); app.use(router);
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  try {
    const reload = async () => {
      const response = await fetch(`http://127.0.0.1:${server.address().port}/`);
      assert.equal(response.status, 200);
      return response.json();
    };
    assert.equal((await reload()).tel, '+212612345678');
    phoneNumber = '+212612345679';
    assert.equal((await reload()).tel, phoneNumber);
    phoneNumber = null;
    assert.equal((await reload()).tel, '+212699999999');
  } finally {
    await new Promise(resolve => server.close(resolve));
    delete globalThis.coachPhoneTestPool;
  }
});
