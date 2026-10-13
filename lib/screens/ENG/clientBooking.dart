import '../../services/live_updates.dart';
import '../../services/booking_policy.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fitlek1/models/anas/reservation.dart';
import 'package:fitlek1/models/anas/coachPackage.dart';
import 'package:fitlek1/constants/urls.dart';
import '../../theme/fitlek_theme_extension.dart';

const _red = Color(0xFFFF5252);

class ScheduledSession {
  DateTime? date;
  String? time;

  ScheduledSession({this.date, this.time});

  bool get isComplete => date != null && time != null;
}

class BookingScreen extends StatefulWidget {
  final ReservationModel session;
  final String? token;
  final int? clientID;
  final List<CoachPackage> packages;
  final DateTime? initialDate;
  final String? initialTime;

  final CoachPackage? initialPackage;

  const BookingScreen({
    super.key,
    required this.session,
    this.token,
    this.clientID,
    this.packages = const [],
    this.initialDate,
    this.initialTime,
    this.initialPackage,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with SingleTickerProviderStateMixin, LiveUpdates<BookingScreen> {
  @override
  Set<String> get liveDomains => {
        'calendar',
        'availability',
        'reservations',
        'packages',
        'profile',
        'edit',
        'coaches'
      };
  @override
  Future<void> refreshLiveData() async {
    await Future.wait(
        [_fetchGym(), _fetchSlotsForMonth(_displayedMonth, silent: true)]);
  }

  late DateTime _selectedDate;
  String? _selectedTime;
  late DateTime _displayedMonth;
  bool _submitting = false;
  bool _loadingSlots = false;

  String? _selectedLocation;
  String _gymName = '';
  String _gymAddress = '';
  String get _bookingLocation => _selectedLocation == 'gym'
      ? [_gymName, _gymAddress].where((v) => v.isNotEmpty).join(' · ')
      : _selectedLocation == 'home'
          ? 'Home visit — arrange address with coach in messages'
          : 'Location to be arranged with coach in messages';
  CoachPackage?
      _selectedPackage; // null means no package selected (book directly)
  bool _packageStepDone =
      false; // true once the client has confirmed package choice

  int _activeSessionIndex = 0;
  List<ScheduledSession> _selectedSessions = [];

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
    '18:00',
    '19:00',
    '20:00',
    '21:00',
    '22:00',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now().add(Duration(days: 1));
    _selectedTime = widget.initialTime;
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _coachPrice = widget.session.price;
    if (widget.initialPackage != null) {
      _selectedPackage = widget.initialPackage;
      _packageStepDone = true;
    }

    final count = (_selectedPackage != null &&
            _selectedPackage!.sessions != null &&
            _selectedPackage!.sessions! > 0)
        ? _selectedPackage!.sessions!
        : 1;

    _selectedSessions = List.generate(count, (i) {
      if (i == 0) {
        return ScheduledSession(
          date: _selectedDate,
          time: _selectedTime,
        );
      }
      return ScheduledSession();
    });
    _activeSessionIndex = 0;

    _slotAnimCtrl =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _slotFade = CurvedAnimation(parent: _slotAnimCtrl, curve: Curves.easeOut);

    _fetchAll();
  }

  @override
  void dispose() {
    _slotAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    await Future.wait(
        [_fetchGym(), _fetchRating(), _fetchSlotsForMonth(_displayedMonth)]);
  }

  Future<void> _fetchGym() async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/coaches/${widget.session.coachID}'),
          headers: {'Authorization': 'Bearer ${widget.token}'});
      if (!mounted || response.statusCode != 200) return;
      final data = jsonDecode(response.body);
      setState(() {
        _gymName = data['gymName']?.toString().trim() ?? '';
        _gymAddress = data['gymAddress']?.toString().trim() ?? '';
        if (_gymName.isEmpty && _selectedLocation == 'gym')
          _selectedLocation = null;
      });
    } catch (_) {}
  }

  Future<void> _fetchRating() async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/reviews/coach/${widget.session.coachID}'),
            headers: _headers,
          )
          .timeout(Duration(seconds: 8));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _coachRating = (data['avg'] as num?)?.toDouble() ?? 0;
          _totalReviews = data['total'] as int? ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchSlotsForMonth(DateTime month,
      {bool silent = false}) async {
    if (!silent) setState(() => _loadingSlots = true);
    final coachID = widget.session.coachID;

    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final fromStr = _dateStr(firstDay);
    final toStr = _dateStr(lastDay);

    try {
      final blockRes = await http
          .get(
            Uri.parse('$baseUrl/availability/$coachID'),
            headers: _headers,
          )
          .timeout(Duration(seconds: 8));

      final resRes = await http
          .get(
            Uri.parse('$baseUrl/reservations?role=coach&userID=$coachID'
                '&from=$fromStr&to=$toStr'),
            headers: _headers,
          )
          .timeout(Duration(seconds: 8));

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
      if (!silent) {
        _slotAnimCtrl
          ..reset()
          ..forward();
      }
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

  void _selectPackage(CoachPackage? pkg) {
    setState(() {
      _selectedPackage = pkg;
      final count = (pkg != null && pkg.sessions != null && pkg.sessions! > 0)
          ? pkg.sessions!
          : 1;

      List<ScheduledSession> updated = [];
      for (int i = 0; i < count; i++) {
        if (i < _selectedSessions.length) {
          updated.add(_selectedSessions[i]);
        } else {
          updated.add(ScheduledSession());
        }
      }
      _selectedSessions = updated;
      if (_activeSessionIndex >= count) {
        _activeSessionIndex = 0;
      }
      final active = _selectedSessions[_activeSessionIndex];
      if (active.date != null) {
        _selectedDate = active.date!;
      }
      _selectedTime = active.time;
    });
  }

  void _switchActiveSession(int idx) {
    setState(() {
      _activeSessionIndex = idx;
      final s = _selectedSessions[idx];
      if (s.date != null) {
        _selectedDate = s.date!;
        if (_displayedMonth.year != _selectedDate.year ||
            _displayedMonth.month != _selectedDate.month) {
          _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);
          _fetchSlotsForMonth(_displayedMonth);
        }
      }
      _selectedTime = s.time;
    });
    _slotAnimCtrl
      ..reset()
      ..forward();
  }

  void _onTimeSelected(String slotTime) {
    setState(() {
      _selectedTime = slotTime;
      _selectedSessions[_activeSessionIndex].date = _selectedDate;
      _selectedSessions[_activeSessionIndex].time = slotTime;

      // Auto-advance to next incomplete session if multi-session
      if (_selectedSessions.length > 1) {
        final nextIncomplete =
            _selectedSessions.indexWhere((s) => !s.isComplete);
        if (nextIncomplete != -1 && nextIncomplete != _activeSessionIndex) {
          _activeSessionIndex = nextIncomplete;
          final nextS = _selectedSessions[_activeSessionIndex];
          if (nextS.date != null) {
            _selectedDate = nextS.date!;
            if (_displayedMonth.year != _selectedDate.year ||
                _displayedMonth.month != _selectedDate.month) {
              _displayedMonth =
                  DateTime(_selectedDate.year, _selectedDate.month);
              _fetchSlotsForMonth(_displayedMonth);
            }
          }
          _selectedTime = nextS.time;
        }
      }
    });
  }

  String _formattedShortDate(DateTime d) {
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
    return '${m[d.month - 1]} ${d.day}';
  }

  bool get _allSessionsComplete =>
      _selectedSessions.isNotEmpty &&
      _selectedSessions.every((s) => s.isComplete);

  List<_SlotInfo> _slotsFor(DateTime d) {
    final key = _dateStr(d);
    final blocked = _blockedSlots[key] ?? [];
    final reserved = _reservedSlots[key] ?? [];
    final now = DateTime.now();

    final otherBookings = <String, int>{};
    for (int i = 0; i < _selectedSessions.length; i++) {
      if (i != _activeSessionIndex) {
        final s = _selectedSessions[i];
        if (s.date != null && _dateStr(s.date!) == key && s.time != null) {
          otherBookings[s.time!] = i + 1;
        }
      }
    }

    return _allSlots.map((t) {
      final parts = t.split(':');
      final start = DateTime(
          d.year, d.month, d.day, int.parse(parts[0]), int.parse(parts[1]));
      final tooSoon = !hasBookingLeadTime(start, now: now);
      final sessionIndex = otherBookings[t];
      final isTakenByPackageSession = sessionIndex != null;
      final isBlocked =
          blocked.contains(t) || tooSoon || isTakenByPackageSession;
      final isReserved = reserved.contains(t);
      return _SlotInfo(
        time: t,
        available: !isBlocked && !isReserved,
        isBlocked: isBlocked,
        bookedSessionLabel:
            isTakenByPackageSession ? 'Session $sessionIndex' : null,
      );
    }).toList();
  }

  Future<void> _submitReservation() async {
    if (!_allSessionsComplete) return;
    for (final session in _selectedSessions) {
      final parts = session.time!.split(':');
      final date = session.date!;
      final start = DateTime(date.year, date.month, date.day,
          int.parse(parts[0]), int.parse(parts[1]));
      if (!hasBookingLeadTime(start)) {
        _showError('Choose a session more than one hour from now.');
        return;
      }
    }
    setState(() => _submitting = true);

    try {
      final sessionsPayload = _selectedSessions
          .map((s) => {
                'reservedDate': _dateStr(s.date!),
                'reservedTime': '${s.time!}:00',
              })
          .toList();

      final firstSession = _selectedSessions.first;

      final bodyMap = <String, dynamic>{
        'coachID': widget.session.coachID,
        'reservedDate': _dateStr(firstSession.date!),
        'reservedTime': '${firstSession.time!}:00',
        'sessions': sessionsPayload,
        if (widget.clientID != null) 'clientID': widget.clientID,
        'location': _selectedLocation ?? 'defined',
      };
      if (_selectedPackage != null) {
        bodyMap['packageID'] = _selectedPackage!.id;
        if (_selectedPackage!.price != null && _selectedSessions.isNotEmpty) {
          bodyMap['price'] =
              (_selectedPackage!.price! / _selectedSessions.length);
        }
      } else {
        bodyMap['price'] = _coachPrice > 0 ? _coachPrice : widget.session.price;
      }
      final body = jsonEncode(bodyMap);

      final res = await http
          .post(Uri.parse('$baseUrl/reservations'),
              headers: _headers, body: body)
          .timeout(Duration(seconds: 12));

      if (!mounted) return;
      setState(() => _submitting = false);

      if (res.statusCode == 201 || res.statusCode == 200) {
        for (final s in _selectedSessions) {
          if (s.date != null && s.time != null) {
            final key = _dateStr(s.date!);
            _reservedSlots.putIfAbsent(key, () => []).add(s.time!);
          }
        }
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.onPrimary, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedSessions.length > 1
                      ? 'All ${_selectedSessions.length} sessions booked successfully!'
                      : 'Booking sent successfully!',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ]),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.all(16),
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
        SizedBox(width: 8),
        Expanded(
            child: Text(msg,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                    fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: _red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.all(16),
    ));
  }

  void _onConfirm() {
    final price = _selectedPackage?.price ??
        (_coachPrice > 0 ? _coachPrice : widget.session.price);
    showDialog(
      context: context,
      builder: (_) => _ConfirmationDialog(
        session: widget.session,
        date: _selectedDate,
        time: _selectedTime,
        sessions: _selectedSessions,
        rating: _coachRating,
        reviews: _totalReviews,
        location: _bookingLocation,
        price: price,
        selectedPackage: _selectedPackage,
        onConfirm: _submitReservation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If packages exist and the client hasn't chosen yet, show package selection first
    if (widget.packages.isNotEmpty && !_packageStepDone) {
      return _buildPackageSelectionStep();
    }
    return _buildBookingStep();
  }

  Widget _buildPackageSelectionStep() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(title: 'Choose a Package'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCoachCard(),
                  SizedBox(height: 24),
                  // Section title
                  Row(children: [
                    Container(
                        width: 3,
                        height: 16,
                        color: cs.primary,
                        margin: EdgeInsets.only(right: 10)),
                    Text('Select a Package',
                        style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                  ]),
                  SizedBox(height: 6),
                  Text(
                    'Choose the package that fits you best, or book without a package.',
                    style: TextStyle(
                        color: f.textMuted, fontSize: 12.5, height: 1.5),
                  ),
                  SizedBox(height: 16),
                  // Package options
                  ...widget.packages
                      .map((pkg) => _buildPackageOption(pkg, cs, f)),
                  SizedBox(height: 10),
                  // "No package" option
                  _buildNoPackageOption(cs, f),
                  SizedBox(height: 28),
                  // Continue button
                  GestureDetector(
                    onTap: () => setState(() => _packageStepDone = true),
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: cs.primary.withValues(alpha: 0.28),
                              blurRadius: 18,
                              offset: Offset(0, 6))
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_forward_rounded,
                                color: cs.onPrimary, size: 18),
                            SizedBox(width: 8),
                            Text('Continue to Booking',
                                style: TextStyle(
                                    color: cs.onPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildPackageOption(CoachPackage pkg, ColorScheme cs, FitlekColors f) {
    final isSelected = _selectedPackage?.id == pkg.id;
    return GestureDetector(
      onTap: () => _selectPackage(pkg),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary.withValues(alpha: 0.07) : f.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? cs.primary : f.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? cs.primary.withValues(alpha: 0.15) : f.card2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.workspace_premium_rounded,
                color: isSelected ? cs.primary : f.textMuted, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pkg.name,
                  style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800)),
              if (pkg.description != null && pkg.description!.isNotEmpty) ...[
                SizedBox(height: 4),
                Text(pkg.description!,
                    style: TextStyle(
                        color: f.textSecondary, fontSize: 12, height: 1.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
              SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                if (pkg.sessions != null)
                  _chipTag('${pkg.sessions} sessions',
                      Icons.calendar_today_rounded, cs, f),
                pkg.price != null
                    ? _chipTag('${pkg.price!.toInt()} MAD',
                        Icons.payments_rounded, cs, f,
                        colored: true)
                    : _chipTag('Price to discuss', Icons.chat_rounded, cs, f),
              ]),
            ]),
          ),
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? cs.primary : Colors.transparent,
              border: Border.all(
                  color: isSelected ? cs.primary : f.border, width: 2),
            ),
            child: isSelected
                ? Icon(Icons.check_rounded, color: cs.onPrimary, size: 13)
                : null,
          ),
        ]),
      ),
    );
  }

  Widget _buildNoPackageOption(ColorScheme cs, FitlekColors f) {
    final isSelected = _selectedPackage == null;
    return GestureDetector(
      onTap: () => _selectPackage(null),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary.withValues(alpha: 0.07) : f.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? cs.primary : f.border,
              width: isSelected ? 1.5 : 1),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? cs.primary.withValues(alpha: 0.15) : f.card2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.calendar_month_rounded,
                color: isSelected ? cs.primary : f.textMuted, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Book without a package',
                  style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              SizedBox(height: 3),
              Text('Single session — price discussed with coach',
                  style: TextStyle(color: f.textMuted, fontSize: 12)),
            ]),
          ),
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? cs.primary : Colors.transparent,
              border: Border.all(
                  color: isSelected ? cs.primary : f.border, width: 2),
            ),
            child: isSelected
                ? Icon(Icons.check_rounded, color: cs.onPrimary, size: 13)
                : null,
          ),
        ]),
      ),
    );
  }

  Widget _chipTag(String label, IconData icon, ColorScheme cs, FitlekColors f,
          {bool colored = false}) =>
      Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colored ? cs.primary.withValues(alpha: 0.1) : f.card2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: colored ? cs.primary.withValues(alpha: 0.3) : f.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 10, color: colored ? cs.primary : f.textMuted),
          SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: colored ? cs.primary : f.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _buildBookingStep() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          // Show selected package banner if any
          if (_selectedPackage != null || widget.packages.isNotEmpty)
            _buildSelectedPackageBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCoachCard(),
                  if (_selectedSessions.length > 1) ...[
                    SizedBox(height: 20),
                    _buildMultiSessionSelector(),
                  ],
                  SizedBox(height: 24),
                  _buildCalendar(),
                  SizedBox(height: 24),
                  _buildTimeSlots(),
                  SizedBox(height: 24),
                  _buildLocationSelector(),
                  SizedBox(height: 28),
                  _buildConfirmButton(),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildSelectedPackageBanner() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final pkg = _selectedPackage;
    return GestureDetector(
      onTap: () => setState(() => _packageStepDone = false),
      child: Container(
        margin: EdgeInsets.fromLTRB(20, 4, 20, 4),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: pkg != null ? cs.primary.withValues(alpha: 0.08) : f.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color:
                  pkg != null ? cs.primary.withValues(alpha: 0.3) : f.border),
        ),
        child: Row(children: [
          Icon(
              pkg != null
                  ? Icons.workspace_premium_rounded
                  : Icons.calendar_month_rounded,
              color: pkg != null ? cs.primary : f.textMuted,
              size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              pkg != null
                  ? '${pkg.name}${pkg.price != null ? ' · ${pkg.price!.toInt()} MAD' : ' · Price on request'}'
                  : 'No package selected',
              style: TextStyle(
                  color: pkg != null ? cs.primary : f.textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700),
            ),
          ),
          Icon(Icons.edit_rounded, color: f.textMuted, size: 14),
        ]),
      ),
    );
  }

  Widget _buildMultiSessionSelector() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final completedCount = _selectedSessions.where((s) => s.isComplete).length;
    final total = _selectedSessions.length;
    final double perSessionPrice = (_selectedPackage != null &&
            _selectedPackage!.price != null &&
            _selectedSessions.isNotEmpty)
        ? (_selectedPackage!.price! / _selectedSessions.length)
        : 0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.fitlek.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.event_repeat_rounded,
                        color: Theme.of(context).colorScheme.primary, size: 16),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Package Sessions',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: completedCount == total
                      ? cs.primary.withValues(alpha: 0.15)
                      : Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: completedCount == total
                        ? cs.primary.withValues(alpha: 0.4)
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '$completedCount of $total scheduled',
                  style: TextStyle(
                    color: completedCount == total
                        ? cs.primary
                        : Theme.of(context).colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            perSessionPrice > 0
                ? 'Select a date & time for each session (${perSessionPrice.toInt()} MAD / session):'
                : 'Select a date & time for each of the $total sessions included in your package:',
            style: TextStyle(color: f.textMuted, fontSize: 12, height: 1.4),
          ),
          SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_selectedSessions.length, (idx) {
                final s = _selectedSessions[idx];
                final isActive = idx == _activeSessionIndex;
                final isDone = s.isComplete;

                return GestureDetector(
                  onTap: () => _switchActiveSession(idx),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: 10),
                    width: 156,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.12)
                          : isDone
                              ? context.fitlek.card2
                              : f.card2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : isDone
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.35)
                                : f.border,
                        width: isActive ? 2 : 1,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                perSessionPrice > 0
                                    ? 'Session ${idx + 1} · ${perSessionPrice.toInt()} MAD'
                                    : 'Session ${idx + 1}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isActive
                                      ? Theme.of(context).colorScheme.onSurface
                                      : cs.onSurface,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            SizedBox(width: 4),
                            if (isDone)
                              Icon(Icons.check_circle_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 16)
                            else if (isActive)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 6),
                        if (isDone) ...[
                          Text(
                            _formattedShortDate(s.date!),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 12),
                              SizedBox(width: 4),
                              Text(
                                s.time!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            isActive ? 'Selecting now...' : 'Tap to select',
                            style: TextStyle(
                              color: isActive
                                  ? Theme.of(context).colorScheme.primary
                                  : f.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({String title = 'Book a session'}) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Row(children: [
          _iconBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(title,
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
      padding: EdgeInsets.all(16),
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
        SizedBox(width: 14),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.coachName,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3)),
            SizedBox(height: 4),
            Text(
                "${s.coachSpeciality.isNotEmpty ? s.coachSpeciality : 'Coach'} • ${s.location.isNotEmpty ? s.location : 'Anywhere'}",
                style:
                    TextStyle(color: context.fitlek.textMuted, fontSize: 12)),
            SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '⭐ ${rating > 0 ? rating.toStringAsFixed(1) : 'New'}',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w800),
                ),
                if (reviews > 0) ...[
                  SizedBox(width: 4),
                  Text('·',
                      style: TextStyle(
                          color: context.fitlek.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w900)),
                  SizedBox(width: 4),
                  Text('$reviews reviews',
                      style: TextStyle(
                          color: context.fitlek.textMuted, fontSize: 12)),
                ],
                if (price > 0) ...[
                  SizedBox(width: 6),
                  Text('·',
                      style: TextStyle(
                          color: context.fitlek.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w900)),
                  SizedBox(width: 6),
                  Text('${price.toInt()} MAD/session',
                      style: TextStyle(
                          color: context.fitlek.textMuted, fontSize: 12)),
                ],
              ],
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildCalendar() {
    final isMulti = _selectedSessions.length > 1;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
            width: 3,
            height: 16,
            color: Theme.of(context).colorScheme.primary,
            margin: EdgeInsets.only(right: 10)),
        Text(
            isMulti
                ? 'Session ${_activeSessionIndex + 1} Date · ${_monthLabel(_displayedMonth)}'
                : _monthLabel(_displayedMonth),
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
        Spacer(),
        _monthNavBtn(Icons.chevron_left_rounded, () {
          final prev =
              DateTime(_displayedMonth.year, _displayedMonth.month - 1);
          setState(() => _displayedMonth = prev);
          _fetchSlotsForMonth(prev);
        }),
        SizedBox(width: 8),
        _monthNavBtn(Icons.chevron_right_rounded, () {
          final next =
              DateTime(_displayedMonth.year, _displayedMonth.month + 1);
          setState(() => _displayedMonth = next);
          _fetchSlotsForMonth(next);
        }),
      ]),
      SizedBox(height: 14),
      Container(
        decoration: BoxDecoration(
          color: context.fitlek.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.fitlek.border),
        ),
        padding: EdgeInsets.all(14),
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
          SizedBox(height: 10),
          _buildDays(),
        ]),
      ),
    ]);
  }

  Widget _monthNavBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(8),
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
      cells.add(SizedBox());
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
      final isScheduledInPackage = _selectedSessions
          .any((s) => s.date != null && _dateStr(s.date!) == _dateStr(date));

      cells.add(GestureDetector(
        onTap: isPast
            ? null
            : () {
                setState(() {
                  _selectedDate = date;
                  _selectedSessions[_activeSessionIndex].date = date;
                  _selectedTime = _selectedSessions[_activeSessionIndex].time;
                  _slotAnimCtrl
                    ..reset()
                    ..forward();
                });
              },
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
            if (!isSelected && isScheduledInPackage)
              Positioned(
                bottom: 2,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            else if (hasDot && !isSelected)
              Positioned(
                bottom: 2,
                child: Container(
                  width: 3,
                  height: 3,
                  decoration:
                      BoxDecoration(color: _red, shape: BoxShape.circle),
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
      physics: NeverScrollableScrollPhysics(),
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
            margin: EdgeInsets.only(right: 10)),
        Text('Session location',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
      ]),
      SizedBox(height: 14),
      Container(
        decoration: BoxDecoration(
          color: context.fitlek.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.fitlek.border),
        ),
        padding: EdgeInsets.all(14),
        child: Column(children: [
          _locationOption(
            icon: Icons.home_rounded,
            label: 'My home',
            subtitle: 'Arrange your address with the coach in messages',
            value: 'home',
          ),
          SizedBox(height: 10),
          if (_gymName.isNotEmpty) ...[
            _locationOption(
                icon: Icons.fitness_center_rounded,
                label: _gymName,
                subtitle: _gymAddress.isNotEmpty
                    ? _gymAddress
                    : 'Coach’s gym · confirm directions in messages',
                value: 'gym'),
            SizedBox(height: 10),
          ],
          _locationOption(
            icon: Icons.help_outline_rounded,
            label: 'To be defined',
            subtitle: 'Agree on the meeting place with your coach in messages',
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
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(14),
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
            padding: EdgeInsets.all(8),
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
          SizedBox(width: 12),
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
              SizedBox(height: 2),
              Text(subtitle,
                  style:
                      TextStyle(color: context.fitlek.textMuted, fontSize: 11)),
            ]),
          ),
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
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
    final isMulti = _selectedSessions.length > 1;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
            width: 3,
            height: 16,
            color: Theme.of(context).colorScheme.primary,
            margin: EdgeInsets.only(right: 10)),
        Text(
            isMulti
                ? 'Session ${_activeSessionIndex + 1} Time slot'
                : 'Time slots',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
        Spacer(),
        if (!_loadingSlots)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      SizedBox(height: 6),
      Text(
          '${_formattedDate(_selectedDate)}${isMulti ? ' · for Session ${_activeSessionIndex + 1}' : ''}',
          style: TextStyle(color: context.fitlek.textMuted, fontSize: 12)),
      SizedBox(height: 14),
      if (_loadingSlots)
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
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
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.55,
            ),
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: slots.length,
            itemBuilder: (_, i) {
              final slot = slots[i];
              final isSelected = _selectedTime == slot.time;
              return GestureDetector(
                onTap: slot.available ? () => _onTimeSelected(slot.time) : null,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 150),
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
                                offset: Offset(0, 3))
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
                        SizedBox(height: 3),
                        Text(
                          isSelected
                              ? '✓ Selected'
                              : slot.bookedSessionLabel != null
                                  ? slot.bookedSessionLabel!
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
                                  : slot.bookedSessionLabel != null
                                      ? Theme.of(context).colorScheme.primary
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
      SizedBox(height: 12),
      Row(children: [
        _dot(Theme.of(context).colorScheme.primary),
        SizedBox(width: 5),
        Text('Free',
            style: TextStyle(color: context.fitlek.textMuted, fontSize: 10)),
        SizedBox(width: 16),
        _dot(_red.withValues(alpha: 0.7)),
        SizedBox(width: 5),
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
    final bool isMulti = _selectedSessions.length > 1;
    final int completedCount =
        _selectedSessions.where((s) => s.isComplete).length;
    final int totalCount = _selectedSessions.length;
    final bool allDone = _selectedSessions.isNotEmpty &&
        _selectedSessions.every((s) => s.isComplete);
    final bool valid = allDone && !_submitting;

    String btnText;
    if (isMulti) {
      if (allDone) {
        btnText = 'CONFIRM ALL $totalCount SESSIONS';
      } else {
        btnText = 'SELECT ALL SESSIONS ($completedCount/$totalCount CHOSEN)';
      }
    } else {
      btnText = valid ? 'CONFIRM · $_selectedTime' : 'CHOOSE A SLOT';
    }

    return GestureDetector(
      onTap: valid
          ? _onConfirm
          : () {
              if (isMulti && !allDone) {
                final firstIncomplete =
                    _selectedSessions.indexWhere((s) => !s.isComplete);
                if (firstIncomplete != -1) {
                  _switchActiveSession(firstIncomplete);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Please select a date & time for Session ${firstIncomplete + 1}'),
                      backgroundColor: Colors.orange.shade800,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 17),
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
                      offset: Offset(0, 6))
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
                SizedBox(width: 8),
                Text(
                  btnText,
                  style: TextStyle(
                      color: valid
                          ? Theme.of(context).colorScheme.onPrimary
                          : context.fitlek.textMuted,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.0),
                ),
              ]),
      ),
    );
  }

  Widget _iconBtn({required IconData icon, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(10),
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
  final String? bookedSessionLabel;
  const _SlotInfo({
    required this.time,
    required this.available,
    required this.isBlocked,
    this.bookedSessionLabel,
  });
}

class _ConfirmationDialog extends StatelessWidget {
  final ReservationModel session;
  final DateTime? date;
  final String? time;
  final List<ScheduledSession> sessions;
  final double rating;
  final int reviews;
  final String? location;
  final double price;
  final CoachPackage? selectedPackage;
  final VoidCallback onConfirm;

  const _ConfirmationDialog({
    required this.session,
    this.date,
    this.time,
    this.sessions = const [],
    required this.rating,
    required this.reviews,
    required this.location,
    required this.price,
    this.selectedPackage,
    required this.onConfirm,
  });

  String get _locationLabel {
    switch (location) {
      case 'home':
        return 'My home';
      case 'gym':
        return 'Your gym';
      default:
        return location ?? 'Location to be arranged with coach in messages';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSessions = sessions.isNotEmpty
        ? sessions
        : (date != null && time != null
            ? [ScheduledSession(date: date, time: time)]
            : <ScheduledSession>[]);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                  width: 3,
                  height: 18,
                  color: Theme.of(context).colorScheme.primary,
                  margin: EdgeInsets.only(right: 10)),
              Text('Confirm booking',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ]),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(14),
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
                      SizedBox(width: 12),
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
                              SizedBox(height: 2),
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
                                SizedBox(width: 5),
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
                    SizedBox(height: 14),
                    Divider(color: context.fitlek.border, height: 1),
                    SizedBox(height: 14),
                    if (activeSessions.length == 1 &&
                        activeSessions[0].date != null &&
                        activeSessions[0].time != null) ...[
                      _infoRow(context, Icons.calendar_today_rounded, 'Date',
                          _dateLabel(activeSessions[0].date!)),
                      SizedBox(height: 10),
                      _infoRow(context, Icons.access_time_rounded, 'Time',
                          '${activeSessions[0].time!} — ${_addHour(activeSessions[0].time!)}'),
                    ] else ...[
                      Text(
                        'Scheduled Sessions (${activeSessions.length})',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 180),
                        child: SingleChildScrollView(
                          child: Column(
                            children:
                                activeSessions.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final s = entry.value;
                              final double perSessionPrice =
                                  (activeSessions.isNotEmpty && price > 0)
                                      ? (price / activeSessions.length)
                                      : 0;
                              return Container(
                                margin: EdgeInsets.only(bottom: 8),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: context.fitlek.card2,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: context.fitlek.border),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text('Session ${idx + 1}',
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800)),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        s.isComplete
                                            ? '${_dateLabel(s.date!)} at ${s.time!}'
                                            : 'Not scheduled yet',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    if (perSessionPrice > 0) ...[
                                      SizedBox(width: 6),
                                      Text(
                                        '${perSessionPrice.toInt()} MAD',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 10),
                    _infoRow(context, Icons.location_on_rounded, 'Location',
                        _locationLabel),
                    if (selectedPackage != null) ...[
                      SizedBox(height: 10),
                      _infoRow(context, Icons.workspace_premium_rounded,
                          'Package', selectedPackage!.name,
                          valueColor: Theme.of(context).colorScheme.primary),
                    ],
                    if (price > 0) ...[
                      SizedBox(height: 10),
                      _infoRow(context, Icons.payments_rounded, 'Total Price',
                          '${price.toInt()} MAD${activeSessions.length > 1 ? ' (${(price / activeSessions.length).toInt()} MAD / session)' : ' / session'}',
                          valueColor: Theme.of(context).colorScheme.primary),
                    ],
                  ]),
            ),
            SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 13),
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
              SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onConfirm();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 13),
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
                            offset: Offset(0, 4))
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
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon,
                color: Theme.of(context).colorScheme.primary, size: 12),
          ),
          SizedBox(width: 8),
          Text(label,
              style: TextStyle(color: context.fitlek.textMuted, fontSize: 11)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 12),
            ),
          ),
        ],
      );

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
