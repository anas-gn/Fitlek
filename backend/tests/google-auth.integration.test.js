import test from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import express from 'express';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
dotenv.config({path: new URL('../.env', import.meta.url), quiet: true});

// Mock only Firebase verification in this isolated test server. The running API
// continues to verify real tokens; no Google account or email is contacted.
test('Google auth schema and existing account compatibility', {skip: process.env.AUTH_TEST_MYSQL !== '1'}, async t => {
  assert.ok(['localhost', '127.0.0.1', '::1'].includes(process.env.DB_HOST), 'Auth fixtures require local MySQL');
  const {default: db} = await import('../config/db.js');
  const {ensureGoogleAuthSchema} = await import('../config/googleAuthSchema.js');
  const {default: admin, initFirebase} = await import('../config/firebase.js');
  initFirebase();
  const firebaseAuth = admin.auth();
  const originalVerifier = firebaseAuth.verifyIdToken;
  const prefix = `google-auth-test-${Date.now()}-${process.pid}`;
  const users = [];
  let server;
  try {
    await ensureGoogleAuthSchema(db);
    await ensureGoogleAuthSchema(db);
    const [columns] = await db.query("SHOW COLUMNS FROM users WHERE Field IN ('passwordHash','gender','authProvider')");
    assert.equal(columns.find(c => c.Field === 'passwordHash').Null, 'YES');
    assert.equal(columns.find(c => c.Field === 'gender').Null, 'YES');
    assert.ok(columns.find(c => c.Field === 'authProvider').Type.includes("'both'"));
    firebaseAuth.verifyIdToken = async token => {
      if (token === 'network-failure') throw Object.assign(new Error('Blocked certificate request'), {code: 'app/network-error'});
      if (!['new', 'existing', 'coach', 'unverified'].includes(token)) throw Object.assign(new Error('Invalid fixture token'), {code: 'auth/argument-error'});
      return {uid: `${prefix}-${token}`, email: `${prefix}-${token}@example.invalid`, email_verified: token !== 'unverified', name: 'Auth Fixture'};
    };
    const password = 'FixturePassword123';
    const hash = await bcrypt.hash(password, 10);
    const [inserted] = await db.query("INSERT INTO users (firstName,lastName,email,passwordHash,role,gender) VALUES ('Auth','Fixture',?,?,'client','Other')", [`${prefix}-existing@example.invalid`, hash]);
    users.push(inserted.insertId);
    const {default: authRoutes} = await import('../routes/anas/auth.js');
    const app = express(); app.use(express.json()); app.use('/api/auth', authRoutes);
    server = app.listen(0, '127.0.0.1'); await once(server, 'listening');
    const request = async (path, body) => {
      const response = await fetch(`http://127.0.0.1:${server.address().port}/api/auth/${path}`, {method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(body)});
      return {status: response.status, body: await response.json()};
    };
    await t.test('invalid and unverified tokens are rejected', async () => {
      assert.equal((await request('google', {})).status, 400);
      assert.equal((await request('google', {idToken: 'invalid'})).status, 401);
      assert.equal((await request('google', {idToken: 'unverified'})).status, 401);
    });
    await t.test('provider connection failures remain unauthenticated and report service unavailable', async () => {
      const response = await request('google', {idToken: 'network-failure'});
      assert.equal(response.status, 503);
      assert.match(response.body.error, /temporarily unavailable/);
      assert.equal(response.body.accessToken, undefined);
    });
    await t.test('Google-only account creation and repeated login keep one user', async () => {
      const created = await request('google', {idToken: 'new'});
      assert.equal(created.status, 200, JSON.stringify(created.body));
      users.push(created.body.user.id);
      assert.equal(created.body.isNewUser, true);
      assert.equal(created.body.hasPassword, false);
      assert.equal(jwt.verify(created.body.accessToken, process.env.JWT_SECRET).id, created.body.user.id);
      const again = await request('google', {idToken: 'new'});
      assert.equal(again.status, 200);
      assert.equal(again.body.user.id, created.body.user.id);
      assert.equal(again.body.isNewUser, false);
      const [[saved]] = await db.query('SELECT passwordHash,gender,authProvider FROM users WHERE id=?', [created.body.user.id]);
      assert.deepEqual(saved, {passwordHash: null, gender: null, authProvider: 'google'});
      assert.equal((await request('login', {email: created.body.user.email, password})).status, 403);
    });
    await t.test('linking Google preserves the existing account, role and password login', async () => {
      const linked = await request('google', {idToken: 'existing', role: 'coach'});
      assert.equal(linked.status, 200, JSON.stringify(linked.body));
      assert.equal(linked.body.user.id, inserted.insertId);
      assert.equal(linked.body.user.role, 'client');
      assert.equal(linked.body.hasPassword, true);
      const [[saved]] = await db.query('SELECT passwordHash,authProvider FROM users WHERE id=?', [inserted.insertId]);
      assert.equal(saved.passwordHash, hash);
      assert.equal(saved.authProvider, 'both');
      const localLogin = await request('login', {email: linked.body.user.email, password});
      assert.equal(localLogin.status, 200, JSON.stringify(localLogin.body));
      assert.equal(localLogin.body.user.id, inserted.insertId);
    });
    await t.test('Google coach signup still creates its SIRVYA coach profile', async () => {
      const created = await request('google', {idToken: 'coach', role: 'coach'});
      assert.equal(created.status, 200, JSON.stringify(created.body));
      users.push(created.body.user.id);
      assert.equal(created.body.user.role, 'coach');
      const [profiles] = await db.query('SELECT userID FROM coachprofiles WHERE userID=?', [created.body.user.id]);
      assert.equal(profiles.length, 1);
    });
    await t.test('Google-only users can set a password without an FCM token', async () => {
      const signedIn = await request('google', {idToken: 'new'});
      const response = await fetch(`http://127.0.0.1:${server.address().port}/api/auth/set-password`, {
        method: 'POST', headers: {'Content-Type':'application/json',Authorization:`Bearer ${signedIn.body.accessToken}`},
        body: JSON.stringify({password:'NewFixturePassword123'}),
      });
      assert.equal(response.status,200,JSON.stringify(await response.json()));
      const loggedIn = await request('login',{email:signedIn.body.user.email,password:'NewFixturePassword123'});
      assert.equal(loggedIn.status,200); assert.equal(loggedIn.body.user.id,signedIn.body.user.id);
      const [[saved]] = await db.query('SELECT authProvider FROM users WHERE id=?',[signedIn.body.user.id]);
      assert.equal(saved.authProvider,'both');
    });
  } finally {
    firebaseAuth.verifyIdToken = originalVerifier;
    if (server) await new Promise(resolve => server.close(resolve));
    // Clean only this run's fixtures, including any insert preceding a failed response.
    const [fixtures] = await db.query('SELECT id FROM users WHERE email LIKE ?', [`${prefix}%@example.invalid`]);
    for (const user of fixtures) {
      await db.query('DELETE FROM authtokens WHERE userID=?', [user.id]);
      await db.query('DELETE FROM coachprofiles WHERE userID=?', [user.id]);
      await db.query('DELETE FROM users WHERE id=?', [user.id]);
    }
    await db.end();
  }
});
