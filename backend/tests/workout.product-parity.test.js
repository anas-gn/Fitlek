import test from 'node:test';
import assert from 'node:assert/strict';
import {nextTarget,defaultWorkoutPreferences,validatePreferences} from '../services/workoutExperience.js';
import {validateConfiguration,validateSet,validatePlan,validateCustomExercise} from '../services/workoutDomain.js';
import {buildEffortStats} from '../services/workoutEffort.js';
import {parseWorkoutCSV} from '../services/workoutImport.js';
import {openGymWorkoutProgram} from '../services/workoutProgram.js';

test('openGym v1 export retains modes, units, progression, customs and Sunday without identity data',()=>{
  const built={externalSource:'exercises-dataset',externalId:'0025',name:'Bench',bodyPart:'chest',muscleGroup:'pectorals',equipment:'barbell',exerciseType:'reps',isBodyweight:false,instructions:[]};
  const hold={...built,externalSource:'sirvya-custom',externalId:'private-123',name:'Custom hold',bodyPart:'waist',description:'Stay straight'};
  const bundle={plan:{format:'sirvya-workout-plan',version:1,name:'Strength',days:[
    {name:'Lift',configuration:{progression:'linear'},exercises:[{exercise:built,targetSets:3,targetReps:10,targetWeight:60,
      configuration:{mode:'reps',perSide:true,progression:'double',increment:2.5,minReps:8,bodyweightRepCeiling:12},supersetGroup:'a'}]},
    {name:'Hold',exercises:[{exercise:hold,targetSets:2,targetDurationSeconds:45,targetWeight:0,configuration:{mode:'timed',progression:'time',increment:5}}]},
    {name:'Ride',exercises:[{exercise:{...hold,externalId:'private-456',name:'Ride',bodyPart:'cardio'},targetSets:1,targetDurationSeconds:1200,
      configuration:{mode:'cardio',speedKmh:12}}]}
  ]},week:{1:[0],7:[1]}};
  const exported=openGymWorkoutProgram(bundle,{exported:'2026-10-05'});
  assert.equal(exported.opengym_plan,1);assert.equal(exported.week[0],'routine-2');
  assert.equal(exported.routines[0].prog,'linear');assert.equal(exported.routines[0].ex[0].prog,'double');
  assert.equal(exported.routines[0].ex[0].weight,60);assert.equal(exported.routines[0].ex[0].side,true);
  assert.equal(exported.routines[1].ex[0].mode,'time');assert.equal(exported.routines[2].ex[0].min,20);
  assert.equal(exported.customEx[0].n,'Custom hold');assert.equal(exported.customEx[0].desc,'Stay straight');
  assert.equal(JSON.stringify(exported).includes('private-123'),false);
  const parsed=parseWorkoutProgram(exported,[built]);
  assert.equal(parsed.dropped,0);assert.equal(parsed.plan.days[0].exercises[0].configuration.progression,'double');
  assert.equal(parsed.plan.days[1].exercises[0].targetDurationSeconds,45);
  assert.equal(parsed.plan.days[2].exercises[0].configuration.speedKmh,12);
  assert.deepEqual(parsed.week,{1:[0],7:[1]});
  const combined=openGymWorkoutProgram({...bundle,week:{2:[0,1]}});
  assert.equal(combined.routines.at(-1).ex.length,2);
  assert.equal(parseWorkoutProgram(combined,[built]).scheduledDays,1);
});

test('reference half-point RIR survives validation/import and stays independent of training calculations',()=>{
  const prescribed={exerciseType:'reps',targetSets:5,isBodyweight:false};
  const sets=[0,.5,1.5,3.5,4.5].map((rir,i)=>({...validateSet({setNumber:i+1,reps:10,weight:60,rir},prescribed),workoutSessionID:1,exerciseID:2}));
  const stats=buildEffortStats([{id:1,startedAt:'2026-10-01T10:00:00Z'}],sets);
  assert.equal(stats.averageRir,2);assert.equal(stats.hardPercent,60);
  assert.equal(stats.weeks[0].rir,2);
  assert.equal(validateConfiguration({targetRir:1.5}).targetRir,1.5);
  const imported=parseWorkoutCSV('Date,Workout Name,Exercise Name,Weight,Reps,RIR,RPE\n2026-10-01 10:00:00,Push,Bench,60,10,1.5,8');
  assert.equal(imported.sessions[0].exercises[0].sets[0].rir,1.5);
  assert.equal(imported.sessions[0].exercises[0].sets[0].rpe,null);
});

test('reference per-side targets are even totals and timed mode removes the flag',()=>{
  const slot={exerciseID:1,targetSets:3,targetReps:15,targetWeight:0,configuration:{perSide:true,mode:'reps'}};
  const input={name:'Unilateral',clientID:1,days:[{name:'Lunges',exercises:[slot]}]};
  assert.equal(validatePlan(input).days[0].exercises[0].targetReps,16);
  const timed=validatePlan({...input,days:[{name:'Hold',exercises:[{...slot,targetReps:null,targetDurationSeconds:45,configuration:{perSide:true,mode:'timed'}}]}]});
  assert.equal(timed.days[0].exercises[0].configuration.perSide,false);
});

// Expected behaviors audited from the requested openGym c42ba6b fork's
// lib/progression.js, not from historical SIRVYA expectations.
const lift = {exerciseType:'reps',targetSets:2,targetReps:10,targetWeight:60,
  configuration:{progression:'linear',increment:2.5}};
const session = (target, weights, reps) => ({target,sets:weights.map((weight,i)=>({weight,reps:reps[i]}))});

test('personal double progression judges the last target, including reduced targets',()=>{
  const e={...lift,configuration:{progression:'double',minReps:8,increment:2.5}};
  const reduced={...e,targetReps:8};
  const successful=session(reduced,[65,65],[8,8]);
  const next=nextTarget(e,[successful],{sharedHistory:true});
  assert.equal(next.weight,67.5);assert.equal(next.reps,8);
  const miss=session(e,[65,65],[7,7]);
  const following=nextTarget(e,[miss,successful,miss],{sharedHistory:true});
  assert.equal(following.weight,65);
  assert.equal(following.reason,'increase_reps');
  const stalled=nextTarget(e,[miss,miss,miss],{sharedHistory:true});
  assert.equal(stalled.weight,57.5);
  assert.equal(stalled.reason,'deload');
});

test('minimal custom cardio uses time and speed, including shared plan import',()=>{
  const cardio=validateCustomExercise({name:'Outdoor ride',bodyPart:'cardio'});
  assert.equal(cardio.exerciseType,'cardio');assert.equal(cardio.equipment,'custom');
  const hold=validateCustomExercise({name:'Held pose',bodyPart:'cardio',exerciseType:'timed'});
  assert.equal(hold.exerciseType,'timed');
  const preview=parseWorkoutProgram({opengym_plan:1,customEx:[{id:'ride',n:'Outdoor ride',bp:'cardio'}],
    routines:[{id:'bike',name:'Bike',ex:[{id:'ride',sets:1,min:20,speed:12}]}]},[]);
  const entry=preview.plan.days[0].exercises[0];
  assert.equal(entry.exercise.exerciseType,'cardio');assert.equal(entry.exercise.isBodyweight,false);
  assert.equal(entry.exercise.equipment,'custom');assert.equal(entry.targetDurationSeconds,1200);
  assert.equal(entry.configuration.speedKmh,12);
});

test('legacy guided defaults migrate without losing options or explicit later view choices',()=>{
  const p=validatePreferences({view:'guided',unit:'lb',bodyweightGoal:80,keepAwake:false});
  assert.equal(p.view,'cards');assert.equal(p.viewVersion,2);
  assert.equal(p.unit,'lb');assert.equal(p.bodyweightGoal,80);assert.equal(p.keepAwake,false);
  assert.deepEqual(validatePreferences(p),p);
  assert.equal(validatePreferences({view:'guided',viewVersion:2}).view,'guided');
  assert.equal(validatePreferences({view:'compact'}).view,'compact');
  assert.throws(()=>validatePreferences({viewVersion:3}));
});
test('progression uses the actual highest working load and counts incomplete sessions as misses',()=>{
  assert.equal(nextTarget(lift,[session(lift,[65,65],[10,10])]).weight,67.5);
  assert.equal(nextTarget(lift,[session(lift,[55,55],[10,10])]).weight,57.5);
  assert.equal(nextTarget(lift,[session(lift,[65],[10])]).reason,'repeat');
  assert.equal(nextTarget(lift,[session(lift,[65,65],[10,9])]).weight,65);
});
test('double progression builds its next rep aim from achieved minimum, then resets at a load increase',()=>{
  const e={...lift,configuration:{progression:'double',minReps:8,increment:2.5}};
  const next=nextTarget(e,[session(e,[65,65],[9,8])]);
  assert.equal(next.reps,9);assert.equal(next.weight,65);
  assert.equal(nextTarget(e,[session(e,[65,65],[10,11])]).reps,8);
  assert.equal(nextTarget(e,[session(e,[65,65],[10,11])]).weight,67.5);
});
test('deload snaps to loadable increments and time deload to five seconds',()=>{
  const miss=session(lift,[60,60],[8,8]);
  assert.equal(nextTarget(lift,[miss,miss,miss]).weight,55);
  const small={...lift,targetWeight:2.5};
  const tiny=session(small,[2.5,2.5],[8,8]);
  assert.equal(nextTarget(small,[tiny,tiny,tiny]).weight,2.5);
  const time={...lift,exerciseType:'timed',targetReps:null,targetDurationSeconds:42,
    configuration:validateConfiguration({progression:'time'})};
  const held={target:time,sets:[{durationSeconds:42},{durationSeconds:42}]};
  assert.equal(nextTarget(time,[held]).durationSeconds,47);
  const failed={target:time,sets:[{durationSeconds:38},{durationSeconds:35}]};
  assert.equal(nextTarget(time,[failed,failed,failed]).durationSeconds,40);
});
test('unloaded per-side reps advance by two; ceiling adds a set and resets to the original reps',()=>{
  const e={...lift,targetWeight:0,targetReps:8,configuration:{progression:'linear',perSide:true,bodyweightRepCeiling:12}};
  assert.equal(nextTarget(e,[session(e,[0,0],[8,8])]).reps,10);
  const atCeiling={...e,targetReps:12};
  const next=nextTarget(e,[session(atCeiling,[0,0],[12,12])]);
  assert.equal(next.sets,3);assert.equal(next.reps,8);
  assert.equal(validateConfiguration({}).bodyweightRepCeiling,0);
});
test('workout defaults include pre-start weigh-in and keeping the screen awake',()=>{
  assert.equal(defaultWorkoutPreferences.bodyweightCheckIn,true);
  assert.equal(defaultWorkoutPreferences.keepAwake,true);
  assert.equal(defaultWorkoutPreferences.view,'cards');
});

import {parseWorkoutProgram} from '../services/workoutProgram.js';
import {workoutMuscleWeights} from '../services/workoutMuscles.js';
import {estimated1RM} from '../services/workoutDomain.js';

test('share preview resolves existing IDs, preserves time/cardio/progression, reports dropped identities',()=>{
  const catalog=[{externalSource:'exercises-dataset',externalId:'0001',name:'Bench',muscleGroup:'chest',bodyPart:'chest',equipment:'barbell',exerciseType:'reps',isBodyweight:0,instructions:[]}];
  const preview=parseWorkoutProgram({opengym_plan:1,name:'Shared',week:{1:'a',0:'b'},customEx:[{id:'custom',n:'Carry',bp:'upper legs',desc:'Keep tall'}],routines:[
    {id:'a',name:'Strength',prog:'greyskull',ex:[{id:'0001',sets:3,reps:10,inc:2.5},{id:'unknown',sets:3}]},
    {id:'b',name:'Hold',ex:[{id:'custom',mode:'time',sec:45,sets:2,prog:'time',sg:'pair'}]}]},catalog);
  assert.equal(preview.dropped,1);assert.equal(preview.exerciseCount,2);
  assert.deepEqual(preview.week,{1:[0],7:[1]});
  assert.equal(preview.plan.days[0].configuration.progression,'greyskull');
  assert.equal(preview.plan.days[0].exercises[0].exercise.externalId,'0001');
  assert.equal(preview.plan.days[1].exercises[0].targetReps,null);
  assert.equal(preview.plan.days[1].exercises[0].targetDurationSeconds,45);
  assert.equal(preview.plan.days[1].exercises[0].exercise.description,'Keep tall');
  assert.throws(()=>parseWorkoutProgram({...preview,format:'sirvya-workout-program',version:1,week:{1:[99]}},catalog));
  assert.throws(()=>parseWorkoutProgram({format:'sirvya-workout-program',version:1,plan:{format:'sirvya-workout-plan',version:1,name:'Bad',days:[{name:'Bad',exercises:[{exercise:null}]}]}},catalog));
});
test('mixed effort uses RIR equivalence, a five-rating threshold and the finished-set denominator',()=>{
  const sessions=[{id:1,startedAt:'2026-10-01'},{id:2,startedAt:'2026-10-02'}];
  const sets=[{workoutSessionID:1,exerciseID:1,rir:0},{workoutSessionID:1,exerciseID:1,rpe:8},
    {workoutSessionID:1,exerciseID:1,rir:4},{workoutSessionID:2,exerciseID:1,rpe:7},
    {workoutSessionID:2,exerciseID:1,rir:1},{workoutSessionID:2,exerciseID:1},
    {workoutSessionID:2,exerciseID:1,rir:0,details:{phase:'warmup'}}];
  const stats=buildEffortStats(sessions,sets);
  assert.equal(stats.done,6);assert.equal(stats.rated,5);assert.equal(stats.averageRir,2);assert.equal(stats.hardPercent,80);
  assert.equal(stats.weeks[0].sets,6);assert.equal(stats.exercisePoints[0].rir,2);
  assert.equal(buildEffortStats(sessions,sets.slice(0,4)).averageRir,null);
});
test('effective muscle sets include secondary muscles once and custom body-part fallback',()=>{
  assert.deepEqual(workoutMuscleWeights({muscleGroup:'pectorals',secondaryMuscles:['triceps','triceps','shoulders']}),{chest:1,triceps:.4,shoulders:.4});
  assert.deepEqual(workoutMuscleWeights({externalSource:'sirvya-custom',bodyPart:'upper arms',muscleGroup:'upper arms'}),{biceps:.5,triceps:.5});
  assert.equal(estimated1RM({weight:20,reps:1},{exerciseType:'reps',isBodyweight:true}),20);
  assert.equal(estimated1RM({weight:20,reps:13},{exerciseType:'reps'}),null);
});
test('personal progression ignores another measurement mode and uses lift-specific default steps',()=>{
  const e={...lift,bodyPart:'upper legs',configuration:{progression:'linear'}};
  assert.equal(nextTarget(e,[session(e,[60,60],[10,10])]).weight,65);
  assert.equal(nextTarget(e,[{target:{...e,exerciseType:'timed'},sets:[{durationSeconds:45}]}],{sharedHistory:true}).reason,'first_session');
  const different={...e,targetWeight:40,configuration:{progression:'double'}};
  assert.equal(nextTarget(e,[session(different,[60,60],[10,10])],{sharedHistory:true}).weight,65);
});
