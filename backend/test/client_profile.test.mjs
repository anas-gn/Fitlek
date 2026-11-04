import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import express from 'express';

test('client profile persists interests, returns canonical phone and protects ownership', async () => {
  const profile = { id: 7, role: 'client', firstName: 'Amal', lastName: 'Client', phoneNumber: '+212612345678', interests: '["Yoga"]', height: null };
  const writes = [];
  globalThis.clientProfileTestDB = { async query(sql, params) {
    if (sql.startsWith('UPDATE')) {
      writes.push({ sql, params });
      const columns = [...sql.matchAll(/(\w+)=\?/g)].map(match => match[1]);
      columns.slice(0, -1).forEach((key, index) => { profile[key] = params[index]; });
      assert.equal(params.at(-1), 7);
      return [{ affectedRows: 1 }];
    }
    assert.match(sql, /phoneNumber/); assert.match(sql, /interests/);
    assert.deepEqual(params, [7]);
    return [[{ ...profile }]];
  } };
  const sourceURL = new URL('../routes/anas/client.js', import.meta.url);
  let source = (await fs.readFile(sourceURL, 'utf8')).replace("import db from '../../config/db.js';", 'const db=globalThis.clientProfileTestDB;');
  source = source.replace(/from '([^']+)'/g, (_, specifier) => `from '${specifier.startsWith('.') ? new URL(specifier, sourceURL).href : import.meta.resolve(specifier)}'`);
  const { default: router } = await import('data:text/javascript;base64,' + Buffer.from(source).toString('base64'));
  const app = express(); app.use(express.json()); app.use((req, res, next) => { req.user = { id: 7, role: req.headers['x-test-role'] || 'client' }; next(); }); app.use(router);
  const server = app.listen(0, '127.0.0.1'); await new Promise(resolve => server.once('listening', resolve));
  const base = `http://127.0.0.1:${server.address().port}`;
  const update = body => fetch(base + '/me', { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
  try {
    const initial = await (await fetch(base + '/me?userID=7')).json();
    assert.equal(initial.phoneNumber, '+212612345678');
    assert.equal((await fetch(base + '/me?userID=8')).status, 403);
    assert.equal((await update({ userID: 8, firstName: 'Changed' })).status, 403);
    assert.equal(writes.length, 0);
    for (const invalid of [{}, { firstName: ' ' }, { gender: 'invalid' }, { height: 301 }, { height: -1 }, { interests: 'Yoga' }, { interests: Array(6).fill('Yoga') }]) assert.equal((await update(invalid)).status, 400);
    assert.equal(writes.length, 0);
    const saved = await update({ userID: 7, firstName: ' Amal ', lastName: 'Client', height: 172.5, interests: [' Yoga ', 'Swimming', 'Yoga'] });
    assert.equal(saved.status, 200);
    const body = await saved.json();
    assert.equal(body.profile.firstName, 'Amal');
    assert.deepEqual(JSON.parse(body.profile.interests), ['Yoga', 'Swimming']);
    assert.equal(body.profile.phoneNumber, '+212612345678');
    assert.equal(body.profile.height, 172.5);
    const refreshed = await (await fetch(base + '/me')).json();
    assert.deepEqual(refreshed, body.profile);
    assert.ok(!writes[0].sql.includes('phoneNumber=')); // Contact changes use the existing account endpoint.
  } finally { await new Promise(resolve => server.close(resolve)); delete globalThis.clientProfileTestDB; }
});
