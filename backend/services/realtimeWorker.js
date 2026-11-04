import {nutritionNotificationAllowed} from './nutritionReminders.js';
import {ensureRealtimeJournal} from './realtimeJournal.js';
import {emitUser,invalidate} from './realtime.js';
import {sendPendingNotifications} from './pushNotificationService.js';
import {dispatchCampaigns} from './appCampaigns.js';
import {publicMediaUrl} from './publicMedia.js';

export async function startRealtimeWorker(db) {
  await ensureRealtimeJournal(db);
  const [[event]] = await db.query('SELECT COALESCE(MAX(id),0) AS id FROM app_live_events');
  const [[notification]] = await db.query('SELECT COALESCE(MAX(id),0) AS id FROM notifications');
  let eventCursor=event.id, notificationCursor=notification.id, busy=false;
  let passes=0;
  const timer=setInterval(async () => {
    if (busy) return;
    busy=true;
    try {
      await dispatchCampaigns(db);
      const [events]=await db.query('SELECT id,domain FROM app_live_events WHERE id>? ORDER BY id LIMIT 500',[eventCursor]);
      for (const domain of new Set(events.map(row=>row.domain))) invalidate(domain);
      if (events.length) eventCursor=events.at(-1).id;
      const [notifications]=await db.query(`SELECT n.*,c.pushEnabled AS campaignPush,
        (c.status='active' AND c.startsAt<=UTC_TIMESTAMP() AND (c.expiresAt IS NULL OR c.expiresAt>UTC_TIMESTAMP())) AS campaignActive
        FROM notifications n LEFT JOIN app_campaigns c ON n.type='app_campaign' AND c.id=n.relatedEntityID
        WHERE n.id>? ORDER BY n.id LIMIT 500`,[notificationCursor]);
      for (const n of notifications) {
        if (!await nutritionNotificationAllowed(db,n)) continue;
        if (n.type==='app_campaign' && !n.campaignActive) continue;
        emitUser(n.recipientUserID,'notification_created',{silent:n.type==='app_campaign' && !n.campaignPush,recipientUserID:n.recipientUserID,notificationID:n.id,type:n.type,title:n.title,body:n.body,relatedEntityID:n.relatedEntityID,actorName:n.actorName,actorAvatar:publicMediaUrl(n.actorAvatar)});
      }
      if (notifications.length) notificationCursor=notifications.at(-1).id;
      await sendPendingNotifications();
      if (++passes%1200===0) await db.query('DELETE FROM app_live_events WHERE createdAt<DATE_SUB(NOW(),INTERVAL 1 DAY)');
    } catch(error) { console.error('Live update delivery failed:',error.message); }
    finally { busy=false; }
  },3000);
  timer.unref();
  return timer;
}
