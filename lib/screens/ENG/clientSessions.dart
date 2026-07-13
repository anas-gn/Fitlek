import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:fitlek1/models/anas/reservation.dart';
import 'clientSessionDetail.dart';

import '../../theme/fitlek_theme_extension.dart';
import '../../components/sirvya_logo.dart';

const _baseUrl = 'http://localhost:3000/api';

class SessionsScreen extends StatefulWidget {
  final String token;
  final int clientID;

  const SessionsScreen({
    super.key,
    required this.clientID,
    required this.token,
  });

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<ReservationModel> _sessions = [];
  bool _loading = true;
  String? _error;

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

  Future<void> _fetchSessions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse('$_baseUrl/reservations').replace(
        queryParameters: {
          'role': 'client',
          'userID': widget.clientID.toString(),
          'limit': '100',
        },
      );

      final res = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final sessions = data.map((j) => ReservationModel.fromJson(j)).toList();

        sessions.sort((a, b) {
          if (a.isUpcoming && !b.isUpcoming) return -1;
          if (!a.isUpcoming && b.isUpcoming) return 1;
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

  List<ReservationModel> get _upcoming =>
      _sessions.where((s) => s.isUpcoming).toList();

  List<ReservationModel> get _past =>
      _sessions.where((s) => !s.isUpcoming).toList();

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
                const SizedBox(height: 4),
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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SirvyaLogo(variant: SirvyaLogoVariant.wordmark, height: 28),
          const SizedBox(width: 10),
          Text('My sessions',
              style: TextStyle(
                  color: context.fitlek.textMuted,
                  fontSize: 13,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          if (!_loading && _error == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.25)),
              ),
              child: Row(children: [
                Icon(Icons.bolt_rounded,
                    color: Theme.of(context).colorScheme.primary, size: 14),
                const SizedBox(width: 6),
                Text('$_completedCount completed',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          if (!_loading) ...[
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: context.fitlek.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.fitlek.border),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8)),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: context.fitlek.textMuted,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          tabs: [
            Tab(
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.upcoming_rounded, size: 13),
                const SizedBox(width: 6),
                Text('UPCOMING (${_upcoming.length})'),
              ]),
            ),
            Tab(
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.history_rounded, size: 13),
                const SizedBox(width: 6),
                Text('PAST (${_past.length})'),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 130,
          decoration: BoxDecoration(
            color: context.fitlek.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.fitlek.border),
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wifi_off_rounded,
              color: context.fitlek.textMuted, size: 52),
          const SizedBox(height: 16),
          Text(_error!,
              style: TextStyle(color: context.fitlek.textMuted, fontSize: 13)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _fetchSessions,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color:
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
              ),
              child: Text('Retry',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
          ),
        ]),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildSessionList(_upcoming, emptyMsg: 'No upcoming sessions.'),
        _buildSessionList(_past, emptyMsg: 'No past sessions.'),
      ],
    );
  }

  Widget _buildSessionList(List<ReservationModel> sessions,
      {required String emptyMsg}) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.calendar_month_outlined,
              color: context.fitlek.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(emptyMsg,
              style: TextStyle(color: context.fitlek.textMuted, fontSize: 14)),
          const SizedBox(height: 6),
          Text('Pull down to refresh',
              style: TextStyle(color: context.fitlek.textMuted, fontSize: 11)),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchSessions,
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: context.fitlek.card,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        itemCount: sessions.length,
        itemBuilder: (_, i) => _SessionCard(
          session: sessions[i],
          token: widget.token,
          clientID: widget.clientID,
          onUpdated: (updated) => setState(() {
            final idx = _sessions.indexWhere((s) => s.id == updated.id);
            if (idx != -1) _sessions[idx] = updated;
          }),
          onCancelled: (id) => setState(() {
            _sessions.removeWhere((s) => s.id == id);
          }),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final ReservationModel session;
  final String token;
  final int clientID;
  final void Function(ReservationModel updated) onUpdated;
  final void Function(int id) onCancelled;

  const _SessionCard({
    required this.session,
    required this.token,
    required this.clientID,
    required this.onUpdated,
    required this.onCancelled,
  });

  Color _statusColor(BuildContext context) {
    switch (session.status) {
      case 'confirmed':
        return context.fitlek.success;
      case 'pending':
        return Theme.of(context).colorScheme.primary;
      case 'cancelled':
        return context.fitlek.error;
      default:
        return context.fitlek.textMuted;
    }
  }

  String get _statusLabel {
    switch (session.status) {
      case 'pending':
        return 'PENDING';
      case 'confirmed':
        return 'CONFIRMED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return '';
    }
  }

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
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]}';
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
                fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to cancel this booking?',
            style: TextStyle(color: ctx.fitlek.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('NO', style: TextStyle(color: ctx.fitlek.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('YES, CANCEL',
                style: TextStyle(
                    color: ctx.fitlek.error, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await http
          .patch(
            Uri.parse('$_baseUrl/reservations/${session.id}/cancel'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'cancelledBy': 'coach',
              'cancellationReason': 'Cancelled by client'
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        onCancelled(session.id);
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text('Booking cancelled',
                  style: TextStyle(
                      color: Theme.of(ctx).colorScheme.onSurface,
                      fontWeight: FontWeight.w600)),
              backgroundColor: ctx.fitlek.card,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bool hasReview = session.reviewRating != null;
    final bool needsReview = session.needsReview;
    final bool canCancel =
        session.isPending && session.sessionStart.isAfter(DateTime.now());
    final statusColor = _statusColor(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.fitlek.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.fitlek.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
          highlightColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.03),
          onTap: () {
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
                transitionDuration: const Duration(milliseconds: 300),
              ),
            ).then((updated) {
              if (updated != null) {
                onUpdated(updated as ReservationModel);
              }
            });
          },
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.5), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: context.fitlek.card2,
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
                                fontWeight: FontWeight.w900),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.coachName,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                letterSpacing: -0.3)),
                        const SizedBox(height: 2),
                        Text(session.coachSpeciality,
                            style: TextStyle(
                                color: context.fitlek.textMuted, fontSize: 12)),
                      ]),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                  ),
                  child: Text(_statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5)),
                ),
              ]),
            ),
            Divider(height: 1, color: context.fitlek.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(children: [
                _meta(Icons.calendar_today_rounded,
                    _formatDate(session.sessionStart)),
                const SizedBox(width: 12),
                _meta(Icons.access_time_rounded,
                    '${_formatTime(session.sessionStart)} — ${_formatTime(session.sessionEnd)}'),
                const Spacer(),
                if (hasReview)
                  Row(
                      children: List.generate(
                          5,
                          (i) => Icon(
                                i < session.reviewRating!
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 13,
                              )))
                else if (needsReview)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.3)),
                    ),
                    child: Text('RATE',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2)),
                  )
                else if (session.price > 0)
                  Text('${session.price.toInt()} MAD',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
              ]),
            ),
            if (canCancel) ...[
              Divider(height: 1, color: context.fitlek.border),
              GestureDetector(
                onTap: () => _cancel(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cancel_outlined,
                            color: context.fitlek.error, size: 13),
                        const SizedBox(width: 6),
                        Text('Cancel booking',
                            style: TextStyle(
                                color: context.fitlek.error,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5)),
                      ]),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Builder(
      builder: (context) => Row(children: [
            Icon(icon, color: context.fitlek.textMuted, size: 11),
            const SizedBox(width: 4),
            Text(text,
                style: TextStyle(
                    color: context.fitlek.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ]));
}
