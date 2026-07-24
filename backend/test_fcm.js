import admin from 'firebase-admin';
import { readFileSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load service account key
const serviceAccountPath = path.join(__dirname, 'config', 'sirvya-app-firebase-adminsdk-fbsvc-5858641a2a.json');
let serviceAccount;

try {
  serviceAccount = JSON.parse(readFileSync(serviceAccountPath, 'utf8'));
} catch (e) {
  console.error(`Failed to load service account key at ${serviceAccountPath}:`, e.message);
  process.exit(1);
}

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// Get registration token from CLI argument
const registrationToken = process.argv[2];

if (!registrationToken) {
  console.error('\n❌ Error: Missing FCM registration token.');
  console.log('\nUsage:');
  console.log('  node test_fcm.js <YOUR_FCM_TOKEN>\n');
  console.log('You can copy the FCM Token from your Flutter application console logs.');
  process.exit(1);
}

// Construct test message
const message = {
  notification: {
    title: 'Test Notification 🔔',
    body: 'Hello! This is a test push notification from the Sirvya backend.'
  },
  data: {
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
    type: 'test',
    message: 'It works!'
  },
  token: registrationToken
};

console.log(`Sending message to token: ${registrationToken.substring(0, 20)}...`);

admin.messaging().send(message)
  .then((response) => {
    console.log('✅ Successfully sent message. Response ID:', response);
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Error sending message:', error.message);
    process.exit(1);
  });
