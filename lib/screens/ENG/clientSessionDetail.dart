import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fitlek1/models/anas/reservation.dart';
import 'clientCoachDetail.dart';
import 'package:fitlek1/constants/urls.dart';
import '../../theme/fitlek_theme_extension.dart';


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

class _SessionDetailScreenState extends State<SessionDetailScreen>
    with SingleTickerProviderStateMixin {
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

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    if (_session.reviewRating != null) {
      _selectedRating = _session.reviewRating!;
      _reviewSubmitted = true;
      if (_session.reviewComment != null) {
        _commentCtrl.text = _session.reviewComment!;
      }
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
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return '${days[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  // Une session pending dont l'heure est dépassée est traitée
  // comme "annulée" (expirée) côté affichage : le coach n'a jamais répondu.
  bool get _isExpiredPending =>
      _session.isPending && _session.sessionStart.isBefore(DateTime.now());

  String get _effectiveStatus =>
      _isExpiredPending ? 'cancelled' : _session.status;

  Color get _statusColor {
    switch (_effectiveStatus) {
      case 'confirmed':
        return context.fitlek.success;
      case 'pending':
        return Theme.of(context).colorScheme.primary;
      default:
        return context.fitlek.error;
    }
  }

  String get _statusLabel {
    switch (_effectiveStatus) {
      case 'pending':
        return 'PENDING';
      case 'confirmed':
        return 'CONFIRMED';
      default:
        return _isExpiredPending ? 'EXPIRED' : 'CANCELLED';
    }
  }

  bool get _sessionIsPast => _session.sessionStart.isBefore(DateTime.now());

  bool get _canReview => _session.isConfirmed && _sessionIsPast;

  Future<void> _cancelSession() async {
    final errorColor = context.fitlek.error;
    final confirm = await _showConfirmDialog(
      title: 'Cancel session?',
      message: 'This action cannot be undone.',
      confirmLabel: 'CANCEL SESSION',
      confirmColor: errorColor,
    );
    if (!confirm) return;

    setState(() => _cancelling = true);
    try {
      final res = await http
          .patch(
            Uri.parse('$baseUrl/reservations/${_session.id}/cancel'),
            headers: _headers,
            body: jsonEncode({
              'cancellationReason': 'Cancelled by client',
              'userID': widget.clientID,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final updated = _session.copyWith(status: 'cancelled');
        setState(() => _session = updated);
        _showSnack('Session cancelled.', color: errorColor);
        if (mounted) Navigator.pop(context, updated);
      } else {
        final body = jsonDecode(res.body);
        _showSnack(body['error'] ?? 'Error while cancelling.',
            color: errorColor);
      }
    } catch (_) {
      _showSnack('Unable to reach the server.', color: errorColor);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0 || _reviewLoading) return;

    final successColor = context.fitlek.success;
    final errorColor = context.fitlek.error;
    setState(() => _reviewLoading = true);
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/reviews'),
            headers: _headers,
            body: jsonEncode({
              'clientID': widget.clientID,
              'coachID': _session.coachID,
              'rating': _selectedRating,
              'comment': _commentCtrl.text.trim().isEmpty
                  ? null
                  : _commentCtrl.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 201) {
        setState(() {
          _reviewSubmitted = true;
          _session = _session.copyWith(
            reviewRating: _selectedRating,
            reviewComment: _commentCtrl.text.trim().isEmpty
                ? null
                : _commentCtrl.text.trim(),
          );
        });
        _showSnack('Review published successfully!', color: successColor);
      } else {
        final body = jsonDecode(res.body);
        _showSnack(body['error'] ?? 'Error while publishing.',
            color: errorColor);
      }
    } catch (_) {
      _showSnack('Unable to reach the server.', color: errorColor);
    } finally {
      if (mounted) setState(() => _reviewLoading = false);
    }
  }

  void _showSnack(String msg, {required Color color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color.withValues(alpha: 0.9),
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
            backgroundColor: context.fitlek.card,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(title,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w800)),
            content: Text(message,
                style: TextStyle(
                    color: context.fitlek.textSecondary, fontSize: 13)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('BACK',
                    style: TextStyle(
                        color: context.fitlek.textMuted,
                        fontWeight: FontWeight.w700)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel,
                    style: TextStyle(
                        color: confirmColor, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            SlideTransition(
              position: _slideUp,
              child: FadeTransition(
                opacity: _fadeIn,
                child: Column(children: [
                  _buildTopBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatusBanner(),
                            const SizedBox(height: 22),
                            _buildInfoCard(),
                            const SizedBox(height: 20),
                            _buildCoachCard(),
                            const SizedBox(height: 20),
                            if (_canReview) _buildReviewSection(),
                            if (_session.isUpcoming && !_sessionIsPast)
                              _buildUpcomingActions(),
                            if (_session.isCancelled || _isExpiredPending)
                              _buildCancelledInfo(),
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
        decoration: BoxDecoration(
            color: context.fitlek.card,
            border: Border(
                bottom: BorderSide(color: context.fitlek.border, width: 1))),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context, _session),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: context.fitlek.card2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.fitlek.border)),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: Theme.of(context).colorScheme.onSurface, size: 16),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Session details',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5)),
                const SizedBox(height: 3),
                Text(_session.coachName,
                    style: TextStyle(
                        color: context.fitlek.textMuted, fontSize: 12)),
              ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _statusColor.withValues(alpha: 0.4))),
            child: Text(_statusLabel,
                style: TextStyle(
                    color: _statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2)),
          ),
        ]),
      );

  Widget _buildStatusBanner() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              _statusColor.withValues(alpha: 0.22),
              _statusColor.withValues(alpha: 0.06)
            ], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: _statusColor.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: _statusColor.withValues(alpha: 0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 8))
            ]),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                    _session.price > 0
                        ? '${_session.price.toInt()} MAD'
                        : 'Awaiting pricing',
                    style: TextStyle(
                        color: _statusColor,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1)),
                const SizedBox(height: 6),
                Text(
                    '${_session.durationMin} min · ${_formatTime(_session.sessionStart)} — ${_formatTime(_session.sessionEnd)}',
                    style: TextStyle(
                        color: context.fitlek.textSecondary, fontSize: 12)),
              ])),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _statusColor.withValues(alpha: 0.3))),
            child: Icon(
                _effectiveStatus == 'confirmed'
                    ? Icons.check_circle_rounded
                    : _effectiveStatus == 'pending'
                        ? Icons.schedule_rounded
                        : Icons.cancel_rounded,
                color: _statusColor,
                size: 28),
          ),
        ]),
      );

  Widget _buildInfoCard() => Container(
        decoration: BoxDecoration(
            color: context.fitlek.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.fitlek.border)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          _infoRow(Icons.calendar_today_rounded, 'Date',
              _formatDate(_session.sessionStart),
              isFirst: true),
          _divider(),
          _infoRow(Icons.access_time_rounded, 'Time',
              '${_formatTime(_session.sessionStart)} — ${_formatTime(_session.sessionEnd)}'),
          _divider(),
          _infoRow(Icons.schedule_rounded, 'Duration',
              '${_session.durationMin} minutes'),
          _divider(),
          _infoRow(Icons.location_on_rounded, 'Location',
              _session.location.isNotEmpty ? _session.location : '—'),
          _divider(),
          _infoRow(Icons.business_rounded, 'Company',
              _session.companyName.isNotEmpty ? _session.companyName : '—'),
          _divider(),
          _infoRow(Icons.receipt_long_rounded, 'Ref.',
              '#${_session.id.toString().padLeft(5, '0')}',
              isLast: true),
        ]),
      );

  Widget _infoRow(IconData icon, String label, String value,
          {bool isFirst = false, bool isLast = false}) =>
      Padding(
        padding:
            EdgeInsets.fromLTRB(18, isFirst ? 16 : 12, 18, isLast ? 16 : 12),
        child: Row(children: [
          Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon,
                  color: Theme.of(context).colorScheme.primary, size: 18)),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: TextStyle(
                        color: context.fitlek.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4)),
                const SizedBox(height: 3),
                Text(value,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ])),
        ]),
      );

  Widget _divider() => Divider(height: 1, color: context.fitlek.border);

  Widget _buildCoachCard() => GestureDetector(
        onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => CoachDetailScreen(
                  session: _session,
                  clientID: widget.clientID,
                  token: widget.token),
              transitionsBuilder: (_, a, __, child) =>
                  FadeTransition(opacity: a, child: child),
              transitionDuration: const Duration(milliseconds: 350),
            )),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: context.fitlek.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.fitlek.border),
              boxShadow: [
                BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4))
              ]),
          child: Row(children: [
            Container(
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.4),
                      width: 2.5),
                  boxShadow: [
                    BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        blurRadius: 12)
                  ]),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: context.fitlek.card2,
                backgroundImage: _session.coachImageUrl.isNotEmpty
                    ? NetworkImage(_session.coachImageUrl)
                    : null,
                child: _session.coachImageUrl.isEmpty
                    ? Text(
                        _session.coachName.isNotEmpty
                            ? _session.coachName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w900))
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(_session.coachName,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  Text(_session.coachSpeciality,
                      style: TextStyle(
                          color: context.fitlek.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  if (_session.coachRating > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.star_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 12),
                        const SizedBox(width: 4),
                        Text('${_session.coachRating.toStringAsFixed(1)}/5',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 11)),
                      ]),
                    ),
                ])),
            Icon(Icons.chevron_right_rounded,
                color: context.fitlek.textMuted, size: 24),
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
                  color: context.fitlek.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: context.fitlek.error.withValues(alpha: 0.3))),
              child: _cancelling
                  ? Center(
                      child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: context.fitlek.error, strokeWidth: 2)))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.close_rounded,
                          color: context.fitlek.error, size: 16),
                      const SizedBox(width: 8),
                      Text('CANCEL',
                          style: TextStyle(
                              color: context.fitlek.error,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 1.3)),
                    ]),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _statusColor.withValues(alpha: 0.3))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(
                  _session.isPending
                      ? Icons.hourglass_top_rounded
                      : Icons.check_rounded,
                  color: _statusColor,
                  size: 16),
              const SizedBox(width: 8),
              Text(_session.isPending ? 'PENDING' : 'CONFIRMED',
                  style: TextStyle(
                      color: _statusColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.3)),
            ]),
          ),
        ),
      ]);

  Widget _buildCancelledInfo() {
    final reason = _session.cancellationReason ??
        _session.rejectionReason ??
        (_isExpiredPending
            ? 'This request expired without a response from the coach.'
            : '');
    if (reason.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: context.fitlek.error.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: context.fitlek.error.withValues(alpha: 0.22))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.info_outline_rounded,
              color: context.fitlek.error, size: 14),
          const SizedBox(width: 8),
          Text(_isExpiredPending ? 'Request expired' : 'Cancellation reason',
              style: TextStyle(
                  color: context.fitlek.error,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 8),
        Text(reason,
            style: TextStyle(
                color: context.fitlek.textSecondary,
                fontSize: 13,
                height: 1.5)),
      ]),
    );
  }

  Widget _buildReviewSection() {
    final alreadyReviewed = _session.reviewRating != null || _reviewSubmitted;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          color: context.fitlek.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.fitlek.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 3,
              height: 20,
              color: Theme.of(context).colorScheme.primary,
              margin: const EdgeInsets.only(right: 12)),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Share your review',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3)),
                const SizedBox(height: 2),
                Text('Help others choose the right coach',
                    style: TextStyle(
                        color: context.fitlek.textMuted, fontSize: 11)),
              ])),
          if (alreadyReviewed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                  color: context.fitlek.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(Icons.check_circle_rounded,
                    color: context.fitlek.success, size: 12),
                const SizedBox(width: 4),
                Text('PUBLISHED',
                    style: TextStyle(
                        color: context.fitlek.success,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8)),
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
    final comment = _session.reviewComment ??
        (_commentCtrl.text.isNotEmpty ? _commentCtrl.text : null);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        ...List.generate(
            5,
            (i) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                      i < rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 30),
                )),
        const SizedBox(width: 12),
        Text('$rating/5',
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 22,
                fontWeight: FontWeight.w900)),
      ]),
      if (comment != null && comment.isNotEmpty) ...[
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: context.fitlek.card2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.fitlek.border)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Comment',
                style: TextStyle(
                    color: context.fitlek.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 7),
            Text(comment,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 13,
                    height: 1.5)),
          ]),
        ),
      ],
    ]);
  }

  Widget _buildReviewForm() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('How was your session?',
            style:
                TextStyle(color: context.fitlek.textSecondary, fontSize: 13)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final filled =
                i < (_hoverRating > 0 ? _hoverRating : _selectedRating);
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
                    child: Icon(
                        filled
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 40),
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
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600))),
        ],
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(
              color: context.fitlek.inputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.fitlek.border)),
          child: TextField(
            controller: _commentCtrl,
            maxLines: 3,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Share the details... (optional)',
              hintStyle:
                  TextStyle(color: context.fitlek.textMuted, fontSize: 12),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap:
                (_selectedRating > 0 && !_reviewLoading) ? _submitReview : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                  color: _selectedRating > 0
                      ? Theme.of(context).colorScheme.primary
                      : context.fitlek.card2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _selectedRating > 0
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.3)
                          : context.fitlek.border)),
              child: _reviewLoading
                  ? Center(
                      child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.onPrimary,
                              strokeWidth: 2)))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.send_rounded,
                          color: _selectedRating > 0
                              ? Theme.of(context).colorScheme.onPrimary
                              : context.fitlek.textMuted,
                          size: 15),
                      const SizedBox(width: 8),
                      Text('PUBLISH MY REVIEW',
                          style: TextStyle(
                              color: _selectedRating > 0
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : context.fitlek.textMuted,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 1.2)),
                    ]),
            ),
          ),
        ),
      ]);

  String _ratingText(int r) {
    const texts = [
      '',
      'Needs improvement',
      'Okay',
      'Good',
      'Very good',
      'Excellent!'
    ];
    return texts[r.clamp(0, 5)];
  }
}