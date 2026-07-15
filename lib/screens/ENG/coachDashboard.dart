import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/apiService.dart';
import '../../theme/fitlek_theme_extension.dart';

/// Coach Dashboard — fully dynamic, backend-driven overview.
///
/// Data flow: UI → ApiService → authenticated `/coach/dashboard`
/// (requireAuth + requireRole('coach'), coachID = req.user.id) → MySQL.
///
/// No fake statistics, no hardcoded business data, no Quick Actions.
/// The shared Coach Header owns the logo / avatar / name / notification, so
/// none of those are repeated here.
class CoachDashboard extends StatefulWidget {
  final VoidCallback? onViewCalendar;
  final VoidCallback? onViewNotifications;

  const CoachDashboard({
    super.key,
    this.onViewCalendar,
    this.onViewNotifications,
  });

  @override
  State<CoachDashboard> createState() => _CoachDashboardState();
}

enum _DashState { loading, success, error }

class _CoachDashboardState extends State<CoachDashboard> {
  _DashState _state = _DashState.loading;

  int _totalReservations = 0;
  int _pendingReservations = 0;
  int _confirmedReservations = 0;
  int _totalClients = 0;
  int _invitationPoints = 0;
  int _totalInvitations = 0;
  int _invitationsThisWeek = 0;
  int _currentTier = 1;
  int _nextTier = 2;
  int _tierProgress = 0;
  int _pointsRemaining = 0;
  List<Map<String, dynamic>> _recentReservations = [];
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Safe numeric parsing: null aggregates become 0.
  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}') ?? 0;
  }

  Future<void> _loadData() async {
    if (mounted && _state != _DashState.loading) {
      setState(() => _state = _DashState.loading);
    }
    final result = await ApiService.get('/coach/dashboard');
    if (!mounted) return;

    if (result['ok'] == true) {
      setState(() {
        _totalReservations = _asInt(result['totalReservations']);
        _pendingReservations = _asInt(result['pendingReservations']);
        _confirmedReservations = _asInt(result['confirmedReservations']);
        _totalClients = _asInt(result['totalClients']);
        _invitationPoints = _asInt(result['invitationPoints']);
        _totalInvitations = _asInt(result['totalInvitations']);
        _invitationsThisWeek = _asInt(result['invitationsThisWeek']);
        final tier = result['pointsTier'] is Map
            ? Map<String, dynamic>.from(result['pointsTier'] as Map)
            : <String, dynamic>{};
        _currentTier = _asInt(tier['current']).clamp(1, 999);
        _nextTier = _asInt(tier['next']).clamp(2, 1000);
        _tierProgress = _asInt(tier['progress']).clamp(0, 100);
        _pointsRemaining = _asInt(tier['pointsRemaining']);
        _recentReservations = ((result['recentReservations'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _notifications = ((result['notifications'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _state = _DashState.success;
      });
    } else {
      setState(() => _state = _DashState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_state == _DashState.loading) return _buildShimmer(context);
    if (_state == _DashState.error) return _buildError(context);
    return _buildContent(context);
  }

  // ─────────────────────────────── SUCCESS ───────────────────────────────

  Widget _buildContent(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;

    return RefreshIndicator(
      color: cs.primary,
      backgroundColor: f.card,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntro(cs, f),
                  const SizedBox(height: 18),
                  _buildClientsOverview(cs, f),
                  const SizedBox(height: 16),
                  _buildRewardCards(cs, f),
                  const SizedBox(height: 22),
                  _buildRecentReservations(cs, f),
                  const SizedBox(height: 22),
                  _buildNotifications(cs, f),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntro(ColorScheme cs, FitlekColors f) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your coaching activity at a glance',
          style: TextStyle(color: f.textSecondary, fontSize: 14, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildClientsOverview(ColorScheme cs, FitlekColors f) {
    final onPrimary = cs.onPrimary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Clients',
                      style: TextStyle(
                        color: onPrimary.withValues(alpha: 0.68),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$_totalClients',
                      style: TextStyle(
                        color: onPrimary,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.trending_up_rounded,
                color: onPrimary.withValues(alpha: 0.62),
                size: 26,
              ),
            ],
          ),
          const SizedBox(height: 38),
          Divider(color: onPrimary.withValues(alpha: 0.13), height: 1),
          const SizedBox(height: 15),
          Row(
            children: [
              _heroStat('Reservations', _totalReservations, onPrimary),
              _heroStat('Confirmed', _confirmedReservations, onPrimary),
              _heroStat('Pending', _pendingReservations, onPrimary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, int value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color.withValues(alpha: 0.58),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCards(ColorScheme cs, FitlekColors f) {
    // Do NOT use CrossAxisAlignment.stretch here: this Row lives inside a
    // scrollable Column (unbounded height) and stretch causes a layout crash
    // that leaves the whole dashboard blank on web.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: f.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: f.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.stars_rounded, color: cs.primary, size: 16),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Invitation Points',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Text(
                    '$_invitationPoints',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _tierProgress / 100,
                      minHeight: 5,
                      backgroundColor: f.border,
                      valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Tier $_currentTier · $_tierProgress% to Tier $_nextTier · $_pointsRemaining points left',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: f.textMuted, fontSize: 10.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: f.card2,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: f.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Invitations',
                    style: TextStyle(color: cs.onSurface, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_totalInvitations',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '+$_invitationsThisWeek this week',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: f.textSecondary, fontSize: 10.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReservations(ColorScheme cs, FitlekColors f) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Recent Reservations',
          action: widget.onViewCalendar == null ? null : 'View all',
          onAction: widget.onViewCalendar,
          cs: cs,
        ),
        const SizedBox(height: 12),
        if (_recentReservations.isEmpty)
          _emptyCard(
            icon: Icons.event_busy_rounded,
            title: 'No upcoming reservations',
            subtitle: 'New reservations will appear here.',
            f: f,
          )
        else
          ..._recentReservations.map(
            (item) => _ReservationTile(
              item: item,
              onTap: widget.onViewCalendar,
            ),
          ),
      ],
    );
  }

  Widget _buildNotifications(ColorScheme cs, FitlekColors f) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Notifications',
          action: widget.onViewNotifications == null ? null : 'View all',
          onAction: widget.onViewNotifications,
          cs: cs,
        ),
        const SizedBox(height: 12),
        if (_notifications.isEmpty)
          _emptyCard(
            icon: Icons.notifications_none_rounded,
            title: 'No notifications',
            subtitle: 'You are all caught up.',
            f: f,
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: f.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: f.border),
            ),
            child: Column(
              children: _notifications
                  .map(
                    (item) => _NotificationTile(
                      item: item,
                      onTap: widget.onViewNotifications,
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _sectionHeader(
    String title, {
    String? action,
    VoidCallback? onAction,
    required ColorScheme cs,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action,
              style: TextStyle(color: cs.primary, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required FitlekColors f,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: f.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: f.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: f.textMuted, size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: f.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  // ─────────────────────────────── LOADING ───────────────────────────────

  Widget _buildShimmer(BuildContext context) {
    final f = context.fitlek;
    Widget block(double h, {double w = double.infinity, double r = 16}) =>
        Shimmer.fromColors(
          baseColor: f.card,
          highlightColor: f.border,
          child: Container(
            height: h,
            width: w,
            decoration: BoxDecoration(
              color: f.card,
              borderRadius: BorderRadius.circular(r),
            ),
          ),
        );

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                block(30, w: 220, r: 8),
                const SizedBox(height: 10),
                block(16, w: 260, r: 6),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: block(96)),
                  const SizedBox(width: 12),
                  Expanded(child: block(96)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: block(96)),
                  const SizedBox(width: 12),
                  Expanded(child: block(96)),
                ]),
                const SizedBox(height: 28),
                block(14, w: 120, r: 4),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: block(84)),
                  const SizedBox(width: 12),
                  Expanded(child: block(84)),
                ]),
                const SizedBox(height: 28),
                block(14, w: 150, r: 4),
                const SizedBox(height: 14),
                block(68),
                const SizedBox(height: 10),
                block(68),
                const SizedBox(height: 10),
                block(68),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────── ERROR ─────────────────────────────────

  Widget _buildError(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: f.card2, shape: BoxShape.circle),
              child: Icon(Icons.wifi_off_rounded, color: f.textMuted, size: 32),
            ),
            const SizedBox(height: 18),
            Text(
              'Couldn\'t load the dashboard',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface, fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: f.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _loadData,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: cs.onPrimary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Retry',
                      style: TextStyle(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReservationTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onTap;

  const _ReservationTile({required this.item, this.onTap});

  String get _firstName => (item['firstName'] ?? '').toString().trim();
  String get _lastName => (item['lastName'] ?? '').toString().trim();
  String get _fullName => '$_firstName $_lastName'.trim();

  String get _initials {
    final f = _firstName.isNotEmpty ? _firstName[0] : '';
    final l = _lastName.isNotEmpty ? _lastName[0] : '';
    final res = (f + l).toUpperCase();
    return res.isNotEmpty ? res : '?';
  }

  DateTime? _dateTime() {
    final dateRaw = item['reservedDate']?.toString();
    final timeRaw = item['reservedTime']?.toString();
    if (dateRaw == null || dateRaw.isEmpty) return null;
    final datePart = dateRaw.length >= 10 ? dateRaw.substring(0, 10) : dateRaw;
    final timePart = (timeRaw == null || timeRaw.isEmpty)
        ? '00:00:00'
        : (timeRaw.length >= 8 ? timeRaw.substring(0, 8) : timeRaw);
    return DateTime.tryParse('${datePart}T$timePart');
  }

  String _dateLabel() {
    final date = _dateTime();
    if (date == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final difference = day.difference(today).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _timeLabel() {
    final date = _dateTime();
    if (date == null) return '';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final avatarUrl = (item['avatarUrl'] as String?)?.trim();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final status = (item['status'] ?? '').toString().toLowerCase();
    final confirmed = status == 'confirmed';
    final statusColor = confirmed ? cs.primary : f.warning;
    final statusLabel = status.isEmpty
        ? 'Unknown'
        : '${status[0].toUpperCase()}${status.substring(1)}';
    final date = _dateLabel();
    final time = _timeLabel();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: f.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: f.border),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: f.card2,
                border: Border.all(color: f.border),
              ),
              child: ClipOval(
                child: hasAvatar
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallbackAvatar(cs),
                      )
                    : _fallbackAvatar(cs),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fullName.isNotEmpty ? _fullName : 'Client',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [date, time].where((value) => value.isNotEmpty).join(' · '),
                    style: TextStyle(color: f.textSecondary, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: confirmed ? 0.16 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackAvatar(ColorScheme cs) {
    return Center(
      child: Text(
        _initials,
        style: TextStyle(
          color: cs.primary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onTap;

  const _NotificationTile({required this.item, this.onTap});

  ({IconData icon, Color color}) _typeStyle(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    switch (item['type']?.toString()) {
      case 'new_message':
        return (icon: Icons.chat_bubble_outline_rounded, color: cs.primary);
      case 'new_reservation':
        return (icon: Icons.event_available_rounded, color: f.info);
      case 'upcoming_session':
        return (icon: Icons.notifications_active_outlined, color: f.warning);
      case 'new_client':
        return (icon: Icons.groups_rounded, color: f.success);
      case 'point_achievement':
        return (icon: Icons.workspace_premium_outlined, color: f.violet);
      default:
        return (icon: Icons.notifications_none_rounded, color: f.textMuted);
    }
  }

  String _timeAgo() {
    final raw = item['createdAt']?.toString();
    if (raw == null || raw.isEmpty) return '';
    final date = DateTime.tryParse(raw);
    if (date == null) return '';
    final difference = DateTime.now().difference(date);
    if (difference.isNegative || difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} mins ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final style = _typeStyle(context);
    final isUnread = item['isRead'] == false || item['isRead'] == 0;
    final title = item['title']?.toString().trim() ?? '';
    final body = item['body']?.toString().trim() ?? '';
    final time = _timeAgo();

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: style.color.withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              child: Icon(style.icon, color: style.color, size: 18),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title.isNotEmpty ? title : 'Notification',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: f.textSecondary, fontSize: 11.5, height: 1.35),
                    ),
                  ],
                  if (time.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(time, style: TextStyle(color: f.textMuted, fontSize: 10.5)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
