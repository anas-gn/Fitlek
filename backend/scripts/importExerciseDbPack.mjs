// Accept an extracted, purchased ExerciseDB pack without a hand-written manifest.
// This command never purchases content, downloads media, or changes exercise IDs.
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {importWorkoutMedia} from './importWorkoutMedia.mjs';

const root=fileURLToPath(new URL('../../',import.meta.url));
const normalize=name=>name.toLowerCase().replace(/[^a-z0-9]+/g,' ').trim();

export async function prepareExerciseDbPack({packDirectory,workspace=root,resolution=360}) {
  if(![180,360,720,1080].includes(resolution))throw Error('Resolution must be 180, 360, 720 or 1080');
  const pack=await fs.realpath(packDirectory),files=[];
  async function walk(directory){
    for(const entry of await fs.readdir(directory,{withFileTypes:true})){
      // Do not follow links into unrelated directories.
      if(entry.isSymbolicLink())continue;
      const location=path.join(directory,entry.name);
      if(entry.isDirectory())await walk(location);
      else if(entry.isFile())files.push(path.relative(pack,location).split(path.sep).join('/'));
    }
  }
  await walk(pack);
  const licenseCandidates=files.filter(file=>/^(eula|license|licence)(?:[-_. ][^/]*)?\.(txt|md)$/i.test(path.posix.basename(file)));
  if(licenseCandidates.length!==1)throw Error('Expected one EULA/LICENSE text file in the extracted pack; supply a manifest for other layouts');
  const metadata=JSON.parse(await fs.readFile(path.join(workspace,'backend/data/exerciseMetadata.json'),'utf8'));
  const valid=new Map(metadata.map(e=>[e.externalId,e])),byId=new Map();
  for(const file of files){
    // Both 0025.gif and 0025-360.gif are common provider layouts. Ignore
    // unrelated images rather than inferring exercise identity from a name.
    const match=/^(\d{4})(?:[-_](180|360|720|1080)(?:x\2)?)?\.gif$/i.exec(path.posix.basename(file));
    if(!match||!valid.has(match[1]))continue;
    const folderSize=/(?:^|\/)(180|360|720|1080)(?:x\1)?(?:[-_][^/]*)?(?:\/|$)/i.exec(file)?.[1];
    const size=Number(match[2]??folderSize??0);
    if(size&&size!==resolution)continue;
    const candidates=byId.get(match[1])??[];candidates.push(file);byId.set(match[1],candidates);
  }
  for(const [id,candidates] of byId)if(candidates.length!==1)
    throw Error(`Ambiguous GIF files for ${id}; use --resolution or an explicit manifest`);
  const sourceFiles=files.filter(file=>/^exercises(?:[-_]data)?\.json$/i.test(path.posix.basename(file)));
  if(sourceFiles.length>1)throw Error('Multiple source datasets; use an explicit manifest');
  if(sourceFiles.length){
    const value=JSON.parse(await fs.readFile(path.join(pack,sourceFiles[0]),'utf8'));
    const rows=Array.isArray(value)?value:value.exercises??value.data;
    if(!Array.isArray(rows))throw Error('Unexpected ExerciseDB metadata format');
    const sourceIds=new Set();
    for(const row of rows){
      if(typeof row.id!=='string'||sourceIds.has(row.id))throw Error('Source exercise IDs must be unique strings');
      sourceIds.add(row.id);
      if(byId.has(row.id)&&normalize(row.name??'')!==normalize(valid.get(row.id).name))
        throw Error(`Exercise name changed for ${row.id}; review the mapping before import`);
    }
    for(const id of byId.keys())if(!sourceIds.has(id))throw Error(`GIF ${id} has no source metadata record`);
  }
  const missing=metadata.filter(e=>!byId.has(e.externalId)).map(e=>e.externalId);
  const manifest={author:'ExerciseDB.io',license:'ExerciseDB purchased product license',
    licenseUrl:'https://exercisedb.io/terms',sourceUrl:'https://exercisedb.io/',
    licenseFile:licenseCandidates[0],videos:metadata.filter(e=>byId.has(e.externalId))
      .map(e=>({externalId:e.externalId,name:e.name,media:byId.get(e.externalId)[0]}))};
  return {manifest,packDirectory:pack,coverage:{total:metadata.length,found:manifest.videos.length,missing}};
}

if(process.argv[1]&&import.meta.url===pathToFileURL(path.resolve(process.argv[1])).href){
  const packDirectory=process.argv[2];
  if(!packDirectory)throw Error('Usage: node backend/scripts/importExerciseDbPack.mjs <extracted-pack-folder> [--resolution 360] [--check-only]');
  const resolutionIndex=process.argv.indexOf('--resolution');
  const prepared=await prepareExerciseDbPack({packDirectory,resolution:resolutionIndex<0?360:Number(process.argv[resolutionIndex+1])});
  console.log(JSON.stringify(prepared.coverage,null,2));
  if(!process.argv.includes('--check-only')){
    // Demand a complete supplied pack, even if reviewed wger clips could fill
    // its missing IDs. An incomplete purchase must not silently pass.
    if(prepared.coverage.missing.length)throw Error('The supplied pack is incomplete. No app assets were changed.');
    await importWorkoutMedia({...prepared,requireFull:true});
    console.log('Full exercise media imported. Rebuild Flutter and restart the backend.');
  }
}
