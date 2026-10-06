import fs from 'node:fs';
import crypto from 'node:crypto';

// Only the separately MIT-licensed MuscleMap vector coordinates are retained.
// No openGym application code is evaluated or included in the generated asset.
const reference = new URL('../../workout_tmp/requested-reference/', import.meta.url);
const source = fs.readFileSync(new URL('frontend/src/lib/body-paths.js', reference), 'utf8');
const notice = fs.readFileSync(new URL('NOTICE.md', reference), 'utf8');
const geometry = JSON.parse(source.slice(source.indexOf('export default ') + 15).trim());
const section = notice.split('## Body diagram geometry')[1]?.split('## Exercise data')[0];
const license = section?.match(/```\s*([\s\S]*?)\s*```/)[1];
if (!license?.includes('MIT License') || !license.includes('Melih Colpan')) {
  throw Error('Missing geometry-specific license; refusing to extract assets.');
}
for (const body of ['male', 'female']) for (const side of ['front', 'back']) {
  const view = geometry[body]?.[side];
  if (!view?.vb || !view.p?.chest && side === 'front') throw Error('Incomplete anatomy geometry');
}
const target = new URL('../../assets/workout/anatomy/', import.meta.url);
fs.mkdirSync(target, {recursive: true});
const bytes = JSON.stringify(geometry) + '\n';
fs.writeFileSync(new URL('musclemap.json', target), bytes);
fs.writeFileSync(new URL('LICENSE.txt', target), license + '\n');
fs.writeFileSync(new URL('provenance.json', target), JSON.stringify({
  author: 'Melih Colpan', license: 'MIT', upstream: 'https://github.com/melihcolpan/MuscleMap',
  referenceCommit: 'c42ba6b98e3776af5981f20c05ba392238799670',
  referenceAsset: 'frontend/src/lib/body-paths.js',
  transformation: 'Retained coordinate data only; renderer authored natively in Flutter',
  sha256: crypto.createHash('sha256').update(bytes).digest('hex')
}, null, 2) + '\n');
console.log('Bundled four MIT anatomy views with license and provenance. Exercise data untouched.');
