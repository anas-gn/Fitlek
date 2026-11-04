import test from 'node:test';
import assert from 'node:assert/strict';
import express from 'express';
import jwt from 'jsonwebtoken';
process.env.JWT_SECRET='nutrition-goal-route-test';
const {createNutritionRouter}=await import('../services/nutritionDiary.js');

test('goal APIs isolate clients, prefill saved details and roll back targets with failed plan edits',async t=>{
  const state={plans:new Map(),goals:new Map([[7,{calories:2000}]]),fail:false};
  const db={async query(sql,a=[]){
    const id=Number(a[0]);
    if(sql.startsWith('SELECT plan,status'))return [state.plans.has(id)?[state.plans.get(id)]:[]];
    if(sql.startsWith('SELECT height'))return [[{height:id===7?175:180}]];
    if(sql.startsWith('SELECT weight,'))return [[]];
    if(sql.startsWith('SELECT weight FROM'))return sql.includes('ORDER BY createdAt')?[[{weight:id===7?80:90}]]:[[]];
    if(sql.startsWith('SELECT goals'))return [state.goals.has(id)?[{goals:JSON.stringify(state.goals.get(id))}]:[]];
    if(sql.startsWith('INSERT INTO client_nutrition_plans')){state.plans.set(id,{plan:a[1],status:a[2],revision:a[3],startedAt:'2026-10-16T00:00:00.000Z'});return [{}];}
    if(sql.startsWith('INSERT INTO client_nutrition_goals')){if(state.fail)throw Error('Database unavailable');state.goals.set(id,JSON.parse(a[1]));return [{}];}
    if(sql.startsWith('SELECT mealDate,payload'))return [id===7?[{mealDate:'2026-10-16',payload:JSON.stringify({mealDate:'2026-10-16',ingredients:[{calories:500,protein:30,carbs:50,fat:10}]})}]:[]];
    throw Error('Unexpected query '+sql);
  },async execute(sql,a){return this.query(sql,a);},async getConnection(){let plans,goals;return {query:db.query.bind(db),async beginTransaction(){plans=new Map(state.plans);goals=new Map(state.goals);},async commit(){},async rollback(){state.plans=plans;state.goals=goals;},release(){}};}};
  const app=express();app.use(express.json());app.use('/diary',createNutritionRouter(db));const server=app.listen(0,'127.0.0.1');await new Promise(resolve=>server.once('listening',resolve));t.after(()=>server.close());
  const call=(path,method='GET',body,id=7,role='client')=>fetch(`http://127.0.0.1:${server.address().port}/diary${path}`,{method,headers:{'Content-Type':'application/json',...(id?{Authorization:`Bearer ${jwt.sign({id,role},process.env.JWT_SECRET)}`}:{})},...(body?{body:JSON.stringify(body)}:{})});
  assert.equal((await call('/plan','GET',null,0)).status,401);assert.equal((await call('/plan','GET',null,7,'coach')).status,403);
  const initial=await(await call('/plan')).json();assert.equal(initial.defaults.currentWeight,80);assert.equal(initial.defaults.targets.calories,2000);
  const plan={userID:8,goalType:'lose',age:30,height:175,currentWeight:80,targetWeight:75,targets:{calories:2200},reminders:{enabled:false}};
  assert.equal((await call('/plan','PUT',plan)).status,200);assert.equal(state.plans.has(7),true);assert.equal(state.plans.has(8),false);
  const own=await(await call('/plan?userID=8')).json();assert.equal(own.plan.targetWeight,75);
  assert.equal((await(await call('/plan','GET',null,8)).json()).plan,null);
  state.fail=true;assert.equal((await call('/plan','PUT',{...plan,targetWeight:70,targets:{calories:2100}})).status,503);state.fail=false;
  const unchanged=await(await call('/plan')).json();assert.equal(unchanged.plan.targetWeight,75);assert.equal(unchanged.plan.targets.calories,2200);
  assert.equal((await call('/plan','PUT',{goalType:'balanced',age:15,targets:{calories:1500}})).status,400);
  assert.equal((await call('/plan/summary?from=2026-02-30&to=2026-03-01')).status,400);
  assert.equal((await(await call('/plan/summary?from=2026-10-01&to=2026-11-01')).json()).loggedDays,1);
  assert.equal((await(await call('/plan/summary?from=2026-10-01&to=2026-11-01','GET',null,8)).json()).loggedDays,0);
});
