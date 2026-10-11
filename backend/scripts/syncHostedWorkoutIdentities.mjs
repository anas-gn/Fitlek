// Import MIT metadata identities only; media stays on the provider's CDN.
import {readFile,writeFile} from 'node:fs/promises';
const revision='7455efae41b330c265e7cd4b78dfa848e7ce5ebd';
const base=`https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/${revision}`;
const localFile=process.argv[2];
const license=localFile?await readFile(new URL('../../docs/licenses/exercises-dataset-LICENSE.txt',import.meta.url),'utf8'):
  await (await fetch(`${base}/LICENSE`,{signal:AbortSignal.timeout(30000)})).text();
if(!license.startsWith('MIT License')||!license.includes('MEDIA EXCEPTION'))throw new Error('Metadata license changed');
const source=localFile?JSON.parse(await readFile(localFile,'utf8')):
  await (await fetch(`${base}/data/exercises.json`,{signal:AbortSignal.timeout(90000)})).json();
const local=JSON.parse(await readFile(new URL('../data/exerciseMetadata.json',import.meta.url),'utf8'));
const rows=local.map(e=>{
  const original=source.find(row=>row.id===e.externalId);
  if(!original||original.name!==e.name||original.equipment!==e.equipment||! /^[A-Za-z0-9_-]+$/.test(original.media_id||''))throw new Error(`Unverified identity ${e.externalId}`);
  return {externalId:e.externalId,providerId:original.media_id,name:e.name,equipment:e.equipment};
});
if(rows.length!==1324||new Set(rows.map(e=>e.providerId)).size!==rows.length)throw new Error('Unexpected identity coverage');
await writeFile(new URL('../data/hostedWorkoutIdentities.json',import.meta.url),JSON.stringify({source:`${base}/data/exercises.json`,revision,license:'MIT (metadata only)',exercises:rows},null,2)+'\n');
console.log(`Verified ${rows.length} hosted exercise identities. No API responses or media stored.`);
