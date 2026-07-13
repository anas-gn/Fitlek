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
  const CoachDashboard({super.key});

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
  List<Map<String, dynamic>> _recentActivity = [];

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
        _recentActivity = ((result['recentActivity'] as List?) ?? [])
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntro(cs, f),
                  const SizedBox(height: 22),
                  _buildStatsGrid(context, cs, f),
                  const SizedBox(height: 28),
                  _buildInvitations(context, cs, f),
                  const SizedBox(height: 28),
                  _buildActivitySection(cs, f),
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
          'An overview of your coaching activity',
          style: TextStyle(color: f.textSecondary, fontSize: 14, height: 1.4),
        ),
      ],
    );
  }

  // ─────────────────────────────── STATS ─────────────────────────────────

  Widget _buildStatsGrid(BuildContext context, ColorScheme cs, FitlekColors f) {
    final stats = <_StatData>[
      _StatData('Clients', _totalClients, Icons.groups_rounded, cs.primary),
      _StatData('Reservations', _totalReservations, Icons.event_note_rounded, f.info),
      _StatData('Confirmed', _confirmedReservations, Icons.check_circle_rounded, f.success),
      _StatData('Pending', _pendingReservations, Icons.hourglass_top_rounded, f.warning),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // 4 per row on wide screens, 2 per row on phones.
        final wide = constraints.maxWidth >= 640;
        final crossAxisCount = wide ? 4 : 2;
        final aspect = wide ? 1.15 : 1.5;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: aspect,
          children: stats.map((s) => _StatCard(data: s)).toList(),
        );
      },
    );
  }

  // ──────────────────────────── INVITATIONS ──────────────────────────────

  Widget _buildInvitations(BuildContext context, ColorScheme cs, FitlekColors f) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('INVITATIONS', cs),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _InvitationCard(
                label: 'Points earned',
                value: _invitationPoints,
                icon: Icons.star_rounded,
                color: f.violet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InvitationCard(
                label: 'Invitations',
                value: _totalInvitations,
                icon: Icons.group_add_rounded,
                color: cs.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ────────────────────────── RECENT ACTIVITY ────────────────────────────

  Widget _buildActivitySection(ColorScheme cs, FitlekColors f) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('RECENT ACTIVITY', cs),
        const SizedBox(height: 14),
        if (_recentActivity.isEmpty)
          _buildActivityEmpty(f)
        else
          ..._recentActivity.map((item) => _ActivityTile(item: item)),
      ],
    );
  }

  Widget _buildActivityEmpty(FitlekColors f) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: f.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: f.border),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, color: f.textMuted, size: 32),
          const SizedBox(height: 12),
          Text(
            'No recent activity yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: f.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'New reservations will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: f.textMuted, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, ColorScheme cs) {
    return Text(
      text,
      style: TextStyle(
        color: cs.primary,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
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

// ═══════════════════════════════ WIDGETS ═══════════════════════════════════

class _StatData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  _StatData(this.label, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: f.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: f.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(data.icon, color: data.color, size: 19),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${data.value}',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            data.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: f.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvitationCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _InvitationCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: f.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: f.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$value',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: f.textMuted, fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ActivityTile({required this.item});

  String get _firstName => (item['firstName'] ?? '').toString().trim();
  String get _lastName => (item['lastName'] ?? '').toString().trim();
  String get _fullName => '$_firstName $_lastName'.trim();

  String get _initials {
    final f = _firstName.isNotEmpty ? _firstName[0] : '';
    final l = _lastName.isNotEmpty ? _lastName[0] : '';
    final res = (f + l).toUpperCase();
    return res.isNotEmpty ? res : '?';
  }

  String _formatDate() {
    final raw = item['createdAt']?.toString();
    if (raw == null || raw.isEmpty) return '';
    final d = DateTime.tryParse(raw);
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final avatarUrl = (item['avatarUrl'] as String?)?.trim();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final date = _formatDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: f.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: f.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: f.card2,
              border: Border.all(color: cs.primary.withValues(alpha: 0.35), width: 1.4),
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
          const SizedBox(width: 12),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'New reservation',
                  style: TextStyle(color: f.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (date.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              date,
              style: TextStyle(color: f.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fallbackAvatar(ColorScheme cs) {
    return Center(
      child: Text(
        _initials,
        style: TextStyle(
          color: cs.primary,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
