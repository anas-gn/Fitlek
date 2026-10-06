// Metadata only. Never download the separately licensed images or animations.
import fs from 'node:fs/promises';
const repository='hasaneyldrm/exercises-dataset';
// Update only after auditing the new revision and its licenses.
const sha='7455efae41b330c265e7cd4b78dfa848e7ce5ebd';
const base=`https://raw.githubusercontent.com/${repository}/${sha}`;
const [licenseResponse,dataResponse]=await Promise.all([fetch(`${base}/LICENSE`),fetch(`${base}/data/exercises.json`)]);
if(!licenseResponse.ok||!dataResponse.ok)throw new Error('Metadata download failed');
const license=await licenseResponse.text();
if(!license.startsWith('MIT License')||!license.includes('MEDIA EXCEPTION'))throw new Error('Exercise licensing changed; review required');
const original=await dataResponse.json();
const data=original.map(e=>({externalId:e.id,name:e.name,bodyPart:e.body_part,muscleGroup:e.target||e.body_part,
  secondaryMuscles:e.secondary_muscles||[],equipment:e.equipment,
  exerciseType:e.body_part==='cardio'?'cardio':/\b(plank|hold|stretch)\b/i.test(e.name)?'timed':'reps',
  isBodyweight:e.equipment==='body weight',instructions:e.instruction_steps.en,
  instructionTranslations:Object.fromEntries(['en','fr','es'].map(l=>[l,e.instruction_steps[l]||e.instruction_steps.en]))}));
if(data.length<1000||new Set(data.map(e=>e.externalId)).size!==data.length||data.some(e=>!Array.isArray(e.instructions)))throw new Error('Unexpected metadata format');
await fs.writeFile(new URL('../data/exerciseMetadata.json',import.meta.url),JSON.stringify(data));
await fs.mkdir(new URL('../../docs/licenses/',import.meta.url),{recursive:true});
await fs.writeFile(new URL('../../docs/licenses/exercises-dataset-LICENSE.txt',import.meta.url),license);
// Preserve the complete third-party notice, including fonts and reference review.
console.log(`Imported ${data.length} metadata records, source revision ${sha.slice(0,12)}; no media.`);
