import {readFileSync} from 'node:fs';

const catalog=JSON.parse(readFileSync(new URL('../data/hostedWorkoutIdentities.json',import.meta.url),'utf8'));
const identities=new Map(catalog.exercises.map(e=>[e.externalId,e]));
// Reviewed starter aliases: preserve equipment and movement; never substitute
// a loaded lunge or a dynamic plank for an unweighted lunge or static hold.
const starterIds=new Map(Object.entries({
  'bench-press':'0025','dumbbell-press':'0289','push-up':'0662','squat':'0043',
  'goblet-squat':'1760','deadlift':'0032','romanian-deadlift':'0085','pull-up':'0652',
  'lat-pulldown':'0150','row':'0180','dumbbell-row':'0292','overhead-press':'1456',
  'lateral-raise':'0334','curl':'0294','triceps-pushdown':'0201','calf-raise':'1373',
  'glute-bridge':'3013','farmer-carry':'2133','cycling':'2138','running':'0685',
}));
const paidHost='edb-with-gifs-and-images-by-ascendapi.p.rapidapi.com';
const normalize=value=>String(value||'').toLowerCase().replace(/[^a-z0-9]/g,'');
const error=(code,status=503)=>Object.assign(new Error(code),{code,status});

export function hostedMediaConfiguration(env=process.env){
  const key=env.ASCENDAPI_KEY||env.RAPIDAPI_KEY;
  const mode=env.WORKOUT_MEDIA_PROVIDER||(key?'ascend':env.NODE_ENV==='production'?'off':'ascend-free');
  if(mode==='off')return {mode,enabled:false};
  if(mode==='ascend-free'&&env.NODE_ENV!=='production')return {mode,enabled:true,base:'https://oss.exercisedb.dev'};
  if(mode==='ascend'&&key)return {mode,enabled:true,base:`https://${paidHost}`,key};
  return {mode,enabled:false};
}
export function hostedWorkoutIdentity(exercise){
  const id=exercise.externalSource==='exercises-dataset'?exercise.externalId:
    exercise.externalSource==='sirvya'?starterIds.get(exercise.externalId):undefined;
  return identities.get(id);
}
export function hostedWorkoutSources(config=hostedMediaConfiguration()){
  return config.enabled?[{targets:[...catalog.exercises.map(e=>['exercises-dataset',e.externalId]),
    ...[...starterIds.keys()].map(id=>['sirvya',id])]}]:[];
}
export function hasHostedWorkoutMedia(exercise,config=hostedMediaConfiguration()){
  return config.enabled&&!!hostedWorkoutIdentity(exercise);
}
function mediaUrl(value,extension){
  try{
    const url=new URL(value);
    if(url.protocol==='https:'&&!url.username&&!url.password&&
      ['static.exercisedb.dev','assets.exercisedb.dev','cdn.exercisedb.dev'].includes(url.hostname)&&
      extension.test(url.pathname))return url.href;
  }catch{}
  return null;
}
function matches(row,identity){
  return normalize(row?.name)===normalize(identity.name)&&Array.isArray(row.equipments)&&
    row.equipments.some(value=>normalize(value)===normalize(identity.equipment));
}
// Coalesce simultaneous calls only. Never cache resolved responses or rotating URLs.
export function createHostedWorkoutMedia({fetchImpl=fetch,configuration=()=>hostedMediaConfiguration(),requestIntervalMs=null,maxConcurrentRequests=3}={}){
  if(!Number.isInteger(maxConcurrentRequests)||maxConcurrentRequests<1||maxConcurrentRequests>8)throw new RangeError('Invalid media request concurrency');
  const pending=new Map();
  const queue=[],freeStarts=[];
  let active=0,nextRequestAt=0,blockedUntil=0,timer;
  const rateLimited=()=>Object.assign(error('exercise_media_rate_limited'),
    {retryAfter:Math.max(1,Math.ceil((blockedUntil-Date.now())/1000))});
  const dispatch=()=>{
    if(timer){clearTimeout(timer);timer=undefined;}
    if(blockedUntil>Date.now()){
      for(const task of queue.splice(0))task.reject(rateLimited());
      return;
    }
    if(active>=maxConcurrentRequests||!queue.length)return;
    const delay=Math.max(0,nextRequestAt-Date.now());
    if(delay){timer=setTimeout(dispatch,delay);return;}
    queue.sort((a,b)=>b.priority()-a.priority()||a.createdAt-b.createdAt);
    const task=queue.shift();
    // Keep a slow upstream from turning the visible list into a long backlog.
    if(Date.now()-task.createdAt>10000){task.reject(error('exercise_media_unavailable'));dispatch();return;}
    if(task.mode==='ascend-free'){
      while(freeStarts.length&&freeStarts[0]<=Date.now()-3600000)freeStarts.shift();
      if(freeStarts.length>=1000){blockedUntil=freeStarts[0]+3600000;task.reject(rateLimited());dispatch();return;}
      freeStarts.push(Date.now());
    }
    active++;
    // The OSS preview rejects request bursts. Foreground demonstrations jump
    // ahead of queued thumbnails while retaining its safe request pacing.
    nextRequestAt=Date.now()+(requestIntervalMs??(task.mode==='ascend-free'?1100:250));
    Promise.resolve().then(()=>fetchImpl(task.url,{...task.options,signal:AbortSignal.timeout(6000)}))
      .then(response=>{
        if(response.status===429){
          const retry=response.headers.get('Retry-After');
          const seconds=Number(retry);
          const duration=retry&&Number.isFinite(seconds)?seconds*1000:Date.parse(retry)-Date.now();
          blockedUntil=Math.max(blockedUntil,Date.now()+Math.max(1000,Math.min(3600000,Number.isFinite(duration)?duration:30000)));
        }
        task.resolve(response);
      },task.reject).finally(()=>{active--;dispatch();});
    dispatch();
  };
  const pacedRequest=(url,options,mode,priority)=>{
    if(blockedUntil>Date.now())return Promise.reject(rateLimited());
    // Allow an ordinary visible page, while bounding concurrency and backlog.
    if(active+queue.length>=32)return Promise.reject(rateLimited());
    return new Promise((resolve,reject)=>{
      queue.push({url,options,mode,priority,resolve,reject,createdAt:Date.now()});dispatch();
    });
  };
  return async(exercise,{priority='detail'}={})=>{
    const config=configuration(),identity=hostedWorkoutIdentity(exercise);
    if(!config.enabled||!identity)return null;
    const pendingKey=`${config.mode}:${identity.externalId}`;
    const priorityLevel=priority==='preview'?0:1;
    if(pending.has(pendingKey)){
      const entry=pending.get(pendingKey);entry.priority=Math.max(entry.priority,priorityLevel);
      dispatch();return entry.lookup;
    }
    const entry={priority:priorityLevel,lookup:null};
    const lookup=(async()=>{
      const request=async path=>{
        let response;
        try{response=await pacedRequest(config.base+path,{redirect:'error',
          headers:config.mode==='ascend'?{'X-RapidAPI-Key':config.key,'X-RapidAPI-Host':paidHost}:{}},config.mode,()=>entry.priority);}
        catch(e){if(e.code==='exercise_media_rate_limited')throw e;throw error('exercise_media_unavailable');}
        if(response.status===404)return null;
        if(response.status===429)throw rateLimited();
        if(!response.ok)throw error('exercise_media_unavailable');
        try{const result=await response.json();if(result.success===false)throw error('exercise_media_unavailable');return result.data??result;}
        catch{throw error('exercise_media_unavailable');}
      };
      let row;
      if(config.mode==='ascend-free'){
        row=await request(`/api/v1/exercises/${encodeURIComponent(identity.providerId)}`);
      }else{
        // Paid IDs differ from the OSS catalog. Never assume they are interchangeable.
        const results=await request(`/api/v1/exercises/search?search=${encodeURIComponent(identity.name)}`);
        const exact=(Array.isArray(results)?results:[]).filter(e=>normalize(e.name)===normalize(identity.name));
        for(const candidate of exact.slice(0,4)){
          if(!/^[A-Za-z0-9_-]+$/.test(candidate.exerciseId||''))continue;
          const detail=await request(`/api/v1/exercises/${encodeURIComponent(candidate.exerciseId)}`);
          if(matches(detail,identity)){row=detail;break;}
        }
      }
      // OSS identities are verified against the original MIT metadata. The
      // provider has renamed movements/equipment; identity is stronger than a
      // name comparison. Paid lookups must still pass name/equipment matching.
      if(!row||(config.mode==='ascend-free'?row.exerciseId!==identity.providerId:!matches(row,identity)))return null;
      const asset=mediaUrl(row.gifUrls?.['360p']||row.gifUrls?.['480p']||row.gifUrls?.['720p']||row.gifUrl,/\.gif$/i);
      if(!asset)return null;
      const poster=mediaUrl(row.imageUrls?.['360p']||row.imageUrls?.['480p'],/\.(png|jpg|jpeg|webp)$/i)||asset;
      return {name:identity.name,asset,poster,author:'AscendAPI',license:config.mode==='ascend-free'?'Noncommercial preview':'Licensed API',
        licenseUrl:'https://docs.ascendapi.com/products/edb-v1/overview',sourceUrl:'https://ascendapi.com',modifications:'Hosted demonstration, unmodified.'};
    })();
    entry.lookup=lookup;pending.set(pendingKey,entry);
    try{return await lookup;}finally{if(pending.get(pendingKey)===entry)pending.delete(pendingKey);}
  };
}
export const resolveHostedWorkoutMedia=createHostedWorkoutMedia();
