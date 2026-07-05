import 'package:flutter/material.dart';
import 'ClientSessions.dart';
import 'clientCoachDetail.dart';

// ─────────────────────────────────────────────
//  Constants
// ─────────────────────────────────────────────

const _lime = Color(0xFFC6F135);
const _dark = Color(0xFF0A0A0A);
const _card = Color(0xFF141414);
const _cardBorder = Color(0xFF232323);

// ─────────────────────────────────────────────
//  SessionDetailScreen
// ─────────────────────────────────────────────

class SessionDetailScreen extends StatefulWidget {
  final SessionModel session;
  const SessionDetailScreen({super.key, required this.session});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  int _hoverRating = 0;
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _reviewSubmitted = false;

  @override
  void initState() {
    super.initState();
    if (widget.session.reviewRating != null) {
      _selectedRating = widget.session.reviewRating!;
      _reviewSubmitted = true;
      if (widget.session.reviewComment != null) {
        _commentController.text = widget.session.reviewComment!;
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    final day = days[dt.weekday - 1];
    return '$day ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  int get _durationMin {
    return widget.session.sessionEnd
        .difference(widget.session.sessionStart)
        .inMinutes;
  }

  Color get _statusColor {
    switch (widget.session.status) {
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
    switch (widget.session.status) {
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

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    return Scaffold(
      backgroundColor: _dark,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusBanner(s),
                    const SizedBox(height: 20),
                    _buildInfoCard(s),
                    const SizedBox(height: 16),
                    _buildCoachCard(context, s),
                    const SizedBox(height: 16),
                    if (s.status == 'completed') _buildReviewSection(s),
                    if (s.status == 'upcoming') _buildUpcomingActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 24, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _cardBorder, width: 1),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Détail de la séance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: _statusColor.withOpacity(0.35), width: 1),
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
    );
  }

  // ── Status/price banner ───────────────────────────────────────────
  Widget _buildStatusBanner(SessionModel s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _statusColor.withOpacity(0.18),
            _statusColor.withOpacity(0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: _statusColor.withOpacity(0.25), width: 1),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${s.price.toInt()} MAD',
                style: TextStyle(
                  color: _statusColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$_durationMin min • ${_formatTime(s.sessionStart)} — ${_formatTime(s.sessionEnd)}',
                style: const TextStyle(
                    color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          Icon(
            s.status == 'upcoming'
                ? Icons.upcoming_rounded
                : s.status == 'completed'
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
            color: _statusColor,
            size: 42,
          ),
        ],
      ),
    );
  }

  // ── Info card ─────────────────────────────────────────────────────
  Widget _buildInfoCard(SessionModel s) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 1),
      ),
      child: Column(
        children: [
          _infoRow(
              Icons.calendar_today_rounded, 'Date', _formatDate(s.sessionStart)),
          _divider(),
          _infoRow(
            Icons.access_time_rounded,
            'Horaire',
            '${_formatTime(s.sessionStart)} — ${_formatTime(s.sessionEnd)}',
          ),
          _divider(),
          _infoRow(Icons.timer_rounded, 'Durée', '$_durationMin minutes'),
          _divider(),
          _infoRow(Icons.location_on_rounded, 'Lieu', s.location),
          _divider(),
          _infoRow(Icons.receipt_long_rounded, 'Session ID', '#${s.id.toString().padLeft(4, '0')}'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _lime.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _lime, size: 16),
          ),
          const SizedBox(width: 14),
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, color: Colors.white.withOpacity(0.05));

  // ── Coach card (tappable) ─────────────────────────────────────────
  Widget _buildCoachCard(BuildContext context, SessionModel s) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) =>
                CoachDetailScreen(session: s),
            transitionsBuilder: (_, a, __, child) =>
                FadeTransition(opacity: a, child: child),
            transitionDuration: const Duration(milliseconds: 350),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardBorder, width: 1),
        ),
        child: Row(
          children: [
            // Section label
            Container(width: 3, height: 40, color: _lime,
                margin: const EdgeInsets.only(right: 12)),
            const Text(
              'Coach',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 16),
            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _lime.withOpacity(0.4), width: 2),
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(s.coachImageUrl),
              ),
            ),
            const SizedBox(width: 14),
            // Name + speciality
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.coachName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.coachSpeciality,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            // Rating
            Row(
              children: [
                const Icon(Icons.star_rounded, color: _lime, size: 13),
                const SizedBox(width: 4),
                Text(
                  s.coachRating.toString(),
                  style: const TextStyle(
                      color: _lime,
                      fontWeight: FontWeight.w800,
                      fontSize: 13),
                ),
              ],
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Review section ────────────────────────────────────────────────
  Widget _buildReviewSection(SessionModel s) {
    final alreadyReviewed =
        s.reviewRating != null || (_reviewSubmitted && _selectedRating > 0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(width: 3, height: 18, color: _lime,
                  margin: const EdgeInsets.only(right: 10)),
              const Text(
                'Avis & Notation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (alreadyReviewed)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Color(0xFF4CAF50), size: 11),
                      SizedBox(width: 4),
                      Text(
                        'NOTÉ',
                        style: TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),

          if (alreadyReviewed) ...[
            // Show existing review
            Row(
              children: [
                Row(
                  children: List.generate(
                    5,
                    (i) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        i < (s.reviewRating ?? _selectedRating)
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: _lime,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${s.reviewRating ?? _selectedRating}/5',
                  style: const TextStyle(
                    color: _lime,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            if ((s.reviewComment ?? _commentController.text).isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.07), width: 1),
                ),
                child: Text(
                  s.reviewComment ?? _commentController.text,
                  style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                      height: 1.55),
                ),
              ),
            ],
          ] else ...[
            // Star rating selector
            const Text(
              'Comment évaluez-vous cette séance ?',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled =
                    i < (_hoverRating > 0 ? _hoverRating : _selectedRating);
                return GestureDetector(
                  onTap: () => setState(() => _selectedRating = i + 1),
                  child: MouseRegion(
                    onEnter: (_) =>
                        setState(() => _hoverRating = i + 1),
                    onExit: (_) => setState(() => _hoverRating = 0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        filled
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: _lime,
                        size: 38,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),
            // Comment field
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withOpacity(0.1), width: 1),
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Partagez votre expérience (optionnel)...',
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Submit button
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _selectedRating > 0
                    ? () => setState(() => _reviewSubmitted = true)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _selectedRating > 0
                        ? _lime
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'SOUMETTRE MON AVIS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _selectedRating > 0
                          ? Colors.black
                          : Colors.white24,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Upcoming actions ──────────────────────────────────────────────
  Widget _buildUpcomingActions() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5252).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFFF5252).withOpacity(0.3), width: 1),
            ),
            child: const Text(
              'ANNULER',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFF5252),
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _lime,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'CONFIRMER',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}