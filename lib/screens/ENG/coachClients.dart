import 'package:flutter/material.dart';
import '../../services/apiService.dart';
import 'coachInviteClients.dart';
import 'coachClientDetail.dart';

import '../../theme/fitlek_theme_extension.dart';

class CoachClients extends StatefulWidget {
  const CoachClients({super.key});
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
    final result = await ApiService.get('/coach/clients');
    if (!mounted) return;
    setState(() {
      if (result['ok'] == true) {
        _clients = result['data'] ?? [];
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
                      : _clients.isEmpty
                          ? _buildEmpty()
                          : _filtered.isEmpty
                              ? _buildNoResults()
                              : RefreshIndicator(
                                  color: cs.primary,
                                  backgroundColor: f.card,
                                  onRefresh: _load,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                                    itemCount: _filtered.length,
                                    itemBuilder: (_, i) => _buildClientCard(_filtered[i]),
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
          Expanded(child: _statBox('$_premiumCount', 'Premium', cs.primary)),
          const SizedBox(width: 10),
          Expanded(child: _statBox('${_clients.length - _premiumCount}', 'Standard', f.textSecondary)),
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

  Widget _buildEmpty() {
    final f = context.fitlek;
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.people_outline_rounded, color: f.textMuted, size: 60),
                const SizedBox(height: 14),
                Text('No clients yet.',
                    style: TextStyle(color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Clients connected to you will appear here.',
                    textAlign: TextAlign.center, style: TextStyle(color: f.textMuted, fontSize: 13)),
                const SizedBox(height: 22),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CoachInviteClients())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.person_add_rounded, color: cs.primary, size: 17),
                      const SizedBox(width: 8),
                      Text('Invite clients', style: TextStyle(color: cs.primary, fontSize: 13.5, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
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
