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

import '../../theme/fitlek_theme_extension.dart';
import '../../components/sirvya_logo.dart';
import '../../constants/app_colors.dart';

// ─── Advisor DTO ────────────────────────────────────────────────────────────
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

// ─── Category DTO ───────────────────────────────────────────────────────────
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

// ─── Icon mapper ────────────────────────────────────────────────────────────
IconData _mapCategoryIcon(String iconName) {
  switch (iconName) {
    case 'fitness_center':
      return Icons.fitness_center_rounded; // All
    case 'monitor_weight':
      return Icons.monitor_weight_rounded; // Perte de poids
    case 'self_improvement':
      return Icons.self_improvement_rounded; // Yoga
    case 'sports_gymnastics':
      return Icons.sports_gymnastics_rounded; // CrossFit
    case 'sports_mma':
      return Icons.sports_martial_arts_rounded; // Boxe / MMA
    case 'restaurant':
      return Icons.apple; // Nutrition
    case 'accessibility_new':
      return Icons.sports_gymnastics_rounded; // Musculation (closest to bicep in Material)
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

// ═══════════════════════════════════════════════════════════════════════════════
//  HOME SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
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

  // Data
  List<CoachModel> _coaches = [];
  List<CoachModel> _allCoaches = [];
  List<_AdvisorItem> _advisors = [];
  List<_CategoryItem> _categories = [
    const _CategoryItem(id: 1, name: 'Musculation', icon: 'accessibility_new'),
    const _CategoryItem(id: 2, name: 'Perte de poids', icon: 'monitor_weight'),
    const _CategoryItem(id: 3, name: 'Yoga', icon: 'self_improvement'),
    const _CategoryItem(id: 4, name: 'CrossFit', icon: 'sports_gymnastics'),
    const _CategoryItem(id: 5, name: 'Boxe', icon: 'sports_mma'),
    const _CategoryItem(id: 6, name: 'Nutrition', icon: 'restaurant'),
  ];
  Set<int> _favoriteCoachIds = {};
  String? _avatarUrl;
  String? _clientVille;
  int _unreadMessagesCount = 0;

  // Loading states
  bool _loadingCoaches = true;
  bool _loadingAdvisors = true;
  bool _loadingCategories = false;
  String? _coachError;
  String? _advisorError;

  // Selected filter
  int? _selectedCategoryId; // null = "All"

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
  }

  // ─── Data fetching ──────────────────────────────────────────────────────────

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
    // Optimistic update
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
      // Revert on failure
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

  // ─── Navigation ─────────────────────────────────────────────────────────────

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

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background gradient
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

  // ─── HOME BODY ──────────────────────────────────────────────────────────────

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
        ]);
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildTopSection()),
          SliverToBoxAdapter(child: _buildCategoryPills()),
          SliverToBoxAdapter(
            child: _sectionHeader(
              'Recommended coaches',
              onSeeAll: () => setState(() => _navIndex = 1),
            ),
          ),
          SliverToBoxAdapter(child: _buildCoachList()),
          SliverToBoxAdapter(
            child: _sectionHeader(
              'Coaching companies',
              onSeeAll: () => setState(() => _navIndex = 1),
            ),
          ),
          SliverToBoxAdapter(child: _buildAdvisorList()),
          SliverToBoxAdapter(child: _buildFindMyCoachCTA()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // ─── 1. HEADER ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo + tagline
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SirvyaLogo(variant: SirvyaLogoVariant.wordmark, height: 18),
              const SizedBox(height: 2),
              Text(
                'TRAIN • CONNECT • PROGRESS',
                style: TextStyle(
                  color: context.fitlek.textMuted,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Location chip
          if (_clientVille != null && _clientVille!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.fitlek.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.fitlek.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_rounded,
                      color: Theme.of(context).colorScheme.primary, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    _clientVille!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 10),
          // Messages icon
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
                    color: context.fitlek.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.fitlek.border),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
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
                        color: context.fitlek.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.fitlek.card, width: 2),
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
          // Notification bell
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                _fadeSlide(
                  const ClientNotificationsScreen(),
                ),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.fitlek.card,
                shape: BoxShape.circle,
                border: Border.all(color: context.fitlek.border),
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: Theme.of(context).colorScheme.onSurface,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Profile Picture
          GestureDetector(
            onTap: () {
              setState(() => _navIndex = 3);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: context.fitlek.border),
                image: _avatarUrl != null && _avatarUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(_avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _avatarUrl == null || _avatarUrl!.isEmpty
                  ? Icon(Icons.person, color: context.fitlek.textMuted, size: 20)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Stack(
      children: [
        // Background image covering the top
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/branding/hero.png'),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            foregroundDecoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.6),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
          ),
        ),
        // Content
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SafeArea(bottom: false, child: _buildHeader()),
            const SizedBox(height: 30),
            _buildHeroText(),
            const SizedBox(height: 24),
            _buildSearchBar(),
            const SizedBox(height: 16),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Find your\ncoach',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Real people. Real results.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Transform.rotate(
              angle: -0.12,
              child: Text(
                'A stronger\nyou',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  fontStyle: FontStyle.italic,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3. SEARCH BAR ─────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => setState(() => _navIndex = 1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: context.fitlek.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.fitlek.border, width: 1),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(
                Icons.search_rounded,
                color: context.fitlek.textMuted,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Search coaches, gyms, or specialties...',
                style: TextStyle(
                  color: context.fitlek.textMuted,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 4. CATEGORY PILLS ─────────────────────────────────────────────────────

  Widget _buildCategoryPills() {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: SizedBox(
        height: 80,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length + 1, // +1 for "All"
          itemBuilder: (context, index) {
            final isAll = index == 0;
            final isSelected = isAll
                ? _selectedCategoryId == null
                : _selectedCategoryId == _categories[index - 1].id;

            final IconData icon;
            final String label;
            if (isAll) {
              icon = Icons.grid_view_rounded;
              label = 'All';
            } else {
              final cat = _categories[index - 1];
              icon = _mapCategoryIcon(cat.icon);
              label = cat.name;
            }

            return GestureDetector(
              onTap: () => _selectCategory(isAll ? null : _categories[index - 1].id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 72,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : context.fitlek.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : context.fitlek.border,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : context.fitlek.textMuted,
                      size: 24,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : context.fitlek.textMuted,
                        fontSize: 9,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── SECTION HEADER ─────────────────────────────────────────────────────────

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
                      'SEE ALL',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded,
                        color: Theme.of(context).colorScheme.primary, size: 14),
                  ],
                ),
              ),
          ],
        ),
      );

  // ─── 5. COACH LIST (Horizontal) ────────────────────────────────────────────

  Widget _buildCoachList() {
    if (_loadingCoaches) {
      return SizedBox(
        height: 290,
        child: ListView.builder(
          padding: const EdgeInsets.only(left: 16),
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (_, __) => Container(
            width: 200,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: context.fitlek.card,
              borderRadius: BorderRadius.circular(14),
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

    return SizedBox(
      height: 300,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _coaches.length,
        itemBuilder: (_, i) => _CoachCard(
          coach: _coaches[i],
          isFavorite: _favoriteCoachIds.contains(_coaches[i].id),
          onTap: () => _openCoachDetail(_coaches[i]),
          onFavorite: () => _toggleFavorite(_coaches[i].id),
        ),
      ),
    );
  }

  // ─── 6. ADVISOR / COMPANY LIST (Horizontal) ────────────────────────────────

  Widget _buildAdvisorList() {
    if (_loadingAdvisors) {
      return SizedBox(
        height: 240,
        child: ListView.builder(
          padding: const EdgeInsets.only(left: 16),
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (_, __) => Container(
            width: 200,
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

  // ─── 7. FIND MY COACH CTA ──────────────────────────────────────────────────

  Widget _buildFindMyCoachCTA() {
    return GestureDetector(
      onTap: () => setState(() => _navIndex = 1),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.fitlek.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.fitlek.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.route_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Not sure who to choose?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Tell us your goal and we'll suggest the best coaches for you.",
                    style: TextStyle(
                      color: context.fitlek.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'FIND MY COACH',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── NAVBAR ─────────────────────────────────────────────────────────────────

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

// ═══════════════════════════════════════════════════════════════════════════════
//  COACH CARD (Redesigned for mockup)
// ═══════════════════════════════════════════════════════════════════════════════
class _CoachCard extends StatelessWidget {
  final CoachModel coach;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const _CoachCard({
    required this.coach,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
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
            // ── Image + Overlays ──
            Stack(
              children: [
                SizedBox(
                  height: 150,
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
                // Bottom gradient
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 60,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ),
                // Premium badge
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
                // Favorite heart
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onFavorite,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavorite
                            ? Colors.redAccent
                            : Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                // Name on image
                Positioned(
                  left: 10,
                  bottom: 8,
                  right: 40,
                  child: Text(
                    coach.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // ── Info section ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Specialty tags
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
                    // Location
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
                    const SizedBox(height: 4),
                    // Rating
                    Row(
                      children: [
                        Icon(Icons.star_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 13),
                        const SizedBox(width: 3),
                        Text(
                          (coach.rating ?? 5.0).toStringAsFixed(1),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          ' (${coach.reviewCount ?? 12} reviews)',
                          style: TextStyle(
                            color: context.fitlek.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // VIEW PROFILE button
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 7),
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
                        'VIEW PROFILE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 1.5,
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

// ═══════════════════════════════════════════════════════════════════════════════
//  COMPANY CARD (Horizontal scrollable — matching mockup)
// ═══════════════════════════════════════════════════════════════════════════════
class _CompanyCard extends StatelessWidget {
  final _AdvisorItem advisor;
  final VoidCallback onTap;

  const _CompanyCard({required this.advisor, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
            // Image + Coach count badge
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
            // Info
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
                        Icon(Icons.star_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 12),
                        const SizedBox(width: 3),
                        Text(
                          (advisor.rating ?? 4.8).toStringAsFixed(1),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          ' (${advisor.totalReviews ?? 24} reviews)',
                          style: TextStyle(
                            color: context.fitlek.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // VIEW COACHES button
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