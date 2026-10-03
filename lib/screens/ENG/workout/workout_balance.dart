import 'package:flutter/material.dart';
import '../../../models/workout.dart';
import '../../../services/workout_service.dart';
import 'workout_ui.dart';

class WorkoutBalanceCard extends StatefulWidget {
  final List<Map<String, dynamic>> records;
  final int? clientID;
  const WorkoutBalanceCard({super.key, required this.records, this.clientID});
  @override
  State<WorkoutBalanceCard> createState() => _WorkoutBalanceCardState();
}

class _WorkoutBalanceCardState extends State<WorkoutBalanceCard> {
  Map<String, dynamic>? _balance;
  Object? _error;
  bool _saving = false, _loading = false;
  String get _path =>
      '/balance${widget.clientID == null ? '' : '?clientID=${widget.clientID}'}';
  List<Map<String, dynamic>> get _records => widget.records
      .where((r) => (workoutNumber(r['estimated1RM']) ?? 0) > 0)
      .toList();
  @override
  void initState() {
    super.initState();
    if (_records.length >= 2) _load();
  }

  @override
  void didUpdateWidget(covariant WorkoutBalanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clientID != oldWidget.clientID) {
      _balance = null;
      _error = null;
      _load();
    } else if (!_loading &&
        _balance == null &&
        _error == null &&
        _records.length >= 2) {
      _load();
    }
  }

  Future<void> _load() async {
    final path = _path;
    _loading = true;
    try {
      final result = await WorkoutService.get(path);
      if (mounted && path == _path) {
        setState(() {
          _balance = result;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted && path == _path) setState(() => _error = e);
    } finally {
      if (path == _path) _loading = false;
    }
  }

  Future<void> _save(Map<String, dynamic> changes) async {
    final path = _path;
    setState(() => _saving = true);
    try {
      final result = await WorkoutService.put(path, changes);
      if (mounted && path == _path) {
        setState(() => _balance = result);
        if (widget.clientID == null) {
          WorkoutService.preferences = {
            ...WorkoutService.preferences,
            ...result
          };
        }
      }
    } catch (e) {
      if (mounted) workoutError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _target(Map<String, dynamic> record) async {
    final targets = workoutRows(_balance!['balanceTargets']);
    final old = targets
        .where((v) => v['exerciseID'] == record['exerciseID'])
        .firstOrNull;
    final controller =
        TextEditingController(text: '${old?['targetPercent'] ?? 100}');
    final form = GlobalKey<FormState>();
    final saved = await workoutDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: WorkoutLabel('${record['name']}'),
                content: Form(
                    key: form,
                    child: TextFormField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                            labelText: 'Target ratio (%)'.workoutTr(context)),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          return n == null || !n.isFinite || n < 1 || n > 500
                              ? 'Enter a value from 1 to 500'.workoutTr(context)
                              : null;
                        })),
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
                ]));
    if (saved == true && mounted) {
      targets.removeWhere((v) => v['exerciseID'] == record['exerciseID']);
      targets.add({
        'exerciseID': record['exerciseID'],
        'targetPercent': double.parse(controller.text)
      });
      await _save({'balanceTargets': targets, 'activeBalanceProtocolID': null});
    }
    controller.dispose();
  }

  Future<void> _saveProtocol(int anchorID) async {
    final controller = TextEditingController();
    final form = GlobalKey<FormState>();
    final saved = await workoutDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const WorkoutLabel('Save balance protocol'),
                content: Form(
                    key: form,
                    child: TextFormField(
                        controller: controller,
                        maxLength: 80,
                        decoration: InputDecoration(
                            labelText: 'Protocol name'.workoutTr(context)),
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? 'Required'.workoutTr(context)
                            : null)),
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
                ]));
    if (saved == true && mounted) {
      final id = 'protocol_${DateTime.now().microsecondsSinceEpoch}';
      final protocols = workoutRows(_balance!['balanceProtocols']);
      protocols.add({
        'id': id,
        'name': controller.text.trim(),
        'anchorID': anchorID,
        'targets': workoutRows(_balance!['balanceTargets'])
      });
      await _save(
          {'balanceProtocols': protocols, 'activeBalanceProtocolID': id});
    }
    controller.dispose();
  }

  Future<void> _deleteProtocol() async {
    final selected = _balance!['activeBalanceProtocolID'];
    final yes = await workoutDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const WorkoutLabel('Delete balance protocol?'),
                content: const WorkoutLabel(
                    'The current ratios will remain as custom targets.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const WorkoutLabel('Cancel')),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const WorkoutLabel('Delete'))
                ]));
    if (yes == true && mounted) {
      await _save({
        'balanceProtocols': workoutRows(_balance!['balanceProtocols'])
            .where((v) => v['id'] != selected)
            .toList(),
        'activeBalanceProtocolID': null
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final records = _records;
    if (records.length < 2) return const SizedBox.shrink();
    if (_error != null) {
      return Card(child: WorkoutFailure(error: _error!, retry: _load));
    }
    if (_balance == null) {
      return const Card(
          child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator())));
    }
    final balance = _balance!;
    final preferred = balance['balanceAnchorID'] == null
        ? workoutInt(records.first['exerciseID'])
        : workoutInt(balance['balanceAnchorID']);
    final anchor = records
        .where((r) => workoutInt(r['exerciseID']) == preferred)
        .firstOrNull;
    final protocols = workoutRows(balance['balanceProtocols']);
    final selected = balance['activeBalanceProtocolID'] as String?;
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const WorkoutLabel('Structural balance',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const WorkoutLabel(
                  'Compare recorded estimated 1RM against an anchor lift. Set ratios with your coach for comparable exercise variants.'),
              if (balance['offline'] == true) const WorkoutOfflineNotice(),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                  key: ValueKey('protocol_$selected'),
                  initialValue: selected ?? '',
                  isExpanded: true,
                  decoration: InputDecoration(
                      labelText: 'Balance protocol'.workoutTr(context)),
                  items: [
                    const DropdownMenuItem(
                        value: '', child: WorkoutLabel('Custom targets')),
                    ...protocols.map((p) => DropdownMenuItem(
                        value: '${p['id']}',
                        child: WorkoutLabel('${p['name']}',
                            overflow: TextOverflow.ellipsis)))
                  ],
                  onChanged: _saving
                      ? null
                      : (v) => _save(
                          {'activeBalanceProtocolID': v == '' ? null : v})),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                  key: ValueKey('anchor_$preferred'),
                  initialValue: preferred,
                  isExpanded: true,
                  decoration: InputDecoration(
                      labelText: 'Anchor exercise'.workoutTr(context)),
                  items: [
                    if (anchor == null)
                      DropdownMenuItem(
                          value: preferred,
                          child: const WorkoutLabel(
                              'Anchor not recorded in this period')),
                    ...records.map((r) => DropdownMenuItem(
                        value: workoutInt(r['exerciseID']),
                        child: WorkoutLabel('${r['name']}',
                            overflow: TextOverflow.ellipsis)))
                  ],
                  onChanged: _saving
                      ? null
                      : (v) => _save({
                            'balanceAnchorID': v,
                            'activeBalanceProtocolID': null
                          })),
              if (anchor == null)
                const WorkoutLabel(
                    'Record the anchor exercise to compare this protocol.'),
              if (anchor != null)
                ...records
                    .where((r) => workoutInt(r['exerciseID']) != preferred)
                    .map((r) {
                  final pct = workoutNumber(r['estimated1RM'])! /
                      workoutNumber(anchor['estimated1RM'])! *
                      100;
                  final target = workoutRows(balance['balanceTargets'])
                      .where((v) => v['exerciseID'] == r['exerciseID'])
                      .firstOrNull;
                  return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(children: [
                        ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: WorkoutLabel('${r['name']}'),
                            subtitle: WorkoutLabel(
                                'Anchor ratio: ${pct.toStringAsFixed(0)}%${target == null ? '' : ' · target ${target['targetPercent']}%'}'),
                            trailing: IconButton(
                                tooltip: 'Set target ratio'.workoutTr(context),
                                onPressed: _saving ? null : () => _target(r),
                                icon: const Icon(Icons.tune))),
                        if (target != null)
                          LinearProgressIndicator(
                              value: (pct /
                                      (workoutNumber(target['targetPercent']) ??
                                          100))
                                  .clamp(0, 1))
                      ]));
                }),
              Wrap(spacing: 8, children: [
                TextButton.icon(
                    onPressed: _saving || protocols.length >= 10
                        ? null
                        : () => _saveProtocol(preferred),
                    icon: const Icon(Icons.save_outlined),
                    label: const WorkoutLabel('Save balance protocol')),
                if (selected != null)
                  TextButton.icon(
                      onPressed: _saving ? null : _deleteProtocol,
                      icon: const Icon(Icons.delete_outline),
                      label: const WorkoutLabel('Delete protocol'))
              ]),
              if (_saving) const LinearProgressIndicator()
            ])));
  }
}
