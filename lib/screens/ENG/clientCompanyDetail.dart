// ─────────────────────────────────────────────
//  companyDetailScreen.dart
//  GET /advisors          → filtre par advisorId
//  GET /advisors/:id/coaches → coachs de l'advisor
//  GET /advisors/:id/images  → images de la salle
// ─────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fitlek1/models/anas/reservation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'clientCoachDetail.dart';

import '../../theme/fitlek_theme_extension.dart';
// ─── Constants ──────────────────────────────────────────────────────────────
const _baseUrl    = 'http://localhost:3000/api';

// ─── DTOs ────────────────────────────────────────────────────────────────────
class _AdvisorDTO {
  final int     id;
  final String  firstName, lastName, email;
  final String? avatarUrl;
  final String  specialty;
  final String? location;
    final String? ville; 
  final String? companyName;
  final bool    isApproved;

  const _AdvisorDTO({
    required this.id, required this.firstName, required this.lastName,
    required this.email, this.avatarUrl,this.ville,
    required this.specialty, this.location, this.companyName,
    required this.isApproved,
  });

  String get fullName => '$firstName $lastName';

  factory _AdvisorDTO.fromJson(Map<String, dynamic> j) => _AdvisorDTO(
    id:         j['id'] as int,
    firstName:  j['firstName'] ?? '',
    lastName:   j['lastName']  ?? '',
    email:      j['email']     ?? '',
    avatarUrl:  j['avatarUrl'],
       ville:      j['ville'] ?? '',
    specialty:  j['specialty'] ?? j['speciality'] ?? '',
    location:   j['location'],
    companyName: j['companyName'],
    isApproved: j['isApproved'] == 1 || j['isApproved'] == true,
  );
}

class _CoachDTO {
  final int     id;
  final String  firstName, lastName;
  final String? avatarUrl;
  final bool    isPremium;
  final String  bio, instagramPage, invitationCode;
  final int     earnedPoints, totalInvitations;

  const _CoachDTO({
    required this.id, required this.firstName, required this.lastName,
    this.avatarUrl, required this.isPremium,
    required this.bio, required this.instagramPage,
    required this.invitationCode,
    required this.earnedPoints, required this.totalInvitations,
  });

  String get fullName => '$firstName $lastName';

  factory _CoachDTO.fromJson(Map<String, dynamic> j) => _CoachDTO(
    id:               j['id'] ?? j['userID'] ?? 0,
    firstName:        j['firstName'] ?? '',
    lastName:         j['lastName']  ?? '',
    avatarUrl:        j['avatarUrl'],
    isPremium:        j['isPremium'] == 1 || j['isPremium'] == true,
    bio:              j['bio'] ?? '',
    instagramPage:    j['instagramPage'] ?? '',
    invitationCode:   j['invitationCode'] ?? '',
    earnedPoints:     j['earnedPoints']     ?? 0,
    totalInvitations: j['totalInvitations'] ?? 0,
  );
}

class _ImageDTO {
  final int    id;
  final String urlImage;
  const _ImageDTO({required this.id, required this.urlImage});

  factory _ImageDTO.fromJson(Map<String, dynamic> j) => _ImageDTO(
    id:       j['id'] as int,
    urlImage: j['urlImage'] ?? j['UrlImage'] ?? '',
  );
}

// ─────────────────────────────────────────────
//  CompanyDetailScreen
// ─────────────────────────────────────────────
class CompanyDetailScreen extends StatefulWidget {
  final int     advisorId;
  final int     clientID;
  final String? accessToken;

  const CompanyDetailScreen({
    super.key,
    required this.advisorId,
    required this.clientID,
    this.accessToken,
  });

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController    _tabController;
  final ScrollController _scrollCtrl = ScrollController();
  bool _isCollapsed = false;

  _AdvisorDTO?     _advisor;
  List<_CoachDTO>  _coaches = [];
  List<_ImageDTO>  _images  = [];
  bool    _loading = true;
  String? _error;

  static const double _expandedHeight = 260.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollCtrl.addListener(() {
      final collapsed = _scrollCtrl.offset > _expandedHeight - 80;
      if (collapsed != _isCollapsed) setState(() => _isCollapsed = collapsed);
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (widget.accessToken != null) 'Authorization': 'Bearer ${widget.accessToken}',
  };

  // ── API ──────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Charger advisor + coaches + images en parallèle
      final results = await Future.wait([
        http.get(Uri.parse('$_baseUrl/advisors'), headers: _headers),
        http.get(
          Uri.parse('$_baseUrl/advisors/${widget.advisorId}/coaches'),
          headers: _headers,
        ),
        http.get(
          Uri.parse('$_baseUrl/advisors/${widget.advisorId}/images'),
          headers: _headers,
        ),
      ]);

      // ── Advisor ──────────────────────────────────────────────────
      if (results[0].statusCode == 200) {
        final List list = jsonDecode(results[0].body);
        final found = list
            .cast<Map<String, dynamic>>()
            .where((e) => (e['id'] as int) == widget.advisorId)
            .toList();
        if (found.isEmpty) throw Exception('Advisor not found');
        _advisor = _AdvisorDTO.fromJson(found.first);
      } else {
        throw Exception('Error loading advisor (${results[0].statusCode})');
      }

      // ── Coaches ──────────────────────────────────────────────────
      if (results[1].statusCode == 200) {
        final List data = jsonDecode(results[1].body);
        _coaches = data
            .map((e) => _CoachDTO.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      else if (results[1].statusCode != 404) {
        debugPrint('⚠️ Coaches fetch: ${results[1].statusCode}');
      }

      // ── Images ───────────────────────────────────────────────────
      if (results[2].statusCode == 200) {
        final List data = jsonDecode(results[2].body);
        _images = data
            .map((e) => _ImageDTO.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      else if (results[2].statusCode != 404) {
        debugPrint('⚠️ Images fetch: ${results[2].statusCode}');
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  // ── Build ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildSkeleton();
    if (_error != null) return _buildError();

    final a = _advisor!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: Theme.of(context).colorScheme.primary, backgroundColor: context.fitlek.card,
          onRefresh: _loadData,
          child: NestedScrollView(
            controller: _scrollCtrl,
            headerSliverBuilder: (_, __) => [
              _buildSliverAppBar(a),
              SliverToBoxAdapter(child: _buildHeader(a)),
              SliverToBoxAdapter(child: _buildStats()),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(_buildTabBar()),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildCoachesTab(),
                _buildAboutTab(a),
                _buildGalleryTab(),
                _buildLocationTab(a),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── SliverAppBar ─────────────────────────────────────────────────
  SliverAppBar _buildSliverAppBar(_AdvisorDTO a) => SliverAppBar(
    expandedHeight: _expandedHeight,
    floating: false, pinned: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor, elevation: 0,
    leading: GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24)),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
      ),
    ),
    title: AnimatedOpacity(
      opacity: _isCollapsed ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Text(a.fullName, style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w800)),
    ),
    flexibleSpace: FlexibleSpaceBar(
      background: Stack(fit: StackFit.expand, children: [
        a.avatarUrl != null
            ? Image.network(a.avatarUrl!, fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.4),
                colorBlendMode: BlendMode.darken,
                errorBuilder: (_, __, ___) => _defaultCover())
            : _defaultCover(),
        Positioned.fill(child: DecoratedBox(
          decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.transparent, Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.7), Theme.of(context).scaffoldBackgroundColor],
            stops: const [0.25, 0.7, 1.0])))),
        if (a.isApproved)
          Positioned(
            bottom: 16, right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                Icon(Icons.verified_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 12),
                const SizedBox(width: 5),
                Text('VERIFIED', style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary, fontSize: 9,
                  fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              ]),
            )),
      ]),
    ),
  );

  Widget _defaultCover() => Container(
    decoration: BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [context.fitlek.card2, context.fitlek.card])),
    child: Center(child: Icon(Icons.business_rounded,
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15), size: 80)),
  );

  // ── Header ───────────────────────────────────────────────────────
  Widget _buildHeader(_AdvisorDTO a) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2.5),
          boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4))],
          color: context.fitlek.card2),
        clipBehavior: Clip.antiAlias,
        child: a.avatarUrl != null
            ? Image.network(a.avatarUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.business_rounded, color: Theme.of(context).colorScheme.primary, size: 32))
            : Icon(Icons.business_rounded, color: Theme.of(context).colorScheme.primary, size: 32),
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(a.fullName, style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.w900,
          letterSpacing: -0.5, height: 1.1)),
        const SizedBox(height: 6),
        if (a.companyName != null && a.companyName!.isNotEmpty) ...[
          Text(a.companyName!, style: TextStyle(
            color: context.fitlek.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3))),
          child: Text(a.specialty.toUpperCase(), style: TextStyle(
            color: Theme.of(context).colorScheme.primary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        ),
        const SizedBox(height: 6),
        Row(children: [
          Icon(Icons.email_rounded, color: context.fitlek.textMuted, size: 12),
          const SizedBox(width: 5),
          Expanded(child: Text(a.email,
            style: TextStyle(color: context.fitlek.textMuted, fontSize: 11),
            overflow: TextOverflow.ellipsis)),
        ]),
      ])),
    ]),
  );

  // ── Stats ────────────────────────────────────────────────────────
  Widget _buildStats() {
    final totalInv = _coaches.fold<int>(0, (s, c) => s + c.totalInvitations);
    final totalPts = _coaches.fold<int>(0, (s, c) => s + c.earnedPoints);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        _statBox('${_coaches.length}', 'Coachs',     Icons.people_rounded),
        const SizedBox(width: 10),
        _statBox('$totalInv',          'Invitations', Icons.card_giftcard_rounded),
        const SizedBox(width: 10),
        _statBox('$totalPts',          'Points',      Icons.bolt_rounded),
      ]),
    );
  }

  Widget _statBox(String val, String label, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: context.fitlek.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.fitlek.border)),
      child: Column(children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 16),
        const SizedBox(height: 5),
        Text(val, style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w900)),
        Text(label, style: TextStyle(color: context.fitlek.textMuted, fontSize: 9)),
      ]),
    ),
  );

  // ── Tab Bar ──────────────────────────────────────────────────────
  Widget _buildTabBar() => Container(
    color: Theme.of(context).scaffoldBackgroundColor,
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
    child: Container(
      height: 44,
      decoration: BoxDecoration(color: context.fitlek.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.fitlek.border)),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(9)),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Theme.of(context).colorScheme.onPrimary,
        unselectedLabelColor: context.fitlek.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.8),
        tabs: [
          Tab(child: Text('COACHES (${_coaches.length})')),
          const Tab(text: 'ABOUT'),
          Tab(child: Text('GALLERY (${_images.length})')),
          const Tab(text: 'LOCATION'),
        ],
      ),
    ),
  );

  // ── Coaches Tab ──────────────────────────────────────────────────
  Widget _buildCoachesTab() {
    if (_coaches.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.people_outline, color: context.fitlek.textMuted, size: 52),
        const SizedBox(height: 14),
        Text('No coaches linked yet',
          style: TextStyle(color: context.fitlek.textMuted, fontSize: 13)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: _coaches.length,
      itemBuilder: (_, i) => _CoachCard(
        coach: _coaches[i],
        onTap: () => _openCoachDetail(_coaches[i]),
      ),
    );
  }

  // ── Navigate → CoachDetailScreen ─────────────────────────────────
  void _openCoachDetail(_CoachDTO coach) {
    final session = ReservationModel(
      id:              0,
      clientID:        widget.clientID,
      coachID:         coach.id,
      coachName:       coach.fullName,
      coachSpeciality: coach.bio.isNotEmpty
          ? (coach.bio.length > 40 ? '${coach.bio.substring(0, 40)}…' : coach.bio)
          : 'Certified coach',
      coachImageUrl:   coach.avatarUrl ?? '',
      coachRating:     0.0,
      sessionStart:    DateTime.now(),
      sessionEnd:      DateTime.now().add(const Duration(hours: 1)),
      location:        _advisor?.specialty ?? '',
      status:          'pending',
      price:           0.0,
      companyName:     _advisor?.fullName ?? '',
    );

    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => CoachDetailScreen(
        session: session,
        token: widget.accessToken ?? '',
        clientID: widget.clientID,
      ),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child),
      ),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  // ── About Tab ────────────────────────────────────────────────────
  Widget _buildAboutTab(_AdvisorDTO a) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
    children: [
      _sectionLabel('PROFILE', Icons.person_rounded),
      const SizedBox(height: 12),
      _infoTile(Icons.badge_rounded,          'Full name', a.fullName),
      const SizedBox(height: 8),
      _infoTile(Icons.email_rounded,          'Email',       a.email),
      const SizedBox(height: 8),
      _infoTile(Icons.fitness_center_rounded, 'Specialty',  a.specialty),
       if (a.ville != null && a.ville!.isNotEmpty) ...[
      const SizedBox(height: 8),
      _infoTile(Icons.location_city_rounded, 'City', a.ville!),
    ],
      if (a.companyName != null && a.companyName!.isNotEmpty) ...[
        const SizedBox(height: 8),
        _infoTile(Icons.business_rounded, 'Gym name', a.companyName!),
      ],
      if (a.location != null && a.location!.isNotEmpty) ...[
        const SizedBox(height: 8),
        _infoTile(Icons.location_on_rounded, 'Address', a.location!),
      ],
      const SizedBox(height: 24),
      _sectionLabel('STATISTICS', Icons.bar_chart_rounded),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: context.fitlek.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.fitlek.border)),
        child: Column(children: [
          _statRow('Coaches on the team', '${_coaches.length}'),
          _divider(),
          _statRow('Total invitations',
            _coaches.fold<int>(0, (s, c) => s + c.totalInvitations).toString()),
          _divider(),
          _statRow('Total points',
            _coaches.fold<int>(0, (s, c) => s + c.earnedPoints).toString()),
        ]),
      ),
    ],
  );

  Widget _statRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(children: [
      Text(label, style: TextStyle(color: context.fitlek.textSecondary, fontSize: 12)),
      const Spacer(),
      Text(value, style: TextStyle(
        color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800, fontSize: 13)),
    ]),
  );

  Widget _divider() => Divider(height: 1, color: context.fitlek.border);

  // ── Gallery Tab (Images de la salle) ─────────────────────────────
  Widget _buildGalleryTab() {
    if (_images.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.photo_library_outlined, color: context.fitlek.textMuted, size: 52),
        const SizedBox(height: 14),
        Text('No gym images yet',
          style: TextStyle(color: context.fitlek.textMuted, fontSize: 13)),
      ]));
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: _images.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => _showImageFullScreen(_images[i].urlImage),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.fitlek.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            _images[i].urlImage,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: context.fitlek.card2,
              child: Center(
                child: Icon(Icons.broken_image_rounded, color: context.fitlek.textMuted, size: 32),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showImageFullScreen(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(
            child: Image.network(url, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded,
                color: Colors.white24, size: 64),
            ),
          ),
        ),
      ),
    );
  }

  // ── Location Tab (Carte + Adresse) ──────────────────────────────
  Widget _buildLocationTab(_AdvisorDTO a) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _sectionLabel('ADDRESS', Icons.location_on_rounded),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.fitlek.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.fitlek.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (a.companyName != null && a.companyName!.isNotEmpty) ...[
                Text(a.companyName!, style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
              ],
              Text(
                a.location ?? 'Address not provided',
                style: TextStyle(
                  color: a.location != null && a.location!.isNotEmpty
                      ? context.fitlek.textSecondary : context.fitlek.textMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionLabel('MAP', Icons.map_rounded),
        const SizedBox(height: 12),
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: context.fitlek.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.fitlek.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: a.location != null && a.location!.isNotEmpty
                ? _buildMiniMap(a.location!)
                : Container(
                    color: context.fitlek.card2,
                    child: Center(
                      child: Text(
                        'Location not available',
                        style: TextStyle(color: context.fitlek.textMuted, fontSize: 13),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // Mini carte stylisée (sans clé API requise)
  Widget _buildMiniMap(String address) {
    return Container(
      color: context.fitlek.card2,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _MapGridPainter(context.fitlek.textMuted),
            size: const Size(double.infinity, 280),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    _advisor?.companyName ?? 'Gym',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                  size: 36,
                  shadows: [
                    Shadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8)],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: GestureDetector(
              onTap: () => _openMaps(address),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_new_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 14),
                    const SizedBox(width: 6),
                    Text('OPEN', style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary, fontSize: 10,
                      fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openMaps(String address) async {
    final encoded = Uri.encodeComponent(address);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────
  Widget _infoTile(IconData icon, String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(color: context.fitlek.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: context.fitlek.border)),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 16)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: context.fitlek.textMuted, fontSize: 10)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w700)),
      ])),
    ]),
  );

  Widget _sectionLabel(String title, IconData icon) => Row(children: [
    Container(width: 3, height: 16, color: Theme.of(context).colorScheme.primary, margin: const EdgeInsets.only(right: 10)),
    Icon(icon, color: Theme.of(context).colorScheme.primary, size: 15),
    const SizedBox(width: 7),
    Text(title, style: TextStyle(
      color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
  ]);

  // ── Skeleton ─────────────────────────────────────────────────────
  Widget _buildSkeleton() => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    body: SafeArea(child: Column(children: [
      _shimBox(double.infinity, 260),
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          _shimBox(64, 64, radius: 16),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _shimBox(200, 20, radius: 6),
            const SizedBox(height: 8),
            _shimBox(120, 14, radius: 6),
          ])),
        ])),
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: List.generate(3, (i) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
            child: _shimBox(double.infinity, 70, radius: 12)))))),
    ])),
  );

  Widget _buildError() => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    body: SafeArea(child: Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.wifi_off_rounded, color: context.fitlek.textMuted, size: 52),
        const SizedBox(height: 16),
        Text('Loading error',
          style: TextStyle(color: context.fitlek.textSecondary, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(_error ?? '', style: TextStyle(color: context.fitlek.textMuted, fontSize: 12),
          textAlign: TextAlign.center),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _loadData,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(12)),
            child: Text('RETRY', style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ),
        ),
      ])),
    )),
  );

  Widget _shimBox(double w, double h, {double radius = 0}) => Container(
    width:  w == double.infinity ? null : w,
    height: h,
    decoration: BoxDecoration(
      color: context.fitlek.card2,
      borderRadius: BorderRadius.circular(radius)));
}

// ─── Map Grid Painter ──────────────────────────────────────────────────────
class _MapGridPainter extends CustomPainter {
  final Color gridColor;
  _MapGridPainter(this.gridColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor.withValues(alpha: 0.15)
      ..strokeWidth = 1;

    const spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final streetPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.3)
      ..strokeWidth = 2;

    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.3, size.height), streetPaint);
    canvas.drawLine(Offset(0, size.height * 0.6), Offset(size.width, size.height * 0.6), streetPaint);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.7, size.height), streetPaint);
    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.3), streetPaint);
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) =>
      oldDelegate.gridColor != gridColor;
}

// ─── Tab Bar Delegate ────────────────────────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget tabBar;
  _TabBarDelegate(this.tabBar);
  @override double get minExtent => 66;
  @override double get maxExtent => 66;
  @override Widget build(_, __, ___) => tabBar;
  @override bool shouldRebuild(_) => false;
}

// ─── Coach Card ──────────────────────────────────────────────────────────────
class _CoachCard extends StatelessWidget {
  final _CoachDTO    coach;
  final VoidCallback onTap;
  const _CoachCard({required this.coach, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: context.fitlek.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.fitlek.border)),
        clipBehavior: Clip.antiAlias,
        child: Row(children: [
          Stack(children: [
            SizedBox(
              width: 96, height: 110,
              child: coach.avatarUrl != null
                  ? Image.network(coach.avatarUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(context))
                  : _placeholder(context),
            ),
            if (coach.isPremium)
              Positioned(top: 6, right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.fitlek.premium, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                      color: context.fitlek.premium.withValues(alpha: 0.5), blurRadius: 8)]),
                  child: const Icon(Icons.star_rounded, color: Colors.black, size: 10))),
          ]),
          Expanded(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(coach.fullName, style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 14))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(8)),
                  child: Text('VIEW', style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1))),
              ]),
              const SizedBox(height: 6),
              Text(
                coach.bio.isNotEmpty
                    ? (coach.bio.length > 55 ? '${coach.bio.substring(0, 55)}…' : coach.bio)
                    : 'Certified coach',
                style: TextStyle(color: context.fitlek.textMuted, fontSize: 11, height: 1.4),
                maxLines: 2),
              const SizedBox(height: 10),
              Row(children: [
                _chip(context, Icons.card_giftcard_rounded, '${coach.totalInvitations} inv.'),
                const SizedBox(width: 8),
                _chip(context, Icons.bolt_rounded, '${coach.earnedPoints} pts'),
              ]),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _placeholder(BuildContext context) => Container(
    color: context.fitlek.card2,
    child: Center(child: Text(
      coach.firstName.isNotEmpty ? coach.firstName[0] : '?',
      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 32, fontWeight: FontWeight.w900))),
  );

  Widget _chip(BuildContext context, IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2))),
    child: Row(children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary, size: 10),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 9, fontWeight: FontWeight.w700)),
    ]),
  );
}