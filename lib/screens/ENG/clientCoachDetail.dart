import 'package:flutter/material.dart';
import 'ClientSessions.dart';

// ─────────────────────────────────────────────
//  Constants
// ─────────────────────────────────────────────

const _lime = Color(0xFFC6F135);
const _dark = Color(0xFF0A0A0A);
const _card = Color(0xFF141414);
const _cardBorder = Color(0xFF232323);

// ─────────────────────────────────────────────
//  Static coach extended data (keyed by coachName)
// ─────────────────────────────────────────────

class _CoachExtra {
  final String bio;
  final int sessions;
  final String city;
  final double hourlyRate;
  final List<String> tags;
  final List<String> certifications;
  final int yearsExp;

  const _CoachExtra({
    required this.bio,
    required this.sessions,
    required this.city,
    required this.hourlyRate,
    required this.tags,
    required this.certifications,
    required this.yearsExp,
  });
}

const _coachExtras = <String, _CoachExtra>{
  'Youssef Benali': _CoachExtra(
    bio:
        'Coach certifié STAPS avec plus de 6 ans d\'expérience en musculation et nutrition sportive. Passionné par la performance et le bien-être, j\'accompagne mes clients vers leurs objectifs avec rigueur et bienveillance.',
    sessions: 312,
    city: 'Casablanca',
    hourlyRate: 200,
    tags: ['Strength', 'Nutrition', 'STAPS'],
    certifications: ['Licence STAPS', 'Certification NSCA', 'Nutrition sportive'],
    yearsExp: 6,
  ),
  'Amina Khalil': _CoachExtra(
    bio:
        'Professeure de yoga certifiée RYT-500, spécialisée en mobilité et pleine conscience. J\'aide mes clients à trouver l\'équilibre entre force et souplesse pour un mieux-être durable.',
    sessions: 198,
    city: 'Rabat',
    hourlyRate: 180,
    tags: ['Yoga', 'Mobility', 'Mindfulness'],
    certifications: ['RYT-500 Yoga Alliance', 'Mobilité fonctionnelle'],
    yearsExp: 4,
  ),
  'Karim Ouazzani': _CoachExtra(
    bio:
        'Expert en cardio-training et perte de poids, diplômé en sciences du sport. Je crée des programmes HIIT personnalisés adaptés à chaque niveau pour maximiser les résultats.',
    sessions: 275,
    city: 'Marrakech',
    hourlyRate: 150,
    tags: ['Cardio', 'HIIT', 'Weight Loss'],
    certifications: ['Diplôme BPJEPS', 'Certificat HIIT Pro'],
    yearsExp: 5,
  ),
  'Sara El Idrissi': _CoachExtra(
    bio:
        'Championne nationale de pilates et coach gainage. Avec plus de 10 ans de pratique, je guide mes clients vers une posture parfaite et un core de fer, dans un esprit positif et motivant.',
    sessions: 420,
    city: 'Casablanca',
    hourlyRate: 220,
    tags: ['Pilates', 'Core', 'Posture'],
    certifications: ['Pilates Method Alliance', 'Physiothérapie du sport', 'Gainage avancé'],
    yearsExp: 10,
  ),
};

// ─────────────────────────────────────────────
//  CoachDetailScreen
// ─────────────────────────────────────────────

class CoachDetailScreen extends StatefulWidget {
  final SessionModel session;
  const CoachDetailScreen({super.key, required this.session});

  @override
  State<CoachDetailScreen> createState() => _CoachDetailScreenState();
}

class _CoachDetailScreenState extends State<CoachDetailScreen> {
  // Fake reviews for display
  final _reviews = const [
    _ReviewItem(
        name: 'Sara E.',
        rating: 5,
        comment: 'Excellent coach, très professionnel et motivant !',
        date: 'Mai 2026'),
    _ReviewItem(
        name: 'Mehdi A.',
        rating: 4,
        comment: 'Séances bien structurées, je progresse rapidement.',
        date: 'Avr 2026'),
    _ReviewItem(
        name: 'Leila B.',
        rating: 5,
        comment: 'Toujours disponible et à l\'écoute. Je recommande vivement.',
        date: 'Mar 2026'),
    _ReviewItem(
        name: 'Omar T.',
        rating: 4,
        comment: 'Bonne pédagogie, plans nutritionnels top.',
        date: 'Fév 2026'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final extra = _coachExtras[s.coachName];

    return Scaffold(
      backgroundColor: _dark,
      body: CustomScrollView(
        slivers: [
          // ── Hero sliver ─────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHero(context, s, extra)),

          // ── Stats row ───────────────────────────────────────────
          SliverToBoxAdapter(child: _buildStats(s, extra)),

          // ── Bio ─────────────────────────────────────────────────
          if (extra != null) SliverToBoxAdapter(child: _buildBio(extra)),

          // ── Tags ────────────────────────────────────────────────
          if (extra != null) SliverToBoxAdapter(child: _buildTags(extra)),

          // ── Certifications ──────────────────────────────────────
          if (extra != null)
            SliverToBoxAdapter(child: _buildCertifications(extra)),

          // ── Reviews ─────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildReviewsHeader(s)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _buildReviewCard(_reviews[i]),
              childCount: _reviews.length,
            ),
          ),

          // ── Book CTA ─────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildBookCTA()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────
  Widget _buildHero(
      BuildContext context, SessionModel s, _CoachExtra? extra) {
    return SizedBox(
      height: 340,
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.network(
              s.coachImageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, p) => p == null
                  ? child
                  : Container(color: const Color(0xFF141414)),
            ),
          ),
          // Gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x88000000),
                    Color(0xFF0A0A0A),
                  ],
                  stops: [0.3, 1.0],
                ),
              ),
            ),
          ),
          // Back button
          Positioned(
            top: 48,
            left: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.15), width: 1),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
            ),
          ),
          // Verified badge
          Positioned(
            top: 56,
            right: 20,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _lime,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_rounded,
                        color: Colors.black, size: 12),
                    SizedBox(width: 5),
                    Text(
                      'VÉRIFIÉ',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Name & speciality at bottom
          Positioned(
            bottom: 20,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: Colors.white38, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      extra?.city ?? '',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  s.coachName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.coachSpeciality,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────
  Widget _buildStats(SessionModel s, _CoachExtra? extra) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          _statBox(s.coachRating.toString(), 'Note'),
          const SizedBox(width: 12),
          _statBox('${extra?.sessions ?? 0}', 'Séances'),
          const SizedBox(width: 12),
          _statBox('${extra?.yearsExp ?? 0} ans', 'Expérience'),
          const SizedBox(width: 12),
          _statBox('${extra?.hourlyRate.toInt() ?? 0} MAD', 'Par heure'),
        ],
      ),
    );
  }

  Widget _statBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _cardBorder, width: 1),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: _lime,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bio ───────────────────────────────────────────────────────────
  Widget _buildBio(_CoachExtra extra) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('À propos'),
          const SizedBox(height: 12),
          Text(
            extra.bio,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tags ──────────────────────────────────────────────────────────
  Widget _buildTags(_CoachExtra extra) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Spécialités'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: extra.tags
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _lime.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _lime.withOpacity(0.3), width: 1),
                      ),
                      child: Text(
                        t,
                        style: const TextStyle(
                          color: _lime,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Certifications ────────────────────────────────────────────────
  Widget _buildCertifications(_CoachExtra extra) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Certifications'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _cardBorder, width: 1),
            ),
            child: Column(
              children: extra.certifications
                  .asMap()
                  .entries
                  .map((e) => Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 13),
                            child: Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: _lime.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                      Icons.workspace_premium_rounded,
                                      color: _lime,
                                      size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    e.value,
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (e.key < extra.certifications.length - 1)
                            Divider(
                                height: 1,
                                color: Colors.white.withOpacity(0.05)),
                        ],
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reviews header ────────────────────────────────────────────────
  Widget _buildReviewsHeader(SessionModel s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Row(
        children: [
          Container(width: 3, height: 18, color: _lime,
              margin: const EdgeInsets.only(right: 10)),
          const Text(
            'Avis des clients',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: _lime, size: 14),
              const SizedBox(width: 4),
              Text(
                '${s.coachRating} (${_reviews.length} avis)',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(_ReviewItem review) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _lime.withOpacity(0.2),
                child: Text(
                  review.name[0],
                  style: const TextStyle(
                      color: _lime, fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ),
              Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                          i < review.rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: _lime,
                          size: 12,
                        )),
              ),
              const SizedBox(width: 8),
              Text(
                review.date,
                style:
                    const TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: const TextStyle(
                color: Colors.white54, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Book CTA ──────────────────────────────────────────────────────
  Widget _buildBookCTA() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _lime,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'RÉSERVER UNE SÉANCE',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(width: 3, height: 16, color: _lime,
            margin: const EdgeInsets.only(right: 10)),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Review item model
// ─────────────────────────────────────────────

class _ReviewItem {
  final String name;
  final int rating;
  final String comment;
  final String date;
  const _ReviewItem(
      {required this.name,
      required this.rating,
      required this.comment,
      required this.date});
}