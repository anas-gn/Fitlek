import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  Static data models
// ─────────────────────────────────────────────

class _Coach {
  final String name;
  final String speciality;
  final double rating;
  final int sessions;
  final String location;
  final String imageUrl;
  final List<String> tags;
  final double hourlyRate;
  final bool isVerified;
  const _Coach({
    required this.name,
    required this.speciality,
    required this.rating,
    required this.sessions,
    required this.location,
    required this.imageUrl,
    required this.tags,
    required this.hourlyRate,
    this.isVerified = true,
  });
}

class _Company {
  final String name;
  final String city;
  final double rating;
  final int coaches;
  final String imageUrl;
  final String description;
  final List<String> services;
  const _Company({
    required this.name,
    required this.city,
    required this.rating,
    required this.coaches,
    required this.imageUrl,
    required this.description,
    required this.services,
  });
}

const _coaches = [
  _Coach(
    name: 'Youssef Benali',
    speciality: 'Musculation & Nutrition',
    rating: 4.9,
    sessions: 312,
    location: 'Casablanca',
    imageUrl:
        'https://images.unsplash.com/photo-1534367610401-9f5ed68180aa?w=400&q=80',
    tags: ['Strength', 'Nutrition', 'STAPS'],
    hourlyRate: 200,
  ),
  _Coach(
    name: 'Amina Khalil',
    speciality: 'Yoga & Mobilité',
    rating: 4.8,
    sessions: 198,
    location: 'Rabat',
    imageUrl:
        'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=400&q=80',
    tags: ['Yoga', 'Mobility', 'Mindfulness'],
    hourlyRate: 180,
  ),
  _Coach(
    name: 'Karim Ouazzani',
    speciality: 'Cardio & Perte de Poids',
    rating: 4.7,
    sessions: 275,
    location: 'Marrakech',
    imageUrl:
        'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&q=80',
    tags: ['Cardio', 'HIIT', 'Weight Loss'],
    hourlyRate: 150,
  ),
  _Coach(
    name: 'Sara El Idrissi',
    speciality: 'Pilates & Gainage',
    rating: 4.9,
    sessions: 420,
    location: 'Casablanca',
    imageUrl:
        'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=400&q=80',
    tags: ['Pilates', 'Core', 'Posture'],
    hourlyRate: 220,
  ),
];

const _companies = [
  _Company(
    name: 'EliteFit Maroc',
    city: 'Casablanca',
    rating: 4.9,
    coaches: 12,
    imageUrl:
        'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600&q=80',
    description: 'Centre de coaching premium au cœur de Casablanca.',
    services: ['Musculation', 'Cardio', 'Nutrition', 'CrossFit'],
  ),
  _Company(
    name: 'ProCoach Rabat',
    city: 'Rabat',
    rating: 4.7,
    coaches: 8,
    imageUrl:
        'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=600&q=80',
    description: 'Coaching personnalisé certifié pour tous niveaux.',
    services: ['Yoga', 'HIIT', 'Réathlétisation'],
  ),
  _Company(
    name: 'AtlasFit',
    city: 'Marrakech',
    rating: 4.8,
    coaches: 15,
    imageUrl:
        'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?w=600&q=80',
    description: 'La référence fitness du sud du Maroc.',
    services: ['Boxe', 'Zumba', 'Stretching', 'Natation'],
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
//  HomeScreen
// ─────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Nearby', 'Top Rated', 'Available'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App bar ───────────────────────────────────────────
            SliverToBoxAdapter(child: _buildHeader()),

            // ── Search bar ───────────────────────────────────────
            SliverToBoxAdapter(child: _buildSearchBar()),

            // ── Filter chips ──────────────────────────────────────
            SliverToBoxAdapter(child: _buildFilters()),

            // ── Hero stat row ─────────────────────────────────────
            SliverToBoxAdapter(child: _buildStatBanner()),

            // ── Section: Coaches ──────────────────────────────────
            SliverToBoxAdapter(
              child: _sectionHeader('Recommended Coaches', onSeeAll: () {}),
            ),
            SliverToBoxAdapter(child: _buildCoachList()),

            // ── Section: Companies ────────────────────────────────
            SliverToBoxAdapter(
              child: _sectionHeader('Top Coaching Companies', onSeeAll: () {}),
            ),
            SliverToBoxAdapter(child: _buildCompanyList()),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  // ── Header ───────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          // Logo
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
          const Spacer(),
          // Greeting
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Good morning,',
                style: TextStyle(
                    color: Colors.white54, fontSize: 11, letterSpacing: 0.5),
              ),
              const Text(
                'Sara ',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundColor: _lime.withOpacity(0.2),
            backgroundImage: const NetworkImage(
                'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=80&q=80'),
          ),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.search, color: Colors.white.withOpacity(0.35), size: 20),
            const SizedBox(width: 10),
            Text(
              'Search coaches, gyms...',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 14,
                  letterSpacing: 0.2),
            ),
            const Spacer(),
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _lime,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.tune, color: Colors.black, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter chips ──────────────────────────────────────────────────
  Widget _buildFilters() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final active = i == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: active ? _lime : _card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _filters[i],
                style: TextStyle(
                  color: active ? Colors.black : Colors.white60,
                  fontWeight:
                      active ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Next session banner ───────────────────────────────────────────
  Widget _buildStatBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background image (coach photo blurred/darkened)
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1534367610401-9f5ed68180aa?w=600&q=80',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.78),
              colorBlendMode: BlendMode.darken,
              loadingBuilder: (_, child, p) =>
                  p == null ? child : Container(color: const Color(0xFF141414)),
            ),
          ),

          // Lime glow bottom-right
          Positioned(
            bottom: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _lime.withOpacity(0.12),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
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
                    const SizedBox(width: 7),
                    const Text(
                      'PROCHAINE SÉANCE',
                      style: TextStyle(
                        color: _lime,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const Spacer(),
                    // Countdown chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _lime,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Dans 2 jours',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Coach info row
                Row(
                  children: [
                    // Coach avatar
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _lime, width: 2),
                      ),
                      child: const CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(
                          'https://images.unsplash.com/photo-1534367610401-9f5ed68180aa?w=100&q=80',
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Name + speciality
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Youssef Benali',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Musculation & Nutrition',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Rating badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.star, color: _lime, size: 13),
                            SizedBox(width: 3),
                            Text(
                              '4.9',
                              style: TextStyle(
                                color: _lime,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '312 sessions',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Divider
                Divider(color: Colors.white.withOpacity(0.08), height: 1),
                const SizedBox(height: 12),

                // Date + time + location row
                Row(
                  children: [
                    _sessionMeta(Icons.calendar_today_rounded, 'Mer 04 Juin'),
                    const SizedBox(width: 18),
                    _sessionMeta(Icons.access_time_rounded, '10:00 — 11:00'),
                    const SizedBox(width: 18),
                    _sessionMeta(Icons.location_on_rounded, 'Casablanca'),
                    const Spacer(),
                    // Join button
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _lime,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'VOIR',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sessionMeta(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.4), size: 12),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Section header ────────────────────────────────────────────────
  Widget _sectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
      child: Row(
        children: [
          Container(width: 3, height: 18, color: _lime,
              margin: const EdgeInsets.only(right: 10)),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3)),
          const Spacer(),
          GestureDetector(
            onTap: onSeeAll,
            child: const Text('SEE ALL',
                style: TextStyle(
                    color: _lime,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
          ),
        ],
      ),
    );
  }

  // ── Coach horizontal list ─────────────────────────────────────────
  Widget _buildCoachList() {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 24),
        scrollDirection: Axis.horizontal,
        itemCount: _coaches.length,
        itemBuilder: (_, i) => _CoachCard(coach: _coaches[i]),
      ),
    );
  }

  // ── Company vertical list ─────────────────────────────────────────
  Widget _buildCompanyList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _companies.length,
      itemBuilder: (_, i) => _CompanyCard(company: _companies[i]),
    );
  }

  // ── Bottom nav ────────────────────────────────────────────────────
  Widget _buildNavBar() {
    final items = [
      (Icons.home_rounded, 'Home'),
      (Icons.search_rounded, 'Explore'),
      (Icons.calendar_today_rounded, 'Sessions'),
      (Icons.person_rounded, 'Profile'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        border: Border(top: BorderSide(color: _cardBorder, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = i == _navIndex;
          return GestureDetector(
            onTap: () => setState(() => _navIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active ? _lime.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(items[i].$1,
                      color: active ? _lime : Colors.white30, size: 22),
                  const SizedBox(height: 4),
                  Text(items[i].$2,
                      style: TextStyle(
                          color: active ? _lime : Colors.white30,
                          fontSize: 10,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w400,
                          letterSpacing: 0.5)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Coach Card
// ─────────────────────────────────────────────

class _CoachCard extends StatelessWidget {
  final _Coach coach;
  const _CoachCard({required this.coach});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Stack(
            children: [
              SizedBox(
                height: 130,
                width: double.infinity,
                child: Image.network(
                  coach.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, p) => p == null
                      ? child
                      : Container(color: const Color(0xFF1a1a1a)),
                ),
              ),
              // Verified badge
              if (coach.isVerified)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _lime,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.verified,
                        color: Colors.black, size: 12),
                  ),
                ),
              // Rating
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: _lime, size: 11),
                      const SizedBox(width: 3),
                      Text(
                        coach.rating.toString(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coach.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  coach.speciality,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${coach.hourlyRate.toInt()} MAD/h',
                      style: const TextStyle(
                          color: _lime,
                          fontWeight: FontWeight.w800,
                          fontSize: 12),
                    ),
                    const Spacer(),
                    Icon(Icons.location_on,
                        color: Colors.white.withOpacity(0.35), size: 11),
                    Text(
                      coach.location,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.35), fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Company Card
// ─────────────────────────────────────────────

class _CompanyCard extends StatelessWidget {
  final _Company company;
  const _CompanyCard({required this.company});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      height: 140,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // Image
          SizedBox(
            width: 120,
            child: Image.network(
              company.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, p) =>
                  p == null ? child : Container(color: const Color(0xFF1a1a1a)),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + rating
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          company.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.star, color: _lime, size: 13),
                      const SizedBox(width: 3),
                      Text(company.rating.toString(),
                          style: const TextStyle(
                              color: _lime,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 11,
                          color: Colors.white.withOpacity(0.4)),
                      const SizedBox(width: 2),
                      Text(company.city,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11)),
                      const SizedBox(width: 12),
                      Icon(Icons.person_outline,
                          size: 11,
                          color: Colors.white.withOpacity(0.4)),
                      const SizedBox(width: 2),
                      Text('${company.coaches} coaches',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    company.description,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 11,
                        height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  // Service tags
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: company.services
                        .take(3)
                        .map((s) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: _lime.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: _lime.withOpacity(0.3), width: 1),
                              ),
                              child: Text(s,
                                  style: const TextStyle(
                                      color: _lime,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600)),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}