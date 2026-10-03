// Independent SIRVYA implementation; no openGym source or datasets incorporated.
export class WorkoutError extends Error {
  constructor(code, status = 400) { super(code); this.code = code; this.status = status; }
}
export const fail = (code, status) => { throw new WorkoutError(code, status); };
export function integer(value, min = 1, max = Number.MAX_SAFE_INTEGER) {
  if (!['number', 'string'].includes(typeof value) || value === '') fail('invalid_workout');
  const n = Number(value);
  if (!Number.isSafeInteger(n) || n < min || n > max) fail('invalid_workout');
  return n;
}
export function number(value, min, max, whole = false) {
  if (value == null || value === '') return null;
  if (!['number', 'string'].includes(typeof value)) fail('invalid_workout');
  const n = Number(value);
  if (!Number.isFinite(n) || n < min || n > max || (whole && !Number.isInteger(n))) fail('invalid_workout');
  return n;
}
export function text(value, max, required = false) {
  if (value != null && typeof value !== 'string') fail('invalid_workout');
  const s = (value || '').trim();
  if (s.length > max || (required && !s)) fail('invalid_workout');
  return s || null;
}
export const json = value => typeof value === 'string' ? JSON.parse(value) : value;
export function validateCustomExercise(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) fail('invalid_workout');
  const exerciseType = body.exerciseType ?? 'reps';
  if (!['reps', 'timed', 'cardio'].includes(exerciseType) ||
      typeof body.isBodyweight !== 'boolean' || !Array.isArray(body.instructions) ||
      body.instructions.length > 30 || !Array.isArray(body.secondaryMuscles ?? []) ||
      (body.secondaryMuscles ?? []).length > 20) fail('invalid_workout');
  return {name: text(body.name, 160, true), muscleGroup: text(body.muscleGroup, 80, true),
    equipment: text(body.equipment, 80) ?? 'body weight', exerciseType,
    isBodyweight: body.isBodyweight, description: text(body.description, 5000),
    instructions: body.instructions.map(v => text(v, 2000, true)),
    secondaryMuscles: [...new Set((body.secondaryMuscles ?? []).map(v => text(v, 80, true)))]};
}
export function validatePlan(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) fail('invalid_workout');
  const status = body.status ?? 'draft';
  if (!['draft', 'assigned', 'archived'].includes(status)) fail('invalid_workout');
  if (!Array.isArray(body.days) || body.days.length > 14) fail('invalid_workout');
  const days = body.days.map((d, i) => {
    if (!d || !Array.isArray(d.exercises) || d.exercises.length > 50) fail('invalid_workout');
    if (d.exercises.some(e => !e || typeof e !== 'object' || Array.isArray(e))) fail('invalid_workout');
    const exercises = d.exercises.map((e, j) => ({
      id:e.id?integer(e.id):null,
      exerciseID: integer(e.exerciseID), sortOrder: j,
      targetSets: integer(e.targetSets, 1, 30),
      targetReps: number(e.targetReps, 1, 1000, true),
      targetWeight: number(e.targetWeight, 0, 2000),
      targetDurationSeconds: number(e.targetDurationSeconds, 1, 86400, true),
      restSeconds: integer(e.restSeconds ?? 90, 0, 3600),
      notes: text(e.notes, 2000), supersetGroup: text(e.supersetGroup, 64),
      configuration: validateConfiguration(e.configuration),
    }));
    // Groups must be contiguous; otherwise execution order is ambiguous.
    for(const e of exercises)if(e.configuration.progression==='double'&&e.configuration.minReps>e.targetReps)fail('invalid_target');
    const seen = new Set(); let previous = null;
    for (const e of exercises) {
      if (e.supersetGroup && e.supersetGroup !== previous && seen.has(e.supersetGroup)) fail('invalid_superset');
      if (e.supersetGroup) seen.add(e.supersetGroup);
      previous = e.supersetGroup;
    }
    const configuration=validateConfiguration(d.configuration);
    if(configuration.progression==='inherit')fail('invalid_workout');
    return {id:d.id?integer(d.id):null,name: text(d.name, 160, true), dayOfWeek: number(d.dayOfWeek, 1, 7, true), sortOrder: i, configuration, exercises};
  });
  if (status === 'assigned' && (!days.length || days.some(d => !d.exercises.length))) fail('empty_plan');
  return {name: text(body.name, 160, true), description: text(body.description, 5000), clientID: integer(body.clientID), status, days};
}
export function validateSet(body, prescribed) {
  const warmup=body.details?.phase==='warmup';
  const setNumber = warmup?integer(body.setNumber,1001,1030):integer(body.setNumber, 1, prescribed.targetSets);
  let reps = number(body.reps, 1, body.details?.sides?2000:1000, true);
  let weight = number(body.weight, 0, 2000);
  const durationSeconds = number(body.durationSeconds, 1, 86400, true);
  const rpe = number(body.rpe, 1, 10);
  const rir = number(body.rir, 0, 10, true);
  if (rpe !== null && rir !== null) fail('invalid_effort');
  const timed = prescribed.exerciseType !== 'reps';
  if ((timed && (durationSeconds === null || reps !== null)) ||
      (!timed && (reps === null || durationSeconds !== null)) ||
      (!timed && !prescribed.isBodyweight && weight === null)) fail('invalid_set');
  const details = validateSetDetails(body.details, prescribed);
  if (details.sides) {
    reps = details.sides.left.reps + details.sides.right.reps;
    weight = Math.max(details.sides.left.weight, details.sides.right.weight);
  }
  return {setNumber, reps, weight: weight ?? 0, durationSeconds, rpe, rir, details};
}
export function validateConfiguration(input = {}) {
  if (input == null) input = {};
  if (typeof input !== 'object' || Array.isArray(input)) fail('invalid_workout');
  const progression = input.progression || 'off';
  if (!['off','inherit','linear','double','greyskull','time'].includes(progression)) fail('invalid_workout');
  if (input.targetRpe != null && input.targetRir != null) fail('invalid_effort');
  const icon=input.icon??'strength';
  if(!['strength','cardio','recovery','mobility'].includes(icon))fail('invalid_workout');
  return {progression, icon, increment: number(input.increment, 0.1, 100) ?? 2.5,
    minReps: number(input.minReps, 1, 1000, true), deloadFactor: number(input.deloadFactor, 0.5, 0.95) ?? 0.9,
    bodyweightRepCeiling: integer(input.bodyweightRepCeiling ?? 30, 1, 1000),
    maxBodyweightSets: integer(input.maxBodyweightSets ?? 6, 1, 30),
    perSide: input.perSide === true, excludeFromProgression: input.excludeFromProgression === true,
    targetRpe: number(input.targetRpe, 1, 10), targetRir: number(input.targetRir, 0, 10, true)};
}
export function validateSetDetails(input = {}, exercise) {
  if (input == null) input = {};
  if (typeof input !== 'object' || Array.isArray(input)) fail('invalid_set');
  const phase = input.phase ?? 'work'; const type = input.type ?? 'straight';
  if (!['work','warmup'].includes(phase) || !['straight','dropset','restpause'].includes(type)) fail('invalid_set');
  const details = {phase, type, notes: text(input.notes, 2000), distanceMeters: number(input.distanceMeters, 0, 1000000)};
  if (details.distanceMeters != null && exercise.exerciseType !== 'cardio') fail('invalid_set');
  if (input.sides != null) {
    if (exercise.exerciseType !== 'reps' || !input.sides?.left || !input.sides?.right ||
        ['left', 'right'].some(side => typeof input.sides[side] !== 'object' || Array.isArray(input.sides[side]))) fail('invalid_set');
    details.sides = {};
    for (const side of ['left','right']) {
      details.sides[side] = {
      reps: integer(input.sides[side].reps, 1, 1000), weight: number(input.sides[side].weight, 0, 2000) ?? 0,
      rpe: number(input.sides[side].rpe, 1, 10), rir: number(input.sides[side].rir, 0, 10, true)};
      if (details.sides[side].rpe != null && details.sides[side].rir != null) fail('invalid_effort');
    }
  }
  if (input.segments != null) {
    if (exercise.exerciseType !== 'reps' || type === 'straight' || !Array.isArray(input.segments) || input.segments.length > 20) fail('invalid_set');
    if (input.segments.some(s => !s || typeof s !== 'object' || Array.isArray(s))) fail('invalid_set');
    details.segments = input.segments.map(s => ({reps: integer(s.reps, 1, 1000), weight: number(s.weight, 0, 2000) ?? 0, restSeconds: integer(s.restSeconds ?? 0, 0, 3600)}));
  }
  return details;
}
export const setDetails = s => s.details ? json(s.details) : {phase:'work',type:'straight'};
export const isWorkSet = s => setDetails(s).phase !== 'warmup';
export function setVolume(s, e) {
  if (e?.exerciseType !== 'reps') return 0;
  const details = setDetails(s);
  const base = details.sides ? Object.values(details.sides).reduce((n,v)=>n+Number(v.weight)*Number(v.reps),0) : Number(s.weight || 0)*Number(s.reps || 0);
  return base + (details.segments || []).reduce((n,v)=>n+Number(v.weight)*Number(v.reps),0);
}
export function estimated1RM(s, e) {
  if (!isWorkSet(s)) return null;
  const sides = setDetails(s).sides;
  if (sides) return Math.max(...Object.values(sides).map(v => estimated1RM(v, e) || 0)) || null;
  return e.exerciseType === 'reps' && !e.isBodyweight && Number(s.weight) > 0 && s.reps >= 1 && s.reps <= 12
    ? Number(s.weight) * (s.reps === 1 ? 1 : 1 + s.reps / 30) : null;
}
export function summarize(sets, prescription) {
  const entries = new Map(prescription.exercises.map(e => [Number(e.id), e]));
  return {setCount: sets.length, exerciseCount: new Set(sets.map(s => Number(s.workoutExerciseID))).size,
    volume: sets.reduce((n, s) => n + setVolume(s, entries.get(Number(s.workoutExerciseID))), 0)};
}
