import {json,exerciseForPrescription} from './workoutDomain.js';

// Explicit weekday assignments override only that weekday. Existing assigned
// programs remain the fallback, including Coach routines the Client cannot edit.
export async function readWeeklyDays(conn, userID) {
  const allowed="p.clientID=? AND p.status='assigned' AND (p.coachID IS NULL OR EXISTS (SELECT 1 FROM coachclients cc WHERE cc.coachID=p.coachID AND cc.clientID=p.clientID))";
  const [rows]=await conn.query(`SELECT d.id,d.name,d.dayOfWeek FROM workout_days d
    JOIN workout_plans p ON p.id=d.workoutPlanID WHERE ${allowed} AND d.dayOfWeek IS NOT NULL
    AND NOT EXISTS(SELECT 1 FROM workout_week_days wd WHERE wd.userID=? AND wd.weekday=d.dayOfWeek)
    UNION ALL SELECT d.id,d.name,ws.weekday AS dayOfWeek FROM workout_week_schedule ws
    JOIN workout_days d ON d.id=ws.workoutDayID JOIN workout_plans p ON p.id=d.workoutPlanID
    WHERE ws.userID=? AND ${allowed}`,[userID,userID,userID,userID]);
  return rows;
}

// Batch relational reads keep dashboard/history request counts independent of
// the number of plans, sessions and exercises displayed.
export async function readPlanDetails(conn, plans) {
  if (!plans.length) return [];
  const ids=plans.map(p=>p.id);
  const [days]=await conn.query('SELECT * FROM workout_days WHERE workoutPlanID IN (?) ORDER BY sortOrder,id',[ids]);
  const [rows]=await conn.query(`SELECT we.*,e.name,e.muscleGroup,e.equipment,e.exerciseType,e.isBodyweight,e.isTimed,
    e.instructions,e.imageUrl,e.videoUrl,e.externalSource,e.externalId,e.bodyPart,e.secondaryMuscles,e.description FROM workout_exercises we JOIN exercises e ON e.id=we.exerciseID
    JOIN workout_days d ON d.id=we.workoutDayID WHERE d.workoutPlanID IN (?) ORDER BY we.sortOrder,we.id`,[ids]);
  const exercises=new Map(),byPlan=new Map();
  for(const row of rows){const id=Number(row.workoutDayID);if(!exercises.has(id))exercises.set(id,[]);
    exercises.get(id).push({...exerciseForPrescription(row,row.configuration),configuration:row.configuration?json(row.configuration):{},instructions:json(row.instructions),secondaryMuscles:json(row.secondaryMuscles)||[]});}
  for(const day of days){const id=Number(day.workoutPlanID);if(!byPlan.has(id))byPlan.set(id,[]);
    byPlan.get(id).push({...day,configuration:day.configuration?json(day.configuration):{},exercises:exercises.get(Number(day.id))??[]});}
  return plans.map(p=>({...p,days:byPlan.get(Number(p.id))??[]}));
}

export async function readSessionSets(conn, ids) {
  if(!ids.length)return [];
  const [rows]=await conn.query('SELECT * FROM workout_sets WHERE workoutSessionID IN (?) ORDER BY workoutExerciseID,setNumber',[ids]);
  return rows.map(s=>({...s,details:s.details?json(s.details):{phase:'work',type:'straight'}}));
}

export async function readPreviousPerformance(conn, session) {
  const ids=[...new Set(session.prescription.exercises.map(e=>Number(e.exerciseID)))];
  if(!ids.length)return {};
  const [rows]=await conn.query(`SELECT ws.*,s.startedAt,s.prescription,s.execution FROM workout_sets ws JOIN workout_sessions s ON s.id=ws.workoutSessionID
    WHERE s.clientID=? AND s.status='completed' AND ws.exerciseID IN (?)
    AND s.id=(SELECT s2.id FROM workout_sessions s2 JOIN workout_sets w2 ON w2.workoutSessionID=s2.id
      WHERE s2.clientID=? AND s2.status='completed' AND w2.exerciseID=ws.exerciseID
      AND (s2.startedAt<? OR (s2.startedAt=? AND s2.id<?)) ORDER BY s2.startedAt DESC,s2.id DESC LIMIT 1)
    ORDER BY ws.exerciseID,ws.workoutExerciseID,ws.setNumber`,[session.clientID,ids,session.clientID,session.startedAt,session.startedAt,session.id]);
  const result=Object.fromEntries(ids.map(id=>[id,[]]));
  for(const row of rows){
    const {prescription,execution,...set}=row;
    const entries=execution?json(execution):(json(prescription)?.exercises??[]);
    const target=entries.find(e=>Number(e.id)===Number(row.workoutExerciseID));
    result[row.exerciseID].push({...set,exerciseType:target?.exerciseType,details:row.details?json(row.details):{}});
  }
  return result;
}
