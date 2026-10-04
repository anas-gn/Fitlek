import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fitlek1/constants/urls.dart';
import 'package:fitlek1/models/anas/coach.dart';
import 'package:fitlek1/models/anas/reservation.dart';
import 'clientCoachDetail.dart';
import '../../theme/fitlek_theme_extension.dart';
import '../../constants/app_colors.dart';

class ClientCoachFavoriteScreen extends StatefulWidget {
  final int clientID;
  final String token;

  const ClientCoachFavoriteScreen({
    super.key,
    required this.clientID,
    required this.token,
  });

  @override
  State<ClientCoachFavoriteScreen> createState() =>
      _ClientCoachFavoriteScreenState();
}

class _ClientCoachFavoriteScreenState extends State<ClientCoachFavoriteScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<CoachModel> _coaches = [];
  Map<int, double> _ratings = {};
  Map<int, int> _reviewCounts = {};
  final Set<int> _removing = {};
  bool _loading = true;
  String? _error;
  String _query = '';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      };

  List<CoachModel> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _coaches;
    return _coaches.where((c) {
      return c.fullName.toLowerCase().contains(q) ||
          (c.speciality ?? '').toLowerCase().contains(q) ||
          (c.ville ?? '').toLowerCase().contains(q) ||
          c.displaySpecialties.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
    _fetchFavorites();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchFavorites({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/favorites/coaches?clientID=${widget.clientID}'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _coaches = data
              .map((e) => CoachModel.fromJson(e as Map<String, dynamic>))
              .toList();
          _loading = false;
          _error = null;
        });
        _fetchRatings();
      } else {
        setState(() {
          _error = 'Server error (${res.statusCode})';
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Server unreachable';
        _loading = false;
      });
    }
  }

  Future<void> _fetchRatings() async {
    final ids = _coaches.map((c) => c.id).toSet();
    final results = await Future.wait(ids.map((id) async {
      try {
        final res = await http
            .get(Uri.parse('$baseUrl/reviews/coach/$id'), headers: _headers)
            .timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          return MapEntry(
            id,
            MapEntry(
              (data['avg'] as num?)?.toDouble() ?? 0.0,
              (data['total'] as num?)?.toInt() ?? 0,
            ),
          );
        }
      } catch (_) {}
      return MapEntry(id, const MapEntry(0.0, 0));
    }));
    if (!mounted) return;
    setState(() {
      for (final e in results) {
        _ratings[e.key] = e.value.key;
        _reviewCounts[e.key] = e.value.value;
      }
    });
  }

  Future<void> _removeFavorite(CoachModel coach) async {
    if (_removing.contains(coach.id)) return;
    _removing.add(coach.id);

    final index = _coaches.indexWhere((c) => c.id == coach.id);
    setState(() => _coaches.removeWhere((c) => c.id == coach.id));

    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/favorites/toggle'),
            headers: _headers,
            body: jsonEncode({
              'clientID': widget.clientID,
              'coachID': coach.id,
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) throw Exception('status ${res.statusCode}');

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['favorited'] == true) {
        await _fetchFavorites(silent: true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          if (!_coaches.any((c) => c.id == coach.id)) {
            _coaches.insert(
              index < 0 || index > _coaches.length ? 0 : index,
              coach,
            );
          }
        });
        _showSnack('Unable to update favorites', isError: true);
      }
    } finally {
      _removing.remove(coach.id);
    }
  }

  void _openCoach(CoachModel coach) {
    final session = ReservationModel(
      id: 0,
      clientID: widget.clientID,
      coachID: coach.id,
      coachName: coach.fullName,
      coachSpeciality: coach.speciality ?? '',
      coachImageUrl: coach.avatarUrl ?? '',
      coachRating: _ratings[coach.id] ?? coach.rating ?? 0.0,
      sessionStart: DateTime.now(),
      sessionEnd: DateTime.now().add(const Duration(hours: 1)),
      location: 'To be defined',
      status: 'pending',
      price: 0.0,
      companyName: 'Independent',
    );

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => CoachDetailScreen(
          session: session,
          token: widget.token,
          clientID: widget.clientID,
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ).then((_) => _fetchFavorites(silent: true));
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        msg,
        style: TextStyle(
          color: isError ? cs.onError : cs.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: isError ? context.fitlek.error : cs.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.cyprus.withValues(alpha: 0.16),
                    AppColors.cyprus.withValues(alpha: 0.05),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 0.18, 0.42],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                if (!_loading && _error == null && _coaches.isNotEmpty)
                  _buildSearchBar(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: f.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: f.border),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: cs.onSurface, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Favorites',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _loading
                      ? 'Loading…'
                      : _coaches.isEmpty
                          ? 'Coaches you like will appear here'
                          : '${_coaches.length} coach${_coaches.length == 1 ? '' : 'es'} saved',
                  style: TextStyle(
                    color: f.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.favorite_rounded,
                color: Colors.redAccent, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: f.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: f.border),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: f.textMuted, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(color: cs.onSurface, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search your favorite coaches...',
                  hintStyle: TextStyle(color: f.textSecondary, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_query.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                },
                child: Icon(Icons.close_rounded, color: f.textMuted, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildSkeleton();
    if (_error != null) return _buildError();
    if (_coaches.isEmpty) return _buildEmpty();

    final list = _filtered;
    if (list.isEmpty) return _buildNoResults();

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: context.fitlek.card,
      onRefresh: () => _fetchFavorites(silent: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        itemCount: list.length,
        itemBuilder: (_, i) => _FavoriteCoachTile(
          key: ValueKey(list[i].id),
          coach: list[i],
          rating: _ratings[list[i].id] ?? 0.0,
          reviewCount: _reviewCounts[list[i].id] ?? 0,
          onTap: () => _openCoach(list[i]),
          onRemove: () => _removeFavorite(list[i]),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    final f = context.fitlek;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 112,
        decoration: BoxDecoration(
          color: f.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: f.border),
        ),
      ),
    );
  }

  Widget _buildError() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, color: f.textMuted, size: 52),
            const SizedBox(height: 14),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: f.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _fetchFavorites,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return RefreshIndicator(
      color: cs.primary,
      backgroundColor: f.card,
      onRefresh: () => _fetchFavorites(silent: true),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: f.card2,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.favorite_border_rounded,
                          color: f.textMuted, size: 38),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'No favorite coaches yet',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap the heart on a coach to save them here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: f.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 22),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 26, vertical: 13),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Find a coach',
                          style: TextStyle(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, color: f.textMuted, size: 52),
          const SizedBox(height: 14),
          Text(
            'No coach matches your search',
            style: TextStyle(color: f.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              _searchCtrl.clear();
              setState(() => _query = '');
            },
            child: Text(
              'Reset',
              style: TextStyle(
                color: cs.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteCoachTile extends StatefulWidget {
  final CoachModel coach;
  final double rating;
  final int reviewCount;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteCoachTile({
    super.key,
    required this.coach,
    required this.rating,
    required this.reviewCount,
    required this.onTap,
    required this.onRemove,
  });

  @override
  State<_FavoriteCoachTile> createState() => _FavoriteCoachTileState();
}

class _FavoriteCoachTileState extends State<_FavoriteCoachTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final coach = widget.coach;
    final hasRating = widget.reviewCount > 0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: f.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: f.border),
            boxShadow: [
              BoxShadow(
                color: f.shadow,
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Stack(
                children: [
                  SizedBox(
                    width: 104,
                    height: 124,
                    child: coach.avatarUrl?.isNotEmpty == true
                        ? Image.network(
                            coach.avatarUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, p) =>
                                p == null ? child : Container(color: f.card2),
                            errorBuilder: (_, __, ___) => _placeholder(cs, f),
                          )
                        : _placeholder(cs, f),
                  ),
                  if (coach.isPremium)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: f.premium,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.workspace_premium_rounded,
                            color: Colors.black, size: 11),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              coach.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onRemove,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.favorite_rounded,
                                  color: Colors.redAccent, size: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        coach.displaySpecialties,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: f.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: hasRating
                                ? const Color(0xFFF59E0B)
                                : f.textMuted,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hasRating ? widget.rating.toStringAsFixed(1) : 'New',
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (hasRating)
                            Text(
                              ' (${widget.reviewCount})',
                              style: TextStyle(color: f.textMuted, fontSize: 11),
                            ),
                          const SizedBox(width: 12),
                          Icon(Icons.location_on_rounded,
                              color: f.textMuted, size: 12),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              coach.ville?.isNotEmpty == true
                                  ? coach.ville!
                                  : 'Anywhere',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: f.textMuted, fontSize: 11.5),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                              color: cs.primary.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          'VIEW PROFILE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme cs, FitlekColors f) => Container(
        color: f.card2,
        child: Center(
          child: Text(
            widget.coach.fullName.isNotEmpty
                ? widget.coach.fullName[0].toUpperCase()
                : '?',
            style: TextStyle(
              color: cs.primary,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
}