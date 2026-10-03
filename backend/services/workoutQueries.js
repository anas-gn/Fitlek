import {json} from './workoutDomain.js';

// Batch relational reads keep dashboard/history request counts independent of
// the number of plans, sessions and exercises displayed.
export async function readPlanDetails(conn, plans) {
  if (!plans.length) return [];
  const ids=plans.map(p=>p.id);
  const [days]=await conn.query('SELECT * FROM workout_days WHERE workoutPlanID IN (?) ORDER BY sortOrder,id',[ids]);
  const [rows]=await conn.query(`SELECT we.*,e.name,e.muscleGroup,e.equipment,e.exerciseType,e.isBodyweight,e.isTimed,
    e.instructions,e.imageUrl,e.videoUrl FROM workout_exercises we JOIN exercises e ON e.id=we.exerciseID
    JOIN workout_days d ON d.id=we.workoutDayID WHERE d.workoutPlanID IN (?) ORDER BY we.sortOrder,we.id`,[ids]);
  const exercises=new Map(),byPlan=new Map();
  for(const row of rows){const id=Number(row.workoutDayID);if(!exercises.has(id))exercises.set(id,[]);
    exercises.get(id).push({...row,configuration:row.configuration?json(row.configuration):{},instructions:json(row.instructions)});}
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
  const [rows]=await conn.query(`SELECT ws.*,s.startedAt FROM workout_sets ws JOIN workout_sessions s ON s.id=ws.workoutSessionID
    WHERE s.clientID=? AND s.status='completed' AND ws.exerciseID IN (?)
    AND s.id=(SELECT s2.id FROM workout_sessions s2 JOIN workout_sets w2 ON w2.workoutSessionID=s2.id
      WHERE s2.clientID=? AND s2.status='completed' AND w2.exerciseID=ws.exerciseID
      AND (s2.startedAt<? OR (s2.startedAt=? AND s2.id<?)) ORDER BY s2.startedAt DESC,s2.id DESC LIMIT 1)
    ORDER BY ws.exerciseID,ws.workoutExerciseID,ws.setNumber`,[session.clientID,ids,session.clientID,session.startedAt,session.startedAt,session.id]);
  const result=Object.fromEntries(ids.map(id=>[id,[]]));
  for(const row of rows)result[row.exerciseID].push(row);
  return result;
}
