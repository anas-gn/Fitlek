import 'clientConversation.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'clientConversationList.dart';

import 'package:fitlek1/models/anas/reservation.dart';
import 'package:fitlek1/models/anas/coach.dart';

import 'clientCoachDetail.dart';
import 'clientCompanyDetail.dart';
import 'clientSessions.dart';
import 'clientList.dart';
import 'clientProfil.dart';

const _lime = Color(0xFFC6F135);
const _dark = Color(0xFF0A0A0A);
const _card = Color(0xFF141414);
const _cardBorder = Color(0xFF232323);
const _baseUrl = 'http://localhost:3000/api';

class _FitlekLogoPainter extends CustomPainter {
  final Color strokeColor;
  final Color circleColor;

  const _FitlekLogoPainter({required this.strokeColor, required this.circleColor});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 132;
    final scaleY = size.height / 120;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    canvas.drawCircle(const Offset(65.6104, 17.25), 17.25, Paint()..color = circleColor);

    final path = Path()
      ..moveTo(5.8103, 21.85)
      ..cubicTo(19.2827, 35.9, 45.0007, 47.25, 64.4603, 47.7336)
      ..moveTo(125.41, 21.85)
      ..cubicTo(112.388, 36.0329, 83.709, 48.212, 64.4603, 47.7336)
      ..moveTo(64.4603, 47.7336)
      ..lineTo(64.4603, 106.95)
      ..cubicTo(87.8436, 95.8333, 128.4, 73.37, 103.56, 72.45)
      ..cubicTo(78.7203, 71.53, 36.477, 72.0666, 18.4603, 72.45);

    canvas.drawPath(
      path,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16.1
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FitlekLogoPainter oldDelegate) => false;
}

class _FitlekLogo extends StatelessWidget {
  final double height;
  const _FitlekLogo({this.height = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: height * 132 / 120,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: _lime.withOpacity(0.25),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _FitlekLogoPainter(strokeColor: Colors.white, circleColor: _lime),
      ),
    );
  }
}

class _AdvisorItem {
  final int id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String specialty;
  final bool isApproved;

  const _AdvisorItem({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    required this.specialty,
    required this.isApproved,
  });

  String get fullName => '$firstName $lastName';

  factory _AdvisorItem.fromJson(Map<String, dynamic> j) => _AdvisorItem(
        id: j['id'],
        firstName: j['firstName'] ?? '',
        lastName: j['lastName'] ?? '',
        avatarUrl: j['avatarUrl'],
        specialty: j['specialty'] ?? j['speciality'] ?? '',
        isApproved: j['isApproved'] == 1 || j['isApproved'] == true,
      );
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
  List<_AdvisorItem> _advisors = [];
  ReservationModel? _nextSession;
  String? _avatarUrl;

  bool _loadingCoaches = true;
  bool _loadingAdvisors = true;
  bool _loadingSession = true;
  String? _coachError;
  String? _advisorError;

  int _totalSessions = 0;
  int _confirmedSessions = 0;
  int _pendingSessions = 0;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      };

  @override
  void initState() {
    super.initState();
    _fetchCoaches();
    _fetchAdvisors();
    _fetchReservations();
    _fetchClientProfile();
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
                '$_baseUrl/conversations?userID=${widget.clientID}&coachID=$coachID&role=client'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (data.isNotEmpty) {
          final conv = data.first;
          Navigator.push(
            context,
            _fadeSlide(
              ClientConversationScreen(
                conversationID: conv['id'],
                clientID: widget.clientID,
                token: widget.token,
                coachName: coachName,
                coachAvatar: coachAvatar,
                coachSpeciality: coachSpeciality,
              ),
            ),
          );
        } else {
          final createRes = await http
              .post(
                Uri.parse('$_baseUrl/conversations'),
                headers: _headers,
                body: jsonEncode({
                  'coachID': coachID,
                  'clientID': widget.clientID,
                }),
              )
              .timeout(const Duration(seconds: 10));

          if (createRes.statusCode == 201) {
            final newConv = jsonDecode(createRes.body);
            Navigator.push(
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
          }
        }
      }
    } catch (_) {}
  }

  Widget _buildMessagesBanner() {
    final int totalUnread = 3;
    final bool hasUnread = totalUnread > 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          _fadeSlide(
            ClientConversationsListScreen(
              clientID: widget.clientID,
              token: widget.token,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasUnread ? _lime.withOpacity(0.3) : _cardBorder,
            width: 1,
          ),
          boxShadow: hasUnread
              ? [
                  BoxShadow(
                    color: _lime.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: hasUnread
                        ? _lime.withOpacity(0.12)
                        : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.chat_bubble_rounded,
                    color: hasUnread ? _lime : Colors.white.withOpacity(0.3),
                    size: 22,
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5252),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _card, width: 2),
                      ),
                      child: Text(
                        totalUnread > 99 ? '99+' : '$totalUnread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Messagerie',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Discutez avec vos coachs',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _lime,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'OUVRIR',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchClientProfile() async {
    try {
      final res = await http
          .get(
            Uri.parse('$_baseUrl/clients/me?userID=${widget.clientID}'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (mounted) setState(() => _avatarUrl = data['avatarUrl'] as String?);
      }
    } catch (_) {}
  }

  Future<void> _fetchCoaches() async {
    setState(() {
      _loadingCoaches = true;
      _coachError = null;
    });
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/coaches?limit=10'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _coaches = data
              .map((e) => CoachModel.fromJson(e as Map<String, dynamic>))
              .toList();
          _loadingCoaches = false;
        });
      } else {
        setState(() {
          _coachError = 'Erreur (${res.statusCode})';
          _loadingCoaches = false;
        });
      }
    } catch (_) {
      setState(() {
        _coachError = 'Serveur inaccessible';
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
          .get(Uri.parse('$_baseUrl/advisors'), headers: _headers)
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
          _advisorError = 'Erreur (${res.statusCode})';
          _loadingAdvisors = false;
        });
      }
    } catch (_) {
      setState(() {
        _advisorError = 'Serveur inaccessible';
        _loadingAdvisors = false;
      });
    }
  }

  Future<void> _fetchReservations() async {
    setState(() => _loadingSession = true);
    try {
      final res = await http
          .get(
            Uri.parse(
              '$_baseUrl/reservations?userID=${widget.clientID}&role=client',
            ),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        final reservations = data
            .map((e) => ReservationModel.fromJson(e as Map<String, dynamic>))
            .toList();

        final now = DateTime.now();
        final upcoming = reservations
            .where((r) => r.isUpcoming && r.sessionStart.isAfter(now))
            .toList()
          ..sort((a, b) => a.sessionStart.compareTo(b.sessionStart));

        setState(() {
          _nextSession = upcoming.isNotEmpty ? upcoming.first : null;
          _totalSessions = reservations.length;
          _confirmedSessions = reservations.where((r) => r.isConfirmed).length;
          _pendingSessions = reservations.where((r) => r.isPending).length;
          _loadingSession = false;
        });
      } else {
        setState(() => _loadingSession = false);
      }
    } catch (_) {
      setState(() => _loadingSession = false);
    }
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
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 400),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      body: IndexedStack(
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
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildHomeBody() {
    return SafeArea(
      child: RefreshIndicator(
        color: _lime,
        backgroundColor: _card,
        onRefresh: () async {
          await Future.wait([
            _fetchCoaches(),
            _fetchAdvisors(),
            _fetchReservations(),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildStatsRow()),
            SliverToBoxAdapter(child: _buildSessionBanner()),
            SliverToBoxAdapter(child: _buildMessagesBanner()),
            SliverToBoxAdapter(
              child: _sectionHeader(
                'Coachs recommandés',
                onSeeAll: () => setState(() => _navIndex = 1),
              ),
            ),
            SliverToBoxAdapter(child: _buildCoachList()),
            SliverToBoxAdapter(
              child: _sectionHeader(
                'Sociétés de coaching',
                onSeeAll: () => setState(() => _navIndex = 1),
              ),
            ),
            SliverToBoxAdapter(child: _buildAdvisorList()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _FitlekLogo(height: 40),
          const SizedBox(width: 10),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'FIT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _lime,
                    letterSpacing: 2.5,
                  ),
                ),
                TextSpan(
                  text: 'LEK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Bonjour,',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              Text(
                widget.firstName != null ? '${widget.firstName}' : 'Bienvenue',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => _navIndex = 3),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _lime, width: 2),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF1A1A1A),
                backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                    ? NetworkImage(_avatarUrl!)
                    : null,
                child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                    ? Text(
                        widget.firstName != null && widget.firstName!.isNotEmpty
                            ? widget.firstName![0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: _lime,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => setState(() => _navIndex = 1),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _cardBorder, width: 1),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(
                Icons.search_rounded,
                color: Colors.white.withOpacity(0.3),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Rechercher coachs, salles…',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _lime,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.black,
                  size: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    if (_loadingSession) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
        child: Row(
          children: List.generate(
            3,
            (_) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                height: 72,
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final stats = [
      {
        'label': 'Total séances',
        'value': '$_totalSessions',
        'icon': Icons.bolt_rounded,
        'color': _lime,
      },
      {
        'label': 'Confirmées',
        'value': '$_confirmedSessions',
        'icon': Icons.check_circle_rounded,
        'color': const Color(0xFF4CAF50),
      },
      {
        'label': 'En attente',
        'value': '$_pendingSessions',
        'icon': Icons.hourglass_top_rounded,
        'color': const Color(0xFFFFB74D),
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: Row(
        children: stats.asMap().entries.map((e) {
          final color = e.value['color'] as Color;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _navIndex = 2),
              child: Container(
                margin: EdgeInsets.only(
                  right: e.key < stats.length - 1 ? 10 : 0,
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.2), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(e.value['icon'] as IconData, color: color, size: 16),
                    const SizedBox(height: 8),
                    Text(
                      e.value['value'] as String,
                      style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      e.value['label'] as String,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildSessionBanner() {
    if (_loadingSession) {
      return Container(
        margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        height: 140,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(color: _lime, strokeWidth: 2),
          ),
        ),
      );
    }

    if (_nextSession == null) {
      return GestureDetector(
        onTap: () => setState(() => _navIndex = 1),
        child: Container(
          margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _cardBorder, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _lime.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: _lime,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aucune séance prévue',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Réservez une séance avec un coach',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _lime,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'EXPLORER',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final s = _nextSession!;
    final diff = s.sessionStart.difference(DateTime.now());
    final daysLeft = diff.inDays;
    final countdown = daysLeft == 0
        ? "Aujourd'hui"
        : daysLeft == 1
            ? 'Demain'
            : 'Dans $daysLeft jours';

    return GestureDetector(
      onTap: () => setState(() => _navIndex = 2),
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _lime.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: _lime.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              bottom: -40,
              right: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _lime.withOpacity(0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: _lime,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'PROCHAINE SÉANCE',
                        style: TextStyle(
                          color: _lime,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _lime,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          countdown,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _lime, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF1A1A1A),
                          backgroundImage: s.coachImageUrl.isNotEmpty
                              ? NetworkImage(s.coachImageUrl)
                              : null,
                          child: s.coachImageUrl.isEmpty
                              ? Text(
                                  s.coachName.isNotEmpty ? s.coachName[0] : '?',
                                  style: const TextStyle(
                                    color: _lime,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.coachName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.coachSpeciality.isNotEmpty
                                  ? s.coachSpeciality
                                  : 'Coach',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (s.isConfirmed ? const Color(0xFF4CAF50) : _lime)
                                  .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                (s.isConfirmed ? const Color(0xFF4CAF50) : _lime)
                                    .withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          s.isConfirmed ? 'CONFIRMÉE' : 'EN ATTENTE',
                          style: TextStyle(
                            color: s.isConfirmed
                                ? const Color(0xFF4CAF50)
                                : _lime,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(color: Colors.white.withOpacity(0.07), height: 1),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _openConversationWithCoach(
                      s.coachID,
                      s.coachName,
                      s.coachImageUrl,
                      s.coachSpeciality,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _lime.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _lime.withOpacity(0.25)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              color: _lime, size: 13),
                          SizedBox(width: 6),
                          Text(
                            'MESSAGE',
                            style: TextStyle(
                              color: _lime,
                              fontWeight: FontWeight.w800,
                              fontSize: 9,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _metaChip(
                        Icons.calendar_today_rounded,
                        _formatDate(s.sessionStart),
                      ),
                      const SizedBox(width: 12),
                      _metaChip(
                        Icons.access_time_rounded,
                        '${_formatTime(s.sessionStart)} — ${_formatTime(s.sessionEnd)}',
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white24,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) => Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.35), size: 12),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11),
          ),
        ],
      );

  Widget _sectionHeader(String title, {VoidCallback? onSeeAll}) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 18,
              color: _lime,
              margin: const EdgeInsets.only(right: 10),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onSeeAll,
              child: Row(
                children: [
                  const Text(
                    'TOUT VOIR',
                    style: TextStyle(
                      color: _lime,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, color: _lime, size: 14),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildCoachList() {
    if (_loadingCoaches) {
      return SizedBox(
        height: 240,
        child: ListView.builder(
          padding: const EdgeInsets.only(left: 24),
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          itemBuilder: (_, __) => Container(
            width: 160,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: _card,
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
          _coachError ?? 'Aucun coach disponible',
          style: const TextStyle(color: Colors.white38, fontSize: 13),
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 24),
        scrollDirection: Axis.horizontal,
        itemCount: _coaches.length,
        itemBuilder: (_, i) => _CoachCard(
          coach: _coaches[i],
          onTap: () => _openCoachDetail(_coaches[i]),
        ),
      ),
    );
  }

  Widget _buildAdvisorList() {
    if (_loadingAdvisors) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: List.generate(
            2,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 14),
              height: 110,
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14),
              ),
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
          _advisorError ?? 'Aucune société disponible',
          style: const TextStyle(color: Colors.white38, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _advisors.length,
      itemBuilder: (_, i) => _AdvisorCard(
        advisor: _advisors[i],
        onTap: () => _openCompanyDetail(_advisors[i]),
      ),
    );
  }

  Widget _buildNavBar() {
    const items = [
      (Icons.home_rounded, 'Accueil'),
      (Icons.search_rounded, 'Explorer'),
      (Icons.calendar_today_rounded, 'Séances'),
      (Icons.person_rounded, 'Profil'),
    ];

    const leftItems = [0, 1];
    const rightItems = [2, 3];

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            border: Border(top: BorderSide(color: _cardBorder, width: 1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
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
                    color: _lime.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                  
                ],
              ),
              child: Center(
                child: Container(
                  width: 52,
                  height: 52,
                  child: const Center(
                    child: _FitlekLogo(height: 42),
                  ),
                ),
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
          color: active ? _lime.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.$1,
              color: active ? _lime : Colors.white24,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              item.$2,
              style: TextStyle(
                color: active ? _lime : Colors.white24,
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

  String _formatDate(DateTime d) {
    const m = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc',
    ];
    const w = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return '${w[d.weekday - 1]} ${d.day} ${m[d.month - 1]}';
  }

  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _CoachCard extends StatelessWidget {
  final CoachModel coach;
  final VoidCallback onTap;

  const _CoachCard({required this.coach, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 165,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardBorder, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 130,
                  width: double.infinity,
                  child: coach.avatarUrl?.isNotEmpty == true
                      ? Image.network(
                          coach.avatarUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, p) => p == null
                              ? child
                              : Container(color: const Color(0xFF1A1A1A)),
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                if (coach.isPremium)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.black,
                        size: 11,
                      ),
                    ),
                  ),
                if (coach.rating != null)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: _lime, size: 11),
                          const SizedBox(width: 3),
                          Text(
                            coach.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coach.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      coach.speciality ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: _lime.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: _lime.withOpacity(0.25), width: 1),
                      ),
                      child: const Text(
                        'VOIR',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _lime,
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

  Widget _placeholder() => Container(
        color: const Color(0xFF1A1A1A),
        child: Center(
          child: Text(
            coach.fullName.isNotEmpty ? coach.fullName[0].toUpperCase() : '?',
            style: const TextStyle(
              color: _lime,
              fontSize: 40,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
}

class _AdvisorCard extends StatelessWidget {
  final _AdvisorItem advisor;
  final VoidCallback onTap;

  const _AdvisorCard({required this.advisor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 110,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardBorder, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: advisor.avatarUrl != null
                  ? Image.network(
                      advisor.avatarUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, p) => p == null
                          ? child
                          : Container(color: const Color(0xFF1A1A1A)),
                      errorBuilder: (_, __, ___) => _defaultCover(),
                    )
                  : _defaultCover(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            advisor.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (advisor.isApproved)
                          const Icon(Icons.verified_rounded, color: _lime, size: 14),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _lime.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: _lime.withOpacity(0.25), width: 1),
                      ),
                      child: Text(
                        advisor.specialty.toUpperCase(),
                        style: const TextStyle(
                          color: _lime,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _lime,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Text(
                        'VOIR LES COACHS',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                          letterSpacing: 1,
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

  Widget _defaultCover() => Container(
        color: const Color(0xFF1A1A1A),
        child: Center(
          child: Icon(
            Icons.business_rounded,
            color: _lime.withOpacity(0.3),
            size: 36,
          ),
        ),
      );
}