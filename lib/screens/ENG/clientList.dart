import '../../services/coach_qr_navigation.dart';
import '../../services/live_updates.dart';
import '../../components/ENG/exploreCoachMap.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../components/ENG/exploreCoachGrid.dart';
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
import 'package:geolocator/geolocator.dart';

String resolveImageUrl(String? url) {
  if (url == null || url.trim().isEmpty) return '';
  final u = url.trim();
  if (u.startsWith('http://') || u.startsWith('https://')) return u;
  final root = baseUrl.replaceAll(RegExp(r'/api/?$'), '');
  return u.startsWith('/') ? '$root$u' : '$root/$u';
}

Widget networkAvatar(String? url,
    {required Widget placeholder, BoxFit fit = BoxFit.cover}) {
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
                  ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
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
  final int id;
  final String name;
  final String icon;

  const _CategoryItem(
      {required this.id, required this.name, required this.icon});

  factory _CategoryItem.fromJson(Map<String, dynamic> j) => _CategoryItem(
        id: j['id'],
        name: j['name'] ?? '',
        icon: j['icon'] ?? 'fitness_center',
      );
}

IconData _mapCategoryIcon(String iconName) {
  switch (iconName) {
    case 'fitness_center':
      return Icons.fitness_center_rounded;
    case 'monitor_weight':
      return Icons.monitor_weight_rounded;
    case 'self_improvement':
      return Icons.self_improvement_rounded;
    case 'sports_gymnastics':
      return Icons.sports_gymnastics_rounded;
    case 'sports_mma':
      return Icons.sports_martial_arts_rounded;
    case 'restaurant':
      return Icons.apple;
    case 'accessibility_new':
      return Icons.sports_gymnastics_rounded;
    case 'directions_run':
      return Icons.directions_run_rounded;
    case 'straighten':
      return Icons.straighten_rounded;
    default:
      return Icons.fitness_center_rounded;
  }
}

class DiscoverScreen extends StatefulWidget {
  final int clientID;
  final VoidCallback? onBack;
  final ValueChanged<bool>? onMapChanged;
  final String? token;
  final int initialTabIndex;
  final ValueNotifier<int>? tabRequest;

  const DiscoverScreen({
    super.key,
    this.onBack,
    this.onMapChanged,
    required this.clientID,
    this.token,
    this.initialTabIndex = 0,
    this.tabRequest,
  });

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin, LiveUpdates<DiscoverScreen> {
  @override
  Set<String> get liveDomains => {
        'coaches',
        'profile',
        'edit',
        'packages',
        'reviews',
        'locations',
        'favorites',
        'bans',
        'categories'
      };
  @override
  Future<void> refreshLiveData() async {
    await Future.wait(
        [_fetchCoaches(silent: true), _fetchFavorites(), _fetchClientVille()]);
  }

  late TabController _tabController;

  List<CoachModel> _coaches = [];
  List<_AdvisorItem> _advisors = [];
  bool _coachesLoading = true;
  bool _advisorsLoading = true;
  String? _coachesError;
  String? _advisorsError;

  final _searchCtrl = TextEditingController();
  String _query = '';
  String _sortBy = 'recommended';
  String? _selectedCity;
  bool _showFilters = false;
  bool _gridView = false;
  bool _verifiedOnly = false;
  String? _clientVille;
  String? _selectedSpecialty;
  double? _selectedMinRating;
  Set<int> _favoriteCoachIds = {};
  Map<int, double> _coachAvgRatings = {};
  Map<int, int> _coachReviewCounts = {};

  List<_CategoryItem> _categories = [];
  bool _loadingCategories = true;
  bool _isMapView = false;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
      };

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location services are disabled.'),
          backgroundColor: Colors.redAccent,
        ));
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location permissions are denied'),
            backgroundColor: Colors.redAccent,
          ));
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location permissions are permanently denied.'),
          backgroundColor: Colors.redAccent,
        ));
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Fetching location...'),
        backgroundColor: Colors.black54,
        duration: Duration(seconds: 1),
      ));
    }

    try {
      Position position = await Geolocator.getCurrentPosition();

      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=14&addressdetails=1');
      final response = await http.get(url,
          headers: {'User-Agent': 'Sirvya_App/1.0', 'Accept-Language': 'en'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['address'] != null) {
          final address = data['address'];
          String city =
              address['city'] ?? address['town'] ?? address['village'] ?? '';
          String district = address['suburb'] ??
              address['neighbourhood'] ??
              address['county'] ??
              '';

          String locationStr = '';
          if (city.isNotEmpty) locationStr = city;
          if (district.isNotEmpty) {
            if (locationStr.isNotEmpty)
              locationStr += ', $district';
            else
              locationStr = district;
          }

          if (locationStr.isNotEmpty && mounted) {
            setState(() {
              _clientVille = locationStr;
              _selectedCity = locationStr;
            });
            _fetchCoaches(); // Refresh coaches based on new location

            // Record the location in the database
            try {
              final putHeaders = Map<String, String>.from(_headers)
                ..['Content-Type'] = 'application/json';
              await http
                  .put(
                    Uri.parse('$baseUrl/clients/me'),
                    headers: putHeaders,
                    body: jsonEncode({
                      'userID': widget.clientID,
                      'ville': locationStr,
                    }),
                  )
                  .timeout(const Duration(seconds: 10));
            } catch (e) {
              // Ignore silently if failed to save to DB
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to get location: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  Future<void> _scanCoachQrCode() => CoachQrNavigation.scanAndOpen(context);

  @override
  void initState() {
    super.initState();
    _loadViewPreference();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(() => setState(() {}));
    _searchCtrl.addListener(
        () => setState(() => _query = _searchCtrl.text.toLowerCase()));
    widget.tabRequest?.addListener(_onTabRequest);
    _fetchCategories();
    _fetchCoaches();
    _fetchAdvisors();
    _companyVisibilityTimer = Timer.periodic(
        const Duration(seconds: 30), (_) => _refreshCompanyVisibility());
    _fetchClientVille();
    _fetchFavorites();
  }

  Future<void> _fetchCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/coaches/specialties'), headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _categories = data
                .map((e) => _CategoryItem.fromJson(e as Map<String, dynamic>))
                .toList();
            _loadingCategories = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingCategories = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
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
    _tabController
        .animateTo(_coachingCompaniesEnabled ? widget.tabRequest!.value : 0);
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
    _companyVisibilityTimer?.cancel();
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCoaches({bool silent = false}) async {
    if (!mounted) return;
    if (!silent)
      setState(() {
        _coachesLoading = true;
        _coachesError = null;
      });
    try {
      String url = '$baseUrl/recommendations?limit=50';
      if (_selectedSpecialty != null && _selectedSpecialty!.isNotEmpty) {
        url += '&specialty=${Uri.encodeComponent(_selectedSpecialty!)}';
      }
      final res = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _coaches = data.map((j) => CoachModel.fromJson(j)).toList();
          _coachAvgRatings = {
            for (final coach in _coaches) coach.id: coach.rating ?? 0,
          };
          _coachReviewCounts = {
            for (final coach in _coaches) coach.id: coach.reviewCount ?? 0,
          };
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
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _coachesError = error is FormatException || error is TypeError
            ? 'Could not load recommendations. Please try again.'
            : 'Unable to connect. Please try again.';
        _coachesLoading = false;
      });
    }
  }

  bool _coachingCompaniesEnabled = false;
  Timer? _companyVisibilityTimer;

  Future<void> _refreshCompanyVisibility() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/advisors/visibility'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (!mounted || res.statusCode != 200) return;
      final enabled = jsonDecode(res.body)['coachingCompanies'] == true;
      if (enabled == _coachingCompaniesEnabled) return;
      if (enabled) {
        await _fetchAdvisors();
      } else {
        setState(() {
          _coachingCompaniesEnabled = false;
          _advisors = [];
          _advisorsLoading = false;
          _tabController.animateTo(0);
        });
      }
    } catch (_) {
      // Keep the last confirmed value during a temporary connection failure.
    }
  }

  Future<void> _fetchAdvisors() async {
    setState(() {
      _advisorsLoading = true;
      _advisorsError = null;
    });
    try {
      final visibility = await http
          .get(
            Uri.parse('$baseUrl/advisors/visibility'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (visibility.statusCode != 200) {
        throw Exception('Visibility unavailable');
      }
      final enabled = jsonDecode(visibility.body)['coachingCompanies'] == true;
      setState(() {
        _coachingCompaniesEnabled = enabled;
        if (!enabled) {
          _advisors = [];
          _advisorsLoading = false;
          _tabController.animateTo(0);
        }
      });
      if (!enabled) return;

      final res = await http
          .get(Uri.parse('$baseUrl/advisors'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
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
      if (!mounted) return;
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
      if (_verifiedOnly && !c.isApproved) return false;
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
    } else if (_sortBy == 'points') {
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
    if (_isMapView) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
            child: Stack(children: [
          Positioned.fill(child: _buildCoachTab()),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Material(
              color: context.fitlek.card.withValues(alpha: 0.96),
              elevation: 5,
              borderRadius: BorderRadius.circular(22),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _buildHeader(),
                _buildSearchBar(),
                Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Row(children: [
                      TextButton.icon(
                          onPressed: _openFilters,
                          icon: const Icon(Icons.tune_rounded, size: 18),
                          label: const Text('Filters')),
                      const Spacer(),
                      Flexible(
                          child: Text(_selectedSpecialty ?? 'All specialties',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: context.fitlek.textMuted))),
                    ])),
              ]),
            ),
          ),
        ])),
      );
    }

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
              if (_tabController.index == 0) _buildActiveFilters(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics:
                      const NeverScrollableScrollPhysics(), // Disable swipe to keep focus on coaches
                  children: [
                    _buildCoachTab(),
                    _coachingCompaniesEnabled
                        ? _buildAdvisorTab()
                        : _buildCoachTab()
                  ],
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
            GestureDetector(
              onTap: () {
                if (widget.onBack != null || Navigator.canPop(context)) {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else {
                    Navigator.maybePop(context);
                  }
                }
              },
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Find a coach',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Container(
              height: 36,
              decoration: BoxDecoration(
                color: context.fitlek.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.fitlek.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _mapListToggleBtn('Map', Icons.map_outlined, _isMapView, () {
                    setState(() => _isMapView = true);
                    widget.onMapChanged?.call(true);
                    _tabController.animateTo(0);
                  }),
                  _mapListToggleBtn(
                      'List', Icons.format_list_bulleted_rounded, !_isMapView,
                      () {
                    setState(() => _isMapView = false);
                    widget.onMapChanged?.call(false);
                  }),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _mapListToggleBtn(
      String label, IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : context.fitlek.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : context.fitlek.textMuted,
                fontSize: 12,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectSpecialty(String? specialty) {
    if (_selectedSpecialty == specialty) return;
    setState(() => _selectedSpecialty = specialty);
    _filterSheetSetState?.call(() {});
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
              final active = _selectedSpecialty == cat.name;
              return GestureDetector(
                onTap: () => _selectSpecialty(active ? null : cat.name),
                child: Container(
                  width: 66,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: active
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12)
                        : context.fitlek.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : context.fitlek.border,
                      width: active ? 1.4 : 1,
                    ),
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_mapCategoryIcon(cat.icon),
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
                            fontWeight:
                                active ? FontWeight.w800 : FontWeight.w600,
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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: context.fitlek.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.fitlek.border),
          ),
          child: Row(children: [
            Icon(Icons.search_rounded,
                color: context.fitlek.textMuted, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search coaches, specialties...',
                  hintStyle: TextStyle(
                      color: context.fitlek.textSecondary, fontSize: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
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
                child: Icon(Icons.close_rounded,
                    color: context.fitlek.textMuted, size: 18),
              ),
          ]),
        ),
      );

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
    bool showDot = false,
    double size = 50,
  }) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: active ? cs.primary : context.fitlek.card,
          borderRadius: BorderRadius.circular(size / 2.5),
          border:
              Border.all(color: active ? cs.primary : context.fitlek.border),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: cs.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: Stack(clipBehavior: Clip.none, children: [
          Center(
            child: Icon(icon,
                size: size * 0.4,
                color: active ? cs.onPrimary : context.fitlek.textMuted),
          ),
          if (showDot)
            Positioned(
              top: size * 0.12,
              right: size * 0.12,
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

  Widget _buildActiveFilters() {
    final activeChips = <Widget>[];
    if (_verifiedOnly) {
      activeChips.add(_activeChip(
        label: 'Verified only',
        icon: Icons.verified_rounded,
        onRemove: () => setState(() => _verifiedOnly = false),
      ));
    }

    if (_selectedCity != null && _selectedCity!.isNotEmpty) {
      activeChips.add(_activeChip(
        label: _selectedCity!,
        icon: Icons.location_on_rounded,
        onRemove: () => setState(() => _selectedCity = null),
      ));
    }

    if (_selectedSpecialty != null && _selectedSpecialty!.isNotEmpty) {
      activeChips.add(_activeChip(
        label: _selectedSpecialty!,
        icon: Icons.fitness_center_rounded,
        onRemove: () {
          setState(() => _selectedSpecialty = null);
          _fetchCoaches();
        },
      ));
    }

    if (_selectedMinRating != null) {
      activeChips.add(_activeChip(
        label: '${_selectedMinRating?.toStringAsFixed(0)}+ Stars',
        icon: Icons.star_rounded,
        onRemove: () => setState(() => _selectedMinRating = null),
      ));
    }

    if (activeChips.isEmpty && _categories.isNotEmpty) {
      return _buildCategoryChips();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: activeChips
                    .map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8), child: c))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _openFilters,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _showFilters
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.15)
                    : context.fitlek.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _showFilters
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.4)
                      : context.fitlek.border,
                ),
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 18,
                color: _showFilters
                    ? Theme.of(context).colorScheme.primary
                    : context.fitlek.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeChip({
    required String label,
    required IconData icon,
    required VoidCallback onRemove,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.onSurface.withValues(alpha: 0.75)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded,
                size: 13, color: cs.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  // Removed TabBar visually, replaced by the toggle switch in header

  StateSetter? _filterSheetSetState;

  void _updateFilters(VoidCallback update) {
    setState(update);
    _filterSheetSetState?.call(() {});
  }

  Future<void> _openFilters() async {
    setState(() => _showFilters = true);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.fitlek.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) =>
          StatefulBuilder(builder: (context, updateSheet) {
        _filterSheetSetState = updateSheet;
        return ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.85),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
                child: Row(children: [
                  const Expanded(
                      child: Text('Filter coaches',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800))),
                  TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Done')),
                ])),
            Flexible(
                child: SingleChildScrollView(
                    child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          if (_isMapView) _buildCategoryChips(),
                          _buildFilterPanel(),
                        ])))),
          ]),
        );
      }),
    );
    _filterSheetSetState = null;
    if (mounted) setState(() => _showFilters = false);
  }

  Widget _buildFilterPanel() => Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: context.fitlek.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.fitlek.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary:
                const Icon(Icons.verified_rounded, color: Color(0xFF38BDF8)),
            title: const Text('Verified only'),
            subtitle: const Text('Show coaches verified by Sirvya'),
            value: _verifiedOnly,
            onChanged: (value) => _updateFilters(() => _verifiedOnly = value),
          ),
          const SizedBox(height: 12),
          Text('SORT BY',
              style: TextStyle(
                  color: context.fitlek.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 8, children: [
            _sortBtn('Recommended for you', 'recommended'),
            _sortBtn('Points', 'points'),
            _sortBtn('Alphabetical', 'name'),
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
                onTap: () => _updateFilters(() => _selectedMinRating = null),
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
                  onTap: () => _updateFilters(() => _selectedCity = null),
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
      onTap: () => _updateFilters(() => _sortBy = value),
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
      onTap: () => _updateFilters(() => _selectedCity = value),
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
      onTap: () => _updateFilters(() => _selectedMinRating = value),
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

  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted)
      setState(() => _gridView =
          prefs.getBool('explore_grid_${widget.clientID}') ?? false);
  }

  Future<void> _setGridView(bool value) async {
    setState(() => _gridView = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('explore_grid_${widget.clientID}', value);
  }

  void _openGridCoach(CoachModel coach) {
    final session = ReservationModel(
        id: 0,
        clientID: widget.clientID,
        coachID: coach.id,
        coachName: coach.fullName,
        coachSpeciality: coach.displaySpecialties,
        coachImageUrl: coach.avatarUrl ?? '',
        coachRating: _coachAvgRatings[coach.id] ?? 0,
        sessionStart: DateTime.now(),
        sessionEnd: DateTime.now().add(const Duration(hours: 1)),
        location: 'To be defined',
        status: 'pending',
        price: 0,
        companyName: 'Independent');
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CoachDetailScreen(
                session: session,
                token: widget.token ?? '',
                clientID: widget.clientID)));
  }

  Widget _buildCoachTab() {
    if (_coachesLoading) return _shimmerList();
    if (_coachesError != null) return _errorView(_coachesError!, _fetchCoaches);
    final list = _filteredCoaches;
    if (_isMapView) {
      return ExploreCoachMap(
          topInset: 190,
          coaches: list,
          token: widget.token ?? '',
          onOpen: _openGridCoach,
          onRefresh: _fetchCoaches);
    }
    if (list.isEmpty) {
      return _emptyView(_selectedCity != null
          ? 'No coaches found in $_selectedCity'
          : 'No coaches found');
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Text(
                '${list.length} coaches found',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              )),
              IconButton(
                  tooltip: 'List view',
                  isSelected: !_gridView,
                  style: IconButton.styleFrom(
                    backgroundColor: !_gridView
                        ? const Color(0xFF55E6D0)
                        : Colors.transparent,
                    foregroundColor: !_gridView
                        ? const Color(0xFF064B43)
                        : Theme.of(context).colorScheme.onSurface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _setGridView(false),
                  icon: const Icon(Icons.view_list_rounded)),
              IconButton(
                  tooltip: 'Grid view',
                  isSelected: _gridView,
                  style: IconButton.styleFrom(
                    backgroundColor: _gridView
                        ? const Color(0xFF55E6D0)
                        : Colors.transparent,
                    foregroundColor: _gridView
                        ? const Color(0xFF064B43)
                        : Theme.of(context).colorScheme.onSurface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _setGridView(true),
                  icon: const Icon(Icons.grid_view_rounded)),
              GestureDetector(
                onTap: _openFilters,
                child: Row(
                  children: [
                    Text(
                      'Sort',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.swap_vert_rounded,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchCoaches,
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: context.fitlek.card,
            child: _gridView
                ? ExploreCoachGrid(
                    coaches: list,
                    favorites: _favoriteCoachIds,
                    ratings: _coachAvgRatings,
                    reviewCounts: _coachReviewCounts,
                    onOpen: _openGridCoach,
                    onFavorite: _toggleFavorite,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
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
          ),
        ),
      ],
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
              _verifiedOnly = false;
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
        color: const Color(0xFF13322B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: photo placeholder
                Container(
                  width: 90,
                  height: 110,
                  decoration: BoxDecoration(
                    color: context.fitlek.card2,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: AnimatedBuilder(
                    animation: _anim,
                    builder: (context, _) => Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
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
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Right: text placeholders
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerLine(width: 130, height: 15),
                      const SizedBox(height: 8),
                      _shimmerLine(width: 100, height: 12),
                      const SizedBox(height: 8),
                      _shimmerLine(width: 110, height: 12),
                      const SizedBox(height: 8),
                      _shimmerLine(width: 140, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _shimmerLine(width: 100, height: 14),
                _shimmerLine(width: 110, height: 36),
              ],
            ),
          ],
        ),
      ),
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
          coachSpeciality: coach.displaySpecialties,
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
                session: session,
                token: widget.token ?? '',
                clientID: widget.clientID),
            transitionsBuilder: (_, a, __, child) =>
                FadeTransition(opacity: a, child: child),
            transitionDuration: const Duration(milliseconds: 350),
          ),
        );
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(
                0xFF13322B), // Dark green cyprus background to match design
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                  color: f.shadow, blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Image and Details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Side: Image (taller rectangular to match design)
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          networkAvatar(coach.avatarUrl,
                              placeholder: _bannerGradient()),
                          if (coach.isPremium)
                            Positioned(
                              bottom: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                    color: f.premium,
                                    borderRadius: BorderRadius.circular(8)),
                                child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.workspace_premium_rounded,
                                          color: Colors.black, size: 8),
                                      SizedBox(width: 2),
                                      Text('PREMIUM',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 7,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5)),
                                    ]),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Right Side: Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Row: Name, Verified, Favorite
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        coach.fullName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    if (coach.isApproved) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified_rounded,
                                          color: Color(0xFF38BDF8), size: 14),
                                    ]
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: widget.onFavorite,
                                child: Icon(
                                  widget.isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: widget.isFavorite
                                      ? Colors.redAccent
                                      : Colors.white70,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Category / Specialty
                          Text(
                            coach.displaySpecialties,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          // Location
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded,
                                  color: Colors.white.withValues(alpha: 0.6),
                                  size: 12),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  coach.locationLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Rating & Availability
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 4,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFF59E0B), size: 18),
                              const SizedBox(width: 4),
                              Text(
                                hasRating
                                    ? widget.avgRating.toStringAsFixed(1)
                                    : 'New',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700),
                              ),
                              if (hasRating)
                                Text(
                                  ' (${widget.reviewCount})',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12),
                                ),
                              if (coach.isAvailableToday) ...[
                                const SizedBox(width: 12),
                                const SizedBox(width: 12),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.event_available_rounded,
                                        color: Color(0xFFD4F844), size: 14),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Available today',
                                      style: TextStyle(
                                          color: Color(0xFFD4F844),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Bottom Row: Price & Action Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (coach.minPrice != null && coach.minPrice! > 0)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${coach.minPrice!.toInt()} MAD',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Text(
                              'Price on request',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    GestureDetector(
                      onTap: () {
                        final session = ReservationModel(
                          id: 0,
                          clientID: widget.clientID,
                          coachID: coach.id,
                          coachName: coach.fullName,
                          coachSpeciality: coach.displaySpecialties,
                          coachImageUrl: coach.avatarUrl ?? '',
                          coachRating: widget.avgRating,
                          sessionStart: DateTime.now(),
                          sessionEnd:
                              DateTime.now().add(const Duration(hours: 1)),
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
                                token: widget.token ?? '',
                                clientID: widget.clientID),
                            transitionsBuilder: (_, a, __, child) =>
                                FadeTransition(opacity: a, child: child),
                            transitionDuration:
                                const Duration(milliseconds: 350),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 11),
                        decoration: BoxDecoration(
                          color: const Color(
                              0xFFE8F5C0), // Light lime/cream to match design
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View & book',
                              style: TextStyle(
                                color: Color(0xFF0D2B22),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded,
                                color: Color(0xFF0D2B22), size: 15),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bannerGradient() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [cs.primary.withValues(alpha: 0.35), f.primaryDim])),
    );
  }

  Widget _buildPriceTelRow() {
    final coach = widget.coach;
    final hasTel = coach.tel != null && coach.tel!.trim().isNotEmpty;
    final hasCode = coach.invitationCode.trim().isNotEmpty;
    final hasCity = coach.ville != null && coach.ville!.trim().isNotEmpty;
    if (!hasTel && !hasCode && !hasCity) return const SizedBox.shrink();

    return Wrap(spacing: 8, runSpacing: 8, children: [
      if (hasCity)
        _pill(Icons.location_on_rounded, coach.locationLabel,
            Theme.of(context).colorScheme.primary),
      if (hasCode)
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: coach.invitationCode));
            _snack(context, 'Code copied', Colors.amber, Colors.black);
          },
          child:
              _pill(Icons.qr_code_rounded, coach.invitationCode, Colors.amber),
        ),
      if (hasTel)
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: coach.tel!));
            _snack(
                context,
                'Number copied',
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.onPrimary);
          },
          child: _pill(
              Icons.phone_rounded, coach.tel!, context.fitlek.textSecondary,
              outline: true),
        ),
    ]);
  }

  Widget _pill(IconData icon, String label, Color color,
          {bool outline = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: outline ? context.fitlek.card2 : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: outline
                  ? context.fitlek.border
                  : color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _chip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
        ]),
      );

  void _snack(BuildContext context, String msg, Color bg, Color fg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(msg, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
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
