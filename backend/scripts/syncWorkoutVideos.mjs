// Maintenance only: pinned CC BY-SA video assets; never imports exercise rows.
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
import {execFileSync} from 'node:child_process';
import seeds from '../data/workoutExercises.js';
const root=fileURLToPath(new URL('../../',import.meta.url));
const directory=path.join(root,'assets','workout','videos');
const scratch=path.join(root,'workout_tmp','video-transcode');
const mapping=JSON.parse(await fs.readFile(new URL('../data/workoutVideoSources.json',import.meta.url)));
const metadata=JSON.parse(await fs.readFile(new URL('../data/exerciseMetadata.json',import.meta.url)));
const identities=new Set([...metadata.map(e=>`exercises-dataset:${e.externalId}`),...seeds.map(e=>`sirvya:${e.externalId}`)]);
const concurrency=Number(process.env.WORKOUT_VIDEO_DOWNLOAD_CONCURRENCY||8);
if(!Number.isInteger(concurrency)||concurrency<1||concurrency>16)throw Error('Video download concurrency must be between 1 and 16');
const hash=bytes=>createHash('sha256').update(bytes).digest('hex');
const request=async(url,options={},timeout=120000)=>{
  for(let attempt=0;attempt<3;attempt++){
    try{return await fetch(url,{...options,signal:AbortSignal.timeout(timeout)});}
    catch(error){if(attempt===2)throw error;await new Promise(resolve=>setTimeout(resolve,1000*(attempt+1)));}
  }
};
const get=async url=>{const r=await request(url);if(!r.ok)throw Error(`Media source unavailable (${r.status})`);return r;};
const download=async source=>{
  const chunks=[];
  const chunkSize=1024*1024;
  for(let start=0;start<source.size;start+=concurrency*chunkSize){
    const ranges=Array.from({length:Math.min(concurrency,Math.ceil((source.size-start)/chunkSize))},(_,i)=>({start:start+i*chunkSize,end:Math.min(source.size-1,start+(i+1)*chunkSize-1)}));
    const batch=await Promise.all(ranges.map(async range=>{
      const cache=path.join(scratch,`source-${source.id}-${range.start}.part`);
      try{const existing=await fs.readFile(cache);if(existing.length===range.end-range.start+1)return existing;}catch(e){if(e.code!=='ENOENT')throw e;}
      const response=await request(source.video,{headers:{Range:`bytes=${range.start}-${range.end}`}},60000);
      if(response.status!==206||response.headers.get('content-range')!==`bytes ${range.start}-${range.end}/${source.size}`)throw Error('Video range/size changed');
      const bytes=Buffer.from(await response.arrayBuffer());
      if(bytes.length!==range.end-range.start+1)throw Error('Incomplete source range');
      await fs.writeFile(cache,bytes);return bytes;
    }));
    chunks.push(...batch);
    console.log(`Downloaded ${ranges.at(-1).end+1}/${source.size} bytes for video ${source.id}`);
  }
  return Buffer.concat(chunks);
};
const [videos,exercises,licenses]=await Promise.all(['video/?limit=300','exerciseinfo/?limit=1000','license/'].map(async p=>(await get('https://wger.de/api/v2/'+p)).json()));
const license=licenses.results.find(l=>l.id===2);
if(!license||license.short_name!=='CC-BY-SA 4'||new URL(license.url).hostname!=='creativecommons.org'||!new URL(license.url).pathname.startsWith('/licenses/by-sa/4.0/'))throw Error('License changed; review');
await fs.mkdir(directory,{recursive:true});await fs.mkdir(scratch,{recursive:true});
let prior;try{prior=JSON.parse(await fs.readFile(path.join(directory,'catalog.json')));}catch(e){if(e.code!=='ENOENT')throw e;}
const known=new Map((prior?.videos??[]).map(v=>[v.videoID,v]));
const result=[],mapped=new Set();
for(const m of mapping){
  for(const [provider,id] of m.targets){const key=`${provider}:${id}`;if(!identities.has(key)||mapped.has(key))throw Error('Invalid or duplicate exercise identity');mapped.add(key);}
  const exercise=exercises.results.find(e=>e.id===m.wgerID),source=videos.results.find(v=>v.id===m.videoID);
  if(exercise?.translations.find(t=>t.language===2)?.name!==m.name||source?.exercise!==m.wgerID||source.license!==2||source.license_author!=='Goulart')throw Error(`Review changed source ${m.wgerID}`);
  const url=new URL(source.video);
  if(url.origin!=='https://wger.de'||!url.pathname.startsWith(`/media/exercise-video/${m.wgerID}/`)||source.size>100*1024*1024)throw Error('Unexpected source video');
  const asset=`assets/workout/videos/wger-${m.videoID}.mp4`,poster=`assets/workout/videos/wger-${m.videoID}.jpg`;
  const output=path.join(root,asset),posterOutput=path.join(root,poster),old=known.get(m.videoID);
  if(old){
    if(old.sourceUrl!==source.video||old.sourceSize!==source.size||hash(await fs.readFile(output))!==old.sha256||hash(await fs.readFile(posterOutput))!==old.posterSha256)throw Error('Audited bytes/source changed');
    if(JSON.stringify(old.targets)!==JSON.stringify(m.targets)||old.reviewNote!==m.reviewNote)throw Error('Exercise mapping changed; update the catalog only after visual review');
    result.push(old);continue;
  }
  const input=path.join(scratch,`source-${m.videoID}.mov`);
  try{
    console.log(`Downloading video ${m.videoID}: ${m.name}`);
    const bytes=await download(source);
    if(bytes.length!==source.size)throw Error('Video size changed');
    await fs.writeFile(input,bytes);
    const options={stdio:['ignore','ignore','pipe'],windowsHide:true};
    execFileSync(process.env.FFMPEG_PATH||'ffmpeg',['-y','-loglevel','error','-i',input,'-map','0:v:0','-an','-vf','scale=640:640:force_original_aspect_ratio=decrease:force_divisible_by=2,setsar=1','-c:v','libx264','-preset','fast','-crf','25','-pix_fmt','yuv420p','-r','24','-threads','2','-movflags','+faststart',output],options);
    execFileSync(process.env.FFMPEG_PATH||'ffmpeg',['-y','-loglevel','error','-ss','1','-i',output,'-frames:v','1','-vf','scale=180:180:force_original_aspect_ratio=decrease','-q:v','3',posterOutput],options);
    const probe=JSON.parse(execFileSync(process.env.FFPROBE_PATH||'ffprobe',['-v','error','-show_streams','-show_format','-of','json',output],{...options,stdio:['ignore','pipe','pipe'],encoding:'utf8'}));
    const stream=probe.streams.find(s=>s.codec_type==='video');
    if(stream?.codec_name!=='h264'||stream.pix_fmt!=='yuv420p'||probe.streams.some(s=>s.codec_type==='audio'))throw Error('Unexpected output codec');
    const data={videoID:m.videoID,wgerID:m.wgerID,wgerUUID:exercise.uuid,name:m.name,targets:m.targets,asset,poster,sourceUrl:source.video,sourceSize:source.size,sourceSha256:hash(bytes),sha256:hash(await fs.readFile(output)),posterSha256:hash(await fs.readFile(posterOutput)),author:source.license_author,authorHistory:source.author_history,license:'CC BY-SA 4.0',licenseUrl:'https://creativecommons.org/licenses/by-sa/4.0/',modified:true,modifications:'Transcoded to H.264 MP4, scaled to fit 640px, resampled to 24fps, audio removed; poster extracted. Original movement speed retained.',width:stream.width,height:stream.height,durationSeconds:Number(probe.format.duration)};
    if(m.reviewNote)data.reviewNote=m.reviewNote;
    result.push(data);console.log(`Saved video ${m.videoID}: ${m.name}`);
  }finally{await fs.unlink(input).catch(e=>{if(e.code!=='ENOENT')throw e;});}
  for(let start=0;start<source.size;start+=1024*1024)await fs.unlink(path.join(scratch,`source-${source.id}-${start}.part`)).catch(e=>{if(e.code!=='ENOENT')throw e;});
  await fs.writeFile(path.join(directory,'catalog.json'),JSON.stringify({version:1,videos:result},null,2)+'\n');
}
const text=await(await get('https://creativecommons.org/licenses/by-sa/4.0/legalcode.txt')).text();
if(!text.includes('Attribution-ShareAlike 4.0 International'))throw Error('Unexpected license text');
await fs.writeFile(path.join(directory,'LICENSE.txt'),text);
await fs.writeFile(path.join(root,'docs','licenses','CC-BY-SA-4.0.txt'),text);
await fs.writeFile(path.join(directory,'catalog.json'),JSON.stringify({version:1,videos:result},null,2)+'\n');
console.log(`${result.length} real videos, ${mapped.size} stable exercise identities. Existing dataset untouched.`);
