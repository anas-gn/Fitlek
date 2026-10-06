import {json} from './workoutDomain.js';
import {dailyReminderKey} from './workoutExperience.js';
import {readWeeklyDays} from './workoutQueries.js';

const localDay = (date, timeZone) => new Intl.DateTimeFormat('en-CA', {
  timeZone, year:'numeric', month:'2-digit', day:'2-digit'
}).format(date);
async function trainedToday(db, userID, date, timeZone, now) {
  // Two UTC days cover every local day, including date-line zones and DST.
  // Bind Date objects consistently with the existing mysql2 session timestamps.
  const [sessions] = await db.query(`SELECT startedAt FROM workout_sessions
    WHERE clientID=? AND status='completed' AND startedAt>=? AND startedAt<=?`,
    [userID, new Date(now.getTime()-2*86400000), now]);
  return sessions.some(s => localDay(new Date(s.startedAt), timeZone) === date);
}

// Durable scheduling in SIRVYA's MySQL; delivery uses its existing FCM service.
export async function dispatchWorkoutReminders(db,notify,now=new Date(),{checkDaily=true,userIDs=null}={}) {
  if(userIDs!=null&&(!Array.isArray(userIDs)||!userIDs.length||userIDs.some(id=>!Number.isSafeInteger(id)||id<1)))throw new Error('Invalid reminder scope');
  const scope=userIDs==null?'':' AND userID IN (?)';
  // Alerts are UTC DATETIME values; bind strings so mysql2's local Date conversion
  // cannot shift a rest countdown when Node and MySQL use different time zones.
  const timestamp=now.toISOString().slice(0,19).replace('T',' ');
  const [preferences]=checkDaily?await db.query("SELECT userID,preferences FROM workout_preferences WHERE JSON_EXTRACT(preferences,'$.reminderEnabled')=true"+scope,userIDs==null?[]:[userIDs]):[[]];
  for(const row of preferences){
    const p=json(row.preferences),key=dailyReminderKey(p,now);if(!key)continue;
    const weekday=Number(new Intl.DateTimeFormat('en',{timeZone:p.timeZone,weekday:'short'}).format(now).replace(/.*/,v=>({Mon:1,Tue:2,Wed:3,Thu:4,Fri:5,Sat:6,Sun:7})[v]));
    const date=key.slice(6);
    if(await trainedToday(db,row.userID,date,p.timeZone,now))continue;
    const [override]=await db.query('SELECT userID FROM workout_schedule_dates WHERE userID=? AND workoutDate=?',[row.userID,date]);
    const days=override.length?(await db.query(`SELECT d.name FROM workout_days d JOIN workout_plans p ON p.id=d.workoutPlanID WHERE p.clientID=? AND p.status='assigned' AND EXISTS(SELECT 1 FROM workout_schedule sc WHERE sc.userID=p.clientID AND sc.workoutDayID=d.id AND sc.workoutDate=?) AND (p.coachID IS NULL OR EXISTS(SELECT 1 FROM coachclients cc WHERE cc.coachID=p.coachID AND cc.clientID=p.clientID)) ORDER BY d.sortOrder LIMIT 5`,[row.userID,date]))[0]:(await readWeeklyDays(db,row.userID)).filter(d=>Number(d.dayOfWeek)===weekday).slice(0,5);
    if(!days.length)continue;
    await db.query(`INSERT IGNORE INTO workout_alerts (userID,alertKey,dueAt,title,body) VALUES (?,?,?,'SIRVYA Workout',?)`,[row.userID,key,timestamp,days.map(d=>d.name).join(' + ').slice(0,500)]);
  }
  const [due]=await db.query("SELECT *,DATE_FORMAT(dueAt,'%Y-%m-%dT%H:%i:%sZ') AS dueAtUTC FROM workout_alerts WHERE deliveredAt IS NULL AND (claimedAt IS NULL OR claimedAt<DATE_SUB(?,INTERVAL 2 MINUTE)) AND dueAt<=? AND dueAt>=DATE_SUB(?,INTERVAL 1 DAY)"+scope+" ORDER BY dueAt,id LIMIT 100",[timestamp,timestamp,timestamp,...(userIDs==null?[]:[userIDs])]);
  for(const alert of due){
    // Atomic claim keeps multiple API workers from delivering the same alert.
    const [claimed]=await db.query('UPDATE workout_alerts SET claimedAt=? WHERE id=? AND deliveredAt IS NULL AND (claimedAt IS NULL OR claimedAt<DATE_SUB(?,INTERVAL 2 MINUTE))',[timestamp,alert.id,timestamp]);
    if(!claimed.affectedRows)continue;
    try{
      if (!alert.sessionID && alert.alertKey.startsWith('daily:')) {
        const [[row]] = await db.query('SELECT preferences FROM workout_preferences WHERE userID=?',[alert.userID]);
        const p = row ? json(row.preferences) : {};
        const date = alert.alertKey.slice(6);
        if (!p.reminderEnabled || localDay(now,p.timeZone) !== date ||
            await trainedToday(db,alert.userID,date,p.timeZone,now)) {
          await db.query('UPDATE workout_alerts SET deliveredAt=?,claimedAt=NULL WHERE id=?',[timestamp,alert.id]);
          continue;
        }
      }
      await notify({recipientUserID:alert.userID,type:alert.sessionID?'workout_rest':'workout_reminder',title:alert.title,body:alert.body,relatedEntityID:alert.sessionID,uniqueKey:`workout_alert:${alert.id}:${new Date(alert.dueAtUTC).getTime()}`,requirePersistence:true});
      await db.query('UPDATE workout_alerts SET deliveredAt=?,claimedAt=NULL WHERE id=? AND dueAt=?',[timestamp,alert.id,alert.dueAtUTC.slice(0,19).replace('T',' ')]);
    }
    catch {await db.query('UPDATE workout_alerts SET claimedAt=NULL WHERE id=?',[alert.id]);}
  }
}
export function startWorkoutReminders(db,notify,ready) {
  let busy=false,lastMinute=null;
  const timer=setInterval(async()=>{if(busy)return;busy=true;try{await ready;const now=new Date(),minute=now.toISOString().slice(0,16);await dispatchWorkoutReminders(db,notify,now,{checkDaily:minute!==lastMinute});lastMinute=minute;}catch(error){console.error('Workout reminders unavailable:',error.code||error.message);}finally{busy=false;}},1000);
  timer.unref();return ()=>clearInterval(timer);
}
