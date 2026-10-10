import {parseWorkoutProgram,portableExercise,starterWorkoutProgram,openGymWorkoutProgram} from '../../services/workoutProgram.js';
import express from 'express';
import { requireAuth, requireRole } from '../../middleware/auth.js';
import { fail, integer, text, json, number, validatePlan, validateSet, validateCustomExercise, summarize, estimated1RM, isWorkSet,setVolume,exerciseForPrescription } from '../../services/workoutDomain.js';
import {defaultWorkoutPreferences, validatePreferences, nextTarget, balancePreferences, balancePreferenceKeys} from '../../services/workoutExperience.js';
import {buildTrainingStats,scheduleAdherence} from '../../services/workoutStats.js';
import {readPlanDetails,readSessionSets,readPreviousPerformance,readWeeklyDays} from '../../services/workoutQueries.js';
import {installWorkoutMedia} from '../../services/workoutMedia.js';
import {installWorkoutBackup} from '../../services/workoutBackup.js';
import {installWorkoutHistoryTransfer} from '../../services/workoutHistoryTransfer.js';

// Dependencies are injectable so authorization and transaction behavior can be tested.
export function createWorkoutRouter(db, {ready = Promise.resolve(), notify = async () => {}, authenticate = requireAuth} = {}) {
  const router = express.Router();
  const run = handler => async (req, res, next) => {
    try { await handler(req, res, next); }
    catch (error) {
      if (!error.status) console.error('Workout request failed:', error.code || error.message);
      res.status(error.status || 500).json({message: error.code && error.status ? error.code : 'workout_error'});
    }
  };
  const transaction = async fn => {
    const conn = await db.getConnection();
    try { await conn.beginTransaction(); const result = await fn(conn); await conn.commit(); return result; }
    catch (e) { await conn.rollback(); throw e; }
    finally { conn.release(); }
  };
  const linked = async (conn, coachID, clientID) => {
    const [rows] = await conn.query(`SELECT cc.id FROM coachclients cc JOIN users u ON u.id = cc.clientID
      WHERE cc.coachID = ? AND cc.clientID = ? AND u.role = 'client'`, [coachID, clientID]);
    if (!rows.length) fail('unauthorized_client', 403);
  };
  const planAccess = async (conn, user, id, lock = false) => {
    const [rows] = await conn.query(`SELECT * FROM workout_plans WHERE id = ?${lock ? ' FOR UPDATE' : ''}`, [integer(id)]);
    const p = rows[0];
    if (!p || (user.role === 'client' ? Number(p.clientID) !== Number(user.id) || p.coachID != null && p.status !== 'assigned' : Number(p.coachID) !== Number(user.id))) fail('workout_not_found', 404);
    if (p.coachID != null) await linked(conn, p.coachID, p.clientID);
    return p;
  };
  const editablePlan = async (conn, user, id, lock=false) => {
    const p=await planAccess(conn,user,id,lock);
    if(user.role==='client'&&p.coachID!=null)fail('unauthorized_client',403);
    return p;
  };
  const visibleExercise = async (conn, user, id) => {
    const [rows]=await conn.query(`SELECT e.* FROM exercises e WHERE e.id=? AND ((e.ownerID IS NULL AND e.isPrivate=0) OR e.ownerID=?
      OR EXISTS (SELECT 1 FROM coachclients cc WHERE (cc.coachID=? AND cc.clientID=e.ownerID) OR (cc.clientID=? AND cc.coachID=e.ownerID))
      OR EXISTS (SELECT 1 FROM workout_exercises we JOIN workout_days d ON d.id=we.workoutDayID JOIN workout_plans p ON p.id=d.workoutPlanID WHERE we.exerciseID=e.id AND p.clientID=? AND p.status='assigned' AND (p.coachID IS NULL OR EXISTS(SELECT 1 FROM coachclients cc WHERE cc.coachID=p.coachID AND cc.clientID=p.clientID))))`,[integer(id),user.id,user.id,user.id,user.id]);
    if(!rows.length)fail('exercise_not_found',404); return rows[0];
  };
  const planDetail = async (conn, p) => {
    return (await readPlanDetails(conn,[p]))[0];
  };
  const sessionAccess = async (conn, user, id, lock = false) => {
    const [rows] = await conn.query(`SELECT s.*, p.coachID FROM workout_sessions s JOIN workout_plans p ON p.id = s.workoutPlanID
      WHERE s.id = ?${lock ? ' FOR UPDATE' : ''}`, [integer(id)]);
    const s = rows[0];
    if (!s || user.role === 'client' && Number(s.clientID) !== Number(user.id)) fail('workout_not_found', 404);
    if (user.role === 'coach') await linked(conn, user.id, s.clientID);
    s.prescription = json(s.prescription);
    s.originalPrescription=s.prescription;
    if(s.execution)s.prescription={...s.prescription,exercises:json(s.execution)};
    return s;
  };
  const sessionSets = (conn,id) => readSessionSets(conn,[id]);
  const clientScope = async req => {
    if (req.user.role === 'client') {
      if (req.query.clientID != null && integer(req.query.clientID) !== Number(req.user.id)) fail('unauthorized_client', 403);
      return Number(req.user.id);
    }
    const clientID = integer(req.query.clientID);
    await linked(db, req.user.id, clientID);
    return clientID;
  };
  const validateBalanceExercises=async(conn,user,p)=>{
    const ids=new Set([p.balanceAnchorID,...p.balanceTargets.map(v=>v.exerciseID),
      ...p.balanceProtocols.flatMap(v=>[v.anchorID,...v.targets.map(t=>t.exerciseID)])].filter(v=>v!=null));
    if(ids.size>100)fail('invalid_workout');
    for(const id of ids)await visibleExercise(conn,user,id);
  };
  // Validates account/role in the database as well as the JWT on every request.
  installWorkoutMedia(router,db,{run,sessionAccess,visibleExercise},true);
  router.use(authenticate, requireRole('client', 'coach'), run(async (req, res, next) => {
    try { await ready; } catch { fail('workout_unavailable', 503); }
    const [users] = await db.query('SELECT id, role FROM users WHERE id = ?', [req.user.id]);
    if (!users.length || users[0].role !== req.user.role) fail('authentication_expired', 401);
    next();
  }));
  installWorkoutMedia(router,db,{run,sessionAccess,visibleExercise});
  router.use(run(async(req,res,next)=>{
    if(['POST','PUT'].includes(req.method) && !req.is('multipart/form-data') &&
        (!req.body || typeof req.body!=='object' || Array.isArray(req.body)))fail('invalid_workout');
    next();
  }));
  const historyTransfer=installWorkoutHistoryTransfer(router,db,{run,transaction,visibleExercise,clientScope});

  router.get('/exercises', run(async (req, res) => {
    const search = text(req.query.search, 160) || '';
    // Usage is scoped to this training account, not to all visible exercises or
    // a linked Coach's other clients. Count history entries rather than sets.
    const usageJoin = `LEFT JOIN (SELECT exerciseID,SUM(n) AS usageCount FROM (
      SELECT we.exerciseID,COUNT(*) AS n FROM workout_exercises we
      JOIN workout_days wd ON wd.id=we.workoutDayID JOIN workout_plans wp ON wp.id=wd.workoutPlanID
      WHERE wp.clientID=? AND wp.status<>'archived' GROUP BY we.exerciseID
      UNION ALL SELECT ws.exerciseID,COUNT(DISTINCT ws.workoutSessionID,ws.workoutExerciseID) AS n
      FROM workout_sets ws JOIN workout_sessions s ON s.id=ws.workoutSessionID
      WHERE s.clientID=? AND s.status='completed' GROUP BY ws.exerciseID
    ) used GROUP BY exerciseID) eu ON eu.exerciseID=e.id`;
    const catalogue = `FROM exercises e LEFT JOIN workout_exercise_preferences ep ON ep.exerciseID=e.id AND ep.userID=? ${usageJoin}`;
    const scoped = () => [req.user.id,req.user.id,req.user.id];
    const where = ['e.archivedAt IS NULL', '(e.name LIKE ? OR e.muscleGroup LIKE ? OR e.equipment LIKE ? OR COALESCE(e.description,\'\') LIKE ? OR CAST(e.secondaryMuscles AS CHAR) LIKE ?)', `((e.ownerID IS NULL AND e.isPrivate=0) OR e.ownerID=? OR EXISTS (SELECT 1 FROM coachclients cc WHERE (cc.coachID=? AND cc.clientID=e.ownerID) OR (cc.clientID=? AND cc.coachID=e.ownerID)))`]; const params = [ ...Array(5).fill(`%${search}%`),req.user.id,req.user.id,req.user.id];
    for (const key of ['bodyPart','muscleGroup', 'exerciseType']) {
      if (req.query[key]) { where.push(key==='bodyPart'?'COALESCE(e.bodyPart,e.muscleGroup) = ?':`e.${key} = ?`); params.push(text(req.query[key], 80)); }
    }
    if(req.query.secondaryMuscle){where.push('JSON_CONTAINS(e.secondaryMuscles, JSON_QUOTE(?))');params.push(text(req.query.secondaryMuscle,80));}
    if(req.query.bodyweight==='true')where.push('e.isBodyweight=1');
    if(req.query.favorite==='true')where.push('ep.favorite=1');
    if(req.query.chosen==='true')where.push('COALESCE(eu.usageCount,0)>0');
    if(req.query.equipmentList){const equipment=text(req.query.equipmentList,2000,true).split(',').slice(0,40);where.push(`e.equipment IN (${equipment.map(()=>'?').join(',')})`);params.push(...equipment);}
    // Equipment choices describe the search/body-part base, before equipment is
    // applied. A search that excludes the selected equipment clears it rather
    // than trapping the user in an empty result with a stale filter.
    const [filters] = await db.query(`SELECT DISTINCT e.bodyPart,e.muscleGroup,e.equipment,e.exerciseType,e.secondaryMuscles ${catalogue} WHERE `+where.join(' AND '),[...scoped(),...params]);
    const [equipmentCounts]=await db.query(`SELECT e.equipment,COUNT(*) AS n ${catalogue} WHERE `+where.join(' AND ')+' GROUP BY e.equipment ORDER BY n DESC,e.equipment',[...scoped(),...params]);
    const [[chosen]]=await db.query(`SELECT COUNT(*) AS n ${catalogue} WHERE e.archivedAt IS NULL AND COALESCE(eu.usageCount,0)>0`,scoped());
    const equipmentOptions=equipmentCounts.map(e=>e.equipment);
    const selectedEquipment=text(req.query.equipment,80);
    const effectiveEquipment=equipmentOptions.includes(selectedEquipment)?selectedEquipment:null;
    if(effectiveEquipment){where.push('e.equipment = ?');params.push(effectiveEquipment);}
    const [bodyParts]=await db.query(`SELECT DISTINCT COALESCE(e.bodyPart,e.muscleGroup) AS bodyPart FROM exercises e WHERE e.archivedAt IS NULL AND ((e.ownerID IS NULL AND e.isPrivate=0) OR e.ownerID=? OR EXISTS (SELECT 1 FROM coachclients cc WHERE (cc.coachID=? AND cc.clientID=e.ownerID) OR (cc.clientID=? AND cc.coachID=e.ownerID))) ORDER BY bodyPart`,[req.user.id,req.user.id,req.user.id]);
    const page = integer(req.query.page ?? 1, 1, 10000); const limit = req.query.picker === 'true' ? 50 : 40;
    const [rows] = await db.query(`SELECT e.*, COALESCE(ep.favorite,0) AS favorite, ep.notes AS personalNotes,COALESCE(eu.usageCount,0) AS usageCount,
      GREATEST(COALESCE(ep.workingWeight,0),COALESCE((SELECT MAX(ws.weight) FROM workout_sets ws JOIN workout_sessions bs ON bs.id=ws.workoutSessionID
        WHERE bs.clientID=? AND bs.status='completed' AND ws.exerciseID=e.id AND COALESCE(JSON_UNQUOTE(JSON_EXTRACT(ws.details,'$.phase')),'work')='work'),0)) AS bestWeight
      ${catalogue} WHERE ${where.join(' AND ')} ORDER BY ${req.query.chosen==='true'?'usageCount DESC, ':''}e.name, e.id LIMIT ? OFFSET ?`, [req.user.id,...scoped(),...params, limit + 1, (page - 1) * limit]);
    const [[count]]=await db.query(`SELECT COUNT(*) AS total ${catalogue} WHERE ${where.join(' AND ')}`,[...scoped(),...params]);
    res.json({data: rows.slice(0, limit).map(({instructionTranslations,...e}) => ({...e,usageCount:Number(e.usageCount), secondaryMuscles: json(e.secondaryMuscles), instructions: json(e.instructions)})),total:Number(count.total),chosenCount:Number(chosen.n), hasMore: rows.length > limit,effectiveEquipment,
      filters: {equipment:equipmentOptions,...Object.fromEntries(['exerciseType'].map(k => [k, [...new Set(filters.map(e => e[k]))].sort()])),bodyPart:bodyParts.map(e=>e.bodyPart),muscleGroup:[...new Set(filters.map(e=>e.muscleGroup))].sort(),secondaryMuscle:[...new Set(filters.flatMap(e=>json(e.secondaryMuscles)||[]))].sort()}});
  }));
  router.get('/exercises/:id/history',run(async(req,res)=>{
    const clientID=await clientScope(req),exerciseID=integer(req.params.id),page=integer(req.query.page??1,1,10000);
    await visibleExercise(db,req.user,exerciseID);
    const [rows]=await db.query(`SELECT ws.*,s.startedAt,s.durationSeconds AS workoutDurationSeconds,s.notes AS workoutNotes FROM workout_sets ws JOIN workout_sessions s ON s.id=ws.workoutSessionID WHERE s.clientID=? AND s.status='completed' AND ws.exerciseID=? ORDER BY s.startedAt DESC,s.id DESC,ws.setNumber LIMIT 61 OFFSET ?`,[clientID,exerciseID,(page-1)*60]);
    res.json({data:rows.slice(0,60).map(s=>({...s,details:s.details?json(s.details):{}})),hasMore:rows.length>60});
  }));
  router.get('/exercises/:id', run(async (req, res) => {
    const e=await visibleExercise(db,req.user,req.params.id);
    const [prefs]=await db.query('SELECT favorite,notes AS personalNotes FROM workout_exercise_preferences WHERE userID=? AND exerciseID=?',[req.user.id,e.id]);
    const language=['en','fr','es'].includes(req.query.language)?req.query.language:'en';
    const translations=e.instructionTranslations?json(e.instructionTranslations):{};
    res.json({...e,...prefs[0],instructions:translations[language]||json(e.instructions),secondaryMuscles:json(e.secondaryMuscles)});
  }));
  router.put('/exercises/:id/preferences', run(async(req,res)=>{
    const e=await visibleExercise(db,req.user,req.params.id);
    if(typeof req.body.favorite!=='boolean')fail('invalid_workout');
    await db.query(`INSERT INTO workout_exercise_preferences (userID,exerciseID,favorite,notes) VALUES (?,?,?,?) ON DUPLICATE KEY UPDATE favorite=VALUES(favorite),notes=VALUES(notes)`,[req.user.id,e.id,req.body.favorite?1:0,text(req.body.notes,2000)]);
    res.json({saved:true});
  }));
  router.put('/exercises/:id/working-weight',requireRole('client'),run(async(req,res)=>{
    const exercise=await visibleExercise(db,req.user,req.params.id);
    const weight=number(req.body.weight,0,2000);
    if(weight==null)fail('invalid_set');
    await db.query(`INSERT INTO workout_exercise_preferences(userID,exerciseID,workingWeight) VALUES(?,?,?)
      ON DUPLICATE KEY UPDATE workingWeight=GREATEST(COALESCE(workingWeight,0),VALUES(workingWeight))`,[req.user.id,exercise.id,weight]);
    res.json({saved:true});
  }));
  router.post('/exercises', run(async(req,res)=>{
    const e=validateCustomExercise(req.body);
    const [duplicates]=await db.query(`SELECT id FROM exercises WHERE archivedAt IS NULL AND LOWER(name)=LOWER(?)
      AND ((ownerID IS NULL AND isPrivate=0) OR ownerID=? OR EXISTS(SELECT 1 FROM coachclients cc WHERE
      (cc.coachID=? AND cc.clientID=ownerID) OR (cc.clientID=? AND cc.coachID=ownerID))) LIMIT 1`,[e.name,req.user.id,req.user.id,req.user.id]);
    if(duplicates.length)fail('exercise_name_exists',409);
    const [r]=await db.query(`INSERT INTO exercises (name,muscleGroup,bodyPart,equipment,exerciseType,isBodyweight,isTimed,instructions,secondaryMuscles,description,externalSource,externalId,ownerID,isPrivate) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,1)`,[e.name,e.muscleGroup,e.bodyPart,e.equipment,e.exerciseType,e.isBodyweight?1:0,e.exerciseType==='reps'?0:1,JSON.stringify(e.instructions),JSON.stringify(e.secondaryMuscles),e.description,'sirvya-custom',crypto.randomUUID(),req.user.id]);
    res.status(201).json({id:r.insertId});
  }));
  router.put('/exercises/:id',run(async(req,res)=>{
    const e=validateCustomExercise(req.body);
    await transaction(async conn=>{
      const [[existing]]=await conn.query('SELECT * FROM exercises WHERE id=? FOR UPDATE',[integer(req.params.id)]);
      if(!existing || Number(existing.ownerID)!==Number(req.user.id))fail('exercise_not_found',404);
      const [duplicates]=await conn.query(`SELECT id FROM exercises WHERE id<>? AND archivedAt IS NULL AND LOWER(name)=LOWER(?)
        AND ((ownerID IS NULL AND isPrivate=0) OR ownerID=? OR EXISTS(SELECT 1 FROM coachclients cc WHERE
        (cc.coachID=? AND cc.clientID=ownerID) OR (cc.clientID=? AND cc.coachID=ownerID))) LIMIT 1`,[existing.id,e.name,req.user.id,req.user.id,req.user.id]);
      if(duplicates.length)fail('exercise_name_exists',409);
      if(existing.exerciseType!==e.exerciseType || Boolean(existing.isBodyweight)!==e.isBodyweight){
        const [[usage]]=await conn.query('SELECT (EXISTS(SELECT 1 FROM workout_exercises WHERE exerciseID=?) OR EXISTS(SELECT 1 FROM workout_sets WHERE exerciseID=?)) AS used',[existing.id,existing.id]);
        const [active]=await conn.query("SELECT id FROM workout_sessions WHERE status='active' AND (JSON_CONTAINS(prescription,JSON_OBJECT('exerciseID',?), '$.exercises') OR JSON_CONTAINS(execution,JSON_OBJECT('exerciseID',?))) LIMIT 1",[existing.id,existing.id]);
        if(usage.used || active.length)fail('exercise_in_use',409);
      }
      await conn.query('UPDATE exercises SET name=?,muscleGroup=?,equipment=?,exerciseType=?,isBodyweight=?,isTimed=?,instructions=?,secondaryMuscles=?,description=? WHERE id=?', [e.name,e.muscleGroup,e.equipment,e.exerciseType,e.isBodyweight?1:0,e.exerciseType==='reps'?0:1,JSON.stringify(e.instructions),JSON.stringify(e.secondaryMuscles),e.description,existing.id]);
      await conn.query('UPDATE exercises SET bodyPart=? WHERE id=?',[e.bodyPart,existing.id]);
    });res.json({saved:true});
  }));
  // Personal deletion removes future routine entries, while archived identities
  // and immutable session snapshots keep completed training readable.
  router.delete('/exercises/:id',run(async(req,res)=>{
    await transaction(async conn=>{
      const id=integer(req.params.id);
      const [[exercise]]=await conn.query('SELECT id,ownerID FROM exercises WHERE id=? FOR UPDATE',[id]);
      if(!exercise||Number(exercise.ownerID)!==Number(req.user.id))fail('exercise_not_found',404);
      const [active]=await conn.query("SELECT id FROM workout_sessions WHERE status='active' AND (JSON_CONTAINS(prescription,JSON_OBJECT('exerciseID',?), '$.exercises') OR JSON_CONTAINS(execution,JSON_OBJECT('exerciseID',?))) LIMIT 1",[id,id]);
      if(active.length)fail('exercise_in_use',409);
      const [days]=await conn.query(`SELECT DISTINCT d.id,d.workoutPlanID FROM workout_days d JOIN workout_plans p ON p.id=d.workoutPlanID
        JOIN workout_exercises we ON we.workoutDayID=d.id WHERE we.exerciseID=? AND p.clientID=? AND p.coachID IS NULL FOR UPDATE`,[id,req.user.id]);
      for(const day of days){
        await conn.query('DELETE FROM workout_exercises WHERE workoutDayID=? AND exerciseID=?',[day.id,id]);
        const [remaining]=await conn.query('SELECT id,supersetGroup FROM workout_exercises WHERE workoutDayID=? ORDER BY sortOrder,id',[day.id]);
        for(let i=0;i<remaining.length;i++){
          const entry=remaining[i],group=entry.supersetGroup;
          const retained=group&&(remaining[i-1]?.supersetGroup===group||remaining[i+1]?.supersetGroup===group)?group:null;
          await conn.query('UPDATE workout_exercises SET sortOrder=?,supersetGroup=? WHERE id=?',[i,retained,entry.id]);
        }
      }
      for(const planID of new Set(days.map(day=>day.workoutPlanID)))await conn.query('UPDATE workout_plans SET revision=revision+1 WHERE id=?',[planID]);
      await conn.query('UPDATE exercises SET archivedAt=COALESCE(archivedAt,UTC_TIMESTAMP()) WHERE id=?',[id]);
      await conn.query('UPDATE workout_exercise_preferences SET workingWeight=NULL WHERE exerciseID=? AND userID=?',[id,req.user.id]);
    });
    res.json({archived:true});
  }));
  router.get('/preferences',run(async(req,res)=>{
    const [rows]=await db.query('SELECT preferences FROM workout_preferences WHERE userID=?',[req.user.id]);
    res.json({...defaultWorkoutPreferences,...(rows[0]?json(rows[0].preferences):{})});
  }));
  router.put('/preferences',run(async(req,res)=>{
    const p=validatePreferences(req.body);
    await validateBalanceExercises(db,req.user,p);
    await db.query('INSERT INTO workout_preferences (userID,preferences) VALUES (?,?) ON DUPLICATE KEY UPDATE preferences=VALUES(preferences)',[req.user.id,JSON.stringify(p)]);
    res.json(p);
  }));
  // Coach access is limited to linked clients and these workout-specific ratios.
  router.get('/balance',run(async(req,res)=>{
    const clientID=await clientScope(req);
    const [[row]]=await db.query('SELECT preferences FROM workout_preferences WHERE userID=?',[clientID]);
    res.json(balancePreferences(row?json(row.preferences):{}));
  }));
  router.put('/balance',run(async(req,res)=>{
    const clientID=await clientScope(req);
    if(Object.keys(req.body).some(k=>!balancePreferenceKeys.includes(k)))fail('invalid_workout');
    const data=await transaction(async conn=>{
      await conn.query("INSERT IGNORE INTO workout_preferences (userID,preferences) VALUES (?, '{}')",[clientID]);
      const [[row]]=await conn.query('SELECT preferences FROM workout_preferences WHERE userID=? FOR UPDATE',[clientID]);
      const changes=Object.fromEntries(balancePreferenceKeys.filter(k=>Object.hasOwn(req.body,k)).map(k=>[k,req.body[k]]));
      const p=validatePreferences({...json(row.preferences),...changes});
      await validateBalanceExercises(conn,{id:clientID,role:'client'},p);
      await conn.query('UPDATE workout_preferences SET preferences=? WHERE userID=?',[JSON.stringify(p),clientID]);
      return balancePreferences(p);
    });
    res.json(data);
  }));
  router.get('/clients', requireRole('coach'), run(async (req, res) => {
    const [rows] = await db.query(`SELECT u.id, u.firstName, u.lastName, u.avatarUrl FROM users u JOIN coachclients cc ON cc.clientID = u.id
      WHERE cc.coachID = ? AND u.role = 'client' ORDER BY u.firstName, u.id`, [req.user.id]);
    res.json({data: rows});
  }));
  router.get('/plans', run(async (req, res) => {
    const where = req.user.role === 'coach' ? 'p.coachID = ?' : "p.clientID = ? AND (p.status = 'assigned' OR p.coachID IS NULL AND p.status = 'draft')";
    const params = [req.user.id];
    let extra = '';
    if (req.user.role === 'coach' && req.query.clientID != null) { const id = integer(req.query.clientID); await linked(db, req.user.id, id); extra = ' AND p.clientID = ?'; params.push(id); }
    const [rows] = await db.query(`SELECT p.*, u.firstName, u.lastName FROM workout_plans p
      JOIN users u ON u.id = p.clientID WHERE ${where}${extra} AND (p.coachID IS NULL OR EXISTS (SELECT 1 FROM coachclients cc WHERE cc.coachID=p.coachID AND cc.clientID=p.clientID)) ORDER BY p.updatedAt DESC, p.id DESC`, params);
    res.json({data:await readPlanDetails(db,rows)});
  }));
  router.get('/plans/:id', run(async (req, res) => res.json(await planDetail(db, await planAccess(db, req.user, req.params.id)))));

  const savePlan = async (req, res, updating, imported = null) => {
    if(req.user.role==='client' && req.body.clientID!=null && integer(req.body.clientID)!==Number(req.user.id))fail('unauthorized_client',403);
    const body = validatePlan({...req.body,clientID:req.user.role==='client'?req.user.id:req.body.clientID},{allowEmptyRoutine:req.user.role==='client'});
    const commit=req.backupConnection ? fn=>fn(req.backupConnection) : transaction;
    const result = await commit(async conn => {
      if(req.user.role==='coach')await linked(conn, req.user.id, body.clientID);
      if(imported){
        const ids=new Map();
        for(const [placeholder,e] of imported){
          const [matches]=await conn.query('SELECT id FROM exercises WHERE externalSource=? AND externalId=? AND ownerID IS NULL AND isPrivate=0',[e.externalSource,e.externalId]);
          let id=req.backupExerciseIDs?.get(JSON.stringify([e.externalSource,e.externalId])) ?? matches[0]?.id;
          if(!id && e.externalSource==='sirvya-custom'){
            const [[same]]=await conn.query('SELECT id FROM exercises WHERE ownerID=? AND isPrivate=1 AND LOWER(name)=LOWER(?) AND COALESCE(bodyPart,muscleGroup)=?',[req.user.id,e.name,e.bodyPart??e.muscleGroup]);
            id=same?.id;
          }
          if(!id){
            const [row]=await conn.query(`INSERT INTO exercises(name,muscleGroup,equipment,exerciseType,isBodyweight,isTimed,instructions,secondaryMuscles,externalSource,externalId,ownerID,isPrivate) VALUES(?,?,?,?,?,?,?,?,'sirvya-custom',?,?,1)`,[e.name,e.muscleGroup,e.equipment,e.exerciseType,e.isBodyweight?1:0,e.exerciseType==='reps'?0:1,JSON.stringify(e.instructions),JSON.stringify([]),crypto.randomUUID(),req.user.id]);
            id=row.insertId;
            await conn.query('UPDATE exercises SET bodyPart=?,description=? WHERE id=?',[e.bodyPart??e.muscleGroup,e.description??null,id]);
          }ids.set(placeholder,id);
        }
        for(const day of body.days)for(const e of day.exercises)e.exerciseID=ids.get(e.exerciseID);
      }
      let id;let existingDays=[],existingExercises=[];
      if (updating) {
        const p = await editablePlan(conn, req.user, req.params.id, true);
        if (Number(p.clientID) !== body.clientID) fail('invalid_workout');
        if (integer(req.body.revision) !== p.revision) fail('plan_changed', 409);
        id = p.id;
        await conn.query('UPDATE workout_plans SET name = ?, description = ?, status = ?, revision = revision + 1 WHERE id = ?', [body.name, body.description, body.status, id]);
        [existingDays]=await conn.query('SELECT id FROM workout_days WHERE workoutPlanID=?',[id]);
        [existingExercises]=await conn.query('SELECT we.id FROM workout_exercises we JOIN workout_days d ON d.id=we.workoutDayID WHERE d.workoutPlanID=?',[id]);
      } else {
        const [r] = await conn.query('INSERT INTO workout_plans (coachID, clientID, name, description, status) VALUES (?, ?, ?, ?, ?)', [req.user.role==='coach'?req.user.id:null, body.clientID, body.name, body.description, body.status]);
        id = r.insertId;
      }
      const keptDays=new Set(),keptExercises=new Set(),newDayIDs=[];
      for(const d of body.days){
        let dayID;
        if(updating&&d.id){
          if(!existingDays.some(v=>Number(v.id)===d.id)||keptDays.has(d.id))fail('invalid_workout');dayID=d.id;
          await conn.query('UPDATE workout_days SET name=?,dayOfWeek=?,sortOrder=?,configuration=? WHERE id=? AND workoutPlanID=?',[d.name,d.dayOfWeek,d.sortOrder,JSON.stringify(d.configuration),dayID,id]);
        }else{const [r]=await conn.query('INSERT INTO workout_days(workoutPlanID,name,dayOfWeek,sortOrder,configuration) VALUES(?,?,?,?,?)',[id,d.name,d.dayOfWeek,d.sortOrder,JSON.stringify(d.configuration)]);dayID=r.insertId;}
        keptDays.add(Number(dayID));newDayIDs.push(Number(dayID));
        for(const e of d.exercises){
          const catalog=exerciseForPrescription(await visibleExercise(conn,req.user,e.exerciseID),e.configuration);
          if(catalog.exerciseType==='reps'?e.targetReps===null||e.targetDurationSeconds!==null:e.targetDurationSeconds===null||e.targetReps!==null)fail('invalid_target');
          const values=[dayID,e.exerciseID,e.sortOrder,e.targetSets,e.targetReps,e.targetWeight,e.targetDurationSeconds,e.restSeconds,e.notes,e.supersetGroup,JSON.stringify(e.configuration)];
          let exerciseID;
          if(updating&&e.id){
            if(!existingExercises.some(v=>Number(v.id)===e.id)||keptExercises.has(e.id))fail('invalid_workout');exerciseID=e.id;
            await conn.query('UPDATE workout_exercises SET workoutDayID=?,exerciseID=?,sortOrder=?,targetSets=?,targetReps=?,targetWeight=?,targetDurationSeconds=?,restSeconds=?,notes=?,supersetGroup=?,configuration=? WHERE id=?',[...values,exerciseID]);
          }else{const [r]=await conn.query('INSERT INTO workout_exercises(workoutDayID,exerciseID,sortOrder,targetSets,targetReps,targetWeight,targetDurationSeconds,restSeconds,notes,supersetGroup,configuration) VALUES(?,?,?,?,?,?,?,?,?,?,?)',values);exerciseID=r.insertId;}
          keptExercises.add(Number(exerciseID));
        }
      }
      for(const row of existingExercises)if(!keptExercises.has(Number(row.id)))await conn.query('DELETE FROM workout_exercises WHERE id=?',[row.id]);
      for(const row of existingDays)if(!keptDays.has(Number(row.id)))await conn.query('DELETE FROM workout_days WHERE id=? AND workoutPlanID=?',[row.id,id]);
      if(req.programWeek){
        if(req.user.role!=='client'||body.status!=='assigned')fail('invalid_workout');
        await conn.query('SELECT id FROM users WHERE id=? FOR UPDATE',[req.user.id]);
        const weekdays=req.programWeekDays??[1,2,3,4,5,6,7];
        for(const weekday of weekdays){
          await conn.query('DELETE FROM workout_week_days WHERE userID=? AND weekday=?',[req.user.id,weekday]);
          await conn.query('INSERT INTO workout_week_days(userID,weekday) VALUES(?,?)',[req.user.id,weekday]);
          for(const index of req.programWeek[weekday]??[])await conn.query('INSERT INTO workout_week_schedule(userID,weekday,workoutDayID) VALUES(?,?,?)',[req.user.id,weekday,newDayIDs[index]]);
        }
      }
      return {id, revision: updating ? Number(req.body.revision) + 1 : 1,dayIDs:newDayIDs,exerciseIDs:[...keptExercises]};
    });
    res.status(updating ? 200 : 201).json(result);
    if (body.status === 'assigned'&&req.user.role==='coach') void notify({recipientUserID: body.clientID, type: 'workout_assigned', title: 'SIRVYA Workout', body: body.name,
      relatedEntityID: result.id, uniqueKey: `workout_assigned:${result.id}:${result.revision}`}).catch(() => {});
  };
  router.post('/plans', run((req, res) => savePlan(req, res, false)));
  router.put('/plans/:id', run((req, res) => savePlan(req, res, true)));
  // Archive rather than destroy prescriptions referenced by history.
  router.delete('/plans/:id', run(async (req, res) => {
    await transaction(async conn => {
      const p = await editablePlan(conn, req.user, req.params.id, true);
      await conn.query("UPDATE workout_plans SET status = 'archived', revision = revision + 1 WHERE id = ?", [p.id]);
    });
    res.json({archived: true});
  }));
  router.delete('/plans/:id/days/:dayID',run(async(req,res)=>{
    await transaction(async conn=>{
      const plan=await editablePlan(conn,req.user,req.params.id,true);
      if(integer(req.query.revision)!==Number(plan.revision))fail('plan_changed',409);
      const dayID=integer(req.params.dayID);
      const [days]=await conn.query('SELECT id FROM workout_days WHERE workoutPlanID=? AND id=?',[plan.id,dayID]);
      if(!days.length)fail('workout_not_found',404);
      await conn.query('DELETE FROM workout_days WHERE workoutPlanID=? AND id=?',[plan.id,dayID]);
      const [[remaining]]=await conn.query('SELECT COUNT(*) AS n FROM workout_days WHERE workoutPlanID=?',[plan.id]);
      await conn.query('UPDATE workout_plans SET revision=revision+1,status=? WHERE id=?',[Number(remaining.n)?plan.status:'archived',plan.id]);
    });res.json({deleted:true});
  }));
  router.post('/plans/:id/duplicate',run(async(req,res)=>{
    const p=await planDetail(db,await planAccess(db,req.user,req.params.id));
    req.body={...p,id:undefined,revision:undefined,clientID:req.user.role==='client'?req.user.id:(req.body.clientID??p.clientID),name:text(req.body.name,160)||`${p.name.slice(0,150)} (copy)`,status:'draft'};
    await savePlan(req,res,false);
  }));
  router.get('/plans/:id/export',run(async(req,res)=>{
    const plan=await planDetail(db,await planAccess(db,req.user,req.params.id));
    const days=[];
    for(const day of plan.days){const exercises=[];for(const e of day.exercises){const source=await visibleExercise(db,req.user,e.exerciseID);exercises.push({targetSets:e.targetSets,targetReps:e.targetReps,targetWeight:e.targetWeight,targetDurationSeconds:e.targetDurationSeconds,restSeconds:e.restSeconds,notes:e.notes,supersetGroup:e.supersetGroup,configuration:e.configuration,
      exercise:{externalSource:source.externalSource,externalId:source.externalId,name:source.name,muscleGroup:source.muscleGroup,equipment:source.equipment,exerciseType:source.exerciseType,isBodyweight:source.isBodyweight===1,instructions:json(source.instructions)}});}days.push({name:day.name,dayOfWeek:day.dayOfWeek,configuration:day.configuration,exercises});}
    res.json({format:'sirvya-workout-plan',version:1,name:plan.name,description:plan.description,days});
  }));
  const importPlan=async(req,res)=>{
    const input=req.body.plan;
    if(!input||input.format!=='sirvya-workout-plan'||input.version!==1||!Array.isArray(input.days)||input.days.length>(req.programImport?100:14))fail('invalid_workout');
    const imported=new Map(),keys=new Map(),days=[];
    for(const day of input.days){
      if(!day||!Array.isArray(day.exercises)||day.exercises.length>50)fail('invalid_workout');
      const exercises=[];
      for(const config of day.exercises){
        const raw=config?.exercise;
        if(!raw||!['reps','timed','cardio'].includes(raw.exerciseType)||!Array.isArray(raw.instructions)||raw.instructions.length>30)fail('invalid_workout');
        const e={externalSource:text(raw.externalSource,80,true),externalId:text(raw.externalId,160,true),name:text(raw.name,160,true),muscleGroup:text(raw.muscleGroup,80,true),equipment:text(raw.equipment,80,true),exerciseType:raw.exerciseType,isBodyweight:raw.isBodyweight===true,bodyPart:text(raw.bodyPart,80)??raw.muscleGroup,description:text(raw.description,5000),instructions:raw.instructions.map(v=>text(v,2000,true))};
        const key=JSON.stringify([e.externalSource,e.externalId]);let id=keys.get(key);
        if(!id){id=keys.size+1;keys.set(key,id);imported.set(id,e);}
        exercises.push({...config,exerciseID:id});
      }days.push({...day,exercises});
    }
    req.body={name:input.name,description:input.description,status:req.backupStatus ?? (req.programImport && req.user.role==='client' && days.length && days.every(d=>d.exercises.length)?'assigned':'draft'),clientID:req.user.role==='client'?req.user.id:req.body.clientID,days};
    await savePlan(req,res,false,imported);
  };
  router.post('/plans/import',run(importPlan));
  router.get('/program/export',requireRole('client'),run(async(req,res)=>{
    const [rows]=await db.query("SELECT p.* FROM workout_plans p WHERE p.clientID=? AND (p.status='assigned' OR p.coachID IS NULL AND p.status='draft') AND (p.coachID IS NULL OR EXISTS(SELECT 1 FROM coachclients cc WHERE cc.coachID=p.coachID AND cc.clientID=p.clientID)) ORDER BY p.id",[req.user.id]);
    const plans=await readPlanDetails(db,rows),days=[];const indexByDay=new Map();
    for(const p of plans)for(const d of p.days){
      indexByDay.set(Number(d.id),days.length);
      const exercises=[];for(const e of d.exercises)exercises.push({targetSets:e.targetSets,targetReps:e.targetReps,targetWeight:e.targetWeight,targetDurationSeconds:e.targetDurationSeconds,restSeconds:e.restSeconds,notes:e.notes,supersetGroup:e.supersetGroup,configuration:e.configuration,exercise:portableExercise(await visibleExercise(db,req.user,e.exerciseID))});
      days.push({name:d.name,configuration:d.configuration,dayOfWeek:null,exercises});
    }
    const week={};for(const day of await readWeeklyDays(db,req.user.id)){const index=indexByDay.get(Number(day.id));if(index!=null)(week[day.dayOfWeek]??=[]).push(index);}
    const bundle={format:'sirvya-workout-program',version:1,plan:{format:'sirvya-workout-plan',version:1,name:'Weekly workout plan',days},week};
    res.json(req.query.format==='opengym'?openGymWorkoutProgram(bundle):bundle);
  }));
  router.post('/program/starter',requireRole('client'),run(async(req,res)=>{
    const [catalog]=await db.query("SELECT * FROM exercises WHERE ownerID IS NULL AND isPrivate=0 AND externalSource='exercises-dataset'");
    const bundle=parseWorkoutProgram(starterWorkoutProgram(),catalog,{clientID:req.user.id});
    if(bundle.dropped)fail('starter_unavailable',409);
    req.programImport=true;req.programWeek=bundle.week;req.programWeekDays=[1,3,5];req.body={plan:bundle.plan};
    await importPlan(req,res);
  }));
  router.post('/program/import-preview',requireRole('client'),run(async(req,res)=>{
    const [catalog]=await db.query("SELECT * FROM exercises WHERE ownerID IS NULL AND isPrivate=0 AND externalSource='exercises-dataset'");
    res.json(parseWorkoutProgram(req.body.program,catalog,{clientID:req.user.id}));
  }));
  router.post('/program/import',requireRole('client'),run(async(req,res)=>{
    const [catalog]=await db.query("SELECT * FROM exercises WHERE ownerID IS NULL AND isPrivate=0 AND externalSource='exercises-dataset'");
    const bundle=parseWorkoutProgram(req.body.program,catalog,{clientID:req.user.id});
    if(req.body.replaceWeek!==undefined&&typeof req.body.replaceWeek!=='boolean')fail('invalid_workout');
    req.programImport=true;req.programWeek=req.body.replaceWeek?bundle.week:null;req.body={plan:bundle.plan};
    await importPlan(req,res);
  }));
  router.get('/templates',run(async(req,res)=>{
    const templates=[{key:'full-body',name:'Full body',days:[{name:'Full body A',dayOfWeek:1,ids:['goblet-squat','dumbbell-press','row','plank']},{name:'Full body B',dayOfWeek:3,ids:['romanian-deadlift','overhead-press','lat-pulldown','glute-bridge']},{name:'Full body A',dayOfWeek:5,ids:['goblet-squat','dumbbell-press','row','plank']}]},
      {key:'push-pull-legs',name:'Push / Pull / Legs',days:[{name:'Push',dayOfWeek:1,ids:['bench-press','overhead-press','triceps-pushdown']},{name:'Pull',dayOfWeek:3,ids:['deadlift','row','curl']},{name:'Legs',dayOfWeek:5,ids:['squat','romanian-deadlift','calf-raise']}]},
      {key:'bodyweight',name:'Bodyweight',days:[{name:'At home',dayOfWeek:null,ids:['push-up','lunge','glute-bridge','plank']}]}];
    const [catalog]=await db.query("SELECT * FROM exercises WHERE externalSource='sirvya'");
    res.json({data:templates.map(t=>({...t,days:t.days.map(d=>({name:d.name,dayOfWeek:d.dayOfWeek,exercises:d.ids.map(id=>{const e=catalog.find(e=>e.externalId===id);return {...e,id:0,exerciseID:e.id,instructions:json(e.instructions),targetSets:3,targetReps:e.exerciseType==='reps'?10:null,targetWeight:0,targetDurationSeconds:e.exerciseType==='reps'?null:30,restSeconds:90,configuration:{progression:'off'}};})}))}))});
  }));
  router.get('/schedule',run(async(req,res)=>{
    const clientID=await clientScope(req);
    const [rows]=await db.query("SELECT DATE_FORMAT(workoutDate,'%Y-%m-%d') AS workoutDate,workoutDayID FROM workout_schedule WHERE userID=? ORDER BY workoutDate,workoutDayID",[clientID]);
    const [overrides]=await db.query("SELECT DATE_FORMAT(workoutDate,'%Y-%m-%d') AS workoutDate FROM workout_schedule_dates WHERE userID=? ORDER BY workoutDate",[clientID]);
    const [weekOverrides]=await db.query('SELECT weekday FROM workout_week_days WHERE userID=? ORDER BY weekday',[clientID]);
    res.json({data:rows,overrideDates:overrides.map(d=>d.workoutDate),week:await readWeeklyDays(db,clientID),weekOverrideDays:weekOverrides.map(r=>Number(r.weekday))});
  }));
  router.put('/week',requireRole('client'),run(async(req,res)=>{
    const weekday=integer(req.body.weekday,1,7);
    if(!Array.isArray(req.body.dayIDs)||req.body.dayIDs.length>14)fail('invalid_workout');
    const ids=[...new Set(req.body.dayIDs.map(v=>integer(v)))];
    await transaction(async conn=>{
      await conn.query('SELECT id FROM users WHERE id=? FOR UPDATE',[req.user.id]);
      for(const id of ids){
        const [[day]]=await conn.query('SELECT workoutPlanID FROM workout_days WHERE id=?',[id]);
        if(!day)fail('workout_not_found',404);
        if((await planAccess(conn,req.user,day.workoutPlanID)).status!=='assigned')fail('invalid_workout');
      }
      await conn.query('DELETE FROM workout_week_days WHERE userID=? AND weekday=?',[req.user.id,weekday]);
      if(req.body.reset===true)return;
      await conn.query('INSERT INTO workout_week_days(userID,weekday) VALUES(?,?)',[req.user.id,weekday]);
      for(const id of ids)await conn.query('INSERT INTO workout_week_schedule(userID,weekday,workoutDayID) VALUES(?,?,?)',[req.user.id,weekday,id]);
    });res.json({saved:true});
  }));
  router.post('/schedule/move',requireRole('client'),run(async(req,res)=>{
    const valid=date=>typeof date==='string'&&/^\d{4}-\d{2}-\d{2}$/.test(date)&&!Number.isNaN(Date.parse(date))&&new Date(date).toISOString().slice(0,10)===date;
    const {fromDate,toDate}=req.body;
    if(!valid(fromDate)||!valid(toDate)||fromDate===toDate)fail('invalid_workout');
    await transaction(async conn=>{
      await conn.query('SELECT id FROM users WHERE id=? FOR UPDATE',[req.user.id]);
      const weekly=await readWeeklyDays(conn,req.user.id);
      const effective=async date=>{
        const [override]=await conn.query('SELECT userID FROM workout_schedule_dates WHERE userID=? AND workoutDate=?',[req.user.id,date]);
        if(!override.length)return weekly.filter(d=>Number(d.dayOfWeek)===(new Date(`${date}T12:00:00Z`).getUTCDay()||7)).map(d=>Number(d.id));
        const [rows]=await conn.query('SELECT workoutDayID FROM workout_schedule WHERE userID=? AND workoutDate=?',[req.user.id,date]);
        const accessible=new Set(weekly.map(d=>Number(d.id)));
        // Flexible routines may exist only in date overrides. Recheck each plan.
        for(const row of rows){const [[day]]=await conn.query('SELECT workoutPlanID FROM workout_days WHERE id=?',[row.workoutDayID]);if(day&&(await planAccess(conn,req.user,day.workoutPlanID)).status==='assigned')accessible.add(Number(row.workoutDayID));}
        return rows.map(r=>Number(r.workoutDayID)).filter(id=>accessible.has(id));
      };
      const source=await effective(fromDate);
      if(!source.length)fail('empty_plan');
      const destination=[...new Set([...await effective(toDate),...source])];
      if(destination.length>14)fail('invalid_workout');
      for(const date of [fromDate,toDate]){
        await conn.query('INSERT IGNORE INTO workout_schedule_dates(userID,workoutDate) VALUES(?,?)',[req.user.id,date]);
        await conn.query('DELETE FROM workout_schedule WHERE userID=? AND workoutDate=?',[req.user.id,date]);
      }
      for(const id of destination)await conn.query('INSERT INTO workout_schedule(userID,workoutDate,workoutDayID) VALUES(?,?,?)',[req.user.id,toDate,id]);
    });res.json({saved:true});
  }));
  router.put('/schedule',requireRole('client'),run(async(req,res)=>{
    if(!/^\d{4}-\d{2}-\d{2}$/.test(req.body.date)||Number.isNaN(Date.parse(req.body.date))||new Date(req.body.date).toISOString().slice(0,10)!==req.body.date||!Array.isArray(req.body.dayIDs)||req.body.dayIDs.length>14)fail('invalid_workout');
    await transaction(async conn=>{
      await conn.query('SELECT id FROM users WHERE id=? FOR UPDATE',[req.user.id]);
      for(const id of new Set(req.body.dayIDs)) {const [days]=await conn.query('SELECT workoutPlanID FROM workout_days WHERE id=?',[integer(id)]);if(!days.length)fail('workout_not_found',404);const p=await planAccess(conn,req.user,days[0].workoutPlanID);if(p.status!=='assigned')fail('invalid_workout');}
      await conn.query('DELETE FROM workout_schedule WHERE userID=? AND workoutDate=?',[req.user.id,req.body.date]);
      if(req.body.reset===true) {
        await conn.query('DELETE FROM workout_schedule_dates WHERE userID=? AND workoutDate=?',[req.user.id,req.body.date]);
        return;
      }
      await conn.query('INSERT IGNORE INTO workout_schedule_dates (userID,workoutDate) VALUES (?,?)',[req.user.id,req.body.date]);
      for(const id of new Set(req.body.dayIDs))await conn.query('INSERT INTO workout_schedule (userID,workoutDate,workoutDayID) VALUES (?,?,?)',[req.user.id,req.body.date,id]);
    });res.json({saved:true});
  }));
  router.post('/sessions', requireRole('client'), run(async (req, res) => {
    if(req.body.workoutDayIDs!=null&&!Array.isArray(req.body.workoutDayIDs))fail('invalid_workout');
    if(req.body.startedAt!=null&&typeof req.body.startedAt!=='string')fail('invalid_workout');
    const historical=req.body.startedAt!=null;
    const startedAt=historical?new Date(req.body.startedAt):new Date();
    if(Number.isNaN(startedAt.getTime())||startedAt.getTime()>Date.now()+60000||startedAt.getUTCFullYear()<1900)fail('invalid_workout');
    const freestyle=req.body.freestyle===true;
    const dayIDs=freestyle?[]:[...new Set((req.body.workoutDayIDs??[req.body.workoutDayID]).map(v=>integer(v)))];
    if(!freestyle&&(!dayIDs.length||dayIDs.length>14))fail('invalid_workout');
    const dayID=dayIDs[0]??null;
    const result = await transaction(async conn => {
      await conn.query('SELECT id FROM users WHERE id = ? FOR UPDATE', [req.user.id]);
      const [active] = await conn.query("SELECT id, workoutDayID, prescription FROM workout_sessions WHERE clientID = ? AND status = 'active'", [req.user.id]);
      if (active.length) {
        const sourceIDs=json(active[0].prescription).sourceDayIDs??[Number(active[0].workoutDayID)];
        if (JSON.stringify(sourceIDs)!==JSON.stringify(dayIDs)||historical!==Boolean(json(active[0].prescription).historical)) fail('active_workout_exists', 409);
        await sessionAccess(conn, req.user, active[0].id);
        return {id: active[0].id, resumed: true};
      }
      let p,day;const selected=[];
      for(const id of dayIDs){
        const [days]=await conn.query('SELECT workoutPlanID FROM workout_days WHERE id=?',[id]);
        if(!days.length)fail('workout_not_found',404);
        const plan=await planAccess(conn,req.user,days[0].workoutPlanID,true);
        if(plan.status!=='assigned')fail('invalid_workout');
        const detail=await planDetail(conn,plan),chosen=detail.days.find(d=>Number(d.id)===id);
        if(!chosen || plan.coachID!=null&&!chosen.exercises.length)fail('empty_plan');
        chosen.exercises=chosen.exercises.map(e=>{
          if(e.configuration.progression!=='inherit')return e;
          const policy=chosen.configuration.progression??'off';
          const progression=e.exerciseType==='cardio'||(e.exerciseType!=='reps'&&policy!=='time')|| (e.exerciseType==='reps'&&policy==='time')?'off':policy;
          return {...e,configuration:{...e.configuration,progression}};
        });
        selected.push({plan,day:chosen});
      }
      if(selected.length===1){p=selected[0].plan;day=selected[0].day;}
      else {
        const name=freestyle?(text(req.body.name,160)||'Freestyle workout'):selected.map(s=>s.day.name).join(' + ').slice(0,160);
        const [container]=await conn.query("INSERT INTO workout_plans(coachID,clientID,name,status) VALUES(NULL,?,?,'archived')",[req.user.id,name]);
        p={id:container.insertId,name};day={name,exercises:selected.flatMap(({day},i)=>day.exercises.map(e=>({...e,supersetGroup:e.supersetGroup?`${i}:${e.supersetGroup}`:null})))};
        if(day.exercises.length>50)fail('invalid_workout');
      }
      const [[startPrefs]]=await conn.query('SELECT preferences FROM workout_preferences WHERE userID=?',[req.user.id]);
      const startUnit=startPrefs?json(startPrefs.preferences).unit:'kg';
      for(const e of day.exercises) {
        const sharedHistory=!selected.find(s=>s.day.exercises.some(x=>Number(x.id)===Number(e.id)))?.plan.coachID && day.exercises.filter(x=>Number(x.exerciseID)===Number(e.exerciseID)).length===1;
        const [past]=await conn.query(`SELECT s.prescription,s.execution,s.excludedFromProgression,ws.* FROM workout_sessions s JOIN workout_sets ws ON ws.workoutSessionID=s.id WHERE s.clientID=? AND s.status='completed' AND ws.exerciseID=? AND s.startedAt<=? ORDER BY s.startedAt DESC,s.id DESC,ws.setNumber`,[req.user.id,e.exerciseID,startedAt]);
        const groups=new Map();
        const [[preference]]=await conn.query('SELECT workingWeight FROM workout_exercise_preferences WHERE userID=? AND exerciseID=?',[req.user.id,e.exerciseID]);
        // The retained confirmation and the lifetime record have different roles.
        // Without a confirmation, row prefill uses the last positional set.
        e.workingWeight=Number(preference?.workingWeight)||null;
        e.bestWeight=Math.max(e.workingWeight||0,...past.filter(isWorkSet).map(s=>Number(s.weight)||0));
        for(const row of past){
          const entries=row.execution?json(row.execution):json(row.prescription).exercises;
          const target=entries.find(x=>Number(x.exerciseID)===Number(e.exerciseID)&&(sharedHistory||Number(x.id)===Number(e.id)));
          if(!target||Number(row.workoutExerciseID)!==Number(target.id))continue;
          const id=Number(row.workoutSessionID);
          if(!groups.has(id))groups.set(id,{target,excludedFromProgression:row.excludedFromProgression,sets:[]});
          groups.get(id).sets.push(row);
        }
        // Coach prescriptions progress by stable slot; personal routines reuse the
        // most recent compatible exercise performance, as the reference does.
        const history=[...groups.values()];
        const recommendation=nextTarget(e,history,{sharedHistory,unit:startUnit});
        e.originalTargets={targetWeight:e.targetWeight,targetReps:e.targetReps,targetSets:e.targetSets,targetDurationSeconds:e.targetDurationSeconds};
        e.recommendation=recommendation;
        if(recommendation.policy!=='off'){e.targetWeight=recommendation.weight;e.targetReps=recommendation.reps;e.targetSets=recommendation.sets;e.targetDurationSeconds=recommendation.durationSeconds;}
      }
      const prescription = {planName: p.name, dayName: day.name, sourceDayIDs:dayIDs, historical, exercises: day.exercises};
      const [r] = await conn.query('INSERT INTO workout_sessions (workoutPlanID, workoutDayID, clientID, prescription, activeClientID,startedAt) VALUES (?, ?, ?, ?, ?,?)', [p.id, selected.length===1?dayID:null, req.user.id, JSON.stringify(prescription), req.user.id,startedAt]);
      return {id: r.insertId};
    });
    res.status(201).json(result);
  }));
  router.get('/sessions/active', requireRole('client'), run(async (req, res) => {
    const [rows] = await db.query("SELECT id FROM workout_sessions WHERE clientID = ? AND status = 'active'", [req.user.id]);
    if (!rows.length) return res.json({session: null});
    const s = await sessionAccess(db, req.user, rows[0].id);
    res.json({session: {...s, sets: await sessionSets(db, s.id)}});
  }));
  router.get('/sessions/:id', run(async (req, res) => {
    const s = await sessionAccess(db, req.user, req.params.id); const sets = await sessionSets(db, s.id);
    const previous = await readPreviousPerformance(db,s);
    res.json({...s, sets, previous, summary: summarize(sets, s.prescription)});
  }));
  router.put('/sessions/:id/sets', requireRole('client'), run(async (req, res) => {
    const result = await transaction(async conn => {
      const s = await sessionAccess(conn, req.user, req.params.id, true);
      if (s.status !== 'active') fail('workout_closed', 409);
      const e = s.prescription.exercises.find(e => Number(e.id) === integer(req.body.workoutExerciseID));
      if (!e) fail('invalid_set');
      const v = validateSet(req.body, e);
      await conn.query(`INSERT INTO workout_sets (workoutSessionID, workoutExerciseID, exerciseID, setNumber, reps, weight, durationSeconds, rpe, rir, details)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE reps = VALUES(reps), weight = VALUES(weight), durationSeconds = VALUES(durationSeconds), rpe = VALUES(rpe), rir = VALUES(rir), details = VALUES(details)`,
      [s.id, e.id, e.exerciseID, v.setNumber, v.reps, v.weight, v.durationSeconds, v.rpe, v.rir, JSON.stringify(v.details)]);
      return {saved: true};
    });
    res.json(result);
  }));
  router.delete('/sessions/:id/sets/:exerciseID/:setNumber',requireRole('client'),run(async(req,res)=>{
    await transaction(async conn=>{
      const s=await sessionAccess(conn,req.user,req.params.id,true);
      if(s.status!=='active')fail('workout_closed',409);
      const exerciseID=integer(req.params.exerciseID),setNumber=integer(req.params.setNumber,1,1030);
      if(!s.prescription.exercises.some(e=>Number(e.id)===exerciseID))fail('invalid_set');
      await conn.query('DELETE FROM workout_sets WHERE workoutSessionID=? AND workoutExerciseID=? AND setNumber=?',[s.id,exerciseID,setNumber]);
    });res.json({removed:true});
  }));
  router.put('/sessions/:id/execution',requireRole('client'),run(async(req,res)=>{
    const result=await transaction(async conn=>{
      const s=await sessionAccess(conn,req.user,req.params.id,true);
      if(s.status!=='active')fail('workout_closed',409);
      if(integer(req.body.revision)!==Number(s.revision))fail('session_changed',409);
      const days=validatePlan({name:'Session',clientID:s.clientID,status:'draft',days:[{name:'Session',exercises:req.body.exercises}]}).days;
      const saved=await sessionSets(conn,s.id), existing=s.prescription.exercises;
      const result=[];let nextID=Math.max(0,...existing.map(e=>Number(e.id)),...s.originalPrescription.exercises.map(e=>Number(e.id)))+1;
      for(let i=0;i<days[0].exercises.length;i++){
        const e=days[0].exercises[i], supplied=req.body.exercises[i].id;
        const old=supplied?existing.find(e=>Number(e.id)===integer(supplied)):null;
        if(supplied&&!old)fail('invalid_workout');
        const recorded=saved.filter(v=>Number(v.workoutExerciseID)===Number(old?.id));
        if(recorded.length&&(old.exerciseType!==(e.configuration.mode??old.exerciseType)||Boolean(old.isBodyweight)!==Boolean(e.configuration.bodyweight??old.isBodyweight)||Number(old.exerciseID)!==e.exerciseID||Math.max(0,...recorded.filter(isWorkSet).map(v=>v.setNumber))>e.targetSets))fail('recorded_exercise',409);
        const catalog=exerciseForPrescription(await visibleExercise(conn,req.user,e.exerciseID),e.configuration);
        if(catalog.exerciseType==='reps'?e.targetReps==null||e.targetDurationSeconds!=null:e.targetDurationSeconds==null||e.targetReps!=null)fail('invalid_target');
        result.push({...catalog,...e,id:old?.id??nextID++,instructions:json(catalog.instructions),secondaryMuscles:json(catalog.secondaryMuscles)||[]});
      }
      if(new Set(result.map(e=>Number(e.id))).size!==result.length)fail('invalid_workout');
      if(saved.some(v=>!result.some(e=>Number(e.id)===Number(v.workoutExerciseID))))fail('recorded_exercise',409);
      await conn.query('UPDATE workout_sessions SET execution=?,revision=revision+1,notes=? WHERE id=?',[JSON.stringify(result),text(req.body.notes??s.notes,5000),s.id]);
      return {saved:true,revision:Number(s.revision)+1};
    });res.json(result);
  }));
  router.put('/sessions/:id/rest-alert',requireRole('client'),run(async(req,res)=>{
    if(req.body.kind!=null&&!['rest','work'].includes(req.body.kind))fail('invalid_workout');
    const seconds=req.body.seconds==null?0:integer(req.body.seconds,0,86400);
    const alertBody=req.body.kind==='work'?'Timed set complete':'Rest complete — ready for your next set';
    await transaction(async conn=>{
      // Serialize with finish/cancel so a delayed request cannot recreate an
      // alert after the completion transaction has removed it.
      const s=await sessionAccess(conn,req.user,req.params.id,true);
      if(s.status!=='active'&&seconds>0)fail('workout_closed',409);
      if(!seconds)await conn.query('DELETE FROM workout_alerts WHERE userID=? AND alertKey=?',[req.user.id,`rest:${s.id}`]);
      else await conn.query(`INSERT INTO workout_alerts (userID,sessionID,alertKey,dueAt,title,body) VALUES (?,?,?,DATE_ADD(UTC_TIMESTAMP(),INTERVAL ? SECOND),'SIRVYA Workout',?) ON DUPLICATE KEY UPDATE dueAt=VALUES(dueAt),body=VALUES(body),deliveredAt=NULL,claimedAt=NULL`,[req.user.id,s.id,`rest:${s.id}`,seconds,alertBody]);
    });
    res.json({saved:true});
  }));
  router.put('/sessions/:id', requireRole('client'), run(async (req, res) => {
    if (!['completed', 'cancelled'].includes(req.body.status)) fail('invalid_workout');
    const result = await transaction(async conn => {
      const s = await sessionAccess(conn, req.user, req.params.id, true);
      const sets = await sessionSets(conn, s.id);
      if (s.status !== 'active' && s.status !== req.body.status) fail('workout_closed', 409);
      const expected = s.prescription.exercises.reduce((n, e) => n + e.targetSets, 0);
      if (req.body.status === 'completed' && (!sets.some(isWorkSet) || sets.filter(isWorkSet).length < expected && req.body.allowIncomplete !== true)) fail('incomplete_workout', 409);
      let newPRs = 0;const loadRecords=[],estimatedRecords=[];
      if (req.body.status === 'completed') {
        for (const e of new Map(s.prescription.exercises.map(e => [Number(e.exerciseID), e])).values()) {
          const current = sets.filter(v => Number(v.exerciseID) === Number(e.exerciseID)&&isWorkSet(v));
          const [past] = await conn.query(`SELECT ws.* FROM workout_sets ws JOIN workout_sessions s ON s.id = ws.workoutSessionID
            WHERE s.clientID = ? AND s.status = 'completed' AND s.id <> ? AND s.startedAt<=? AND ws.exerciseID = ?`, [s.clientID, s.id,s.startedAt, e.exerciseID]);
          const score = v => e.exerciseType !== 'reps' ? Number(v.durationSeconds || 0) : e.isBodyweight ? Number(v.reps || 0) : estimated1RM(v, e) || 0;
          const previous=past.filter(isWorkSet),volumes=new Map();
          for(const v of previous)volumes.set(v.workoutSessionID,(volumes.get(v.workoutSessionID)||0)+setVolume(v,e));
          const loaded=e.exerciseType==='reps'&&current.some(v=>Number(v.weight)>0);
          const currentLoad=Math.max(0,...current.map(v=>Number(v.weight)||0)),previousLoad=Math.max(0,...previous.map(v=>Number(v.weight)||0));
          if(loaded&&currentLoad>previousLoad)loadRecords.push({exerciseID:e.exerciseID,name:e.name,weight:currentLoad});
          const currentRM=Math.max(0,...current.map(v=>estimated1RM(v,e)||0)),previousRM=Math.max(0,...previous.map(v=>estimated1RM(v,e)||0));
          if(currentRM>previousRM)estimatedRecords.push({exerciseID:e.exerciseID,name:e.name,estimated1RM:currentRM});
          if (Math.max(0, ...current.map(score)) > Math.max(0, ...previous.map(score)) || loaded&&(Math.max(0,...current.map(v=>Number(v.weight)))>Math.max(0,...previous.map(v=>Number(v.weight)))||current.reduce((n,v)=>n+setVolume(v,e),0)>Math.max(0,...volumes.values()))) newPRs++;
        }
      }
      if (s.status === 'active') {
        const historical=s.originalPrescription.historical===true;
        const duration=historical?integer(req.body.durationSeconds??0,0,604800):Math.max(0,Math.floor((Date.now()-new Date(s.startedAt).getTime())/1000));
        const completedAt=historical?new Date(new Date(s.startedAt).getTime()+duration*1000):new Date();
        await conn.query('UPDATE workout_sessions SET status=?,activeClientID=NULL,completedAt=?,durationSeconds=?,notes=? WHERE id=?',[req.body.status,completedAt,duration,text(req.body.notes,5000),s.id]);
        if(historical)await conn.query('UPDATE workout_sets SET completedAt=? WHERE workoutSessionID=?',[completedAt,s.id]);
      }
      await conn.query('DELETE FROM workout_alerts WHERE userID=? AND sessionID=?',[req.user.id,s.id]);
      const [updated] = await conn.query('SELECT durationSeconds, completedAt FROM workout_sessions WHERE id = ?', [s.id]);
      return {...summarize(sets, s.prescription), ...updated[0], newPRs,loadRecords,estimatedRecords, status: req.body.status};
    });
    res.json(result);
  }));
  router.put('/sessions/:id/history',requireRole('client'),run(async(req,res)=>{
    await transaction(async conn=>{
      const s=await sessionAccess(conn,req.user,req.params.id,true);
      if(s.status!=='completed')fail('workout_closed',409);
      if(integer(req.body.revision)!==Number(s.revision))fail('session_changed',409);
      if(req.body.startedAt!=null&&typeof req.body.startedAt!=='string')fail('invalid_workout');
      const started=new Date(req.body.startedAt??s.startedAt);
      if(Number.isNaN(started.getTime())||started>Date.now()+60000)fail('invalid_workout');
      const duration=integer(req.body.durationSeconds??s.durationSeconds,0,604800);
      if(req.body.sets){
        if(!Array.isArray(req.body.sets)||req.body.sets.length>1500)fail('invalid_set');
        const identities=new Set();
        await conn.query('DELETE FROM workout_sets WHERE workoutSessionID=?',[s.id]);
        for(const row of req.body.sets){
          if(!row||typeof row!=='object'||Array.isArray(row))fail('invalid_set');
          const e=s.prescription.exercises.find(e=>Number(e.id)===integer(row.workoutExerciseID));if(!e)fail('invalid_set');
          const v=validateSet(row,e),key=`${e.id}:${v.setNumber}`;if(identities.has(key))fail('invalid_set');identities.add(key);
          await conn.query(`INSERT INTO workout_sets (workoutSessionID,workoutExerciseID,exerciseID,setNumber,reps,weight,durationSeconds,rpe,rir,details) VALUES (?,?,?,?,?,?,?,?,?,?)`,[s.id,e.id,e.exerciseID,v.setNumber,v.reps,v.weight,v.durationSeconds,v.rpe,v.rir,JSON.stringify(v.details)]);
        }
        if(!identities.size)fail('incomplete_workout');
      }
      await conn.query('UPDATE workout_sessions SET startedAt=?,durationSeconds=?,completedAt=?,notes=?,excludedFromProgression=?,revision=revision+1 WHERE id=?',[started,duration,new Date(started.getTime()+duration*1000),text(req.body.notes??s.notes,5000),req.body.excludedFromProgression===true?1:0,s.id]);
    });res.json({saved:true});
  }));
  router.delete('/sessions/:id',requireRole('client'),run(async(req,res)=>{
    await transaction(async conn=>{const s=await sessionAccess(conn,req.user,req.params.id,true);if(s.status==='active')fail('workout_closed',409);await conn.query('DELETE FROM workout_sessions WHERE id=?',[s.id]);});res.json({deleted:true});
  }));
  router.get('/history', run(async (req, res) => {
    const clientID = await clientScope(req); const page = integer(req.query.page ?? 1, 1, 10000);
    const [rows] = await db.query(`SELECT s.* FROM workout_sessions s JOIN workout_plans p ON p.id = s.workoutPlanID
      WHERE s.clientID = ? AND s.status = 'completed'
      ORDER BY s.startedAt DESC, s.id DESC LIMIT 31 OFFSET ?`, [clientID, (page - 1) * 30]);
    const data = [];
    const sets=await readSessionSets(db,rows.slice(0,30).map(s=>s.id)),bySession=new Map();
    for(const set of sets){const id=Number(set.workoutSessionID);if(!bySession.has(id))bySession.set(id,[]);bySession.get(id).push(set);}
    for (const s of rows.slice(0, 30)) { const p = {...json(s.prescription)};if(s.execution)p.exercises=json(s.execution); data.push({...s, prescription: p, summary: summarize(bySession.get(Number(s.id))??[], p)}); }
    res.json({data, hasMore: rows.length > 30});
  }));
  router.get('/stats', run(async (req, res) => {
    const clientID = await clientScope(req);
    const period=req.query.days==null?null:integer(req.query.days,1,3650);
    const [sessions] = await db.query(`SELECT s.* FROM workout_sessions s JOIN workout_plans p ON p.id = s.workoutPlanID
      WHERE s.clientID = ? AND s.status = 'completed' ORDER BY s.startedAt, s.id`, [clientID]);
    const [allSets] = await db.query(`SELECT ws.* FROM workout_sets ws
      JOIN workout_sessions s ON s.id = ws.workoutSessionID JOIN workout_plans p ON p.id = s.workoutPlanID
      WHERE s.clientID = ? AND s.status = 'completed'`, [clientID]);
    const [weightRows]=await db.query("SELECT id,weight,note,DATE_FORMAT(recordedAt,'%Y-%m-%d') AS recordedAt,createdAt FROM weighthistory WHERE clientID=? ORDER BY recordedAt DESC,id DESC",[clientID]);
    const seenWeightDays=new Set();const bodyweight=weightRows.filter(r=>{if(seenWeightDays.has(r.recordedAt))return false;seenWeightDays.add(r.recordedAt);return true;});
    const days=await readWeeklyDays(db,clientID);
    const planned=new Set(days.filter(d=>d.dayOfWeek!=null).map(d=>Number(d.dayOfWeek)));
    const now=new Date(),start=new Date(now.getTime()-(Math.min(period??30,3650)-1)*86400000).toISOString().slice(0,10),end=now.toISOString().slice(0,10);
    const [overrides]=await db.query("SELECT DATE_FORMAT(workoutDate,'%Y-%m-%d') AS date FROM workout_schedule_dates WHERE userID=? AND workoutDate>=? AND workoutDate<=?",[clientID,start,end]);
    const [scheduled]=await db.query("SELECT DATE_FORMAT(workoutDate,'%Y-%m-%d') AS date,workoutDayID FROM workout_schedule WHERE userID=? AND workoutDate>=? AND workoutDate<=?",[clientID,start,end]);
    const [[prefs]]=await db.query('SELECT preferences FROM workout_preferences WHERE userID=?',[clientID]);
    const timeZone=prefs?json(prefs.preferences).timeZone:'UTC';
    const adherence=scheduleAdherence(sessions,days,overrides,scheduled,{start,end,timeZone});
    const all=buildTrainingStats(sessions,allSets,{now,bodyweight:Number(bodyweight[0]?.weight)||null,timeZone});
    const currentMonth=new Intl.DateTimeFormat('en-CA',{timeZone,year:'numeric',month:'2-digit'}).format(now);
    const weight30=bodyweight.filter(r=>new Date(r.recordedAt)>=new Date(now.getTime()-30*86400000));
    const localToday=new Intl.DateTimeFormat('en-CA',{timeZone,year:'numeric',month:'2-digit',day:'2-digit'}).format(now);
    const monday=new Date(`${localToday}T12:00:00Z`);monday.setUTCDate(monday.getUTCDate()-(monday.getUTCDay()+6)%7);
    const weekStart=monday.toISOString().slice(0,10);
    const weekSessions=req.query.window==='week'?sessions.filter(s=>new Intl.DateTimeFormat('en-CA',{timeZone,year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date(s.startedAt))>=weekStart):null;
    const stats=weekSessions?buildTrainingStats(weekSessions,allSets,{now,bodyweight:Number(bodyweight[0]?.weight)||null,timeZone}):period?buildTrainingStats(sessions,allSets,{now,bodyweight:Number(bodyweight[0]?.weight)||null,timeZone,since:new Date(now.getTime()-period*86400000)}):all;
    res.json({...stats,overview:{workoutCount:all.workoutCount,monthWorkouts:all.frequency.filter(f=>f.date.startsWith(currentMonth)).reduce((n,f)=>n+f.count,0),
      weeklyStreak:all.currentWeeklyStreak,bodyweightDelta30:weight30.length>1?Number(weight30[0].weight)-Number(weight30.at(-1).weight):null},
      yearActivity:all.activity,bodyweight:bodyweight.reverse(),bodyweightGoal:prefs?json(prefs.preferences).bodyweightGoal:null,plannedDaysPerWeek:planned.size,adherence});
  }));
  installWorkoutBackup(router,db,{run,transaction,visibleExercise,importPlan,...historyTransfer});
  return router;
}
