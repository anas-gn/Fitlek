import test from 'node:test';
import assert from 'node:assert/strict';
import {buildTrainingStats,scheduleAdherence} from '../services/workoutStats.js';
import {validMP4} from '../services/workoutMedia.js';

test('statistics derive chronological records, actual effort, streak and cardio speed',()=>{
  const e={id:10,exerciseID:1,name:'Bench',exerciseType:'reps',isBodyweight:false,muscleGroup:'chest'};
  const s=(id,date)=>({id,startedAt:date+'T12:00:00Z',durationSeconds:600,prescription:{exercises:[e]}});
  const stats=buildTrainingStats([s(2,'2024-01-02'),s(1,'2024-01-01')],[{workoutSessionID:2,workoutExerciseID:10,exerciseID:1,setNumber:1,reps:10,weight:60,rpe:8},{workoutSessionID:1,workoutExerciseID:10,exerciseID:1,setNumber:1,reps:10,weight:50,rir:2}],{now:new Date('2024-01-03T12:00:00Z'),bodyweight:80});
  assert.equal(stats.records[0].estimated1RM,80);
  assert.equal(stats.records[0].relativeStrength,1);
  assert.equal(stats.currentStreak,2);assert.equal(stats.longestStreak,2);
  assert.equal(stats.personalRecords.length,2);
  assert.deepEqual(stats.effortDistribution,{rpe:{8:1},rir:{2:1}});
  const cardio=buildTrainingStats([{id:1,startedAt:'2024-01-01',prescription:{exercises:[{...e,exerciseType:'cardio'}]}}],[{workoutSessionID:1,workoutExerciseID:10,exerciseID:1,durationSeconds:600,details:{distanceMeters:1000}}]);
  assert.equal(cardio.records[0].points[0].speedKmh,6);assert.equal(cardio.volume,0);
});
test('adherence honors rest-day overrides and combined routines by stable day identity',()=>{
  const days=[{id:1,dayOfWeek:1},{id:2,dayOfWeek:2},{id:3,dayOfWeek:2}];
  const stats=scheduleAdherence([{startedAt:'2024-01-02T12:00:00Z',prescription:{sourceDayIDs:[2,3]}}],days,[{date:'2024-01-01'}],[],{start:'2024-01-01',end:'2024-01-02'});
  assert.deepEqual(stats,{expected:2,performed:2,percent:100,missed:[]});
});
test('weekly consistency does not require consecutive training days and expires after a missed week',()=>{
  const sessions=['2024-01-01','2024-01-04','2024-01-08','2024-01-18'].map((date,i)=>({id:i+1,startedAt:date+'T12:00:00Z',prescription:{exercises:[]}}));
  const current=buildTrainingStats(sessions,[],{now:new Date('2024-01-24')});
  assert.equal(current.currentWeeklyStreak,3);assert.equal(current.longestWeeklyStreak,3);
  assert.equal(buildTrainingStats(sessions,[],{now:new Date('2024-01-29')}).currentWeeklyStreak,0);
});

test('period statistics keep earlier PR baselines and use the workout time zone',()=>{
  const exercise={id:10,exerciseID:1,name:'Bench',exerciseType:'reps',isBodyweight:false,muscleGroup:'chest'};
  const sessions=[{id:1,startedAt:'2024-01-01T12:00:00Z',prescription:{exercises:[exercise]}},
    {id:2,startedAt:'2024-02-01T23:30:00Z',prescription:{exercises:[exercise]}}];
  const sets=sessions.map((s,i)=>({workoutSessionID:s.id,workoutExerciseID:10,exerciseID:1,reps:5,weight:i?60:100}));
  const stats=buildTrainingStats(sessions,sets,{since:new Date('2024-02-01'),timeZone:'Africa/Casablanca'});
  assert.equal(stats.workoutCount,1);
  assert.equal(stats.prCount,0,'lower loads after the period boundary are not new records');
  assert.equal(stats.volume,300);
  assert.equal(stats.records[0].points.length,1);
  assert.equal(stats.records[0].points[0].date,'2024-02-02');
  assert.equal(stats.records[0].estimated1RM,100*(1+5/30));
});
test('MP4 upload rejects truncated or forged container headers',()=>{
  const box=(name,payload=Buffer.alloc(0))=>{const b=Buffer.alloc(8+payload.length);b.writeUInt32BE(b.length);b.write(name,4,'ascii');payload.copy(b,8);return b;};
  const ftyp=box('ftyp',Buffer.from('isom0000'));
  assert.equal(validMP4(ftyp),false);
  const valid=Buffer.concat([ftyp,box('moov'),box('mdat',Buffer.alloc(8))]);
  assert.equal(validMP4(valid),true);assert.equal(validMP4(valid.subarray(0,valid.length-1)),false);
});
