import {nutritionNotificationAllowed} from './nutritionReminders.js';
import admin from 'firebase-admin';
import { readFileSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import db from '../config/db.js';
import {emitUser} from './realtime.js';
import {publicMediaUrl} from './publicMedia.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

let isFirebaseInitialized = false;
const delivering = new Set();
async function deliverStoredNotification(id, payload) {
  if (delivering.has(String(id))) return;
  delivering.add(String(id));
  try {
    const [[row]]=await db.query('SELECT * FROM notifications WHERE id=?',[id]);
    if (!row || row.pushDelivered) return;
    if (!await nutritionNotificationAllowed(db,row)) {
      // Quiet, revoked or stale habit alerts are skipped, not replayed later.
      // Marking them handled also prevents starvation of the shared push queue.
      await db.query('UPDATE notifications SET pushDelivered=1 WHERE id=?',[id]);
      return;
    }
    const result=await sendPushNotification(payload);
    if (result.success) await db.query('UPDATE notifications SET pushDelivered=1 WHERE id=?',[id]);
  } finally { delivering.delete(String(id)); }
}

function initFirebase() {
  if (isFirebaseInitialized) return true;
  // The API's authentication module already initializes the default Firebase app.
  if (admin.apps.length > 0) { isFirebaseInitialized = true; return true; }
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
      stringData[key] = String(key === 'actorAvatar' ? publicMediaUrl(value) ?? '' : value ?? '');
    }
    stringData.click_action = 'FLUTTER_NOTIFICATION_CLICK';

    const message = {
      notification: {
        title,
        body,
      },
      data: stringData,
      token: fcmToken,
      android: {priority:'high',notification:{channelId:'sirvya_high_importance_channel',sound:'default'}},
      apns: {payload:{aps:{sound:'default'}}},
      webpush: {headers:{Urgency:'high'},notification:{icon:'/icons/Icon-192.png'}},
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
    const [inserted] = await db.query(
      `INSERT IGNORE INTO notifications
         (recipientUserID, type, title, body, relatedEntityID, actorName, actorAvatar, uniqueKey)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [recipientUserID, type, title, body, relatedEntityID, actorName, actorAvatar, key]
    );
    if (!inserted.affectedRows) return;
    emitUser(recipientUserID,'notification_created',{recipientUserID,notificationID:inserted.insertId,type,title,body,relatedEntityID,actorName,actorAvatar});

    // 2. Send FCM Push Notification
    await deliverStoredNotification(inserted.insertId, {
      recipientUserID,
      title,
      body,
      data: {
        title,
        recipientUserID,
        body,
        type,
        relatedEntityID: relatedEntityID || '',
        actorName: actorName || '',
        actorAvatar: actorAvatar || '',
        notificationID: inserted.insertId,
      }
    });
  } catch (err) {
    console.error('createAndSendNotification error:', err.message);
  }
}

// Retry queued alerts, including verification changes written by web admin.
export async function sendPendingNotifications() {
  const [rows] = await db.query(`SELECT n.* FROM notifications n JOIN users u ON u.id=n.recipientUserID LEFT JOIN app_campaigns c ON n.type='app_campaign' AND c.id=n.relatedEntityID
    WHERE n.pushDelivered=0 AND (n.type<>'app_campaign' OR (c.status='active' AND c.startsAt<=UTC_TIMESTAMP() AND (c.expiresAt IS NULL OR c.expiresAt>UTC_TIMESTAMP()))) AND n.createdAt>=DATE_SUB(NOW(),INTERVAL 24 HOUR)
    AND u.fcmToken IS NOT NULL AND u.fcmToken<>'' ORDER BY n.id ASC LIMIT 100`);
  for (const n of rows) {
    if (n.type === 'app_campaign') {
      const [[active]] = await db.query("SELECT id FROM app_campaigns WHERE id=? AND status='active' AND startsAt<=UTC_TIMESTAMP() AND (expiresAt IS NULL OR expiresAt>UTC_TIMESTAMP())", [n.relatedEntityID]);
      if (!active) continue;
    }
    await deliverStoredNotification(n.id,{recipientUserID:n.recipientUserID,title:n.title,body:n.body,
      data:{recipientUserID:n.recipientUserID,notificationID:n.id,type:n.type,relatedEntityID:n.relatedEntityID || '',actorName:n.actorName || '',actorAvatar:n.actorAvatar || '',title:n.title,body:n.body}});
  }
}
