// Explicit maintenance command. No API calls are made at application startup.
// Existing images must retain their audited author, license and byte hash.
import fs from 'node:fs/promises';
import {createHash} from 'node:crypto';
const directory=new URL('../../assets/workout/demonstrations/',import.meta.url);
const sources=JSON.parse(await fs.readFile(new URL('../data/workoutDemonstrationSources.json',import.meta.url),'utf8'));
const metadata=JSON.parse(await fs.readFile(new URL('../data/exerciseMetadata.json',import.meta.url),'utf8'));
const {default:seeds}=await import('../data/workoutExercises.js');
const identities=new Set([...metadata.map(e=>`exercises-dataset:${e.externalId}`),...seeds.map(e=>`sirvya:${e.externalId}`)]);
let previous;
try{previous=JSON.parse(await fs.readFile(new URL('catalog.json',directory),'utf8'));}catch(e){if(e.code!=='ENOENT')throw e;}
const known=new Map((previous?.demonstrations??[]).flatMap(d=>d.frames.map(f=>[f.id,f])));
const get=async url=>{for(let attempt=0;attempt<3;attempt++){try{const r=await fetch(url,{signal:AbortSignal.timeout(30000)});if(!r.ok)throw Error(`Download failed (${r.status})`);return r;}catch(e){if(attempt===2)throw e;}}};
await fs.mkdir(directory,{recursive:true});
const demonstrations=[];
for(const source of sources){
  if(source.targets.some(([provider,id])=>!identities.has(`${provider}:${id}`)))throw Error('Unknown exercise identity');
  const exercise=await (await get(`https://wger.de/api/v2/exerciseinfo/${source.wgerID}/`)).json();
  if(exercise.translations.find(t=>t.language===2)?.name!==source.name)throw Error('Exercise changed; review mapping');
  const images=exercise.images.filter(i=>i.license===1&&i.license_author==='Everkinetic'&&!i.is_ai_generated&&i.style==='1');
  if(images.length!==2)throw Error(`Unexpected demonstration frames for ${source.name}`);
  images.sort((a,b)=>a.image.split('/').at(-1).localeCompare(b.image.split('/').at(-1),undefined,{numeric:true}));
  const frames=[];
  for(const image of images){
    const url=new URL(image.image);
    if(url.origin!=='https://wger.de'||!url.pathname.startsWith('/media/exercise-images/')||!url.pathname.endsWith('.png'))throw Error('Unexpected image source');
    let bytes;
    const filename=`wger-${image.id}.png`;
    try{bytes=await fs.readFile(new URL(filename,directory));}catch(e){if(e.code!=='ENOENT')throw e;bytes=Buffer.from(await (await get(url)).arrayBuffer());}
    if(bytes.length>5*1024*1024||!bytes.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10])))throw Error('Invalid PNG');
    const sha256=createHash('sha256').update(bytes).digest('hex');
    const old=known.get(image.id);
    if(old&&(old.sha256!==sha256||old.sourceUrl!==image.image))throw Error('Image changed; review its license and mapping');
    await fs.writeFile(new URL(filename,directory),bytes);
    frames.push({id:image.id,asset:`assets/workout/demonstrations/${filename}`,sourceUrl:image.image,sha256,title:image.license_title||url.pathname.split('/').at(-1),
      author:image.license_author,authorUrl:image.license_author_url||null,originalUrl:image.license_object_url||null,derivativeSourceUrl:image.license_derivative_source_url||null,authorHistory:image.author_history||[]});
  }
  demonstrations.push({wgerID:exercise.id,wgerUUID:exercise.uuid,name:source.name,targets:source.targets,license:'CC BY-SA 3.0',licenseUrl:'https://creativecommons.org/licenses/by-sa/3.0/',modified:false,frames});
}
await fs.writeFile(new URL('catalog.json',directory),JSON.stringify({version:1,demonstrations},null,2)+'\n');
const license=await (await get('https://creativecommons.org/licenses/by-sa/3.0/legalcode.txt')).text();
if(!license.includes('Attribution-ShareAlike 3.0 Unported'))throw Error('Unexpected license text');
await fs.writeFile(new URL('../../docs/licenses/CC-BY-SA-3.0.txt',import.meta.url),license);
await fs.writeFile(new URL('LICENSE.txt',directory),license);
console.log(`Saved ${demonstrations.length} licensed demonstrations (${demonstrations.reduce((n,d)=>n+d.frames.length,0)} unmodified images).`);
