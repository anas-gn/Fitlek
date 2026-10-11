// Import a locally supplied, licensed pack. No provider downloads or DB writes.
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath, pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
import {execFileSync} from 'node:child_process';
import seeds from '../data/workoutExercises.js';

const hash=bytes=>createHash('sha256').update(bytes).digest('hex');
const root=fileURLToPath(new URL('../../',import.meta.url));
const text=(value,label)=>{
  if(typeof value!=='string'||!value.trim())throw Error(`Missing ${label}`);
  return value.trim();
};
const url=(value,label)=>{
  const parsed=new URL(text(value,label));
  if(!['https:','http:'].includes(parsed.protocol))throw Error(`Invalid ${label}`);
  return parsed.href;
};

export async function importWorkoutMedia({manifestPath,manifest:providedManifest,packDirectory,workspace=root,requireFull=false}) {
  const manifest=providedManifest??JSON.parse(await fs.readFile(manifestPath,'utf8'));
  const pack=await fs.realpath(packDirectory??path.dirname(manifestPath));
  const resolveInput=async value=>{
    const input=await fs.realpath(path.resolve(pack,text(value,'media path')));
    const relative=path.relative(pack,input);
    if(relative.startsWith('..')||path.isAbsolute(relative))throw Error('Media must stay inside the pack folder');
    return input;
  };
  const metadata=JSON.parse(await fs.readFile(path.join(workspace,'backend/data/exerciseMetadata.json'),'utf8'));
  const valid=new Map([...metadata.map(e=>[`exercises-dataset:${e.externalId}`,e]),
    ...seeds.map(e=>[`sirvya:${e.externalId}`,e])]);
  if(!Array.isArray(manifest.videos)||!manifest.videos.length)throw Error('The pack contains no videos');
  const author=text(manifest.author,'author'),license=text(manifest.license,'license');
  const licenseUrl=url(manifest.licenseUrl,'license URL'),sourceUrl=url(manifest.sourceUrl,'source URL');
  const licenseBytes=await fs.readFile(await resolveInput(manifest.licenseFile));
  if(!licenseBytes.toString('utf8').trim())throw Error('Empty license file');
  const mapped=new Set(),prepared=[];
  // Validate every identity/file before creating any output.
  for(const entry of manifest.videos){
    const targets=entry.targets??[[entry.externalSource??'exercises-dataset',entry.externalId]];
    if(!Array.isArray(targets)||!targets.length)throw Error('Missing stable exercise identity');
    for(const identity of targets){
      if(!Array.isArray(identity)||identity.length!==2||identity.some(v=>typeof v!=='string'))throw Error('IDs must be strings; retain leading zeros');
      const key=identity.join(':');
      if(!valid.has(key)||mapped.has(key))throw Error(`Unknown or duplicate exercise identity: ${key}`);
      mapped.add(key);
    }
    const input=await resolveInput(entry.media);
    if(!/\.(mp4|webm|mov|gif)$/i.test(input))throw Error(`Unsupported exercise media: ${entry.media}`);
    prepared.push({input,targets,name:entry.name??valid.get(targets[0].join(':')).name});
  }
  const previousPath=path.join(workspace,'assets/workout/exercise_media/catalog.json');
  let previous={videos:[],licenses:[]};
  try{previous=JSON.parse(await fs.readFile(previousPath,'utf8'));}catch(error){if(error.code!=='ENOENT')throw error;}
  const reviewed=JSON.parse(await fs.readFile(path.join(workspace,'assets/workout/videos/catalog.json'),'utf8'));
  const retained=(previous.videos??[]).map(v=>({...v,targets:v.targets.filter(t=>!mapped.has(t.join(':')))}))
    .filter(v=>v.targets.length);
  const covered=new Set([...mapped,...reviewed.videos.flatMap(v=>v.targets.map(t=>t.join(':'))),
    ...retained.flatMap(v=>v.targets.map(t=>t.join(':')))]);
  const missing=metadata.filter(e=>!covered.has(`exercises-dataset:${e.externalId}`)).map(e=>e.externalId);
  if(requireFull&&missing.length)throw Error(`Incomplete media catalog: ${missing.length}/${metadata.length} imported exercises missing; first IDs: ${missing.slice(0,12).join(', ')}`);
  const directory=path.join(workspace,'assets/workout/exercise_media');
  await fs.mkdir(directory,{recursive:true});
  const assets=[],options={stdio:['ignore','pipe','pipe'],windowsHide:true};
  for(const entry of prepared){
    const sourceBytes=await fs.readFile(entry.input),sourceSha256=hash(sourceBytes);
    const basename=`pack-${sourceSha256.slice(0,24)}`;
    const asset=`assets/workout/exercise_media/${basename}.mp4`;
    const poster=`assets/workout/exercise_media/${basename}.jpg`;
    const output=path.join(workspace,asset),posterOutput=path.join(workspace,poster);
    execFileSync(process.env.FFMPEG_PATH||'ffmpeg',['-y','-loglevel','error','-i',entry.input,
      '-map','0:v:0','-an','-vf','scale=640:640:force_original_aspect_ratio=decrease:force_divisible_by=2,setsar=1',
      '-c:v','libx264','-preset','fast','-crf','25','-pix_fmt','yuv420p','-threads','2','-movflags','+faststart',output],options);
    execFileSync(process.env.FFMPEG_PATH||'ffmpeg',['-y','-loglevel','error','-i',output,
      '-frames:v','1','-vf','scale=180:180:force_original_aspect_ratio=decrease','-q:v','3',posterOutput],options);
    const probe=JSON.parse(execFileSync(process.env.FFPROBE_PATH||'ffprobe',
      ['-v','error','-show_streams','-show_format','-of','json',output],{...options,encoding:'utf8'}));
    const stream=probe.streams.find(s=>s.codec_type==='video');
    if(stream?.codec_name!=='h264'||!(Number(probe.format.duration)>0))throw Error('Invalid converted exercise video');
    assets.push({name:entry.name,targets:entry.targets,asset,poster,author,license,licenseUrl,sourceUrl,
      modifications:'Converted to silent H.264 MP4, scaled to fit 640px; JPEG poster extracted. Original movement speed retained.',
      sourceSha256,sha256:hash(await fs.readFile(output)),posterSha256:hash(await fs.readFile(posterOutput)),
      width:stream.width,height:stream.height,durationSeconds:Number(probe.format.duration)});
  }
  const licenseAsset=`assets/workout/exercise_media/license-${hash(licenseBytes).slice(0,24)}.txt`;
  await fs.writeFile(path.join(workspace,licenseAsset),licenseBytes);
  const licenses=[...(previous.licenses??[]).filter(l=>l.asset!==licenseAsset),{name:`${author} exercise media`,asset:licenseAsset}];
  const videos=[...retained,...assets];
  const coverage={total:metadata.length,covered:metadata.length-missing.length,missing};
  await fs.writeFile(previousPath,JSON.stringify({version:1,videos,licenses,coverage},null,2)+'\n');
  await fs.writeFile(path.join(workspace,'backend/data/workoutMediaSources.json'),
    JSON.stringify(videos.map(({name,targets})=>({name,targets})),null,2)+'\n');
  return coverage;
}

if(process.argv[1]&&import.meta.url===pathToFileURL(path.resolve(process.argv[1])).href){
  const manifestPath=process.argv[2];
  if(!manifestPath)throw Error('Usage: node backend/scripts/importWorkoutMedia.mjs <pack-manifest.json> [--require-full]');
  const result=await importWorkoutMedia({manifestPath:path.resolve(manifestPath),requireFull:process.argv.includes('--require-full')});
  console.log(`${result.covered}/${result.total} imported exercises have playable media; ${result.missing.length} still missing. Rebuild Flutter and restart the backend.`);
}
