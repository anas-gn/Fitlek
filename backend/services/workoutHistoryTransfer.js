import {createHash,randomUUID} from 'node:crypto';
import {requireRole} from '../middleware/auth.js';
import {fail,integer,text,number,json,validateSet,validateConfiguration,exerciseForPrescription} from './workoutDomain.js';
import {parseWorkoutCSV,parseBodyweightXML} from './workoutImport.js';
import {readSessionSets} from './workoutQueries.js';

export function installWorkoutHistoryTransfer(router,db,{run,transaction,visibleExercise,clientScope}){
  router.post('/history/import-preview',requireRole('client'),run(async(req,res)=>{
    const data=req.body.xml!=null?parseBodyweightXML(req.body.xml,{timeZone:req.body.timeZone}):req.body.csv!=null?parseWorkoutCSV(req.body.csv,{unit:req.body.unit,timeZone:req.body.timeZone}):req.body.history;
    if(!data||data.format!=='sirvya-workout-history'||data.version!==1||!Array.isArray(data.sessions)||data.sessions.length>1000)fail('invalid_import');
    const names=new Map();
    for(const s of data.sessions){if(!s||!Array.isArray(s.exercises))fail('invalid_import');for(const e of s.exercises){if(!e||typeof e!=='object'||Array.isArray(e))fail('invalid_import');const key=e.sourceKey??`${e.externalSource}:${e.externalId}`;if(!names.has(key))names.set(key,{sourceKey:key,name:text(e.name,160,true),exerciseType:e.exerciseType,matches:[]});}}
    for(const item of names.values()){
      const [rows]=await db.query('SELECT id FROM exercises WHERE name=? ORDER BY ownerID IS NULL DESC,id LIMIT 20',[item.name]);
      for(const row of rows){try{const e=await visibleExercise(db,req.user,row.id);item.matches.push({id:e.id,name:e.name,equipment:e.equipment});}catch(error){if(error.code!=='exercise_not_found')throw error;}}
    }
    res.json({...data,exercises:[...names.values()]});
  }));
  const importHistory=async(req,res)=>{
    const input=req.body;
    if(input.format!=='sirvya-workout-history'||input.version!==1||(input.unit!=null&&input.unit!=='kg')||!Array.isArray(input.sessions)||(!input.sessions.length&&!input.bodyweight?.length)||input.sessions.length>1000)fail('invalid_import');
    let totalSets=0;
    for(const s of input.sessions){
      if(!s||!Array.isArray(s.exercises)||s.exercises.length>50)fail('invalid_import');
      for(const e of s.exercises){if(!e||!Array.isArray(e.sets)||e.sets.length>60)fail('invalid_import');totalSets+=e.sets.length;if(totalSets>50000)fail('import_too_large',413);}
    }
    const commit=req.backupConnection ? fn=>fn(req.backupConnection) : transaction;
    const result=await commit(async conn=>{
      await conn.query('SELECT id FROM users WHERE id=? FOR UPDATE',[req.user.id]);
      let imported=0,skipped=0,bodyweightImported=0,bodyweightSkipped=0;const ids=[];
      if(input.bodyweight!=null){
        if(!Array.isArray(input.bodyweight)||input.bodyweight.length>1000)fail('invalid_import');
        for(const entry of input.bodyweight){
          if(!entry||typeof entry!=='object'||Array.isArray(entry))fail('invalid_import');
          const date=text(entry.recordedAt,10,true);const parsed=new Date(`${date}T12:00:00Z`);
          if(!/^\d{4}-\d{2}-\d{2}$/.test(date)||Number.isNaN(parsed.getTime())||parsed.toISOString().slice(0,10)!==date||parsed>Date.now()+86400000)fail('invalid_import_date');
          const value=number(entry.weight,1,500);if(value==null)fail('invalid_import');
          // Match the existing DECIMAL(5,2) storage before checking identity.
          // Converted Health pounds otherwise never equal the stored kg row.
          const weight=Number(value.toFixed(2)),note=text(entry.note,2000);
          const [exists]=await conn.query('SELECT id FROM weighthistory WHERE clientID=? AND recordedAt=? AND weight=?',[req.user.id,date,weight]);
          if(!exists.length){await conn.query('INSERT INTO weighthistory(clientID,recordedAt,weight,note) VALUES (?,?,?,?)',[req.user.id,date,weight,note]);bodyweightImported++;}else bodyweightSkipped++;
        }
      }
      for(const raw of input.sessions){
        if(!raw||!Array.isArray(raw.exercises)||!raw.exercises.length||raw.exercises.length>50)fail('invalid_import');
        if(typeof raw.startedAt!=='string')fail('invalid_import_date');
        const name=text(raw.name,160,true),startedAt=new Date(raw.startedAt),durationSeconds=integer(raw.durationSeconds??0,0,604800);
        if(Number.isNaN(startedAt.getTime())||startedAt.getTime()>Date.now()+60000||startedAt.getUTCFullYear()<1900)fail('invalid_import_date');
        const fingerprint=createHash('sha256').update(JSON.stringify({source:input.source??'SIRVYA',...raw})).digest('hex');
        const [duplicate]=await conn.query('SELECT sessionID FROM workout_imports WHERE userID=? AND fingerprint=?',[req.user.id,fingerprint]);
        if(duplicate.length){skipped++;continue;}
        const exercises=[],actual=[];let n=0;
        for(const r of raw.exercises){
          if(!r||!Array.isArray(r.sets)||!r.sets.length||r.sets.length>60)fail('invalid_import');
          if(r.sets.some(s=>!s||typeof s!=='object'||Array.isArray(s)))fail('invalid_set');
          const key=r.sourceKey??`${r.externalSource}:${r.externalId}`;
          let exerciseID=input.mappings?.[key]??r.exerciseID;
          if(!exerciseID&&r.externalSource&&r.externalId){
            const [found]=await conn.query('SELECT id FROM exercises WHERE externalSource=? AND externalId=?',[text(r.externalSource,80,true),text(r.externalId,160,true)]);
            if(found.length){try{exerciseID=(await visibleExercise(conn,req.user,found[0].id)).id;}catch(error){if(error.code!=='exercise_not_found')throw error;}}
          }
          const sourceKey=createHash('sha256').update(JSON.stringify([input.source??'SIRVYA',key])).digest('hex');
          if(!exerciseID){const [mapped]=await conn.query('SELECT exerciseID FROM workout_import_exercises WHERE userID=? AND sourceKey=?',[req.user.id,sourceKey]);exerciseID=mapped[0]?.exerciseID;}
          if(!exerciseID){
            if(input.createUnmatched!==true||!['reps','timed','cardio'].includes(r.exerciseType))fail('unmapped_exercise');
            const [custom]=await conn.query(`INSERT INTO exercises(name,muscleGroup,equipment,exerciseType,isBodyweight,isTimed,instructions,secondaryMuscles,externalSource,externalId,ownerID,isPrivate) VALUES(?,'other','other',?,?,?,'[]','[]','sirvya-custom',?,?,1)`,[text(r.name,160,true),r.exerciseType,r.isBodyweight===true?1:0,r.exerciseType==='reps'?0:1,randomUUID(),req.user.id]);exerciseID=custom.insertId;
          }
          if(!['reps','timed','cardio'].includes(r.exerciseType))fail('invalid_target');
          const configuration=validateConfiguration({...r.configuration,mode:r.exerciseType,...(typeof r.isBodyweight==='boolean'?{bodyweight:r.isBodyweight}:{})});
          const catalog=exerciseForPrescription(await visibleExercise(conn,req.user,exerciseID),configuration);
          await conn.query('INSERT INTO workout_import_exercises(userID,sourceKey,exerciseID) VALUES(?,?,?) ON DUPLICATE KEY UPDATE exerciseID=VALUES(exerciseID)',[req.user.id,sourceKey,exerciseID]);
          const work=r.sets.filter(s=>s.details?.phase!=='warmup');
          const e={...catalog,id:++n,exerciseID:Number(exerciseID),targetSets:Math.max(1,...work.map(s=>integer(s.setNumber,1,30))),targetReps:catalog.exerciseType==='reps'?integer(work[0]?.reps??r.sets[0].reps,1,2000):null,targetDurationSeconds:catalog.exerciseType==='reps'?null:integer(work[0]?.durationSeconds??r.sets[0].durationSeconds,1,86400),targetWeight:number(work[0]?.weight??r.sets[0].weight,0,2000),restSeconds:integer(r.restSeconds??90,0,3600),notes:text(r.notes,2000),supersetGroup:text(r.supersetGroup,64),configuration,instructions:json(catalog.instructions)};
          exercises.push(e);const unique=new Set();
          for(const row of r.sets){const set=validateSet(row,e);if(unique.has(set.setNumber))fail('invalid_set');unique.add(set.setNumber);actual.push({exercise:e,set});}
        }
        const notes=text(raw.notes,5000),completedAt=new Date(startedAt.getTime()+durationSeconds*1000);
        const [plan]=await conn.query("INSERT INTO workout_plans(coachID,clientID,name,status) VALUES(NULL,?,?,'archived')",[req.user.id,name]);
        const [session]=await conn.query("INSERT INTO workout_sessions(workoutPlanID,clientID,prescription,status,startedAt,completedAt,durationSeconds,notes,excludedFromProgression) VALUES(?,?,?,'completed',?,?,?,?,?)",[plan.insertId,req.user.id,JSON.stringify({planName:name,dayName:name,sourceDayIDs:[],importSource:input.source??'SIRVYA',exercises}),startedAt,completedAt,durationSeconds,notes,raw.excludedFromProgression===true?1:0]);
        for(const {exercise:e,set:v} of actual)await conn.query('INSERT INTO workout_sets(workoutSessionID,workoutExerciseID,exerciseID,setNumber,reps,weight,durationSeconds,rpe,rir,details,completedAt) VALUES(?,?,?,?,?,?,?,?,?,?,?)',[session.insertId,e.id,e.exerciseID,v.setNumber,v.reps,v.weight,v.durationSeconds,v.rpe,v.rir,JSON.stringify(v.details),completedAt]);
        await conn.query('INSERT INTO workout_imports(userID,fingerprint,sessionID) VALUES(?,?,?)',[req.user.id,fingerprint,session.insertId]);imported++;ids.push(session.insertId);
      }return {imported,skipped,ids,bodyweightImported,bodyweightSkipped};
    });res.status(201).json(result);
  };
  router.post('/history/import',requireRole('client'),run(importHistory));
  const exportHistory=async(req,res)=>{
    const conn=req.backupConnection??db;
    const clientID=await clientScope(req),page=integer(req.query.page??1,1,10000);
    const limit=integer(req.query.limit??100,1,100),offset=integer(req.query.offset??(page-1)*100,0,1000000),weightOffset=integer(req.query.weightOffset??(page-1)*100,0,1000000);
    const dates=req.backupDates;
    const dateFilter=dates?.length?' AND startedAt IN (?)':'';
    const [sessions]=await conn.query("SELECT * FROM workout_sessions WHERE clientID=? AND status='completed'"+dateFilter+" ORDER BY startedAt,id LIMIT ? OFFSET ?",[clientID,...(dates?.length?[dates.map(v=>new Date(v))]:[]),limit+1,offset]);
    const batch=sessions.slice(0,limit);
    const allSets=await readSessionSets(conn,batch.map(s=>s.id));
    const exerciseIDs=[...new Set(allSets.map(v=>Number(v.exerciseID)))];
    const [sourceRows]=exerciseIDs.length?await conn.query('SELECT id,externalSource,externalId FROM exercises WHERE id IN (?)',[exerciseIDs]):[[]];
    const sources=new Map(sourceRows.map(e=>[Number(e.id),{externalSource:e.externalSource,externalId:e.externalId}]));
    const result=[];
    for(const s of batch){
      const p=json(s.prescription),entries=s.execution?json(s.execution):p.exercises;
      const sets=allSets.filter(v=>Number(v.workoutSessionID)===Number(s.id));
      const exercises=[];
      for(const e of entries){
        const source=sources.get(Number(e.exerciseID));
        const own=sets.filter(v=>Number(v.workoutExerciseID)===Number(e.id));if(!own.length)continue;
        exercises.push({...source,name:e.name,exerciseType:e.exerciseType,isBodyweight:Boolean(e.isBodyweight),restSeconds:e.restSeconds,notes:e.notes,supersetGroup:e.supersetGroup,configuration:e.configuration,sets:own.map(v=>({setNumber:v.setNumber,reps:v.reps,weight:v.weight,durationSeconds:v.durationSeconds,rpe:v.rpe,rir:v.rir,details:v.details?json(v.details):{phase:'work',type:'straight'}}))});
      }
      result.push({name:p.dayName,startedAt:s.startedAt instanceof Date?s.startedAt.toISOString():s.startedAt,durationSeconds:s.durationSeconds,notes:s.notes,excludedFromProgression:s.excludedFromProgression===1,exercises,...(req.includeSessionIDs?{_sessionID:s.id}:{})});
    }
    const [weights]=req.skipBodyweight?[[]]:await conn.query('SELECT weight,DATE_FORMAT(recordedAt,\'%Y-%m-%d\') AS recordedAt,note FROM weighthistory WHERE clientID=? ORDER BY recordedAt,id LIMIT 101 OFFSET ?',[clientID,weightOffset]);
    res.json({format:'sirvya-workout-history',source:'SIRVYA',version:1,unit:'kg',sessions:result,bodyweight:weights.slice(0,100),hasMore:sessions.length>limit||weights.length>100,sessionHasMore:sessions.length>limit,bodyweightHasMore:weights.length>100});
  };
  router.get('/history/export',run(exportHistory));
  return {importHistory,exportHistory};
}
