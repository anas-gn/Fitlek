import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {hasWorkoutVideo,workoutVideoFilter} from '../services/workoutVideos.js';
import seeds from '../data/workoutExercises.js';

test('media filtering recognizes supplied GIF/MP4 URLs without fake catalog identities',()=>{
  for(const videoUrl of ['https://media.example/demo.GIF?version=1','/uploads/demo.mp4'])
    assert.equal(hasWorkoutVideo({videoUrl}),true);
  for(const videoUrl of ['javascript:demo.gif','//media.example/demo.gif','https://youtube.com/watch?v=demo',null])
    assert.equal(hasWorkoutVideo({videoUrl}),false);
  assert.match(workoutVideoFilter().sql,/e\.videoUrl/);
});

test('real video assets retain attribution, stable reviewed identities and exact audited bytes',async()=>{
  const metadata=JSON.parse(await fs.readFile(new URL('../data/exerciseMetadata.json',import.meta.url),'utf8'));
  const valid=new Set([...metadata.map(e=>`exercises-dataset:${e.externalId}`),...seeds.map(e=>`sirvya:${e.externalId}`)]);
  const catalog=JSON.parse(await fs.readFile(new URL('../../assets/workout/videos/catalog.json',import.meta.url),'utf8'));
  const sources=JSON.parse(await fs.readFile(new URL('../data/workoutVideoSources.json',import.meta.url),'utf8'));
  assert.equal(catalog.videos.length,sources.length);
  assert.deepEqual(catalog.videos.map(v=>[v.videoID,v.targets]),sources.map(v=>[v.videoID,v.targets]));
  // wger 70 duplicates the exact bytes of ordinary pull-up 71. It is not a
  // verified assisted-machine demonstration and must not be attached to 0017.
  assert.equal(catalog.videos.some(v=>v.videoID===70),false);
  assert.equal(sources.some(v=>v.targets.some(([source,id])=>source==='exercises-dataset'&&id==='0017')),false);
  const romanian=catalog.videos.find(v=>v.videoID===2);
  assert.deepEqual(romanian.targets,[['exercises-dataset','1459']]);
  assert.match(romanian.reviewNote,/shows dumbbells/);
  const mapped=new Set();
  for(const video of catalog.videos){
    assert.equal(video.author,'Goulart');assert.equal(video.license,'CC BY-SA 4.0');
    assert.equal(video.licenseUrl,'https://creativecommons.org/licenses/by-sa/4.0/');
    assert.equal(video.modified,true);assert.match(video.modifications,/H.264/);
    assert.equal(new URL(video.sourceUrl).origin,'https://wger.de');
    assert.ok(video.durationSeconds>0);assert.ok(video.width<=640&&video.height<=640);
    for(const [source,id] of video.targets){const key=`${source}:${id}`;assert.ok(valid.has(key));assert.ok(!mapped.has(key));mapped.add(key);
      assert.equal(hasWorkoutVideo({externalSource:source,externalId:id}),true);}
    for(const [asset,expected] of [[video.asset,video.sha256],[video.poster,video.posterSha256]]){
      assert.match(asset,/^assets\/workout\/videos\/wger-\d+\.(mp4|jpg)$/);
      const bytes=await fs.readFile(new URL('../../'+asset,import.meta.url));
      assert.equal(createHash('sha256').update(bytes).digest('hex'),expected);
      if(asset.endsWith('.mp4')){assert.equal(bytes.toString('ascii',4,8),'ftyp');assert.ok(bytes.length>1000);}
    }
  }
  assert.equal(hasWorkoutVideo({externalSource:'sirvya-custom',externalId:'0025'}),false);
  const filter=workoutVideoFilter();assert.ok(filter.sql.includes('e.externalSource=?'));assert.ok(filter.params.includes('exercises-dataset'));
  assert.equal(await fs.readFile(new URL('../../assets/workout/videos/LICENSE.txt',import.meta.url),'utf8'),await fs.readFile(new URL('../../docs/licenses/CC-BY-SA-4.0.txt',import.meta.url),'utf8'));
});
