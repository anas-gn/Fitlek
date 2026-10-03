import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import {createHash} from 'node:crypto';
import sharp from 'sharp';
import seeds from '../data/workoutExercises.js';

test('bundled demonstrations retain audited licenses, exact bytes and unique stable catalog identities',async()=>{
  const metadata=JSON.parse(await fs.readFile(new URL('../data/exerciseMetadata.json',import.meta.url),'utf8'));
  const identities=new Set([...metadata.map(e=>`exercises-dataset:${e.externalId}`),...seeds.map(e=>`sirvya:${e.externalId}`)]);
  const catalog=JSON.parse(await fs.readFile(new URL('../../assets/workout/demonstrations/catalog.json',import.meta.url),'utf8'));
  const mapped=new Set();
  assert.equal(catalog.demonstrations.length,19);
  for(const d of catalog.demonstrations){
    assert.equal(d.license,'CC BY-SA 3.0');assert.equal(d.licenseUrl,'https://creativecommons.org/licenses/by-sa/3.0/');assert.equal(d.modified,false);
    assert.equal(d.frames.length,2);
    for(const [source,id] of d.targets){const key=`${source}:${id}`;assert.ok(identities.has(key));assert.ok(!mapped.has(key));mapped.add(key);}
    for(const frame of d.frames){
      assert.equal(frame.author,'Everkinetic');assert.match(frame.asset,/^assets\/workout\/demonstrations\/wger-\d+\.png$/);
      assert.equal(new URL(frame.sourceUrl).origin,'https://wger.de');
      const bytes=await fs.readFile(new URL('../../'+frame.asset,import.meta.url));
      assert.equal(createHash('sha256').update(bytes).digest('hex'),frame.sha256);
      const image=await sharp(bytes).metadata();assert.equal(image.format,'png');assert.ok(image.width>0&&image.height>0);
    }
  }
  const docs=await fs.readFile(new URL('../../docs/licenses/CC-BY-SA-3.0.txt',import.meta.url),'utf8');
  assert.equal(await fs.readFile(new URL('../../assets/workout/demonstrations/LICENSE.txt',import.meta.url),'utf8'),docs);
});
