// Record fresh evidence in the existing working matrix; never infer UI parity
// from a test count or recreate the historical baseline after recovery edits.
import fs from 'node:fs';
import assert from 'node:assert/strict';
const file = 'docs/WORKOUT_RECOVERY_CURRENT.md';
const flutter = fs.readFileSync('workout_tmp/final-all-flutter.log', 'utf8');
const backend = fs.readFileSync('workout_tmp/final-backend.log', 'utf8');
const analysis = fs.readFileSync('workout_tmp/final-analysis.log', 'utf8');
assert.match(flutter, /All tests passed!/);
assert.match(backend, /# fail 0\b/);
assert.match(analysis, /No issues found!/);
const accepted = new Set([
  'Weight delta interpretation', 'Empty Home onboarding',
  'Routine delete', 'Exercise order/supersets', 'Library search',
  'Body-part/equipment filters', 'Custom exercise history/statistics',
  'Previous-performance prefill', 'Confirm working weight',
  'Persistence/resume/exit', 'Rest start/stop rules', 'Rest controls',
  'Timed work countdown', 'Timed loaded exercise', 'Cardio',
  'Bodyweight/per-side sets', 'Linear/Greyskull progression',
  'Double progression', 'Time/bodyweight progression', 'Estimated 1RM',
  'Chosen exercises', 'Half-point RIR', 'Per-side prescription',
  'Routine/history units', 'Custom cardio defaults',
  'Picker/configuration stacking', 'Unconfirmed previous load',
  'Personal double progression success', 'Paired completion verification'
]);
const changes = {
  'Custom cardio defaults': [
    'Body-part chips derive cardio mode automatically; minimal API creation and reference plan import retain duration/speed and custom identity.',
    'Fresh: custom-flow widget creation/selection and backend default/import regression pass.'
  ],
  'Picker/configuration stacking': [
    'Routine and active-workout configuration open above the retained picker; Cancel preserves filters and Save adds without closing the picker. Coach assignment closes the picker explicitly.',
    'Fresh: Cancel, Save, retained Chosen selection and Coach assignment pass at tested widths.'
  ],
  'Unconfirmed previous load': [
    'Session snapshot separates confirmed workingWeight from lifetime bestWeight. Without confirmation, the prior positional/final-set load prefills the grid; no fabricated values.',
    'Fresh MySQL: 80 kg then 40 kg unconfirmed retains previous 40 kg and best 80 kg; confirmed 65 kg retains working 65 kg separately.'
  ],
  'Personal double progression success': [
    'Personal progression evaluates the last actual target and actual consecutive failures. Original Coach prescription rules remain a host-specific extension.',
    'Fresh backend regression: reduced prior target success and miss/reset sequence pass.'
  ],
  'Paired completion verification': [
    'Actual reference FinishSummary and native finish-to-summary captures use the same one-set/600 kg/30-minute fixture at 396 and 1100 pixels. Native uses bundled MIT contours.',
    'Fresh paired artifacts and native locked-summary/explicit-Home-return checks pass. Overall dialog styling is assessed separately.'
  ],
  'Exercise configuration': [
    'Sets, reps/seconds/minutes and load/speed use one compact row; bodyweight and per-side controls sit together; mode, progression, rest and optional Coach fields persist. Material controls remain visually different.',
    'Fresh: mode/per-side/odd-total guards, retained picker, 320/396/1100 editor and Coach assignment checks pass; paired configuration captures refreshed.'
  ],
  'Personal routine editor': [
    'Live autosave/retry, stable identities, adjacent links, ordering, MIT muscle preview and stacked picker/configuration. Material controls and spacing remain visual adaptations.',
    'Fresh recovery/responsive suites pass; editor/configuration captures refreshed at 396 and 1100.'
  ],
  'Custom exercise create': [
    'Compact name/body-part chips/optional description form; richer metadata is behind More exercise options. Cardio is inferred from the chosen body part.',
    'Fresh minimal cardio widget flow and real MySQL custom lifecycle/duplicate ownership tests pass; native custom form is not yet paired visually.'
  ],
  'Minimal custom exercise': [
    'Name/body part suffice; description and advanced fields optional. Stable private identity and duplicate-name guards; created exercise selects immediately.',
    'Fresh custom-flow widget and MySQL creation/history/isolation checks pass; exact sheet spacing remains unverified.'
  ],
  'Completion summary': [
    'Locked centered dialog capped at 300 px, compact actual metric rows, separate load/e1RM records, MIT muscle figures and explicit Nice! return. Dynamic metric heights handle enlarged text.',
    'Fresh flow/capture tests at 320/396/1100 plus EN/FR/ES responsive cases pass; paired reference summary added. Typography, backdrop and native controls still differ.'
  ],
  'Routine muscle preview': [
    'Live planned effective sets on the same separately MIT-licensed MuscleMap region contours; native parsing, painting, selection and figure preference.',
    'Fresh anatomy contour/hit tests for both figures and responsive coverage tests pass; paired editor captures refreshed.'
  ],
  'Muscle visualization': [
    'Bundled MIT MuscleMap coordinate data for male/female front/back replaces divergent contours in coverage, Stats and summary. Native SVG-path parsing and precise hit testing; separate legacy explorer retained.',
    'Fresh four-view geometry and male/female interaction tests pass; assets, license and provenance bundled. Remaining legend/control styling prevents an exact visual claim.'
  ],
  'Muscle statistics': [
    'Independent periods/all-hard controls, missed groups, primary 1/secondary .4 effective sets and selectable MIT front/back anatomy; native legend/chips differ.',
    'Fresh backend region/effort fixtures and anatomy/responsive suites pass; paired Stats captures refreshed.'
  ],
  'Library pagination/loading/empty': [
    'Library pages contain 40 records; routine picker pages contain 50, matching the source. Show more, loading/error/no-match and filter pagination resets retained.',
    'Fresh API/library/recovery suites pass. Dedicated full picker-page boundary interaction is not asserted.'
  ],
  'Responsive visual system': [
    'Reference neutral surfaces/accent, five persistent tabs, wide Plan/Stats columns, bounded sheets, compact configuration and summary. Material styling and chart presentation remain visual gaps.',
    'Fresh EN/FR/ES enlarged-text/long-name responsive checks and paired 396/1100 captures pass; no pixel-equality assertion.'
  ],
  'Home hierarchy': [
    'Combined week/Today card, optional onboarding, dated weight/goal/chart and streak/calendar follow source hierarchy. Capture clock is fixed to the same reference date; native spacing/chart styling differ.',
    'Fresh Home flow/responsive checks and same-date paired 396/1100 captures pass.'
  ]
};
let matrix = fs.readFileSync(file, 'utf8');
matrix = matrix.replace('Fresh checks are pending. Previously accepted rows are conservatively PARTIAL until the current evidence is recorded; unresolved source-media rights remain BLOCKED - LICENSE.',
  'Fresh revalidation recorded on 2026-10-05. Status covers the whole row: passing behavior tests do not promote a visibly different screen. Accepted logic/interaction rows have current regression evidence; remaining UI gaps stay PARTIAL. Original demonstration-media rights remain BLOCKED - LICENSE.');
matrix = matrix.split('\n').map(line => {
  if (!line.startsWith('| ') || line.startsWith('| openGym') || line.startsWith('| ---')) return line;
  const cells = line.split('|').slice(1, -1).map(v => v.trim());
  assert.equal(cells.length, 9);
  const [feature] = cells;
  if (accepted.has(feature)) cells[7] = 'EXACT / ACCEPTABLE PARITY';
  if (changes[feature]) [cells[5], cells[8]] = changes[feature];
  else if (cells[7].startsWith('EXCLUDED')) cells[8] = 'Outside requested Workout parity scope; existing SIRVYA identity/roles/settings retained.';
  else cells[8] = cells[8].replace(/^Historical: /, 'Existing assertions rerun successfully: ').replace(/Fresh revalidation pending\.?/g, 'Fresh full Workout backend/Flutter suites pass; device or visual caveats above still apply.');
  return '| ' + cells.join(' | ') + ' |';
}).join('\n');
const mediaRow = '| Demonstration playback/size | components/Media.jsx; store/useStore.js gifSize | Default playback; reduced motion adaptation; minimize choice survives exercises and later workouts | Media with size/play controls | Play or pause; minimize then revisit | Licensed native frame playback defaults on; reduced motion disables it; full/mini is validated and saved in existing account-scoped Workout preferences; API failure restores the prior size | W/workout_demonstration.dart; B/services/workoutExperience.js | EXACT / ACCEPTABLE PARITY | Fresh playback/accessibility/disposal and recreate-after-minimize preference-preservation tests pass. Original catalog GIF coverage remains separately license-blocked. |';
if (!matrix.includes('| Demonstration playback/size |')) matrix += '\n' + mediaRow + '\n';
fs.writeFileSync(file, matrix);
const statuses = {};
for (const line of matrix.split('\n').filter(l => l.startsWith('| ') && !l.startsWith('| openGym') && !l.startsWith('| ---'))) {
  const status = line.split('|')[8].trim();
  statuses[status] = (statuses[status] || 0) + 1;
}
console.log(JSON.stringify({rows: Object.values(statuses).reduce((a,b)=>a+b,0), statuses}));
