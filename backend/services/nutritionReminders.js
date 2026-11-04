import { readNutritionPlan, planProgress, nutritionSummary } from './nutritionGoals.js';

export function localClock(now, timeZone) {
  const parts = Object.fromEntries(new Intl.DateTimeFormat('en-GB', {timeZone, year:'numeric',month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit',hourCycle:'h23'}).formatToParts(now).filter(p=>p.type!=='literal').map(p=>[p.type,p.value]));
  return { day:`${parts.year}-${parts.month}-${parts.day}`, minute:Number(parts.hour)*60+Number(parts.minute), year:Number(parts.year), month:Number(parts.month), dayOfMonth:Number(parts.day) };
}
export function inQuietHours(minute, start, end) {
  if(start===end) return false;
  return start<end ? minute>=start&&minute<end : minute>=start||minute<end;
}
const object = value => typeof value==='string' ? JSON.parse(value) : value;
const dayKey = date => date.toISOString().slice(0,10);

export function chooseNutritionReminder({plan, clock, meals, goals, lastWeightAt, now = new Date()}) {
  if(!plan.reminders.enabled || plan.status!=='active' || inQuietHours(clock.minute,plan.reminders.quietStart,plan.reminders.quietEnd)) return null;
  const totals = {calories:0,protein:0,carbs:0,fat:0};
  const types = new Set();
  for(const meal of meals) { types.add(meal.mealType); for(const ingredient of meal.ingredients ?? []) for(const key of Object.keys(totals)) totals[key] += Number(ingredient[key])||0; }
  const adult = plan.age>=18;
  if(adult && plan.reminders.calorieAlerts && goals.calories>=1500 && totals.calories>goals.calories*1.05) return {
    kind:'calories', title:'A quick diary check', body:'Your logged calories are above today’s target. Estimates vary—review portions if needed. Keep your usual meals; no need to compensate.' };
  for(const type of ['dinner','lunch','breakfast']) {
    const time = plan.reminders[type];
    if(clock.minute>=time && clock.minute<time+60 && !types.has(type)) {
      const ideas = adult && plan.reminders.mealIdeas && type==='dinner' && meals.length>0 && goals.calories>=1500 && totals.calories<goals.calories*.85;
      return { kind:type, title: ideas ? 'Time for a gentle check-in' : 'A moment for your meal diary', body: ideas
        ? (goals.protein>0 && totals.protein<goals.protein*.7 ? `If you’re hungry and planning a meal, include ${['vegan','vegetarian'].includes(plan.diet)?'a plant-based protein source':'a protein source'} that suits you. Log anything you’ve already eaten.` : 'If you’re hungry, take a meal break that fits your routine. Your diary may not include everything you’ve eaten.')
        : `Already had ${type}? Add it when convenient. There’s no need to change your eating to complete the diary.` };
    }
  }
  if(adult && plan.reminders.mealIdeas && types.has('dinner') && goals.calories>=1500 && totals.calories<goals.calories*.85 && clock.minute>=plan.reminders.dinner+45 && clock.minute<plan.reminders.dinner+105) return {
    kind:'balance',title:'A gentle end-of-day check-in',body:'Your diary is below your target and may be incomplete. Log anything missing. If you’re hungry, choose something that suits your appetite and routine.' };
  if(adult && plan.reminders.weekly && ['lose','gain'].includes(plan.goalType) && clock.minute>=660 && clock.minute<720 && new Date(clock.day+'T12:00:00Z').getUTCDay()===0 && (!lastWeightAt || now-new Date(lastWeightAt)>7*86400000)) return {kind:'weight',title:'Your weekly check-in',body:'If a weigh-in feels helpful, add one to review your goal. Progress takes time; you can also pause these reminders.'};
  return null;
}

export async function nutritionNotificationAllowed(db, notification, now = new Date()) {
  if(!String(notification.type).startsWith('nutrition_')) return true;
  const [[recipient]] = await db.query('SELECT role FROM users WHERE id=?',[notification.recipientUserID]);
  if(recipient?.role!=='client') return false;
  const plan = await readNutritionPlan(db,notification.recipientUserID);
  if(!plan || !plan.reminders.enabled) return false;
  const clock = localClock(now,plan.timeZone);
  if(inQuietHours(clock.minute,plan.reminders.quietStart,plan.reminders.quietEnd)) return false;
  if(plan.status!=='active' && !(plan.status==='achieved' && notification.type==='nutrition_achieved')) return false;
  if(!String(notification.uniqueKey).startsWith(`nutrition:${notification.recipientUserID}:${plan.revision}:`)) return false;
  const kind = notification.type.replace('nutrition_','');
  if(kind==='calories' && (!plan.reminders.calorieAlerts || plan.age<18)) return false;
  if(kind==='monthly' && !plan.reminders.monthly) return false;
  if(kind==='yearly' && !plan.reminders.yearly) return false;
  if(kind==='weight' && !plan.reminders.weekly) return false;
  if(kind==='balance' && (!plan.reminders.mealIdeas || plan.age<18)) return false;
  // Never deliver an old meal/threshold alert the following local day.
  if(['breakfast','lunch','dinner','calories','weight','balance'].includes(kind) && !notification.uniqueKey.endsWith(`:${clock.day}:${kind}`)) return false;
  if(['breakfast','lunch','dinner','calories','balance'].includes(kind)) {
    const [rows] = await db.query('SELECT payload FROM client_meals WHERE userID=? AND mealDate=?',[notification.recipientUserID,clock.day]);
    const meals=rows.map(row=>object(row.payload));
    if(meals.some(meal=>meal.mealType===kind)) return false;
    if(kind==='calories' || kind==='balance') {
      const [[row]]=await db.query('SELECT goals FROM client_nutrition_goals WHERE userID=?',[notification.recipientUserID]);
      const goal=row?object(row.goals).calories:null;
      const total=meals.reduce((sum,meal)=>sum+(meal.ingredients??[]).reduce((value,i)=>value+(Number(i.calories)||0),0),0);
      if(kind==='calories' && !(goal>=1500 && total>goal*1.05)) return false;
      if(kind==='balance' && !(goal>=1500 && total<goal*.85 && meals.some(meal=>meal.mealType==='dinner'))) return false;
    }
  }
  if(kind==='weight') {
    const [[row]]=await db.query('SELECT MAX(createdAt) AS at FROM weighthistory WHERE clientID=?',[notification.recipientUserID]);
    if(row.at && now-new Date(row.at)<=7*86400000) return false;
  }
  return true;
}

async function insertReminder(db,userID,plan,clock,item,period=clock.day,now=new Date()) {
  const [[count]] = await db.query('SELECT COUNT(*) AS count,MAX(createdAt) AS latest FROM notifications WHERE recipientUserID=? AND uniqueKey LIKE ?', [userID, `nutrition:${userID}:%:${clock.day}:%`]);
  if(Number(count.count)>=3 || (count.latest && now-new Date(count.latest)<90*60000)) return false;
  const key = `nutrition:${userID}:${plan.revision}:${period}:${clock.day}:${item.kind}`;
  const destination = item.kind==='monthly' ? Number(period.replace('-','')) : item.kind==='yearly' ? Number(period) : Number(clock.day.replaceAll('-',''));
  const [result] = await db.query(`INSERT IGNORE INTO notifications (recipientUserID,type,title,body,actorName,uniqueKey,relatedEntityID) VALUES (?,?,?,?,?,?,?)`,[userID,`nutrition_${item.kind}`,item.title,item.body.slice(0,255),'Sirvya nutrition',key,destination]);
  return Boolean(result.affectedRows);
}

export async function processNutritionUser(db,userID,now = new Date()) {
  const [[recipient]] = await db.query('SELECT role FROM users WHERE id=?',[userID]);
  if(recipient?.role!=='client') return;
  const plan = await readNutritionPlan(db,userID);
  if(!plan || plan.status!=='active') return;
  const clock = localClock(now,plan.timeZone);
  const progress = await planProgress(db,userID,plan,now);
  if(progress.reached) {
    // Completion is durable; the next pass does not restart goal prompts.
    await db.query("UPDATE client_nutrition_plans SET status='achieved' WHERE userID=? AND revision=? AND status='active'",[userID,plan.revision]);
    if(plan.reminders.enabled && !inQuietHours(clock.minute,plan.reminders.quietStart,plan.reminders.quietEnd)) await insertReminder(db,userID,plan,clock,{kind:'achieved',title:'A milestone worth noticing',body:'Your recent weigh-ins suggest you’ve reached your saved goal. Review your progress and choose whether to start a maintenance goal.'},`goal-${plan.revision}`,now);
    return;
  }
  if(!plan.reminders.enabled || inQuietHours(clock.minute,plan.reminders.quietStart,plan.reminders.quietEnd)) return;
  // Anniversary reviews are at most once per month/year, not daily repeats.
  const annual = plan.reminders.yearly && clock.month===1 && clock.dayOfMonth<=7 && plan.startedAt.slice(0,4)<String(clock.year);
  const monthly = plan.reminders.monthly && clock.dayOfMonth<=3 && plan.startedAt.slice(0,7)<clock.day.slice(0,7);
  if((annual || monthly) && clock.minute>=600 && clock.minute<1260) {
    const reviews = [];
    if(annual) reviews.push({kind:'yearly',from:`${clock.year-1}-01-01`,to:`${clock.year}-01-01`,period:String(clock.year-1)});
    if(monthly) {
      const from=dayKey(new Date(Date.UTC(clock.year,clock.month-2,1)));
      reviews.push({kind:'monthly',from,to:clock.day.slice(0,7)+'-01',period:from.slice(0,7)});
    }
    for(const {kind,from,to,period} of reviews) {
      const [sent] = await db.query('SELECT id FROM notifications WHERE recipientUserID=? AND uniqueKey LIKE ? LIMIT 1',[userID,`nutrition:${userID}:${plan.revision}:${period}:%:${kind}`]);
      if(!sent.length) {
        const summary = await nutritionSummary(db,userID,from,to);
        if(await insertReminder(db,userID,plan,clock,{kind,title:kind==='yearly'?'Your year in review':'Your month in review',body:`You logged meals on ${summary.loggedDays} days in this period. Review your progress and adjust your goal if your needs have changed.`},period,now)) return;
      }
    }
  }

  const [rows] = await db.query('SELECT payload FROM client_meals WHERE userID=? AND mealDate=?',[userID,clock.day]);
  const [[goals]] = await db.query('SELECT goals FROM client_nutrition_goals WHERE userID=?',[userID]);
  const [[last]] = await db.query('SELECT MAX(createdAt) AS at FROM weighthistory WHERE clientID=?',[userID]);
  const item = chooseNutritionReminder({plan,clock,meals:rows.map(row=>object(row.payload)),goals:goals?object(goals.goals):{},lastWeightAt:last.at,now});
  if(item) await insertReminder(db,userID,plan,clock,item,clock.day,now);
}

export function startNutritionReminderWorker(pool) {
  let busy=false;
  const run = async () => {
    if(busy) return; busy=true; let tx;
    try {
      tx=await pool.getConnection();
      const [[lock]]=await tx.query("SELECT GET_LOCK('sirvya_nutrition_reminders',0) AS acquired");
      if(!lock.acquired) return;
      let cursor=0;
      while(true) {
        const [rows]=await tx.query("SELECT p.userID FROM client_nutrition_plans p JOIN users u ON u.id=p.userID AND u.role='client' WHERE p.status='active' AND p.userID>? AND (JSON_UNQUOTE(JSON_EXTRACT(p.plan,'$.reminders.enabled'))='true' OR JSON_UNQUOTE(JSON_EXTRACT(p.plan,'$.goalType')) IN ('lose','gain')) ORDER BY p.userID LIMIT 100",[cursor]);
        if(!rows.length) break;
        for(const row of rows) { cursor=row.userID; try { await processNutritionUser(tx,row.userID); } catch { console.error('Nutrition reminder evaluation failed'); } }
      }
    } catch { console.error('Nutrition reminder worker unavailable'); }
    finally { if(tx) { try {await tx.query("SELECT RELEASE_LOCK('sirvya_nutrition_reminders')");} catch {} tx.release(); } busy=false; }
  };
  const timer=setInterval(run,60000); timer.unref();
  const initial=setTimeout(run,10000); initial.unref();
  return timer;
}
