import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App.jsx'
import { MOBILE } from './lib/mobile.js'
import { sirvyaBoot } from './lib/api.js'
import './index.css'

// App.jsx restores per-route scroll itself; the browser's own attempt races it.
if ('scrollRestoration' in history) history.scrollRestoration = 'manual'

// Sirvya SSO boot: when this frontend is loaded from the SIRVYA app, the native
// side passes a credential via a URL fragment and sirvyaBoot() (api.js) resolves
// it BEFORE the app renders, so boot()'s first api('/api/me') already carries
// `Authorization: Bearer` and the server resolves the user immediately.
//   #sirvya_token=…  openGym session token (mobile WebView path) — used as-is.
//   #sirvya_login=…  raw Firebase/Sirvya credential (web path) — exchanged here,
//                    same-origin, then the session goes into setRemoteAuth().
// No fragment → normal boot (passkey / guest front door).
sirvyaBoot().finally(() => {
  createRoot(document.getElementById('root')).render(
    <StrictMode><App /></StrictMode>
  )

  // Not in the mobile build: the native shell already serves everything from disk.
  if (!MOBILE && 'serviceWorker' in navigator && location.protocol === 'https:') {
    navigator.serviceWorker.register('sw.js').catch(() => {})
  }
})
