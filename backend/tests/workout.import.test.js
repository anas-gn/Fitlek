import test from 'node:test';
import assert from 'node:assert/strict';
import {csvRows,parseWorkoutCSV,parseBodyweightXML} from '../services/workoutImport.js';

test('CSV preserves quoted commas, escaped quotes and multiline notes',()=>{
  assert.deepEqual(csvRows('\uFEFFa,b\r\n"a,b","a ""quote""\nline"\r\n'),[['a','b'],['a,b','a "quote"\nline']]);
  assert.throws(()=>csvRows('a,b\n"unfinished,cell'));
});
test('Strong separates total workout duration from timed set seconds',()=>{
  const result=parseWorkoutCSV('Date,Workout Name,Duration,Exercise Name,Set Order,Weight,Reps,Seconds,Notes\n2024-01-05 18:00:00,Push,1h 5m,Bench Press,1,60,10,,"Smooth, controlled"\n2024-01-05 18:00:00,Push,1h 5m,Plank,1,0,,45,');
  assert.equal(result.sessions.length,1);
  assert.equal(result.sessions[0].durationSeconds,3900);
  assert.equal(result.sessions[0].exercises[1].sets[0].durationSeconds,45);
  assert.equal(result.sessions[0].exercises[0].sets[0].details.notes,'Smooth, controlled');
});
test('Hevy respects local timezone, warmups, supersets and unset RPE',()=>{
  const r=parseWorkoutCSV('title,start_time,end_time,exercise_title,superset_id,set_type,weight_kg,reps,duration_seconds,rpe\nPush,"5 févr. 2024, 18:00","5 févr. 2024, 18:30",Bench Press,1,warmup,20,10,,0\nPush,"5 févr. 2024, 18:00","5 févr. 2024, 18:30",Bench Press,1,normal,60,8,,8',{timeZone:'Europe/Paris'});
  assert.equal(r.sessions[0].startedAt,'2024-02-05T17:00:00.000Z');
  assert.equal(r.sessions[0].durationSeconds,1800);
  assert.deepEqual(r.sessions[0].exercises[0].sets.map(s=>s.setNumber),[1001,1]);
  assert.equal(r.sessions[0].exercises[0].sets[0].rpe,null);
});
test('FitNotes normalizes explicit kilograms and miles despite display preferences',()=>{
  const r=parseWorkoutCSV('Date,Exercise,Weight(kg),Reps,Distance,DistanceUnit,Time\n2024-01-01,Bench Press,60,10,,,\n2024-01-01,Running,,,1,miles,00:10:00',{unit:'lb'});
  assert.equal(r.sessions[0].exercises[0].sets[0].weight,60);
  assert.equal(r.sessions[0].exercises[1].sets[0].details.distanceMeters,1609.344);
});
test('invalid calendar dates, DST gaps and malformed numbers are rejected',()=>{
  for(const date of ['2024-02-30','2024-03-10 02:30:00'])assert.throws(()=>parseWorkoutCSV(`Date,Exercise,Weight,Reps\n${date},Bench Press,60,10`,{timeZone:'America/New_York'}));
  assert.throws(()=>parseWorkoutCSV('Date,Exercise,Weight,Reps\n2024-01-01,Bench Press,NaN,10'));
});
test('bodyweight CSV retains the local calendar day and converts pounds once',()=>{
  const result=parseWorkoutCSV('Date,Weight,Note\n2024-01-01,176.36981,Morning',{unit:'lb',timeZone:'Africa/Casablanca'});
  assert.equal(result.sessions.length,0);assert.equal(result.bodyweight[0].recordedAt,'2024-01-01');assert.ok(Math.abs(result.bodyweight[0].weight-80)<0.001);
});

test('Apple Health imports only body mass, converts units and retains the latest local daily measurement',()=>{
  const xml=`<HealthData><Record type="HKQuantityTypeIdentifierStepCount" value="9000"/><Record type="HKQuantityTypeIdentifierBodyMass" unit="lb" value="176.36981" startDate="2024-01-01 23:30:00 +0000"/><Record type='HKQuantityTypeIdentifierBodyMass' unit='g' value='81000' startDate='2024-01-02 01:00:00 +0000'/></HealthData>`;
  const result=parseBodyweightXML(xml,{timeZone:'Africa/Casablanca'});
  assert.equal(result.source,'Apple Health');assert.deepEqual(result.sessions,[]);
  assert.deepEqual(result.bodyweight,[{recordedAt:'2024-01-02',weight:81,note:'Imported from Apple Health'}]);
});
test('Apple Health rejects DTDs, external entities, invalid units and dates, and oversized documents',()=>{
  const record=(unit='kg',value='80',date='2024-01-01 10:00:00 +0000')=>`<HealthData><Record type="HKQuantityTypeIdentifierBodyMass" unit="${unit}" value="${value}" startDate="${date}"/></HealthData>`;
  for(const xml of ['<!DOCTYPE HealthData>'+record(),'<!ENTITY remote SYSTEM "https://example.invalid">'+record(),record('stone'),record('kg','-1'),record('kg','80','2024-02-30 10:00:00 +0000'),'<HealthData></HealthData>',record()+' '.repeat(8*1024*1024)])assert.throws(()=>parseBodyweightXML(xml));
});
