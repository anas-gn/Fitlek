import fs from 'node:fs';

// Preserve the previous audit as historical evidence; consolidate its latest
// source-linked rows into one current working matrix before making changes.
const previous = fs.readFileSync(new URL('../../docs/WORKOUT_PRODUCT_PARITY.md', import.meta.url), 'utf8');
const lines = previous.split(/\r?\n/);
const start = lines.findIndex(line => line.startsWith('## Recovery implementation'));
const end = lines.findIndex((line, index) => index > start && line.startsWith('### Verification evidence'));
const current = new Map();
for (const line of lines.slice(start, end)) {
  if (!line.startsWith('| ') || line.startsWith('| openGym') || line.startsWith('| ---')) continue;
  const cells = line.split('|').slice(1, -1).map(cell => cell.trim());
  current.set(cells[0], cells);
}
const updates = lines.findIndex(line => line.startsWith('## Recovery after reinspection'));
for (const line of lines.slice(updates)) {
  if (!line.startsWith('| ') || line.startsWith('| openGym') || line.startsWith('| ---')) continue;
  const cells = line.split('|').slice(1, -1).map(cell => cell.trim());
  current.set(cells[0], cells);
}
for (const cells of current.values()) {
  // Passing an old suite is not current visual/interaction verification.
  if (cells[7] === 'EXACT / ACCEPTABLE PARITY') cells[7] = 'PARTIAL';
  cells[8] = `Historical: ${cells[8]} Fresh revalidation pending.`;
}
const findings = [
  ['Custom cardio defaults', 'lib/exercises.js isCardio; sheets.jsx CustomExForm', 'Choosing cardio makes a custom exercise log time and speed', 'Name, body-part chips, optional description', 'Create cardio → select → configure/log', 'Form and validator default to reps even for cardio body part', 'W/exercise_library.dart; B/services/work​outDomain.js'.replace('\u200b', ''), 'WRONG IMPLEMENTATION', 'Regression not yet present'],
  ['Picker/configuration stacking', 'sheets.jsx ExercisePicker/ExConfig; components/Modals.jsx', 'Configuration appears above picker; dismiss returns to same search/filter', 'Stacked bounded sheets', 'Pick → configure → cancel → picker; Save adds and retains picker', 'Picker is popped before configuration; cancellation loses search/filter context', 'W/exercise_library.dart; workout_builder.dart; active_workout.dart', 'WRONG IMPLEMENTATION', 'Existing recovery test proves bounded sheet only'],
  ['Unconfirmed previous load', 'lib/history.js buildSets; sheets.jsx TopWeight', 'Confirmed highest load wins; without confirmation use previous positional set', 'Real previous values and prefilled grid', 'Log lower recent session without confirming → restart', 'Session start puts lifetime best into workingWeight even without confirmation', 'B/routes/anas/workout.js; W/workout_set_row.dart', 'WRONG IMPLEMENTATION', 'Existing test checks a confirmed load but misses no-confirmation branch'],
  ['Personal double progression success', 'lib/progression.js readSession/nextPrescription', 'Success uses the actual last target; consecutive misses determine reset', 'Reason and next target above set grid', 'Hit a reduced previous target → next prescription', 'Uses original range ceiling and counts ceiling misses instead of actual-target misses', 'B/services/workoutExperience.js', 'WRONG IMPLEMENTATION', 'Existing fixtures omit changed-target sequence'],
  ['Paired completion verification', 'sheets.jsx FinishSummary', 'Locked summary shows actual sets, volume, duration, records and muscles', 'Centered summary', 'Finish → summary → explicit return Home', 'Native summary captures exist; matching reference capture missing', 'B/scripts/captureWorkoutReference.mjs; test/workout_visual_parity_test.dart', 'PARTIAL', 'Native-only screenshots do not prove paired parity'],
];
for (const cells of findings) current.set(cells[0], cells);
const header = `# Current SIRVYA Workout recovery matrix\n\nReference: [requested openGym](https://github.com/arvids-unavailable/openGym/tree/c42ba6b98e3776af5981f20c05ba392238799670), commit c42ba6b98e3776af5981f20c05ba392238799670. Remote main verified on 2026-10-04; local checkout workout_tmp/requested-reference.\n\nThis is the single working matrix for the current correction. [Previous audit](WORKOUT_PRODUCT_PARITY.md) and its pass counts are historical evidence. Rows are consolidated from the source-linked audit, then rechecked against code. No class name, old test pass or dataset identity establishes product parity. Behaviour, visual structure, interaction and test evidence remain separate.\n\nScope: openGym workout routes, sheets, stores, algorithms, charts, CSS and transitions; SIRVYA Flutter, existing JWT/users, linked Coach/Client authorization, API and MySQL remain the host. No dataset reimport is required. W/ = lib/screens/ENG/workout/; B/ = backend/.\n\nFresh checks are pending. Previously accepted rows are conservatively PARTIAL until the current evidence is recorded; unresolved source-media rights remain BLOCKED - LICENSE.\n\n| openGym feature/screen | openGym source files | openGym behavior | openGym visual structure | openGym interaction flow | current SIRVYA implementation | SIRVYA source files | status | test status |\n| --- | --- | --- | --- | --- | --- | --- | --- | --- |\n`;
fs.writeFileSync(new URL('../../docs/WORKOUT_RECOVERY_CURRENT.md', import.meta.url), header + [...current.values()].map(cells => `| ${cells.join(' | ')} |`).join('\n') + '\n');
console.log(`Consolidated ${current.size} source-linked rows; historical audit preserved.`);
