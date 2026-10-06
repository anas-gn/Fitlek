import {fail,json,text,validatePlan,validateCustomExercise} from './workoutDomain.js';

const progression = value => ({none:'off',lp:'linear',gs:'greyskull',dp:'double',time:'time',off:'off',linear:'linear',greyskull:'greyskull',double:'double',inherit:'inherit'}[value] ?? 'off');
export function portableExercise(e) {
  return {externalSource:e.externalSource,externalId:e.externalId,name:e.name,muscleGroup:e.muscleGroup,
    bodyPart:e.bodyPart??e.muscleGroup,equipment:e.equipment,exerciseType:e.exerciseType,
    isBodyweight:!!e.isBodyweight,description:e.description??null,instructions:json(e.instructions??[])};
}

// Independent serializer for the reference's public v1 exchange format.
// Database/account IDs, sessions and measurements never leave this bundle.
export function openGymWorkoutProgram(bundle, {exported = new Date().toISOString().slice(0,10)} = {}) {
  const customs = new Map();
  const rule = value => ['off','linear','greyskull','double','time'].includes(value)?value:'off';
  const routines = bundle.plan.days.map((day,index) => ({
    id:`routine-${index+1}`,name:day.name,
    ...(day.configuration?.progression ? {prog:rule(day.configuration.progression)} : {}),
    ex:day.exercises.map(entry => {
      const source=entry.exercise, c=entry.configuration??{};
      let id=source.externalId;
      if(source.externalSource!=='exercises-dataset') {
        const key=JSON.stringify([source.externalSource,source.externalId]);
        if(!customs.has(key))customs.set(key,{id:`custom-${customs.size+1}`,n:source.name,
          bp:source.bodyPart||source.muscleGroup,...(source.description?{desc:source.description}:{})});
        id=customs.get(key).id;
      }
      const mode=c.mode??source.exerciseType;
      const result={id,sets:entry.targetSets};
      if(mode==='cardio')Object.assign(result,{mode:'cardio',min:entry.targetDurationSeconds/60,speed:c.speedKmh??8});
      else if(mode==='timed'||mode==='time')Object.assign(result,{mode:'time',sec:entry.targetDurationSeconds});
      else Object.assign(result,{reps:entry.targetReps,...(c.perSide?{side:true}:{})});
      if(entry.targetWeight)result.weight=entry.targetWeight;
      if(c.bodyweight!=null)result.bodyweight=c.bodyweight;
      if(c.progression&&c.progression!=='inherit')result.prog=rule(c.progression);
      if(c.increment>0)result.inc=c.increment;
      if(c.minReps!=null)result.repsMin=c.minReps;
      if(c.bodyweightRepCeiling>0)result.repsMax=c.bodyweightRepCeiling;
      if(entry.supersetGroup)result.sg=entry.supersetGroup;
      return result;
    })
  }));
  const week={};
  for(const [weekday,indices] of Object.entries(bundle.week??{})) {
    const selected=indices.map(index=>routines[index]).filter(Boolean);
    if(!selected.length)continue;
    let routine=selected[0];
    if(selected.length>1){
      // The host can assign several routines. Preserve that day as an explicit
      // combined routine because the reference assigns a single routine/day.
      routine={id:`combined-${weekday}`,name:selected.map(r=>r.name).join(' + '),
        ex:selected.flatMap((r,i)=>r.ex.map(e=>({...e,
          ...(e.prog?{}:r.prog?{prog:r.prog}:{}),
          ...(e.sg?{sg:`${i}:${e.sg}`}:{})})))};
      routines.push(routine);
    }
    week[weekday==='7'?'0':weekday]=routine.id;
  }
  return {opengym_plan:1,exported,name:bundle.plan.name??'',week,routines,customEx:[...customs.values()]};
}

// Read the reference's public file format, resolving the stable imported catalogue
// identities. No history, account data, media or application settings are transferred.
export function parseWorkoutProgram(raw,catalog,{clientID=1}={}) {
  if(!raw||typeof raw!=='object'||Array.isArray(raw))fail('invalid_workout');
  let plan,week={},dropped=0;
  if(raw.format==='sirvya-workout-program'&&raw.version===1){
    plan=raw.plan;week=raw.week??{};
  }else if(raw.opengym_plan===1&&Array.isArray(raw.routines)&&raw.routines.length<=100){
    const builtins=new Map(catalog.filter(e=>e.externalSource==='exercises-dataset').map(e=>[String(e.externalId),e]));
    if(raw.customEx!=null&&(!Array.isArray(raw.customEx)||raw.customEx.length>500))fail('invalid_workout');
    if(raw.week!=null&&(typeof raw.week!=='object'||Array.isArray(raw.week)))fail('invalid_workout');
    const customs=new Map((raw.customEx??[]).filter(c=>c?.id).map(c=>[String(c.id),c]));
    const routineIDs=new Map();
    const days=raw.routines.map((r,index)=>{
      if(!r||!Array.isArray(r.ex)||r.ex.length>50||!r.id||routineIDs.has(String(r.id)))fail('invalid_workout');
      routineIDs.set(String(r.id),index);
      const exercises=[];
      for(const x of r.ex){
        if(!x){dropped++;continue;}
        const custom=customs.get(String(x.id)),builtin=builtins.get(String(x.id));
        if(!custom&&!builtin){dropped++;continue;}
        const source=custom?{externalSource:'sirvya-custom',externalId:String(custom.id),name:text(custom.n,160,true),
          bodyPart:text(custom.bp,80,true),muscleGroup:custom.bp,equipment:'custom',exerciseType:custom.bp==='cardio'?'cardio':'reps',isBodyweight:false,
          description:text(custom.desc,5000),instructions:[]}:portableExercise(builtin);
        const mode=x.mode==='time'?'timed':x.mode==='cardio'||source.exerciseType==='cardio'?'cardio':'reps';
        exercises.push({exercise:source,targetSets:x.sets??3,targetReps:mode==='reps'?(x.reps??10):null,
          targetWeight:x.weight??0,targetDurationSeconds:mode==='reps'?null:mode==='cardio'?Math.round((x.min??20)*60):x.sec??45,
          restSeconds:90,supersetGroup:x.sg??null,configuration:{mode,bodyweight:x.bodyweight??source.isBodyweight,
            progression:x.prog?progression(x.prog):'inherit',increment:x.inc??null,minReps:x.repsMin??null,
            bodyweightRepCeiling:x.repsMax??0,perSide:!!x.side,speedKmh:mode==='cardio'?x.speed??8:null}});
      }
      return {name:r.name||'Shared routine',dayOfWeek:null,configuration:{progression:progression(r.prog)},exercises};
    });
    for(const [day,id] of Object.entries(raw.week??{}))if(routineIDs.has(String(id)))week[day==='0'?'7':day]=[routineIDs.get(String(id))];
    plan={format:'sirvya-workout-plan',version:1,name:raw.name||'Shared weekly plan',description:null,days};
  }else fail('invalid_workout');
  if(!plan||plan.format!=='sirvya-workout-plan'||plan.version!==1||!Array.isArray(plan.days)||plan.days.length>100)fail('invalid_workout');
  for(const day of plan.days){
    if(!day||!Array.isArray(day.exercises))fail('invalid_workout');
    for(const entry of day.exercises){
      if(!entry?.exercise)fail('invalid_workout');
      const source=entry.exercise;
      validateCustomExercise(source);
      text(source.externalSource,80,true);text(source.externalId,160,true);
      const mode=entry.configuration?.mode??source.exerciseType;
      if(mode==='reps'?entry.targetReps==null||entry.targetDurationSeconds!=null:entry.targetDurationSeconds==null||entry.targetReps!=null)fail('invalid_target');
    }
  }
  if(typeof week!=='object'||Array.isArray(week))fail('invalid_workout');
  const normalizedWeek={};
  for(const [key,indices] of Object.entries(week)){
    if(!/^[1-7]$/.test(key)||!Array.isArray(indices)||indices.length>14||indices.some(i=>!Number.isInteger(i)||i<0||i>=plan.days.length))fail('invalid_workout');
    normalizedWeek[key]=[...new Set(indices)];
  }
  // Validation is read-only at preview time; persistence resolves new private IDs.
  validatePlan({...plan,clientID,status:'draft',days:plan.days.map(d=>({...d,exercises:(d.exercises??[]).map((e,i)=>({...e,exerciseID:i+1}))}))});
  return {plan,week:normalizedWeek,dropped,routineCount:plan.days.length,
    exerciseCount:plan.days.reduce((n,d)=>n+d.exercises.length,0),scheduledDays:Object.values(normalizedWeek).filter(v=>v.length).length};
}

// Public workout specification: the reference's 17 exercise prescriptions.
// Persistence assigns fresh native IDs; catalogue and prior training stay intact.
export function starterWorkoutProgram() {
  const specs=[
    ['push','Push Day',[['0025',4,8],['0047',3,10],['0426',3,10],['0334',3,12],['0241',3,12],['0251',3,10]]],
    ['pull','Pull Day',[['2330',4,10],['0027',4,8],['1323',3,10],['0031',3,10],['0313',3,12]]],
    ['legs','Leg Day',[['0043',4,8],['0085',3,10],['0739',3,12],['0585',3,12],['0586',3,12],['0605',4,15]]]
  ];
  return {opengym_plan:1,name:'Push / Pull / Legs',week:{1:'push',3:'pull',5:'legs'},routines:specs.map(([id,name,sets])=>({id,name,prog:'linear',ex:sets.map(([id,sets,reps])=>({id,sets,reps,weight:0}))}))};
}
