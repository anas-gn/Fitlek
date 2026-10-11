import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createHostedWorkoutMedia,hostedMediaConfiguration,hostedWorkoutSources,hasHostedWorkoutMedia} from '../services/hostedWorkoutMedia.js';

const exercise={externalSource:'exercises-dataset',externalId:'0001'};
const free=()=>hostedMediaConfiguration({NODE_ENV:'development',WORKOUT_MEDIA_PROVIDER:'ascend-free'});
const detail=(url='https://static.exercisedb.dev/media/2gPfomN.gif')=>({exerciseId:'2gPfomN',name:'3/4 sit-up',equipments:['bodyweight'],gifUrl:url});
const response=data=>new Response(JSON.stringify({success:true,data}),{status:200});

test('full identity map matches existing metadata exactly and never contains media URLs',()=>{
  const map=JSON.parse(readFileSync(new URL('../data/hostedWorkoutIdentities.json',import.meta.url)));
  const local=JSON.parse(readFileSync(new URL('../data/exerciseMetadata.json',import.meta.url)));
  assert.equal(map.exercises.length,1324);
  for(const row of map.exercises){
    const expected=local.find(e=>e.externalId===row.externalId);
    assert.equal(row.name,expected.name);assert.equal(row.equipment,expected.equipment);
    assert.match(row.providerId,/^[A-Za-z0-9_-]+$/);assert.equal(row.gifUrl,undefined);
  }
  assert.equal(hostedWorkoutSources(free())[0].targets.filter(([source])=>source==='exercises-dataset').length,1324);
  assert.equal(hasHostedWorkoutMedia({externalSource:'sirvya',externalId:'romanian-deadlift'},free()),true);
  assert.equal(hasHostedWorkoutMedia({externalSource:'sirvya',externalId:'wall-sit'},free()),false);
  assert.equal(hasHostedWorkoutMedia(exercise,free()),true);
  assert.equal(hasHostedWorkoutMedia({...exercise,externalSource:'custom'},free()),false);
});

test('commercial deployment cannot silently use the noncommercial preview',()=>{
  for(const env of [{NODE_ENV:'production'},{NODE_ENV:'production',WORKOUT_MEDIA_PROVIDER:'ascend-free'},
    {NODE_ENV:'production',WORKOUT_MEDIA_PROVIDER:'ascend'},{WORKOUT_MEDIA_PROVIDER:'off',ASCENDAPI_KEY:'test'}]){
    assert.equal(hostedMediaConfiguration(env).enabled,false);
  }
  const config=hostedMediaConfiguration({NODE_ENV:'production',ASCENDAPI_KEY:'test'});
  assert.equal(config.enabled,true);assert.equal(config.mode,'ascend');
});

test('simultaneous lookups coalesce but subsequent lookup resolves a fresh rotating URL',async()=>{
  let requests=0;
  const resolve=createHostedWorkoutMedia({requestIntervalMs:0,configuration:free,fetchImpl:async(url,options)=>{
    requests++;assert.match(url,/\/exercises\/2gPfomN$/);assert.deepEqual(options.headers,{});
    await new Promise(r=>setImmediate(r));return response(detail(`https://static.exercisedb.dev/media/2gPfomN.gif?revision=${requests}`));
  }});
  const [a,b]=await Promise.all([resolve(exercise),resolve(exercise)]);
  assert.equal(requests,1);assert.equal(a.asset,b.asset);assert.equal(a.author,'AscendAPI');
  const c=await resolve(exercise);assert.equal(requests,2);assert.notEqual(c.asset,a.asset);
});

test('wrong identity, unsafe CDN URLs and absent identities cannot show a false demo',async()=>{
  for(const row of [{...detail(),exerciseId:'another-movement'},
    detail('https://untrusted.example/demo.gif'),detail('http://static.exercisedb.dev/demo.gif'),
    detail('https://secret@static.exercisedb.dev/demo.gif'),detail('https://static.exercisedb.dev/demo.mp4')]){
    const resolve=createHostedWorkoutMedia({configuration:free,fetchImpl:async()=>response(row)});
    assert.equal(await resolve(exercise),null);
  }
  const resolve=createHostedWorkoutMedia({configuration:free,fetchImpl:()=>{throw new Error('must not fetch');}});
  assert.equal(await resolve({...exercise,externalSource:'private'}),null);
  assert.equal(await resolve({...exercise,externalId:'unknown'}),null);
});

test('verified OSS identity remains usable after a provider renames the movement or equipment',async()=>{
  const resolve=createHostedWorkoutMedia({configuration:free,fetchImpl:async()=>response({...detail(),name:'Renamed sit up',equipments:['body weight']})});
  assert.equal((await resolve(exercise)).asset,detail().gifUrl);
});

test('upstream failures remain retryable and never expose credentials',async()=>{
  for(const status of [429,500,401]){
    let requests=0;
    const resolve=createHostedWorkoutMedia({requestIntervalMs:0,configuration:free,fetchImpl:async()=>{requests++;return new Response('',{status});}});
    await assert.rejects(resolve(exercise),e=>e.status===503&&e.code===(status===429?'exercise_media_rate_limited':'exercise_media_unavailable'));
    await assert.rejects(resolve(exercise));assert.equal(requests,status===429?1:2);
  }
  const resolve=createHostedWorkoutMedia({configuration:free,fetchImpl:async()=>{throw new Error('secret');}});
  await assert.rejects(resolve(exercise),e=>e.message==='exercise_media_unavailable');
});

test('request workers stay bounded when the configured provider permits bursts',async()=>{
  const rows=JSON.parse(readFileSync(new URL('../data/hostedWorkoutIdentities.json',import.meta.url))).exercises.slice(0,12);
  let active=0,maximum=0,requests=0;
  const resolve=createHostedWorkoutMedia({requestIntervalMs:0,configuration:free,fetchImpl:async url=>{
    requests++;active++;maximum=Math.max(maximum,active);
    await new Promise(r=>setTimeout(r,10));active--;
    const exerciseId=new URL(url).pathname.split('/').pop();
    return response({exerciseId,gifUrl:`https://static.exercisedb.dev/media/${exerciseId}.gif`});
  }});
  const videos=await Promise.all(rows.map(row=>resolve({...exercise,externalId:row.externalId})));
  assert.equal(requests,12);assert.equal(maximum,3);
  videos.forEach((video,i)=>assert.equal(video.asset,`https://static.exercisedb.dev/media/${rows[i].providerId}.gif`));
});

test('opening a demonstration promotes its pending thumbnail ahead of the list',async t=>{
  const rows=JSON.parse(readFileSync(new URL('../data/hostedWorkoutIdentities.json',import.meta.url))).exercises.slice(0,4);
  let release;const gate=new Promise(r=>{release=r;});t.after(()=>release());
  const calls=[];
  const resolve=createHostedWorkoutMedia({requestIntervalMs:0,maxConcurrentRequests:1,configuration:free,fetchImpl:async url=>{
    const exerciseId=new URL(url).pathname.split('/').pop();calls.push(exerciseId);
    if(calls.length===1)await gate;
    return response({exerciseId,gifUrl:`https://static.exercisedb.dev/media/${exerciseId}.gif`});
  }});
  const previews=rows.slice(0,3).map(row=>resolve({...exercise,externalId:row.externalId},{priority:'preview'}));
  const promoted=resolve({...exercise,externalId:rows[2].externalId});
  const foreground=resolve({...exercise,externalId:rows[3].externalId});
  release();const [,,preview,detail]=await Promise.all([...previews,promoted,foreground]);
  assert.deepEqual(calls,[rows[0],rows[2],rows[3],rows[1]].map(row=>row.providerId));
  assert.equal(preview.asset,detail.asset);assert.equal(calls.length,4);
});

test('default OSS pacing avoids the provider burst throttle',async()=>{
  const starts=[];
  const resolve=createHostedWorkoutMedia({configuration:free,fetchImpl:async url=>{
    starts.push(Date.now());const exerciseId=new URL(url).pathname.split('/').pop();
    return response({exerciseId,gifUrl:`https://static.exercisedb.dev/media/${exerciseId}.gif`});
  }});
  await Promise.all([resolve(exercise),resolve({...exercise,externalId:'0002'})]);
  assert.equal(starts.length,2);assert.ok(starts[1]-starts[0]>=1050);
});

test('provider throttling stops queued requests and honors Retry-After',async()=>{
  let requests=0;
  const resolve=createHostedWorkoutMedia({requestIntervalMs:0,maxConcurrentRequests:1,configuration:free,fetchImpl:async()=>{
    requests++;return new Response('',{status:429,headers:{'Retry-After':'60'}});
  }});
  const results=await Promise.allSettled([resolve(exercise),resolve({...exercise,externalId:'0002'})]);
  for(const result of results){
    assert.equal(result.status,'rejected');assert.equal(result.reason.code,'exercise_media_rate_limited');
    assert.ok(result.reason.retryAfter>=59&&result.reason.retryAfter<=60);
  }
  await assert.rejects(resolve(exercise),e=>e.code==='exercise_media_rate_limited');
  assert.equal(requests,1);
});

test('the request backlog is bounded without rejecting an ordinary visible page',async t=>{
  const rows=JSON.parse(readFileSync(new URL('../data/hostedWorkoutIdentities.json',import.meta.url))).exercises.slice(0,33);
  let release;const gate=new Promise(r=>{release=r;});t.after(()=>release());
  const resolve=createHostedWorkoutMedia({requestIntervalMs:0,configuration:free,fetchImpl:async url=>{
    await gate;const exerciseId=new URL(url).pathname.split('/').pop();
    return response({exerciseId,gifUrl:`https://static.exercisedb.dev/media/${exerciseId}.gif`});
  }});
  const accepted=rows.slice(0,32).map(row=>resolve({...exercise,externalId:row.externalId}));
  await assert.rejects(resolve({...exercise,externalId:rows[32].externalId}),e=>e.code==='exercise_media_rate_limited');
  release();assert.equal((await Promise.all(accepted)).filter(Boolean).length,32);
});

test('free preview respects the hourly request budget even when requests are fast',async()=>{
  let requests=0;
  const resolve=createHostedWorkoutMedia({requestIntervalMs:0,configuration:free,fetchImpl:async()=>{requests++;return response(detail());}});
  for(let i=0;i<1000;i++)await resolve(exercise);
  await assert.rejects(resolve(exercise),e=>e.code==='exercise_media_rate_limited'&&e.retryAfter>3500);
  assert.equal(requests,1000);
});

test('paid lookup resolves its own ID with exact movement and equipment and serves 360p media',async()=>{
  const calls=[];
  const resolve=createHostedWorkoutMedia({requestIntervalMs:0,configuration:()=>hostedMediaConfiguration({NODE_ENV:'production',ASCENDAPI_KEY:'test-only-key'}),
    fetchImpl:async(url,options)=>{
      calls.push(url);assert.equal(options.headers['X-RapidAPI-Key'],'test-only-key');
      assert.equal(new URL(url).host,options.headers['X-RapidAPI-Host']);assert.equal(options.redirect,'error');
      if(url.includes('/search?'))return response([{exerciseId:'edb_test',name:'3/4 sit-up'}]);
      assert.match(url,/\/exercises\/edb_test$/);
      return response({...detail(),exerciseId:'edb_test',gifUrls:{'360p':'https://assets.exercisedb.dev/media/paid.gif'},imageUrls:{'360p':'https://assets.exercisedb.dev/media/paid.png'}});
    }});
  const video=await resolve(exercise);
  assert.equal(calls.length,2);assert.equal(video.asset,'https://assets.exercisedb.dev/media/paid.gif');
  assert.equal(video.poster,'https://assets.exercisedb.dev/media/paid.png');assert.equal(JSON.stringify(video).includes('test-only-key'),false);
});
