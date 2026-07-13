import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:fitlek1/models/anas/coach.dart';
import 'package:fitlek1/models/anas/reservation.dart';
import 'clientCoachDetail.dart';
import 'clientCompanyDetail.dart';

import '../../theme/fitlek_theme_extension.dart';

const _baseUrl = 'http://localhost:3000/api';

class _AdvisorItem {
  final int id;
  final String firstName, lastName, email;
  final String? avatarUrl;
  final String specialty;

  const _AdvisorItem({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.avatarUrl,
    required this.specialty,
  });

  String get fullName => '$firstName $lastName';

  factory _AdvisorItem.fromJson(Map<String, dynamic> j) => _AdvisorItem(
        id: j['id'] as int,
        firstName: j['firstName'] ?? '',
        lastName: j['lastName'] ?? '',
        email: j['email'] ?? '',
        avatarUrl: j['avatarUrl'],
        specialty: j['specialty'] ?? j['speciality'] ?? '',
      );
}

class DiscoverScreen extends StatefulWidget {
  final int clientID;
  final String? token;

  const DiscoverScreen({super.key, required this.clientID, this.token});

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
  bool _showFilters = false;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
      };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(
        () => setState(() => _query = _searchCtrl.text.toLowerCase()));
    _fetchCoaches();
    _fetchAdvisors();
  }

  @override
  void dispose() {
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
      final res = await http
          .get(Uri.parse('$_baseUrl/coaches?limit=50'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _coaches = data.map((j) => CoachModel.fromJson(j)).toList();
          _coachesLoading = false;
        });
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
          .get(Uri.parse('$_baseUrl/advisors'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _advisors = data.map((j) => _AdvisorItem.fromJson(j)).toList();
          _advisorsLoading = false;
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

  List<CoachModel> get _filteredCoaches {
    var list = _coaches.where((c) {
      if (_query.isEmpty) return true;
      return c.fullName.toLowerCase().contains(_query) ||
          (c.speciality ?? '').toLowerCase().contains(_query) ||
          c.bio.toLowerCase().contains(_query) ||
          c.invitationCode.toLowerCase().contains(_query);
    }).toList();

    if (_sortBy == 'name') {
      list.sort((a, b) => a.fullName.compareTo(b.fullName));
    } else {
      list.sort((a, b) => b.earnedPoints.compareTo(a.earnedPoints));
    }
    return list;
  }

  List<_AdvisorItem> get _filteredAdvisors {
    return _advisors.where((a) {
      if (_query.isEmpty) return true;
      return a.fullName.toLowerCase().contains(_query) ||
          a.specialty.toLowerCase().contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          _buildSearchBar(),
          _buildTabBar(),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _showFilters ? _buildFilterPanel() : const SizedBox.shrink(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildCoachTab(), _buildAdvisorTab()],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildSearchBar() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
              color: context.fitlek.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.fitlek.border)),
          child: Row(children: [
            const SizedBox(width: 16),
            Icon(Icons.search_rounded,
                color: context.fitlek.textMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search a coach or company...',
                  hintStyle: TextStyle(
                      color: context.fitlek.textSecondary, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _showFilters = !_showFilters),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: _showFilters
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.tune_rounded,
                    color: _showFilters
                        ? Theme.of(context).colorScheme.onPrimary
                        : context.fitlek.textMuted,
                    size: 18),
              ),
            ),
            if (_query.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                },
                child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Icon(Icons.close_rounded,
                        color: context.fitlek.textMuted, size: 18)),
              ),
          ]),
        ),
      );

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
          ]),
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

  Widget _buildCoachTab() {
    if (_coachesLoading) return _shimmerList();
    if (_coachesError != null) return _errorView(_coachesError!, _fetchCoaches);
    final list = _filteredCoaches;
    if (list.isEmpty) return _emptyView('No coaches found');

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
    if (list.isEmpty) return _emptyView('No companies found');

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
              style: TextStyle(color: context.fitlek.textMuted, fontSize: 14)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() {
              _searchCtrl.clear();
              _query = '';
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

  const _CoachCard({required this.coach, required this.clientID, this.token});

  @override
  State<_CoachCard> createState() => _CoachCardState();
}

class _CoachCardState extends State<_CoachCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final avatar = widget.coach.avatarUrl ?? '';
    final hasAvatar = avatar.isNotEmpty;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        final session = ReservationModel(
          id: 0,
          clientID: widget.clientID,
          coachID: widget.coach.id,
          coachName: widget.coach.fullName,
          coachSpeciality: widget.coach.speciality ?? '',
          coachImageUrl: avatar,
          coachRating: widget.coach.rating ?? 0.0,
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
            ));
      },
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
                hasAvatar
                    ? Hero(
                        tag: 'coach_avatar_${widget.coach.id}',
                        child: Image.network(avatar,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _namePlaceholder(widget.coach.firstName)),
                      )
                    : _namePlaceholder(widget.coach.firstName),
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
                    right: widget.coach.rating != null ? 90 : 14,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.coach.fullName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5)),
                          if ((widget.coach.speciality ?? '').isNotEmpty)
                            Text(widget.coach.speciality!,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                        ])),
                if (widget.coach.rating != null)
                  Positioned(
                      bottom: 12,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(children: [
                          Icon(Icons.star_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 14),
                          const SizedBox(width: 4),
                          Text(widget.coach.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800)),
                        ]),
                      )),
                if (widget.coach.isPremium)
                  Positioned(
                      top: 10,
                      right: 12,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                            color: context.fitlek.premium,
                            borderRadius: BorderRadius.circular(20)),
                        child: const Row(children: [
                          Icon(Icons.star_rounded,
                              color: Colors.black, size: 10),
                          SizedBox(width: 4),
                          Text('PREMIUM',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1)),
                        ]),
                      )),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.coach.bio.isNotEmpty)
                      Text(widget.coach.bio,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: context.fitlek.textSecondary,
                              fontSize: 12,
                              height: 1.5)),
                    const SizedBox(height: 12),
                    _buildPriceTelRow(),
                    const SizedBox(height: 12),
                    Row(children: [
                      _chip(Icons.bolt_rounded,
                          '${widget.coach.earnedPoints} pts'),
                      const SizedBox(width: 8),
                      _chip(Icons.card_giftcard_rounded,
                          '${widget.coach.totalInvitations} inv.'),
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

  Widget _buildPriceTelRow() {
    final hasTel =
        widget.coach.tel != null && widget.coach.tel!.trim().isNotEmpty;
    final hasCode = widget.coach.invitationCode.trim().isNotEmpty;

    if (!hasTel && !hasCode) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (hasCode)
          GestureDetector(
            onTap: () {
              Clipboard.setData(
                  ClipboardData(text: widget.coach.invitationCode));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Code copied',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w700)),
                  backgroundColor: Colors.amber,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.qr_code_rounded,
                      color: Colors.amber, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    widget.coach.invitationCode,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.content_copy_rounded,
                      color: Colors.amber, size: 9),
                ],
              ),
            ),
          ),
        if (hasTel)
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.coach.tel!));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Number copied',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w700)),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.fitlek.card2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.fitlek.border,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_rounded,
                      color: context.fitlek.textMuted, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    widget.coach.tel!,
                    style: TextStyle(
                      color: context.fitlek.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.content_copy_rounded,
                      color: context.fitlek.textMuted, size: 9),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _namePlaceholder(String firstName) => Container(
        color: context.fitlek.card2,
        child: Center(
            child: Text(firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 56,
                    fontWeight: FontWeight.w900))),
      );

  Widget _chip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.2))),
        child: Row(children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
        ]),
      );
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
