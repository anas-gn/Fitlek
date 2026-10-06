// One-off guarded extraction of the two existing planning sheets. Persistence,
// authorization, atomic moves and historical start behavior stay in the host.
import fs from 'node:fs';
import assert from 'node:assert/strict';
const file='lib/screens/ENG/workout/workout_home.dart';
let source=fs.readFileSync(file,'utf8').replaceAll('\r\n','\n');
const weekStart=source.indexOf('  Future<void> _assignWeekday(');
const weekEnd=source.indexOf('  Future<void> _moveDay(',weekStart);
assert.ok(weekStart>0 && weekEnd>weekStart);
assert.ok(source.slice(weekStart,weekEnd).includes('CheckboxListTile'));
source=source.slice(0,weekStart)+`  Future<void> _assignWeekday(int weekday) async {
    final result = await workoutRoutineChoice(context,
        title: WorkoutText.weekdays[weekday - 1], routines: _days,
        selected: _baseDays(weekday).map((day) => day.id));
    if (result == null || !mounted) return;
    try {
      await WorkoutService.put('/week', {
        'weekday': weekday, 'dayIDs': result.dayIDs,
        'reset': result.action == 'reset'
      });
      if (mounted) await _load();
    } catch (error) {
      if (mounted) workoutError(context, error);
    }
  }

`+source.slice(weekEnd);
const dateStart=source.indexOf('  Future<void> _chooseDay(');
const dateEnd=source.indexOf('\n}\n\nclass WorkoutDayScreen',dateStart);
assert.ok(dateStart>0 && dateEnd>dateStart);
assert.ok(source.slice(dateStart,dateEnd).includes('CheckboxListTile'));
source=source.slice(0,dateStart)+`  Future<void> _chooseDay(DateTime date) async {
    final selected = _scheduled(date).map((day) => day.id).toList();
    final base = _baseDays(date.weekday);
    final result = await workoutRoutineChoice(context,
        title: workoutDate(date), routines: _days, selected: selected,
        weeklyContext: base.isEmpty ? 'Rest day' : base.map((day) => day.name).join(' + '),
        changed: _overrides.contains(_dateKey(date)),
        allowMove: selected.isNotEmpty,
        allowStart: selected.isNotEmpty || date.isBefore(_now));
    if (result == null || !mounted) return;
    if (result.action == 'move') {
      await _moveDay(date);
      return;
    }
    if (result.action == 'start') {
      await _startSelection(initial: result.dayIDs, date: date);
      return;
    }
    try {
      await WorkoutService.put('/schedule', {
        'date': _dateKey(date), 'dayIDs': result.dayIDs,
        'reset': result.action == 'reset'
      });
      if (mounted) await _load();
    } catch (error) {
      if (mounted) workoutError(context, error);
    }
  }
`+source.slice(dateEnd);
source=source.replace("import 'workout_calendar.dart';", "import 'workout_calendar.dart';\nimport 'workout_planning.dart';");
fs.writeFileSync(file,source);
console.log('Extracted planning choices; retained host write/move/start handlers.');
