import '../../services/live_updates.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/apiService.dart';
import 'coachCalendar.dart';
import '../../services/notification_navigation.dart';
import '../../theme/fitlek_theme_extension.dart';

class CoachDashboard extends StatefulWidget {
  final VoidCallback? onViewCalendar;
  final VoidCallback? onViewNotifications;
  final VoidCallback? onViewInvitations;
  final String coachName;
  final Future<Map<String, dynamic>> Function(String)? load;

  const CoachDashboard({
    super.key,
    this.onViewCalendar,
    this.onViewNotifications,
    this.onViewInvitations,
    this.coachName = '',
    this.load,
  });

  @override
  State<CoachDashboard> createState() => _CoachDashboardState();
}

enum _DashState { loading, success, error }

class _CoachDashboardState extends State<CoachDashboard> with LiveUpdates<CoachDashboard> {
  @override
  Set<String> get liveDomains => {'calendar','reservations','notifications','messages','profile','edit','invitations','reviews','clients'};
  @override
  Future<void> refreshLiveData() async { await _loadData(silent:true); await _refreshVerification(); }

  Future<Map<String, dynamic>> _get(String path) =>
      (widget.load ?? ApiService.get)(path);
  bool? _isVerified;
  Timer? _verificationTimer;
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
  int _periodClients = 0;
  List<Map<String, dynamic>> _recentReservations = [];
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _recentClientInvitations = [];

  int _selectedFilterIndex = 0; // 0=Today, 1=This Week, 2=This Month

  String get _periodParam {
    if (_selectedFilterIndex == 0) return 'today';
    if (_selectedFilterIndex == 1) return 'week';
    return 'month';
  }

  String get _periodLabel {
    if (_selectedFilterIndex == 0) return 'today';
    if (_selectedFilterIndex == 1) return 'this week';
    return 'this month';
  }

  String _getTodaySubtitle() {
    final now = DateTime.now();
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
    return '${m[now.month - 1]} ${now.day}, ${now.year}';
  }

  String _getWeekSubtitle() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
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
    if (startOfWeek.month == endOfWeek.month) {
      return '${m[startOfWeek.month - 1]} ${startOfWeek.day} - ${endOfWeek.day}';
    } else {
      return '${m[startOfWeek.month - 1]} ${startOfWeek.day} - ${m[endOfWeek.month - 1]} ${endOfWeek.day}';
    }
  }

  String _getMonthSubtitle() {
    final now = DateTime.now();
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
    return '${m[now.month - 1]} ${now.year}';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _verificationTimer = Timer.periodic(
        const Duration(seconds: 30), (_) => _refreshVerification());
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshVerification() async {
    if (_isVerified == true) return;
    final result = await _get('/coaches/me/profile');
    if (!mounted || result['ok'] != true || result['isApproved'] == null)
      return;
    setState(() => _isVerified =
        result['isApproved'] == true || result['isApproved'].toString() == '1');
  }

  /// Safe numeric parsing: null aggregates become 0.
  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}') ?? 0;
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent && mounted && _state != _DashState.loading) {
      setState(() => _state = _DashState.loading);
    }
    final result = await _get('/coach/dashboard?period=$_periodParam');
    if (!mounted) return;

    if (result['ok'] == true) {
      setState(() {
        _isVerified = result['isVerified'] == true;
        _totalReservations = _asInt(result['totalReservations']);
        _pendingReservations = _asInt(result['pendingReservations']);
        _confirmedReservations = _asInt(result['confirmedReservations']);
        _totalClients = _asInt(result['totalClients']);
        _periodClients = _asInt(result['periodClients']);
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
        _recentClientInvitations =
            ((result['recentClientInvitations'] as List?) ?? [])
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
                  if (_isVerified == false) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: cs.primary.withValues(alpha: 0.25))),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.verified_outlined,
                                color: cs.primary, size: 26),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('Verification pending',
                                      style: TextStyle(
                                          color: cs.onSurface,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 5),
                                  Text(
                                      'We’re reviewing your profile for the Sirvya verified badge. Verification can take up to 48 hours. Your badge will appear once verification is complete.',
                                      style: TextStyle(
                                          color: f.textMuted,
                                          fontSize: 13,
                                          height: 1.5)),
                                ])),
                          ]),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _buildDateFilters(cs, f),
                  const SizedBox(height: 20),
                  _buildClientsOverviewCard(cs, f),
                  const SizedBox(height: 16),
                  _buildStatsGrid(cs, f),
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

  Widget _buildDateFilters(ColorScheme cs, FitlekColors f) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _dateFilterTab(
            cs,
            f,
            icon: Icons.calendar_today_rounded,
            title: 'Today',
            subtitle: _getTodaySubtitle(),
            isSelected: _selectedFilterIndex == 0,
            onTap: () {
              if (_selectedFilterIndex != 0) {
                setState(() => _selectedFilterIndex = 0);
                _loadData();
              }
            },
          ),
          const SizedBox(width: 12),
          _dateFilterTab(
            cs,
            f,
            icon: Icons.date_range_rounded,
            title: 'This Week',
            subtitle: _getWeekSubtitle(),
            isSelected: _selectedFilterIndex == 1,
            onTap: () {
              if (_selectedFilterIndex != 1) {
                setState(() => _selectedFilterIndex = 1);
                _loadData();
              }
            },
          ),
          const SizedBox(width: 12),
          _dateFilterTab(
            cs,
            f,
            icon: Icons.calendar_month_rounded,
            title: 'This Month',
            subtitle: _getMonthSubtitle(),
            isSelected: _selectedFilterIndex == 2,
            onTap: () {
              if (_selectedFilterIndex != 2) {
                setState(() => _selectedFilterIndex = 2);
                _loadData();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _dateFilterTab(
    ColorScheme cs,
    FitlekColors f, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary.withValues(alpha: 0.1) : f.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? cs.primary : f.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? cs.primary : f.textSecondary, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? cs.onSurface : f.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isSelected ? cs.primary : f.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            if (!isSelected) ...[
              const SizedBox(width: 16),
              Icon(Icons.chevron_right, color: f.textMuted, size: 16),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildIntro(ColorScheme cs, FitlekColors f) {
    final name =
        widget.coachName.isNotEmpty ? widget.coachName.toUpperCase() : 'COACH';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning,',
          style: TextStyle(color: cs.onSurface, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          '$name 👋',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Here\'s your coaching activity today.',
          style: TextStyle(color: f.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildClientsOverviewCard(ColorScheme cs, FitlekColors f) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: f.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: f.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: f.card2,
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.people_alt_rounded, color: cs.onSurface, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Clients',
                  style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$_totalClients',
                      style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          height: 1),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_upward_rounded,
                              color: cs.primary, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '100%',
                            style: TextStyle(
                                color: cs.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '+$_periodClients $_periodLabel',
                  style: TextStyle(color: f.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          _buildBarChart(cs, f),
        ],
      ),
    );
  }

  Widget _buildBarChart(ColorScheme cs, FitlekColors f) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final heights = [10.0, 20.0, 40.0, 10.0, 10.0, 10.0, 10.0];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (index) {
        final isToday = index == 2;
        return Padding(
          padding: const EdgeInsets.only(left: 6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: heights[index],
                decoration: BoxDecoration(
                  color:
                      isToday ? cs.primary : cs.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                days[index],
                style: TextStyle(
                  color: isToday ? cs.primary : f.textMuted,
                  fontSize: 9,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatsGrid(ColorScheme cs, FitlekColors f) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      children: [
        _statCard(
          cs,
          f,
          icon: Icons.calendar_today_rounded,
          iconColor: cs.primary,
          iconBg: cs.primary.withValues(alpha: 0.15),
          title: 'Reservations',
          value: '$_totalReservations',
          subtitle: '$_periodLabel',
          subtitleColor: cs.primary,
          subtitleIcon: Icons.arrow_upward_rounded,
        ),
        _statCard(
          cs,
          f,
          icon: Icons.check_circle_rounded,
          iconColor: f.success,
          iconBg: f.success.withValues(alpha: 0.15),
          title: 'Confirmed',
          value: '$_confirmedReservations',
          subtitle: '12.5% of total',
          subtitleColor: f.textSecondary,
        ),
        _statCard(
          cs,
          f,
          icon: Icons.access_time_rounded,
          iconColor: f.warning,
          iconBg: f.warning.withValues(alpha: 0.15),
          title: 'Pending',
          value: '$_pendingReservations',
          subtitle: '87.5% of total',
          subtitleColor: f.warning,
        ),
        _statCard(
          cs,
          f,
          icon: Icons.attach_money_rounded,
          iconColor: f.textSecondary,
          iconBg: f.textSecondary.withValues(alpha: 0.15),
          title: 'Total Earnings',
          value: '0 MAD',
          subtitle: '+0 this week',
          subtitleColor: f.textSecondary,
        ),
      ],
    );
  }

  Widget _statCard(
    ColorScheme cs,
    FitlekColors f, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String value,
    required String subtitle,
    required Color subtitleColor,
    IconData? subtitleIcon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: f.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: f.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
                color: cs.onSurface, fontSize: 24, fontWeight: FontWeight.w900),
          ),
          Row(
            children: [
              if (subtitleIcon != null) ...[
                Icon(subtitleIcon, color: subtitleColor, size: 12),
                const SizedBox(width: 4),
              ],
              Text(
                subtitle,
                style: TextStyle(color: subtitleColor, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCards(ColorScheme cs, FitlekColors f) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: f.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: f.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.star_rounded,
                            color: Colors.orange, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Invitation Points',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.chevron_right, color: f.textMuted, size: 16),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$_invitationPoints',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _tierProgress / 100,
                      minHeight: 6,
                      backgroundColor: f.border,
                      valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Tier $_currentTier',
                        style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$_tierProgress% to Tier $_nextTier • $_pointsRemaining points left',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: f.textMuted, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: f.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: f.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.share_rounded,
                            color: Colors.purpleAccent, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Invitations',
                          style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.chevron_right, color: f.textMuted, size: 16),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$_totalInvitations',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '+$_invitationsThisWeek this week',
                    style: TextStyle(color: f.textSecondary, fontSize: 11),
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
            icon: Icons.calendar_today_rounded, // Wait, calendar with an x?
            title: 'No upcoming reservations',
            subtitle: 'New reservations will appear here.',
            f: f,
            actionButton: OutlinedButton.icon(
              onPressed: () {}, // Can be wired up later
              icon: const Icon(Icons.calendar_month_rounded, size: 16),
              label: const Text('Set Your Availability'),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.onSurface,
                backgroundColor: cs.primary.withValues(alpha: 0.15),
                side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          )
        else
          ..._recentReservations.map(
            (item) => _ReservationTile(
              item: item,
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => CoachCalendar(reservationId: '${item['id']}'),
                ));
                if (mounted) _loadData();
              },
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
                      onTap: () async {
                        await ApiService.patch(
                            '/coach/notifications/${item['id']}/read', {});
                        if (!mounted) return;
                        await NotificationNavigation.open(context, item);
                        if (mounted) _loadData();
                      },
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
              style: TextStyle(
                  color: cs.primary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600),
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
    Widget? actionButton,
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
          if (actionButton != null) ...[
            const SizedBox(height: 16),
            actionButton,
          ],
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
              style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
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

class _ClientInvitationTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onTap;

  const _ClientInvitationTile({required this.item, this.onTap});

  String _timeAgo() {
    final date =
        DateTime.tryParse(item['clickedAt']?.toString() ?? '')?.toLocal();
    if (date == null) return '';
    final difference = DateTime.now().difference(date);
    if (difference.isNegative || difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final status = item['status']?.toString() ?? 'pending';
    final pending = status == 'pending';
    final accepted = status == 'accepted';
    final statusColor = pending
        ? f.warning
        : accepted
            ? f.success
            : f.error;
    final name = '${item['firstName'] ?? ''} ${item['lastName'] ?? ''}'.trim();
    final avatar = item['avatarUrl']?.toString();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: f.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: pending ? f.warning.withValues(alpha: 0.28) : f.border,
          ),
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
                child: avatar != null && avatar.isNotEmpty
                    ? Image.network(
                        avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.person_rounded, color: f.textMuted),
                      )
                    : Icon(Icons.person_rounded, color: f.textMuted),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Client' : name,
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
                    pending ? 'Wants to connect · ${_timeAgo()}' : _timeAgo(),
                    style: TextStyle(
                      color: f.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                pending
                    ? 'Pending'
                    : accepted
                        ? 'Accepted · +${item['pointsEarned'] ?? 20}'
                        : 'Declined',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Icon(Icons.chevron_right_rounded, color: f.textMuted, size: 18),
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
      'Dec',
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
                          decoration: BoxDecoration(
                              color: cs.primary, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: f.textSecondary, fontSize: 11.5, height: 1.35),
                    ),
                  ],
                  if (time.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(time,
                        style: TextStyle(color: f.textMuted, fontSize: 10.5)),
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
