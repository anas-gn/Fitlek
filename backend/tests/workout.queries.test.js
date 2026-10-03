import test from 'node:test';
import assert from 'node:assert/strict';
import {readPlanDetails,readSessionSets,readPreviousPerformance} from '../services/workoutQueries.js';

test('batch plan reads preserve plan/day/slot identity and use two queries',async()=>{
  const calls=[];
  const conn={query:async(sql,args)=>{calls.push({sql,args});return [sql.includes('FROM workout_days')?
    [{id:20,workoutPlanID:2},{id:10,workoutPlanID:1}]:
    [{id:7,workoutDayID:20,exerciseID:3,instructions:'["Lift"]',configuration:'{"progression":"linear"}'},
      {id:8,workoutDayID:10,exerciseID:4,instructions:'[]'}]];}};
  const result=await readPlanDetails(conn,[{id:1,name:'A'},{id:2,name:'B'}]);
  assert.equal(calls.length,2);assert.deepEqual(calls[0].args,[[1,2]]);
  assert.equal(result[0].days[0].exercises[0].id,8);
  assert.equal(result[1].days[0].exercises[0].configuration.progression,'linear');
  assert.deepEqual(result[1].days[0].exercises[0].instructions,['Lift']);
  assert.deepEqual(await readPlanDetails(conn,[]),[]);assert.equal(calls.length,2);
});

test('batch set and previous-performance reads retain client and chronology restrictions',async()=>{
  const calls=[];
  const conn={query:async(sql,args)=>{calls.push({sql,args});return [[{exerciseID:3,workoutSessionID:2,details:'{"phase":"warmup"}'}]];}};
  const sets=await readSessionSets(conn,[2,4]);assert.equal(sets[0].details.phase,'warmup');
  const previous=await readPreviousPerformance(conn,{id:9,clientID:42,startedAt:'2024-01-01',prescription:{exercises:[{exerciseID:3},{exerciseID:3},{exerciseID:4}]}});
  assert.equal(calls.length,2);assert.deepEqual(calls[1].args,[42,[3,4],42,'2024-01-01','2024-01-01',9]);
  assert.match(calls[1].sql,/s2.id<\?/);assert.equal(previous[3].length,1);assert.deepEqual(previous[4],[]);
});
