import 'clientConversation.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'clientConversationList.dart';
import 'package:fitlek1/constants/urls.dart';
import 'package:fitlek1/models/anas/reservation.dart';
import 'package:fitlek1/models/anas/coach.dart';
import 'clientCoachDetail.dart';
import 'clientCompanyDetail.dart';
import 'clientSessions.dart';
import 'clientList.dart';
import 'clientProfil.dart';
import 'clientNotifications.dart';
import 'clientSessionDetail.dart';
import 'clientQrScanner.dart';
import 'clientList.dart';
import 'clientBooking.dart';

import '../../theme/fitlek_theme_extension.dart';
import '../../components/sirvya_logo.dart';
import '../../constants/app_colors.dart';

class _AdvisorItem {
  final int id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String specialty;
  final bool isApproved;
  final String? ville;
  final int coachCount;
  final double? rating;
  final int? totalReviews;

  const _AdvisorItem({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    required this.specialty,
    required this.isApproved,
    this.ville,
    this.coachCount = 0,
    this.rating,
    this.totalReviews,
  });

  String get fullName => '$firstName $lastName';

  factory _AdvisorItem.fromJson(Map<String, dynamic> j) => _AdvisorItem(
        id: j['id'],
        firstName: j['firstName'] ?? '',
        lastName: j['lastName'] ?? '',
        avatarUrl: j['avatarUrl'],
        specialty: j['specialty'] ?? j['speciality'] ?? '',
        isApproved: j['isApproved'] == 1 || j['isApproved'] == true,
        ville: j['ville'],
        coachCount: j['coachCount'] ?? j['coach_count'] ?? 0,
        rating: j['rating'] != null ? (j['rating'] as num).toDouble() : null,
        totalReviews: j['totalReviews'] ?? j['total_reviews'],
      );
}

class _UpcomingSession {
  final int id;
  final String coachName;
  final String? coachAvatar;
  final String sessionTitle;
  final DateTime sessionStart;
  final String location;
  final String status;

  const _UpcomingSession({
    required this.id,
    required this.coachName,
    this.coachAvatar,
    required this.sessionTitle,
    required this.sessionStart,
    required this.location,
    required this.status,
  });

  factory _UpcomingSession.fromJson(Map<String, dynamic> j) {
    return _UpcomingSession(
      id: j['id'] ?? 0,
      coachName: j['coachName'] ?? j['coach_name'] ?? '',
      coachAvatar: j['coachImageUrl'] ?? j['coachAvatar'],
      sessionTitle: j['sessionTitle'] ?? j['title'] ?? 'Session',
      sessionStart: DateTime.tryParse(j['sessionStart'] ?? j['session_start'] ?? '') ?? DateTime.now(),
      location: j['location'] ?? '',
      status: j['status'] ?? 'pending',
    );
  }
}

class _CategoryItem {
  final int id;
  final String name;
  final String icon;

  const _CategoryItem({required this.id, required this.name, required this.icon});

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
    case 'sports_kabaddi':
      return Icons.sports_kabaddi_rounded;
    default:
      return Icons.fitness_center_rounded;
  }
}

class HomeScreen extends StatefulWidget {
  final int clientID;
  final String token;
  final String? firstName;
  final VoidCallback? onLogout;

  const HomeScreen({
    super.key,
    required this.clientID,
    required this.token,
    this.firstName,
    this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  List<CoachModel> _coaches = [];
  List<CoachModel> _allCoaches = [];
  List<_AdvisorItem> _advisors = [];
  List<_UpcomingSession> _upcomingSessions = [];
  List<_CategoryItem> _categories = [
    const _CategoryItem(id: 1, name: 'Musculation', icon: 'accessibility_new'),
    const _CategoryItem(id: 2, name: 'Perte de poids', icon: 'monitor_weight'),
    const _CategoryItem(id: 3, name: 'Yoga', icon: 'self_improvement'),
    const _CategoryItem(id: 4, name: 'CrossFit', icon: 'sports_gymnastics'),
    const _CategoryItem(id: 5, name: 'Boxe', icon: 'sports_mma'),
    const _CategoryItem(id: 6, name: 'Nutrition', icon: 'restaurant'),
  ];
  Set<int> _favoriteCoachIds = {};
  Map<int, double> _coachAvgRatings = {};
  Map<int, int> _coachReviewCounts = {};
  String? _avatarUrl;
  String? _clientVille;
  int _unreadMessagesCount = 0;

  bool _loadingCoaches = true;
  bool _loadingAdvisors = true;
  bool _loadingCategories = false;
  bool _loadingSessions = true;
  String? _coachError;
  String? _advisorError;

  int? _selectedCategoryId;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      };

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchCoaches();
    _fetchAdvisors();
    _fetchClientProfile();
    _fetchFavorites();
    _fetchUnreadMessagesCount();
    _fetchUpcomingSessions();
  }
  Future<void> _fetchCoachRatings() async {
    final ids = _allCoaches.map((c) => c.id).toSet();
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

  Future<void> _fetchUnreadMessagesCount() async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/conversations/unread-total?userID=${widget.clientID}'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() => _unreadMessagesCount = data['totalUnread'] ?? 0);
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchUpcomingSessions() async {
    setState(() => _loadingSessions = true);
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/reservations?clientID=${widget.clientID}&status=confirmed&limit=3&upcoming=true'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _upcomingSessions = data
                .map((e) => _UpcomingSession.fromJson(e as Map<String, dynamic>))
                .where((s) => s.sessionStart.isAfter(DateTime.now()))
                .take(3)
                .toList();
            _loadingSessions = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingSessions = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSessions = false);
    }
  }

  Future<void> _fetchCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/categories'), headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _categories = data.map((e) => _CategoryItem.fromJson(e as Map<String, dynamic>)).toList();
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
      setState(() {
        if (_favoriteCoachIds.contains(coachId)) {
          _favoriteCoachIds.remove(coachId);
        } else {
          _favoriteCoachIds.add(coachId);
        }
      });
    }
  }

  Future<void> _fetchClientProfile() async {
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
          setState(() {
            _avatarUrl = data['avatarUrl'] as String?;
            _clientVille = data['ville'] as String?;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchCoaches() async {
    setState(() {
      _loadingCoaches = true;
      _coachError = null;
    });
    try {
      String url = '$baseUrl/coaches?limit=20';
      if (_selectedCategoryId != null) {
        url += '&categoryID=$_selectedCategoryId';
      }
      final res = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _allCoaches = data
              .map((e) => CoachModel.fromJson(e as Map<String, dynamic>))
              .toList();
          _coaches = List.from(_allCoaches);
          _loadingCoaches = false;
        });
        _fetchCoachRatings();
      } else {
        setState(() {
          _coachError = 'Error (${res.statusCode})';
          _loadingCoaches = false;
        });
      }
    } catch (_) {
      setState(() {
        _coachError = 'Server unreachable';
        _loadingCoaches = false;
      });
    }
  }

  Future<void> _fetchAdvisors() async {
    setState(() {
      _loadingAdvisors = true;
      _advisorError = null;
    });
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/advisors'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _advisors = data
              .map((e) => _AdvisorItem.fromJson(e as Map<String, dynamic>))
              .toList();
          _loadingAdvisors = false;
        });
      } else {
        setState(() {
          _advisorError = 'Error (${res.statusCode})';
          _loadingAdvisors = false;
        });
      }
    } catch (_) {
      setState(() {
        _advisorError = 'Server unreachable';
        _loadingAdvisors = false;
      });
    }
  }

  void _selectCategory(int? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    setState(() => _selectedCategoryId = categoryId);
    _fetchCoaches();
  }


  void _openConversationWithCoach(
    int coachID,
    String coachName,
    String? coachAvatar,
    String? coachSpeciality,
  ) async {
    try {
      final res = await http
          .get(
            Uri.parse(
                '$baseUrl/conversations?userID=${widget.clientID}&coachID=$coachID&role=client'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List convs = jsonDecode(res.body);
        final match = convs.firstWhere(
          (c) => c['coachID'] == coachID,
          orElse: () => null,
        );

        if (match != null) {
          if (!mounted) return;
          await Navigator.push(
            context,
            _fadeSlide(
              ClientConversationScreen(
                conversationID: match['id'],
                clientID: widget.clientID,
                token: widget.token,
                coachName: coachName,
                coachAvatar: coachAvatar,
                coachSpeciality: coachSpeciality,
              ),
            ),
          );
          _fetchUnreadMessagesCount();
        } else {
          final createRes = await http
              .post(
                Uri.parse('$baseUrl/conversations/find-or-create'),
                headers: _headers,
                body: jsonEncode({
                  'clientID': widget.clientID,
                  'coachID': coachID,
                }),
              )
              .timeout(const Duration(seconds: 10));

          if (createRes.statusCode == 201) {
            final newConv = jsonDecode(createRes.body);
            if (!mounted) return;
            await Navigator.push(
              context,
              _fadeSlide(
                ClientConversationScreen(
                  conversationID: newConv['id'],
                  clientID: widget.clientID,
                  token: widget.token,
                  coachName: coachName,
                  coachAvatar: coachAvatar,
                  coachSpeciality: coachSpeciality,
                ),
              ),
            );
            _fetchUnreadMessagesCount();
          }
        }
      }
    } catch (_) {}
  }

  void _openCoachDetail(CoachModel coach) {
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
      location: '',
      status: 'pending',
      price: 0,
      companyName: '',
    );
    Navigator.push(
      context,
      _fadeSlide(
        CoachDetailScreen(
          session: session,
          token: widget.token,
          clientID: widget.clientID,
        ),
      ),
    );
  }

  void _openCompanyDetail(_AdvisorItem advisor) {
    Navigator.push(
      context,
      _fadeSlide(
        CompanyDetailScreen(
          advisorId: advisor.id,
          accessToken: widget.token,
          clientID: widget.clientID,
        ),
      ),
    );
  }

  PageRouteBuilder _fadeSlide(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 400),
      );


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
          IndexedStack(
            index: _navIndex,
            children: [
              _buildHomeBody(),
              DiscoverScreen(clientID: widget.clientID, token: widget.token),
              SessionsScreen(clientID: widget.clientID, token: widget.token),
              ClientProfileScreen(
                clientID: widget.clientID,
                token: widget.token,
                onLogout: widget.onLogout,
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }


  Widget _buildHomeBody() {
    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: context.fitlek.card,
      onRefresh: () async {
        await Future.wait([
          _fetchCoaches(),
          _fetchAdvisors(),
          _fetchCategories(),
          _fetchFavorites(),
          _fetchUnreadMessagesCount(),
          _fetchUpcomingSessions(),
        ]);
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeroBanner()),
          SliverToBoxAdapter(child: _buildQuickActions()),
          SliverToBoxAdapter(
            child: _sectionHeader(
              'Recommended for You',
              onSeeAll: () => setState(() => _navIndex = 1),
            ),
          ),
          SliverToBoxAdapter(child: _buildCategoryPills()),
          SliverToBoxAdapter(child: _buildCoachList()),
          if (_upcomingSessions.isNotEmpty || _loadingSessions) ...[
            SliverToBoxAdapter(
              child: _sectionHeader(
                'Upcoming Sessions',
                onSeeAll: () => setState(() => _navIndex = 2),
              ),
            ),
            SliverToBoxAdapter(child: _buildUpcomingSessions()),
          ],
          SliverToBoxAdapter(
            child: _sectionHeader(
              'Coaching companies',
              onSeeAll: () => setState(() => _navIndex = 1),
            ),
          ),
          SliverToBoxAdapter(child: _buildAdvisorList()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }


  Widget _buildHeroBanner() {
    return Stack(
      children: [
        SizedBox(
          height: 420,
          width: double.infinity,
          child: Image.asset(
            'assets/branding/hero.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF0D1F1A),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.82),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
                stops: const [0.0, 0.35, 0.75, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: _buildHeader(),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your\nGoals.\nOur Coaches.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Find the right coach, book a\nsession and start your journey.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.80),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => setState(() => _navIndex = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Find your coach',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 17,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SirvyaLogo(variant: SirvyaLogoVariant.wordmark, height: 18),
              const SizedBox(height: 2),
              Text(
                'TRAIN • CONNECT • PROGRESS',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_clientVille != null && _clientVille!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_rounded,
                      color: Theme.of(context).colorScheme.primary, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    _clientVille!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.white70, size: 14),
                ],
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
  onTap: () async {
    await Navigator.push(
      context,
      _fadeSlide(
        ClientConversationsListScreen(
          clientID: widget.clientID,
          token: widget.token,
        ),
      ),
    );
    _fetchUnreadMessagesCount();
  },
  child: Stack(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: const Icon(
          Icons.chat_bubble_outline_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
      if (_unreadMessagesCount > 0)
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _unreadMessagesCount > 9 ? '9+' : '$_unreadMessagesCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
    ],
  ),
),
const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                _fadeSlide(const ClientNotificationsScreen()),
              );
            },
            child: Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (_unreadMessagesCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2),
                      ),
                      child: Center(
                        child: Text(
                          _unreadMessagesCount > 9
                              ? '9+'
                              : '$_unreadMessagesCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildQuickActions() {
    final actions = [
      (Icons.calendar_today_rounded, 'Book a\nSession', () {
        Navigator.push(
          context,
          _fadeSlide(
            DiscoverScreen(clientID: widget.clientID, token: widget.token),
          ),
        );
      }),
      (Icons.person_search_rounded, 'Find a\nCoach', () {
        setState(() => _navIndex = 1);
      }),
      (Icons.location_on_rounded, 'Gyms\nNear You', () {
      }),
      (Icons.qr_code_scanner_rounded, 'Scan\nQR', () {
        Navigator.push(
          context,
          _fadeSlide(ClientQrScannerScreen()),
        );
      }),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: actions.asMap().entries.map((entry) {
          final i = entry.key;
          final a = entry.value;
          return Expanded(
            child: GestureDetector(
              onTap: a.$3,
              child: Container(
                margin: EdgeInsets.only(right: i < actions.length - 1 ? 10 : 0),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: context.fitlek.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.fitlek.border, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      a.$1,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 24,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      a.$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }


  Widget _sectionHeader(String title, {VoidCallback? onSeeAll}) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            if (onSeeAll != null)
              GestureDetector(
                onTap: onSeeAll,
                child: Row(
                  children: [
                    Text(
                      'See all',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded,
                        color: Theme.of(context).colorScheme.primary, size: 16),
                  ],
                ),
              ),
          ],
        ),
      );


  Widget _buildCategoryPills() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final isSelected = isAll
              ? _selectedCategoryId == null
              : _selectedCategoryId == _categories[index - 1].id;
          final label = isAll ? 'All' : _categories[index - 1].name;

          return GestureDetector(
            onTap: () => _selectCategory(isAll ? null : _categories[index - 1].id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : context.fitlek.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : context.fitlek.border,
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : context.fitlek.textMuted,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildCoachList() {
    if (_loadingCoaches) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SizedBox(
          height: 290,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (_, __) => Container(
              width: 165,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: context.fitlek.card,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      );
    }

    if (_coachError != null || _coaches.isEmpty) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        child: Text(
          _coachError ?? 'No coaches available',
          style: TextStyle(color: context.fitlek.textMuted, fontSize: 13),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 290,
        child: ListView.builder(
          padding: const EdgeInsets.only(left: 16),
          scrollDirection: Axis.horizontal,
          itemCount: _coaches.length,
          itemBuilder: (_, i) => _CoachCard(
            coach: _coaches[i],
            isFavorite: _favoriteCoachIds.contains(_coaches[i].id),
            avgRating: _coachAvgRatings[_coaches[i].id] ?? 0.0,
            reviewCount: _coachReviewCounts[_coaches[i].id] ?? 0,
            onTap: () => _openCoachDetail(_coaches[i]),
            onFavorite: () => _toggleFavorite(_coaches[i].id),
          ),
        ),
      ),
    );
  }


  Widget _buildUpcomingSessions() {
    if (_loadingSessions) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: context.fitlek.card,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _upcomingSessions.map((s) => _buildSessionTile(s)).toList(),
      ),
    );
  }

  Widget _buildSessionTile(_UpcomingSession s) {
    final now = DateTime.now();
    final diff = s.sessionStart.difference(now);
    final String whenLabel;
    if (diff.inDays == 0) {
      whenLabel = 'Today • ${_fmt(s.sessionStart)}';
    } else if (diff.inDays == 1) {
      whenLabel = 'Tomorrow • ${_fmt(s.sessionStart)}';
    } else {
      whenLabel = '${_fmtDate(s.sessionStart)} • ${_fmt(s.sessionStart)}';
    }

    return GestureDetector(
      onTap: () => setState(() => _navIndex = 2),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.fitlek.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.fitlek.border, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: context.fitlek.card2,
                image: s.coachAvatar != null && s.coachAvatar!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(s.coachAvatar!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: s.coachAvatar == null || s.coachAvatar!.isEmpty
                  ? Icon(Icons.person_rounded,
                      color: context.fitlek.textMuted, size: 24)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.sessionTitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'With ${s.coachName}',
                    style: TextStyle(
                      color: context.fitlek.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          color: context.fitlek.textMuted, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        whenLabel,
                        style: TextStyle(
                          color: context.fitlek.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (s.location.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            color: context.fitlek.textMuted, size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            s.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.fitlek.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: context.fitlek.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _fmtDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }


  Widget _buildAdvisorList() {
    if (_loadingAdvisors) {
      return SizedBox(
        height: 240,
        child: ListView.builder(
          padding: const EdgeInsets.only(left: 16),
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (_, __) => Container(
            width: 190,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: context.fitlek.card,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }

    if (_advisorError != null || _advisors.isEmpty) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        child: Text(
          _advisorError ?? 'No companies available',
          style: TextStyle(color: context.fitlek.textMuted, fontSize: 13),
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _advisors.length,
        itemBuilder: (_, i) => _CompanyCard(
          advisor: _advisors[i],
          onTap: () => _openCompanyDetail(_advisors[i]),
        ),
      ),
    );
  }


  Widget _buildNavBar() {
    const items = [
      (Icons.home_rounded, 'Home'),
      (Icons.search_rounded, 'Explore'),
      (Icons.calendar_today_rounded, 'Sessions'),
      (Icons.person_rounded, 'Profile'),
    ];

    const leftItems = [0, 1];
    const rightItems = [2, 3];

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          decoration: BoxDecoration(
            color: context.fitlek.card,
            border:
                Border(top: BorderSide(color: context.fitlek.border, width: 1)),
            boxShadow: [
              BoxShadow(
                color: context.fitlek.shadow,
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ...leftItems.map((i) => _buildNavItem(i, items[i])),
              const SizedBox(width: 70),
              ...rightItems.map((i) => _buildNavItem(i, items[i])),
            ],
          ),
        ),
        Positioned(
          top: -8,
          child: GestureDetector(
            onTap: () => setState(() => _navIndex = 0),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: SirvyaLogo(variant: SirvyaLogoVariant.mark, height: 105),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, (IconData, String) item) {
    final active = index == _navIndex;
    return GestureDetector(
      onTap: () => setState(() => _navIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.$1,
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : context.fitlek.navUnselected,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              item.$2,
              style: TextStyle(
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : context.fitlek.navUnselected,
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  final CoachModel coach;
  final bool isFavorite;
  final double avgRating;
  final int reviewCount;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const _CoachCard({
    required this.coach,
    required this.isFavorite,
    required this.avgRating,
    required this.reviewCount,
    required this.onTap,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final double rating = avgRating;
    final bool hasRating = reviewCount > 0;


    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 165,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: context.fitlek.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.fitlek.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: coach.avatarUrl?.isNotEmpty == true
                      ? Image.network(
                          coach.avatarUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, p) => p == null
                              ? child
                              : Container(color: context.fitlek.card2),
                          errorBuilder: (_, __, ___) => _placeholder(context),
                        )
                      : _placeholder(context),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 70,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                     
                         
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onFavorite,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavorite ? Colors.redAccent : Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ),
                if (coach.isPremium)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: context.fitlek.premium,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.black,
                        size: 11,
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coach.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      coach.displaySpecialties,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.fitlek.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: hasRating
                              ? const Color(0xFFF59E0B)
                              : context.fitlek.textMuted,
                          size: 13,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          hasRating ? rating.toStringAsFixed(1) : 'New',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (hasRating)
                          Text(
                            ' ($reviewCount)',
                            style: TextStyle(
                              color: context.fitlek.textMuted,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            color: context.fitlek.textMuted, size: 11),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            coach.ville?.isNotEmpty == true
                                ? coach.ville!
                                : 'Anywhere',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.fitlek.textMuted,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
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

  Widget _placeholder(BuildContext context) => Container(
        color: context.fitlek.card2,
        child: Center(
          child: Text(
            coach.fullName.isNotEmpty ? coach.fullName[0].toUpperCase() : '?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 40,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
}

class _CompanyCard extends StatelessWidget {
  final _AdvisorItem advisor;
  final VoidCallback onTap;

  const _CompanyCard({required this.advisor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final double rating = advisor.rating ?? 0.0;
    final int totalReviews = advisor.totalReviews ?? 0;
    final bool hasRating = totalReviews > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 190,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: context.fitlek.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.fitlek.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: advisor.avatarUrl != null && advisor.avatarUrl!.isNotEmpty
                      ? Image.network(
                          advisor.avatarUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, p) => p == null
                              ? child
                              : Container(color: context.fitlek.card2),
                          errorBuilder: (_, __, ___) => _defaultCover(context),
                        )
                      : _defaultCover(context),
                ),
                if (advisor.coachCount > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${advisor.coachCount} coaches',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            advisor.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (advisor.isApproved)
                          Icon(Icons.verified_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 13),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      advisor.specialty.isNotEmpty ? advisor.specialty : 'Coaching',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.fitlek.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            color: context.fitlek.textMuted, size: 11),
                        const SizedBox(width: 3),
                        Text(
                          advisor.ville?.isNotEmpty == true
                              ? advisor.ville!
                              : 'Morocco',
                          style: TextStyle(
                            color: context.fitlek.textMuted,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                      
                        const SizedBox(width: 3),
                       
                        if (hasRating)
                          Text(
                            ' ($totalReviews reviews)',
                            style: TextStyle(
                              color: context.fitlek.textMuted,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.25),
                            width: 1),
                      ),
                      child: Text(
                        'VIEW COACHES',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
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
    );
  }

  Widget _defaultCover(BuildContext context) => Container(
        color: context.fitlek.card2,
        child: Center(
          child: Icon(
            Icons.business_rounded,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            size: 36,
          ),
        ),
      );
}