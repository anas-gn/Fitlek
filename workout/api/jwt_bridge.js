// jwt_bridge.js — Sirvya Firebase-ID-token -> openGym session (ESM)
//
// POST /api/auth/sirvya-login
//   Body: { token: <firebase idToken> }
//   Response: { user: {...}, token: "<signed session token>" }
//
// Verifies the Firebase ID token with firebase-admin, looks up or creates an openGym
// user keyed by the Firebase uid (sirvyaUid), and returns a session token signed with
// the same HMAC-SHA256 scheme the rest of the server uses, so the WebView's api() and
// the mobile app's Bearer-token path both accept it without further plumbing.
//
// firebase-admin is loaded lazily via dynamic import. The server still boots and all
// passkey routes still work when FIREBASE_SERVICE_ACCOUNT is absent -- the only thing
// that goes dormant is the Sirvya login path, whose failure is surfaced cleanly to the
// client (503 + reason).
//
// IMPORTANT: the session token format matches server.js's readSession() exactly.
// readSession() expects "<uid>:<expiry>.<base64url-HMAC-SHA256(payload)>" -- that is,
// the payload and MAC are separated by a dot, and readSession splits on the last ".".
// The HMAC payload is "<uid>:<expiry>" (no version field for Sirvya-linked users).

import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
// ─── Sirvya platform JWT (email/password login) ───
// The Sirvya app signs its own session JWTs ({ id, role }, JWT_SECRET, 7d) and stores
// them client-side. The workout server does not share that secret, so instead of
// verifying the signature locally it validates the token against the Sirvya API: a
// requireAuth-protected profile fetch only returns 200 when the token is genuine and
// unexpired. Identity comes from the profile response. Override the target with
// SIRVYA_API_URL for local/staging Sirvya backends.
const SIRVYA_API = (process.env.SIRVYA_API_URL || 'http://51.170.143.251/api').replace(/\/+$/, '');

function decodeJwtPayload(token) {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    return JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8'));
  } catch {
    return null;
  }
}

async function fetchWithAuth(url, token, timeoutMs = 8000) {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const res = await fetch(url, { headers: { Authorization: 'Bearer ' + token }, signal: ctrl.signal });
    if (!res.ok) return null;
    return await res.json();
  } catch {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

/**
 * Validates a Sirvya platform JWT by asking the Sirvya backend who it belongs to.
 * Returns { uid, email, name } or null when the token is not a valid Sirvya session.
 * The decoded payload is only used to pick the endpoint; the 200 response is what
 * actually proves the token (the Sirvya backend verified the signature itself).
 */
async function verifySirvyaPlatformToken(token) {
  const payload = decodeJwtPayload(token);
  const id = payload && payload.id;
  if (id == null) return null;
  const role = payload.role || 'client';
  let profile = null;
  if (role === 'coach') {
    profile = await fetchWithAuth(SIRVYA_API + '/coach/profile', token);
  } else {
    profile = await fetchWithAuth(SIRVYA_API + '/clients/' + id, token);
  }
  if (!profile || profile.id == null) return null;
  const email = profile.email || '';
  const name =
    [profile.firstName, profile.lastName].filter(Boolean).join(' ') ||
    profile.name || email || ('Sirvya ' + role);
  return { uid: 'sirvya-' + id, email, name };
}

let firebaseAdmin = null;
let firebaseInitError = null;
let firebaseInitP = null;

async function getFirebaseAdmin() {
  if (firebaseAdmin) return firebaseAdmin;
  if (firebaseInitError) throw firebaseInitError;
  if (firebaseInitP) return firebaseInitP;
  firebaseInitP = (async () => {
    try {
      const admin = await import('firebase-admin');
      if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
        throw new Error('FIREBASE_SERVICE_ACCOUNT env var is not set');
      }
      let cred;
      try {
        cred = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      } catch {
        cred = JSON.parse(fs.readFileSync(process.env.FIREBASE_SERVICE_ACCOUNT, 'utf8'));
      }
      admin.initializeApp({ credential: admin.credential.cert(cred) });
      firebaseAdmin = admin;
      return firebaseAdmin;
    } catch (e) {
      firebaseInitError = e;
      throw e;
    }
  })();
  return firebaseInitP;
}

function makeSession(user) {
  // Match server.js's sign(): payload = "<uid>:<expiry>", token = payload + '.' + mac
  const SECRET = fs
    .readFileSync(path.join(process.env.DATA_DIR || '/data', 'secret'), 'utf8')
    .trim();
  const exp = Date.now() + 1000 * 60 * 60 * 24 * 90; // 90 days, matches SESSION_DAYS default
  const payload = String(user.id) + ':' + exp;
  const mac = crypto
    .createHmac('sha256', SECRET)
    .update(payload)
    .digest('base64url');
  return payload + '.' + mac;
}

function findOrCreateUser(db, firebaseUid, email, name) {
  let user = db.users.find(u => u.sirvyaUid === firebaseUid);
  if (user) {
    if (user.name !== name && name) user.name = name;
    if (user.email !== email && email) user.email = email;
    return user;
  }
  user = {
    id: crypto.randomBytes(16).toString('hex'),
    name: name || email || 'Sirvya user',
    email: email || '',
    sirvyaUid: firebaseUid,
    createdAt: new Date().toISOString(),
    prefs: {},
    state: { workouts: [], routines: [], bodyweight: [], _rev: 0, _ts: Date.now() },
    push: [],
  };
  db.users.push(user);
  return user;
}

/**
 * Returns the route handler for POST /api/auth/sirvya-login.
 * db + saveDb are passed in by server.js so this module stays free of circular
 * requires -- server.js imports this module before db is fully initialized.
 * The handler closes over the server's json/readBody/audit helpers, matching how
 * the coach routes are injected.
 */
export function sirvyaLogin(db, saveDb, json, readBody, audit) {
  return async (req, res) => {
    let body;
    try {
      body = await readBody(req);
    } catch {
      return json(res, 400, { error: 'bad_request', message: 'malformed JSON' });
    }

    const idToken = body && body.token;
    if (!idToken || typeof idToken !== 'string') {
      return json(res, 400, { error: 'missing_token', message: 'token is required' });
    }

    // 1) Sirvya platform JWT (email/password login) — validated against the Sirvya API.
    const platform = await verifySirvyaPlatformToken(idToken);
    if (platform) {
      const user = findOrCreateUser(db, platform.uid, platform.email, platform.name);
      saveDb();
      const session = makeSession(user);
      audit(req, 'sirvya.login', { uid: user.id, name: user.name, msg: 'Sirvya platform JWT login' });
      return json(res, 200, {
        user: { id: user.id, name: user.name, email: user.email },
        token: session,
      });
    }

    // 2) Firebase ID token (Google / Apple sign-in)
    let fb;
    try {
      fb = await getFirebaseAdmin();
    } catch (e) {
      return json(res, 503, {
        error: 'sso_unavailable',
        message: 'Sirvya SSO is not configured on this server',
        reason: e && e.message ? e.message : String(e),
      });
    }

    let decoded;
    try {
      decoded = await fb.auth().verifyIdToken(idToken);
    } catch (e) {
      const msg = e && (e.message || e.code || String(e));
      if (/expired|expir/i.test(msg)) {
        return json(res, 401, { error: 'token_expired', message: 'Firebase ID token has expired' });
      }
      if (/revoked/i.test(msg)) {
        return json(res, 401, { error: 'token_revoked', message: 'Firebase ID token has been revoked' });
      }
      return json(res, 401, { error: 'invalid_token', message: 'Firebase ID token is invalid' });
    }

    const firebaseUid = decoded.sub;
    const email = decoded.email || '';
    const name = decoded.name || decoded.email || 'Sirvya user';

    if (!firebaseUid) {
      return json(res, 400, { error: 'invalid_token', message: 'token has no uid claim' });
    }

    const user = findOrCreateUser(db, firebaseUid, email, name);
    saveDb();

    const token = makeSession(user);
    audit(req, 'sirvya.login', { uid: user.id, name: user.name, msg: 'Sirvya SSO login' });

    json(res, 200, {
      user: { id: user.id, name: user.name, email: user.email },
      token,
    });
  };
}


