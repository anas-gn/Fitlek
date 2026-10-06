import test from 'node:test';
import assert from 'node:assert/strict';
import {nextTarget,validatePreferences,dailyReminderKey} from '../services/workoutExperience.js';
import {validateSet,validateConfiguration,setVolume,estimated1RM} from '../services/workoutDomain.js';
const exercise={id:1,exerciseType:'reps',isBodyweight:0,targetSets:2,targetReps:10,targetWeight:60,configuration:{progression:'linear',increment:2.5}};
const successful={target:exercise,sets:[{reps:10,weight:60},{reps:10,weight:60}]};
test('workout demonstration size persists without dropping training preferences',()=>{
  const p=validatePreferences({demonstrationSize:'mini',unit:'lb',bodyweightGoal:78});
  assert.equal(p.demonstrationSize,'mini'); assert.equal(p.unit,'lb'); assert.equal(p.bodyweightGoal,78);
  assert.equal(validatePreferences({}).demonstrationSize,'full');
  assert.throws(()=>validatePreferences({demonstrationSize:'hidden'}),{status:400});
});
test('routine glyphs persist as bounded configuration without changing progression',()=>{
  assert.equal(validateConfiguration({icon:'mobility',progression:'double'}).icon,'mobility');
  assert.throws(()=>validateConfiguration({icon:'external-brand'}),{status:400});
});
test('progression increases only completed working sets and deloads repeated misses',()=>{
  assert.equal(nextTarget(exercise,[successful]).weight,62.5);
  const failed={target:exercise,sets:[{reps:8,weight:60},{reps:7,weight:60}]};
  assert.equal(nextTarget(exercise,[failed]).weight,60);
  assert.equal(nextTarget(exercise,[failed,failed,failed]).reason,'deload');
  assert.equal(nextTarget(exercise,[{...successful,excludedFromProgression:true}]).reason,'first_session');
  assert.equal(nextTarget(exercise,[{...successful,sets:successful.sets.map(s=>({...s,details:{phase:'warmup'}}))}]).reason,'first_session');
});
test('double progression, AMRAP, timed and unloaded bodyweight remain different policies',()=>{
  const double={...exercise,configuration:{progression:'double',minReps:8,increment:2.5}};
  const next=nextTarget(double,[{...successful,target:double}]);assert.equal(next.weight,62.5);assert.equal(next.reps,8);
  assert.equal(nextTarget(double,[{target:{...double,targetReps:8},sets:[{reps:8,weight:60},{reps:8,weight:60}]}]).weight,60);
  const greyskull={...exercise,configuration:{progression:'greyskull',increment:2.5}};
  assert.equal(nextTarget(greyskull,[{target:greyskull,sets:[{reps:10,weight:60},{reps:20,weight:60}]}]).weight,65);
  const timed={...exercise,exerciseType:'timed',targetReps:null,targetDurationSeconds:30,configuration:{progression:'time',increment:5}};
  assert.equal(nextTarget(timed,[{target:timed,sets:[{durationSeconds:30},{durationSeconds:31}]}]).durationSeconds,35);
  const bw={...exercise,isBodyweight:1,targetWeight:0};assert.equal(nextTarget(bw,[{target:bw,sets:[{reps:10,weight:0},{reps:10,weight:0}]}]).reps,11);
});
test('changing prescribed targets or policy resets progression while note edits keep it',()=>{
  const history={...successful,target:{...exercise,originalTargets:{targetWeight:60,targetReps:10,targetSets:2,targetDurationSeconds:null}}};
  assert.equal(nextTarget({...exercise,notes:'New cue'},[history]).weight,62.5);
  assert.equal(nextTarget({...exercise,targetWeight:40},[history]).weight,40);
  assert.equal(nextTarget({...exercise,configuration:{progression:'double'}},[history]).reason,'first_session');
});
test('bodyweight progression honors the configured rep ceiling and set cap',()=>{
  const bw={...exercise,isBodyweight:1,targetWeight:0,targetReps:12,
    configuration:validateConfiguration({progression:'linear',bodyweightRepCeiling:12,maxBodyweightSets:3})};
  const hit={target:bw,sets:[{reps:12,weight:0},{reps:12,weight:0}]};
  assert.equal(nextTarget(bw,[hit]).sets,3);
  assert.equal(nextTarget(bw,[{target:{...bw,targetSets:3},sets:[...hit.sets,hit.sets[0]]}]).reason,'add_load_or_variation');
  assert.equal(nextTarget(bw,[{...hit,sets:[{reps:11,weight:0}]}]).reason,'repeat');
  const loaded={...bw,targetWeight:10};
  assert.equal(nextTarget(loaded,[{target:loaded,sets:hit.sets.map(s=>({...s,weight:10}))}]).weight,12.5);
  assert.throws(()=>validateConfiguration({bodyweightRepCeiling:-1}));
  assert.throws(()=>validateConfiguration({maxBodyweightSets:31}));
});
test('malformed detailed set payloads fail validation rather than throwing server errors',()=>{
  for(const details of [{type:'dropset',segments:[null]}, {sides:{left:'bad',right:{reps:10}}}]) {
    assert.throws(()=>validateSet({setNumber:1,reps:10,weight:60,details},exercise),{code:'invalid_set',status:400});
  }
});
test('warmups, asymmetric sides and drops use actual load without inflating 1RM',()=>{
  const set=validateSet({setNumber:1,reps:18,weight:30,details:{sides:{left:{reps:8,weight:25},right:{reps:10,weight:30}}}},exercise);
  assert.equal(setVolume(set,exercise),500);
  assert.equal(estimated1RM(set,exercise),40);
  assert.equal(estimated1RM({...set,details:{phase:'warmup'}},exercise),null);
  assert.equal(setVolume({weight:60,reps:10,details:{type:'dropset',segments:[{weight:40,reps:5}]}},exercise),800);
  assert.throws(()=>validateSet({setNumber:1,reps:10,weight:60,details:{segments:[{reps:5,weight:40}]}},exercise));
});
test('workout preferences validate units, timers, equipment and time-zone reminder boundaries',()=>{
  const p=validatePreferences({reminderEnabled:true,reminderTime:'08:00',timeZone:'Africa/Casablanca'});
  assert.equal(dailyReminderKey(p,new Date('2026-10-02T07:00:00Z')),'daily:2026-10-02');
  assert.equal(dailyReminderKey(p,new Date('2026-10-02T07:01:00Z')),null);
  assert.throws(()=>validatePreferences({timeZone:'Bad/Zone'}));assert.throws(()=>validatePreferences({unit:'stone'}));
  for(const invalid of [{equipmentProfiles:[null]},{equipmentProfiles:[{name:'Home',equipment:'bad'}]},{plates:[null]},{balanceTargets:[null]}]) {
    assert.throws(()=>validatePreferences(invalid),{code:'invalid_workout',status:400});
  }
});
test('saved balance protocols resolve stable anchors and reject ambiguous or malformed targets',()=>{
  const protocol={id:'upper_1',name:'Upper balance',anchorID:1,targets:[{exerciseID:2,targetPercent:75}]};
  const p=validatePreferences({balanceProtocols:[protocol],activeBalanceProtocolID:'upper_1'});
  assert.equal(p.balanceAnchorID,1);assert.deepEqual(p.balanceTargets,protocol.targets);
  for(const invalid of [{balanceProtocols:[null]},{balanceProtocols:[{...protocol,id:'../bad'}]},
    {balanceProtocols:[protocol,protocol]},{balanceProtocols:[{...protocol,name:' '}]},
    {balanceProtocols:[{...protocol,targets:[null]}]},{activeBalanceProtocolID:'missing'},
    {balanceTargets:[{exerciseID:1,targetPercent:70},{exerciseID:1,targetPercent:80}]}]){
    assert.throws(()=>validatePreferences(invalid),{code:'invalid_workout',status:400});
  }
});
