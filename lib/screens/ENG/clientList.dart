import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:fitlek1/models/anas/coach.dart';
import 'package:fitlek1/models/anas/reservation.dart';
import 'clientCoachDetail.dart';
import 'clientCompanyDetail.dart';
import 'package:fitlek1/constants/urls.dart';
import '../../theme/fitlek_theme_extension.dart';
import '../../constants/app_colors.dart';
import 'clientQrScanner.dart';
String resolveImageUrl(String? url) {
  if (url == null || url.trim().isEmpty) return '';
  final u = url.trim();
  if (u.startsWith('http://') || u.startsWith('https://')) return u;
  final root = baseUrl.replaceAll(RegExp(r'/api/?$'), '');
  return u.startsWith('/') ? '$root$u' : '$root/$u';
}

Widget networkAvatar(String? url, {required Widget placeholder, BoxFit fit = BoxFit.cover}) {
  final resolved = resolveImageUrl(url);
  if (resolved.isEmpty) return placeholder;
  return Image.network(
    resolved,
    fit: fit,
    loadingBuilder: (context, child, progress) {
      if (progress == null) return child;
      return Container(
        color: Colors.black12,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
            ),
          ),
        ),
      );
    },
    errorBuilder: (_, __, ___) => placeholder,
  );
}
class _AdvisorItem {
  final int id;
  final String firstName, lastName, email;
  final String? avatarUrl;
  final String specialty;
  final String? ville;

  const _AdvisorItem({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.avatarUrl,
    required this.specialty,
    this.ville,
  });

  String get fullName => '$firstName $lastName';

  factory _AdvisorItem.fromJson(Map<String, dynamic> j) => _AdvisorItem(
        id: j['id'] as int,
        firstName: j['firstName'] ?? '',
        lastName: j['lastName'] ?? '',
        email: j['email'] ?? '',
        avatarUrl: j['avatarUrl'],
        specialty: j['specialty'] ?? j['speciality'] ?? '',
        ville: j['ville'],
      );
}

class _CategoryItem {
  final int? id;
  final String name;
  final IconData icon;

  const _CategoryItem({this.id, required this.name, required this.icon});
}

class DiscoverScreen extends StatefulWidget {
  final int clientID;
  final String? token;
  final int initialTabIndex;
  final ValueNotifier<int>? tabRequest;

  const DiscoverScreen({
    super.key,
    required this.clientID,
    this.token,
    this.initialTabIndex = 0,
    this.tabRequest,
  });

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<CoachModel> _coaches = [];
  List<_AdvisorItem> _advisors = [];
  bool _coachesLoading = true;
  bool _advisorsLoading = true;
  String? _coachesError;
  String? _advisorsError;

  final _searchCtrl = TextEditingController();
  String _query = '';
  String _sortBy = 'points';
  String? _selectedCity;
  bool _showFilters = false;
  String? _clientVille;
  int? _selectedCategoryId;
  double? _selectedMinRating;
  Set<int> _favoriteCoachIds = {};
  Map<int, double> _coachAvgRatings = {};
  Map<int, int> _coachReviewCounts = {};

  final List<_CategoryItem> _categories = const [
    _CategoryItem(id: 1, name: 'Musculation', icon: Icons.fitness_center_rounded),
    _CategoryItem(id: 2, name: 'Fitness', icon: Icons.directions_run_rounded),
    _CategoryItem(id: 3, name: 'Yoga', icon: Icons.self_improvement_rounded),
    _CategoryItem(id: 4, name: 'CrossFit', icon: Icons.sports_gymnastics_rounded),
    _CategoryItem(id: 5, name: 'Nutrition', icon: Icons.apple),
    _CategoryItem(id: 6, name: 'Boxe', icon: Icons.sports_martial_arts_rounded),
  ];

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
      };
Future<void> _scanCoachQrCode() async {
  final scanned = await Navigator.push<String>(
    context,
    MaterialPageRoute(builder: (_) => const ClientQrScannerScreen()),
  );
  if (scanned == null || scanned.isEmpty) return;

  final normalized = scanned.trim().toLowerCase();
  final matches = _coaches.where(
    (c) => c.invitationCode.trim().toLowerCase() == normalized,
  );

  if (matches.isEmpty) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No coach found for this code'),
          backgroundColor: context.fitlek.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
    return;
  }

  final coach = matches.first;

  final session = ReservationModel(
    id: 0,
    clientID: widget.clientID,
    coachID: coach.id,
    coachName: coach.fullName,
    coachSpeciality: coach.speciality ?? '',
    coachImageUrl: coach.avatarUrl ?? '',
    coachRating: coach.rating ?? 0.0,
    sessionStart: DateTime.now(),
    sessionEnd: DateTime.now().add(const Duration(hours: 1)),
    location: 'To be defined',
    status: 'pending',
    price: 0.0,
    companyName: 'Independent',
  );

  if (!mounted) return;
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => CoachDetailScreen(
        session: session,
        token: widget.token ?? '',
        clientID: widget.clientID,
      ),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 350),
    ),
  );
}
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(() => setState(() {}));
    _searchCtrl.addListener(
        () => setState(() => _query = _searchCtrl.text.toLowerCase()));
    widget.tabRequest?.addListener(_onTabRequest);
    _fetchCoaches();
    _fetchAdvisors();
    _fetchClientVille();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/favorites?clientID=${widget.clientID}'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (mounted) {
          setState(() => _favoriteCoachIds = data.map((e) => e as int).toSet());
        }
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorite(int coachId) async {
    setState(() {
      if (_favoriteCoachIds.contains(coachId)) {
        _favoriteCoachIds.remove(coachId);
      } else {
        _favoriteCoachIds.add(coachId);
      }
    });
    try {
      await http
          .post(
            Uri.parse('$baseUrl/favorites/toggle'),
            headers: _headers,
            body: jsonEncode({'clientID': widget.clientID, 'coachID': coachId}),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_favoriteCoachIds.contains(coachId)) {
          _favoriteCoachIds.remove(coachId);
        } else {
          _favoriteCoachIds.add(coachId);
        }
      });
    }
  }

  Future<void> _fetchCoachRatings() async {
    final ids = _coaches.map((c) => c.id).toSet();
    final results = await Future.wait(ids.map((id) async {
      try {
        final res = await http
            .get(
              Uri.parse('$baseUrl/reviews/coach/$id'),
              headers: _headers,
            )
            .timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final avg = (data['avg'] as num?)?.toDouble() ?? 0.0;
          final total = (data['total'] as num?)?.toInt() ?? 0;
          return MapEntry(id, MapEntry(avg, total));
        }
      } catch (_) {}
      return MapEntry(id, const MapEntry(0.0, 0));
    }));

    if (!mounted) return;
    setState(() {
      for (final entry in results) {
        _coachAvgRatings[entry.key] = entry.value.key;
        _coachReviewCounts[entry.key] = entry.value.value;
      }
    });
  }

  void _onTabRequest() {
    if (!mounted || widget.tabRequest == null) return;
    _tabController.animateTo(widget.tabRequest!.value);
  }

  Future<void> _fetchClientVille() async {
    if (widget.token == null) return;
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/clients/me?userID=${widget.clientID}'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (mounted) {
          setState(() => _clientVille = data['ville'] as String?);
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    widget.tabRequest?.removeListener(_onTabRequest);
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCoaches() async {
    setState(() {
      _coachesLoading = true;
      _coachesError = null;
    });
    try {
      String url = '$baseUrl/coaches?limit=50';
      if (_selectedCategoryId != null) {
        url += '&categoryID=$_selectedCategoryId';
      }
      final res = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _coaches = data.map((j) => CoachModel.fromJson(j)).toList();
          _coachesLoading = false;
          if (_selectedCity != null &&
              !_availableCities.contains(_selectedCity)) {
            _selectedCity = null;
          }
        });
        _fetchCoachRatings();
      } else {
        setState(() {
          _coachesError = 'Server error (${res.statusCode})';
          _coachesLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _coachesError = 'Server unreachable.';
        _coachesLoading = false;
      });
    }
  }

  Future<void> _fetchAdvisors() async {
    setState(() {
      _advisorsLoading = true;
      _advisorsError = null;
    });
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/advisors'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _advisors = data.map((j) => _AdvisorItem.fromJson(j)).toList();
          _advisorsLoading = false;
          if (_selectedCity != null &&
              !_availableCities.contains(_selectedCity)) {
            _selectedCity = null;
          }
        });
      } else {
        setState(() {
          _advisorsError = 'Server error (${res.statusCode})';
          _advisorsLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _advisorsError = 'Server unreachable.';
        _advisorsLoading = false;
      });
    }
  }

  List<dynamic> get _availableCities {
    final cities = <String>{};

    for (final c in _coaches) {
      final city = (c.ville ?? '').trim();
      if (city.isNotEmpty) cities.add(city);
    }

    for (final a in _advisors) {
      final city = (a.ville ?? '').trim();
      if (city.isNotEmpty) cities.add(city);
    }

    final sorted = cities.toList();
    sorted.sort();
    return sorted;
  }

  List<CoachModel> get _filteredCoaches {
    var list = _coaches.where((c) {
      final matchesQuery = _query.isEmpty ||
          c.fullName.toLowerCase().contains(_query) ||
          (c.speciality ?? '').toLowerCase().contains(_query) ||
          c.bio.toLowerCase().contains(_query) ||
          c.invitationCode.toLowerCase().contains(_query);
      if (!matchesQuery) return false;

      if (_selectedCity != null && _selectedCity!.isNotEmpty) {
        final coachCity = (c.ville ?? '').trim();
        if (coachCity.toLowerCase() != _selectedCity!.toLowerCase()) {
          return false;
        }
      }

      if (_selectedMinRating != null) {
        final rating = _coachAvgRatings[c.id] ?? 0.0;
        if (rating < _selectedMinRating!) return false;
      }
      return true;
    }).toList();

    if (_sortBy == 'name') {
      list.sort((a, b) => a.fullName.compareTo(b.fullName));
    } else if (_sortBy == 'rating') {
      list.sort((a, b) => (_coachAvgRatings[b.id] ?? 0.0)
          .compareTo(_coachAvgRatings[a.id] ?? 0.0));
    } else {
      list.sort((a, b) => b.earnedPoints.compareTo(a.earnedPoints));
    }
    return list;
  }

  List<_AdvisorItem> get _filteredAdvisors {
    return _advisors.where((a) {
      final matchesQuery = _query.isEmpty ||
          a.fullName.toLowerCase().contains(_query) ||
          a.specialty.toLowerCase().contains(_query);
      if (!matchesQuery) return false;

      if (_selectedCity != null && _selectedCity!.isNotEmpty) {
        final advisorCity = (a.ville ?? '').trim();
        if (advisorCity.toLowerCase() != _selectedCity!.toLowerCase()) {
          return false;
        }
      }
      return true;
    }).toList();
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
            child: Column(children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildTabBar(),
              if (_tabController.index == 0) _buildCategoryChips(),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child:
                    _showFilters ? _buildFilterPanel() : const SizedBox.shrink(),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildCoachTab(), _buildAdvisorTab()],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _tabController.index == 0
                        ? 'Discover more than coaches.'
                        : 'Discover companies near you.',
                    style: TextStyle(
                      color: context.fitlek.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => setState(() => _showFilters = !_showFilters),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: context.fitlek.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.fitlek.border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.location_on_rounded,
                      color: Theme.of(context).colorScheme.primary, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    _selectedCity ?? (_clientVille?.isNotEmpty == true ? _clientVille! : 'Anywhere'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      color: context.fitlek.textMuted, size: 16),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _showFilters = !_showFilters),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: context.fitlek.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.fitlek.border),
                ),
                child: Icon(Icons.map_rounded,
                    color: context.fitlek.textMuted, size: 17),
              ),
            ),
          ],
        ),
      );

  void _selectCategory(int? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    setState(() => _selectedCategoryId = categoryId);
    _fetchCoaches();
  }

  Widget _buildCategoryChips() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 0, 0),
        child: SizedBox(
          height: 76,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 20),
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final active = _selectedCategoryId == cat.id;
              return GestureDetector(
                onTap: () => _selectCategory(active ? null : cat.id),
                child: Container(
                  width: 66,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: active
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                        : context.fitlek.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : context.fitlek.border,
                      width: active ? 1.4 : 1,
                    ),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(cat.icon,
                        size: 20,
                        color: active
                            ? Theme.of(context).colorScheme.primary
                            : context.fitlek.textMuted),
                    const SizedBox(height: 6),
                    Text(
                      cat.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: active
                            ? Theme.of(context).colorScheme.primary
                            : context.fitlek.textMuted,
                        fontSize: 9.5,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
      );

 Widget _buildSearchBar() => Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: context.fitlek.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.fitlek.border),
              ),
              child: Row(children: [
                Icon(Icons.search_rounded, color: context.fitlek.textMuted, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search a coach or company...',
                      hintStyle: TextStyle(color: context.fitlek.textSecondary, fontSize: 14),
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
                    child: Icon(Icons.close_rounded, color: context.fitlek.textMuted, size: 18),
                  ),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          _circleIconButton(
            icon: Icons.qr_code_scanner_rounded,
            onTap: _scanCoachQrCode,
          ),
          const SizedBox(width: 10),
          _circleIconButton(
            icon: Icons.tune_rounded,
            active: _showFilters,
            showDot: _selectedCity != null,
            onTap: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
    );

Widget _circleIconButton({
  required IconData icon,
  required VoidCallback onTap,
  bool active = false,
  bool showDot = false,
}) {
  final cs = Theme.of(context).colorScheme;
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: active ? cs.primary : context.fitlek.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: active ? cs.primary : context.fitlek.border),
        boxShadow: active
            ? [BoxShadow(color: cs.primary.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))]
            : null,
      ),
      child: Stack(clipBehavior: Clip.none, children: [
        Center(
          child: Icon(icon, size: 20, color: active ? cs.onPrimary : context.fitlek.textMuted),
        ),
        if (showDot)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
                border: Border.all(color: context.fitlek.card, width: 1.5),
              ),
            ),
          ),
      ]),
    ),
  );
}

  Widget _buildTabBar() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
              color: context.fitlek.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.fitlek.border)),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10)),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: context.fitlek.textMuted,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.8),
            tabs: [
              Tab(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    const Icon(Icons.person_rounded, size: 15),
                    const SizedBox(width: 6),
                    Text('COACHES (${_filteredCoaches.length})'),
                  ])),
              Tab(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    const Icon(Icons.business_rounded, size: 15),
                    const SizedBox(width: 6),
                    Text('COMPANIES (${_filteredAdvisors.length})'),
                  ])),
            ],
          ),
        ),
      );

  Widget _buildFilterPanel() => Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: context.fitlek.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.fitlek.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('SORT BY',
              style: TextStyle(
                  color: context.fitlek.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Row(children: [
            _sortBtn('Points', 'points'),
            const SizedBox(width: 10),
            _sortBtn('Alphabetical', 'name'),
            const SizedBox(width: 10),
            _sortBtn('Top rated', 'rating'),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            Text('MINIMUM RATING',
                style: TextStyle(
                    color: context.fitlek.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
            const Spacer(),
            if (_selectedMinRating != null)
              GestureDetector(
                onTap: () => setState(() => _selectedMinRating = null),
                child: Text('Clear',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ratingChip('All', null),
              _ratingChip('4.5+', 4.5),
              _ratingChip('4.0+', 4.0),
              _ratingChip('3.5+', 3.5),
            ],
          ),
          if (_availableCities.isNotEmpty) ...[
            const SizedBox(height: 18),
            Row(children: [
              Text('CITY',
                  style: TextStyle(
                      color: context.fitlek.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5)),
              const Spacer(),
              if (_selectedCity != null)
                GestureDetector(
                  onTap: () => setState(() => _selectedCity = null),
                  child: Text('Clear',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
            ]),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _cityChip('All', null),
                ..._availableCities.map((city) => _cityChip(city, city)),
              ],
            ),
          ],
        ]),
      );

  Widget _sortBtn(String label, String value) {
    final active = _sortBy == value;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.primary
                : context.fitlek.card2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : context.fitlek.border)),
        child: Text(label,
            style: TextStyle(
                color: active
                    ? Theme.of(context).colorScheme.onPrimary
                    : context.fitlek.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _cityChip(String label, String? value) {
    final active = _selectedCity == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedCity = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.primary
                : context.fitlek.card2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : context.fitlek.border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (value != null) ...[
            Icon(Icons.location_on_rounded,
                size: 12,
                color: active
                    ? Theme.of(context).colorScheme.onPrimary
                    : context.fitlek.textMuted),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  color: active
                      ? Theme.of(context).colorScheme.onPrimary
                      : context.fitlek.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Widget _ratingChip(String label, double? value) {
    final active = _selectedMinRating == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedMinRating = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.primary
                : context.fitlek.card2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : context.fitlek.border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (value != null) ...[
            Icon(Icons.star_rounded,
                size: 12,
                color: active
                    ? Theme.of(context).colorScheme.onPrimary
                    : const Color(0xFFF59E0B)),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  color: active
                      ? Theme.of(context).colorScheme.onPrimary
                      : context.fitlek.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Widget _buildCoachTab() {
    if (_coachesLoading) return _shimmerList();
    if (_coachesError != null) return _errorView(_coachesError!, _fetchCoaches);
    final list = _filteredCoaches;
    if (list.isEmpty) {
      return _emptyView(_selectedCity != null
          ? 'No coaches found in $_selectedCity'
          : 'No coaches found');
    }

    return RefreshIndicator(
      onRefresh: _fetchCoaches,
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: context.fitlek.card,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        itemCount: list.length,
        itemBuilder: (_, i) => _AnimatedListItem(
          index: i,
          child: _CoachCard(
            coach: list[i],
            clientID: widget.clientID,
            token: widget.token,
            avgRating: _coachAvgRatings[list[i].id] ?? 0.0,
            reviewCount: _coachReviewCounts[list[i].id] ?? 0,
            isFavorite: _favoriteCoachIds.contains(list[i].id),
            onFavorite: () => _toggleFavorite(list[i].id),
          ),
        ),
      ),
    );
  }

  Widget _buildAdvisorTab() {
    if (_advisorsLoading) return _shimmerList();
    if (_advisorsError != null) {
      return _errorView(_advisorsError!, _fetchAdvisors);
    }
    final list = _filteredAdvisors;
    if (list.isEmpty) {
      return _emptyView(_selectedCity != null
          ? 'No companies found in $_selectedCity'
          : 'No companies found');
    }

    return RefreshIndicator(
      onRefresh: _fetchAdvisors,
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: context.fitlek.card,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        itemCount: list.length,
        itemBuilder: (_, i) => _AnimatedListItem(
          index: i,
          child: _AdvisorCard(
            advisor: list[i],
            clientID: widget.clientID,
            token: widget.token,
          ),
        ),
      ),
    );
  }

  Widget _shimmerList() => ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        itemCount: 5,
        itemBuilder: (_, i) => _AnimatedListItem(
          index: i,
          child: _ShimmerCard(),
        ),
      );

  Widget _errorView(String msg, VoidCallback retry) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.wifi_off_rounded,
                color: context.fitlek.textMuted, size: 52),
            const SizedBox(height: 14),
            Text(msg,
                style: TextStyle(color: context.fitlek.textMuted, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: retry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.4))),
                child: Text('Retry',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
            ),
          ]),
        ),
      );

  Widget _emptyView(String msg) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off_rounded,
              color: context.fitlek.textMuted, size: 52),
          const SizedBox(height: 14),
          Text(msg,
              style: TextStyle(color: context.fitlek.textMuted, fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() {
              _searchCtrl.clear();
              _query = '';
              _selectedCity = null;
            }),
            child: Text('Reset',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
      );
}

class _AnimatedListItem extends StatefulWidget {
  final int index;
  final Widget child;
  const _AnimatedListItem({required this.index, required this.child});

  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: widget.child,
      ),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _anim = Tween<double>(begin: -2, end: 2)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: context.fitlek.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.fitlek.border)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Container(height: 160, color: context.fitlek.card2),
        Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _shimmerLine(width: 140, height: 16),
            const SizedBox(height: 8),
            _shimmerLine(width: 200, height: 12),
            const SizedBox(height: 16),
            Row(children: [
              _shimmerLine(width: 80, height: 28),
              const SizedBox(width: 8),
              _shimmerLine(width: 80, height: 28),
            ]),
            const SizedBox(height: 14),
            _shimmerLine(width: double.infinity, height: 40),
          ]),
        ),
      ]),
    );
  }

  Widget _shimmerLine({required double width, required double height}) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(_anim.value - 1, 0),
              end: Alignment(_anim.value + 1, 0),
              colors: [
                context.fitlek.card2,
                context.fitlek.border,
                context.fitlek.card2,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CoachCard extends StatefulWidget {
  final CoachModel coach;
  final int clientID;
  final String? token;
  final double avgRating;
  final int reviewCount;
  final bool isFavorite;
  final VoidCallback onFavorite;

  const _CoachCard({
    required this.coach,
    required this.clientID,
    this.token,
    required this.avgRating,
    required this.reviewCount,
    required this.isFavorite,
    required this.onFavorite,
  });

  @override
  State<_CoachCard> createState() => _CoachCardState();
}

class _CoachCardState extends State<_CoachCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final coach = widget.coach;
    final bool hasRating = widget.reviewCount > 0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        final session = ReservationModel(
          id: 0,
          clientID: widget.clientID,
          coachID: coach.id,
          coachName: coach.fullName,
          coachSpeciality: coach.speciality ?? '',
          coachImageUrl: coach.avatarUrl ?? '',
          coachRating: widget.avgRating,
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
                session: session, token: widget.token ?? '', clientID: widget.clientID),
            transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
            transitionDuration: const Duration(milliseconds: 350),
          ),
        );
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: f.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: f.border),
            boxShadow: [
              BoxShadow(color: f.shadow, blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            SizedBox(
              height: 190,
              width: double.infinity,
              child: Stack(fit: StackFit.expand, children: [
                networkAvatar(coach.avatarUrl, placeholder: _bannerGradient()),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                      stops: const [0.35, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.star_rounded,
                          color: hasRating ? const Color(0xFFF59E0B) : Colors.white54, size: 13),
                      const SizedBox(width: 4),
                      Text(hasRating ? widget.avgRating.toStringAsFixed(1) : 'New',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                      if (hasRating)
                        Text(' (${widget.reviewCount})',
                            style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    ]),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: widget.onFavorite,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: widget.isFavorite ? Colors.redAccent : Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                if (coach.isPremium)
                  Positioned(
                    top: 48,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: f.premium, borderRadius: BorderRadius.circular(20)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.workspace_premium_rounded, color: Colors.black, size: 11),
                        SizedBox(width: 4),
                        Text('PREMIUM',
                            style: TextStyle(color: Colors.black, fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ]),
                    ),
                  ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(coach.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                    const SizedBox(height: 3),
                    Row(children: [
                      Icon(Icons.fitness_center_rounded, color: cs.primary, size: 12),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          "${coach.speciality ?? 'Coach'} • ${coach.ville?.isNotEmpty == true ? coach.ville : 'Anywhere'}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ]),
                  ]),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (coach.bio.isNotEmpty) ...[
                  Text(coach.bio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: f.textSecondary, fontSize: 12.5, height: 1.5)),
                  const SizedBox(height: 12),
                ],
                _buildPriceTelRow(),
                const SizedBox(height: 12),
                Row(children: [
                  _chip(Icons.bolt_rounded, '${coach.earnedPoints} pts'),
                  const SizedBox(width: 8),
                  _chip(Icons.card_giftcard_rounded, '${coach.totalInvitations} inv.'),
                ]),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [cs.primary, f.primaryDim]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 6))],
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.person_rounded, color: cs.onPrimary, size: 15),
                    const SizedBox(width: 8),
                    Text('VIEW PROFILE',
                        style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.4)),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _bannerGradient() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: [cs.primary.withValues(alpha: 0.35), f.primaryDim])),
    );
  }

  Widget _buildPriceTelRow() {
    final coach = widget.coach;
    final hasTel = coach.tel != null && coach.tel!.trim().isNotEmpty;
    final hasCode = coach.invitationCode.trim().isNotEmpty;
    final hasCity = coach.ville != null && coach.ville!.trim().isNotEmpty;
    if (!hasTel && !hasCode && !hasCity) return const SizedBox.shrink();

    return Wrap(spacing: 8, runSpacing: 8, children: [
      if (hasCity) _pill(Icons.location_on_rounded, coach.ville!, Theme.of(context).colorScheme.primary),
      if (hasCode)
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: coach.invitationCode));
            _snack(context, 'Code copied', Colors.amber, Colors.black);
          },
          child: _pill(Icons.qr_code_rounded, coach.invitationCode, Colors.amber),
        ),
      if (hasTel)
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: coach.tel!));
            _snack(context, 'Number copied', Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.onPrimary);
          },
          child: _pill(Icons.phone_rounded, coach.tel!, context.fitlek.textSecondary, outline: true),
        ),
    ]);
  }

  Widget _pill(IconData icon, String label, Color color, {bool outline = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: outline ? context.fitlek.card2 : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: outline ? context.fitlek.border : color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _chip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 12),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 10, fontWeight: FontWeight.w700)),
        ]),
      );

  void _snack(BuildContext context, String msg, Color bg, Color fg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }
}

class _AdvisorCard extends StatefulWidget {
  final _AdvisorItem advisor;
  final int clientID;
  final String? token;

  const _AdvisorCard(
      {required this.advisor, required this.clientID, this.token});

  @override
  State<_AdvisorCard> createState() => _AdvisorCardState();
}

class _AdvisorCardState extends State<_AdvisorCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.advisor.avatarUrl ?? '';
    final hasImage = imageUrl.isNotEmpty;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => CompanyDetailScreen(
            advisorId: widget.advisor.id,
            clientID: widget.clientID,
            accessToken: widget.token,
          ),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
                position: Tween<Offset>(
                        begin: const Offset(0, 0.04), end: Offset.zero)
                    .animate(CurvedAnimation(
                        parent: anim, curve: Curves.easeOutCubic)),
                child: child),
          ),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: context.fitlek.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.fitlek.border),
            boxShadow: [
              BoxShadow(
                color: context.fitlek.shadow,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            SizedBox(
              height: 170,
              width: double.infinity,
              child: Stack(fit: StackFit.expand, children: [
                hasImage
                    ? Hero(
                        tag: 'advisor_avatar_${widget.advisor.id}',
                        child: Image.network(imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _coverPlaceholder()),
                      )
                    : _coverPlaceholder(),
                DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8)
                    ],
                            stops: const [
                      0.3,
                      1.0
                    ]))),
                Positioned(
                    bottom: 12,
                    left: 14,
                    right: 14,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.advisor.fullName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5)),
                          Row(children: [
                            Icon(Icons.fitness_center_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 12),
                            const SizedBox(width: 4),
                            Text(widget.advisor.specialty,
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 12)),
                          ]),
                        ])),
                Positioned(
                    top: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24)),
                      child: const Row(children: [
                        Icon(Icons.people_rounded,
                            color: Colors.white70, size: 11),
                        SizedBox(width: 4),
                        Text('View coaches',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ]),
                    )),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.email_rounded,
                          color: context.fitlek.textMuted, size: 12),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(widget.advisor.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: context.fitlek.textSecondary,
                                  fontSize: 11))),
                    ]),
                    if (widget.advisor.ville != null &&
                        widget.advisor.ville!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(children: [
                        Icon(Icons.location_on_rounded,
                            color: context.fitlek.textMuted, size: 12),
                        const SizedBox(width: 6),
                        Text(widget.advisor.ville!,
                            style: TextStyle(
                                color: context.fitlek.textSecondary,
                                fontSize: 11)),
                      ]),
                    ],
                    const SizedBox(height: 10),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.3))),
                        child: Text(widget.advisor.specialty,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                    ]),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text('VIEW PROFILE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 1.5)),
                    ),
                  ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _coverPlaceholder() => Container(
        color: context.fitlek.card2,
        child: Center(
            child: Icon(Icons.business_rounded,
                color: Theme.of(context).colorScheme.primary, size: 56)),
      );
}