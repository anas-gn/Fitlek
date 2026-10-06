import fs from 'node:fs';
import {buildTrainingStats} from '../services/workoutStats.js';

// Deterministic review data, never inserted into an application user's account.
const now=new Date('2026-10-04T12:00:00Z');
const exercises=[{id:11,exerciseID:1,name:'barbell bench press',muscleGroup:'pectorals',bodyPart:'chest',equipment:'barbell',exerciseType:'reps',isBodyweight:false,externalSource:'exercises-dataset',externalId:'0025',secondaryMuscles:['triceps','shoulders'],targetSets:3,targetReps:10,targetWeight:60,restSeconds:90,configuration:{progression:'off'}},
  {id:12,exerciseID:2,name:'barbell bent over row',muscleGroup:'upper back',bodyPart:'back',equipment:'barbell',exerciseType:'reps',isBodyweight:false,externalSource:'exercises-dataset',externalId:'0027',secondaryMuscles:['biceps','forearms'],targetSets:3,targetReps:10,targetWeight:40,restSeconds:90,configuration:{progression:'off'}}];
const day={id:2,name:'Full body',configuration:{progression:'off'},exercises};
const plan={id:1,clientID:42,name:'Full body',coachID:null,status:'assigned',revision:1,days:[day]};
const oldDate=new Date('2026-10-02T12:00:00Z');
const prescription={dayName:day.name,planName:plan.name,sourceDayIDs:[2],exercises};
const sets=exercises.flatMap(e=>[1,2,3].map(n=>({id:e.id*10+n,workoutSessionID:1,workoutExerciseID:e.id,exerciseID:e.exerciseID,startedAt:oldDate.toISOString(),setNumber:n,weight:e.targetWeight,reps:n===3?9:10,rir:n,details:{phase:'work',type:'straight'}})));
const session={id:1,startedAt:oldDate.toISOString(),status:'completed',durationSeconds:1800,prescription,sets,summary:{setCount:6,volume:2900}};
const stats=buildTrainingStats([session],sets,{now,bodyweight:79.5});
stats.bodyweight=[{weight:80,recordedAt:'2026-09-30T12:00:00Z'},{weight:79.5,recordedAt:'2026-10-03T12:00:00Z'}];
stats.bodyweightGoal=78;stats.yearActivity=stats.activity;
stats.overview={workoutCount:1,monthWorkouts:1,weeklyStreak:1,bodyweightDelta30:-.5};
const week=[1,3,7].map(dayOfWeek=>({id:2,name:'Full body',dayOfWeek}));
const active={id:7,startedAt:now.toISOString(),status:'active',prescription,sets:[],previous:Object.fromEntries(exercises.map(e=>[e.exerciseID,sets.filter(s=>s.exerciseID===e.exerciseID)]))};
const refExercises=exercises.map(e=>({id:e.externalId,sets:3,reps:10,weight:e.targetWeight}));
const entries=exercises.map(e=>({id:e.externalId,target:{...refExercises.find(x=>x.id===e.externalId)},sets:sets.filter(s=>s.exerciseID===e.exerciseID).map(s=>({w:s.weight,r:s.reps,rir:s.rir,done:true}))}));
const reference={theme:'light',accent:'green',unit:'kg',lang:'en',restSec:90,sound:false,keepAwake:false,effort:'rir',targetW:78,
  routines:[{id:'r1',name:'Full body',emoji:'dumbbell',prog:'off',ex:refExercises}],week:{1:'r1',3:'r1',0:'r1'},dayPlan:{},customEx:[],
  exWeights:{'0025':{w:60},'0027':{w:40}},bodyweight:stats.bodyweight.map(b=>({d:b.recordedAt.slice(0,10),t:new Date(b.recordedAt).getTime(),w:b.weight})),
  workouts:[{id:'w1',d:'2026-10-02',start:oldDate.getTime(),end:oldDate.getTime()+1800000,name:'Full body',routineId:'r1',bw:80,entries,vol:2900}],active:null};
const referenceActive={id:'w2',d:'2026-10-04',start:now.getTime(),name:'Full body',routineId:'r1',cur:0,bw:79.5,entries:entries.map(e=>({...e,sets:e.sets.map(s=>({w:s.w,r:s.r,done:false}))}))};
fs.mkdirSync(new URL('../../test/fixtures/',import.meta.url),{recursive:true});
fs.writeFileSync(new URL('../../test/fixtures/workout-product-parity.json',import.meta.url),JSON.stringify({now:now.toISOString(),plan,stats,history:[session],schedule:{data:[],overrideDates:[],week},active,reference,referenceActive},null,2)+'\n');
console.log('Wrote matched training fixture; no database or authentication changes.');
