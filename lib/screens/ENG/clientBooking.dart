import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:fitlek1/models/anas/reservation.dart';

const _lime       = Color(0xFFC6F135);
const _limeDeep   = Color(0xFFAAD400);
const _dark       = Color(0xFF0A0A0A);
const _card       = Color(0xFF141414);
const _cardBorder = Color(0xFF232323);
const _red        = Color(0xFFFF5252);
const _baseUrl    = 'http://localhost:3000/api';

class BookingScreen extends StatefulWidget {
  final ReservationModel session;
  final String?          token;
  final int?             clientID;

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
  String?       _selectedTime;
  late DateTime _displayedMonth;
  bool          _submitting  = false;
  bool          _loadingSlots = false;

  String? _selectedLocation;

  double _coachRating   = 0;
  int    _totalReviews  = 0;
  double _coachPrice    = 0;

  Map<String, List<String>> _blockedSlots   = {};
  Map<String, List<String>> _reservedSlots  = {};

  late AnimationController _slotAnimCtrl;
  late Animation<double>   _slotFade;

  static const _allSlots = [
    '08:00','09:00','10:00','11:00','12:00',
    '13:00','14:00','15:00','16:00','17:00',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate   = DateTime.now().add(const Duration(days: 1));
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
    await Future.wait([
      _fetchRating(),
      _fetchCoachPrice(),
      _fetchSlotsForMonth(_displayedMonth)
    ]);
  }

  Future<void> _fetchRating() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/reviews/coach/${widget.session.coachID}'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _coachRating  = (data['avg'] as num?)?.toDouble() ?? 0;
          _totalReviews = data['total'] as int? ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchCoachPrice() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/coaches/${widget.session.coachID}'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        final price = (data['price'] as num?)?.toDouble() ??
                      (data['sessionPrice'] as num?)?.toDouble() ??
                      (data['pricePerSession'] as num?)?.toDouble() ??
                      widget.session.price;
        if (price > 0) {
          setState(() => _coachPrice = price);
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchSlotsForMonth(DateTime month) async {
    setState(() => _loadingSlots = true);
    final coachID = widget.session.coachID;

    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay  = DateTime(month.year, month.month + 1, 0);
    final fromStr  = _dateStr(firstDay);
    final toStr    = _dateStr(lastDay);

    try {
      final blockRes = await http.get(
        Uri.parse('$_baseUrl/availability/$coachID'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));

      final resRes = await http.get(
        Uri.parse('$_baseUrl/reservations?role=coach&userID=$coachID'
            '&from=$fromStr&to=$toStr'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));

      if (!mounted) return;

      final Map<String, List<String>> blocked  = {};
      final Map<String, List<String>> reserved = {};

      if (blockRes.statusCode == 200) {
        final List blocks = jsonDecode(blockRes.body);
        for (final b in blocks) {
          final dateKey = (b['blockedDate'] as String).substring(0, 10);
          final start   = (b['startTime'] as String).substring(0, 5);
          final end     = (b['endTime']   as String).substring(0, 5);
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
          final time    = (r['reservedTime'] as String).substring(0, 5);
          reserved.putIfAbsent(dateKey, () => []).add(time);
        }
      }

      setState(() {
        _blockedSlots  = blocked;
        _reservedSlots = reserved;
        _loadingSlots  = false;
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
    return (_blockedSlots[key]?.isNotEmpty  ?? false) ||
           (_reservedSlots[key]?.isNotEmpty ?? false);
  }

  List<_SlotInfo> _slotsFor(DateTime d) {
    final key     = _dateStr(d);
    final blocked  = _blockedSlots[key]  ?? [];
    final reserved = _reservedSlots[key] ?? [];
    return _allSlots.map((t) {
      final isBlocked  = blocked.contains(t);
      final isReserved = reserved.contains(t);
      return _SlotInfo(
        time:      t,
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
        'coachID':      widget.session.coachID,
        'reservedDate': _dateStr(_selectedDate),
        'reservedTime': '$_selectedTime:00',
        if (widget.clientID != null) 'clientID': widget.clientID,
        'location': _selectedLocation ?? 'À définir',
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
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.black, size: 16),
              SizedBox(width: 8),
              Text('Réservation envoyée avec succès !',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
            ]),
            backgroundColor: _lime,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        final msg = jsonDecode(res.body)['error'] ?? 'Erreur (${res.statusCode})';
        _showError(msg);
      }
    } catch (e) {
      if (mounted) setState(() => _submitting = false);
      _showError('Impossible de joindre le serveur.');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_rounded, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
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
        session:      widget.session,
        date:         _selectedDate,
        time:         _selectedTime!,
        rating:       _coachRating,
        reviews:      _totalReviews,
        location:     _selectedLocation,
        price:        _coachPrice > 0 ? _coachPrice : widget.session.price,
        onConfirm:    _submitReservation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
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
      const Expanded(
        child: Text('Réserver une séance',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1)),
      ),
    ]),
  );

  Widget _buildCoachCard() {
    final s = widget.session;
    final rating   = _coachRating > 0 ? _coachRating : s.coachRating;
    final reviews  = _totalReviews;
    final price    = _coachPrice > 0 ? _coachPrice : s.price;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _lime, width: 2),
            boxShadow: [BoxShadow(color: _lime.withOpacity(0.2), blurRadius: 12)],
          ),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: _card,
            backgroundImage:
                s.coachImageUrl.isNotEmpty ? NetworkImage(s.coachImageUrl) : null,
            child: s.coachImageUrl.isEmpty
                ? Text(s.coachName.isNotEmpty ? s.coachName[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: _lime, fontSize: 22, fontWeight: FontWeight.w900))
                : null,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.coachName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3)),
            if (s.coachSpeciality.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(s.coachSpeciality,
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
            const SizedBox(height: 8),
            Row(children: [
              ...List.generate(5, (i) {
                if (i < rating.floor()) {
                  return const Icon(Icons.star_rounded, color: _lime, size: 13);
                } else if (i < rating && rating - i >= 0.5) {
                  return const Icon(Icons.star_half_rounded, color: _lime, size: 13);
                } else {
                  return const Icon(Icons.star_outline_rounded,
                      color: Colors.white24, size: 13);
                }
              }),
              const SizedBox(width: 6),
              Text(
                rating > 0
                    ? '${rating.toStringAsFixed(1)}${reviews > 0 ? ' ($reviews)' : ''}'
                    : 'Pas encore noté',
                style: TextStyle(
                    color: rating > 0 ? _lime : Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
              if (price > 0) ...[
                const SizedBox(width: 10),
                Container(
                  width: 1, height: 10,
                  color: Colors.white12,
                ),
                const SizedBox(width: 10),
                Text('${price.toInt()} MAD/séance',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
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
        Container(width: 3, height: 16, color: _lime,
            margin: const EdgeInsets.only(right: 10)),
        Text(_monthLabel(_displayedMonth),
            style: const TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
        const Spacer(),
        _monthNavBtn(Icons.chevron_left_rounded, () {
          final prev = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
          setState(() => _displayedMonth = prev);
          _fetchSlotsForMonth(prev);
        }),
        const SizedBox(width: 8),
        _monthNavBtn(Icons.chevron_right_rounded, () {
          final next = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
          setState(() => _displayedMonth = next);
          _fetchSlotsForMonth(next);
        }),
      ]),
      const SizedBox(height: 14),
      Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _cardBorder),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Row(
            children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: const TextStyle(
                                color: Colors.white24,
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
        color: _card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _cardBorder),
      ),
      child: Icon(icon, color: Colors.white38, size: 16),
    ),
  );

  Widget _buildDays() {
    final first   = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final lastDay = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final startWd = first.weekday;

    final cells = <Widget>[];
    for (int i = 1; i < startWd; i++) cells.add(const SizedBox());

    for (int d = 1; d <= lastDay; d++) {
      final date = DateTime(_displayedMonth.year, _displayedMonth.month, d);
      final now  = DateTime.now();
      final isToday    = date.year == now.year && date.month == now.month && date.day == now.day;
      final isSelected = _dateStr(date) == _dateStr(_selectedDate);
      final isPast     = _isPast(date) && !isToday;
      final hasDot     = !isPast && _hasAnyUnavailable(date);

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
                ? _lime
                : isToday
                    ? _lime.withOpacity(0.15)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isToday && !isSelected
                ? Border.all(color: _lime.withOpacity(0.4), width: 1)
                : null,
          ),
          child: Stack(alignment: Alignment.center, children: [
            Text('$d',
                style: TextStyle(
                    color: isSelected
                        ? Colors.black
                        : isPast
                            ? Colors.white12
                            : Colors.white,
                    fontWeight:
                        isSelected || isToday ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 13)),
            if (hasDot && !isSelected)
              Positioned(
                bottom: 2,
                child: Container(
                  width: 3,
                  height: 3,
                  decoration: const BoxDecoration(
                      color: _red, shape: BoxShape.circle),
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
        Container(width: 3, height: 16, color: _lime,
            margin: const EdgeInsets.only(right: 10)),
        const Text('Lieu de la séance',
            style: TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 14),
      Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _cardBorder),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          _locationOption(
            icon: Icons.home_rounded,
            label: 'Mon domicile',
            subtitle: 'Le coach se déplace chez vous',
            value: 'home',
          ),
          const SizedBox(height: 10),
          _locationOption(
            icon: Icons.fitness_center_rounded,
            label: 'Votre salle',
            subtitle: 'Séance dans la salle du coach',
            value: 'gym',
          ),
          const SizedBox(height: 10),
          _locationOption(
            icon: Icons.help_outline_rounded,
            label: 'À définir',
            subtitle: 'Vous déciderez plus tard',
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
          color: isSelected ? _lime.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _lime : _cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? _lime.withOpacity(0.15) : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: isSelected ? _lime : Colors.white38, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ]),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? _lime : Colors.transparent,
              border: Border.all(
                color: isSelected ? _lime : Colors.white24,
                width: 2,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, color: Colors.black, size: 14)
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
        Container(width: 3, height: 16, color: _lime,
            margin: const EdgeInsets.only(right: 10)),
        const Text('Créneaux',
            style: TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
        const Spacer(),
        if (!_loadingSlots)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: availableCount > 0
                  ? _lime.withOpacity(0.1)
                  : _red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: availableCount > 0
                      ? _lime.withOpacity(0.3)
                      : _red.withOpacity(0.3)),
            ),
            child: Text(
              availableCount > 0
                  ? '$availableCount disponible${availableCount > 1 ? 's' : ''}'
                  : 'Complet',
              style: TextStyle(
                  color: availableCount > 0 ? _lime : _red,
                  fontSize: 10,
                  fontWeight: FontWeight.w700),
            ),
          ),
      ]),
      const SizedBox(height: 6),
      Text(_formattedDate(_selectedDate),
          style: const TextStyle(color: Colors.white38, fontSize: 12)),
      const SizedBox(height: 14),

      if (_loadingSlots)
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(color: _lime, strokeWidth: 2),
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
              final slot       = slots[i];
              final isSelected = _selectedTime == slot.time;
              return GestureDetector(
                onTap: slot.available
                    ? () => setState(() => _selectedTime = slot.time)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _lime
                        : slot.available
                            ? _card
                            : _red.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? _lime
                          : slot.available
                              ? (isSelected ? _lime : _cardBorder)
                              : _red.withOpacity(0.3),
                      width: isSelected ? 0 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(
                            color: _lime.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 3))]
                        : null,
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(slot.time,
                            style: TextStyle(
                                color: isSelected
                                    ? Colors.black
                                    : slot.available
                                        ? Colors.white
                                        : _red.withOpacity(0.6),
                                fontWeight: isSelected
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                                fontSize: 13)),
                        const SizedBox(height: 3),
                        Text(
                          isSelected
                              ? '✓ Sélectionné'
                              : slot.available
                                  ? '1h'
                                  : slot.isBlocked
                                      ? 'Bloqué'
                                      : 'Réservé',
                          style: TextStyle(
                              color: isSelected
                                  ? Colors.black54
                                  : slot.available
                                      ? Colors.white38
                                      : _red.withOpacity(0.5),
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
        _dot(_lime),
        const SizedBox(width: 5),
        const Text('Libre', style: TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(width: 16),
        _dot(_red.withOpacity(0.7)),
        const SizedBox(width: 5),
        const Text('Indisponible', style: TextStyle(color: Colors.white38, fontSize: 10)),
      ]),
    ]);
  }

  Widget _dot(Color color) => Container(
      width: 8, height: 8,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)));

  Widget _buildConfirmButton() {
    final valid = _selectedTime != null && !_submitting;
    return GestureDetector(
      onTap: valid ? _onConfirm : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: valid ? _lime : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          boxShadow: valid
              ? [BoxShadow(
                  color: _lime.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 6))]
              : null,
        ),
        child: _submitting
            ? const Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.black, strokeWidth: 2.5),
                ),
              )
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(
                  valid ? Icons.event_available_rounded : Icons.event_busy_rounded,
                  color: valid ? Colors.black : Colors.white24,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  valid
                      ? 'CONFIRMER · $_selectedTime'
                      : 'CHOISIR UN CRÉNEAU',
                  style: TextStyle(
                      color: valid ? Colors.black : Colors.white24,
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
            color: _card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _cardBorder),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
      );

  String _monthLabel(DateTime d) {
    const months = [
      'Janvier','Février','Mars','Avril','Mai','Juin',
      'Juillet','Août','Septembre','Octobre','Novembre','Décembre'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  String _formattedDate(DateTime d) {
    const m = ['Jan','Fév','Mar','Avr','Mai','Jun',
                'Jul','Aoû','Sep','Oct','Nov','Déc'];
    const w = ['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'];
    return '${w[d.weekday - 1]} ${d.day} ${m[d.month - 1]}';
  }
}

class _SlotInfo {
  final String time;
  final bool   available;
  final bool   isBlocked;
  const _SlotInfo({
    required this.time,
    required this.available,
    required this.isBlocked,
  });
}

class _ConfirmationDialog extends StatelessWidget {
  final ReservationModel session;
  final DateTime         date;
  final String           time;
  final double           rating;
  final int              reviews;
  final String?          location;
  final double           price;
  final VoidCallback     onConfirm;

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
        return 'Mon domicile';
      case 'gym':
        return 'Votre salle';
      default:
        return 'À définir';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _dark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 3, height: 18, color: _lime,
                  margin: const EdgeInsets.only(right: 10)),
              const Text('Confirmer la réservation',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _cardBorder),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _card,
                    backgroundImage: session.coachImageUrl.isNotEmpty
                        ? NetworkImage(session.coachImageUrl)
                        : null,
                    child: session.coachImageUrl.isEmpty
                        ? Text(
                            session.coachName.isNotEmpty
                                ? session.coachName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: _lime, fontWeight: FontWeight.w900))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(session.coachName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14)),
                      const SizedBox(height: 2),
                      Row(children: [
                        ...List.generate(5, (i) => Icon(
                          i < rating.floor()
                              ? Icons.star_rounded
                              : (i < rating && rating - i >= 0.5)
                                  ? Icons.star_half_rounded
                                  : Icons.star_outline_rounded,
                          color: i < rating ? _lime : Colors.white24,
                          size: 11,
                        )),
                        const SizedBox(width: 5),
                        Text(
                          rating > 0
                              ? '${rating.toStringAsFixed(1)}${reviews > 0 ? ' · $reviews avis' : ''}'
                              : 'Pas encore noté',
                          style: TextStyle(
                              color: rating > 0 ? _lime : Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ]),
                    ]),
                  ),
                ]),

                const SizedBox(height: 14),
                const Divider(color: Color(0xFF232323), height: 1),
                const SizedBox(height: 14),

                _infoRow(Icons.calendar_today_rounded, 'Date', _dateLabel(date)),
                const SizedBox(height: 10),
                _infoRow(Icons.access_time_rounded, 'Heure',
                    '$time — ${_addHour(time)}'),
                const SizedBox(height: 10),
                _infoRow(Icons.location_on_rounded, 'Lieu', _locationLabel),
                if (price > 0) ...[
                  const SizedBox(height: 10),
                  _infoRow(Icons.payments_rounded, 'Tarif',
                      '${price.toInt()} MAD / séance',
                      valueColor: _lime),
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
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: _cardBorder),
                    ),
                    child: const Text('ANNULER',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white54,
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
                      color: _lime,
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: [
                        BoxShadow(
                            color: _lime.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: const Text('CONFIRMER',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.black,
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

  Widget _infoRow(IconData icon, String label, String value,
          {Color valueColor = Colors.white}) =>
      Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _lime.withOpacity(0.08),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: _lime, size: 12),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w700,
                fontSize: 12)),
      ]);

  String _dateLabel(DateTime d) {
    const m = ['Janvier','Février','Mars','Avril','Mai','Juin',
                'Juillet','Août','Septembre','Octobre','Novembre','Décembre'];
    const w = ['Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi','Dimanche'];
    return '${w[d.weekday - 1]} ${d.day} ${m[d.month - 1]}';
  }

  String _addHour(String t) {
    final h = int.parse(t.split(':')[0]);
    return '${(h + 1).toString().padLeft(2, '0')}:00';
  }
}
