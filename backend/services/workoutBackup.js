import {createHash,randomUUID} from 'node:crypto';
import {requireRole} from '../middleware/auth.js';
import {fail,json,integer,text,validateCustomExercise,validatePlan} from './workoutDomain.js';
import {validatePreferences} from './workoutExperience.js';
import {readPlanDetails,readWeeklyDays} from './workoutQueries.js';
import {portableExercise} from './workoutProgram.js';

const limits={plans:100,days:1000,exercises:3000,sessions:1000,measurements:1000,dateOverrides:1000,bytes:8*1024*1024};
const key=e=>JSON.stringify([e.externalSource,e.externalId]);
const capture=async(handler,req)=>{
  let result;
  const response={status(){return this;},json(value){result=value;return this;}};
  await handler(req,response);
  return result;
};
function validateBackup(input){
  if(!input||input.format!=='sirvya-workout-backup'||input.version!==1)fail('unsupported_backup');
  if(Buffer.byteLength(JSON.stringify(input))>limits.bytes)fail('backup_too_large',413);
  for(const name of ['plans','exercises'])if(!Array.isArray(input[name])||input[name].length>limits[name])fail('invalid_backup');
  if(!input.history||input.history.format!=='sirvya-workout-history'||input.history.version!==1||input.history.unit!=='kg'||!Array.isArray(input.history.sessions)||input.history.sessions.length>limits.sessions||!Array.isArray(input.history.bodyweight)||input.history.bodyweight.length>limits.measurements)fail('invalid_backup');
  if(!Array.isArray(input.schedule?.week)||input.schedule.week.length!==7||!Array.isArray(input.schedule.dates)||input.schedule.dates.length>limits.dateOverrides)fail('invalid_backup');
  if(!Array.isArray(input.exercisePreferences)||input.exercisePreferences.length>limits.exercises)fail('invalid_backup');
  if(!input.preferences||typeof input.preferences!=='object'||Array.isArray(input.preferences)||input.exercisePreferences.some(v=>!v||typeof v!=='object'||Array.isArray(v)))fail('invalid_backup');
  const exercises=new Map(),sourceKeys=new Set(),days=new Set();
  for(const e of input.exercises){
    if(!e||exercises.has(integer(e.id))||sourceKeys.has(key(e)))fail('invalid_backup');
    validateCustomExercise(e);text(e.externalSource,80,true);text(e.externalId,160,true);
    exercises.set(e.id,e);
    sourceKeys.add(key(e));
  }
  const planKeys=new Set();
  for(const p of input.plans){
    if(!p||!['draft','assigned'].includes(p.status)||!Array.isArray(p.days)||p.days.length>100||typeof p.key!=='string'||planKeys.has(p.key))fail('invalid_backup');
    planKeys.add(p.key);
    for(const d of p.days){
      if(!d||typeof d.key!=='string'||days.has(d.key)||!Array.isArray(d.exercises)||d.exercises.length>50)fail('invalid_backup');
      days.add(d.key);
      for(const e of d.exercises)if(!exercises.has(e.exerciseID))fail('invalid_backup');
    }
    validatePlan({...p,clientID:1,days:p.days.map(d=>({...d,exercises:d.exercises.map(e=>({...e,id:undefined}))}))},{allowEmptyRoutine:true});
  }
  if(days.size>limits.days)fail('invalid_backup');
  const weekdays=new Set();
  for(const row of input.schedule.week){
    if(!row||typeof row!=='object')fail('invalid_backup');
    const weekday=integer(row.weekday,1,7);if(weekdays.has(weekday))fail('invalid_backup');weekdays.add(weekday);
    if(!Array.isArray(row.days)||row.days.length>14||row.days.some(k=>!days.has(k)))fail('invalid_backup');
  }
  const dates=new Set();
  for(const row of input.schedule.dates){
    if(!row||typeof row.date!=='string')fail('invalid_backup');
    const date=new Date(`${row.date}T12:00:00Z`);
    if(!/^\d{4}-\d{2}-\d{2}$/.test(row.date)||Number.isNaN(date.getTime())||date.toISOString().slice(0,10)!==row.date||dates.has(row.date)||!Array.isArray(row.days)||row.days.length>14||row.days.some(k=>!days.has(k)))fail('invalid_backup');
    dates.add(row.date);
  }
  const preferences=validatePreferences(input.preferences);
  for(const id of [preferences.balanceAnchorID,...preferences.balanceTargets.map(v=>v.exerciseID),...preferences.balanceProtocols.flatMap(v=>[v.anchorID,...v.targets.map(t=>t.exerciseID)]),...input.exercisePreferences.map(v=>v.exerciseID)].filter(v=>v!=null))if(!exercises.has(id))fail('invalid_backup');
  let sets=0;
  for(const s of input.history.sessions){
    if(!s||!Array.isArray(s.exercises)||!s.exercises.length||s.exercises.length>50)fail('invalid_backup');
    const started=new Date(s.startedAt);
    if(typeof s.startedAt!=='string'||Number.isNaN(started.getTime())||started.getUTCFullYear()<1900||started.getTime()>Date.now()+60000)fail('invalid_import_date');
    for(const e of s.exercises){
      if(!e||!Array.isArray(e.sets)||!e.sets.length||e.sets.length>60||e.sets.some(v=>!v||typeof v!=='object')||!input.exercises.some(v=>v.externalSource===e.externalSource&&v.externalId===e.externalId))fail('invalid_backup');
      sets+=e.sets.length;if(sets>50000)fail('backup_too_large',413);
    }
  }
  return {preferences,exercises,summary:{plans:input.plans.length,routines:days.size,workouts:input.history.sessions.length,measurements:input.history.bodyweight.length,customExercises:input.exercises.filter(e=>e.private===true).length},limits};
}

export function installWorkoutBackup(router,db,{run,transaction,visibleExercise,importPlan,importHistory,exportHistory}){
  router.get('/backup/export',requireRole('client'),run(async(req,res)=>{
    const result=await transaction(async conn=>{
      const id=req.user.id;
      const [rows]=await conn.query(`SELECT p.* FROM workout_plans p WHERE p.clientID=? AND
        (p.coachID IS NULL AND p.status IN ('draft','assigned') OR p.status='assigned' AND EXISTS(SELECT 1 FROM coachclients cc WHERE cc.coachID=p.coachID AND cc.clientID=p.clientID)) ORDER BY p.id LIMIT 101`,[id]);
      if(rows.length>limits.plans)fail('backup_too_large',413);
      const details=await readPlanDetails(conn,rows),dayKeys=new Map(),used=new Set();
      const plans=details.map((p,i)=>({key:`plan-${i}`,name:p.name,description:p.description,status:p.status,days:p.days.map(d=>{
        const dayKey=`day-${dayKeys.size}`;dayKeys.set(Number(d.id),dayKey);
        return {key:dayKey,name:d.name,dayOfWeek:d.dayOfWeek,configuration:d.configuration,exercises:d.exercises.map(e=>{
          used.add(Number(e.exerciseID));
          return {exerciseID:Number(e.exerciseID),targetSets:e.targetSets,targetReps:e.targetReps,targetWeight:e.targetWeight,targetDurationSeconds:e.targetDurationSeconds,restSeconds:e.restSeconds,notes:e.notes,supersetGroup:e.supersetGroup,configuration:e.configuration};
        })};
      })}));
      const preferences=validatePreferences(json((await conn.query('SELECT preferences FROM workout_preferences WHERE userID=?',[id]))[0][0]?.preferences??{}));
      for(const v of [preferences.balanceAnchorID,...preferences.balanceTargets.map(v=>v.exerciseID),...preferences.balanceProtocols.flatMap(v=>[v.anchorID,...v.targets.map(t=>t.exerciseID)])])if(v)used.add(v);
      const [ep]=await conn.query('SELECT exerciseID,favorite,notes,workingWeight FROM workout_exercise_preferences WHERE userID=?',[id]);for(const v of ep)used.add(Number(v.exerciseID));
      const [customs]=await conn.query('SELECT id FROM exercises WHERE ownerID=?',[id]);for(const e of customs)used.add(Number(e.id));
      const [loggedExercises]=await conn.query("SELECT DISTINCT ws.exerciseID FROM workout_sets ws JOIN workout_sessions s ON s.id=ws.workoutSessionID WHERE s.clientID=? AND s.status='completed'",[id]);for(const e of loggedExercises)used.add(Number(e.exerciseID));
      const history={format:'sirvya-workout-history',version:1,source:'SIRVYA',unit:'kg',sessions:[],bodyweight:[]};
      for(let page=1;;page++){
        const data=await capture(exportHistory,{...req,query:{page},backupConnection:conn,skipBodyweight:true});
        history.sessions.push(...data.sessions);if(history.sessions.length>limits.sessions)fail('backup_too_large',413);
        if(!data.hasMore)break;
      }
      const [weights]=await conn.query("SELECT weight,DATE_FORMAT(recordedAt,'%Y-%m-%d') AS recordedAt,note FROM weighthistory WHERE clientID=? ORDER BY recordedAt,id LIMIT 1001",[id]);
      if(weights.length>limits.measurements||used.size>limits.exercises)fail('backup_too_large',413);history.bodyweight=weights;
      const exercises=[];
      for(const eid of used){
        // Completed history may retain an archived or former Coach's private
        // identity; export only the client's recorded snapshot for that case.
        let e;try{e=await visibleExercise(conn,req.user,eid);}catch(error){
          if(error.code!=='exercise_not_found')throw error;
          const [own]=await conn.query(`SELECT s.prescription FROM workout_sessions s JOIN workout_sets ws ON ws.workoutSessionID=s.id WHERE s.clientID=? AND ws.exerciseID=? LIMIT 1`,[id,eid]);
          const snapshot=own[0]&&json(own[0].prescription).exercises.find(v=>Number(v.exerciseID)===eid);
          if(!snapshot)fail('invalid_backup');
          e={...snapshot,externalSource:snapshot.externalSource??'snapshot',externalId:snapshot.externalId??String(eid),ownerID:-1};
        }
        exercises.push({...portableExercise(e),secondaryMuscles:json(e.secondaryMuscles??[]),id:eid,private:e.ownerID!=null,archived:Boolean(e.archivedAt)});
      }
      const weekly=await readWeeklyDays(conn,id);
      const [dateRows]=await conn.query("SELECT DATE_FORMAT(workoutDate,'%Y-%m-%d') AS date FROM workout_schedule_dates WHERE userID=? ORDER BY workoutDate LIMIT 1001",[id]);
      if(dateRows.length>limits.dateOverrides)fail('backup_too_large',413);
      const [assigned]=await conn.query("SELECT DATE_FORMAT(workoutDate,'%Y-%m-%d') AS date,workoutDayID FROM workout_schedule WHERE userID=?",[id]);
      const schedule={week:Array.from({length:7},(_,i)=>({weekday:i+1,days:weekly.filter(d=>Number(d.dayOfWeek)===i+1).map(d=>dayKeys.get(Number(d.id))).filter(Boolean)})),dates:dateRows.map(d=>({date:d.date,days:assigned.filter(v=>v.date===d.date).map(v=>dayKeys.get(Number(v.workoutDayID))).filter(Boolean)}))};
      const bundle={format:'sirvya-workout-backup',version:1,exportedAt:new Date().toISOString(),preferences,plans,exercises,exercisePreferences:ep.map(v=>({...v,exerciseID:Number(v.exerciseID),favorite:Boolean(v.favorite)})),schedule,history};
      validateBackup(bundle);return bundle;
    });
    res.set('Cache-Control','no-store').json(result);
  }));
  router.post('/backup/preview',requireRole('client'),run(async(req,res)=>res.json(validateBackup(req.body.backup).summary)));
  router.post('/backup/restore',requireRole('client'),run(async(req,res)=>{
    const input=req.body.backup,validated=validateBackup(input);
    const fingerprint=createHash('sha256').update(JSON.stringify(input)).digest('hex');
    const result=await transaction(async conn=>{
      await conn.query('SELECT id FROM users WHERE id=? FOR UPDATE',[req.user.id]);
      const [active]=await conn.query("SELECT id FROM workout_sessions WHERE clientID=? AND status='active'",[req.user.id]);if(active.length)fail('active_workout_exists',409);
      const [restored]=await conn.query('SELECT fingerprint FROM workout_backup_restores WHERE userID=? AND fingerprint=?',[req.user.id,fingerprint]);if(restored.length)return {alreadyRestored:true,...validated.summary};
      // A backup restored on its source account must not duplicate manually
      // recorded history. Register matching portable native sessions in the
      // existing import identity table before replaying incoming rows.
      if(input.history.sessions.length){
        const dates=input.history.sessions.map(s=>s.startedAt);
        for(let page=1;page<=20;page++){
          const existing=await capture(exportHistory,{...req,query:{page},backupConnection:conn,backupDates:dates,includeSessionIDs:true,skipBodyweight:true});
          for(const row of existing.sessions){
            const {_sessionID,...raw}=row;
            const identity=createHash('sha256').update(JSON.stringify({source:input.history.source??'SIRVYA',...raw})).digest('hex');
            await conn.query('INSERT IGNORE INTO workout_imports(userID,fingerprint,sessionID) VALUES(?,?,?)',[req.user.id,identity,_sessionID]);
          }
          if(!existing.hasMore)break;
          if(page===20)fail('backup_too_large',413);
        }
      }
      const ids=new Map(),sources=new Map();
      for(const e of input.exercises){
        const [catalog]=await conn.query('SELECT id FROM exercises WHERE externalSource=? AND externalId=? AND (ownerID IS NULL AND isPrivate=0 OR ownerID=?)',[e.externalSource,e.externalId,req.user.id]);
        let eid=catalog[0]?.id;
        if(!eid){
          const sourceKey=createHash('sha256').update(key(e)).digest('hex');
          const [[mapped]]=await conn.query('SELECT exerciseID FROM workout_import_exercises WHERE userID=? AND sourceKey=?',[req.user.id,sourceKey]);
          eid=mapped?.exerciseID;
          if(!eid){
            const v=validateCustomExercise(e);
            const [created]=await conn.query(`INSERT INTO exercises(name,description,muscleGroup,bodyPart,equipment,exerciseType,isBodyweight,isTimed,instructions,secondaryMuscles,externalSource,externalId,ownerID,isPrivate) VALUES(?,?,?,?,?,?,?,?,?,?,'sirvya-custom',?,?,1)`,[v.name,v.description,v.muscleGroup,v.bodyPart,v.equipment,v.exerciseType,v.isBodyweight?1:0,v.exerciseType==='reps'?0:1,JSON.stringify(v.instructions),JSON.stringify(v.secondaryMuscles),randomUUID(),req.user.id]);eid=created.insertId;
            await conn.query('INSERT INTO workout_import_exercises(userID,sourceKey,exerciseID) VALUES(?,?,?)',[req.user.id,sourceKey,eid]);
          }
        }
        ids.set(e.id,Number(eid));sources.set(key(e),Number(eid));
      }
      const dayIDs=new Map();
      for(const p of input.plans){
        const portable={format:'sirvya-workout-plan',version:1,name:p.name,description:p.description,days:p.days.map(d=>({...d,dayOfWeek:null,exercises:d.exercises.map(e=>({...e,exercise:validated.exercises.get(e.exerciseID)}))}))};
        const r=await capture(importPlan,{...req,body:{plan:portable},programImport:true,backupStatus:p.status,backupConnection:conn,backupExerciseIDs:sources});
        p.days.forEach((d,i)=>dayIDs.set(d.key,r.dayIDs[i]));
      }
      const mappings=Object.fromEntries(input.exercises.map(e=>[`${e.externalSource}:${e.externalId}`,ids.get(e.id)]));
      // All batches share this transaction: a failure in the final batch rolls
      // back plans, private identities, measurements and every earlier session.
      for(let offset=0;offset<Math.max(1,input.history.sessions.length);offset+=100){
        const history={...input.history,sessions:input.history.sessions.slice(offset,offset+100),bodyweight:offset===0?input.history.bodyweight:[],mappings};
        if(history.sessions.length||history.bodyweight.length)await capture(importHistory,{...req,body:history,backupConnection:conn});
      }
      for(const v of input.exercisePreferences){
        const favorite=v.favorite===true?1:0,notes=text(v.notes,2000),weight=v.workingWeight==null?null:Number(v.workingWeight);
        if(weight!=null&&(!Number.isFinite(weight)||weight<0||weight>2000))fail('invalid_backup');
        const update=req.body.restorePreferences===true?'favorite=VALUES(favorite),notes=VALUES(notes),workingWeight=VALUES(workingWeight)':'exerciseID=exerciseID';
        await conn.query('INSERT INTO workout_exercise_preferences(userID,exerciseID,favorite,notes,workingWeight) VALUES(?,?,?,?,?) ON DUPLICATE KEY UPDATE '+update,[req.user.id,ids.get(v.exerciseID),favorite,notes,weight]);
      }
      if(req.body.restorePreferences===true){
        const p=validated.preferences;
        p.balanceAnchorID=p.balanceAnchorID==null?null:ids.get(p.balanceAnchorID);
        p.balanceTargets=p.balanceTargets.map(v=>({...v,exerciseID:ids.get(v.exerciseID)}));
        p.balanceProtocols=p.balanceProtocols.map(v=>({...v,anchorID:ids.get(v.anchorID),targets:v.targets.map(t=>({...t,exerciseID:ids.get(t.exerciseID)}))}));
        await conn.query('INSERT INTO workout_preferences(userID,preferences) VALUES(?,?) ON DUPLICATE KEY UPDATE preferences=VALUES(preferences)',[req.user.id,JSON.stringify(validatePreferences(p))]);
      }
      if(req.body.restoreSchedule===true){
        await conn.query('DELETE FROM workout_week_days WHERE userID=?',[req.user.id]);
        for(const row of input.schedule.week){await conn.query('INSERT INTO workout_week_days(userID,weekday) VALUES(?,?)',[req.user.id,row.weekday]);for(const k of row.days)await conn.query('INSERT INTO workout_week_schedule(userID,weekday,workoutDayID) VALUES(?,?,?)',[req.user.id,row.weekday,dayIDs.get(k)]);}
        await conn.query('DELETE FROM workout_schedule WHERE userID=?',[req.user.id]);await conn.query('DELETE FROM workout_schedule_dates WHERE userID=?',[req.user.id]);
        for(const row of input.schedule.dates){await conn.query('INSERT INTO workout_schedule_dates(userID,workoutDate) VALUES(?,?)',[req.user.id,row.date]);for(const k of row.days)await conn.query('INSERT INTO workout_schedule(userID,workoutDate,workoutDayID) VALUES(?,?,?)',[req.user.id,row.date,dayIDs.get(k)]);}
      }
      for(const e of input.exercises)if(e.archived===true)await conn.query('UPDATE exercises SET archivedAt=NOW() WHERE id=? AND ownerID=?',[ids.get(e.id),req.user.id]);
      await conn.query('INSERT INTO workout_backup_restores(userID,fingerprint) VALUES(?,?)',[req.user.id,fingerprint]);
      return {alreadyRestored:false,...validated.summary};
    });res.status(result.alreadyRestored?200:201).json(result);
  }));
}
