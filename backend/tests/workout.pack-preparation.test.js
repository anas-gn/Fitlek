import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {prepareExerciseDbPack} from '../scripts/importExerciseDbPack.mjs';
import {importWorkoutMedia} from '../scripts/importWorkoutMedia.mjs';
import {spawnSync} from 'node:child_process';

async function fixture(t){
  const directory=await fs.mkdtemp(path.join(os.tmpdir(),'sirvya-pack-preparation-'));
  t.after(()=>fs.rm(directory,{recursive:true,force:true}));
  const workspace=path.join(directory,'workspace'),packDirectory=path.join(directory,'pack');
  await fs.mkdir(path.join(workspace,'backend/data'),{recursive:true});
  await fs.mkdir(path.join(workspace,'assets/workout/videos'),{recursive:true});
  await fs.writeFile(path.join(workspace,'assets/workout/videos/catalog.json'),JSON.stringify({videos:[]}));
  await fs.writeFile(path.join(workspace,'backend/data/exerciseMetadata.json'),JSON.stringify([
    {externalId:'0001',name:'First exercise'},{externalId:'0002',name:'Second exercise'},
  ]));
  await fs.mkdir(path.join(packDirectory,'360x360'),{recursive:true});
  await fs.writeFile(path.join(packDirectory,'EULA.txt'),'Created only for this regression fixture.');
  for(const id of ['0001','0002'])await fs.copyFile(new URL('../../test/fixtures/exercise-demo.gif',import.meta.url),
    path.join(packDirectory,'360x360',`${id}.gif`));
  return {directory,workspace,packDirectory};
}

test('pack preparation maps every leading-zero ID and selects the requested GIF resolution',async t=>{
  const f=await fixture(t);
  await fs.mkdir(path.join(f.packDirectory,'180x180'));
  await fs.writeFile(path.join(f.packDirectory,'180x180','0001.gif'),'other resolution');
  const result=await prepareExerciseDbPack(f);
  assert.deepEqual(result.coverage,{total:2,found:2,missing:[]});
  assert.deepEqual(result.manifest.videos.map(v=>[v.externalId,v.media]),[
    ['0001','360x360/0001.gif'],['0002','360x360/0002.gif'],
  ]);
  assert.equal(result.manifest.licenseFile,'EULA.txt');
});
test('pack preparation reports missing IDs and rejects ambiguous files or changed source identities',async t=>{
  const f=await fixture(t);
  await fs.rm(path.join(f.packDirectory,'360x360','0002.gif'));
  assert.deepEqual((await prepareExerciseDbPack(f)).coverage.missing,['0002']);
  await fs.copyFile(path.join(f.packDirectory,'360x360','0001.gif'),path.join(f.packDirectory,'0001-360.gif'));
  await assert.rejects(prepareExerciseDbPack(f),/Ambiguous GIF files for 0001/);
  await fs.rm(path.join(f.packDirectory,'0001-360.gif'));
  await fs.writeFile(path.join(f.packDirectory,'exercises.json'),JSON.stringify([{id:'0001',name:'Different exercise'}]));
  await assert.rejects(prepareExerciseDbPack(f),/Exercise name changed for 0001/);
});
test('a prepared complete pack imports end to end without writing a manifest into the source folder',
  {skip:spawnSync(process.env.FFMPEG_PATH||'ffmpeg',['-version'],{windowsHide:true}).status!==0},async t=>{
    const f=await fixture(t);
    const prepared=await prepareExerciseDbPack(f);
    assert.deepEqual(await importWorkoutMedia({...prepared,workspace:f.workspace,requireFull:true}),
      {total:2,covered:2,missing:[]});
    const catalog=JSON.parse(await fs.readFile(path.join(f.workspace,'assets/workout/exercise_media/catalog.json'),'utf8'));
    assert.equal(catalog.videos.length,2);
    assert.deepEqual(catalog.videos.map(v=>v.targets),[
      [['exercises-dataset','0001']],[['exercises-dataset','0002']],
    ]);
    assert.equal((await fs.readdir(f.packDirectory)).includes('manifest.json'),false);
  });
