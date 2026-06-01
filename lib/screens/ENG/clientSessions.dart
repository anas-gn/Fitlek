import 'package:flutter/material.dart';
import 'clientSessionDetail.dart';

// ─────────────────────────────────────────────
//  Data models
// ─────────────────────────────────────────────

class SessionModel {
  final int id;
  final String coachName;
  final String coachSpeciality;
  final String coachImageUrl;
  final double coachRating;
  final DateTime sessionStart;
  final DateTime sessionEnd;
  final String location;
  final String status; // 'upcoming' | 'completed' | 'cancelled'
  final double price;
  final int? reviewRating;     // null si pas encore noté
  final String? reviewComment;

  const SessionModel({
    required this.id,
    required this.coachName,
    required this.coachSpeciality,
    required this.coachImageUrl,
    required this.coachRating,
    required this.sessionStart,
    required this.sessionEnd,
    required this.location,
    required this.status,
    required this.price,
    this.reviewRating,
    this.reviewComment,
  });
}

final _sessions = [
  SessionModel(
    id: 1,
    coachName: 'Youssef Benali',
    coachSpeciality: 'Musculation & Nutrition',
    coachImageUrl:
        'https://images.unsplash.com/photo-1534367610401-9f5ed68180aa?w=400&q=80',
    coachRating: 4.9,
    sessionStart: DateTime(2026, 6, 4, 10, 0),
    sessionEnd: DateTime(2026, 6, 4, 11, 0),
    location: 'Casablanca',
    status: 'upcoming',
    price: 200,
    reviewRating: null,
    reviewComment: null,
  ),
  SessionModel(
    id: 2,
    coachName: 'Youssef Benali',
    coachSpeciality: 'Musculation & Nutrition',
    coachImageUrl:
        'https://images.unsplash.com/photo-1534367610401-9f5ed68180aa?w=400&q=80',
    coachRating: 4.9,
    sessionStart: DateTime(2026, 6, 10, 14, 0),
    sessionEnd: DateTime(2026, 6, 10, 15, 0),
    location: 'Casablanca',
    status: 'upcoming',
    price: 200,
    reviewRating: null,
    reviewComment: null,
  ),
  SessionModel(
    id: 3,
    coachName: 'Amina Khalil',
    coachSpeciality: 'Yoga & Mobilité',
    coachImageUrl:
        'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=400&q=80',
    coachRating: 4.8,
    sessionStart: DateTime(2026, 5, 20, 9, 0),
    sessionEnd: DateTime(2026, 5, 20, 10, 0),
    location: 'Rabat',
    status: 'completed',
    price: 180,
    reviewRating: 5,
    reviewComment: 'Séance incroyable, Amina est très professionnelle !',
  ),
  SessionModel(
    id: 4,
    coachName: 'Karim Ouazzani',
    coachSpeciality: 'Cardio & Perte de Poids',
    coachImageUrl:
        'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&q=80',
    coachRating: 4.7,
    sessionStart: DateTime(2026, 5, 10, 11, 0),
    sessionEnd: DateTime(2026, 5, 10, 12, 0),
    location: 'Marrakech',
    status: 'completed',
    price: 150,
    reviewRating: null,
    reviewComment: null,
  ),
  SessionModel(
    id: 5,
    coachName: 'Sara El Idrissi',
    coachSpeciality: 'Pilates & Gainage',
    coachImageUrl:
        'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=400&q=80',
    coachRating: 4.9,
    sessionStart: DateTime(2026, 4, 28, 16, 0),
    sessionEnd: DateTime(2026, 4, 28, 17, 0),
    location: 'Casablanca',
    status: 'cancelled',
    price: 220,
    reviewRating: null,
    reviewComment: null,
  ),
  SessionModel(
    id: 6,
    coachName: 'Amina Khalil',
    coachSpeciality: 'Yoga & Mobilité',
    coachImageUrl:
        'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=400&q=80',
    coachRating: 4.8,
    sessionStart: DateTime(2026, 4, 15, 8, 0),
    sessionEnd: DateTime(2026, 4, 15, 9, 0),
    location: 'Rabat',
    status: 'completed',
    price: 180,
    reviewRating: 4,
    reviewComment: 'Très bonne séance, je recommande.',
  ),
];

// ─────────────────────────────────────────────
//  Constants
// ─────────────────────────────────────────────

const _lime = Color(0xFFC6F135);
const _dark = Color(0xFF0A0A0A);
const _card = Color(0xFF141414);
const _cardBorder = Color(0xFF232323);

// ─────────────────────────────────────────────
//  SessionsScreen
// ─────────────────────────────────────────────

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<SessionModel> get _upcoming =>
      _sessions.where((s) => s.status == 'upcoming').toList();

  List<SessionModel> get _past =>
      _sessions.where((s) => s.status != 'upcoming').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 4),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSessionList(_upcoming, emptyMsg: 'Aucune séance à venir.'),
                  _buildSessionList(_past, emptyMsg: 'Aucune séance passée.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'FIT',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _lime,
                        letterSpacing: 4,
                      ),
                    ),
                    TextSpan(
                      text: 'LEK',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Mes séances',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Stats badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _lime.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _lime.withOpacity(0.25), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: _lime, size: 14),
                const SizedBox(width: 6),
                Text(
                  '${_past.where((s) => s.status == 'completed').length} complétées',
                  style: const TextStyle(
                    color: _lime,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _cardBorder, width: 1),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: _lime,
            borderRadius: BorderRadius.circular(8),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.upcoming_rounded, size: 14),
                  const SizedBox(width: 6),
                  Text('À VENIR (${_upcoming.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_rounded, size: 14),
                  const SizedBox(width: 6),
                  Text('PASSÉES (${_past.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Session list ──────────────────────────────────────────────────
  Widget _buildSessionList(List<SessionModel> sessions,
      {required String emptyMsg}) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_outlined,
                color: Colors.white12, size: 48),
            const SizedBox(height: 12),
            Text(emptyMsg,
                style:
                    const TextStyle(color: Colors.white24, fontSize: 14)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      itemCount: sessions.length,
      itemBuilder: (_, i) => _SessionCard(session: sessions[i]),
    );
  }
}

// ─────────────────────────────────────────────
//  Session Card
// ─────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final SessionModel session;
  const _SessionCard({required this.session});

  Color get _statusColor {
    switch (session.status) {
      case 'upcoming':
        return _lime;
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return const Color(0xFFFF5252);
      default:
        return Colors.white38;
    }
  }

  String get _statusLabel {
    switch (session.status) {
      case 'upcoming':
        return 'À VENIR';
      case 'completed':
        return 'TERMINÉE';
      case 'cancelled':
        return 'ANNULÉE';
      default:
        return '';
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final day = days[dt.weekday - 1];
    return '$day ${dt.day} ${months[dt.month - 1]}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final bool needsReview =
        session.status == 'completed' && session.reviewRating == null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) =>
                SessionDetailScreen(session: session),
            transitionsBuilder: (_, a, __, child) =>
                FadeTransition(opacity: a, child: child),
            transitionDuration: const Duration(milliseconds: 350),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardBorder, width: 1),
        ),
        child: Column(
          children: [
            // Top section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Coach avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _statusColor.withOpacity(0.5), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundImage:
                          NetworkImage(session.coachImageUrl),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.coachName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          session.coachSpeciality,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _statusColor.withOpacity(0.35), width: 1),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Divider(height: 1, color: Colors.white.withOpacity(0.06)),

            // Bottom meta row
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _meta(Icons.calendar_today_rounded,
                      _formatDate(session.sessionStart)),
                  const SizedBox(width: 16),
                  _meta(
                    Icons.access_time_rounded,
                    '${_formatTime(session.sessionStart)} — ${_formatTime(session.sessionEnd)}',
                  ),
                  const SizedBox(width: 16),
                  _meta(Icons.location_on_rounded, session.location),
                  const Spacer(),
                  // Price or review stars
                  if (session.status == 'completed' &&
                      session.reviewRating != null)
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < session.reviewRating!
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: _lime,
                          size: 13,
                        ),
                      ),
                    )
                  else if (needsReview)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _lime.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: _lime.withOpacity(0.3), width: 1),
                      ),
                      child: const Text(
                        'NOTER',
                        style: TextStyle(
                          color: _lime,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    )
                  else
                    Text(
                      '${session.price.toInt()} MAD',
                      style: const TextStyle(
                        color: _lime,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white24, size: 11),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
              color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}