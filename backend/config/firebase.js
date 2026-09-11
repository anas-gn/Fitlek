import admin from 'firebase-admin';
import { createRequire } from 'module';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const require = createRequire(import.meta.url);

let firebaseApp;

export function initFirebase() {
  if (admin.apps.length > 0) {
    firebaseApp = admin.apps[0];
    return;
  }

  let credential;
  const keyPath = path.join(__dirname, 'sirvya-app-firebase-adminsdk-fbsvc-5858641a2a.json');

  if (fs.existsSync(keyPath)) {
    // Local environment
    const serviceAccount = require(keyPath);
    credential = admin.credential.cert(serviceAccount);
  } else if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    // Production (Heroku)
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    credential = admin.credential.cert(serviceAccount);
  } else {
    throw new Error('Firebase Service Account is missing! Please provide FIREBASE_SERVICE_ACCOUNT env var or local JSON file.');
  }

  firebaseApp = admin.initializeApp({ credential });
}

export default admin;
