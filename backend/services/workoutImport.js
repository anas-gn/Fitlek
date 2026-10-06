import {fail,text,number} from './workoutDomain.js';

// Read only Apple Health body-mass records. No XML entities, DTDs or remote
// resources are interpreted; the bounded text is never passed to an XML engine.
export function parseBodyweightXML(input,{timeZone='UTC'}={}){
  if(typeof input!=='string'||Buffer.byteLength(input)>8*1024*1024||/<!DOCTYPE|<!ENTITY/i.test(input)||!/<HealthData\b/.test(input)||!/<\/HealthData\s*>/.test(input))fail('invalid_import');
  let formatter;try{formatter=new Intl.DateTimeFormat('en-CA',{timeZone,year:'numeric',month:'2-digit',day:'2-digit'});}catch{fail('invalid_import_date');}
  const byDay=new Map();
  for(const match of input.matchAll(/<Record\b([^<>]*)\/?>/g)){
    const attrs=Object.fromEntries([...match[1].matchAll(/([A-Za-z][\w]*)\s*=\s*(?:"([^"<>]*)"|'([^'<>]*)')/g)].map(m=>[m[1],m[2]??m[3]]));
    if(attrs.type!=='HKQuantityTypeIdentifierBodyMass')continue;
    const source=attrs.startDate??attrs.creationDate;
    if(typeof source!=='string'||!/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} [+-]\d{4}$/.test(source))fail('invalid_import_date');
    const date=localDate(source.replace(' ','T').replace(/ ([+-]\d{2})(\d{2})$/,'$1:$2'),timeZone);
    if(date>Date.now()+60000||date.getUTCFullYear()<1900)fail('invalid_import_date');
    const factor={kg:1,lb:0.45359237,g:0.001}[attrs.unit];
    if(factor==null||!/^\d+(?:\.\d+)?$/.test(attrs.value??''))fail('invalid_import');
    const weight=number(Number(attrs.value)*factor,1,500),recordedAt=formatter.format(date);
    if(!byDay.has(recordedAt)||byDay.get(recordedAt).time<date.getTime())byDay.set(recordedAt,{recordedAt,weight,note:'Imported from Apple Health',time:date.getTime()});
    if(byDay.size>1000)fail('invalid_import');
  }
  if(!byDay.size)fail('invalid_import');
  return {format:'sirvya-workout-history',source:'Apple Health',version:1,unit:'kg',sessions:[],bodyweight:[...byDay.values()].sort((a,b)=>a.time-b.time).map(({time,...row})=>row)};
}

// Independent CSV parser. Quoted fields, escaped quotes, BOM and line breaks.
export function csvRows(input){
  if(typeof input!=='string'||Buffer.byteLength(input)>8*1024*1024)fail('invalid_import');
  const rows=[];let row=[],field='',quoted=false;
  const source=input.replace(/^\uFEFF/,'');
  for(let i=0;i<source.length;i++){
    const c=source[i];
    if(c==='"'){if(quoted&&source[i+1]==='"'){field+='"';i++;}else quoted=!quoted;}
    else if(!quoted&&(c===','||c==='\n'||c==='\r')){
      row.push(field);field='';
      if(c!==','){if(c==='\r'&&source[i+1]==='\n')i++;if(row.some(v=>v.trim()))rows.push(row);row=[];}
    }else field+=c;
  }
  if(quoted)fail('invalid_import');
  if(field||row.length){row.push(field);if(row.some(v=>v.trim()))rows.push(row);}
  if(rows.length<2||rows.length>30001)fail('invalid_import');return rows;
}

function localDate(value,timeZone){
  const source=value.trim();
  if(/^\d{4}-\d{2}-\d{2}T.*(?:Z|[+-]\d\d:\d\d)$/.test(source)){
    const calendar=source.slice(0,10),nominal=new Date(`${calendar}T00:00:00Z`);
    if(Number.isNaN(nominal.getTime())||nominal.toISOString().slice(0,10)!==calendar)fail('invalid_import_date');
    const d=new Date(source);if(Number.isNaN(d.getTime()))fail('invalid_import_date');return d;
  }
  let match=/^(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{1,2}):(\d{2})(?::(\d{2}))?)?$/.exec(source),parts;
  if(match)parts=match.slice(1).map(v=>Number(v||0));
  else{
    const months=['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'];
    const aliases={janv:1,févr:2,fevr:2,mars:3,avr:4,mai:5,juin:6,juil:7,août:8,aout:8,déc:12,dec:12,ene:1,abr:4,ago:8,dic:12};
    match=/^(\d{1,2})\s+([\p{L}.]+)\s+(\d{4})[,\s]+(\d{1,2}):(\d{2})(?::(\d{2}))?$/u.exec(source);
    if(!match)fail('invalid_import_date');
    const name=match[2].replace(/\./g,'').toLowerCase(),month=aliases[name]??(months.indexOf(name.slice(0,3))+1);
    if(!month)fail('invalid_import_date');parts=[Number(match[3]),month,Number(match[1]),Number(match[4]),Number(match[5]),Number(match[6]||0)];
  }
  const wall=Date.UTC(parts[0],parts[1]-1,parts[2],parts[3],parts[4],parts[5]);
  const nominal=new Date(wall);
  if(nominal.getUTCFullYear()!==parts[0]||nominal.getUTCMonth()+1!==parts[1]||nominal.getUTCDate()!==parts[2]||parts[3]>23||parts[4]>59||parts[5]>59)fail('invalid_import_date');
  let formatter;try{formatter=new Intl.DateTimeFormat('en',{timeZone,year:'numeric',month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit',second:'2-digit',hourCycle:'h23'});}catch{fail('invalid_import_date');}
  const asWall=date=>{const p=Object.fromEntries(formatter.formatToParts(date).map(v=>[v.type,v.value]));return Date.UTC(Number(p.year),Number(p.month)-1,Number(p.day),Number(p.hour),Number(p.minute),Number(p.second));};
  let guess=new Date(wall);
  for(let i=0;i<3;i++)guess=new Date(guess.getTime()+wall-asWall(guess));
  if(asWall(guess)!==wall)fail('invalid_import_date');return guess;
}

function seconds(value){
  if(value==null||value==='')return 0;
  if(/^\d+(?:\.\d+)?$/.test(value))return Math.round(Number(value));
  if(/^\d+:\d{2}(?::\d{2})?$/.test(value))return value.split(':').reduce((n,v)=>n*60+Number(v),0);
  let total=0;for(const m of value.matchAll(/(\d+(?:\.\d+)?)\s*([hms])/gi))total+=Number(m[1])*({h:3600,m:60,s:1}[m[2].toLowerCase()]);
  if(!total)fail('invalid_import');return Math.round(total);
}

export function parseWorkoutCSV(input,{unit='kg',timeZone='UTC'}={}){
  if(!['kg','lb'].includes(unit))fail('invalid_import');
  const [header,...rows]=csvRows(input),columns=header.map(v=>v.trim().toLowerCase());
  const hevy=columns.includes('exercise_title')&&columns.includes('start_time');
  const strong=columns.includes('workout name')&&columns.includes('exercise name');
  const fitnotes=columns.includes('exercise')&&columns.includes('date');
  if(!hevy&&!strong&&!fitnotes&&columns.includes('date')&&(columns.includes('weight')||columns.includes('weight (kg)'))){
    const bodyweight=rows.map(row=>{if(row.length!==columns.length)fail('invalid_import');const values=Object.fromEntries(columns.map((c,i)=>[c,row[i]]));const date=localDate(values.date,timeZone);if(date>Date.now()+60000)fail('invalid_import_date');return {recordedAt:new Intl.DateTimeFormat('en-CA',{timeZone,year:'numeric',month:'2-digit',day:'2-digit'}).format(date),weight:number(values['weight (kg)']??values.weight,1,1103)*(columns.includes('weight (kg)')||unit==='kg'?1:0.45359237),note:text(values.note,2000)};});
    if(bodyweight.length>1000)fail('invalid_import');return {format:'sirvya-workout-history',source:'Bodyweight CSV',version:1,unit:'kg',sessions:[],bodyweight};
  }
  if(!hevy&&!strong&&!fitnotes)fail('unsupported_import');
  const source=hevy?'Hevy':strong?'Strong':'FitNotes',sessions=new Map();
  for(const row of rows){
    if(row.length!==columns.length)fail('invalid_import');
    const values=Object.fromEntries(columns.map((c,i)=>[c,row[i]]));
    const get=(...names)=>names.map(n=>values[n]).find(v=>v!=null&&v.trim()!=='')??'';
    const start=localDate(get('start_time','date'),timeZone);
    if(start.getTime()>Date.now()+60000||start.getUTCFullYear()<1900)fail('invalid_import_date');
    const title=text(get('title','workout name')||'Imported workout',160,true),key=`${start.toISOString()}:${title}`;
    const note=text(get('description','workout notes'),5000);
    let duration=strong?seconds(get('duration')):0;
    if(hevy&&get('end_time'))duration=Math.round((localDate(get('end_time'),timeZone)-start)/1000);
    if(duration<0||duration>604800)fail('invalid_import');
    if(!sessions.has(key))sessions.set(key,{name:title,startedAt:start.toISOString(),durationSeconds:duration,notes:note,exercises:[]});
    const session=sessions.get(key),name=text(get('exercise_title','exercise name','exercise'),160,true);
    const reps=number(get('reps'),0,1000,true),durationSeconds=seconds(get('duration_seconds','seconds','time'));
    if(!reps&&!durationSeconds)fail('invalid_import');
    const weight=number(get('weight_kg','weight (kg)','weight(kg)','weight','weight (lbs)','weight(lb)','weight_lb'),0,5000)??0;
    const isPounds=columns.includes('weight_lb')||columns.includes('weight (lbs)')||columns.includes('weight(lb)')||!columns.includes('weight_kg')&&!columns.includes('weight (kg)')&&!columns.includes('weight(kg)')&&unit==='lb';
    const normalizedWeight=weight*(isPounds?0.45359237:1);if(normalizedWeight>2000)fail('invalid_import');
    const type=get('set_type'),warmup=type==='warmup';
    const distance=number(get('distance_km','distance','distance (km)','distance_meters'),0,1000000);
    const metres=distance==null?null:distance*(columns.includes('distance_meters')?1:get('distanceunit').toLowerCase()==='miles'?1609.344:1000);
    let e=session.exercises.find(e=>e.sourceKey===name);
    if(!e){e={sourceKey:name,name,exerciseType:reps?'reps':metres?'cardio':'timed',supersetGroup:hevy&&get('superset_id')!==''?`csv:${get('superset_id')}`:null,sets:[]};session.exercises.push(e);}
    if((reps?'reps':metres?'cardio':'timed')!==e.exerciseType)fail('invalid_import');
    const setNumber=warmup?1001+e.sets.filter(s=>s.details.phase==='warmup').length:1+e.sets.filter(s=>s.details.phase!=='warmup').length;
    if(setNumber>30&&setNumber<1001||setNumber>1030)fail('invalid_import');
    const rir=number(get('rir'),0,10);
    const rpe=rir==null?number(get('rpe')==='0'?'':get('rpe'),1,10):null;
    e.sets.push({setNumber,weight:normalizedWeight,reps:reps||null,durationSeconds:reps?null:durationSeconds,rpe,rir,details:{phase:warmup?'warmup':'work',type:'straight',notes:text(get('notes','exercise_notes'),2000),distanceMeters:e.exerciseType==='cardio'?metres:null}});
  }
  if(sessions.size>1000)fail('invalid_import');
  return {source,format:'sirvya-workout-history',version:1,unit:'kg',sessions:[...sessions.values()]};
}
