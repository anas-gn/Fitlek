import {cert, getApps, initializeApp} from 'firebase-admin/app';
export {getAuth} from 'firebase-admin/auth';
export {getMessaging} from 'firebase-admin/messaging';
import { createRequire } from 'module';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const require = createRequire(import.meta.url);

export function initFirebase() {
  const apps=getApps();
  if (apps.length > 0) return apps[0];

  let credential;
  const keyPath = path.join(__dirname, 'sirvya-app-firebase-adminsdk-fbsvc-5858641a2a.json');

  if (fs.existsSync(keyPath)) {
    // Local environment
    const serviceAccount = require(keyPath);
    credential = cert(serviceAccount);
  } else if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    // Production (Heroku)
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    credential = cert(serviceAccount);
  } else {
    throw new Error('Firebase Service Account is missing! Please provide FIREBASE_SERVICE_ACCOUNT env var or local JSON file.');
  }

  return initializeApp({ credential });
}
