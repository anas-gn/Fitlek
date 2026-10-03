import test from 'node:test';
import assert from 'node:assert/strict';
import { validatePlan, validateSet, validateCustomExercise, estimated1RM, summarize } from '../services/workoutDomain.js';

const plan = () => ({name: 'Push day plan', clientID: 12, status: 'assigned', days: [{name: 'Push', dayOfWeek: 1,
  exercises: [{exerciseID: 1, targetSets: 3, targetReps: 10, targetWeight: 60, restSeconds: 90}]}]});

test('coach prescription stays distinct from actual set performance', () => {
  const p = validatePlan(plan());
  const e = {...p.days[0].exercises[0], exerciseType: 'reps', isBodyweight: false};
  const v = validateSet({setNumber: 1, reps: 9, weight: 55, rpe: 8.5}, e);
  assert.equal(e.targetReps, 10); assert.equal(v.reps, 9); assert.equal(v.weight, 55);
  assert.equal(v.rpe, 8.5); assert.equal(v.rir, null);
});
test('reject malformed, infinite, fractional, out-of-range or mixed effort data', () => {
  const e = {targetSets: 3, exerciseType: 'reps', isBodyweight: false};
  for (const changes of [{setNumber: 4}, {weight: Infinity}, {reps: 1.5}, {weight: -1}, {rpe: 11}, {rir: 2.5}, {rpe: 8, rir: 2}, {reps: null}, {weight: null}, {durationSeconds: 30}]) {
    assert.throws(() => validateSet({setNumber: 1, reps: 10, weight: 60, ...changes}, e));
  }
});
test('bodyweight and timed sets use appropriate performance fields', () => {
  assert.equal(validateSet({setNumber: 1, reps: 15}, {targetSets: 2, exerciseType: 'reps', isBodyweight: true}).weight, 0);
  assert.equal(validateSet({setNumber: 1, durationSeconds: 45}, {targetSets: 2, exerciseType: 'timed'}).durationSeconds, 45);
  assert.throws(() => validateSet({setNumber: 1, reps: 20}, {targetSets: 2, exerciseType: 'timed'}));
});
test('1RM only estimates eligible loaded sets and volume excludes timed sets', () => {
  assert.equal(estimated1RM({weight: 60, reps: 10}, {exerciseType: 'reps'}), 80);
  assert.equal(estimated1RM({weight: 60, reps: 1}, {exerciseType: 'reps'}), 60);
  assert.equal(estimated1RM({weight: 60, reps: 13}, {exerciseType: 'reps'}), null);
  assert.equal(estimated1RM({weight: 0, reps: 10}, {exerciseType: 'reps', isBodyweight: true}), null);
  assert.equal(estimated1RM({weight: 20, reps: 10}, {exerciseType: 'timed'}), null);
  assert.deepEqual(summarize([{workoutExerciseID: 2, reps: 10, weight: 60}, {workoutExerciseID: 3, reps: null, weight: 20, durationSeconds: 60}],
    {exercises: [{id: 2, exerciseType: 'reps'}, {id: 3, exerciseType: 'timed'}]}), {setCount: 2, exerciseCount: 2, volume: 600});
});
test('assignment requires exercises and valid contiguous superset groups', () => {
  const p = plan(); p.days[0].exercises = [];
  assert.throws(() => validatePlan(p), {code: 'empty_plan'});
  const q = plan(); const base = q.days[0].exercises[0];
  q.days[0].exercises = [{...base, supersetGroup: 'A'}, {...base, supersetGroup: 'B'}, {...base, supersetGroup: 'A'}];
  assert.throws(() => validatePlan(q), {code: 'invalid_superset'});
  q.days[0].exercises[1].supersetGroup = 'A';
  assert.equal(validatePlan(q).days[0].exercises.length, 3);
});
test('custom exercise input validates metadata without requiring licensed media', () => {
  const input = {name:'Wall hold',muscleGroup:'quads',exerciseType:'timed',isBodyweight:true,
    instructions:['Keep breathing.'],secondaryMuscles:['core','core']};
  const result = validateCustomExercise(input);
  assert.equal(result.equipment,'body weight');
  assert.deepEqual(result.secondaryMuscles,['core']);
  for(const changes of [{instructions:[null]},{secondaryMuscles:['']},{name:''},{exerciseType:'bad'},{isBodyweight:'false'}]) {
    assert.throws(()=>validateCustomExercise({...input,...changes}),{status:400});
  }
});
