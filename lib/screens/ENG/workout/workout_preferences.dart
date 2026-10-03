import 'package:flutter/material.dart';
import '../../../services/workout_service.dart';
import 'workout_ui.dart';

class WorkoutPreferencesScreen extends StatefulWidget {
  const WorkoutPreferencesScreen({super.key});
  @override
  State<WorkoutPreferencesScreen> createState() =>
      _WorkoutPreferencesScreenState();
}

class _WorkoutPreferencesScreenState extends State<WorkoutPreferencesScreen> {
  Map<String, dynamic>? _preferences;
  Object? _error;
  bool _saving = false;
  final _rest = TextEditingController(),
      _restPause = TextEditingController(),
      _goal = TextEditingController(),
      _time = TextEditingController(),
      _zone = TextEditingController();
  final _form = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _rest.dispose();
    _restPause.dispose();
    _goal.dispose();
    _time.dispose();
    _zone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p = await WorkoutService.get('/preferences');
      if (!mounted) return;
      setState(() => _preferences = p);
      _rest.text = '${p['defaultRestSeconds']}';
      _restPause.text = '${p['restPauseSeconds'] ?? 15}';
      _goal.text = p['bodyweightGoal'] == null ? '' : '${p['bodyweightGoal']}';
      _time.text = p['reminderTime'];
      _zone.text = p['timeZone'];
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final p = await WorkoutService.put('/preferences', {
        ..._preferences!,
        'defaultRestSeconds': int.parse(_rest.text),
        'restPauseSeconds': int.parse(_restPause.text),
        'bodyweightGoal': _goal.text.isEmpty ? null : double.parse(_goal.text),
        'reminderTime': _time.text,
        'timeZone': _zone.text
      });
      WorkoutService.preferences = p;
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) workoutError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _switch(String key, String title) => SwitchListTile(
      title: WorkoutLabel(title),
      value: _preferences![key] == true,
      onChanged: (v) => setState(() => _preferences![key] = v));
  Widget _choice(String key, String title, Map<String, String> values) =>
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: DropdownButtonFormField<String>(
              initialValue: _preferences![key],
              decoration:
                  InputDecoration(labelText: ((title)).workoutTr(context)),
              items: values.entries
                  .map((e) => DropdownMenuItem(
                      value: e.key, child: WorkoutLabel(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _preferences![key] = v)));
  Future<void> _equipment({Map<String, dynamic>? existing}) async {
    try {
      final result = await WorkoutService.get('/exercises');
      if (!mounted) return;
      final options = List<String>.from(result['filters']['equipment']);
      final name = TextEditingController(text: existing?['name'] ?? '');
      final selected = Set<String>.from(existing?['equipment'] ?? []),
          form = GlobalKey<FormState>();
      final yes = await workoutDialog<bool>(
          context: context,
          builder: (context) => StatefulBuilder(
              builder: (context, update) => AlertDialog(
                      title: const WorkoutLabel('Equipment profile'),
                      content: SingleChildScrollView(
                          child: Form(
                              key: form,
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextFormField(
                                        controller: name,
                                        maxLength: 80,
                                        decoration: InputDecoration(
                                            labelText: ('Profile name')
                                                .workoutTr(context)),
                                        validator: (v) =>
                                            (v ?? '').trim().isEmpty
                                                ? ('Enter a profile name')
                                                    .workoutTr(context)
                                                : null),
                                    Wrap(
                                        spacing: 6,
                                        children: options
                                            .map((e) => FilterChip(
                                                label: WorkoutLabel(e),
                                                selected: selected.contains(e),
                                                onSelected: (v) => update(() {
                                                      if (v) {
                                                        selected.add(e);
                                                      } else {
                                                        selected.remove(e);
                                                      }
                                                    })))
                                            .toList())
                                  ]))),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const WorkoutLabel('Cancel')),
                        ElevatedButton(
                            onPressed: () {
                              if (form.currentState!.validate()) {
                                Navigator.pop(context, true);
                              }
                            },
                            child: const WorkoutLabel('Save'))
                      ])));
      if (yes != true || !mounted) return;
      final profile = {
        'name': name.text.trim(),
        'equipment': selected.toList()
      };
      final rows = List<Map<String, dynamic>>.from(
          (_preferences!['equipmentProfiles'] as List)
              .map((v) => Map<String, dynamic>.from(v)));
      if (rows.any((r) =>
          r['name'] == profile['name'] && r['name'] != existing?['name'])) {
        workoutError(
            context, const WorkoutApiException('invalid_workout', 400));
        return;
      }
      rows.removeWhere((v) => v['name'] == existing?['name']);
      rows.add(profile);
      setState(() {
        _preferences!['equipmentProfiles'] = rows;
        if (_preferences!['activeEquipmentProfile'] == existing?['name']) {
          _preferences!['activeEquipmentProfile'] = profile['name'];
        }
      });
    } catch (e) {
      if (mounted) workoutError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) => WorkoutScaffold(
      appBar: AppBar(title: const WorkoutLabel('Workout preferences')),
      body: _error != null
          ? WorkoutFailure(
              error: _error!,
              retry: () {
                setState(() => _error = null);
                _load();
              })
          : _preferences == null
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _form,
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    Card(
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(children: [
                              _choice('unit', 'Load units',
                                  {'kg': 'Kilograms', 'lb': 'Pounds'}),
                              _choice('view', 'Workout view', {
                                'cards': 'Exercise cards',
                                'compact': 'Compact set rows',
                                'guided': 'Guided set entry'
                              }),
                              _choice('effort', 'Effort scale',
                                  {'off': 'Off', 'rpe': 'RPE', 'rir': 'RIR'}),
                              TextFormField(
                                  controller: _rest,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                      labelText: (('Default rest (sec)'))
                                          .workoutTr(context)),
                                  validator: (v) {
                                    final n = int.tryParse(v ?? '');
                                    return n == null || n < 0 || n > 3600
                                        ? (((('Enter 0–3600 seconds')
                                            .workoutTr(context))))
                                        : null;
                                  })
                            ]))),
                    Card(
                        child: Column(children: [
                      _switch('automaticRest', 'Start rest after sets'),
                      _switch('timerSound', 'Timer sound'),
                      _switch('timerVibration', 'Timer vibration'),
                      _switch('timerFlash', 'Flash when rest finishes'),
                      _switch('keepAwake', 'Keep screen awake during workouts')
                    ])),
                    Card(
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(children: [
                              _switch('bodyweightCheckIn',
                                  'Offer body weight check-in before workouts'),
                              TextFormField(
                                  controller: _goal,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: InputDecoration(
                                      labelText:
                                          'Body weight goal (kg, optional)'
                                              .workoutTr(context)),
                                  validator: (v) {
                                    if ((v ?? '').isEmpty) return null;
                                    final n = double.tryParse(v!);
                                    return n == null ||
                                            !n.isFinite ||
                                            n < 1 ||
                                            n > 500
                                        ? 'Enter a valid body weight'
                                            .workoutTr(context)
                                        : null;
                                  }),
                              const SizedBox(height: 12),
                              TextFormField(
                                  controller: _restPause,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                      labelText: 'Rest-pause interval (sec)'
                                          .workoutTr(context)),
                                  validator: (v) {
                                    final n = int.tryParse(v ?? '');
                                    return n == null || n < 0 || n > 300
                                        ? 'Enter a value from 0 to 300'
                                            .workoutTr(context)
                                        : null;
                                  })
                            ]))),
                    Card(
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(children: [
                              DropdownButtonFormField<int>(
                                  initialValue: _preferences!['weekStart'],
                                  decoration: InputDecoration(
                                      labelText: ('First day of week')
                                          .workoutTr(context)),
                                  items: [
                                    for (int i = 0; i < 7; i++)
                                      DropdownMenuItem(
                                          value: i + 1,
                                          child: WorkoutLabel(
                                              WorkoutText.weekdays[i]))
                                  ],
                                  onChanged: (v) => setState(
                                      () => _preferences!['weekStart'] = v)),
                              const SizedBox(height: 12),
                              const WorkoutLabel('Equipment profiles'),
                              for (final row
                                  in (_preferences!['equipmentProfiles']
                                      as List))
                                ListTile(
                                    title: WorkoutLabel(row['name']),
                                    subtitle: WorkoutLabel(
                                        (row['equipment'] as List).join(', ')),
                                    leading: Checkbox(
                                        value: _preferences![
                                                'activeEquipmentProfile'] ==
                                            row['name'],
                                        onChanged: (v) => setState(() =>
                                            _preferences!['activeEquipmentProfile'] =
                                                v == true
                                                    ? row['name']
                                                    : null)),
                                    onTap: () => _equipment(
                                        existing: Map<String, dynamic>.from(row)),
                                    trailing: IconButton(
                                        tooltip: ('Remove profile').workoutTr(context),
                                        icon: const Icon(Icons.close),
                                        onPressed: () => setState(() {
                                              (_preferences![
                                                          'equipmentProfiles']
                                                      as List)
                                                  .remove(row);
                                              if (_preferences![
                                                      'activeEquipmentProfile'] ==
                                                  row['name']) {
                                                _preferences![
                                                        'activeEquipmentProfile'] =
                                                    null;
                                              }
                                            }))),
                              TextButton(
                                  onPressed: () => setState(() =>
                                      _preferences!['activeEquipmentProfile'] =
                                          null),
                                  child:
                                      const WorkoutLabel('Use all equipment')),
                              OutlinedButton.icon(
                                  onPressed: (_preferences!['equipmentProfiles']
                                                  as List)
                                              .length >=
                                          10
                                      ? null
                                      : () => _equipment(),
                                  icon: const Icon(Icons.add),
                                  label: const WorkoutLabel(
                                      'Add equipment profile'))
                            ]))),
                    Card(
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(children: [
                              _switch('reminderEnabled', 'Workout reminders'),
                              const WorkoutLabel(
                                  'Reminders follow your scheduled workout days and use SIRVYA notifications.'),
                              const SizedBox(height: 12),
                              TextFormField(
                                  controller: _time,
                                  decoration: InputDecoration(
                                      labelText: (('Reminder time (HH:mm)'))
                                          .workoutTr(context)),
                                  validator: (v) =>
                                      RegExp(r'^([01]\d|2[0-3]):[0-5]\d$')
                                              .hasMatch(v ?? '')
                                          ? null
                                          : (((('Enter a time such as 08:00')
                                              .workoutTr(context))))),
                              const SizedBox(height: 12),
                              TextFormField(
                                  controller: _zone,
                                  decoration: InputDecoration(
                                      labelText:
                                          (('Time zone')).workoutTr(context),
                                      hintText: (('Africa/Casablanca'))
                                          .workoutTr(context)),
                                  validator: (v) => (v ?? '').trim().isEmpty
                                      ? (((('Enter a time zone')
                                          .workoutTr(context))))
                                      : null)
                            ]))),
                    if (_saving)
                      const Center(child: CircularProgressIndicator())
                    else
                      ElevatedButton(
                          onPressed: _save,
                          child: const WorkoutLabel(WorkoutText.save))
                  ])));
}
