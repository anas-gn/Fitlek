import test from 'node:test';
import assert from 'node:assert/strict';
import {once} from 'node:events';
import express from 'express';
import bcrypt from 'bcrypt';
import dotenv from 'dotenv';
dotenv.config({path:new URL('../.env',import.meta.url),quiet:true});

test('real Push Day twice: Coach assignment, actual sets, progression, history and isolation',
  {skip:process.env.WORKOUT_TEST_MYSQL!=='1'},async t=>{
  assert.ok(['localhost','127.0.0.1','::1'].includes(process.env.DB_HOST));
  assert.match(process.env.DB_NAME,/^sirvya_ci_\d+$/,'Use a disposable audit schema');
  const {default:db}=await import('../config/db.js');
  const {ensureWorkoutSchema}=await import('../config/workoutSchema.js');
  const {ensureGoogleAuthSchema}=await import('../config/googleAuthSchema.js');
  const {createWorkoutRouter}=await import('../routes/anas/workout.js');
  const {default:auth}=await import('../routes/anas/auth.js');
  const {trainingCalendarRange}=await import('../services/workoutStats.js');
  const prefix=`push-day-audit-${Date.now()}-${process.pid}`,accounts=[],notifications=[];
  let server,plan,first,second;
  try{
    await ensureGoogleAuthSchema(db);await ensureWorkoutSchema(db);
    const password='LocalAuditPassword123',hash=await bcrypt.hash(password,10);
    for(const role of ['coach','client','coach','client']){
      const email=`${prefix}-${accounts.length}@example.invalid`;
      const [row]=await db.query("INSERT INTO users(firstName,lastName,email,passwordHash,gender,role) VALUES('Push','Audit',?,?,'Other',?)",[email,hash,role]);
      accounts.push({id:row.insertId,email,role});
    }
    const [coach,client,otherCoach,otherClient]=accounts;
    await db.query('INSERT INTO coachclients(coachID,clientID) VALUES(?,?)',[coach.id,client.id]);
    const app=express();app.use(express.json());app.use('/api/auth',auth);
    app.use('/api/workout',createWorkoutRouter(db,{notify:async notification=>notifications.push(notification)}));
    server=app.listen(0,'127.0.0.1');await once(server,'listening');
    const request=async(user,path,method='GET',body)=>{
      const response=await fetch(`http://127.0.0.1:${server.address().port}/api${path}`,{method,headers:{'Content-Type':'application/json',...(user?.token?{Authorization:`Bearer ${user.token}`}:{})},...(body===undefined?{}:{body:JSON.stringify(body)})});
      return {status:response.status,body:await response.json()};
    };
    const ok=async(user,path,method='GET',body)=>{
      const result=await request(user,path,method,body);assert.ok(result.status>=200&&result.status<300,`${path}: ${result.status} ${JSON.stringify(result.body)}`);return result.body;
    };
    await t.test('real password login and Coach assignment of the four-exercise program',async()=>{
      for(const user of accounts)user.token=(await ok(null,'/auth/login','POST',{email:user.email,password})).accessToken;
      const [seed]=await db.query("SELECT id,externalId FROM exercises WHERE externalSource='sirvya' AND externalId IN ('bench-press','lateral-raise','plank')");
      const [incline]=await db.query("SELECT id FROM exercises WHERE externalSource='exercises-dataset' AND name LIKE '%incline%' AND equipment='dumbbell' AND bodyPart='chest' AND exerciseType='reps' ORDER BY externalId LIMIT 1");
      assert.equal(seed.length,3);assert.equal(incline.length,1);
      const id=name=>seed.find(exercise=>exercise.externalId===name).id;
      const exercises=[
        {exerciseID:id('bench-press'),targetSets:3,targetReps:10,targetWeight:60,restSeconds:90,configuration:{progression:'linear',increment:2.5}},
        {exerciseID:incline[0].id,targetSets:3,targetReps:10,targetWeight:25,restSeconds:90,configuration:{progression:'linear',increment:2.5}},
        {exerciseID:id('lateral-raise'),targetSets:3,targetReps:12,targetWeight:8,restSeconds:60,configuration:{progression:'off'}},
        {exerciseID:id('plank'),targetSets:3,targetDurationSeconds:45,restSeconds:30,configuration:{progression:'time',increment:5}},
      ];
      const created=await ok(coach,'/workout/plans','POST',{clientID:client.id,name:'Audit Push Program',status:'assigned',days:[{name:'PUSH DAY',dayOfWeek:1,exercises}]});
      plan=await ok(client,`/workout/plans/${created.id}`);
      assert.equal(plan.days[0].exercises.length,4);
      assert.ok(notifications.some(notification=>notification.recipientUserID===client.id));
      await ok(client,'/workout/preferences','PUT',{timeZone:'Africa/Casablanca'});
    });
    const perform=async(session,secondPass=false)=>{
      const detail=await ok(client,`/workout/sessions/${session.id}`);
      for(const [index,exercise] of detail.prescription.exercises.entries()){
        for(let number=1;number<=exercise.targetSets;number++){
          const row={workoutExerciseID:exercise.id,setNumber:number,rir:2.5};
          if(exercise.exerciseType==='timed')row.durationSeconds=exercise.targetDurationSeconds;
          else{
            row.weight=index===0&&!secondPass&&number===3?57.5:Number(exercise.targetWeight);
            row.reps=index===0&&!secondPass&&number===2?9:exercise.targetReps;
          }
          await ok(client,`/workout/sessions/${session.id}/sets`,'PUT',row);
          if(number===1)await ok(client,`/workout/sessions/${session.id}/sets`,'PUT',row);
        }
      }
      return ok(client,`/workout/sessions/${session.id}`,'PUT',{status:'completed',durationSeconds:2400,notes:secondPass?'Second Push Day':'First Push Day'});
    };
    await t.test('first complete Push Day preserves targets and 12 actual idempotent sets',async()=>{
      const firstDate=new Date();firstDate.setUTCDate(firstDate.getUTCDate()-10);
      first=await ok(client,'/workout/sessions','POST',{workoutDayID:plan.days[0].id,startedAt:firstDate.toISOString()});
      const completed=await perform(first);
      assert.equal(completed.setCount,12);assert.equal(completed.volume,2753);
      const detail=await ok(coach,`/workout/sessions/${first.id}`);
      assert.equal(Number(detail.originalPrescription.exercises[0].originalTargets.targetWeight),60);
      assert.equal(detail.sets.filter(set=>Number(set.exerciseID)===plan.days[0].exercises[0].exerciseID)[2].weight,'57.50');
      assert.equal(detail.sets.filter(set=>set.durationSeconds!=null).length,3);
      assert.ok(detail.sets.every(set=>Number(set.rir)===2.5));
      assert.equal((await request(otherClient,`/workout/sessions/${first.id}`)).status,404);
      assert.equal((await request(otherCoach,`/workout/sessions/${first.id}`)).status,403);
    });
    await t.test('second workout exposes previous sets and calculates progression from actual completion',async()=>{
      second=await ok(client,'/workout/sessions','POST',{workoutDayID:plan.days[0].id,startedAt:new Date().toISOString()});
      const detail=await ok(client,`/workout/sessions/${second.id}`),[bench,incline,,plank]=detail.prescription.exercises;
      assert.equal(bench.targetWeight,60,'missed reps must not increase the next load');
      assert.equal(incline.targetWeight,27.5);
      assert.equal(plank.targetDurationSeconds,50);
      assert.equal(detail.previous[bench.exerciseID].length,3);
      assert.equal(Number(detail.previous[bench.exerciseID][2].weight),57.5);
      const completed=await perform(second,true);
      assert.equal(completed.setCount,12);
      assert.ok(completed.loadRecords.some(record=>record.exerciseID===incline.exerciseID));
      assert.ok(!completed.loadRecords.some(record=>record.exerciseID===bench.exerciseID));
    });
    await t.test('Client and Coach see the same actual history, period PRs and statistics',async()=>{
      const history=await ok(client,'/workout/history');assert.equal(history.total,2);assert.equal(history.data[0].id,second.id);
      const stats=await ok(client,'/workout/stats');assert.equal(stats.workoutCount,2);assert.equal(stats.setCount,24);
      assert.equal(stats.totalReps,191);assert.equal(stats.totalDurationSeconds,4800);
      assert.equal(stats.volume,5666);assert.equal(stats.records.length,4);
      const weekly=await ok(client,'/workout/stats?window=week');assert.equal(weekly.workoutCount,1);
      const benchID=plan.days[0].exercises[0].exerciseID;
      const benchPR=weekly.personalRecords.find(record=>record.exerciseID===benchID);
      assert.ok(!benchPR?.metrics.includes('weight'),'weekly view must retain earlier maximum load');
      assert.ok(!benchPR?.metrics.includes('estimated1RM'),'equal e1RM must not become a fresh weekly record');
      assert.equal(weekly.adherence.missed.every(day=>day.date>=trainingCalendarRange(new Date(),'Africa/Casablanca').weekStart),true);
      assert.equal((await ok(coach,`/workout/history?clientID=${client.id}`)).total,2);
      assert.equal((await request(otherClient,`/workout/stats?clientID=${client.id}`)).status,403);
      assert.equal((await request(otherCoach,`/workout/stats?clientID=${client.id}`)).status,403);
      const third=await ok(client,'/workout/sessions','POST',{workoutDayID:plan.days[0].id});
      const next=await ok(client,`/workout/sessions/${third.id}`);
      assert.equal(next.prescription.exercises[0].targetWeight,62.5);
      assert.equal((await ok(client,`/workout/plans/${plan.id}`)).days[0].exercises[0].targetWeight,'60.00');
      await ok(client,`/workout/sessions/${third.id}`,'PUT',{status:'cancelled'});
      assert.equal((await ok(client,'/workout/history')).total,2);
    });
  }finally{
    if(server)await new Promise(resolve=>server.close(resolve));
    for(const account of accounts)await db.query('DELETE FROM users WHERE id=?',[account.id]);
    await db.end();
  }
});
