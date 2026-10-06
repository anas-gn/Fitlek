// Keep this host edit reviewable: restore its original formatting only when
// the current file has exactly the same tokens as the two intended changes.
import fs from 'node:fs';
import {execFileSync} from 'node:child_process';
import assert from 'node:assert/strict';
const file='lib/screens/ENG/clientHome.dart';
const original=execFileSync('git',['show',`HEAD:${file}`],{encoding:'utf8'});
assert.ok(original.includes('              const WorkoutHomeScreen(),'));
assert.ok(original.includes('            onTap: () => setState(() => _navIndex = 4),'));
const next=original.replace('              const WorkoutHomeScreen(),\n','').replace(
  '            onTap: () => setState(() => _navIndex = 4),',
  '            onTap: () => Navigator.push(context,\n                MaterialPageRoute(builder: (_) => const WorkoutHomeScreen())),');
const current=fs.readFileSync(file,'utf8');
assert.equal(current.replace(/\s/g,''),next.replace(/\s/g,''),'Other edits detected; do not overwrite');
fs.writeFileSync(file,next);
console.log('Retained original host formatting around the full-screen Workout route.');
