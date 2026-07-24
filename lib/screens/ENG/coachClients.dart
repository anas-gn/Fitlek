import 'package:flutter/material.dart';
import '../../services/apiService.dart';
import 'coachInviteClients.dart';
import 'coachClientDetail.dart';

import '../../theme/fitlek_theme_extension.dart';

class CoachClients extends StatefulWidget {
  final VoidCallback? onInvitationAccepted;
  final VoidCallback? onInvitationsChanged;

  const CoachClients({
    super.key,
    this.onInvitationAccepted,
    this.onInvitationsChanged,
  });
  @override
  State<CoachClients> createState() => _CoachClientsState();
}

enum _ClientSort { az, za, newest }

class _CoachClientsState extends State<CoachClients> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filter = 'All';
  _ClientSort _sort = _ClientSort.az;
  bool _loading = true;
  bool _error = false;
  List<dynamic> _clients = [];
  List<dynamic> _invitations = [];
  final Set<String> _respondingInvitationIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    final results = await Future.wait([
      ApiService.get('/coach/clients'),
      ApiService.get('/coach/invitations'),
    ]);
    if (!mounted) return;
    final clientsResult = results[0];
    final invitationsResult = results[1];
    setState(() {
      // Keep clients visible even if the invitations call fails.
      if (clientsResult['ok'] == true) {
        _clients = List<dynamic>.from(clientsResult['data'] ?? const []);
        _invitations = invitationsResult['ok'] == true
            ? List<dynamic>.from(invitationsResult['data'] ?? const [])
            : <dynamic>[];
        _error = false;
      } else {
        _error = true;
      }
      _loading = false;
    });
  }

  bool _premiumOf(dynamic c) => c['isPremium'] == 1 || c['isPremium'] == true;

  bool get _isSearching => _query.trim().isNotEmpty;

  List<dynamic> get _filtered {
    final q = _query.trim().toLowerCase();
    final list = _clients.where((c) {
      final name = '${c['firstName'] ?? ''} ${c['lastName'] ?? ''}'.toLowerCase();
      final email = (c['email'] ?? '').toString().toLowerCase();
      final matchQuery = q.isEmpty || name.contains(q) || email.contains(q);
      final matchFilter = _filter == 'All' ||
          (_filter == 'Premium' && _premiumOf(c)) ||
          (_filter == 'Standard' && !_premiumOf(c));
      return matchQuery && matchFilter;
    }).toList();

    int byName(dynamic a, dynamic b) {
      final an = '${a['firstName'] ?? ''} ${a['lastName'] ?? ''}'.trim().toLowerCase();
      final bn = '${b['firstName'] ?? ''} ${b['lastName'] ?? ''}'.trim().toLowerCase();
      return an.compareTo(bn);
    }

    switch (_sort) {
      case _ClientSort.az:
        list.sort(byName);
        break;
      case _ClientSort.za:
        list.sort((a, b) => byName(b, a));
        break;
      case _ClientSort.newest:
        list.sort((a, b) {
          final ad = DateTime.tryParse((a['linkedAt'] ?? '').toString());
          final bd = DateTime.tryParse((b['linkedAt'] ?? '').toString());
          if (ad == null && bd == null) return byName(a, b);
          if (ad == null) return 1;
          if (bd == null) return -1;
          return bd.compareTo(ad);
        });
        break;
    }
    return list;
  }

  int get _premiumCount => _clients.where(_premiumOf).length;
  // Only pending invitations are actionable. Accepted invitations become
  // connected clients and declined ones are dismissed, so neither should
  // linger in the invitations section.
  List<dynamic> get _pendingInvitations =>
      _invitations.where((i) => i['status'] == 'pending').toList();
  int get _pendingInvitationCount => _pendingInvitations.length;

  Future<void> _respondToInvitation(dynamic invitation, bool accept) async {
    final id = invitation['id']?.toString();
    if (id == null || _respondingInvitationIds.contains(id)) return;

    setState(() => _respondingInvitationIds.add(id));
    final action = accept ? 'accept' : 'refuse';
    final result = await ApiService.patch(
      '/coach/invitations/$id/$action',
      {},
    );
    if (!mounted) return;

    setState(() => _respondingInvitationIds.remove(id));
    if (result['ok'] == true) {
      if (accept) widget.onInvitationAccepted?.call();
      widget.onInvitationsChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? 'Invitation accepted: +20 points. The client is now available in Chats.'
                : 'Invitation declined.',
          ),
        ),
      );
      await _load();
    } else {
      ApiService.showError(
        context,
        result['message']?.toString() ?? 'Unable to update invitation.',
      );
    }
  }

  Future<void> _openDetail(dynamic c) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CoachClientDetail(
          clientId: c['id'].toString(),
          initialName: '${c['firstName'] ?? ''} ${c['lastName'] ?? ''}'.trim(),
          initialAvatar: c['avatarUrl']?.toString(),
          initialPremium: _premiumOf(c),
        ),
      ),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(children: [
            _buildTopBar(),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: cs.primary))
                  : _error
                      ? _buildError()
                      : RefreshIndicator(
                          color: cs.primary,
                          backgroundColor: f.card,
                          onRefresh: _load,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                            children: [
                              if (_pendingInvitations.isNotEmpty) ...[
                                _buildInvitationsSection(),
                                const SizedBox(height: 20),
                              ],
                              Text(
                                'CONNECTED CLIENTS',
                                style: TextStyle(
                                  color: f.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (_clients.isEmpty)
                                _buildClientsEmptyCard()
                              else if (_filtered.isEmpty)
                                _buildNoResults()
                              else
                                ..._filtered.map(_buildClientCard),
                            ],
                          ),
                        ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final count = _clients.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('My Clients',
                  style: TextStyle(color: cs.onSurface, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 2),
              Text(
                _loading
                    ? 'Loading…'
                    : count == 0
                        ? 'Clients connected to you will appear here'
                        : '$count client${count == 1 ? '' : 's'} connected to you',
                style: TextStyle(color: f.textMuted, fontSize: 12.5),
              ),
            ]),
          ),
          _buildSortButton(),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CoachInviteClients())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.person_add_rounded, color: cs.onPrimary, size: 16),
                const SizedBox(width: 6),
                Text('Invite', style: TextStyle(color: cs.onPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _statBox('${_clients.length}', 'Total', cs.onSurface)),
          const SizedBox(width: 10),
          Expanded(
              child: _statBox(
                  '$_pendingInvitationCount', 'Pending', f.warning)),
          const SizedBox(width: 10),
          Expanded(child: _statBox('$_premiumCount', 'Premium', cs.primary)),
        ]),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(color: f.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: f.border)),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            style: TextStyle(color: cs.onSurface, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search clients...',
              hintStyle: TextStyle(color: f.textMuted, fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: f.textMuted, size: 20),
              suffixIcon: _isSearching
                  ? GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                      child: Icon(Icons.close_rounded, color: f.textMuted, size: 18),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: ['All', 'Premium', 'Standard'].map((filter) {
            final sel = _filter == filter;
            return GestureDetector(
              onTap: () => setState(() => _filter = filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: sel ? cs.primary : f.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? cs.primary : f.border),
                ),
                child: Text(filter,
                    style: TextStyle(
                        color: sel ? cs.onPrimary : f.textSecondary,
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  Widget _buildSortButton() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return PopupMenuButton<_ClientSort>(
      tooltip: 'Sort',
      color: f.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (v) => setState(() => _sort = v),
      itemBuilder: (ctx) => [
        _sortItem(_ClientSort.az, 'Name A–Z'),
        _sortItem(_ClientSort.za, 'Name Z–A'),
        _sortItem(_ClientSort.newest, 'Newest connected'),
      ],
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(color: f.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: f.border)),
        child: Icon(Icons.sort_rounded, color: cs.onSurface, size: 20),
      ),
    );
  }

  PopupMenuItem<_ClientSort> _sortItem(_ClientSort value, String label) {
    final cs = Theme.of(context).colorScheme;
    final selected = _sort == value;
    return PopupMenuItem<_ClientSort>(
      value: value,
      child: Row(children: [
        Icon(selected ? Icons.check_rounded : Icons.sort_rounded,
            size: 18, color: selected ? cs.primary : context.fitlek.textMuted),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(color: cs.onSurface, fontSize: 13.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      ]),
    );
  }

  Widget _statBox(String value, String label, Color color) {
    final f = context.fitlek;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: f.card, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: f.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildInvitationsSection() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'CLIENT INVITATIONS',
              style: TextStyle(
                color: f.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            if (_pendingInvitationCount > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: f.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_pendingInvitationCount pending',
                  style: TextStyle(
                    color: f.warning,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ..._pendingInvitations.map((invitation) {
          final id = invitation['id']?.toString() ?? '';
          final status = invitation['status']?.toString() ?? 'pending';
          final isPending = status == 'pending';
          final isAccepted = status == 'accepted';
          final isResponding = _respondingInvitationIds.contains(id);
          final avatar = invitation['avatarUrl']?.toString();
          final name =
              '${invitation['firstName'] ?? ''} ${invitation['lastName'] ?? ''}'
                  .trim();
          final statusColor = isPending
              ? f.warning
              : isAccepted
                  ? f.success
                  : f.error;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: f.card,
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: statusColor.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: f.border),
                      ),
                      child: ClipOval(
                        child: avatar != null && avatar.isNotEmpty
                            ? Image.network(
                                avatar,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.person_rounded,
                                  color: f.textMuted,
                                ),
                              )
                            : Icon(Icons.person_rounded, color: f.textMuted),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            invitation['email']?.toString() ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(color: f.textMuted, fontSize: 11.5),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatInvitationDate(invitation['clickedAt']),
                            style:
                                TextStyle(color: f.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isPending
                            ? 'Pending'
                            : isAccepted
                                ? 'Accepted · +${invitation['pointsEarned'] ?? 20} pts'
                                : 'Declined',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isPending) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isResponding
                              ? null
                              : () =>
                                  _respondToInvitation(invitation, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: f.error,
                            side: BorderSide(
                                color: f.error.withValues(alpha: 0.35)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11)),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isResponding
                              ? null
                              : () => _respondToInvitation(invitation, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11)),
                          ),
                          child: isResponding
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: cs.onPrimary,
                                  ),
                                )
                              : const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  String _formatInvitationDate(dynamic raw) {
    final date = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildClientsEmptyCard() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: BoxDecoration(
        color: f.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: f.border),
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline_rounded, color: f.textMuted, size: 44),
          const SizedBox(height: 10),
          Text(
            'No connected clients yet',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Accept a pending invitation to add the client.',
            textAlign: TextAlign.center,
            style: TextStyle(color: f.textMuted, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(dynamic c) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final isPremium = _premiumOf(c);
    final avatar = c['avatarUrl']?.toString();
    return GestureDetector(
      onTap: () => _openDetail(c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: f.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isPremium ? cs.primary.withValues(alpha: 0.15) : f.border),
        ),
        child: Row(children: [
          Stack(children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isPremium ? cs.primary.withValues(alpha: 0.5) : f.border, width: 1.5),
              ),
              child: ClipOval(
                child: (avatar != null && avatar.isNotEmpty)
                    ? Image.network(avatar, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.person, color: f.textMuted, size: 24))
                    : Icon(Icons.person, color: f.textMuted, size: 24),
              ),
            ),
            if (isPremium)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                  child: Icon(Icons.star_rounded, color: cs.onPrimary, size: 11),
                ),
              ),
          ]),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${c['firstName'] ?? ''} ${c['lastName'] ?? ''}'.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text((c['email'] ?? '').toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: f.textMuted, fontSize: 12)),
            ]),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: f.textMuted, size: 20),
        ]),
      ),
    );
  }

  Widget _buildError() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.wifi_off_rounded, color: f.textMuted, size: 52),
        const SizedBox(height: 12),
        Text('Unable to load clients', style: TextStyle(color: f.textMuted, fontSize: 15)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _load,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
            decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(14)),
            child: Text('Retry', style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ),
      ]),
    );
  }

  Widget _buildNoResults() {
    final f = context.fitlek;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off_rounded, color: f.textMuted, size: 52),
          const SizedBox(height: 12),
          Text(_isSearching ? 'No clients match your search.' : 'No clients match this filter.',
              textAlign: TextAlign.center, style: TextStyle(color: cs.onSurface, fontSize: 14.5, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
