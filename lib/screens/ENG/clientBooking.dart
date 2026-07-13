import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:fitlek1/models/anas/reservation.dart';

import '../../theme/fitlek_theme_extension.dart';

const _red = Color(0xFFFF5252);
const _baseUrl = 'http://localhost:3000/api';

class BookingScreen extends StatefulWidget {
  final ReservationModel session;
  final String? token;
  final int? clientID;

  const BookingScreen({
    super.key,
    required this.session,
    this.token,
    this.clientID,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _selectedDate;
  String? _selectedTime;
  late DateTime _displayedMonth;
  bool _submitting = false;
  bool _loadingSlots = false;

  String? _selectedLocation;

  double _coachRating = 0;
  int _totalReviews = 0;
  double _coachPrice = 0;

  Map<String, List<String>> _blockedSlots = {};
  Map<String, List<String>> _reservedSlots = {};

  late AnimationController _slotAnimCtrl;
  late Animation<double> _slotFade;

  static const _allSlots = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _coachPrice = widget.session.price;

    _slotAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _slotFade = CurvedAnimation(parent: _slotAnimCtrl, curve: Curves.easeOut);

    _fetchAll();
  }

  @override
  void dispose() {
    _slotAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    await Future.wait([_fetchRating(), _fetchSlotsForMonth(_displayedMonth)]);
  }

  Future<void> _fetchRating() async {
    try {
      final res = await http
          .get(
            Uri.parse('$_baseUrl/reviews/coach/${widget.session.coachID}'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _coachRating = (data['avg'] as num?)?.toDouble() ?? 0;
          _totalReviews = data['total'] as int? ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchSlotsForMonth(DateTime month) async {
    setState(() => _loadingSlots = true);
    final coachID = widget.session.coachID;

    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final fromStr = _dateStr(firstDay);
    final toStr = _dateStr(lastDay);

    try {
      final blockRes = await http
          .get(
            Uri.parse('$_baseUrl/availability/$coachID'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 8));

      final resRes = await http
          .get(
            Uri.parse('$_baseUrl/reservations?role=coach&userID=$coachID'
                '&from=$fromStr&to=$toStr'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 8));

      if (!mounted) return;

      final Map<String, List<String>> blocked = {};
      final Map<String, List<String>> reserved = {};

      if (blockRes.statusCode == 200) {
        final List blocks = jsonDecode(blockRes.body);
        for (final b in blocks) {
          final dateKey = (b['blockedDate'] as String).substring(0, 10);
          final start = (b['startTime'] as String).substring(0, 5);
          final end = (b['endTime'] as String).substring(0, 5);
          for (final slot in _allSlots) {
            if (slot.compareTo(start) >= 0 && slot.compareTo(end) < 0) {
              blocked.putIfAbsent(dateKey, () => []).add(slot);
            }
          }
        }
      }

      if (resRes.statusCode == 200) {
        final List reservations = jsonDecode(resRes.body);
        for (final r in reservations) {
          final status = r['status'] as String;
          if (status == 'cancelled') continue;
          final dateKey = (r['reservedDate'] as String).substring(0, 10);
          final time = (r['reservedTime'] as String).substring(0, 5);
          reserved.putIfAbsent(dateKey, () => []).add(time);
        }
      }

      setState(() {
        _blockedSlots = blocked;
        _reservedSlots = reserved;
        _loadingSlots = false;
      });
      _slotAnimCtrl
        ..reset()
        ..forward();
    } catch (_) {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
      };

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _isPast(DateTime d) {
    final now = DateTime.now();
    return d.isBefore(DateTime(now.year, now.month, now.day));
  }

  bool _hasAnyUnavailable(DateTime d) {
    final key = _dateStr(d);
    return (_blockedSlots[key]?.isNotEmpty ?? false) ||
        (_reservedSlots[key]?.isNotEmpty ?? false);
  }

  List<_SlotInfo> _slotsFor(DateTime d) {
    final key = _dateStr(d);
    final blocked = _blockedSlots[key] ?? [];
    final reserved = _reservedSlots[key] ?? [];
    return _allSlots.map((t) {
      final isBlocked = blocked.contains(t);
      final isReserved = reserved.contains(t);
      return _SlotInfo(
        time: t,
        available: !isBlocked && !isReserved,
        isBlocked: isBlocked,
      );
    }).toList();
  }

  Future<void> _submitReservation() async {
    if (_selectedTime == null) return;
    setState(() => _submitting = true);

    try {
      final body = jsonEncode({
        'coachID': widget.session.coachID,
        'reservedDate': _dateStr(_selectedDate),
        'reservedTime': '$_selectedTime:00',
        if (widget.clientID != null) 'clientID': widget.clientID,
        'location': _selectedLocation ?? 'To be defined',
        'price': _coachPrice > 0 ? _coachPrice : widget.session.price,
      });

      final res = await http
          .post(Uri.parse('$_baseUrl/reservations'),
              headers: _headers, body: body)
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      setState(() => _submitting = false);

      if (res.statusCode == 201 || res.statusCode == 200) {
        final key = _dateStr(_selectedDate);
        setState(() {
          _reservedSlots.putIfAbsent(key, () => []).add(_selectedTime!);
          _selectedTime = null;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.onPrimary, size: 16),
              const SizedBox(width: 8),
              Text('Booking sent successfully!',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w700)),
            ]),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        final msg =
            jsonDecode(res.body)['error'] ?? 'Error (${res.statusCode})';
        _showError(msg);
      }
    } catch (e) {
      if (mounted) setState(() => _submitting = false);
      _showError('Unable to reach the server.');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(Icons.error_rounded,
            color: Theme.of(context).colorScheme.onError, size: 16),
        const SizedBox(width: 8),
        Expanded(
            child: Text(msg,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                    fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: _red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _onConfirm() {
    showDialog(
      context: context,
      builder: (_) => _ConfirmationDialog(
        session: widget.session,
        date: _selectedDate,
        time: _selectedTime!,
        rating: _coachRating,
        reviews: _totalReviews,
        location: _selectedLocation,
        price: _coachPrice > 0 ? _coachPrice : widget.session.price,
        onConfirm: _submitReservation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCoachCard(),
                  const SizedBox(height: 24),
                  _buildCalendar(),
                  const SizedBox(height: 24),
                  _buildTimeSlots(),
                  const SizedBox(height: 24),
                  _buildLocationSelector(),
                  const SizedBox(height: 28),
                  _buildConfirmButton(),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Row(children: [
          _iconBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text('Book a session',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1)),
          ),
        ]),
      );

  Widget _buildCoachCard() {
    final s = widget.session;
    final rating = _coachRating > 0 ? _coachRating : s.coachRating;
    final reviews = _totalReviews;
    final price = _coachPrice > 0 ? _coachPrice : s.price;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.fitlek.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.fitlek.border),
      ),
      child: Row(children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: Theme.of(context).colorScheme.primary, width: 2),
            boxShadow: [
              BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2),
                  blurRadius: 12)
            ],
          ),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: context.fitlek.card,
            backgroundImage: s.coachImageUrl.isNotEmpty
                ? NetworkImage(s.coachImageUrl)
                : null,
            child: s.coachImageUrl.isEmpty
                ? Text(
                    s.coachName.isNotEmpty ? s.coachName[0].toUpperCase() : '?',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900))
                : null,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.coachName,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3)),
            if (s.coachSpeciality.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(s.coachSpeciality,
                  style:
                      TextStyle(color: context.fitlek.textMuted, fontSize: 12)),
            ],
            const SizedBox(height: 8),
            Row(children: [
              ...List.generate(5, (i) {
                if (i < rating.floor()) {
                  return Icon(Icons.star_rounded,
                      color: Theme.of(context).colorScheme.primary, size: 13);
                } else if (i < rating && rating - i >= 0.5) {
                  return Icon(Icons.star_half_rounded,
                      color: Theme.of(context).colorScheme.primary, size: 13);
                } else {
                  return Icon(Icons.star_outline_rounded,
                      color: context.fitlek.textMuted, size: 13);
                }
              }),
              const SizedBox(width: 6),
              Text(
                rating > 0
                    ? '${rating.toStringAsFixed(1)}${reviews > 0 ? ' ($reviews)' : ''}'
                    : 'Not yet rated',
                style: TextStyle(
                    color: rating > 0
                        ? Theme.of(context).colorScheme.primary
                        : context.fitlek.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
              if (price > 0) ...[
                const SizedBox(width: 10),
                Container(
                  width: 1,
                  height: 10,
                  color: context.fitlek.border,
                ),
                const SizedBox(width: 10),
                Text('${price.toInt()} MAD/session',
                    style: TextStyle(
                        color: context.fitlek.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _buildCalendar() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
            width: 3,
            height: 16,
            color: Theme.of(context).colorScheme.primary,
            margin: const EdgeInsets.only(right: 10)),
        Text(_monthLabel(_displayedMonth),
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
        const Spacer(),
        _monthNavBtn(Icons.chevron_left_rounded, () {
          final prev =
              DateTime(_displayedMonth.year, _displayedMonth.month - 1);
          setState(() => _displayedMonth = prev);
          _fetchSlotsForMonth(prev);
        }),
        const SizedBox(width: 8),
        _monthNavBtn(Icons.chevron_right_rounded, () {
          final next =
              DateTime(_displayedMonth.year, _displayedMonth.month + 1);
          setState(() => _displayedMonth = next);
          _fetchSlotsForMonth(next);
        }),
      ]),
      const SizedBox(height: 14),
      Container(
        decoration: BoxDecoration(
          color: context.fitlek.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.fitlek.border),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: TextStyle(
                                color: context.fitlek.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
          _buildDays(),
        ]),
      ),
    ]);
  }

  Widget _monthNavBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.fitlek.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.fitlek.border),
          ),
          child: Icon(icon, color: context.fitlek.textMuted, size: 16),
        ),
      );

  Widget _buildDays() {
    final first = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final lastDay =
        DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final startWd = first.weekday;

    final cells = <Widget>[];
    for (int i = 1; i < startWd; i++) {
      cells.add(const SizedBox());
    }

    for (int d = 1; d <= lastDay; d++) {
      final date = DateTime(_displayedMonth.year, _displayedMonth.month, d);
      final now = DateTime.now();
      final isToday = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
      final isSelected = _dateStr(date) == _dateStr(_selectedDate);
      final isPast = _isPast(date) && !isToday;
      final hasDot = !isPast && _hasAnyUnavailable(date);

      cells.add(GestureDetector(
        onTap: isPast
            ? null
            : () => setState(() {
                  _selectedDate = date;
                  _selectedTime = null;
                  _slotAnimCtrl
                    ..reset()
                    ..forward();
                }),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : isToday
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.15)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isToday && !isSelected
                ? Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4),
                    width: 1)
                : null,
          ),
          child: Stack(alignment: Alignment.center, children: [
            Text('$d',
                style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : isPast
                            ? context.fitlek.textMuted
                            : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected || isToday
                        ? FontWeight.w800
                        : FontWeight.w500,
                    fontSize: 13)),
            if (hasDot && !isSelected)
              Positioned(
                bottom: 2,
                child: Container(
                  width: 3,
                  height: 3,
                  decoration:
                      const BoxDecoration(color: _red, shape: BoxShape.circle),
                ),
              ),
          ]),
        ),
      ));
    }

    return GridView.count(
      crossAxisCount: 7,
      childAspectRatio: 1.15,
      mainAxisSpacing: 6,
      crossAxisSpacing: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }

  Widget _buildLocationSelector() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
            width: 3,
            height: 16,
            color: Theme.of(context).colorScheme.primary,
            margin: const EdgeInsets.only(right: 10)),
        Text('Session location',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 14),
      Container(
        decoration: BoxDecoration(
          color: context.fitlek.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.fitlek.border),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          _locationOption(
            icon: Icons.home_rounded,
            label: 'My home',
            subtitle: 'The coach comes to you',
            value: 'home',
          ),
          const SizedBox(height: 10),
          _locationOption(
            icon: Icons.fitness_center_rounded,
            label: 'Your gym',
            subtitle: 'Session at the coach\'s gym',
            value: 'gym',
          ),
          const SizedBox(height: 10),
          _locationOption(
            icon: Icons.help_outline_rounded,
            label: 'To be defined',
            subtitle: 'You\'ll decide later',
            value: null,
          ),
        ]),
      ),
    ]);
  }

  Widget _locationOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required String? value,
  }) {
    final isSelected = _selectedLocation == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedLocation = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : context.fitlek.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.15)
                  : context.fitlek.card2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : context.fitlek.textMuted,
                size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onSurface
                          : context.fitlek.textSecondary,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style:
                      TextStyle(color: context.fitlek.textMuted, fontSize: 11)),
            ]),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : context.fitlek.border,
                width: 2,
              ),
            ),
            child: isSelected
                ? Icon(Icons.check_rounded,
                    color: Theme.of(context).colorScheme.onPrimary, size: 14)
                : null,
          ),
        ]),
      ),
    );
  }

  Widget _buildTimeSlots() {
    final slots = _slotsFor(_selectedDate);
    final availableCount = slots.where((s) => s.available).length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
            width: 3,
            height: 16,
            color: Theme.of(context).colorScheme.primary,
            margin: const EdgeInsets.only(right: 10)),
        Text('Time slots',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
        const Spacer(),
        if (!_loadingSlots)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: availableCount > 0
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : _red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: availableCount > 0
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3)
                      : _red.withValues(alpha: 0.3)),
            ),
            child: Text(
              availableCount > 0 ? '$availableCount available' : 'Full',
              style: TextStyle(
                  color: availableCount > 0
                      ? Theme.of(context).colorScheme.primary
                      : _red,
                  fontSize: 10,
                  fontWeight: FontWeight.w700),
            ),
          ),
      ]),
      const SizedBox(height: 6),
      Text(_formattedDate(_selectedDate),
          style: TextStyle(color: context.fitlek.textMuted, fontSize: 12)),
      const SizedBox(height: 14),
      if (_loadingSlots)
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary, strokeWidth: 2),
            ),
          ),
        )
      else
        FadeTransition(
          opacity: _slotFade,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.55,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: slots.length,
            itemBuilder: (_, i) {
              final slot = slots[i];
              final isSelected = _selectedTime == slot.time;
              return GestureDetector(
                onTap: slot.available
                    ? () => setState(() => _selectedTime = slot.time)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : slot.available
                            ? context.fitlek.card
                            : _red.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : slot.available
                              ? (isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : context.fitlek.border)
                              : _red.withValues(alpha: 0.3),
                      width: isSelected ? 0 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3))
                          ]
                        : null,
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(slot.time,
                            style: TextStyle(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : slot.available
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                        : _red.withValues(alpha: 0.6),
                                fontWeight: isSelected
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                                fontSize: 13)),
                        const SizedBox(height: 3),
                        Text(
                          isSelected
                              ? '✓ Selected'
                              : slot.available
                                  ? '1h'
                                  : slot.isBlocked
                                      ? 'Blocked'
                                      : 'Booked',
                          style: TextStyle(
                              color: isSelected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onPrimary
                                      .withValues(alpha: 0.7)
                                  : slot.available
                                      ? context.fitlek.textMuted
                                      : _red.withValues(alpha: 0.5),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3),
                        ),
                      ]),
                ),
              );
            },
          ),
        ),
      const SizedBox(height: 12),
      Row(children: [
        _dot(Theme.of(context).colorScheme.primary),
        const SizedBox(width: 5),
        Text('Free',
            style: TextStyle(color: context.fitlek.textMuted, fontSize: 10)),
        const SizedBox(width: 16),
        _dot(_red.withValues(alpha: 0.7)),
        const SizedBox(width: 5),
        Text('Unavailable',
            style: TextStyle(color: context.fitlek.textMuted, fontSize: 10)),
      ]),
    ]);
  }

  Widget _dot(Color color) => Container(
      width: 8,
      height: 8,
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)));

  Widget _buildConfirmButton() {
    final valid = _selectedTime != null && !_submitting;
    return GestureDetector(
      onTap: valid ? _onConfirm : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: valid
              ? Theme.of(context).colorScheme.primary
              : context.fitlek.card2,
          borderRadius: BorderRadius.circular(14),
          boxShadow: valid
              ? [
                  BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6))
                ]
              : null,
        ),
        child: _submitting
            ? Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onPrimary,
                      strokeWidth: 2.5),
                ),
              )
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(
                  valid
                      ? Icons.event_available_rounded
                      : Icons.event_busy_rounded,
                  color: valid
                      ? Theme.of(context).colorScheme.onPrimary
                      : context.fitlek.textMuted,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  valid ? 'CONFIRM · $_selectedTime' : 'CHOOSE A SLOT',
                  style: TextStyle(
                      color: valid
                          ? Theme.of(context).colorScheme.onPrimary
                          : context.fitlek.textMuted,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.2),
                ),
              ]),
      ),
    );
  }

  Widget _iconBtn({required IconData icon, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.fitlek.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.fitlek.border),
          ),
          child: Icon(icon,
              color: Theme.of(context).colorScheme.onSurface, size: 16),
        ),
      );

  String _monthLabel(DateTime d) {
    const months = [
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
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  String _formattedDate(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    const w = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${w[d.weekday - 1]} ${d.day} ${m[d.month - 1]}';
  }
}

class _SlotInfo {
  final String time;
  final bool available;
  final bool isBlocked;
  const _SlotInfo({
    required this.time,
    required this.available,
    required this.isBlocked,
  });
}

class _ConfirmationDialog extends StatelessWidget {
  final ReservationModel session;
  final DateTime date;
  final String time;
  final double rating;
  final int reviews;
  final String? location;
  final double price;
  final VoidCallback onConfirm;

  const _ConfirmationDialog({
    required this.session,
    required this.date,
    required this.time,
    required this.rating,
    required this.reviews,
    required this.location,
    required this.price,
    required this.onConfirm,
  });

  String get _locationLabel {
    switch (location) {
      case 'home':
        return 'My home';
      case 'gym':
        return 'Your gym';
      default:
        return 'To be defined';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                  width: 3,
                  height: 18,
                  color: Theme.of(context).colorScheme.primary,
                  margin: const EdgeInsets.only(right: 10)),
              Text('Confirm booking',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.fitlek.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.fitlek.border),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: context.fitlek.card,
                        backgroundImage: session.coachImageUrl.isNotEmpty
                            ? NetworkImage(session.coachImageUrl)
                            : null,
                        child: session.coachImageUrl.isEmpty
                            ? Text(
                                session.coachName.isNotEmpty
                                    ? session.coachName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w900))
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(session.coachName,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14)),
                              const SizedBox(height: 2),
                              Row(children: [
                                ...List.generate(
                                    5,
                                    (i) => Icon(
                                          i < rating.floor()
                                              ? Icons.star_rounded
                                              : (i < rating &&
                                                      rating - i >= 0.5)
                                                  ? Icons.star_half_rounded
                                                  : Icons.star_outline_rounded,
                                          color: i < rating
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : context.fitlek.textMuted,
                                          size: 11,
                                        )),
                                const SizedBox(width: 5),
                                Text(
                                  rating > 0
                                      ? '${rating.toStringAsFixed(1)}${reviews > 0 ? ' · $reviews reviews' : ''}'
                                      : 'Not yet rated',
                                  style: TextStyle(
                                      color: rating > 0
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : context.fitlek.textMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700),
                                ),
                              ]),
                            ]),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    Divider(color: context.fitlek.border, height: 1),
                    const SizedBox(height: 14),
                    _infoRow(context, Icons.calendar_today_rounded, 'Date',
                        _dateLabel(date)),
                    const SizedBox(height: 10),
                    _infoRow(context, Icons.access_time_rounded, 'Time',
                        '$time — ${_addHour(time)}'),
                    const SizedBox(height: 10),
                    _infoRow(context, Icons.location_on_rounded, 'Location',
                        _locationLabel),
                    if (price > 0) ...[
                      const SizedBox(height: 10),
                      _infoRow(context, Icons.payments_rounded, 'Price',
                          '${price.toInt()} MAD / session',
                          valueColor: Theme.of(context).colorScheme.primary),
                    ],
                  ]),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: context.fitlek.card2,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: context.fitlek.border),
                    ),
                    child: Text('CANCEL',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: context.fitlek.textSecondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 1.2)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onConfirm();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: [
                        BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Text('CONFIRM',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 1.2)),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
          BuildContext context, IconData icon, String label, String value,
          {Color? valueColor}) =>
      Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon,
              color: Theme.of(context).colorScheme.primary, size: 12),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(color: context.fitlek.textMuted, fontSize: 11)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 12)),
      ]);

  String _dateLabel(DateTime d) {
    const m = [
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
    ];
    const w = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return '${w[d.weekday - 1]} ${d.day} ${m[d.month - 1]}';
  }

  String _addHour(String t) {
    final h = int.parse(t.split(':')[0]);
    return '${(h + 1).toString().padLeft(2, '0')}:00';
  }
}
