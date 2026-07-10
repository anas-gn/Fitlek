import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fitlek1/models/anas/reservation.dart';
import 'clientCoachDetail.dart';

const _lime = Color(0xFFC6F135);
const _dark = Color(0xFF0A0A0A);
const _card = Color(0xFF141414);
const _cardBorder = Color(0xFF232323);
const _success = Color(0xFF4CAF50);
const _errorRed = Color(0xFFFF5252);
const _accent = Color(0xFF2A2A2A);
const _baseUrl = 'http://192.168.0.232:3000/api';

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

class _LogoWatermark extends StatelessWidget {
  final double size;
  const _LogoWatermark({this.size = 320});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.035,
        child: SizedBox(
          width: size,
          height: size * 120 / 132,
          child: CustomPaint(
            painter: _FitlekLogoPainter(strokeColor: Colors.white, circleColor: _lime),
          ),
        ),
      ),
    );
  }
}

class SessionDetailScreen extends StatefulWidget {
  final ReservationModel session;
  final int clientID;
  final String token;

  const SessionDetailScreen({
    super.key,
    required this.session,
    required this.clientID,
    required this.token,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  late ReservationModel _session;

  int _hoverRating = 0;
  int _selectedRating = 0;
  final _commentCtrl = TextEditingController();
  bool _reviewSubmitted = false;
  bool _reviewLoading = false;

  bool _cancelling = false;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      };

  @override
  void initState() {
    super.initState();
    _session = widget.session;

    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    if (_session.reviewRating != null) {
      _selectedRating = _session.reviewRating!;
      _reviewSubmitted = true;
      if (_session.reviewComment != null) _commentCtrl.text = _session.reviewComment!;
    }

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
    ];
    const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return '${days[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Color get _statusColor {
    if (_session.isConfirmed) return _success;
    if (_session.isPending) return _lime;
    return _errorRed;
  }

  String get _statusLabel {
    if (_session.isPending) return 'EN ATTENTE';
    if (_session.isConfirmed) return 'CONFIRMÉE';
    return 'ANNULÉE';
  }

  bool get _sessionIsPast => _session.sessionStart.isBefore(DateTime.now());

  bool get _canReview => _session.isConfirmed && _sessionIsPast;

  Future<void> _cancelSession() async {
    final confirm = await _showConfirmDialog(
      title: 'Annuler la séance ?',
      message: 'Cette action est irréversible.',
      confirmLabel: 'ANNULER LA SÉANCE',
      confirmColor: _errorRed,
    );
    if (!confirm) return;

    setState(() => _cancelling = true);
    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl/reservations/${_session.id}/cancel'),
        headers: _headers,
        body: jsonEncode({
          'cancellationReason': 'Annulée par le client',
          'userID': widget.clientID,
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final updated = _session.copyWith(status: 'cancelled');
        setState(() => _session = updated);
        _showSnack('Séance annulée.', color: _errorRed);
        if (mounted) Navigator.pop(context, updated);
      } else {
        final body = jsonDecode(res.body);
        _showSnack(body['error'] ?? "Erreur lors de l'annulation.", color: _errorRed);
      }
    } catch (_) {
      _showSnack('Impossible de joindre le serveur.', color: _errorRed);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0 || _reviewLoading) return;

    setState(() => _reviewLoading = true);
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/reviews'),
        headers: _headers,
        body: jsonEncode({
          'clientID': widget.clientID,
          'coachID': _session.coachID,
          'rating': _selectedRating,
          'comment': _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 201) {
        setState(() {
          _reviewSubmitted = true;
          _session = _session.copyWith(
            reviewRating: _selectedRating,
            reviewComment: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
          );
        });
        _showSnack('Avis publié avec succès !', color: _success);
      } else {
        final body = jsonDecode(res.body);
        _showSnack(body['error'] ?? 'Erreur lors de la publication.', color: _errorRed);
      }
    } catch (_) {
      _showSnack('Impossible de joindre le serveur.', color: _errorRed);
    } finally {
      if (mounted) setState(() => _reviewLoading = false);
    }
  }

  void _showSnack(String msg, {required Color color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color.withOpacity(0.9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: _card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            content: Text(message, style: const TextStyle(color: Colors.white54, fontSize: 13)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('RETOUR', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w700)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel, style: TextStyle(color: confirmColor, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              right: -100,
              top: 80,
              child: _LogoWatermark(size: 280),
            ),
            SlideTransition(
              position: _slideUp,
              child: FadeTransition(
                opacity: _fadeIn,
                child: Column(children: [
                  _buildTopBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _buildStatusBanner(),
                        const SizedBox(height: 22),
                        _buildInfoCard(),
                        const SizedBox(height: 20),
                        _buildCoachCard(),
                        const SizedBox(height: 20),
                        if (_canReview) _buildReviewSection(),
                        if (_session.isUpcoming && !_sessionIsPast) _buildUpcomingActions(),
                        if (_session.isCancelled) _buildCancelledInfo(),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() => Container(
        decoration: BoxDecoration(color: _card, border: Border(bottom: BorderSide(color: _cardBorder, width: 1))),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context, _session),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration:
                  BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(12), border: Border.all(color: _cardBorder)),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Détail de la séance',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
            const SizedBox(height: 3),
            Text(_session.coachName, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _statusColor.withOpacity(0.4))),
            child: Text(_statusLabel,
                style: TextStyle(color: _statusColor, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          ),
        ]),
      );

  Widget _buildStatusBanner() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [_statusColor.withOpacity(0.22), _statusColor.withOpacity(0.06)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _statusColor.withOpacity(0.3), width: 1.5),
            boxShadow: [BoxShadow(color: _statusColor.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 8))]),
        child: Row(children: [
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_session.price > 0 ? '${_session.price.toInt()} MAD' : 'En attente de tarification',
                style: TextStyle(color: _statusColor, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1)),
            const SizedBox(height: 6),
            Text('${_session.durationMin} min · ${_formatTime(_session.sessionStart)} — ${_formatTime(_session.sessionEnd)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ])),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _statusColor.withOpacity(0.3))),
            child: Icon(
                _session.isConfirmed
                    ? Icons.check_circle_rounded
                    : _session.isPending
                        ? Icons.schedule_rounded
                        : Icons.cancel_rounded,
                color: _statusColor,
                size: 28),
          ),
        ]),
      );

  Widget _buildInfoCard() => Container(
        decoration:
            BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(16), border: Border.all(color: _cardBorder)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          _infoRow(Icons.calendar_today_rounded, 'Date', _formatDate(_session.sessionStart), isFirst: true),
          _divider(),
          _infoRow(Icons.access_time_rounded, 'Horaire',
              '${_formatTime(_session.sessionStart)} — ${_formatTime(_session.sessionEnd)}'),
          _divider(),
          _infoRow(Icons.schedule_rounded, 'Durée', '${_session.durationMin} minutes'),
          _divider(),
          _infoRow(Icons.location_on_rounded, 'Lieu', _session.location.isNotEmpty ? _session.location : '—'),
          _divider(),
          _infoRow(Icons.business_rounded, 'Société', _session.companyName.isNotEmpty ? _session.companyName : '—'),
          _divider(),
          _infoRow(Icons.receipt_long_rounded, 'Réf.', '#${_session.id.toString().padLeft(5, '0')}', isLast: true),
        ]),
      );

  Widget _infoRow(IconData icon, String label, String value, {bool isFirst = false, bool isLast = false}) => Padding(
        padding: EdgeInsets.fromLTRB(18, isFirst ? 16 : 12, 18, isLast ? 16 : 12),
        child: Row(children: [
          Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: _lime.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: _lime, size: 18)),
          const SizedBox(width: 16),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.4)),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          ])),
        ]),
      );

  Widget _divider() => Divider(height: 1, color: Colors.white.withOpacity(0.06));

  Widget _buildCoachCard() => GestureDetector(
        onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) =>
                  CoachDetailScreen(session: _session, clientID: widget.clientID, token: widget.token),
              transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
              transitionDuration: const Duration(milliseconds: 350),
            )),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _cardBorder),
              boxShadow: [BoxShadow(color: _lime.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))]),
          child: Row(children: [
            Container(
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _lime.withOpacity(0.4), width: 2.5),
                  boxShadow: [BoxShadow(color: _lime.withOpacity(0.1), blurRadius: 12)]),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF1A1A1A),
                backgroundImage: _session.coachImageUrl.isNotEmpty ? NetworkImage(_session.coachImageUrl) : null,
                child: _session.coachImageUrl.isEmpty
                    ? Text(_session.coachName.isNotEmpty ? _session.coachName[0].toUpperCase() : '?',
                        style: const TextStyle(color: _lime, fontWeight: FontWeight.w900))
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_session.coachName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.3)),
              const SizedBox(height: 4),
              Text(_session.coachSpeciality, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 6),
              if (_session.coachRating > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _lime.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star_rounded, color: _lime, size: 12),
                    const SizedBox(width: 4),
                    Text('${_session.coachRating.toStringAsFixed(1)}/5',
                        style: const TextStyle(color: _lime, fontWeight: FontWeight.w700, fontSize: 11)),
                  ]),
                ),
            ])),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 24),
          ]),
        ),
      );

  Widget _buildUpcomingActions() => Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: _cancelling ? null : _cancelSession,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                  color: _errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _errorRed.withOpacity(0.3))),
              child: _cancelling
                  ? const Center(
                      child: SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(color: _errorRed, strokeWidth: 2)))
                  : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.close_rounded, color: _errorRed, size: 16),
                      SizedBox(width: 8),
                      Text('ANNULER',
                          style: TextStyle(color: _errorRed, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.3)),
                    ]),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _statusColor.withOpacity(0.3))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(_session.isPending ? Icons.hourglass_top_rounded : Icons.check_rounded, color: _statusColor, size: 16),
              const SizedBox(width: 8),
              Text(_session.isPending ? 'EN ATTENTE' : 'CONFIRMÉE',
                  style: TextStyle(color: _statusColor, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.3)),
            ]),
          ),
        ),
      ]);

  Widget _buildCancelledInfo() {
    final reason = _session.cancellationReason ?? _session.rejectionReason ?? '';
    if (reason.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: _errorRed.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _errorRed.withOpacity(0.22))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.info_outline_rounded, color: _errorRed, size: 14),
          SizedBox(width: 8),
          Text("Motif d'annulation",
              style: TextStyle(color: _errorRed, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 8),
        Text(reason, style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.5)),
      ]),
    );
  }

  Widget _buildReviewSection() {
    final alreadyReviewed = _session.reviewRating != null || _reviewSubmitted;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(22),
      decoration:
          BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(18), border: Border.all(color: _cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 3, height: 20, color: _lime, margin: const EdgeInsets.only(right: 12)),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Partagez votre avis',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            const SizedBox(height: 2),
            const Text('Aidez les autres à choisir le bon coach', style: TextStyle(color: Colors.white38, fontSize: 11)),
          ])),
          if (alreadyReviewed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: _success.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: const Row(children: [
                Icon(Icons.check_circle_rounded, color: _success, size: 12),
                SizedBox(width: 4),
                Text('PUBLIÉ', style: TextStyle(color: _success, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
              ]),
            ),
        ]),
        const SizedBox(height: 20),
        alreadyReviewed ? _buildReviewDisplay() : _buildReviewForm(),
      ]),
    );
  }

  Widget _buildReviewDisplay() {
    final rating = _session.reviewRating ?? _selectedRating;
    final comment = _session.reviewComment ?? (_commentCtrl.text.isNotEmpty ? _commentCtrl.text : null);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        ...List.generate(
            5,
            (i) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(i < rating ? Icons.star_rounded : Icons.star_outline_rounded, color: _lime, size: 30),
                )),
        const SizedBox(width: 12),
        Text('$rating/5', style: const TextStyle(color: _lime, fontSize: 22, fontWeight: FontWeight.w900)),
      ]),
      if (comment != null && comment.isNotEmpty) ...[
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.07))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Commentaire', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600)),
            const SizedBox(height: 7),
            Text(comment, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5)),
          ]),
        ),
      ],
    ]);
  }

  Widget _buildReviewForm() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Comment s'est passée votre séance ?", style: TextStyle(color: Colors.white60, fontSize: 13)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final filled = i < (_hoverRating > 0 ? _hoverRating : _selectedRating);
            return GestureDetector(
              onTap: () => setState(() => _selectedRating = i + 1),
              child: MouseRegion(
                onEnter: (_) => setState(() => _hoverRating = i + 1),
                onExit: (_) => setState(() => _hoverRating = 0),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 150),
                  scale: filled ? 1.1 : 1.0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(filled ? Icons.star_rounded : Icons.star_outline_rounded, color: _lime, size: 40),
                  ),
                ),
              ),
            );
          }),
        ),
        if (_selectedRating > 0) ...[
          const SizedBox(height: 8),
          Center(
              child: Text(_ratingText(_selectedRating),
                  style: const TextStyle(color: _lime, fontSize: 12, fontWeight: FontWeight.w600))),
        ],
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.09))),
          child: TextField(
            controller: _commentCtrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Partagez les détails... (optionnel)',
              hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(14),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: (_selectedRating > 0 && !_reviewLoading) ? _submitReview : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                  color: _selectedRating > 0 ? _lime : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _selectedRating > 0 ? _lime.withOpacity(0.3) : Colors.white.withOpacity(0.08))),
              child: _reviewLoading
                  ? const Center(
                      child: SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.send_rounded, color: _selectedRating > 0 ? Colors.black : Colors.white24, size: 15),
                      const SizedBox(width: 8),
                      Text('PUBLIER MON AVIS',
                          style: TextStyle(
                              color: _selectedRating > 0 ? Colors.black : Colors.white24,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 1.2)),
                    ]),
            ),
          ),
        ),
      ]);

  String _ratingText(int r) {
    const texts = ['', 'À améliorer', 'Correct', 'Bien', 'Très bien', 'Excellent !'];
    return texts[r.clamp(0, 5)];
  }
}