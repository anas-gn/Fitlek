import test from 'node:test';
import assert from 'node:assert/strict';
import {cleanNutritionPlan,maintenanceEstimate,weightGoalProgress,saveNutritionPlan,nutritionSummary} from '../services/nutritionGoals.js';
import {chooseNutritionReminder,localClock,inQuietHours,processNutritionUser,nutritionNotificationAllowed} from '../services/nutritionReminders.js';

const input = overrides => ({goalType:'lose',age:30,height:175,currentWeight:80,targetWeight:75,timeZone:'UTC',targets:{calories:2200,protein:120},reminders:{enabled:true,calorieAlerts:true,mealIdeas:true},...overrides});
const plan = overrides => ({...cleanNutritionPlan(input(overrides)),status:'active',revision:1,startedAt:'2026-10-01T00:00:00.000Z'});
const meal = (calories=500,type='lunch') => ({mealDate:'2026-10-16',mealType:type,ingredients:[{calories,protein:30,carbs:40,fat:12}]});
test('goal validation protects younger clients and rejects invalid weight targets and time zones',()=>{
  assert.equal(cleanNutritionPlan({goalType:'balanced'}).reminders.enabled,false);
  assert.throws(()=>cleanNutritionPlan(input({age:16})),/Adult weight goals/);
  assert.throws(()=>cleanNutritionPlan(input({targetWeight:45})),/below the adult/);
  assert.throws(()=>cleanNutritionPlan(input({targetWeight:85})),/direction/);
  assert.throws(()=>cleanNutritionPlan(input({timeZone:'Not/AZone'})),/time zone/);
  assert.throws(()=>cleanNutritionPlan(input({reminders:{breakfast:1440}})),/reminder times/);
  assert.throws(()=>cleanNutritionPlan({goalType:'balanced',age:15,targets:{calories:1800}}),/under 18/);
  assert.equal(cleanNutritionPlan({goalType:'balanced',age:15,reminders:{enabled:true,calorieAlerts:true,mealIdeas:true}}).reminders.calorieAlerts,false);
});
test('maintenance estimates use known equations only for eligible adults and never choose a deficit',()=>{
  assert.equal(maintenanceEstimate(plan({goalType:'maintain',age:30,height:180,currentWeight:80,formulaSex:'male',activity:'low',estimateEligible:true})),2150);
  assert.equal(maintenanceEstimate(plan({goalType:'maintain',age:30,height:170,currentWeight:70,formulaSex:'female',activity:'low',estimateEligible:true})),1750);
  assert.equal(maintenanceEstimate(plan({estimateEligible:false})),null);
  assert.equal(maintenanceEstimate({...plan(),age:17,estimateEligible:true,formulaSex:'female'}),null);
  assert.equal(maintenanceEstimate({...plan(),age:90,estimateEligible:true,formulaSex:'female'}),null);
});
test('quiet hours, DST and local day boundaries use the chosen IANA zone',()=>{
  assert.equal(inQuietHours(23*60,22*60,8*60),true);assert.equal(inQuietHours(7*60,22*60,8*60),true);assert.equal(inQuietHours(12*60,22*60,8*60),false);
  assert.equal(localClock(new Date('2026-03-29T00:30:00Z'),'Europe/Paris').minute,90);
  assert.equal(localClock(new Date('2026-03-29T01:30:00Z'),'Europe/Paris').minute,210);
  assert.equal(localClock(new Date('2026-10-16T00:30:00Z'),'America/New_York').day,'2026-10-15');
});
test('reminder decisions reflect logged estimates without demands to eat, skip meals or compensate',()=>{
  const clock={day:'2026-10-16',minute:1200};
  const over=chooseNutritionReminder({plan:plan(),clock,meals:[meal(2500)],goals:{calories:2200}});
  assert.equal(over.kind,'calories');assert.match(over.body,/logged calories/);assert.match(over.body,/no need to compensate/);
  const low=chooseNutritionReminder({plan:plan({diet:'vegan'}),clock,meals:[meal(500)],goals:{calories:2200,protein:120}});
  assert.equal(low.kind,'dinner');assert.match(low.body,/If you’re hungry/);assert.match(low.body,/plant-based/);
  const empty=chooseNutritionReminder({plan:plan(),clock,meals:[],goals:{calories:2200}});assert.match(empty.body,/Already had dinner/);
  const afterDinner=chooseNutritionReminder({plan:plan(),clock:{...clock,minute:1260},meals:[meal(500,'dinner')],goals:{calories:2200}});assert.equal(afterDinner.kind,'balance');assert.match(afterDinner.body,/may be incomplete/);
  assert.equal(chooseNutritionReminder({plan:{...plan(),status:'paused'},clock,meals:[],goals:{}}),null);
  assert.equal(chooseNutritionReminder({plan:plan(),clock:{...clock,minute:1380},meals:[],goals:{}}),null);
  const tiny=chooseNutritionReminder({plan:plan(),clock:{...clock,minute:1000},meals:[meal(1300)],goals:{calories:1000}});assert.equal(tiny,null);
});
test('completion needs distinct recent weigh-in days; stale or single readings do not end a goal',()=>{
  const p=plan(),now=new Date('2026-10-16T12:00:00Z');
  assert.equal(weightGoalProgress(p,[{day:'2026-10-16',weight:74}],now).reached,false);
  assert.equal(weightGoalProgress(p,[{day:'2026-10-16',weight:74},{day:'2026-10-16',weight:74}],now).reached,false);
  assert.equal(weightGoalProgress(p,[{day:'2026-10-16',weight:74},{day:'2026-10-14',weight:75}],now).reached,true);
  const stale=weightGoalProgress(p,[{day:'2026-08-16',weight:74},{day:'2026-08-14',weight:75}],now);assert.equal(stale.reached,false);assert.equal(stale.currentWeight,74);
});

function database(p=plan()){
  const state={plan:p,notifications:new Map(),weights:[],meals:[],now:new Date('2026-10-16T09:00:00Z'),goals:p.targets};
  const match=(value,pattern)=>new RegExp('^'+pattern.replaceAll('%','.*')+'$').test(value);
  const db={state,async query(sql,a=[]){
    if(sql.startsWith('SELECT role FROM users'))return [[{role:state.role??'client'}]];
    if(sql.startsWith('SELECT plan,status'))return [[{plan:JSON.stringify(state.plan),status:state.plan.status,revision:state.plan.revision,startedAt:state.plan.startedAt}]];
    if(sql.startsWith('SELECT weight,'))return [state.weights];
    if(sql.startsWith('SELECT weight FROM'))return [state.weights];
    if(sql.startsWith('SELECT payload'))return [state.meals.map(value=>({payload:JSON.stringify(value)}))];
    if(sql.startsWith('SELECT mealDate,payload'))return [state.meals.map(value=>({mealDate:value.mealDate,payload:JSON.stringify(value)}))];
    if(sql.startsWith('SELECT goals'))return [[{goals:JSON.stringify(state.goals)}]];
    if(sql.startsWith('SELECT MAX(createdAt)'))return [[{at:null}]];
    if(sql.startsWith('SELECT COUNT(*)')){const rows=[...state.notifications.values()].filter(n=>match(n.uniqueKey,a[1]));return [[{count:rows.length,latest:rows.at(-1)?.createdAt??null}]];}
    if(sql.startsWith('SELECT id FROM notifications'))return [[...state.notifications.values()].filter(n=>match(n.uniqueKey,a[1])).slice(0,1)];
    if(sql.startsWith('INSERT IGNORE INTO notifications')){if(state.notifications.has(a[5]))return [{affectedRows:0}];state.notifications.set(a[5],{recipientUserID:a[0],type:a[1],title:a[2],body:a[3],uniqueKey:a[5],relatedEntityID:a[6],createdAt:state.now});return [{affectedRows:1}];}
    if(sql.startsWith('UPDATE client_nutrition_plans')){state.plan.status='achieved';return [{affectedRows:1}];}
    if(sql.startsWith('INSERT INTO client_nutrition_plans')){const old=state.plan;state.plan={...JSON.parse(a[1]),status:a[2],revision:a[3],startedAt:a[4]?state.now.toISOString():old.startedAt};return [{}];}
    if(sql.startsWith('INSERT INTO client_nutrition_goals')){state.goals=JSON.parse(a[1]);return [{}];}
    throw Error('Unexpected SQL '+sql);
  }};return db;
}
test('routine alerts are durable, deduplicated, spaced apart and capped across goal revisions',async()=>{
  const db=database();await processNutritionUser(db,7,db.state.now);await processNutritionUser(db,7,db.state.now);assert.equal(db.state.notifications.size,1);
  db.state.now=new Date('2026-10-16T14:00:00Z');await processNutritionUser(db,7,db.state.now);
  db.state.now=new Date('2026-10-16T20:00:00Z');await processNutritionUser(db,7,db.state.now);assert.equal(db.state.notifications.size,3);
  db.state.plan.revision=2;db.state.meals=[meal(3000)];db.state.now=new Date('2026-10-16T21:59:00Z');await processNutritionUser(db,7,db.state.now);assert.equal(db.state.notifications.size,3);
});
test('monthly/yearly review is once per period and goal completion stops later reminders',async()=>{
  const db=database(plan({goalType:'balanced'}));db.state.meals=[meal()];db.state.now=new Date('2026-11-01T11:00:00Z');await processNutritionUser(db,7,db.state.now);
  db.state.now=new Date('2026-11-02T11:00:00Z');await processNutritionUser(db,7,db.state.now);assert.equal([...db.state.notifications.values()].filter(n=>n.type==='nutrition_monthly').length,1); assert.equal([...db.state.notifications.values()].find(n=>n.type==='nutrition_monthly').relatedEntityID,202610);
  db.state.now=new Date('2027-01-01T11:00:00Z');await processNutritionUser(db,7,db.state.now);db.state.now=new Date('2027-01-02T11:00:00Z');await processNutritionUser(db,7,db.state.now);assert.equal([...db.state.notifications.values()].filter(n=>n.type==='nutrition_yearly').length,1);
  const achieved=database();achieved.state.weights=[{day:'2026-10-16',weight:74},{day:'2026-10-14',weight:75}];await processNutritionUser(achieved,7,achieved.state.now);assert.equal(achieved.state.plan.status,'achieved');await processNutritionUser(achieved,7,achieved.state.now);assert.equal(achieved.state.notifications.size,1);
});
test('delivery rechecks opt-out, quiet hours, goal revision and stale local-day alerts',async()=>{
  const db=database();const n={recipientUserID:7,type:'nutrition_lunch',uniqueKey:'nutrition:7:1:2026-10-16:2026-10-16:lunch'};
  assert.equal(await nutritionNotificationAllowed(db,n,new Date('2026-10-16T14:00:00Z')),true);
  assert.equal(await nutritionNotificationAllowed(db,n,new Date('2026-10-16T23:00:00Z')),false);
  assert.equal(await nutritionNotificationAllowed(db,n,new Date('2026-10-17T14:00:00Z')),false);
  db.state.plan.reminders.enabled=false;assert.equal(await nutritionNotificationAllowed(db,n,new Date('2026-10-16T14:00:00Z')),false);
  db.state.plan.reminders.enabled=true;db.state.plan.revision=2;assert.equal(await nutritionNotificationAllowed(db,n,new Date('2026-10-16T14:00:00Z')),false);
  db.state.plan.revision=1;db.state.role='coach';assert.equal(await nutritionNotificationAllowed(db,n,new Date('2026-10-16T14:00:00Z')),false);
  db.state.role='client';db.state.meals=[meal(2500)];
  const calories={...n,type:'nutrition_calories',uniqueKey:'nutrition:7:1:2026-10-16:2026-10-16:calories'};
  assert.equal(await nutritionNotificationAllowed(db,calories,new Date('2026-10-16T14:00:00Z')),true);
  db.state.meals=[];assert.equal(await nutritionNotificationAllowed(db,calories,new Date('2026-10-16T14:00:00Z')),false);
  assert.equal(await nutritionNotificationAllowed(db,{type:'new_message'}),true);
});
test('editing preferences preserves the baseline; a fresh goal resets revision and can stay paused',async()=>{
  const db=database();await saveNutritionPlan(db,7,input({currentWeight:79,reminders:{enabled:false}}));assert.equal(db.state.plan.currentWeight,80);assert.equal(db.state.plan.revision,1);
  await saveNutritionPlan(db,7,input({currentWeight:79,targetWeight:74,status:'paused'}));assert.equal(db.state.plan.currentWeight,79);assert.equal(db.state.plan.revision,2);assert.equal(db.state.plan.status,'paused');
});
test('review averages only logged days and includes actual weight change',async()=>{
  const db=database();db.state.meals=[meal(500),meal(700,'dinner')];db.state.weights=[{weight:80},{weight:78}];const review=await nutritionSummary(db,7,'2026-10-01','2026-11-01');assert.equal(review.loggedDays,1);assert.equal(review.dailyAverages.calories,1200);assert.equal(review.weight.change,-2);
});
