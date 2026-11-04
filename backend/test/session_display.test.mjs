import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import express from 'express';
import {presentSessionLocation} from '../services/sessionLocation.js';

let sequence = 0;
test('coach profile returns the saved account phone to the profile and completion checklist', async () => {
  await serveRoute('../routes/pahae/coachProfile.js', async sql => {
    assert.match(sql, /u.phoneNumber/);
    assert.match(sql, /COALESCE\(NULLIF\(TRIM\(u.phoneNumber\), ''\), cp.tel\) AS tel/);
    return [[{id: 8, phoneNumber: '+212612345678', tel: '+212612345678'}]];
  }, async base => {
    const response = await fetch(base);
    assert.equal(response.status, 200);
    const data = await response.json();
    assert.equal(data.phoneNumber, '+212612345678');
    assert.equal(data.tel, data.phoneNumber);
  });
});
async function serveRoute(path, query, run) {
  const registry = `sessionDisplay${sequence++}`;
  globalThis[registry] = {query};
  const sourceUrl = new URL(path, import.meta.url);
  let source = await fs.readFile(sourceUrl, 'utf8');
  source = source.replace(/import (db|pool) from '..\/..\/config\/db.js';/,
      (_, name) => `const ${name}=globalThis.${registry};`)
    .replace(/import\s*{\s*createAndSendNotification\s*}\s*from '[^']+';/,
      'const createAndSendNotification=async()=>{};')
    .replace(/import\s*{[^}]*requireRole[^}]*}\s*from '[^']+';/,
      'const requireAuth=(req,res,next)=>next(); const requireRole=()=>requireAuth;')
    .replace(/from '([^']+)'/g, (_, specifier) => `from '${specifier === 'express'
      ? new URL('../node_modules/express/index.js', import.meta.url).href
      : specifier.startsWith('.') ? new URL(specifier, sourceUrl).href : specifier}'`);
  const {default: router} = await import('data:text/javascript;base64,' + Buffer.from(source).toString('base64'));
  const app = express();
  app.use(express.json());
  app.use((req, res, next) => {req.user = {id: 8, role: 'coach'}; next();});
  app.use(router);
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  try {await run(`http://127.0.0.1:${server.address().port}`);}
  finally {await new Promise(resolve => server.close(resolve)); delete globalThis[registry];}
}

test('legacy partner addresses are hidden and explicitly selected gyms stay intact', () => {
  assert.match(presentSessionLocation({location: 'HAY EL AMAL 2 RUE 68', companyName: 'Partner'}).location, /arranged/);
  assert.equal(presentSessionLocation({location: 'Atlas Gym · Main street', companyName: null}).location, 'Atlas Gym · Main street');
});

test('coach dashboard returns the confirmed monetary value as a number for each period', async () => {
  const filters = [];
  await serveRoute('../routes/pahae/coachDashboard.js', async (sql) => {
    if (sql.includes('AS totalReservations')) {
      assert.match(sql, /SUM\(CASE WHEN r.status = 'confirmed'\s+AND r.pricingStatus IN \('fixed', 'accepted'\) THEN r.price ELSE 0 END\)/);
      filters.push(sql);
      return [[{totalReservations: 5, pendingReservations: 1, confirmedReservations: 4, confirmedValue: '1050.50'}]];
    }
    if (sql.includes('SELECT isApproved')) return [[{isApproved: 1}]];
    if (sql.includes('AS totalClients')) return [[{totalClients: 2}]];
    if (sql.includes('AS periodClients')) return [[{periodClients: 1}]];
    if (sql.includes('earnedPoints')) return [[{earnedPoints: 140, totalInvitations: 3}]];
    if (sql.includes('AS count')) return [[{count: 1}]];
    return [[]];
  }, async base => {
    for (const period of ['today', 'week', 'month']) {
      const response = await fetch(`${base}/?period=${period}`);
      assert.equal(response.status, 200);
      const data = await response.json();
      assert.equal(data.confirmedValue, 1050.50);
      assert.equal(data.confirmedReservations, 4);
    }
  });
  assert.match(filters[0], /CURDATE/);
  assert.match(filters[1], /YEARWEEK/);
  assert.match(filters[2], /MONTH/);
});

test('specialty categories return the icon selected in the admin', async () => {
  await serveRoute('../routes/anas/coach.js', async sql => {
    if (sql.includes('FROM categories')) return [[{id: 9, name: 'Yoga', icon: 'svgrepo:194845'}]];
    return [[{specialties: '["Yoga"]', specialty: null}]];
  }, async base => {
    const response = await fetch(`${base}/specialties`);
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), [{id: 9, name: 'Yoga', coachCount: 1, icon: 'svgrepo:194845'}]);
  });
});

test('list and detail responses include the shared coach review and hide old company locations', async () => {
  await serveRoute('../routes/anas/reservations.js', async sql => {
    if (!sql.includes('SELECT r.*')) return [[]];
    assert.match(sql, /LEFT JOIN coachreviews cr ON cr.coachID=r.coachID AND cr.clientID=r.clientID/);
    assert.match(sql, /cr.rating AS reviewRating/);
    return [[{id: 1, coachID: 7, clientID: 8, reviewRating: 4, reviewComment: 'Helpful', location: 'HAY EL AMAL 2 RUE 68', companyName: 'Partner'}]];
  }, async base => {
    for (const path of ['/?role=client&userID=8', '/1', '/1/details']) {
      const response = await fetch(base + path);
      assert.equal(response.status, 200, await response.clone().text());
      const data = await response.json();
      const row = Array.isArray(data) ? data[0] : data;
      assert.equal(row.reviewRating, 4);
      assert.equal(row.reviewComment, 'Helpful');
      assert.match(row.location, /arranged with coach/);
    }
  });
});
