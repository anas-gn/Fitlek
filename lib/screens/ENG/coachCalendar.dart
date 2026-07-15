import 'package:flutter/material.dart';
import '../../models/coachReservation.dart';
import '../../models/coachAvailability.dart';
import '../../services/apiService.dart';

import '../../theme/fitlek_theme_extension.dart';

class CoachCalendar extends StatefulWidget {
  const CoachCalendar({super.key});
  @override
  State<CoachCalendar> createState() => _CoachCalendarState();
}

class _CoachCalendarState extends State<CoachCalendar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  bool _loading = true;
  List<CoachReservation> _reservations = [];
  List<CoachAvailability> _unavailablePeriods = [];

  static const int _workStart = 7;
  static const int _workEnd = 22;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final resResult = await ApiService.get('/coach/calendar/reservations');
    final availResult = await ApiService.get('/coach/calendar/availability');
    if (!mounted) return;
    setState(() {
      if (resResult['ok'] == true) {
        _reservations = (resResult['data'] as List? ?? [])
            .map((r) => CoachReservation(
                  id: r['id'].toString(),
                  clientName: '${r['firstName']} ${r['lastName']}',
                  clientPhotoUrl: r['avatarUrl'] ?? '',
                  date: DateTime.parse(r['reservedDate']),
                  time: (r['reservedTime'] as String?)?.substring(0, 5) ?? '',
                  location: r['location']?.toString(),
                  status: r['status'] == 'confirmed'
                      ? ReservationStatus.confirmed
                      : ReservationStatus.pending,
                ))
            .toList();
      }
      if (availResult['ok'] == true) {
        _unavailablePeriods = (availResult['data'] as List? ?? [])
            .map((a) => CoachAvailability(
                  id: a['id'].toString(),
                  date: DateTime.parse(a['blockedDate']),
                  startHour:
                      int.parse((a['startTime'] as String).split(':')[0]),
                  startMinute:
                      int.parse((a['startTime'] as String).split(':')[1]),
                  endHour: int.parse((a['endTime'] as String).split(':')[0]),
                  endMinute: int.parse((a['endTime'] as String).split(':')[1]),
                  note: a['note'],
                ))
            .toList();
      }
      _loading = false;
    });
  }

  List<CoachReservation> get _selectedDayReservations => _reservations
      .where((r) =>
          r.date.year == _selectedDate.year &&
          r.date.month == _selectedDate.month &&
          r.date.day == _selectedDate.day)
      .toList();

  bool _dayHasUnavailability(DateTime date) =>
      _unavailablePeriods.any((a) => a.conflictsWithDay(date));
  bool _hasReservations(DateTime date) => _reservations.any((r) =>
      r.date.year == date.year &&
      r.date.month == date.month &&
      r.date.day == date.day);
  bool _slotIsBlocked(int hour) =>
      _unavailablePeriods.any((a) => a.blocksSlot(_selectedDate, hour));

  Future<void> _acceptReservation(CoachReservation r) async {
    final result =
        await ApiService.patch('/coach/calendar/reservations/${r.id}/accept');
    if (!mounted) return;
    if (result['ok'] == true) {
      _load();
    } else {
      ApiService.showError(context, result['message'] ?? 'Failed.');
    }
  }

  Future<void> _rejectReservation(CoachReservation r, String reason) async {
    final result = await ApiService.patch(
        '/coach/calendar/reservations/${r.id}/reject', {'reason': reason});
    if (!mounted) return;
    if (result['ok'] == true) {
      _load();
    } else {
      ApiService.showError(context, result['message'] ?? 'Failed.');
    }
  }

  Future<void> _cancelReservation(CoachReservation r, String reason) async {
    final result = await ApiService.patch(
        '/coach/calendar/reservations/${r.id}/cancel', {'reason': reason});
    if (!mounted) return;
    if (result['ok'] == true) {
      _load();
    } else {
      ApiService.showError(context, result['message'] ?? 'Failed.');
    }
  }

  Future<void> _deleteAvailability(CoachAvailability a) async {
    final result =
        await ApiService.delete('/coach/calendar/availability/${a.id}');
    if (!mounted) return;
    if (result['ok'] == true) {
      _load();
    } else {
      ApiService.showError(context, result['message'] ?? 'Failed.');
    }
  }

  Future<void> _addAvailability(DateTime date, int startHour, int startMinute,
      int endHour, int endMinute, String? note) async {
    final startTime =
        '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}:00';
    final endTime =
        '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}:00';
    final result = await ApiService.post('/coach/calendar/availability', {
      'blockedDate': date.toIso8601String().split('T')[0],
      'startTime': startTime,
      'endTime': endTime,
      'note': note,
    });
    if (!mounted) return;
    if (result['ok'] == true) {
      _load();
      _tabController.animateTo(1);
    } else {
      ApiService.showError(context, result['message'] ?? 'Failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary))
          : Column(children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                  child: TabBarView(controller: _tabController, children: [
                _buildCalendarTab(),
                _buildAvailabilityTab(),
              ])),
            ]),
    );
  }

  Widget _buildHeader() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(children: [
          Text('Calendar',
              style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const Spacer(),
          GestureDetector(
              onTap: _showAddUnavailabilityDialog,
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.block_rounded, color: cs.onPrimary, size: 16),
                    const SizedBox(width: 6),
                    Text('Block Hours',
                        style: TextStyle(
                            color: cs.onPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ]))),
        ]));
  }

  Widget _buildTabBar() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        decoration: BoxDecoration(
            color: f.card, borderRadius: BorderRadius.circular(14)),
        child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
                color: cs.primary, borderRadius: BorderRadius.circular(12)),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.all(4),
            labelColor: cs.onPrimary,
            unselectedLabelColor: f.textMuted,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Reservations'),
              Tab(text: 'Availability')
            ]));
  }

  Widget _buildCalendarTab() => RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: context.fitlek.card,
      onRefresh: _load,
      child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            _buildMonthCalendar(),
            const SizedBox(height: 24),
            _buildDayView()
          ])));

  Widget _buildMonthCalendar() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startPadding = firstDay.weekday % 7;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: f.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: f.border)),
      child: Column(children: [
        Row(children: [
          GestureDetector(
              onTap: () => setState(() => _focusedMonth =
                  DateTime(_focusedMonth.year, _focusedMonth.month - 1)),
              child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: f.card2, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.chevron_left_rounded,
                      color: cs.onSurface, size: 20))),
          Expanded(
              child: Center(
                  child: Text(
                      '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                      style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)))),
          GestureDetector(
              onTap: () => setState(() => _focusedMonth =
                  DateTime(_focusedMonth.year, _focusedMonth.month + 1)),
              child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: f.card2, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.chevron_right_rounded,
                      color: cs.onSurface, size: 20))),
        ]),
        const SizedBox(height: 16),
        Row(
            children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                .map((d) => Expanded(
                    child: Center(
                        child: Text(d,
                            style: TextStyle(
                                color: f.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)))))
                .toList()),
        const SizedBox(height: 8),
        GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, childAspectRatio: 1),
            itemCount: startPadding + lastDay.day,
            itemBuilder: (_, index) {
              if (index < startPadding) return const SizedBox();
              final day = index - startPadding + 1;
              final date =
                  DateTime(_focusedMonth.year, _focusedMonth.month, day);
              final isSelected = date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;
              final hasUnavail = _dayHasUnavailability(date);
              final hasRes = _hasReservations(date);
              return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                          color: isSelected ? cs.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isToday && !isSelected
                              ? Border.all(color: cs.primary, width: 1.5)
                              : null),
                      child: Stack(alignment: Alignment.center, children: [
                        Text('$day',
                            style: TextStyle(
                                color: isSelected ? cs.onPrimary : cs.onSurface,
                                fontSize: 13,
                                fontWeight: isSelected || isToday
                                    ? FontWeight.w700
                                    : FontWeight.w400)),
                        if ((hasRes || hasUnavail) && !isSelected)
                          Positioned(
                              bottom: 3,
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (hasRes)
                                      Container(
                                          width: 4,
                                          height: 4,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 1),
                                          decoration: BoxDecoration(
                                              color: cs.primary,
                                              shape: BoxShape.circle)),
                                    if (hasUnavail)
                                      Container(
                                          width: 4,
                                          height: 4,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 1),
                                          decoration: BoxDecoration(
                                              color: f.error,
                                              shape: BoxShape.circle)),
                                  ])),
                      ])));
            }),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _legendDot(cs.primary, 'Reservation'),
          const SizedBox(width: 16),
          _legendDot(f.error, 'Blocked'),
        ]),
      ]),
    );
  }

  Widget _legendDot(Color color, String label) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style:
                TextStyle(color: context.fitlek.textSecondary, fontSize: 11)),
      ]);

  Widget _buildDayView() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final reservations = _selectedDayReservations;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${_monthName(_selectedDate.month)} ${_selectedDate.day}',
          style: TextStyle(
              color: cs.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 14),
      ...reservations.map((r) => _buildReservationCard(r)),
      if (reservations.isEmpty)
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: f.card, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              Icon(Icons.event_available_rounded, color: f.textMuted, size: 40),
              const SizedBox(height: 8),
              Text('No reservations this day',
                  style: TextStyle(color: f.textMuted, fontSize: 14))
            ])),
      const SizedBox(height: 16),
      _buildHourTimeline(),
    ]);
  }

  Widget _buildReservationCard(CoachReservation reservation) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final isPending = reservation.status == ReservationStatus.pending;
    final isConfirmed = reservation.status == ReservationStatus.confirmed;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: f.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: isPending
                  ? f.warning.withValues(alpha: 0.2)
                  : cs.primary.withValues(alpha: 0.2))),
      child: Column(children: [
        Row(children: [
          Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isPending
                          ? f.warning.withValues(alpha: 0.4)
                          : cs.primary.withValues(alpha: 0.4),
                      width: 1.5)),
              child: ClipOval(
                  child: reservation.clientPhotoUrl.isNotEmpty
                      ? Image.network(reservation.clientPhotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.person, color: f.textMuted, size: 22))
                      : Icon(Icons.person, color: f.textMuted, size: 22))),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(reservation.clientName,
                    style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.access_time_rounded, size: 13, color: f.textMuted),
                  const SizedBox(width: 4),
                  Text(reservation.time,
                      style: TextStyle(color: f.textMuted, fontSize: 13))
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.location_on_rounded, size: 13, color: f.textMuted),
                  const SizedBox(width: 4),
                  Flexible(
                      child: Text(reservation.locationLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(color: f.textMuted, fontSize: 13)))
                ]),
              ])),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: isPending
                      ? f.warning.withValues(alpha: 0.1)
                      : cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(isPending ? 'Pending' : 'Confirmed',
                  style: TextStyle(
                      color: isPending ? f.warning : cs.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700))),
        ]),
        if (isPending) ...[
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: GestureDetector(
                    onTap: () => _acceptReservation(reservation),
                    child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(10)),
                        child: Center(
                            child: Text('Accept',
                                style: TextStyle(
                                    color: cs.onPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)))))),
            const SizedBox(width: 10),
            Expanded(
                child: GestureDetector(
                    onTap: () => _showReasonDialog('Reject Reservation',
                        (reason) => _rejectReservation(reservation, reason)),
                    child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                            color: f.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: f.error.withValues(alpha: 0.3))),
                        child: Center(
                            child: Text('Reject',
                                style: TextStyle(
                                    color: f.error,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)))))),
          ])
        ] else if (isConfirmed && reservation.canCancel) ...[
          const SizedBox(height: 14),
          GestureDetector(
              onTap: () => _showReasonDialog('Cancel Reservation',
                  (reason) => _cancelReservation(reservation, reason)),
              child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                      color: f.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: f.error.withValues(alpha: 0.2))),
                  child: Center(
                      child: Text('Cancel Reservation',
                          style: TextStyle(
                              color: f.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)))))
        ],
      ]),
    );
  }

  Widget _buildHourTimeline() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final reservationTimes =
        _selectedDayReservations.map((r) => r.time).toSet();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Working Hours ($_workStart:00 – $_workEnd:00)',
          style: TextStyle(
              color: f.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      Column(
          children: List.generate(_workEnd - _workStart, (i) {
        final hour = _workStart + i;
        final label = '${hour.toString().padLeft(2, '0')}:00';
        final hasBooking = reservationTimes.contains(label);
        final isBlocked = _slotIsBlocked(hour);
        Color slotColor =
            isBlocked ? f.error.withValues(alpha: 0.10) : Colors.transparent;
        Color borderColor = isBlocked
            ? f.error.withValues(alpha: 0.3)
            : hasBooking
                ? cs.primary.withValues(alpha: 0.4)
                : f.border;
        Color textColor = isBlocked
            ? f.error.withValues(alpha: 0.6)
            : hasBooking
                ? cs.primary
                : f.textMuted;
        if (hasBooking && !isBlocked) {
          slotColor = cs.primary.withValues(alpha: 0.10);
        }
        Widget? trailing;
        if (isBlocked) {
          trailing = Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: f.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6)),
              child: Text('Blocked',
                  style: TextStyle(
                      color: f.error,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)));
        } else if (hasBooking) {
          trailing = Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6)),
              child: Text('Booked',
                  style: TextStyle(
                      color: cs.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)));
        }
        return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                color: slotColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor)),
            child: Row(children: [
              SizedBox(
                  width: 48,
                  child: Text(label,
                      style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600))),
              Expanded(
                  child: Container(
                      height: 1,
                      color: borderColor,
                      margin: const EdgeInsets.symmetric(horizontal: 8))),
              if (trailing != null) trailing,
            ]));
      })),
    ]);
  }

  Widget _buildAvailabilityTab() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return RefreshIndicator(
        color: cs.primary,
        backgroundColor: f.card,
        onRefresh: _load,
        child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Blocked Periods',
                  style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Manage specific hours when you are unavailable.',
                  style: TextStyle(color: f.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              if (_unavailablePeriods.isEmpty)
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                        color: f.card, borderRadius: BorderRadius.circular(18)),
                    child: Column(children: [
                      Icon(Icons.event_busy_rounded,
                          color: f.textMuted, size: 48),
                      const SizedBox(height: 12),
                      Text('No blocked periods',
                          style:
                              TextStyle(color: f.textSecondary, fontSize: 14))
                    ]))
              else
                ..._unavailablePeriods.map((a) => _buildAvailabilityBlock(a)),
              const SizedBox(height: 20),
              GestureDetector(
                  onTap: _showAddUnavailabilityDialog,
                  child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: cs.primary.withValues(alpha: 0.3),
                              width: 1.5)),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded,
                                color: cs.primary, size: 20),
                            const SizedBox(width: 8),
                            Text('Add Blocked Period',
                                style: TextStyle(
                                    color: cs.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                          ]))),
            ])));
  }

  Widget _buildAvailabilityBlock(CoachAvailability availability) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: f.error.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: f.error.withValues(alpha: 0.2))),
        child: Row(children: [
          Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: f.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.block_rounded, color: f.error, size: 20)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(availability.note ?? 'Blocked',
                    style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                Text(
                    '${_formatDate(availability.date)}  ·  ${availability.startLabel} – ${availability.endLabel}',
                    style: TextStyle(color: f.textMuted, fontSize: 12)),
              ])),
          GestureDetector(
              onTap: () => _deleteAvailability(availability),
              child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: f.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.delete_outline_rounded,
                      color: f.error, size: 18))),
        ]));
  }

  String _monthName(int m) => const [
        '',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ][m];
  String _formatDate(DateTime d) =>
      '${_monthName(d.month).substring(0, 3)} ${d.day}, ${d.year}';

  void _showReasonDialog(String title, Function(String) onConfirm) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final ctrl = TextEditingController();
    showDialog(
        context: context,
        builder: (ctx) => Dialog(
            backgroundColor: f.card,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 14),
                      TextField(
                          controller: ctrl,
                          maxLines: 3,
                          style: TextStyle(color: cs.onSurface, fontSize: 14),
                          decoration: InputDecoration(
                              hintText: 'Enter reason...',
                              hintStyle: TextStyle(color: f.textMuted),
                              filled: true,
                              fillColor: f.inputFill,
                              contentPadding: const EdgeInsets.all(14),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none))),
                      const SizedBox(height: 18),
                      Row(children: [
                        Expanded(
                            child: GestureDetector(
                                onTap: () => Navigator.pop(ctx),
                                child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 13),
                                    decoration: BoxDecoration(
                                        color: f.card2,
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: Center(
                                        child: Text('Cancel',
                                            style: TextStyle(
                                                color: cs.onSurface,
                                                fontWeight:
                                                    FontWeight.w600)))))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: GestureDetector(
                                onTap: () {
                                  if (ctrl.text.trim().isEmpty) return;
                                  Navigator.pop(ctx);
                                  onConfirm(ctrl.text.trim());
                                },
                                child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 13),
                                    decoration: BoxDecoration(
                                        color: f.error,
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: Center(
                                        child: Text('Confirm',
                                            style: TextStyle(
                                                color: cs.onError,
                                                fontWeight:
                                                    FontWeight.w700)))))),
                      ]),
                    ]))));
  }

  void _showAddUnavailabilityDialog() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final noteCtrl = TextEditingController();
    DateTime selectedDay = _selectedDate;
    int startHour = 9, startMinute = 0, endHour = 11, endMinute = 0;
    showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx2, setS) => Dialog(
                backgroundColor: f.card,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22)),
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Block Hours',
                              style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text('Block specific hours on a day.',
                              style: TextStyle(
                                  color: f.textSecondary, fontSize: 13)),
                          const SizedBox(height: 20),
                          GestureDetector(
                              onTap: () async {
                                final d = await showDatePicker(
                                    context: ctx2,
                                    initialDate: selectedDay,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 365)),
                                    builder: (c, child) => Theme(
                                        data: Theme.of(context),
                                        child: child!));
                                if (d != null) setS(() => selectedDay = d);
                              },
                              child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 13),
                                  decoration: BoxDecoration(
                                      color: f.inputFill,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Row(children: [
                                    Icon(Icons.calendar_today_rounded,
                                        color: cs.primary, size: 16),
                                    const SizedBox(width: 10),
                                    Text(_formatDate(selectedDay),
                                        style: TextStyle(
                                            color: cs.onSurface,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600)),
                                    const Spacer(),
                                    Icon(Icons.chevron_right_rounded,
                                        color: f.textMuted, size: 18)
                                  ]))),
                          const SizedBox(height: 14),
                          Row(children: [
                            Expanded(
                                child: _timeDropdown(
                                    'Start',
                                    startHour,
                                    startMinute,
                                    (h, m) => setS(() {
                                          startHour = h;
                                          startMinute = m;
                                        }))),
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Text('–',
                                    style: TextStyle(
                                        color: f.textMuted, fontSize: 20))),
                            Expanded(
                                child: _timeDropdown(
                                    'End',
                                    endHour,
                                    endMinute,
                                    (h, m) => setS(() {
                                          endHour = h;
                                          endMinute = m;
                                        }))),
                          ]),
                          const SizedBox(height: 14),
                          TextField(
                              controller: noteCtrl,
                              style:
                                  TextStyle(color: cs.onSurface, fontSize: 14),
                              decoration: InputDecoration(
                                  hintText: 'Note (optional)',
                                  hintStyle: TextStyle(color: f.textMuted),
                                  filled: true,
                                  fillColor: f.inputFill,
                                  contentPadding: const EdgeInsets.all(14),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none))),
                          const SizedBox(height: 20),
                          GestureDetector(
                              onTap: () {
                                if (endHour * 60 + endMinute <=
                                    startHour * 60 + startMinute) {
                                  return;
                                }
                                Navigator.pop(ctx);
                                _addAvailability(
                                    selectedDay,
                                    startHour,
                                    startMinute,
                                    endHour,
                                    endMinute,
                                    noteCtrl.text.isEmpty
                                        ? null
                                        : noteCtrl.text);
                              },
                              child: Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                      color: cs.primary,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Center(
                                      child: Text('Block These Hours',
                                          style: TextStyle(
                                              color: cs.onPrimary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14))))),
                        ])))));
  }

  Widget _timeDropdown(String label, int selectedHour, int selectedMinute,
      void Function(int, int) onChanged) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final hours =
        List.generate(_workEnd - _workStart + 1, (i) => _workStart + i);
    final minutes = [0, 15, 30, 45];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              color: f.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              color: f.inputFill, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Expanded(
                child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                        value: selectedHour,
                        dropdownColor: f.inputFill,
                        style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                        items: hours
                            .map((h) => DropdownMenuItem(
                                value: h,
                                child: Text(h.toString().padLeft(2, '0'))))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) onChanged(v, selectedMinute);
                        }))),
            Text(':', style: TextStyle(color: f.textMuted, fontSize: 16)),
            Expanded(
                child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                        value: selectedMinute,
                        dropdownColor: f.inputFill,
                        style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                        items: minutes
                            .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(m.toString().padLeft(2, '0'))))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) onChanged(selectedHour, v);
                        }))),
          ])),
    ]);
  }
}
