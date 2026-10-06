import {buildEffortStats} from './workoutEffort.js';
import {workoutMuscleWeights,workoutMuscleNames} from './workoutMuscles.js';
import {json,summarize,isWorkSet,setDetails,setVolume,estimated1RM} from './workoutDomain.js';

export function buildTrainingStats(sessions,allSets,{now=new Date(),bodyweight=null,since=null,timeZone='UTC'}={}) {
  sessions=[...sessions].sort((a,b)=>new Date(a.startedAt)-new Date(b.startedAt)||Number(a.id)-Number(b.id));
  const baselineSessions=since?sessions.filter(s=>new Date(s.startedAt)<since):[];
  const baseline=baselineSessions.length?buildTrainingStats(baselineSessions,allSets,{now,bodyweight,timeZone}):null;
  if(since)sessions=sessions.filter(s=>new Date(s.startedAt)>=since);
  const bySession=new Map();for(const s of allSets){const id=Number(s.workoutSessionID);if(!bySession.has(id))bySession.set(id,[]);bySession.get(id).push(s);}
  const records=new Map((baseline?.records??[]).map(r=>[Number(r.exerciseID),{...r,points:[]}])),frequency=new Map(),activity=[],muscles=new Map(),effort={rpe:[],rir:[]},personalRecords=[];
  const recordedBefore=new Set(records.keys());
  const localDate=new Intl.DateTimeFormat('en-CA',{timeZone,year:'numeric',month:'2-digit',day:'2-digit'});
  let volume=0,setCount=0,totalReps=0,hardSets=0;
  for(const session of sessions){
    const prescription={...json(session.prescription)};if(session.execution)prescription.exercises=json(session.execution);
    const sets=bySession.get(Number(session.id))||[],summary=summarize(sets,prescription),date=localDate.format(new Date(session.startedAt));
    volume+=summary.volume;setCount+=sets.length;frequency.set(date,(frequency.get(date)||0)+1);
    activity.push({date,name:prescription.dayName,sessionID:session.id,durationSeconds:Number(session.durationSeconds||0),volume:summary.volume,setCount:sets.length});
    const perExercise=new Map();
    for(const exercise of prescription.exercises){
      const own=sets.filter(s=>Number(s.workoutExerciseID)===Number(exercise.id));
      if(!own.length)continue;
      if(!perExercise.has(Number(exercise.exerciseID)))perExercise.set(Number(exercise.exerciseID),{exercise,sets:[]});
      perExercise.get(Number(exercise.exerciseID)).sets.push(...own);
      const weights=workoutMuscleWeights(exercise);
      const coverage=Object.entries(weights).map(([group,weight])=>({weight,muscle:muscles.get(group)||{name:group,sets:0,hardSets:0,volume:0,lastTrainedAt:null}}));
      for(const set of own){
        const details=setDetails(set);totalReps+=Number(set.reps||0)+(details.segments||[]).reduce((n,s)=>n+Number(s.reps||0),0);
        if(!isWorkSet(set))continue;
        for(const {weight,muscle} of coverage){muscle.sets+=weight;muscle.volume+=setVolume(set,exercise)*weight;muscle.lastTrainedAt=session.startedAt;}
        if(set.rpe!=null)effort.rpe.push(Number(set.rpe));if(set.rir!=null)effort.rir.push(Number(set.rir));
        if(set.rpe!=null&&Number(set.rpe)>=7||set.rir!=null&&Number(set.rir)<=3){hardSets++;for(const {weight,muscle} of coverage)muscle.hardSets+=weight;}
      }for(const {muscle} of coverage)muscles.set(muscle.name,muscle);
    }
    for(const {exercise:e,sets:own} of perExercise.values()){
      const record=records.get(Number(e.exerciseID))||{exerciseID:e.exerciseID,name:e.name,exerciseType:e.exerciseType,isBodyweight:e.isBodyweight,weight:0,reps:0,durationSeconds:0,estimated1RM:null,bestVolume:0,bestSpeedKmh:0,repsAtLoad:{},points:[]};
      const before={...record};
      const work=own.filter(isWorkSet);if(!work.length)continue;
      let bestRM=null,bestRMSource=null;for(const set of work){
        const sides=setDetails(set).sides,entries=sides?Object.values(sides):[set];
        for(const v of entries){record.weight=Math.max(record.weight,Number(v.weight||0));record.reps=Math.max(record.reps,Number(v.reps||0));record.durationSeconds=Math.max(record.durationSeconds,Number(v.durationSeconds||0));const key=String(Number(v.weight||0));record.repsAtLoad[key]=Math.max(record.repsAtLoad[key]||0,Number(v.reps||0));}
        const rm=estimated1RM(set,e);if(rm!=null){if(rm>(record.estimated1RM||0)){record.estimated1RM=rm;record.estimated1RMSource={weight:Number(set.weight),reps:Number(set.reps),date,sessionID:session.id};}if(rm>(bestRM||0)){bestRM=rm;bestRMSource={weight:Number(set.weight),reps:Number(set.reps),date,sessionID:session.id};}}
      }
      const sessionVolume=work.reduce((n,s)=>n+setVolume(s,e),0);record.bestVolume=Math.max(record.bestVolume,sessionVolume);
      const distanceMeters=work.reduce((n,s)=>n+Number(setDetails(s).distanceMeters||0),0),durationSeconds=work.reduce((n,s)=>n+Number(s.durationSeconds||0),0);
      const speedKmh=e.exerciseType==='cardio'&&distanceMeters>0&&durationSeconds>0?distanceMeters/durationSeconds*3.6:null;
      record.bestSpeedKmh=Math.max(record.bestSpeedKmh,speedKmh||0);
      const metrics=e.exerciseType==='cardio'?['bestSpeedKmh','durationSeconds']:e.exerciseType!=='reps'?['durationSeconds']:e.isBodyweight?['reps']:['weight','estimated1RM','bestVolume'];
      const improved=metrics.filter(k=>Number(record[k]||0)>Number(before[k]||0));
      if(improved.length)personalRecords.push({sessionID:session.id,exerciseID:e.exerciseID,name:e.name,date,metrics:improved,firstRecorded:before.points.length===0&&!recordedBefore.has(Number(e.exerciseID))});
      record.relativeStrength=bodyweight&&record.estimated1RM?record.estimated1RM/bodyweight:null;
      record.exerciseType=e.exerciseType;record.isBodyweight=e.isBodyweight;
      record.points.push({date,exerciseType:e.exerciseType,sessionID:session.id,weight:Math.max(...work.map(s=>Number(s.weight||0))),reps:Math.max(...work.map(s=>Number(s.reps||0))),durationSeconds:Math.max(...work.map(s=>Number(s.durationSeconds||0))),estimated1RM:bestRM,estimated1RMSource:bestRMSource,volume:sessionVolume,distanceMeters,speedKmh});
      records.set(Number(e.exerciseID),record);
    }
  }
  const totalDurationSeconds=sessions.reduce((n,s)=>n+Number(s.durationSeconds||0),0);
  const trainingDates=[...frequency.keys()].sort();let longestStreak=0,currentStreak=0,previousDate;
  for(const date of trainingDates){currentStreak=previousDate&&new Date(date)-new Date(previousDate)===86400000?currentStreak+1:1;longestStreak=Math.max(longestStreak,currentStreak);previousDate=date;}
  if(!previousDate||new Date(localDate.format(now))-new Date(previousDate)>86400000)currentStreak=0;
  const monday=date=>{const d=new Date(`${date}T12:00:00Z`);d.setUTCDate(d.getUTCDate()-(d.getUTCDay()+6)%7);return d.toISOString().slice(0,10);};
  const weeks=[...new Set(trainingDates.map(monday))].sort();let longestWeeklyStreak=0,currentWeeklyStreak=0,previousWeek;
  for(const week of weeks){currentWeeklyStreak=previousWeek&&new Date(week)-new Date(previousWeek)===604800000?currentWeeklyStreak+1:1;longestWeeklyStreak=Math.max(longestWeeklyStreak,currentWeeklyStreak);previousWeek=week;}
  if(!previousWeek||new Date(monday(localDate.format(now)))-new Date(previousWeek)>604800000)currentWeeklyStreak=0;
  const recent=activity.filter(a=>new Date(a.date)>=new Date(now.getTime()-7*86400000)),prior=activity.filter(a=>new Date(a.date)<new Date(now.getTime()-7*86400000)&&new Date(a.date)>=new Date(now.getTime()-14*86400000));
  const workload={recentSets:recent.reduce((n,a)=>n+a.setCount,0),previousSets:prior.reduce((n,a)=>n+a.setCount,0),recentVolume:recent.reduce((n,a)=>n+a.volume,0),previousVolume:prior.reduce((n,a)=>n+a.volume,0)};
  const effortDistribution=Object.fromEntries(['rpe','rir'].map(k=>[k,effort[k].reduce((bins,v)=>{const key=String(Math.floor(v));bins[key]=(bins[key]||0)+1;return bins;},{})]));
  return {workoutCount:sessions.length,setCount,volume,totalReps,hardSets,totalDurationSeconds,averageDurationSeconds:sessions.length?Math.round(totalDurationSeconds/sessions.length):0,
    effortSummary:buildEffortStats(sessions,allSets,{timeZone}),missedMuscles:workoutMuscleNames.filter(m=>!muscles.has(m)),
    frequency:[...frequency].map(([date,count])=>({date,count})),activity,records:[...records.values()].filter(r=>r.points.length),muscles:[...muscles.values()].sort((a,b)=>b.sets-a.sets),effort,effortDistribution,personalRecords,prCount:personalRecords.length,longestStreak,currentStreak,longestWeeklyStreak,currentWeeklyStreak,workload};
}

// Schedule adherence is measured against the currently assigned schedule.
// Historical plan changes cannot reliably reconstruct past obligations.
export function scheduleAdherence(sessions,days,overrides,scheduled,{start,end,timeZone='UTC'}){
  const completed=new Map();
  for(const s of sessions){const date=new Intl.DateTimeFormat('en-CA',{timeZone,year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date(s.startedAt));const ids=json(s.prescription).sourceDayIDs??[s.workoutDayID];if(!completed.has(date))completed.set(date,new Set());for(const id of ids)completed.get(date).add(Number(id));}
  const dates=new Set(overrides.map(r=>r.date)),missed=[];let expected=0,performed=0;
  for(let day=new Date(`${start}T12:00:00Z`);day<=new Date(`${end}T12:00:00Z`);day=new Date(day.getTime()+86400000)){
    const date=day.toISOString().slice(0,10),weekday=day.getUTCDay()||7;
    const required=dates.has(date)?scheduled.filter(r=>r.date===date).map(r=>Number(r.workoutDayID)):days.filter(r=>Number(r.dayOfWeek)===weekday).map(r=>Number(r.id));
    for(const id of new Set(required)){expected++;if(completed.get(date)?.has(id))performed++;else missed.push({date,workoutDayID:id});}
  }return {expected,performed,percent:expected?Math.round(performed/expected*100):null,missed};
}
