import '../../services/live_updates.dart';
import '../../theme/fitlek_theme_extension.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fitlek1/models/anas/reservation.dart';
import 'clientSessionDetail.dart';
import 'clientConversation.dart';
import 'clientCoachDetail.dart';
import 'package:fitlek1/constants/urls.dart';
import '../../components/sirvya_logo.dart';

class SessionsScreen extends StatefulWidget {
  final String token;
  final int clientID;
  final bool embedded;
  final http.Client? httpClient;

  const SessionsScreen({
    super.key,
    this.embedded = false,
    required this.clientID,
    required this.token,
    this.httpClient,
  });

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen>
    with SingleTickerProviderStateMixin, LiveUpdates<SessionsScreen> {
  @override
  Set<String> get liveDomains =>
      {'calendar', 'reservations', 'notifications', 'reviews'};
  @override
  Future<void> refreshLiveData() async {
    await _fetchSessions(silent: true);
  }

  late TabController _tabController;

  List<ReservationModel> _sessions = [];
  bool _loading = true;
  String? _error;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchSessions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchSessions({bool silent = false}) async {
    if (!silent)
      setState(() {
        _loading = true;
        _error = null;
      });
    try {
      final uri = Uri.parse('$baseUrl/reservations').replace(
        queryParameters: {
          'role': 'client',
          'userID': widget.clientID.toString(),
          'limit': '100',
        },
      );

      final res = await (widget.httpClient?.get ?? http.get)(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      ).timeout(Duration(seconds: 10));

      if (!mounted) return;

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final sessions = data.map((j) => ReservationModel.fromJson(j)).toList();

        sessions.sort((a, b) {
          final aUpcoming = _isTrulyUpcoming(a);
          final bUpcoming = _isTrulyUpcoming(b);
          if (aUpcoming && !bUpcoming) return -1;
          if (!aUpcoming && bUpcoming) return 1;
          return b.sessionStart.compareTo(a.sessionStart);
        });

        setState(() {
          _sessions = sessions;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Server error (${res.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unable to reach the server.';
          _loading = false;
        });
      }
    }
  }

  // Une session n'est "à venir" que si son statut le permet ET que
  // sa date/heure n'est pas encore passée.
  bool _isTrulyUpcoming(ReservationModel s) =>
      s.isUpcoming && s.sessionStart.isAfter(DateTime.now());

  List<ReservationModel> get _upcoming =>
      _sessions.where(_isTrulyUpcoming).toList();

  List<ReservationModel> get _past {
    final list = _sessions.where((s) => !_isTrulyUpcoming(s)).toList();
    if (_selectedFilter == 'Completed') {
      return list.where((s) => s.status == 'confirmed').toList();
    } else if (_selectedFilter == 'Cancelled') {
      return list
          .where((s) =>
              s.status == 'cancelled' ||
              s.isExpired ||
              (s.status == 'pending' &&
                  s.sessionStart.isBefore(DateTime.now())))
          .toList();
    }
    return list;
  }

  int get _completedCount => _sessions
      .where((s) => s.isConfirmed && s.sessionStart.isBefore(DateTime.now()))
      .length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 4),
                _buildTabBar(),
                Expanded(child: _buildBody()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!widget.embedded)
                SirvyaLogo(variant: SirvyaLogoVariant.wordmark, height: 20),
              Spacer(),
              if (!_loading && _error == null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.fitlek.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.fitlek.border),
                  ),
                  child: Row(children: [
                    Icon(Icons.bolt_rounded,
                        color: Theme.of(context).colorScheme.primary, size: 14),
                    SizedBox(width: 6),
                    Text('$_completedCount completed',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
            ],
          ),
          SizedBox(height: 24),
          Text('My sessions',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5)),
          SizedBox(height: 4),
          Text('Manage your coaching appointments.',
              style:
                  TextStyle(color: context.fitlek.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: context.fitlek.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.fitlek.border),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(10)),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: context.fitlek.textSecondary,
          labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle:
              TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: [
            Tab(
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.calendar_today_rounded, size: 16),
                SizedBox(width: 8),
                Flexible(
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Upcoming (${_upcoming.length})'))),
              ]),
            ),
            Tab(
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.history_rounded, size: 18),
                SizedBox(width: 8),
                Flexible(
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Past (${_past.length})'))),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
          child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wifi_off_rounded,
              color: context.fitlek.textSecondary, size: 52),
          SizedBox(height: 16),
          Text(_error!,
              style:
                  TextStyle(color: context.fitlek.textSecondary, fontSize: 15)),
        ]),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildSessionList(_upcoming,
            emptyMsg: 'No upcoming sessions.', isPast: false),
        _buildSessionList(_past, emptyMsg: 'No past sessions.', isPast: true),
      ],
    );
  }

  Widget _buildSessionList(List<ReservationModel> sessions,
      {required String emptyMsg, required bool isPast}) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.calendar_month_outlined,
              color: context.fitlek.textSecondary, size: 48),
          SizedBox(height: 12),
          Text(emptyMsg,
              style:
                  TextStyle(color: context.fitlek.textSecondary, fontSize: 16)),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchSessions,
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 40),
        children: [
          if (isPast) _buildFiltersRow(),
          if (isPast) SizedBox(height: 16),
          if (isPast)
            ..._buildGroupedPastSessions(sessions)
          else
            ...sessions.map((s) => _SessionCard(
                  session: s,
                  token: widget.token,
                  clientID: widget.clientID,
                  isPast: isPast,
                  onUpdated: (updated) => setState(() {
                    final idx = _sessions.indexWhere((s) => s.id == updated.id);
                    if (idx != -1) _sessions[idx] = updated;
                  }),
                  onCancelled: (id) => setState(() {
                    _sessions.removeWhere((s) => s.id == id);
                  }),
                )),
          if (!isPast) SizedBox(height: 16),
          if (!isPast)
            Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Theme.of(context).colorScheme.primary, size: 20),
                SizedBox(width: 8),
                Expanded(
                    child: Text(
                        'Your session is confirmed once the coach accepts.',
                        style: TextStyle(
                            color: context.fitlek.textSecondary,
                            fontSize: 13))),
              ],
            ),
          if (!isPast) SizedBox(height: 24),
          if (!isPast)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.fitlek.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.fitlek.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: context.fitlek.card, shape: BoxShape.circle),
                    child: Icon(Icons.support_agent_rounded,
                        color: Theme.of(context).colorScheme.primary, size: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Need help with a booking?',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text('Get in touch and we\'ll be happy to help.',
                            style: TextStyle(
                                color: context.fitlek.textSecondary,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  Text('Contact support',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  Icon(Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.primary, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedPastSessions(List<ReservationModel> sessions) {
    if (sessions.isEmpty) return [];

    final Map<String, List<ReservationModel>> grouped = {};
    const monthsFull = [
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

    for (var s in sessions) {
      final key =
          '${monthsFull[s.sessionStart.month - 1]} ${s.sessionStart.year}';
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(s);
    }

    final List<Widget> widgets = [];
    for (var entry in grouped.entries) {
      widgets.add(Padding(
        padding: EdgeInsets.only(bottom: 12, top: 4),
        child: Text(entry.key,
            style: TextStyle(
                color: context.fitlek.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
      ));
      widgets.addAll(entry.value.map((s) => _SessionCard(
            session: s,
            token: widget.token,
            clientID: widget.clientID,
            isPast: true,
            onUpdated: (updated) => setState(() {
              final idx = _sessions.indexWhere((x) => x.id == updated.id);
              if (idx != -1) _sessions[idx] = updated;
            }),
            onCancelled: (id) => setState(() {
              _sessions.removeWhere((x) => x.id == id);
            }),
          )));
    }
    return widgets;
  }

  Widget _buildFiltersRow() {
    return Row(
      children: [
        _buildFilterChip('All'),
        SizedBox(width: 8),
        _buildFilterChip('Completed'),
        SizedBox(width: 8),
        _buildFilterChip('Cancelled'),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.fitlek.card : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : context.fitlek.border),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : context.fitlek.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final ReservationModel session;
  final String token;
  final int clientID;
  final bool isPast;
  final void Function(ReservationModel updated) onUpdated;
  final void Function(int id) onCancelled;

  const _SessionCard({
    required this.session,
    required this.token,
    required this.clientID,
    required this.isPast,
    required this.onUpdated,
    required this.onCancelled,
  });

  bool get _isExpiredPending =>
      session.isExpired ||
      (session.isPending && session.sessionStart.isBefore(DateTime.now()));
  String get _effectiveStatus =>
      _isExpiredPending ? 'cancelled' : session.status;

  String _formatDate(DateTime dt) {
    const months = [
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
    const monthsFull = [
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
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const daysFull = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    if (isPast) {
      return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]}';
    } else {
      return '${daysFull[dt.weekday - 1]}, ${dt.day} ${monthsFull[dt.month - 1]}';
    }
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Future<void> _cancel(BuildContext ctx) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: ctx.fitlek.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel session',
            style: TextStyle(
                color: Theme.of(ctx).colorScheme.onSurface,
                fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to cancel this booking?',
            style: TextStyle(color: ctx.fitlek.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('NO',
                  style: TextStyle(color: ctx.fitlek.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('YES, CANCEL',
                  style: TextStyle(
                      color: ctx.fitlek.error, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/reservations/${session.id}/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'cancelledBy': 'client',
          'cancellationReason': 'Cancelled by client'
        }),
      );

      if (res.statusCode == 200) {
        onCancelled(session.id);
      }
    } catch (_) {}
  }

  void _viewDetails(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => SessionDetailScreen(
          session: session,
          clientID: clientID,
          token: token,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: Duration(milliseconds: 300),
      ),
    ).then((updated) {
      if (updated != null) {
        onUpdated(updated as ReservationModel);
      }
    });
  }

  Future<void> _startConversation(BuildContext context) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/conversations/find-or-create'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'clientID': clientID,
              'coachID': session.coachID,
            }),
          )
          .timeout(Duration(seconds: 8));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        final convID = data['conversationID'] ?? data['id'];
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClientConversationScreen(
                conversationID: convID,
                clientID: clientID,
                token: token,
                coachName: session.coachName,
                coachAvatar: session.coachImageUrl,
                coachSpeciality: session.coachSpeciality,
              ),
            ),
          );
        }
      }
    } catch (_) {}
  }

  void _bookAgain(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CoachDetailScreen(
          session: session,
          clientID: clientID,
          token: token,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canCancel = session.isPending &&
        !_isExpiredPending &&
        session.sessionStart.isAfter(DateTime.now());

    Color statusBorder, statusText;
    String statusLabel;

    switch (_effectiveStatus) {
      case 'confirmed':
        statusBorder = context.fitlek.success;
        statusText = context.fitlek.success;
        statusLabel = 'Completed'; // Assuming past confirmed is completed
        break;
      case 'pending':
        statusBorder = context.fitlek.warning;
        statusText = context.fitlek.warning;
        statusLabel = 'Pending';
        break;
      case 'cancelled':
      default:
        statusBorder = context.fitlek.error;
        statusText = context.fitlek.error;
        statusLabel = session.isExpired
            ? 'Expired'
            : session.pricingStatus == 'declined'
                ? 'Price declined'
                : 'Cancelled';
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.fitlek.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.fitlek.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
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
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold))
                      : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(session.coachName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text(session.coachSpeciality,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: context.fitlek.textSecondary,
                              fontSize: 14)),
                      if (session.packageName != null &&
                          session.packageName!.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.workspace_premium_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 13),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                session.packageName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (!isPast && session.isPending) ...[
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded,
                                color: context.fitlek.textSecondary, size: 14),
                            SizedBox(width: 4),
                            Expanded(
                                child: Text(
                                    session.pricingStatus == 'proposed'
                                        ? 'Price offer ready — open details to approve.'
                                        : session.pricingStatus == 'awaiting'
                                            ? 'Awaiting coach’s price.'
                                            : 'Awaiting coach confirmation.',
                                    style: TextStyle(
                                        color: context.fitlek.textSecondary,
                                        fontSize: 12))),
                          ],
                        ),
                      ],
                      if (isPast && _effectiveStatus == 'cancelled') ...[
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: context.fitlek.textSecondary, size: 14),
                            SizedBox(width: 4),
                            Expanded(
                                child: Text('Cancelled by you',
                                    style: TextStyle(
                                        color: context.fitlek.textSecondary,
                                        fontSize: 12))),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusBorder),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          color: statusText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          if (isPast)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        color: context.fitlek.textSecondary, size: 16),
                    SizedBox(width: 6),
                    Text(_formatDate(session.sessionStart),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 13)),
                    SizedBox(width: 12),
                    Container(
                        width: 1, height: 12, color: context.fitlek.border),
                    SizedBox(width: 12),
                    Icon(Icons.access_time_rounded,
                        color: context.fitlek.textSecondary, size: 16),
                    SizedBox(width: 6),
                    Text(
                        '${_formatTime(session.sessionStart)} – ${_formatTime(session.sessionEnd)}',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 13)),
                    SizedBox(width: 12),
                    Container(
                        width: 1, height: 12, color: context.fitlek.border),
                    SizedBox(width: 12),
                    Text('${session.price.toInt()} MAD',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )
          else ...[
            Divider(color: context.fitlek.border, height: 1),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          color: context.fitlek.textSecondary, size: 18),
                      SizedBox(width: 12),
                      Expanded(
                          child: Text(_formatDate(session.sessionStart),
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontSize: 15))),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.access_time_rounded,
                          color: context.fitlek.textSecondary, size: 18),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${_formatTime(session.sessionStart)} – ${_formatTime(session.sessionEnd)}',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontSize: 15)),
                          SizedBox(height: 2),
                          Text('${session.durationMin} min',
                              style: TextStyle(
                                  color: context.fitlek.textSecondary,
                                  fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: context.fitlek.textSecondary, size: 18),
                      SizedBox(width: 12),
                      Expanded(
                          child: Text(
                              session.location.isNotEmpty
                                  ? session.location
                                  : 'Location to be confirmed',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontSize: 15))),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        session.packageName != null &&
                                session.packageName!.isNotEmpty
                            ? 'Session price (${session.packageName})'
                            : 'Session total',
                        style: TextStyle(
                            color: context.fitlek.textSecondary, fontSize: 14),
                      ),
                      Text('${session.price.toInt()} MAD',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 0, 16, isPast && _effectiveStatus == 'cancelled' ? 16 : 16),
            child: Row(
              children: [
                if (isPast && _effectiveStatus == 'cancelled') Spacer(),
                if (isPast && _effectiveStatus == 'cancelled')
                  Text('View details >',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                if (!(isPast && _effectiveStatus == 'cancelled')) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (isPast) {
                          _bookAgain(context);
                        } else {
                          _viewDetails(context);
                        }
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isPast)
                                Icon(Icons.calendar_today_rounded,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    size: 18),
                              if (isPast) SizedBox(width: 8),
                              Text(isPast ? 'Book again >' : 'View details >',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (isPast && session.reviewRating == null) {
                          _viewDetails(
                              context); // Go to session detail to leave a review
                        } else if (!isPast) {
                          _startConversation(context);
                        }
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Theme.of(context).colorScheme.primary)),
                        alignment: Alignment.center,
                        child: session.reviewRating != null
                            ? FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                        'Your review: ${session.reviewRating}.0 ',
                                        style: TextStyle(
                                            color: context.fitlek.textSecondary,
                                            fontSize: 12)),
                                    Row(
                                        children: List.generate(
                                            5,
                                            (i) => Icon(
                                                i < session.reviewRating!
                                                    ? Icons.star_rounded
                                                    : Icons.star_border_rounded,
                                                color: Colors.amber,
                                                size: 14))),
                                  ],
                                ),
                              )
                            : FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                        isPast
                                            ? Icons.star_border_rounded
                                            : Icons.chat_bubble_outline_rounded,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        size: 18),
                                    SizedBox(width: 8),
                                    Text(isPast ? 'Leave a review' : 'Message',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isPast && canCancel) ...[
            Divider(color: context.fitlek.border, height: 1),
            GestureDetector(
              onTap: () => _cancel(context),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cancel_outlined,
                        color: context.fitlek.error, size: 18),
                    SizedBox(width: 8),
                    Text('Cancel booking',
                        style: TextStyle(
                            color: context.fitlek.error,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
