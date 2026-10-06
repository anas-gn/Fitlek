import test from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import express from 'express';
import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
dotenv.config({path: new URL('../.env', import.meta.url), quiet: true});

// Explicit opt-in. Never run fixtures against a remote server or create another database.
test('SIRVYA Workout HTTP / MySQL lifecycle and existing endpoint regression', {skip: process.env.WORKOUT_TEST_MYSQL !== '1'}, async t => {
  assert.ok(['localhost', '127.0.0.1', '::1'].includes(process.env.DB_HOST), 'Integration fixtures require local MySQL');
  const {default: db} = await import('../config/db.js');
  const {ensureWorkoutSchema} = await import('../config/workoutSchema.js');
  const {createWorkoutRouter} = await import('../routes/anas/workout.js').catch(async error=>{await db.end();throw error;});
  const {requireAuth} = await import('../middleware/auth.js');
  let server;
  const users = [];
  const prefix = `workout-test-${Date.now()}-${process.pid}`;
  const notifications = [];
  try {
    await ensureWorkoutSchema(db);
    await ensureWorkoutSchema(db); // Idempotency and stable catalog IDs.
    for (const role of ['coach', 'client', 'coach', 'client', 'manager']) {
      const [r] = await db.query(`INSERT INTO users (firstName, lastName, email, passwordHash, role, gender)
        VALUES ('Workout', 'Test', ?, 'test-fixture-no-login', ?, 'Other')`, [`${prefix}-${users.length}@example.invalid`, role]);
      users.push({id: r.insertId, role});
    }
    const [coach, client, otherCoach, otherClient, manager] = users;
    await db.query('INSERT INTO coachclients (coachID, clientID) VALUES (?, ?)', [coach.id, client.id]);
    const app = express(); app.use(express.json({limit:'10mb'}));
    app.use('/api/workout', createWorkoutRouter(db, {notify: async n => { notifications.push(n); }}));
    // Existing profile, reservation, message and notification routes remain mounted normally.
    const {default: clients} = await import('../routes/anas/client.js');
    const {default: reservations} = await import('../routes/anas/reservations.js');
    const {default: conversations} = await import('../routes/anas/conversations.js');
    const {default: calendar} = await import('../routes/pahae/coachCalendar.js');
    const {default: weightHistory} = await import('../routes/anas/weightHistory.js');
    app.use('/api/weight-history',requireAuth,weightHistory);
    app.use('/api/clients', requireAuth, clients);
    app.use('/api/reservations', requireAuth, reservations);
    app.use('/api/conversations', requireAuth, conversations);
    app.use('/api/coach/calendar', calendar);
    server = app.listen(0, '127.0.0.1'); await once(server, 'listening');
    const origin = `http://127.0.0.1:${server.address().port}/api`;
    const request = async (user, path, method = 'GET', body) => {
      const token = user ? jwt.sign(user, process.env.JWT_SECRET, {expiresIn: '5m'}) : null;
      const response = await fetch(origin + path, {method, headers: {'Content-Type': 'application/json', ...(token ? {Authorization: `Bearer ${token}`} : {})}, ...(body === undefined ? {} : {body: JSON.stringify(body)})});
      return {status: response.status, body: await response.json()};
    };
    const conversationBaseline = await request(client, `/conversations?userID=${client.id}&role=client`);
    assert.equal(conversationBaseline.status,200,JSON.stringify(conversationBaseline.body));
    let planID, sessionID, originalExerciseID, secondDayID, body;
    await t.test('malformed workout collections, history rows and tokens fail safely',async()=>{
      for(const workoutDayIDs of ['1',{},1])assert.equal((await request(client,'/workout/sessions','POST',{workoutDayIDs})).status,400);
      for(const token of ['malformed',jwt.sign(client,process.env.JWT_SECRET,{expiresIn:-1})]){
        const response=await fetch(origin+'/workout/exercises',{headers:{Authorization:`Bearer ${token}`}});
        assert.equal(response.status,401);
      }
      assert.equal((await request(client,`/workout/stats?clientID=${otherClient.id}`)).status,403);
      assert.equal((await request(otherCoach,`/workout/history?clientID=${client.id}`)).status,403);
    });
    await t.test('JWT, roles and existing SIRVYA screens still use the same users', async () => {
      assert.equal((await request(null, '/workout/exercises')).status, 401);
      assert.equal((await request(manager, '/workout/exercises')).status, 403);
      assert.equal((await request(client, '/clients/me?userID=' + client.id)).body.id, client.id);
      const reservationsResult = await request(client, `/reservations?userID=${client.id}&role=client`);
      assert.equal(reservationsResult.status, 200, JSON.stringify(reservationsResult.body));
      assert.equal((await request(coach, '/coach/calendar/reservations')).status, 200);
      assert.equal((await request({...client, role: 'coach'}, '/workout/exercises')).status, 401);
    });
    await t.test('library search, filters, details and coach-client selection', async () => {
      const library = await request(client, '/workout/exercises?search=bench&equipment=barbell&exerciseType=reps&muscleGroup=chest');
      assert.equal(library.status, 200); assert.ok(library.body.data.length >= 1);
      const e = library.body.data.find(e=>e.externalSource==='sirvya'); assert.ok(e);
      assert.ok((await request(client, '/workout/exercises/' + e.id)).body.instructions.length);
      assert.equal((await request(coach, '/workout/clients')).body.data[0].id, client.id);
      const timed = (await request(client, '/workout/exercises?search=plank')).body.data[0];
      body = {clientID: client.id, name: 'Integration plan', status: 'assigned', description: 'Fixture', days: [
        {name: 'Push', dayOfWeek: 1, exercises: [{exerciseID: e.id, targetSets: 2, targetReps: 10, targetWeight: 60, restSeconds: 90}]},
        {name: 'Core', dayOfWeek: 3, exercises: [{exerciseID: timed.id, targetSets: 1, targetDurationSeconds: 45, restSeconds: 30}]},
      ]};
    });
    await t.test('balance protocols use linked-client ownership and preserve other workout preferences',async()=>{
      const [catalog]=await db.query("SELECT id FROM exercises WHERE externalSource='sirvya' ORDER BY id LIMIT 2");
      const [anchor,target]=catalog.map(e=>e.id);
      const protocol={id:'coach_protocol',name:'Coach upper targets',anchorID:anchor,targets:[{exerciseID:target,targetPercent:75}]};
      await request(client,'/workout/preferences','PUT',{unit:'lb',defaultRestSeconds:45});
      const path=`/workout/balance?clientID=${client.id}`;
      assert.equal((await request(null,path)).status,401);
      assert.equal((await request(otherClient,path)).status,403);
      assert.equal((await request(otherCoach,path,'PUT',{})).status,403);
      assert.equal((await request(otherCoach,path)).status,403);
      assert.equal((await request(coach,'/workout/balance?clientID=invalid')).status,400);
      const saved=await request(coach,path,'PUT',{balanceProtocols:[protocol],activeBalanceProtocolID:protocol.id});
      assert.equal(saved.status,200,JSON.stringify(saved.body));assert.equal(saved.body.balanceAnchorID,anchor);
      assert.equal((await request(client,'/workout/balance')).body.activeBalanceProtocolID,protocol.id);
      assert.equal((await request(client,'/workout/preferences')).body.unit,'lb');
      assert.equal((await request(client,'/workout/preferences')).body.defaultRestSeconds,45);
      assert.equal((await request(coach,'/workout/preferences')).body.balanceProtocols.length,0);
      assert.equal((await request(coach,path,'PUT',{unit:'kg'})).status,400);
      const custom=await request(otherClient,'/workout/exercises','POST',{name:'Private balance reference',muscleGroup:'back',equipment:'barbell',isBodyweight:false,instructions:['Fixture']});
      assert.equal(custom.status,201);
      assert.equal((await request(client,'/workout/balance','PUT',{balanceAnchorID:custom.body.id,activeBalanceProtocolID:null})).status,404);
      assert.equal((await request(client,'/workout/preferences','PUT',{balanceAnchorID:custom.body.id})).status,404);
      assert.equal((await request(coach,path,'PUT',{balanceAnchorID:999999999,activeBalanceProtocolID:null})).status,404);
      assert.equal((await request(client,'/workout/balance')).body.activeBalanceProtocolID,protocol.id,'failed writes roll back');
      const edited=await request(client,'/workout/balance','PUT',{balanceTargets:[{exerciseID:target,targetPercent:80}],activeBalanceProtocolID:null});
      assert.equal(edited.status,200);assert.equal(edited.body.balanceProtocols.length,1);assert.equal(edited.body.balanceTargets[0].targetPercent,80);
      await request(client,'/workout/balance','PUT',{balanceProtocols:[]});
      await request(client,'/workout/preferences','PUT',{});
    });
    await t.test('only an authorized coach can create and assign a client plan', async () => {
      assert.equal((await request(client, '/workout/plans', 'POST', {...body,clientID:otherClient.id})).status, 403);
      assert.equal((await request(otherCoach, '/workout/plans', 'POST', body)).status, 403);
      assert.equal((await request(coach, '/workout/plans', 'POST', {...body, clientID: otherClient.id})).status, 403);
      const created = await request(coach, '/workout/plans', 'POST', body); assert.equal(created.status, 201); planID = created.body.id;
      assert.equal(notifications.length, 1); assert.equal(notifications[0].recipientUserID, client.id);
      assert.equal((await request(otherClient, '/workout/plans/' + planID)).status, 404);
      assert.equal((await request(otherCoach, '/workout/plans/' + planID)).status, 404);
      assert.equal((await request(client, '/workout/plans')).body.data[0].id, planID);
      const detail = (await request(client, '/workout/plans/' + planID)).body;
      assert.equal((await request(client, '/workout/plans/'+planID,'PUT',{...body,revision:1})).status,403);
      originalExerciseID = detail.days[0].exercises[0].id; secondDayID = detail.days[1].id;
      const started = await request(client, '/workout/sessions', 'POST', {workoutDayID: detail.days[0].id});
      assert.equal(started.status, 201); sessionID = started.body.id;
      assert.equal((await request(client, '/workout/sessions', 'POST', {workoutDayID: detail.days[0].id})).body.id, sessionID);
      assert.equal((await request(client, '/workout/sessions', 'POST', {workoutDayID: secondDayID})).status, 409);
    });
    await t.test('ownership attacks, invalid sets and duplicate submissions', async () => {
      const set = {workoutExerciseID: originalExerciseID, setNumber: 1, weight: 60, reps: 10, rpe: 8};
      assert.equal((await request(otherClient, '/workout/sessions/' + sessionID)).status, 404);
      assert.equal((await request(otherClient, `/workout/sessions/${sessionID}/sets`, 'PUT', set)).status, 404);
      assert.equal((await request(coach, `/workout/sessions/${sessionID}/sets`, 'PUT', set)).status, 403);
      assert.equal((await request(client, `/workout/sessions/${sessionID}/sets`, 'PUT', {...set, workoutExerciseID: 999999999})).status, 400);
      assert.equal((await request(client, `/workout/sessions/${sessionID}/sets`, 'PUT', {...set, setNumber: 3})).status, 400);
      const replies = await Promise.all([request(client, `/workout/sessions/${sessionID}/sets`, 'PUT', set), request(client, `/workout/sessions/${sessionID}/sets`, 'PUT', set)]);
      assert.deepEqual(replies.map(r => r.status), [200, 200]);
      assert.equal((await request(client, '/workout/sessions/' + sessionID)).body.sets.length, 1);
      assert.equal((await request(client, '/workout/sessions/' + sessionID, 'PUT', {status: 'completed'})).status, 409);
      assert.equal((await request(client, `/workout/sessions/${sessionID}/sets`, 'PUT', {...set, setNumber: 2, reps: 9, rir: 2, rpe: null})).status, 200);
    });
    await t.test('editing a plan preserves the session snapshot and prevents stale edits', async () => {
      const changed = structuredClone(body); changed.name = 'Edited plan'; changed.days[0].exercises[0].targetReps = 12;
      assert.equal((await request(coach, '/workout/plans/' + planID, 'PUT', {...changed, revision: 1})).status, 200);
      assert.equal((await request(coach, '/workout/plans/' + planID, 'PUT', {...changed, revision: 1})).status, 409);
      const snapshot = (await request(client, '/workout/sessions/' + sessionID)).body;
      assert.equal(snapshot.prescription.planName, 'Integration plan'); assert.equal(snapshot.prescription.exercises[0].targetReps, 10);
      assert.equal(snapshot.sets.length, 2);
      const done = await request(client, '/workout/sessions/' + sessionID, 'PUT', {status: 'completed', notes: 'Fixture complete'});
      assert.equal(done.status, 200); assert.equal(done.body.volume, 1140); assert.equal(done.body.newPRs, 1);
      assert.equal((await request(client, `/workout/sessions/${sessionID}/sets`, 'PUT', {workoutExerciseID: originalExerciseID, setNumber: 1, weight: 65, reps: 10})).status, 409);
      assert.equal((await request(client, '/workout/sessions/' + sessionID, 'PUT', {status: 'completed'})).body.volume, 1140);
    });
    await t.test('history, progress, previous performance and timed sets', async () => {
      assert.equal((await request(otherCoach, `/workout/stats?clientID=${client.id}`)).status, 403);
      assert.equal((await request(otherClient, `/workout/history?clientID=${client.id}`)).status, 403);
      const stats = (await request(client, '/workout/stats')).body;
      assert.equal(stats.workoutCount, 1); assert.equal(stats.volume, 1140); assert.equal(stats.records[0].estimated1RM, 80);
      assert.equal((await request(coach, `/workout/history?clientID=${client.id}`)).body.data[0].id, sessionID);
      const detail = (await request(client, '/workout/plans/' + planID)).body;
      const next = await request(client, '/workout/sessions', 'POST', {workoutDayID: detail.days[0].id});
      const current = (await request(client, '/workout/sessions/' + next.body.id)).body;
      assert.equal(current.previous[detail.days[0].exercises[0].exerciseID].length, 2);
      assert.equal((await request(client, '/workout/sessions/' + next.body.id, 'PUT', {status: 'cancelled'})).status, 200);
      const timed = await request(client, '/workout/sessions', 'POST', {workoutDayID: detail.days[1].id});
      assert.equal((await request(client, `/workout/sessions/${timed.body.id}/sets`, 'PUT', {workoutExerciseID: detail.days[1].exercises[0].id, setNumber: 1, durationSeconds: 50})).status, 200);
      assert.equal((await request(client, '/workout/sessions/' + timed.body.id, 'PUT', {status: 'completed'})).body.volume, 0);
      assert.equal((await request(client, '/workout/stats')).body.workoutCount, 2);
      assert.equal((await request(coach, '/workout/plans/' + planID, 'DELETE')).status, 200);
      assert.equal((await request(client, '/workout/plans')).body.data.length, 0);
      assert.equal((await request(client, '/workout/history')).body.data.length, 2);
    });
    await t.test('unlinking denies coach access but retains client-owned history', async () => {
      await db.query('DELETE FROM coachclients WHERE coachID = ? AND clientID = ?', [coach.id, client.id]);
      assert.equal((await request(coach, '/workout/sessions/' + sessionID)).status, 403);
      assert.equal((await request(client, '/workout/sessions/' + sessionID)).status, 200);
      assert.equal((await request(client, '/workout/history')).body.data.length, 2);
    });
    await t.test('conversation endpoint behavior matches its baseline after workout operations', async () => {
      assert.deepEqual(await request(client, `/conversations?userID=${client.id}&role=client`), conversationBaseline);
    });
    await t.test('personal routines, preferences, favorite/custom exercises and scheduling stay account scoped', async()=>{
      const personal={name:'Personal',status:'assigned',days:body.days.slice(0,1)};
      const created=await request(otherClient,'/workout/plans','POST',personal);assert.equal(created.status,201,JSON.stringify(created.body));
      const detail=(await request(otherClient,`/workout/plans/${created.body.id}`)).body;assert.equal(detail.coachID,null);
      assert.equal((await request(client,`/workout/plans/${created.body.id}`)).status,404);
      assert.equal((await request(coach,`/workout/plans/${created.body.id}`)).status,404);
      assert.equal((await request(otherClient,`/workout/plans/${created.body.id}/duplicate`,'POST',{})).status,201);
      const prefs=await request(otherClient,'/workout/preferences');assert.equal(prefs.body.unit,'kg');
      assert.equal((await request(otherClient,'/workout/preferences','PUT',{...prefs.body,unit:'lb',defaultRestSeconds:45,reminderEnabled:true,timeZone:'Africa/Casablanca'})).status,200);
      assert.equal((await request(client,'/workout/preferences')).body.unit,'kg');
      assert.equal((await request(otherClient,'/workout/preferences','PUT',{reminderTime:'25:70'})).status,400);
      const custom=await request(otherClient,'/workout/exercises','POST',{name:'Fixture custom hold',muscleGroup:'core',equipment:'body weight',exerciseType:'timed',isBodyweight:true,instructions:['Hold comfortably.']});assert.equal(custom.status,201);
      assert.equal((await request(client,`/workout/exercises/${custom.body.id}`)).status,404);
      assert.equal((await request(otherClient,`/workout/exercises/${custom.body.id}/preferences`,'PUT',{favorite:true,notes:'Personal note'})).status,200);
      assert.equal((await request(otherClient,'/workout/exercises?favorite=true')).body.data[0].id,custom.body.id);
      assert.equal((await request(client,'/workout/exercises?favorite=true')).body.data.length,0);
      assert.equal((await request(otherClient,'/workout/schedule','PUT',{date:'2026-10-05',dayIDs:[detail.days[0].id]})).status,200);
      assert.equal((await request(client,'/workout/schedule','PUT',{date:'2026-10-05',dayIDs:[detail.days[0].id]})).status,404);
    });
    await t.test('custom deletion removes personal routine entries, blocks active use and keeps actual history',async()=>{
      const input={name:'Lifecycle custom press',muscleGroup:'chest',equipment:'dumbbell',exerciseType:'reps',isBodyweight:false,instructions:['Press steadily.'],secondaryMuscles:['triceps'],description:'Independent instructions'};
      const created=await request(client,'/workout/exercises','POST',input);assert.equal(created.status,201);
      const id=created.body.id,path=`/workout/exercises/${id}`;
      await db.query('INSERT INTO coachclients(coachID,clientID) VALUES (?,?)',[coach.id,client.id]);
      assert.equal((await request(coach,path)).status,200);
      assert.equal((await request(coach,path,'PUT',input)).status,404);
      await db.query('DELETE FROM coachclients WHERE coachID=? AND clientID=?',[coach.id,client.id]);
      assert.equal((await request(otherClient,path,'DELETE')).status,404);
      assert.equal((await request(client,path,'PUT',{...input,name:'Renamed custom press'})).status,200);
      const createdPlan=await request(client,'/workout/plans','POST',{name:'Lifecycle routine',status:'assigned',days:[{name:'Custom day',exercises:[{exerciseID:id,targetSets:1,targetReps:10,targetWeight:20}]}]});
      assert.equal(createdPlan.status,201);
      const plan=(await request(client,`/workout/plans/${createdPlan.body.id}`)).body;
      assert.equal((await request(client,path,'PUT',{...input,exerciseType:'timed'})).status,409);
      const started=await request(client,'/workout/sessions','POST',{workoutDayID:plan.days[0].id});assert.equal(started.status,201);
      const sid=started.body.id;
      assert.equal((await request(client,path,'DELETE')).status,409,'active prescription cannot be orphaned');
      assert.equal((await request(client,`/workout/sessions/${sid}/sets`,'PUT',{workoutExerciseID:plan.days[0].exercises[0].id,setNumber:1,reps:10,weight:20})).status,200);
      assert.equal((await request(client,`/workout/sessions/${sid}`,'PUT',{status:'completed'})).status,200);
      assert.equal((await request(client,path,'DELETE')).status,200);
      assert.equal((await request(client,path+'?language=fr')).body.ownerID,client.id);
      assert.equal((await request(client,'/workout/exercises?search=Renamed%20custom%20press')).body.data.length,0);
      assert.equal((await request(client,path+'/history')).body.data.length,1);
      assert.equal((await request(client,`/workout/sessions/${sid}`)).body.summary.volume,200);
      const afterRemoval=(await request(client,`/workout/plans/${plan.id}`)).body;
      assert.equal(afterRemoval.days[0].exercises.length,0);
      assert.equal(afterRemoval.revision,plan.revision+1);
      assert.equal((await request(client,`/workout/sessions/${sid}`)).body.prescription.exercises[0].exerciseID,id);
      const builtIn=(await request(client,'/workout/exercises?search=bench')).body.data.find(e=>!e.ownerID);
      assert.equal((await request(client,`/workout/exercises/${builtIn.id}`,'DELETE')).status,404);
    });
    await t.test('repeated exercises progress independently by stable routine slot',async()=>{
      const e=(await request(otherClient,'/workout/exercises?search=bench')).body.data.find(e=>e.externalSource==='sirvya');
      const created=await request(otherClient,'/workout/plans','POST',{name:'Repeated exercise fixture',status:'assigned',days:[{name:'Two exposures',configuration:{progression:'linear'},exercises:[40,80].map(targetWeight=>({exerciseID:e.id,targetSets:2,targetReps:10,targetWeight,configuration:{progression:'inherit',increment:2.5}}))}]});
      const plan=(await request(otherClient,`/workout/plans/${created.body.id}`)).body,day=plan.days[0];
      const started=await request(otherClient,'/workout/sessions','POST',{workoutDayID:day.id});assert.equal(started.status,201);
      for(const [index,slot] of day.exercises.entries())for(let setNumber=1;setNumber<=2;setNumber++) {
        assert.equal((await request(otherClient,`/workout/sessions/${started.body.id}/sets`,'PUT',{workoutExerciseID:slot.id,setNumber,weight:slot.targetWeight,reps:index===0?8:10})).status,200);
      }
      assert.equal((await request(otherClient,`/workout/sessions/${started.body.id}`,'PUT',{status:'completed'})).status,200);
      const prior=(await request(otherClient,`/workout/sessions/${started.body.id}`)).body;
      assert.equal(prior.prescription.exercises[1].id,day.exercises[1].id);
      const {nextTarget}=await import('../services/workoutExperience.js');
      const slotHistory={target:prior.prescription.exercises[1],sets:prior.sets.filter(s=>Number(s.workoutExerciseID)===Number(day.exercises[1].id))};
      assert.equal(nextTarget({...day.exercises[1],configuration:prior.prescription.exercises[1].configuration},[slotHistory]).weight,82.5,JSON.stringify(slotHistory));
      const next=await request(otherClient,'/workout/sessions','POST',{workoutDayID:day.id});assert.equal(next.status,201);
      const actual=(await request(otherClient,`/workout/sessions/${next.body.id}`)).body.prescription.exercises;
      assert.equal(Number(actual[0].targetWeight),40);assert.equal(Number(actual[1].targetWeight),82.5,JSON.stringify({target:actual[1].recommendation,startedAt:prior.startedAt}));
      assert.equal(actual[1].configuration.progression,'linear');
      assert.equal(day.exercises[1].configuration.progression,'inherit');
      await request(otherClient,`/workout/sessions/${next.body.id}`,'PUT',{status:'cancelled'});
      await request(otherClient,`/workout/plans/${plan.id}`,'DELETE');
    });
    await t.test('active exercise changes, undo, rich set metrics and history correction preserve the prescription',async()=>{
      const plans=(await request(otherClient,'/workout/plans')).body.data;
      const plan=plans.find(p=>p.status==='assigned'),day=plan.days[0];
      const started=await request(otherClient,'/workout/sessions','POST',{workoutDayID:day.id});const sid=started.body.id;
      const path=`/workout/sessions/${sid}`;const original=(await request(otherClient,path)).body;
      const change={revision:original.revision,exercises:day.exercises.map(e=>({...e,targetSets:3})),notes:'Training note'};
      assert.equal((await request(otherClient,path+'/execution','PUT',change)).status,200);
      assert.equal((await request(otherClient,path+'/execution','PUT',change)).status,409);
      const modified=(await request(otherClient,path)).body;assert.equal(modified.originalPrescription.exercises[0].targetSets,2);assert.equal(modified.prescription.exercises[0].targetSets,3);
      const e=modified.prescription.exercises[0];const set={workoutExerciseID:e.id,setNumber:1,reps:10,weight:60,details:{type:'dropset',segments:[{reps:5,weight:40}]}};
      assert.equal((await request(otherClient,path+'/sets','PUT',set)).status,200);
      assert.equal((await request(otherClient,path)).body.summary.volume,800);
      assert.equal((await request(otherClient,`${path}/sets/${e.id}/1`,'DELETE')).status,200);
      assert.equal((await request(otherClient,path)).body.sets.length,0);
      await request(otherClient,path+'/sets','PUT',set);
      assert.equal((await request(otherClient,path+'/rest-alert','PUT',{seconds:60})).status,200);
      assert.equal((await request(client,path+'/rest-alert','PUT',{seconds:60})).status,404);
      const completed=await request(otherClient,path,'PUT',{status:'completed',allowIncomplete:true});assert.equal(completed.status,200);
      const finished=(await request(otherClient,path)).body;
      for(const row of [null,[],5]){
        assert.equal((await request(otherClient,path+'/history','PUT',{revision:finished.revision,sets:[row]})).status,400);
        assert.equal((await request(otherClient,path)).body.sets.length,1,'invalid edits roll back all set changes');
      }
      const correction={revision:finished.revision,startedAt:'2026-09-30T10:00:00Z',durationSeconds:1800,notes:'Corrected',sets:[{...set,weight:55,details:{phase:'work',type:'straight'}}]};
      assert.equal((await request(otherClient,path+'/history','PUT',correction)).status,200);
      assert.equal((await request(otherClient,path+'/history','PUT',correction)).status,409);
      assert.equal((await request(otherClient,path)).body.summary.volume,550);
      assert.equal((await request(client,path,'DELETE')).status,404);
      assert.equal((await request(otherClient,path,'DELETE')).status,200);
    });
    await t.test('portable plans, rest-day overrides, combined routines and freestyle are native and isolated',async()=>{
      const plan=(await request(otherClient,'/workout/plans')).body.data.find(p=>p.status==='assigned');
      const exported=await request(otherClient,`/workout/plans/${plan.id}/export`);assert.equal(exported.status,200);
      assert.equal(exported.body.format,'sirvya-workout-plan');assert.equal(exported.body.clientID,undefined);
      const imported=await request(otherClient,'/workout/plans/import','POST',{plan:exported.body});assert.equal(imported.status,201);
      const copy=(await request(otherClient,`/workout/plans/${imported.body.id}`)).body;
      assert.equal(copy.days[0].exercises[0].exerciseID,plan.days[0].exercises[0].exerciseID);
      const invalid=structuredClone(exported.body);invalid.days[0].exercises[0].targetSets=0;
      const [[before]]=await db.query('SELECT COUNT(*) AS n FROM exercises WHERE ownerID=?',[otherClient.id]);
      assert.equal((await request(otherClient,'/workout/plans/import','POST',{plan:invalid})).status,400);
      const [[after]]=await db.query('SELECT COUNT(*) AS n FROM exercises WHERE ownerID=?',[otherClient.id]);assert.equal(before.n,after.n);
      await request(otherClient,'/workout/schedule','PUT',{date:'2026-10-06',dayIDs:[]});
      const schedule=(await request(otherClient,'/workout/schedule')).body;
      assert.ok(schedule.overrideDates.some(d=>d.startsWith('2026-10-06')));
      assert.ok(!schedule.data.some(d=>d.workoutDate.startsWith('2026-10-06')));
      assert.equal((await request(otherClient,'/workout/schedule','PUT',{date:'2026-02-31',dayIDs:[]})).status,400);
      const combined=await request(otherClient,'/workout/sessions','POST',{workoutDayIDs:plan.days.map(d=>d.id)});assert.equal(combined.status,201);
      const combinedSession=(await request(otherClient,`/workout/sessions/${combined.body.id}`)).body;
      assert.equal(combinedSession.prescription.exercises.length,plan.days.reduce((n,d)=>n+d.exercises.length,0));
      assert.equal((await request(client,`/workout/sessions/${combined.body.id}`)).status,404);
      await request(otherClient,`/workout/sessions/${combined.body.id}`,'PUT',{status:'cancelled'});
      const free=await request(otherClient,'/workout/sessions','POST',{freestyle:true});assert.equal(free.status,201);
      const active=(await request(otherClient,`/workout/sessions/${free.body.id}`)).body;assert.equal(active.prescription.exercises.length,0);
      const inserted=await request(otherClient,`/workout/sessions/${free.body.id}/execution`,'PUT',{revision:active.revision,exercises:[{...plan.days[0].exercises[0],id:undefined}]});assert.equal(inserted.status,200);
      await request(otherClient,`/workout/sessions/${free.body.id}`,'PUT',{status:'cancelled'});
    });
    await t.test('private demonstrations validate files, scope download tickets and cannot authenticate other APIs',async()=>{
      const e=(await request(otherClient,'/workout/exercises?favorite=true')).body.data[0];
      const {default:sharp}=await import('sharp');
      const png=await sharp({create:{width:12,height:12,channels:3,background:{r:30,g:90,b:50}}}).png().toBuffer();
      const upload=async(user,bytes,name,type)=>{
        const form=new FormData();form.set('file',new Blob([bytes],{type}),name);
        const response=await fetch(origin+`/workout/exercises/${e.id}/media`,{method:'POST',headers:{Authorization:`Bearer ${jwt.sign(user,process.env.JWT_SECRET,{expiresIn:'5m'})}`},body:form});
        return {status:response.status,body:await response.json()};
      };
      assert.equal((await upload(client,png,'image.png','image/png')).status,404);
      assert.equal((await upload(otherClient,Buffer.from('<svg onload="alert(1)"/>'),'image.svg','image/svg+xml')).status,400);
      const saved=await upload(otherClient,png,'image.png','image/png');assert.equal(saved.status,201);
      const mid=saved.body.id;
      try{
        assert.equal((await request(client,`/workout/media/${mid}/ticket`)).status,404);
        const ticket=(await request(otherClient,`/workout/media/${mid}/ticket`)).body.ticket;
        const content=await fetch(origin+`/workout/media/${mid}/content?ticket=${encodeURIComponent(ticket)}`);
        assert.equal(content.status,200);assert.equal(content.headers.get('content-type'),'image/webp');assert.ok((await content.arrayBuffer()).byteLength>0);
        assert.equal((await fetch(origin+'/workout/exercises',{headers:{Authorization:`Bearer ${ticket}`}})).status,401);
        assert.equal((await fetch(origin+`/workout/media/${mid}/content`)).status,401);
        assert.equal((await fetch(origin+`/workout/media/${mid+1}/content?ticket=${encodeURIComponent(ticket)}`)).status,404);
        assert.equal((await request(client,`/workout/media/${mid}`,'DELETE')).status,404);
      }finally{await request(otherClient,`/workout/media/${mid}`,'DELETE');}
      assert.equal((await request(otherClient,`/workout/media/${mid}/ticket`)).status,404);
    });
    await t.test('routine editing keeps slot IDs, date overrides and historical chronology',async()=>{
      const p=(await request(otherClient,'/workout/plans')).body.data.find(p=>p.status==='assigned');
      await request(otherClient,'/workout/schedule','PUT',{date:'2024-01-05',dayIDs:[p.days[0].id]});
      const edited=structuredClone(p);edited.days[0].exercises[0].notes='Updated note';
      assert.equal((await request(otherClient,`/workout/plans/${p.id}`,'PUT',edited)).status,200);
      const after=(await request(otherClient,`/workout/plans/${p.id}`)).body;
      assert.equal(after.days[0].id,p.days[0].id);
      assert.equal(after.days[0].exercises[0].id,p.days[0].exercises[0].id);
      assert.ok((await request(otherClient,'/workout/schedule')).body.data.some(d=>d.workoutDayID===p.days[0].id));
      const start=await request(otherClient,'/workout/sessions','POST',{workoutDayID:p.days[0].id,startedAt:'2024-01-05T12:00:00Z'});
      assert.equal(start.status,201);
      const active=(await request(otherClient,`/workout/sessions/${start.body.id}`)).body;
      assert.equal(active.prescription.historical,true);
      assert.equal((active.previous[p.days[0].exercises[0].exerciseID]??[]).length,0);
      const e=active.prescription.exercises[0];
      assert.equal((await request(otherClient,`/workout/sessions/${start.body.id}/sets`,'PUT',{workoutExerciseID:e.id,setNumber:1,reps:10,weight:20})).status,200);
      const done=await request(otherClient,`/workout/sessions/${start.body.id}`,'PUT',{status:'completed',allowIncomplete:true,durationSeconds:3600});
      assert.equal(done.status,200);assert.equal(done.body.durationSeconds,3600);
      assert.equal(new Date(done.body.completedAt).toISOString(),'2024-01-05T13:00:00.000Z');
      assert.equal((await request(otherClient,'/workout/sessions','POST',{freestyle:true,startedAt:'3024-01-01'})).status,400);
    });
    await t.test('history transfer maps stable exercises, rejects foreign IDs, deduplicates and rolls back',async()=>{
      const exercise=(await request(otherClient,'/workout/exercises?search=bench&equipment=barbell')).body.data.find(e=>e.externalSource==='sirvya');
      const preview=await request(otherClient,'/workout/history/import-preview','POST',{csv:'Date,Exercise,Weight,Reps\n2024-01-01,Bench Press,60,10'});assert.equal(preview.status,200);
      const input={...preview.body,mappings:{'Bench Press':exercise.id},createUnmatched:false};
      assert.equal((await request(otherClient,'/workout/history/import-preview','POST',{history:{format:'sirvya-workout-history',version:1,sessions:[null]}})).status,400);
      assert.equal((await request(otherClient,'/workout/history/import','POST',{...input,sessions:[{...input.sessions[0],exercises:[{...input.sessions[0].exercises[0],sets:[null]}]}]})).status,400);
      assert.equal((await request(otherClient,'/workout/history/import','POST',{format:'sirvya-workout-history',version:1,sessions:[],bodyweight:[null]})).status,400);
      assert.equal((await request(coach,'/workout/history/import','POST',input)).status,403);
      const first=await request(otherClient,'/workout/history/import','POST',input);assert.equal(first.status,201,JSON.stringify(first.body));assert.equal(first.body.imported,1);
      assert.equal((await request(otherClient,'/workout/history/import','POST',input)).body.skipped,1);
      const custom=(await request(client,'/workout/exercises','POST',{name:'Private import target',muscleGroup:'other',equipment:'other',exerciseType:'reps',isBodyweight:false,instructions:[]})).body;
      const foreign={...input,sessions:[{...input.sessions[0],startedAt:'2024-01-02T00:00:00Z'}],mappings:{'Bench Press':custom.id}};
      assert.equal((await request(otherClient,'/workout/history/import','POST',foreign)).status,404);
      const invalid={...input,createUnmatched:true,mappings:{},sessions:[{...input.sessions[0],startedAt:'2024-01-03T00:00:00Z',exercises:[{...input.sessions[0].exercises[0],name:'Created but rolled back',sourceKey:'new-fixture'},{...input.sessions[0].exercises[0],name:'Bad row',sourceKey:'bad-fixture',sets:[{setNumber:1,reps:-3,weight:10}]}]}]};
      const [[before]]=await db.query('SELECT COUNT(*) n FROM exercises WHERE ownerID=?',[otherClient.id]);
      assert.equal((await request(otherClient,'/workout/history/import','POST',invalid)).status,400);
      const [[after]]=await db.query('SELECT COUNT(*) n FROM exercises WHERE ownerID=?',[otherClient.id]);assert.equal(after.n,before.n);
      const exported=await request(otherClient,'/workout/history/export');assert.equal(exported.status,200);assert.equal(exported.body.clientID,undefined);
      assert.ok(exported.body.sessions.some(s=>s.startedAt.startsWith('2024-01-01')));
      assert.equal((await request(client,`/workout/history/export?clientID=${otherClient.id}`)).status,403);
      const weights={format:'sirvya-workout-history',version:1,sessions:[],bodyweight:[{recordedAt:'2024-01-01',weight:80,note:'Fixture'}]};
      const xmlPreview=await request(otherClient,'/workout/history/import-preview','POST',{xml:'<HealthData><Record type="HKQuantityTypeIdentifierBodyMass" unit="kg" value="79" startDate="2024-01-02 10:00:00 +0000"/></HealthData>'});
      assert.equal(xmlPreview.status,200);assert.equal((await request(otherClient,'/workout/history/import','POST',xmlPreview.body)).body.bodyweightImported,1);
      assert.equal((await request(otherClient,'/workout/history/import','POST',xmlPreview.body)).body.bodyweightImported,0);
      assert.equal((await request(otherClient,'/workout/history/import','POST',weights)).body.bodyweightImported,1);
      assert.equal((await request(otherClient,'/workout/history/import','POST',weights)).body.bodyweightImported,0);
      const [[record]]=await db.query('SELECT weight FROM weighthistory WHERE clientID=? AND recordedAt=?',[otherClient.id,'2024-01-01']);assert.equal(Number(record.weight),80);
    });
    await t.test('rest reminders respect UTC deadline, retry persistence failures and deliver once',async()=>{
      const {dispatchWorkoutReminders}=await import('../services/workoutReminders.js');
      await db.query("INSERT INTO workout_alerts(userID,alertKey,dueAt,title,body) VALUES (?,'test-deadline','2024-01-01 12:00:00','Workout test','Rest complete')",[otherClient.id]);
      let delivered=0;
      const options={checkDaily:false,userIDs:[otherClient.id]};
      await dispatchWorkoutReminders(db,async()=>{delivered++;},new Date('2024-01-01T11:59:59Z'),options);assert.equal(delivered,0);
      await dispatchWorkoutReminders(db,async()=>{throw new Error('fixture persistence failure');},new Date('2024-01-01T12:00:00Z'),options);
      await dispatchWorkoutReminders(db,async()=>{delivered++;},new Date('2024-01-01T12:00:01Z'),options);assert.equal(delivered,1);
      await dispatchWorkoutReminders(db,async()=>{delivered++;},new Date('2024-01-01T12:00:02Z'),options);assert.equal(delivered,1);
    });
    await t.test('daily reminders skip completed local days and stale alerts, and respect rest overrides',async()=>{
      const {dispatchWorkoutReminders}=await import('../services/workoutReminders.js');
      const [plan]=await db.query("INSERT INTO workout_plans(clientID,coachID,name,status) VALUES (?,NULL,'Reminder fixture','assigned')",[otherClient.id]);
      const [day]=await db.query("INSERT INTO workout_days(workoutPlanID,name,dayOfWeek) VALUES (?,'Training',4)",[plan.insertId]);
      await request(otherClient,'/workout/preferences','PUT',{reminderEnabled:true,reminderTime:'10:00',timeZone:'Pacific/Kiritimati'});
      let delivered=0;const notify=async()=>{delivered++;},options={userIDs:[otherClient.id]};
      await dispatchWorkoutReminders(db,notify,new Date('2024-05-01T20:00:00Z'),options);
      await dispatchWorkoutReminders(db,notify,new Date('2024-05-01T20:00:30Z'),options);
      assert.equal(delivered,1,'only one reminder for the local day');
      await db.query(`INSERT INTO workout_sessions(workoutPlanID,clientID,prescription,status,startedAt,completedAt)
        VALUES (?,?,'{"exercises":[]}','completed',?,?)`,[plan.insertId,otherClient.id,new Date('2024-05-08T10:30:00Z'),new Date('2024-05-08T11:30:00Z')]);
      await dispatchWorkoutReminders(db,notify,new Date('2024-05-08T20:00:00Z'),options);
      assert.equal(delivered,1,'a workout on the same local day suppresses the reminder');
      await db.query("INSERT INTO workout_alerts(userID,alertKey,dueAt,title,body) VALUES (?,'daily:2024-05-09','2024-05-08 20:00:00','Workout','Fixture')",[otherClient.id]);
      await dispatchWorkoutReminders(db,notify,new Date('2024-05-08T20:00:01Z'),{...options,checkDaily:false});
      assert.equal(delivered,1,'pending reminders are suppressed after training');
      await db.query("INSERT INTO workout_schedule_dates(userID,workoutDate) VALUES (?,'2024-05-16')",[otherClient.id]);
      await dispatchWorkoutReminders(db,notify,new Date('2024-05-15T20:00:00Z'),options);
      assert.equal(delivered,1,'an explicit rest override suppresses the reminder');
      await request(otherClient,'/workout/preferences','PUT',{reminderEnabled:false});
      await db.query("INSERT INTO workout_alerts(userID,alertKey,dueAt,title,body) VALUES (?,'daily:2024-05-23','2024-05-22 20:00:00','Workout','Fixture')",[otherClient.id]);
      await dispatchWorkoutReminders(db,notify,new Date('2024-05-22T20:00:00Z'),{...options,checkDaily:false});
      assert.equal(delivered,1,'opting out cancels pending daily reminders');
    });
    await t.test('product parity: Chosen ranks account usage, adapts equipment, and retains fractional RIR in MySQL',async()=>{
      const marker=`${prefix} chosen`;
      const ids=[];
      for(const [name,equipment] of [['press','barbell'],['row','dumbbell'],['unused','cable']]){
        const made=await request(client,'/workout/exercises','POST',{name:`${marker} ${name}`,bodyPart:'back',muscleGroup:'back',equipment,isBodyweight:false});
        assert.equal(made.status,201);ids.push(made.body.id);
      }
      assert.equal((await request(client,'/workout/exercises','POST',{name:`${marker} PRESS`,bodyPart:'chest'})).status,409);
      assert.equal((await request(otherClient,'/workout/exercises','POST',{name:`${marker} press`,bodyPart:'chest'})).status,201,'unrelated private names do not leak or conflict');
      const own=await request(client,'/workout/plans','POST',{name:marker,clientID:client.id,status:'assigned',days:[{name:marker,exercises:[ids[0],ids[0],ids[1]].map(exerciseID=>({exerciseID,targetSets:1,targetReps:10,targetWeight:60,restSeconds:0}))}]});
      assert.equal(own.status,201,JSON.stringify(own.body));
      const plan=(await request(client,`/workout/plans/${own.body.id}`)).body;
      const start=await request(client,'/workout/sessions','POST',{workoutDayID:plan.days[0].id});
      assert.equal(start.status,201,JSON.stringify(start.body));
      for(const slot of plan.days[0].exercises){
        const saved=await request(client,`/workout/sessions/${start.body.id}/sets`,'PUT',{workoutExerciseID:slot.id,setNumber:1,reps:10,weight:60,rir:1.5});
        assert.equal(saved.status,200,JSON.stringify(saved.body));
      }
      assert.equal((await request(client,`/workout/sessions/${start.body.id}`,'PUT',{status:'completed',durationSeconds:600})).status,200);
      const chosen=await request(client,`/workout/exercises?chosen=true&search=${encodeURIComponent(marker)}`);
      assert.equal(chosen.status,200,JSON.stringify(chosen.body));
      assert.deepEqual(chosen.body.data.map(e=>[e.id,e.usageCount]),[[ids[0],4],[ids[1],2]]);
      assert.deepEqual(chosen.body.filters.equipment.sort(),['barbell','dumbbell']);
      const narrow=await request(client,`/workout/exercises?chosen=true&search=${encodeURIComponent(marker+' row')}&equipment=barbell`);
      assert.equal(narrow.body.effectiveEquipment,null);assert.equal(narrow.body.data[0].id,ids[1]);
      assert.equal((await request(otherClient,`/workout/exercises?chosen=true&search=${encodeURIComponent(marker)}`)).body.total,0);
      assert.equal((await request(coach,`/workout/exercises?chosen=true&search=${encodeURIComponent(marker)}`)).body.total,0);
      const historical=(await request(client,`/workout/sessions/${start.body.id}`)).body;
      assert.ok(historical.sets.every(s=>Number(s.rir)===1.5));
      const [[stored]]=await db.query('SELECT rir FROM workout_sets WHERE workoutSessionID=? LIMIT 1',[start.body.id]);
      assert.equal(Number(stored.rir),1.5);
      await request(client,`/workout/plans/${plan.id}`,'DELETE');
      const after=(await request(client,`/workout/exercises?chosen=true&search=${encodeURIComponent(marker)}`)).body;
      assert.deepEqual(after.data.map(e=>[e.id,e.usageCount]),[[ids[0],2],[ids[1],1]],'completed history remains chosen after routine archive');
    });

    await t.test('product parity: equipment facets use the base results and impossible equipment resets',async()=>{
      const marker=`facet-${prefix}`;
      const custom=[];
      for(const equipment of ['barbell','dumbbell']){
        const result=await request(client,'/workout/exercises','POST',{name:`${marker} ${equipment}`,
          muscleGroup:'back',equipment,isBodyweight:false,instructions:[],description:`${marker} cue-only`});
        assert.equal(result.status,201);custom.push(result.body.id);
      }
      const selected=await request(client,`/workout/exercises?search=${marker}&equipment=barbell`);
      assert.equal(selected.body.data.length,1);
      assert.deepEqual(selected.body.filters.equipment,['barbell','dumbbell']);
      assert.equal(selected.body.effectiveEquipment,'barbell');
      const switched=await request(client,`/workout/exercises?search=${marker}&equipment=dumbbell`);
      assert.equal(switched.body.data[0].equipment,'dumbbell');
      const cleared=await request(client,`/workout/exercises?search=${marker}&equipment=cable`);
      assert.equal(cleared.body.data.length,2);assert.equal(cleared.body.effectiveEquipment,null);
      assert.equal((await request(otherClient,`/workout/exercises?search=${marker}`)).body.total,0);
      const byDescription=await request(client,`/workout/exercises?search=${encodeURIComponent(marker+' cue-only')}`);
      assert.equal(byDescription.body.total,2);
      assert.equal((await request(client,'/workout/exercises/'+custom[0]+'/working-weight','PUT',{weight:65})).status,200);
      assert.equal((await request(otherClient,'/workout/exercises/'+custom[0]+'/working-weight','PUT',{weight:70})).status,404);
      await request(client,'/workout/exercises/'+custom[0]+'/working-weight','PUT',{weight:60});
      const [[pref]]=await db.query('SELECT workingWeight FROM workout_exercise_preferences WHERE userID=? AND exerciseID=?',[client.id,custom[0]]);
      assert.equal(Number(pref.workingWeight),65,'confirmed highest load is retained');
    });
    await t.test('unconfirmed prefill uses recent sets while lifetime records remain separate',async()=>{
      const ex=await request(client,'/workout/exercises','POST',{name:prefix+' prefill',bodyPart:'chest'});
      assert.equal(ex.status,201);
      const created=await request(client,'/workout/plans','POST',{name:'Prefill regression',status:'assigned',days:[{name:'Press',configuration:{progression:'off'},exercises:[{exerciseID:ex.body.id,targetSets:1,targetReps:10,weight:60,configuration:{progression:'off'}}]}]});
      assert.equal(created.status,201);
      const plan=(await request(client,'/workout/plans/'+created.body.id)).body;
      const day=plan.days[0],slot=day.exercises[0];
      for(const weight of [80,40]){
        const start=await request(client,'/workout/sessions','POST',{workoutDayID:day.id});
        assert.equal(start.status,201);
        assert.equal((await request(client,'/workout/sessions/'+start.body.id+'/sets','PUT',{workoutExerciseID:slot.id,setNumber:1,weight,reps:10})).status,200);
        assert.equal((await request(client,'/workout/sessions/'+start.body.id,'PUT',{status:'completed'})).status,200);
      }
      const start=await request(client,'/workout/sessions','POST',{workoutDayID:day.id});
      const current=(await request(client,'/workout/sessions/'+start.body.id)).body;
      assert.equal(current.prescription.exercises[0].workingWeight,null);
      assert.equal(current.prescription.exercises[0].bestWeight,80);
      assert.equal(Number(current.previous[ex.body.id][0].weight),40);
      await request(client,'/workout/sessions/'+start.body.id,'PUT',{status:'cancelled'});
      await request(client,'/workout/exercises/'+ex.body.id+'/working-weight','PUT',{weight:65});
      const confirmed=await request(client,'/workout/sessions','POST',{workoutDayID:day.id});
      const snap=(await request(client,'/workout/sessions/'+confirmed.body.id)).body.prescription.exercises[0];
      assert.equal(snap.workingWeight,65);assert.equal(snap.bestWeight,80);
      await request(client,'/workout/sessions/'+confirmed.body.id,'PUT',{status:'cancelled'});
    });
    await t.test('product parity: weekly assignments and atomic date moves preserve the original program',async()=>{
      const [[exercise]]=await db.query("SELECT id FROM exercises WHERE externalSource='sirvya' AND exerciseType='reps' LIMIT 1");
      const created=await request(client,'/workout/plans','POST',{clientID:client.id,name:'Weekly parity fixture',status:'assigned',days:[
        {name:'Monday push',dayOfWeek:1,exercises:[{exerciseID:exercise.id,targetSets:1,targetReps:10,targetWeight:60}]},
        {name:'Tuesday pull',dayOfWeek:2,exercises:[{exerciseID:exercise.id,targetSets:1,targetReps:8,targetWeight:60}]}]});
      assert.equal(created.status,201,JSON.stringify(created.body));
      const original=(await request(client,'/workout/plans/'+created.body.id)).body;
      const [monday,tuesday]=original.days;
      // Explicit week picks decouple the weekday from the immutable routine.
      assert.equal((await request(client,'/workout/week','PUT',{weekday:1,dayIDs:[monday.id]})).status,200);
      assert.equal((await request(client,'/workout/week','PUT',{weekday:2,dayIDs:[tuesday.id]})).status,200);
      assert.equal((await request(client,'/workout/week','PUT',{weekday:5,dayIDs:[monday.id]})).status,200);
      assert.equal((await request(otherClient,'/workout/week','PUT',{weekday:1,dayIDs:[monday.id]})).status,404);
      assert.equal((await request(coach,'/workout/week','PUT',{weekday:1,dayIDs:[monday.id]})).status,403);
      const before=(await request(client,'/workout/schedule')).body;
      assert.ok(before.week.some(d=>d.id===monday.id&&d.dayOfWeek===5));
      assert.equal((await request(client,'/workout/schedule/move','POST',{fromDate:'2026-10-05',toDate:'2026-10-06'})).status,200);
      const moved=(await request(client,'/workout/schedule')).body;
      assert.deepEqual(moved.week,before.week);
      assert.ok(moved.overrideDates.includes('2026-10-05'));
      assert.ok(!moved.data.some(d=>d.workoutDate==='2026-10-05'));
      assert.deepEqual(moved.data.filter(d=>d.workoutDate==='2026-10-06').map(d=>d.workoutDayID).sort((a,b)=>a-b),[monday.id,tuesday.id].sort((a,b)=>a-b));
      assert.equal((await request(client,'/workout/schedule/move','POST',{fromDate:'2026-10-05',toDate:'2026-10-07'})).status,400);
      assert.deepEqual((await request(client,'/workout/schedule')).body,moved,'an empty source rolls back without a new override');
      assert.equal((await request(client,'/workout/schedule/move','POST',{fromDate:'2026-02-31',toDate:'2026-10-07'})).status,400);
      assert.deepEqual((await request(client,'/workout/plans/'+created.body.id)).body.days,original.days);
      for(const weekday of [1,2,5])await request(client,'/workout/week','PUT',{weekday,dayIDs:[],reset:true});
      for(const date of ['2026-10-05','2026-10-06'])await request(client,'/workout/schedule','PUT',{date,dayIDs:[],reset:true});
      await request(client,'/workout/plans/'+created.body.id,'DELETE');
    });
    await t.test('program import previews, merges fresh IDs, reuses customs and atomically replaces seven weekdays',async()=>{
      const [[catalog]]=await db.query("SELECT * FROM exercises WHERE externalSource='exercises-dataset' AND exerciseType='reps' LIMIT 1");
      const program={opengym_plan:1,name:'Program parity',week:{1:'strength',0:'hold'},customEx:[{id:'carry-test',n:'Parity carry',bp:'upper legs',desc:'Keep tall'}],routines:[
        {id:'strength',name:'Strength',prog:'linear',ex:[{id:catalog.externalId,sets:1,reps:10,weight:60}]},
        {id:'hold',name:'Hold',ex:[{id:'carry-test',mode:'time',sec:45,sets:1}]}]};
      const before=(await request(client,'/workout/schedule')).body.week;
      const preview=await request(client,'/workout/program/import-preview','POST',{program});
      assert.equal(preview.status,200,JSON.stringify(preview.body));assert.equal(preview.body.scheduledDays,2);
      const first=await request(client,'/workout/program/import','POST',{program,replaceWeek:false});
      assert.equal(first.status,201,JSON.stringify(first.body));
      assert.deepEqual((await request(client,'/workout/schedule')).body.week,before);
      const firstPlan=(await request(client,'/workout/plans/'+first.body.id)).body;
      assert.equal(firstPlan.days[0].exercises[0].exerciseID,catalog.id);
      assert.equal(firstPlan.days[1].exercises[0].exerciseType,'timed');
      const second=await request(client,'/workout/program/import','POST',{program,replaceWeek:true});
      assert.equal(second.status,201,JSON.stringify(second.body));assert.notEqual(second.body.id,first.body.id);
      const secondPlan=(await request(client,'/workout/plans/'+second.body.id)).body;
      assert.notEqual(secondPlan.days[0].id,firstPlan.days[0].id);
      assert.equal(secondPlan.days[1].exercises[0].exerciseID,firstPlan.days[1].exercises[0].exerciseID,'matching custom reused');
      const schedule=(await request(client,'/workout/schedule')).body;
      assert.deepEqual(schedule.weekOverrideDays,[1,2,3,4,5,6,7]);
      assert.deepEqual(schedule.week.map(d=>d.dayOfWeek).sort(),[1,7]);
      const native=(await request(client,'/workout/program/export')).body;
      assert.equal(native.format,'sirvya-workout-program');assert.equal(native.clientID,undefined);
      assert.equal((await request(client,'/workout/program/import-preview','POST',{program:native})).status,200);
      const compatible=await request(client,'/workout/program/export?format=opengym');
      assert.equal(compatible.status,200);assert.equal(compatible.body.opengym_plan,1);
      assert.equal(compatible.body.clientID,undefined);
      assert.equal(compatible.body.customEx.filter(e=>e.n==='Parity carry').length,1);
      assert.ok(compatible.body.week[0]);
      const compatiblePreview=await request(client,'/workout/program/import-preview','POST',{program:compatible.body});
      assert.equal(compatiblePreview.status,200,JSON.stringify(compatiblePreview.body));
      assert.equal(compatiblePreview.body.dropped,0);
      assert.equal((await request(otherClient,'/workout/program/export')).body.plan.days.some(d=>d.name==='Strength'),false);
      const invalid=structuredClone(program);invalid.routines[1].ex[0].sec=-1;
      const [[countBefore]]=await db.query('SELECT COUNT(*) n FROM workout_plans WHERE clientID=?',[client.id]);
      assert.equal((await request(client,'/workout/program/import','POST',{program:invalid,replaceWeek:true})).status,400);
      const [[countAfter]]=await db.query('SELECT COUNT(*) n FROM workout_plans WHERE clientID=?',[client.id]);
      assert.equal(countBefore.n,countAfter.n);assert.deepEqual((await request(client,'/workout/schedule')).body,schedule);
      assert.equal((await request(coach,'/workout/program/import','POST',{program})).status,403);
      for(let weekday=1;weekday<=7;weekday++)await request(client,'/workout/week','PUT',{weekday,dayIDs:[],reset:true});
    });
    await t.test('measurement modes, actual cardio speed and routine deletion retain immutable history',async()=>{
      const [[exercise]]=await db.query("SELECT id FROM exercises WHERE externalSource='exercises-dataset' AND exerciseType='reps' LIMIT 1");
      const planResult=await request(client,'/workout/plans','POST',{name:'Mode recovery',status:'assigned',days:[
        {name:'Cardio conversion',exercises:[{exerciseID:exercise.id,targetSets:1,targetDurationSeconds:600,configuration:{mode:'cardio',bodyweight:false,speedKmh:8}}]}]});
      assert.equal(planResult.status,201,JSON.stringify(planResult.body));
      const plan=(await request(client,'/workout/plans/'+planResult.body.id)).body;
      const day=plan.days[0],slot=day.exercises[0];assert.equal(slot.exerciseType,'cardio');
      const start=await request(client,'/workout/sessions','POST',{workoutDayID:day.id});assert.equal(start.status,201,JSON.stringify(start.body));
      assert.equal((await request(client,'/workout/sessions/'+start.body.id+'/sets','PUT',{workoutExerciseID:slot.id,setNumber:1,durationSeconds:600,details:{distanceMeters:1500}})).status,200);
      assert.equal((await request(client,'/workout/sessions/'+start.body.id,'PUT',{status:'completed'})).status,200);
      const stats=(await request(client,'/workout/stats')).body;
      const record=stats.records.find(r=>r.exerciseID===exercise.id);assert.equal(record.points.at(-1).speedKmh,9);
      const stale=await request(client,`/workout/plans/${plan.id}/days/${day.id}?revision=999`,'DELETE');assert.equal(stale.status,409);
      assert.equal((await request(otherClient,`/workout/plans/${plan.id}/days/${day.id}?revision=${plan.revision}`,'DELETE')).status,404);
      await request(client,'/workout/week','PUT',{weekday:6,dayIDs:[day.id]});
      assert.equal((await request(client,`/workout/plans/${plan.id}/days/${day.id}?revision=${plan.revision}`,'DELETE')).status,200);
      assert.ok(!(await request(client,'/workout/schedule')).body.week.some(d=>d.id===day.id));
      const retained=(await request(client,'/workout/sessions/'+start.body.id)).body;
      assert.equal(retained.prescription.exercises[0].exerciseType,'cardio');assert.equal(retained.sets[0].durationSeconds,600);
      const exported=(await request(client,'/workout/history/export')).body;
      const exportedSession=exported.sessions.find(s=>s.name==='Cardio conversion');
      assert.ok(exportedSession);
      const transfer={...exported,sessions:[exportedSession],bodyweight:[]};
      const preview=await request(otherClient,'/workout/history/import-preview','POST',{history:transfer});
      assert.equal(preview.status,200,JSON.stringify(preview.body));
      assert.ok(preview.body.exercises[0].matches.some(e=>e.id===exercise.id),'same catalog identity can be reused with a session mode override');
      const imported=await request(otherClient,'/workout/history/import','POST',transfer);
      assert.equal(imported.status,201,JSON.stringify(imported.body));
      const roundtrip=(await request(otherClient,'/workout/sessions/'+imported.body.ids[0])).body;
      assert.equal(roundtrip.prescription.exercises[0].exerciseID,exercise.id);
      assert.equal(roundtrip.prescription.exercises[0].exerciseType,'cardio');
      assert.equal(roundtrip.sets[0].durationSeconds,600);
      assert.equal(roundtrip.sets[0].details.distanceMeters,1500);
      assert.equal((await request(otherClient,'/workout/history/import','POST',transfer)).body.skipped,1);
      assert.equal((await request(client,'/workout/history')).body.data.some(s=>s.id===start.body.id),true);
      await request(client,'/workout/week','PUT',{weekday:6,dayIDs:[],reset:true});
    });
    await t.test('personal routine autosave permits empty drafts and binds stable IDs without changing the week',async()=>{
      const body={name:'New routine',status:'assigned',days:[{name:'New routine',exercises:[]}]};
      assert.equal((await request(coach,'/workout/plans','POST',{...body,clientID:client.id})).status,400,'Coach assignment still requires exercises');
      const created=await request(client,'/workout/plans','POST',body);
      assert.equal(created.status,201,JSON.stringify(created.body));
      const dayID=created.body.dayIDs[0];assert.ok(dayID);
      assert.equal((await request(client,'/workout/week','PUT',{weekday:4,dayIDs:[dayID]})).status,200);
      const empty=await request(client,'/workout/sessions','POST',{workoutDayID:dayID});
      assert.equal(empty.status,201,JSON.stringify(empty.body));
      assert.equal((await request(client,'/workout/sessions/'+empty.body.id)).body.prescription.exercises.length,0);
      await request(client,'/workout/sessions/'+empty.body.id,'PUT',{status:'cancelled'});
      const [[exercise]]=await db.query("SELECT id FROM exercises WHERE externalSource='sirvya' AND exerciseType='reps' LIMIT 1");
      const updated=await request(client,'/workout/plans/'+created.body.id,'PUT',{...body,name:'Edited routine',revision:1,days:[{id:dayID,name:'Edited routine',exercises:[{exerciseID:exercise.id,targetSets:3,targetReps:10,targetWeight:0}]}]});
      assert.equal(updated.status,200,JSON.stringify(updated.body));assert.deepEqual(updated.body.dayIDs,[dayID]);
      assert.ok(updated.body.exerciseIDs[0]);assert.equal(updated.body.revision,2);
      assert.equal((await request(client,'/workout/schedule')).body.week.find(d=>d.dayOfWeek===4).id,dayID);
      assert.equal((await request(client,'/workout/plans/'+created.body.id,'PUT',{...body,revision:1})).status,409,'stale autosave cannot discard newer edits');
      await request(client,'/workout/week','PUT',{weekday:4,dayIDs:[],reset:true});
    });
    await t.test('one-tap PPL starter reuses dataset IDs and replaces only Monday Wednesday Friday',async()=>{
      const original=await request(otherClient,'/workout/plans','POST',{name:'Preserved Tuesday',status:'assigned',days:[{name:'Tuesday',exercises:[]}]});
      assert.equal(original.status,201);const existing={id:original.body.dayIDs[0]};
      await request(otherClient,'/workout/week','PUT',{weekday:2,dayIDs:[existing.id]});
      const result=await request(otherClient,'/workout/program/starter','POST',{});
      assert.equal(result.status,201,JSON.stringify(result.body));
      const plan=(await request(otherClient,'/workout/plans/'+result.body.id)).body;
      assert.deepEqual(plan.days.map(d=>d.exercises.length),[6,5,6]);
      assert.deepEqual(plan.days.map(d=>d.name),['Push Day','Pull Day','Leg Day']);
      assert.equal(plan.days[0].exercises[0].externalId,'0025');
      const schedule=(await request(otherClient,'/workout/schedule')).body;
      assert.equal(schedule.week.find(d=>d.dayOfWeek===2).id,existing.id,'Tuesday program is preserved');
      for(const [i,weekday] of [1,3,5].entries())assert.equal(schedule.week.find(d=>d.dayOfWeek===weekday).id,plan.days[i].id);
      assert.equal((await request(coach,'/workout/program/starter','POST',{})).status,403);
    });
    await t.test('dated bodyweight uses existing history and keeps Client Coach authorization',async()=>{
      const created=await request(client,'/weight-history','POST',{weight:80,recordedAt:'2026-09-30',note:'Workout check-in'});
      assert.equal(created.status,201,JSON.stringify(created.body));
      const [[row]]=await db.query("SELECT weight,DATE_FORMAT(recordedAt,'%Y-%m-%d') day FROM weighthistory WHERE id=?",[created.body.id]);
      assert.equal(row.day,'2026-09-30');assert.equal(Number(row.weight),80);
      assert.equal((await request(client,'/weight-history','POST',{weight:80,recordedAt:'2026-02-31'})).status,400);
      assert.equal((await request(otherClient,'/weight-history/'+created.body.id,'PUT',{weight:75})).status,404);
      assert.equal((await request(coach,'/weight-history/'+created.body.id,'DELETE')).status,403);
      assert.equal((await request(otherCoach,`/weight-history/me?clientID=${client.id}`)).status,403);
      // An earlier access-regression fixture unlinks the original Coach.
      assert.equal((await request(coach,`/weight-history/me?clientID=${client.id}`)).status,403);
      await db.query('INSERT INTO coachclients(coachID,clientID) VALUES(?,?)',[coach.id,client.id]);
      assert.equal((await request(coach,`/weight-history/me?clientID=${client.id}`)).status,200);
      assert.equal((await request(client,'/weight-history/'+created.body.id,'PUT',{weight:79.5})).status,200);
      assert.equal((await request(client,'/weight-history/'+created.body.id,'DELETE')).status,200);
    });
    await t.test('existing account deletion cascades workout data', async () => {
      await db.query('DELETE FROM users WHERE id = ?', [client.id]);
      assert.equal((await db.query('SELECT id FROM workout_plans WHERE clientID = ?', [client.id]))[0].length, 0);
      assert.equal((await db.query('SELECT id FROM workout_sessions WHERE clientID = ?', [client.id]))[0].length, 0);
      assert.equal((await request(client, '/workout/exercises')).status, 401);
    });
  } finally {
    if (server) await new Promise(resolve => server.close(resolve));
    const [custom]=users.length?await db.query('SELECT id FROM exercises WHERE ownerID IN (?)',[users.map(u=>u.id)]):[[]];
    for (const user of users) await db.query('DELETE FROM users WHERE id = ? AND email LIKE ?', [user.id, `${prefix}%`]);
    if(custom.length)await db.query('DELETE FROM exercises WHERE id IN (?) AND ownerID IS NULL',[custom.map(e=>e.id)]);
    await db.end();
  }
});
