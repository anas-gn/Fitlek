import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {importWorkoutMedia} from '../scripts/importWorkoutMedia.mjs';
import {createHash} from 'node:crypto';

const hasFfmpeg=spawnSync(process.env.FFMPEG_PATH||'ffmpeg',['-version'],{windowsHide:true}).status===0;
async function fixture(t){
  const directory=await fs.mkdtemp(path.join(os.tmpdir(),'sirvya-media-import-'));
  t.after(()=>fs.rm(directory,{recursive:true,force:true}));
  const workspace=path.join(directory,'workspace'),pack=path.join(directory,'pack');
  for(const folder of ['backend/data','assets/workout/videos','assets/workout/exercise_media'])
    await fs.mkdir(path.join(workspace,folder),{recursive:true});
  await fs.mkdir(pack,{recursive:true});
  await fs.writeFile(path.join(workspace,'backend/data/exerciseMetadata.json'),JSON.stringify([
    {externalId:'0001',name:'First exercise'},{externalId:'0002',name:'Second exercise'},
  ]));
  await fs.writeFile(path.join(workspace,'assets/workout/videos/catalog.json'),' {"videos":[]}');
  await fs.writeFile(path.join(workspace,'assets/workout/exercise_media/catalog.json'),' {"videos":[]}');
  await fs.copyFile(new URL('../../test/fixtures/exercise-demo.gif',import.meta.url),path.join(pack,'0001.gif'));
  await fs.writeFile(path.join(pack,'LICENSE.txt'),'Fixture assets created for this test.');
  const manifest={author:'Test fixture',license:'Test fixture license',licenseUrl:'https://example.com/license',
    sourceUrl:'https://example.com/media',licenseFile:'LICENSE.txt',videos:[{externalId:'0001',media:'0001.gif'}]};
  const manifestPath=path.join(pack,'manifest.json');
  const write=()=>fs.writeFile(manifestPath,JSON.stringify(manifest));
  await write();
  return {directory,workspace,pack,manifest,manifestPath,write};
}

test('full catalog import rejects missing exercise IDs before touching media/catalogs',async t=>{
  const f=await fixture(t);
  await assert.rejects(importWorkoutMedia({...f,requireFull:true}),/1\/2 imported exercises missing/);
  assert.deepEqual(await fs.readdir(path.join(f.workspace,'assets/workout/exercise_media')),['catalog.json']);
});
test('media import rejects numeric IDs, duplicates and paths outside the supplied pack',async t=>{
  const f=await fixture(t);
  f.manifest.videos[0].externalId=1;await f.write();
  await assert.rejects(importWorkoutMedia(f),/IDs must be strings/);
  f.manifest.videos[0].externalId='0001';f.manifest.videos.push({...f.manifest.videos[0]});await f.write();
  await assert.rejects(importWorkoutMedia(f),/duplicate exercise identity/);
  f.manifest.videos.pop();
  await fs.writeFile(path.join(f.directory,'outside.gif'),'outside');
  f.manifest.videos[0].media='../outside.gif';await f.write();
  await assert.rejects(importWorkoutMedia(f),/inside the pack folder/);
});
test('licensed GIF pack becomes a playable MP4/poster with matching backend identities and coverage',
  {skip:!hasFfmpeg},async t=>{
    const f=await fixture(t);
    const coverage=await importWorkoutMedia(f);
    assert.deepEqual(coverage,{total:2,covered:1,missing:['0002']});
    const catalog=JSON.parse(await fs.readFile(path.join(f.workspace,'assets/workout/exercise_media/catalog.json'),'utf8'));
    const backend=JSON.parse(await fs.readFile(path.join(f.workspace,'backend/data/workoutMediaSources.json'),'utf8'));
    assert.deepEqual(backend[0].targets,[['exercises-dataset','0001']]);
    assert.deepEqual(catalog.videos[0].targets,backend[0].targets);
    for(const [location,expected] of [[catalog.videos[0].asset,catalog.videos[0].sha256],
      [catalog.videos[0].poster,catalog.videos[0].posterSha256]]){
      const bytes=await fs.readFile(path.join(f.workspace,location));
      assert.equal(createHash('sha256').update(bytes).digest('hex'),expected);
    }
    assert.equal(catalog.videos[0].author,'Test fixture');
    assert.match(catalog.videos[0].modifications,/Original movement speed retained/);
    assert.ok(catalog.videos[0].durationSeconds>0);
    assert.equal(await fs.readFile(path.join(f.workspace,catalog.licenses[0].asset),'utf8'),
      'Fixture assets created for this test.');
    f.manifest.videos[0].externalId='0002';await f.write();
    assert.deepEqual(await importWorkoutMedia({...f,requireFull:true}),{total:2,covered:2,missing:[]});
  });
