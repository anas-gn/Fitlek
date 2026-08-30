import admin from 'firebase-admin';
import { readFileSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import db from '../config/db.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

let isFirebaseInitialized = false;

function initFirebase() {
  if (isFirebaseInitialized) return true;
  try {
    let serviceAccount;
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    } else {
      const serviceAccountPath = path.join(__dirname, '..', 'config', 'sirvya-app-firebase-adminsdk-fbsvc-5858641a2a.json');
      serviceAccount = JSON.parse(readFileSync(serviceAccountPath, 'utf8'));
    }

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    isFirebaseInitialized = true;
    console.log('✅ Firebase Admin SDK initialized for push notifications');
    return true;
  } catch (error) {
    console.error('❌ Failed to initialize Firebase Admin SDK:', error.message);
    return false;
  }
}

/**
 * Send push notification to a user by userID
 * @param {Object} params
 * @param {number|string} params.recipientUserID - The recipient's user ID in MySQL
 * @param {string} params.title - Notification title
 * @param {string} params.body - Notification body content
 * @param {Object} [params.data] - Additional string key-value payload for Flutter app
 */
export async function sendPushNotification({ recipientUserID, title, body, data = {} }) {
  if (!initFirebase()) return { success: false, reason: 'Firebase not initialized' };

  try {
    // Fetch user's FCM token from MySQL
    const [rows] = await db.query(
      'SELECT fcmToken FROM users WHERE id = ? AND fcmToken IS NOT NULL AND fcmToken != ""',
      [recipientUserID]
    );

    if (!rows.length || !rows[0].fcmToken) {
      console.log(`ℹ️ No FCM token found for user ID ${recipientUserID}, skipping push.`);
      return { success: false, reason: 'No FCM token' };
    }

    const fcmToken = rows[0].fcmToken;

    // Convert data values to strings (FCM requires string data fields)
    const stringData = {};
    for (const [key, value] of Object.entries(data)) {
      stringData[key] = String(value ?? '');
    }
    stringData.click_action = 'FLUTTER_NOTIFICATION_CLICK';

    const message = {
      notification: {
        title,
        body,
      },
      data: stringData,
      token: fcmToken,
    };

    const response = await admin.messaging().send(message);
    console.log(`✉️ Push notification sent to user ${recipientUserID} (Msg ID: ${response})`);
    return { success: true, messageId: response };
  } catch (error) {
    console.error(`❌ Push notification failed for user ${recipientUserID}:`, error.message);
    if (error.code === 'messaging/invalid-registration-token' || error.code === 'messaging/registration-token-not-registered') {
      try {
        await db.query('UPDATE users SET fcmToken = NULL WHERE id = ?', [recipientUserID]);
      } catch (err) {
        // ignore
      }
    }
    return { success: false, error: error.message };
  }
}

/**
 * Helper to insert an in-app notification in MySQL AND send a Push Notification simultaneously
 */
export async function createAndSendNotification({
  recipientUserID,
  type,
  title,
  body,
  relatedEntityID = null,
  actorName = null,
  actorAvatar = null,
  uniqueKey = null
}) {
  try {
    // 1. Insert in-app notification into MySQL
    const key = uniqueKey || `${type}:${Date.now()}:${recipientUserID}`;
    await db.query(
      `INSERT IGNORE INTO notifications
         (recipientUserID, type, title, body, relatedEntityID, actorName, actorAvatar, uniqueKey)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [recipientUserID, type, title, body, relatedEntityID, actorName, actorAvatar, key]
    );

    // 2. Send FCM Push Notification
    await sendPushNotification({
      recipientUserID,
      title,
      body,
      data: {
        type,
        relatedEntityID: relatedEntityID || '',
        actorName: actorName || '',
      }
    });
  } catch (err) {
    console.error('createAndSendNotification error:', err.message);
  }
}
