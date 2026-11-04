import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/weight_entry.dart';
import '../theme/fitlek_theme_extension.dart';

class WeightProgressView extends StatefulWidget {
  final List<WeightEntry> entries;
  final double? current, start;
  final int total;
  final String bmi;
  final bool loading;
  final String? error;
  final DateTime? now;
  final Future<void> Function() onRefresh;
  final Future<void> Function(double) onAdd;
  const WeightProgressView(
      {super.key,
      required this.entries,
      required this.current,
      required this.start,
      required this.total,
      required this.bmi,
      required this.onRefresh,
      required this.onAdd,
      this.loading = false,
      this.error,
      this.now});
  @override
  State<WeightProgressView> createState() => _WeightProgressViewState();
}

class _WeightProgressViewState extends State<WeightProgressView>
    with AutomaticKeepAliveClientMixin {
  int? _days = 30;
  int? _selectedID;
  @override
  bool get wantKeepAlive => true;
  @override
  void didUpdateWidget(covariant WeightProgressView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries.lastOrNull?.id != widget.entries.lastOrNull?.id) {
      _selectedID = null;
    }
  }

  Future<void> _log() => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          WeightLogSheet(lastWeight: widget.current, onSave: widget.onAdd));

  Widget _card(Widget child, {EdgeInsets padding = const EdgeInsets.all(20)}) =>
      Container(
          padding: padding,
          decoration: BoxDecoration(
              color: context.fitlek.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.fitlek.border)),
          child: child);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = context.fitlek, scheme = Theme.of(context).colorScheme;
    final data =
        weightPeriod(widget.entries, _days, widget.now ?? DateTime.now());
    final recent =
        weightPeriod(widget.entries, null, widget.now ?? DateTime.now());
    final latest = recent.lastOrNull;
    final current = widget.current;
    final selected =
        data.where((e) => e.id == _selectedID).firstOrNull ?? data.lastOrNull;
    return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          key: const PageStorageKey('client-weight-progress'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('YOUR PROGRESS',
                        style: TextStyle(
                            color: c.textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.8)),
                    const SizedBox(height: 6),
                    Text('Every check-in counts.',
                        style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: 22,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.6)),
                  ])),
              const SizedBox(width: 10),
              IconButton.filled(
                  onPressed: _log,
                  tooltip: 'Log weight',
                  style: IconButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary),
                  icon: const Icon(Icons.add_rounded))
            ]),
            const SizedBox(height: 18),
            if (widget.error != null)
              Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _card(Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.error!,
                            style: TextStyle(
                                color: c.textSecondary, fontSize: 12)),
                        TextButton(
                            onPressed: widget.loading ? null : widget.onRefresh,
                            child: const Text('Refresh history')),
                      ]))),
            Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [c.card2, c.card]),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: c.border)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: .09),
                                borderRadius: BorderRadius.circular(14)),
                            child: Icon(Icons.monitor_weight_outlined,
                                color: scheme.primary, size: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text('Current weight',
                                style: TextStyle(
                                    color: c.textSecondary, fontSize: 13))),
                        if (widget.loading)
                          const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(strokeWidth: 2))
                      ]),
                      const SizedBox(height: 18),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Flexible(
                                child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                        current?.toStringAsFixed(1) ?? '—',
                                        style: TextStyle(
                                            fontSize: 56,
                                            height: 1,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -2.5,
                                            color: scheme.onSurface)))),
                            const SizedBox(width: 8),
                            Text('kg',
                                style: TextStyle(
                                    fontSize: 20, color: c.textMuted)),
                          ]),
                      const SizedBox(height: 12),
                      Text(
                          latest == null
                              ? 'Your first weigh-in starts here.'
                              : 'Latest weigh-in · ${latest.fullLabel}',
                          style: TextStyle(color: c.textMuted, fontSize: 12)),
                      if (current != null && widget.start != null) ...[
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Divider(height: 1, color: c.border)),
                        Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                      color:
                                          scheme.primary.withValues(alpha: .08),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Text(
                                      weightChange(current - widget.start!),
                                      style: TextStyle(
                                          color: scheme.primary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800))),
                              Text('since your first weigh-in',
                                  style: TextStyle(
                                      color: c.textMuted, fontSize: 11)),
                            ]),
                      ],
                    ])),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: _summary(
                      'Starting weight',
                      widget.start == null
                          ? '—'
                          : '${widget.start!.toStringAsFixed(1)} kg',
                      Icons.flag_outlined)),
              const SizedBox(width: 12),
              Expanded(
                  child: _summary('Weigh-ins logged', '${widget.total}',
                      Icons.calendar_today_outlined))
            ]),
            const SizedBox(height: 20),
            _card(
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Weight trend',
                  style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('A little perspective on your journey.',
                  style: TextStyle(color: c.textMuted, fontSize: 12)),
              const SizedBox(height: 16),
              Row(
                  children: [(7, '7 days'), (30, '30 days'), (null, 'Recent')]
                      .map((period) => Expanded(
                          child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: TextButton(
                                onPressed: () => setState(() {
                                  _days = period.$1;
                                  _selectedID = null;
                                }),
                                style: TextButton.styleFrom(
                                    backgroundColor: _days == period.$1
                                        ? scheme.primary
                                        : c.card2,
                                    foregroundColor: _days == period.$1
                                        ? scheme.onPrimary
                                        : c.textMuted,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 3)),
                                child: Text(period.$2,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700)),
                              ))))
                      .toList()),
              const SizedBox(height: 20),
              if (selected != null) ...[
                Row(children: [
                  Expanded(
                      child: Text('${selected.weight.toStringAsFixed(1)} kg',
                          style: TextStyle(
                              color: scheme.onSurface,
                              fontSize: 22,
                              fontWeight: FontWeight.w800))),
                  Text(selected.label,
                      style: TextStyle(color: c.textMuted, fontSize: 12))
                ]),
                const SizedBox(height: 12),
                Semantics(
                    label:
                        'Weight trend, ${data.length} weigh-ins. Selected ${selected.weight.toStringAsFixed(1)} kilograms on ${selected.fullLabel}.',
                    child: LayoutBuilder(builder: (context, constraints) {
                      void select(double x) {
                        final index =
                            _nearestWeight(data, constraints.maxWidth, x);
                        setState(() => _selectedID = data[index].id);
                      }

                      return GestureDetector(
                          onTapDown: (event) => select(event.localPosition.dx),
                          onHorizontalDragUpdate: (event) =>
                              select(event.localPosition.dx),
                          child: SizedBox(
                              height: 190,
                              width: double.infinity,
                              child: CustomPaint(
                                  painter: WeightTrendPainter(
                                      entries: data,
                                      selectedID: selected.id,
                                      color: scheme.primary,
                                      grid: c.border,
                                      text: c.textMuted,
                                      fontFamily: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.fontFamily,
                                      surface: c.card))));
                    })),
                const SizedBox(height: 10),
                Text(
                    data.length == 1
                        ? 'Your first point is on the chart. Add another to see a trend. Dates in UTC.'
                        : 'Tap or slide across the chart to explore your weigh-ins. Dates in UTC.',
                    style: TextStyle(
                        color: c.textMuted, fontSize: 10, height: 1.5)),
              ] else
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.show_chart_rounded,
                              size: 32, color: c.textMuted),
                          const SizedBox(height: 12),
                          Text(
                              widget.total == 0
                                  ? 'Your story starts with one log.'
                                  : 'No weigh-ins in this period.',
                              style: TextStyle(
                                  color: scheme.onSurface,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 7),
                          Text(
                              widget.total == 0
                                  ? 'Log a weight to start your personal trend.'
                                  : 'Choose Recent to see your latest available records.',
                              style: TextStyle(
                                  color: c.textMuted,
                                  fontSize: 12,
                                  height: 1.5)),
                        ])),
            ])),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(
                  child: Text('Recent weigh-ins',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface))),
              if (data.isNotEmpty)
                Text('${data.length} in view',
                    style: TextStyle(color: c.textMuted, fontSize: 11))
            ]),
            const SizedBox(height: 12),
            if (data.isEmpty)
              _card(Text('Your recorded weights will appear here.',
                  style: TextStyle(color: c.textMuted, fontSize: 12)))
            else
              _card(
                  Column(
                      children: data.reversed.take(5).map((entry) {
                    final index = data.indexOf(entry);
                    final change = index == 0
                        ? null
                        : entry.weight - data[index - 1].weight;
                    return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(children: [
                          Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: c.card2,
                                  borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.monitor_weight_outlined,
                                  size: 18, color: scheme.primary)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(entry.fullLabel,
                                    style: TextStyle(
                                        color: scheme.onSurface,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(
                                    entry.note.isNotEmpty
                                        ? entry.note
                                        : change == null
                                            ? 'First in this view'
                                            : '${weightChange(change)} from previous',
                                    style: TextStyle(
                                        color: c.textMuted,
                                        fontSize: 10,
                                        height: 1.4)),
                              ])),
                          const SizedBox(width: 8),
                          Text('${entry.weight.toStringAsFixed(1)} kg',
                              style: TextStyle(
                                  color: scheme.onSurface,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800)),
                        ]));
                  }).toList()),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6)),
            if (widget.entries.length >= 90 || data.length > 5)
              Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                      'Chart: up to the latest 90 saved weigh-ins. List: latest 5 in this view.',
                      style: TextStyle(
                          color: c.textMuted, fontSize: 10, height: 1.5))),
            const SizedBox(height: 20),
            _card(
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Keep a record, at your pace.',
                  style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 7),
              Text('A quick check-in adds another point to your story.',
                  style:
                      TextStyle(color: c.textMuted, fontSize: 12, height: 1.5)),
              const SizedBox(height: 16),
              SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                      onPressed: _log,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Log a weigh-in'))),
            ])),
            if (widget.bmi != '—')
              Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _card(
                      Row(children: [
                        Icon(Icons.insights_outlined,
                            color: c.textMuted, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('BMI · ${widget.bmi}',
                                  style: TextStyle(
                                      color: scheme.onSurface,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text('From your latest weight and saved height.',
                                  style: TextStyle(
                                      color: c.textMuted,
                                      fontSize: 10,
                                      height: 1.5))
                            ])),
                      ]),
                      padding: const EdgeInsets.all(16))),
          ],
        ));
  }

  Widget _summary(String title, String value, IconData icon) => _card(
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: context.fitlek.textMuted, size: 18),
        const SizedBox(height: 12),
        FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 21,
                    fontWeight: FontWeight.w800))),
        const SizedBox(height: 5),
        Text(title,
            style: TextStyle(color: context.fitlek.textMuted, fontSize: 11)),
      ]),
      padding: const EdgeInsets.all(16));
}

List<Offset> _weightPoints(List<WeightEntry> data, Size size) {
  if (data.isEmpty) return [];
  final values = data.map((e) => e.weight);
  final min = values.reduce(math.min), max = values.reduce(math.max);
  final padding = math.max(.5, (max - min) * .25),
      low = min - padding,
      range = max - min + padding * 2;
  final width = math.max(1.0, size.width - 46), height = size.height - 32;
  final elapsed = data.last.at.difference(data.first.at).inMilliseconds;
  return data.indexed
      .map((e) => Offset(
          8 +
              (data.length == 1
                      ? .5
                      : elapsed == 0
                          ? e.$1 / (data.length - 1)
                          : e.$2.at.difference(data.first.at).inMilliseconds /
                              elapsed) *
                  width,
          6 + height * (1 - (e.$2.weight - low) / range)))
      .toList();
}

int _nearestWeight(List<WeightEntry> data, double width, double x) {
  final points = _weightPoints(data, Size(width, 190));
  int nearest = 0;
  for (int i = 1; i < points.length; i++) {
    if ((points[i].dx - x).abs() <= (points[nearest].dx - x).abs()) nearest = i;
  }
  return nearest;
}

class WeightTrendPainter extends CustomPainter {
  final List<WeightEntry> entries;
  final int selectedID;
  final Color color, grid, text, surface;
  final String? fontFamily;
  const WeightTrendPainter(
      {required this.entries,
      required this.selectedID,
      required this.color,
      required this.grid,
      required this.text,
      this.fontFamily,
      required this.surface});
  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty || size.width < 60) return;
    final points = _weightPoints(entries, size),
        right = size.width - 38,
        bottom = size.height - 26;
    final min = entries.map((e) => e.weight).reduce(math.min),
        max = entries.map((e) => e.weight).reduce(math.max);
    final padding = math.max(.5, (max - min) * .25);
    void label(String value, Offset position, {bool alignRight = false}) {
      final painter = TextPainter(
          text: TextSpan(
              text: value,
              style:
                  TextStyle(color: text, fontSize: 9, fontFamily: fontFamily)),
          textDirection: TextDirection.ltr)
        ..layout();
      painter.paint(
          canvas,
          Offset(alignRight ? position.dx - painter.width : position.dx,
              position.dy));
    }

    for (int i = 0; i <= 3; i++) {
      final y = 6 + (bottom - 6) * i / 3;
      canvas.drawLine(
          Offset(8, y),
          Offset(right, y),
          Paint()
            ..color = grid.withValues(alpha: .6)
            ..strokeWidth = .7);
      label(
          (max + padding - (max - min + 2 * padding) * i / 3)
              .toStringAsFixed(1),
          Offset(size.width, y - 5),
          alignRight: true);
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final middle = (points[i - 1].dx + points[i].dx) / 2;
      path.cubicTo(middle, points[i - 1].dy, middle, points[i].dy, points[i].dx,
          points[i].dy);
    }
    if (points.length > 1) {
      final area = Path.from(path)
        ..lineTo(points.last.dx, bottom)
        ..lineTo(points.first.dx, bottom)
        ..close();
      canvas.drawPath(
          area,
          Paint()
            ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: .16),
                  color.withValues(alpha: 0)
                ]).createShader(Offset.zero & size));
      canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round);
    }
    final index = math.max(0, entries.indexWhere((e) => e.id == selectedID));
    final selected = points[index];
    canvas.drawLine(
        Offset(selected.dx, 6),
        Offset(selected.dx, bottom),
        Paint()
          ..color = color.withValues(alpha: .2)
          ..strokeWidth = 1);
    canvas.drawCircle(
        selected, 9, Paint()..color = color.withValues(alpha: .12));
    canvas.drawCircle(selected, 4.5, Paint()..color = color);
    canvas.drawCircle(selected, 2, Paint()..color = surface);
    label(entries.first.label, Offset(8, size.height - 12));
    if (entries.length > 1) {
      label(entries.last.label, Offset(right, size.height - 12),
          alignRight: true);
    }
  }

  @override
  bool shouldRepaint(covariant WeightTrendPainter oldDelegate) =>
      oldDelegate.entries != entries ||
      oldDelegate.selectedID != selectedID ||
      oldDelegate.color != color ||
      oldDelegate.grid != grid ||
      oldDelegate.text != text ||
      oldDelegate.fontFamily != fontFamily ||
      oldDelegate.surface != surface;
}

class WeightLogSheet extends StatefulWidget {
  final double? lastWeight;
  final Future<void> Function(double) onSave;
  const WeightLogSheet({super.key, required this.onSave, this.lastWeight});
  @override
  State<WeightLogSheet> createState() => _WeightLogSheetState();
}

class _WeightLogSheetState extends State<WeightLogSheet> {
  final _input = TextEditingController();
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final weight = double.tryParse(_input.text.trim().replaceAll(',', '.'));
    if (weight == null || !weight.isFinite || weight <= 0 || weight > 500) {
      setState(() => _error = 'Enter a valid weight between 0 and 500 kg.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(weight);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save. Your entry is still here—please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fitlek, scheme = Theme.of(context).colorScheme;
    return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Container(
          decoration: BoxDecoration(
              color: c.card,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: c.border)),
          child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                            child: Container(
                                width: 34,
                                height: 4,
                                decoration: BoxDecoration(
                                    color: c.border,
                                    borderRadius: BorderRadius.circular(4)))),
                        const SizedBox(height: 22),
                        Row(children: [
                          Expanded(
                              child: Text('A moment for you.',
                                  style: TextStyle(
                                      fontSize: 25,
                                      letterSpacing: -.7,
                                      fontWeight: FontWeight.w800,
                                      color: scheme.onSurface))),
                          IconButton(
                              tooltip: 'Close',
                              onPressed:
                                  _saving ? null : () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded, size: 20)),
                        ]),
                        const SizedBox(height: 8),
                        Text('Log your weight and keep your journey in view.',
                            style: TextStyle(
                                fontSize: 12, height: 1.5, color: c.textMuted)),
                        const SizedBox(height: 24),
                        TextField(
                            key: const ValueKey('weight-log-input'),
                            controller: _input,
                            enabled: !_saving,
                            autofocus: true,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _save(),
                            style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface),
                            decoration: InputDecoration(
                                labelText: 'Weight (kg)',
                                hintText: '00.0',
                                suffixText: 'kg',
                                errorText: _error,
                                errorMaxLines: 3,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 18),
                                filled: true,
                                fillColor: c.card2,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide(color: c.border)))),
                        const SizedBox(height: 12),
                        Text(
                            widget.lastWeight == null
                                ? 'Recorded for today. You can use a dot or a comma.'
                                : 'Last recorded: ${widget.lastWeight!.toStringAsFixed(1)} kg · Recorded for today.',
                            style: TextStyle(
                                fontSize: 11, height: 1.5, color: c.textMuted)),
                        const SizedBox(height: 24),
                        SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                                onPressed: _saving ? null : _save,
                                style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    backgroundColor: scheme.primary,
                                    foregroundColor: scheme.onPrimary),
                                icon: _saving
                                    ? const SizedBox(
                                        width: 17,
                                        height: 17,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Icon(Icons.check_rounded, size: 20),
                                label: Text(
                                    _saving ? 'Saving…' : 'Save weigh-in'))),
                      ]))),
        ));
  }
}
