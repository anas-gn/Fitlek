import test from 'node:test';
import assert from 'node:assert/strict';
import {once} from 'node:events';
import express from 'express';
import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
dotenv.config({path:new URL('../.env',import.meta.url),quiet:true});

test('Atomic Workout backup round-trip and rollback', {skip:process.env.WORKOUT_TEST_MYSQL!=='1'},async t=>{
  assert.ok(['localhost','127.0.0.1','::1'].includes(process.env.DB_HOST));
  const {default:db}=await import('../config/db.js');
  const {ensureGoogleAuthSchema}=await import('../config/googleAuthSchema.js');
  const {ensureWorkoutSchema}=await import('../config/workoutSchema.js');
  const {createWorkoutRouter}=await import('../routes/anas/workout.js');
  const prefix=`backup-${Date.now()}-${process.pid}`,users=[];
  let server,backup;
  try{
    await ensureGoogleAuthSchema(db);await ensureWorkoutSchema(db);
    for(const role of ['client','client','client','coach']){
      const [r]=await db.query("INSERT INTO users(firstName,lastName,email,passwordHash,gender,role) VALUES('Backup','Fixture',?,'fixture-no-login','Other',?)",[`${prefix}-${users.length}@example.invalid`,role]);users.push({id:r.insertId,role});
    }
    const [source,target,rollback,coach]=users;
    const app=express();app.use(express.json({limit:'10mb'}));app.use('/workout',createWorkoutRouter(db));server=app.listen(0,'127.0.0.1');await once(server,'listening');
    const call=async(user,path,method='GET',body)=>{
      const response=await fetch(`http://127.0.0.1:${server.address().port}/workout${path}`,{method,headers:{'Content-Type':'application/json',Authorization:`Bearer ${jwt.sign(user,process.env.JWT_SECRET,{expiresIn:'5m'})}`},...(body?{body:JSON.stringify(body)}:{})});return {status:response.status,body:await response.json()};
    };
    const expect=async(user,path,status=200,method='GET',body)=>{const r=await call(user,path,method,body);assert.equal(r.status,status,`${path}: ${JSON.stringify(r.body)}`);return r.body;};
    await t.test('export retains plans, week/rest overrides, custom identity, actual sets and preferences',async()=>{
      const e=await expect(source,'/exercises',201,'POST',{name:`${prefix} press`,bodyPart:'chest',equipment:'barbell',description:'Private instructions',instructions:['Keep steady.'],exerciseType:'reps',isBodyweight:false});
      const plan=await expect(source,'/plans',201,'POST',{name:'Backup plan',status:'assigned',days:[{name:'Push',dayOfWeek:1,configuration:{progression:'double'},exercises:[{exerciseID:e.id,targetSets:1,targetReps:10,targetWeight:60,restSeconds:75,configuration:{progression:'double',minReps:8}}]}]});
      await expect(source,'/preferences',200,'PUT',{unit:'lb',defaultRestSeconds:75,balanceAnchorID:e.id,balanceTargets:[{exerciseID:e.id,targetPercent:100}]});
      await expect(source,`/exercises/${e.id}/preferences`,200,'PUT',{favorite:true,notes:'Personal cue'});
      await expect(source,'/schedule',200,'PUT',{date:'2026-10-01',dayIDs:[]});
      const session=await expect(source,'/sessions',201,'POST',{workoutDayID:plan.dayIDs[0]});
      const full=await expect(source,`/sessions/${session.id}`);
      await expect(source,`/sessions/${session.id}/sets`,200,'PUT',{exerciseID:e.id,workoutExerciseID:full.prescription.exercises[0].id,setNumber:1,reps:10,weight:60,rir:1.5});
      await expect(source,`/sessions/${session.id}`,200,'PUT',{status:'completed',durationSeconds:1800,notes:'Round-trip fixture'});
      await db.query('INSERT INTO weighthistory(clientID,weight,recordedAt,note) VALUES(?,75,?,?)',[source.id,'2026-10-01','Check-in']);
      backup=await expect(source,'/backup/export');
      assert.equal(backup.plans.length,1);assert.equal(backup.history.sessions.length,1);assert.equal(backup.history.sessions[0].exercises[0].sets[0].rir,'1.50');
      assert.equal(backup.preferences.unit,'lb');assert.equal(backup.exercises[0].description,'Private instructions');assert.equal(backup.history.bodyweight.length,1);
      assert.equal(backup.schedule.week.find(v=>v.weekday===1).days.length,1);assert.deepEqual(backup.schedule.dates,[{date:'2026-10-01',days:[]}]);
      assert.equal(JSON.stringify(backup).includes('clientID'),false);assert.equal(JSON.stringify(backup).includes('coachID'),false);
    });
    await t.test('restore remaps private exercise and balance IDs, preserves metrics and does not duplicate on replay',async()=>{
      const summary=await expect(target,'/backup/preview',200,'POST',{backup});assert.equal(summary.workouts,1);
      const restored=await expect(target,'/backup/restore',201,'POST',{backup,restoreSchedule:true,restorePreferences:true});assert.equal(restored.alreadyRestored,false);
      const plans=(await expect(target,'/plans')).data;assert.equal(plans.length,1);const e=plans[0].days[0].exercises[0];assert.notEqual(Number(e.exerciseID),backup.exercises[0].id);
      const p=await expect(target,'/preferences');assert.equal(p.unit,'lb');assert.equal(p.balanceAnchorID,Number(e.exerciseID));
      const stats=await expect(target,'/stats');assert.equal(stats.workoutCount,1);assert.equal(Number(stats.volume),600);
      const history=await expect(target,'/history/export');assert.equal(history.sessions[0].exercises[0].sets[0].rir,'1.50');assert.equal(history.bodyweight.length,1);
      const replay=await expect(target,'/backup/restore',200,'POST',{backup,restoreSchedule:true,restorePreferences:true});assert.equal(replay.alreadyRestored,true);assert.equal((await expect(target,'/plans')).data.length,1);
      const ownBackup=await expect(target,'/backup/export');assert.equal(ownBackup.history.sessions.length,1);assert.equal(ownBackup.exercises[0].description,'Private instructions');
    });
    await t.test('invalid late-batch sets roll back every earlier batch, plan, preference and exercise',async()=>{
      const broken=structuredClone(backup);broken.history.sessions=Array.from({length:101},(_,i)=>({...structuredClone(backup.history.sessions[0]),startedAt:new Date(Date.UTC(2025,0,1,0,i)).toISOString()}));
      broken.history.sessions[100].exercises[0].sets[0].reps=-1;
      assert.equal((await call(rollback,'/backup/restore','POST',{backup:broken,restoreSchedule:true,restorePreferences:true})).status,400);
      for(const [table,column] of [['workout_plans','clientID'],['workout_sessions','clientID'],['exercises','ownerID'],['workout_preferences','userID'],['workout_backup_restores','userID']]){
        const [[n]]=await db.query(`SELECT COUNT(*) AS n FROM ${table} WHERE ${column}=?`,[rollback.id]);assert.equal(n.n,0,table);
      }
    });
    await t.test('restoring on the source account keeps its native history and unchecked schedule',async()=>{
      const before=await expect(source,'/schedule');
      await expect(source,'/backup/restore',201,'POST',{backup,restoreSchedule:false,restorePreferences:false});
      const after=await expect(source,'/schedule');
      assert.deepEqual(after.week,before.week);assert.deepEqual(after.overrides,before.overrides);
      assert.equal((await expect(source,'/stats')).workoutCount,1);
      const [[privateCount]]=await db.query('SELECT COUNT(*) AS n FROM exercises WHERE ownerID=?',[source.id]);assert.equal(privateCount.n,1);
    });
    await t.test('late timer cleanup is idempotent and closed sessions cannot acquire new alerts',async()=>{
      const history=await expect(source,'/history');const id=history.data[0].id;
      await expect(source,`/sessions/${id}/rest-alert`,200,'PUT',{seconds:0});
      await expect(source,`/sessions/${id}/rest-alert`,200,'PUT',{seconds:0});
      await expect(source,`/sessions/${id}/rest-alert`,409,'PUT',{seconds:30});
      const [[count]]=await db.query('SELECT COUNT(*) AS n FROM workout_alerts WHERE sessionID=?',[id]);assert.equal(count.n,0);
    });
    await t.test('whole history files roll back after a late invalid row',async()=>{
      const broken=structuredClone(backup.history);
      broken.sessions=Array.from({length:101},(_,i)=>({...structuredClone(backup.history.sessions[0]),startedAt:new Date(Date.UTC(2025,0,1,0,i)).toISOString()}));
      broken.sessions[100].exercises[0].sets[0].reps=-1;
      await expect(rollback,'/history/import',400,'POST',{...broken,createUnmatched:true});
      for(const [table,column] of [['workout_sessions','clientID'],['workout_plans','clientID'],['exercises','ownerID'],['weighthistory','clientID']]){
        const [[n]]=await db.query(`SELECT COUNT(*) AS n FROM ${table} WHERE ${column}=?`,[rollback.id]);assert.equal(n.n,0,table);
      }
    });
    await t.test('history export pages measurements without truncation or duplication',async()=>{
      const values=Array.from({length:150},(_,i)=>[source.id,70,new Date(Date.UTC(2025,0,i+1)),`Export fixture ${i}`]);
      await db.query('INSERT INTO weighthistory(clientID,weight,recordedAt,note) VALUES ?',[values]);
      const first=await expect(source,'/history/export?limit=1&offset=0&weightOffset=0');assert.equal(first.sessions.length,1);assert.equal(first.bodyweight.length,100);assert.equal(first.hasMore,true);
      const next=await expect(source,'/history/export?limit=1&offset=1&weightOffset=100');assert.equal(next.sessions.length,0);assert.equal(next.bodyweight.length,51);assert.equal(next.hasMore,false);
      assert.equal(new Set([...first.bodyweight,...next.bodyweight].map(v=>v.recordedAt)).size,151);
    });
    await t.test('converted Health pounds deduplicate at the stored measurement precision',async()=>{
      const preview=await expect(target,'/history/import-preview',200,'POST',{xml:'<HealthData><Record type="HKQuantityTypeIdentifierBodyMass" unit="lb" value="170" startDate="2026-10-02 10:00:00 +0000"/></HealthData>'});
      const first=await expect(target,'/history/import',201,'POST',preview);assert.equal(first.bodyweightImported,1);
      const replay=await expect(target,'/history/import',201,'POST',preview);assert.equal(replay.bodyweightImported,0);assert.equal(replay.bodyweightSkipped,1);
      const [rows]=await db.query("SELECT weight FROM weighthistory WHERE clientID=? AND recordedAt='2026-10-02'",[target.id]);assert.equal(rows.length,1);assert.equal(Number(rows[0].weight),77.11);
    });
    await t.test('unknown versions, invalid references, Coach restores and active-session restores fail',async()=>{
      await expect(target,'/backup/preview',400,'POST',{backup:{...backup,version:2}});
      await expect(target,'/backup/preview',400,'POST',{backup:{...backup,history:{...backup.history,unit:'lb'}}});
      const broken=structuredClone(backup);broken.schedule.week[0].days=['missing'];await expect(target,'/backup/preview',400,'POST',{backup:broken});
      await expect(coach,'/backup/restore',403,'POST',{backup});
      const plans=(await expect(target,'/plans')).data;const s=await expect(target,'/sessions',201,'POST',{workoutDayID:plans[0].days[0].id});
      await expect(target,'/backup/restore',409,'POST',{backup});await expect(target,`/sessions/${s.id}`,200,'PUT',{status:'cancelled'});
    });
  }finally{
    if(server)await new Promise(resolve=>server.close(resolve));
    const [rows]=await db.query('SELECT id FROM users WHERE email LIKE ?',[`${prefix}%@example.invalid`]);for(const row of rows)await db.query('DELETE FROM users WHERE id=?',[row.id]);await db.end();
  }
});
