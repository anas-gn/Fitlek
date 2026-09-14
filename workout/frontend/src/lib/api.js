// Backend + WebAuthn helpers (ported from the vanilla app).
export const IS_APPLE = /iPhone|iPad|iPod|Macintosh/.test(navigator.userAgent)
export const IS_ANDROID = /Android/.test(navigator.userAgent)
export const BIO = IS_APPLE ? 'Face ID / Touch ID' : IS_ANDROID ? 'fingerprint or face unlock' : 'your fingerprint, face or PIN'
export const VAULT = IS_APPLE ? 'iCloud Keychain' : IS_ANDROID ? 'Google Password Manager' : 'your password manager'
// PublicKeyCredential is the WebAuthn-specific capability signal. Do not also gate the UI on
// navigator.credentials: some browsers expose WebAuthn while that generic Credential Management
// API check produces a false negative (notably Chrome on iOS). The real create/get calls still run
// only after the user chooses a passkey action and surface any genuine browser error there.
export const webauthnOK = () => typeof window.PublicKeyCredential !== 'undefined'

// The paired mobile app (lib/remote.js) is the only caller of these — everywhere else stays on
// same-origin cookies, so remoteBase/remoteToken stay empty and api() behaves exactly as before.
let remoteBase = ''
let remoteToken = null
export function setRemoteAuth(base, token) { remoteBase = base || ''; remoteToken = token || null }

export async function api(path, opts) {
  const headers = Object.assign({ 'Content-Type': 'application/json' }, opts && opts.headers)
  if (remoteToken) headers.Authorization = 'Bearer ' + remoteToken
  const r = await fetch(remoteBase + path, Object.assign({}, opts, { headers }))
  const data = await r.json().catch(() => ({}))
  // The body rides along on the error: a 409 from /api/data carries the server's document.
  if (!r.ok) { const e = new Error(data.error || ('HTTP ' + r.status)); e.status = r.status; e.data = data; throw e }
  return data
}

// Bootstraps the connection itself: the base isn't configured yet (that's what this call decides),
// so it talks straight to the server the user typed in, no Authorization header.
export async function pairRedeem(serverBase, code) {
  const r = await fetch(serverBase + '/api/pair/redeem', {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ code })
  })
  const data = await r.json().catch(() => ({}))
  if (!r.ok) { const e = new Error(data.error || ('HTTP ' + r.status)); e.status = r.status; throw e }
  return data
}

// Sirvya SSO: exchanges a Firebase ID token (minted by the Sirvya mobile app over the
// user's Google account) for an openGym session token. The bridge verifies the token,
// maps/creates the openGym user by Firebase uid, and returns { user, token } — where
// `token` is exactly what api() sends as `Authorization: Bearer` on every later call.
// passkeyLogin()/passkeyRegister() stay the self-hosted flow; this is the sign-in path
// used when the workout frontend runs inside the SIRVYA app's WebView.
export async function sirvyaLogin(workoutBase, idToken) {
  const base = (workoutBase || '').replace(/\/+$/, '')
  if (!base) throw new Error('Sirvya login needs the workout server base')
  const r = await fetch(base + '/api/auth/sirvya-login', {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ token: idToken })
  })
  const data = await r.json().catch(() => ({}))
  if (!r.ok) { const e = new Error((data.message || data.error || 'HTTP ' + r.status) + (data.reason ? ': ' + data.reason : '')); e.status = r.status; e.data = data; throw e }
  setRemoteAuth(base, data.token)
  return data
}

/**
 * Sirvya WebView boot helper — reads the openGym session token that the native
 * Sirvya app passed through the URL fragment (#sirvya_token=…), wires it into
 * setRemoteAuth() so every api() call carries `Authorization: Bearer`, and
 * clears the fragment so HashRouter doesn't try to route to it.
 *
 * Called from main.jsx before the app renders, so that boot()'s first
 * api('/api/me') already has the bearer header and the server resolves the
 * user immediately — no second Firebase exchange needed on a warm reopen.
 *
 * No-op when the fragment is absent (i.e. the frontend is loaded directly in a
 * browser rather than inside the Sirvya app's WebView).
 */
export function sirvyaAuth() {
  const hash = location.hash || ''
  if (!hash.startsWith('#sirvya_token=')) return false
  const token = decodeURIComponent(hash.slice('#sirvya_token='.length))
  if (!token) return false
  // Same origin the WebView was loaded from — the workout server that minted
  // this token. api.js will prepend this to every relative path and attach the
  // bearer header, matching how readSession() validates it server-side.
  setRemoteAuth(location.origin, token)
  // Consume the fragment: the token must not linger in history or be visible
  // to the router. The WebView now sits on the server root; boot() / the router
  // will resolve the default route (Home) from there.
  history.replaceState(null, '', location.pathname + location.search)
  return true
}

/**
 * Sirvya boot for the web path. The Flutter web build cannot POST the bridge
 * itself — that would be a cross-origin browser request (CORS, plus the API's
 * Origin-based CSRF guard). So it hands the RAW credential over in the fragment
 * (#sirvya_login=…) and this page performs the exchange same-origin: the dev
 * server proxies /api to the workout API and stamps the Origin header the CSRF
 * guard expects. The fragment is consumed first so the raw credential never
 * lingers in history.
 *
 * #sirvya_token=… (mobile WebView path) is the already-exchanged openGym
 * session and goes straight into setRemoteAuth() via sirvyaAuth().
 *
 * Returns true when a Sirvya fragment was handled, false for a normal boot.
 */
export async function sirvyaBoot() {
  const hash = location.hash || ''
  if (!hash.startsWith('#sirvya_login=')) return sirvyaAuth()
  const raw = decodeURIComponent(hash.slice('#sirvya_login='.length))
  history.replaceState(null, '', location.pathname + location.search)
  if (raw) {
    try {
      await sirvyaLogin(location.origin, raw)
    } catch {
      // Exchange failed (unknown token, server unreachable…) — fall through to
      // the normal boot, which shows the passkey/guest front door.
    }
  }
  return true
}

const bufToB64u = buf => btoa(String.fromCharCode(...new Uint8Array(buf))).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
const b64uToBuf = s => Uint8Array.from(atob(s.replace(/-/g, '+').replace(/_/g, '/')), c => c.charCodeAt(0)).buffer

function toCreationOptions(o) {
  o.challenge = b64uToBuf(o.challenge)
  o.user.id = b64uToBuf(o.user.id)
  ;(o.excludeCredentials || []).forEach(c => { c.id = b64uToBuf(c.id) })
  return o
}
function toRequestOptions(o) {
  o.challenge = b64uToBuf(o.challenge)
  ;(o.allowCredentials || []).forEach(c => { c.id = b64uToBuf(c.id) })
  return o
}
function credToJSON(cred) {
  const r = cred.response
  const out = {
    id: cred.id, rawId: bufToB64u(cred.rawId), type: cred.type,
    clientExtensionResults: cred.getClientExtensionResults ? cred.getClientExtensionResults() : {},
    authenticatorAttachment: cred.authenticatorAttachment || null,
    response: { clientDataJSON: bufToB64u(r.clientDataJSON) }
  }
  if (r.attestationObject) {
    out.response.attestationObject = bufToB64u(r.attestationObject)
    out.response.transports = r.getTransports ? r.getTransports() : ['internal']
  }
  if (r.authenticatorData) {
    out.response.authenticatorData = bufToB64u(r.authenticatorData)
    out.response.signature = bufToB64u(r.signature)
    out.response.userHandle = r.userHandle ? bufToB64u(r.userHandle) : null
  }
  return out
}
export async function passkeyRegister(name, code) {
  const { cid, options } = await api('/api/register/options', { method: 'POST', body: JSON.stringify({ name, code: code || '' }) })
  const cred = await navigator.credentials.create({ publicKey: toCreationOptions(options) })
  const res = await api('/api/register/verify', { method: 'POST', body: JSON.stringify({ cid, credential: credToJSON(cred) }) })
  return res.user
}
export async function passkeyLogin() {
  const { cid, options } = await api('/api/login/options', { method: 'POST', body: '{}' })
  const cred = await navigator.credentials.get({ publicKey: toRequestOptions(options) })
  const res = await api('/api/login/verify', { method: 'POST', body: JSON.stringify({ cid, credential: credToJSON(cred) }) })
  return res.user
}
