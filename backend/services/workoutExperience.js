// Independently implemented progression and workout-specific preferences.
import {fail, integer, number, text, json, isWorkSet} from './workoutDomain.js';

export const defaultWorkoutPreferences = Object.freeze({unit:'kg', defaultRestSeconds:90,
  restPauseSeconds:15, timerSound:true, timerVibration:true, timerFlash:false,
  automaticRest:true, keepAwake:false, bodyweightCheckIn:false, bodyweightGoal:null, view:'cards', effort:'off', weekStart:1,
  reminderEnabled:false, reminderTime:'08:00', timeZone:'UTC', equipmentProfiles:[], activeEquipmentProfile:null,
  barWeight:20,balanceAnchorID:null,balanceTargets:[],balanceProtocols:[],activeBalanceProtocolID:null,
  plates:[25,20,15,10,5,2.5,1.25].map(weight=>({weight,count:4}))});
export const balancePreferenceKeys=['balanceAnchorID','balanceTargets','balanceProtocols','activeBalanceProtocolID'];
export function balancePreferences(preferences){
  return Object.fromEntries(balancePreferenceKeys.map(k=>[k,preferences[k]??defaultWorkoutPreferences[k]]));
}
const validateBalanceTargets=targets=>{
  if(!Array.isArray(targets)||targets.length>50||targets.some(v=>!v||typeof v!=='object'||Array.isArray(v)))fail('invalid_workout');
  const rows=targets.map(v=>({exerciseID:integer(v.exerciseID),targetPercent:number(v.targetPercent,1,500)}));
  if(rows.some(v=>v.targetPercent==null)||new Set(rows.map(v=>v.exerciseID)).size!==rows.length)fail('invalid_workout');
  return rows;
};
export function validatePreferences(input) {
  if (!input || typeof input !== 'object' || Array.isArray(input)) fail('invalid_workout');
  const p={...defaultWorkoutPreferences,...input};
  if (!['kg','lb'].includes(p.unit) || !['cards','compact','guided'].includes(p.view) || !['off','rpe','rir'].includes(p.effort)) fail('invalid_workout');
  p.defaultRestSeconds=integer(p.defaultRestSeconds,0,3600); p.restPauseSeconds=integer(p.restPauseSeconds,0,300); p.weekStart=integer(p.weekStart,1,7);
  for(const key of ['timerSound','timerVibration','timerFlash','automaticRest','keepAwake','reminderEnabled','bodyweightCheckIn']) if(typeof p[key]!=='boolean') fail('invalid_workout');
  if(!/^([01]\d|2[0-3]):[0-5]\d$/.test(p.reminderTime)) fail('invalid_workout');
  try {new Intl.DateTimeFormat('en',{timeZone:p.timeZone}).format();} catch {fail('invalid_workout');}
  if(!Array.isArray(p.equipmentProfiles)||p.equipmentProfiles.length>10)fail('invalid_workout');
  if(p.equipmentProfiles.some(e=>!e||typeof e!=='object'||Array.isArray(e)||!Array.isArray(e.equipment)||e.equipment.length>40))fail('invalid_workout');
  p.equipmentProfiles=p.equipmentProfiles.map(e=>({name:text(e.name,80,true),equipment:Array.isArray(e.equipment)?e.equipment.map(v=>text(v,80,true)).slice(0,40):[]}));
  if(p.activeEquipmentProfile!=null&&!p.equipmentProfiles.some(e=>e.name===p.activeEquipmentProfile))fail('invalid_workout');
  p.barWeight=number(p.barWeight,0,100)??20;
  p.bodyweightGoal=number(p.bodyweightGoal,1,500);
  if(!Array.isArray(p.plates)||p.plates.length>20)fail('invalid_workout');
  if(p.plates.some(v=>!v||typeof v!=='object'||Array.isArray(v)))fail('invalid_workout');
  p.plates=p.plates.map(v=>({weight:number(v.weight,0.01,100),count:integer(v.count,0,40)}));
  if(p.plates.some(v=>v.weight==null))fail('invalid_workout');
  p.balanceAnchorID=p.balanceAnchorID==null?null:integer(p.balanceAnchorID);
  p.balanceTargets=validateBalanceTargets(p.balanceTargets);
  if(!Array.isArray(p.balanceProtocols)||p.balanceProtocols.length>10)fail('invalid_workout');
  p.balanceProtocols=p.balanceProtocols.map(v=>{
    if(!v||typeof v!=='object'||Array.isArray(v)||typeof v.id!=='string'||! /^[a-zA-Z0-9_-]{1,80}$/.test(v.id))fail('invalid_workout');
    return {id:v.id,name:text(v.name,80,true),anchorID:integer(v.anchorID),targets:validateBalanceTargets(v.targets)};
  });
  if(new Set(p.balanceProtocols.map(v=>v.id)).size!==p.balanceProtocols.length)fail('invalid_workout');
  if(p.activeBalanceProtocolID!=null){
    const active=p.balanceProtocols.find(v=>v.id===p.activeBalanceProtocolID);
    if(!active)fail('invalid_workout');
    p.balanceAnchorID=active.anchorID;p.balanceTargets=active.targets;
  }
  return Object.fromEntries(Object.keys(defaultWorkoutPreferences).map(k=>[k,p[k]]));
}

// Targets are suggestions generated at start; the original prescription is retained.
// Only working sets from completed sessions affect progression.
export function nextTarget(exercise, history) {
  const cfg = typeof exercise.configuration === 'string' ? json(exercise.configuration) : exercise.configuration || {};
  const policy=cfg.progression || 'off';
  const baseline={weight:Number(exercise.targetWeight || 0),reps:exercise.targetReps,sets:exercise.targetSets,durationSeconds:exercise.targetDurationSeconds};
  if(policy==='off'||policy==='inherit'||cfg.excludeFromProgression||exercise.exerciseType==='cardio')return {...baseline,reason:'prescribed',policy:'off'};
  const valid=history.filter(h=>!h.excludedFromProgression&&h.sets.some(isWorkSet)&&
    (!h.target?.originalTargets || ['targetWeight','targetReps','targetSets','targetDurationSeconds'].every(k=>Number(h.target.originalTargets[k]??0)===Number(exercise[k]??0)))&&
    (!h.target?.configuration || (typeof h.target.configuration==='string'?json(h.target.configuration):h.target.configuration).progression===policy));
  if(!valid.length)return {...baseline,reason:'first_session',policy};
  const last=valid[0]; const work=last.sets.filter(isWorkSet);
  const lastTarget=last.target || exercise;
  const reps=Number(lastTarget.targetReps || baseline.reps || 1), sets=Number(lastTarget.targetSets || baseline.sets);
  const weight=Number(lastTarget.targetWeight ?? baseline.weight), duration=Number(lastTarget.targetDurationSeconds || baseline.durationSeconds || 0);
  const met=h=>{const ss=h.sets.filter(isWorkSet);return ss.length>=Number(h.target?.targetSets||sets)&&ss.every(s=>{
    if(exercise.exerciseType!=='reps')return Number(s.durationSeconds)>=Number(h.target?.targetDurationSeconds||duration);
    const details=s.details?json(s.details):{},entries=details.sides?Object.values(details.sides):[s];
    return entries.every(v=>Number(v.reps)>=Number(h.target?.targetReps||reps)&&Number(v.weight)>=Number(h.target?.targetWeight??weight));
  });};
  let failures=0;for(const h of valid){if(met(h))break;failures++;}
  const success=met(last),factor=Number(cfg.deloadFactor||0.9),step=Number(cfg.increment||2.5);
  const base={weight,reps,sets,durationSeconds:duration||null,policy,reason:'repeat'};
  if(exercise.exerciseType!=='reps') {
    if(policy!=='time')return {...baseline,reason:'prescribed',policy:'off'};
    if(success)return {...base,durationSeconds:Math.min(86400,duration+Math.max(1,Math.round(cfg.increment||5))),reason:'increase_time'};
    return failures>=3?{...base,durationSeconds:Math.max(1,Math.round(duration*factor)),reason:'deload'}:base;
  }
  if(exercise.isBodyweight&&weight===0) {
    const ceiling=Number(cfg.bodyweightRepCeiling??30),maxSets=Number(cfg.maxBodyweightSets??6);
    if(success&&reps<ceiling)return {...base,reps:Math.min(ceiling,reps+1),reason:'increase_reps'};
    if(success&&sets<maxSets)return {...base,sets:sets+1,reason:'increase_sets'};
    return {...base,reason:success?'add_load_or_variation':'repeat'};
  }
  if(policy==='double') {
    const upper=Number(exercise.targetReps),lower=Number(cfg.minReps||Math.max(1,upper-2));
    if(success&&reps>=upper)return {...base,weight:Math.min(2000,weight+step),reps:lower,reason:'increase_load'};
    if(success)return {...base,reps:Math.min(upper,reps+1),reason:'increase_reps'};
  } else if(success) {
    const top=Number(work.at(-1)?.reps||0);
    return {...base,weight:Math.min(2000,weight+step*(policy==='greyskull'&&top>=reps*2?2:1)),reason:'increase_load'};
  }
  if(failures>=(policy==='greyskull'?1:3))return {...base,weight:Math.max(0,Math.floor(weight*factor/step)*step),reason:'deload'};
  return base;
}

export function dailyReminderKey(preferences, now=new Date()) {
  if(!preferences.reminderEnabled)return null;
  const parts=new Intl.DateTimeFormat('en-CA',{timeZone:preferences.timeZone,year:'numeric',month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit',hourCycle:'h23'}).formatToParts(now);
  const v=Object.fromEntries(parts.map(p=>[p.type,p.value]));
  if(`${v.hour}:${v.minute}`!==preferences.reminderTime)return null;
  return `daily:${v.year}-${v.month}-${v.day}`;
}
