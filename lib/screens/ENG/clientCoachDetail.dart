
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:fitlek1/constants/urls.dart';
import 'package:fitlek1/models/anas/reservation.dart';
import 'package:fitlek1/models/anas/coach.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'clientBooking.dart';
import 'clientConversation.dart';
import '../../theme/fitlek_theme_extension.dart';

class _ReviewItem {
  final int id;
  final int coachID;
  final int clientID;
  final int rating;
  final String? comment;
  final String clientName;
  final String? clientAvatar;
  final DateTime createdAt;

  const _ReviewItem({
    required this.id,
    required this.coachID,
    required this.clientID,
    required this.rating,
    this.comment,
    required this.clientName,
    this.clientAvatar,
    required this.createdAt,
  });

  factory _ReviewItem.fromJson(Map<String, dynamic> j) => _ReviewItem(
        id: j['id'],
        coachID: j['coachID'],
        clientID: j['clientID'],
        rating: j['rating'],
        comment: j['comment'],
        clientName: j['clientName'] ?? 'Anonymous',
        clientAvatar: j['clientAvatar'],
        createdAt: DateTime.parse(j['createdAt']),
      );
}

class CoachDetailScreen extends StatefulWidget {
  final ReservationModel session;
  final int clientID;
  final String token;

  const CoachDetailScreen({
    super.key,
    required this.session,
    required this.clientID,
    required this.token,
  });

  @override
  State<CoachDetailScreen> createState() => _CoachDetailScreenState();
}

class _CoachDetailScreenState extends State<CoachDetailScreen>
    with SingleTickerProviderStateMixin {
  CoachModel? _coach;
  List<_ReviewItem> _reviews = [];
  double _avgRating = 0;
  int _totalReviews = 0;
  _ReviewItem? _myReview;

  bool _loadingCoach = true;
  bool _loadingReviews = true;
  String? _errorCoach;

  int _pendingRating = 0;
  bool _submittingReview = false;
  final _commentCtrl = TextEditingController();
  bool _showReviewForm = false;

  bool _sendingInvite = false;
  String _inviteStatus = 'none';
  int? _conversationID;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _fetchAll();
    _checkInvitationStatus();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    await Future.wait([_fetchCoach(), _fetchReviews()]);
    _animCtrl.forward();
  }

  Future<void> _fetchCoach() async {
    setState(() {
      _loadingCoach = true;
      _errorCoach = null;
    });
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/coaches/${widget.session.coachID}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final jsonData = jsonDecode(res.body);
        setState(() {
          _coach = CoachModel.fromJson(jsonData);
          _loadingCoach = false;
        });
      } else {
        setState(() {
          _errorCoach = 'Error ${res.statusCode}';
          _loadingCoach = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorCoach = 'Unable to reach the server.';
        _loadingCoach = false;
      });
    }
  }
Widget _buildQrCode(CoachModel c) {
  final code = c.invitationCode;
  if (code.isEmpty) return const SizedBox.shrink();

  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.fitlek.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.fitlek.border),
      ),
      child: Column(
        children: [
          Row(children: [
            _sectionHeader('Coach QR Code'),
          ]),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showQrDialog(code),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: QrImageView(
                data: code,
                version: QrVersions.auto,
                size: 140,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text('Tap to enlarge or scan',
              style: TextStyle(color: context.fitlek.textMuted, fontSize: 11)),
        ],
      ),
    ),
  );
}

void _showQrDialog(String code) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: context.fitlek.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Coach QR Code',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: QrImageView(data: code, version: QrVersions.auto, size: 220),
            ),
            const SizedBox(height: 16),
            Text(code,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5)),
          ],
        ),
      ),
    ),
  );
}
  Future<void> _fetchReviews() async {
    setState(() => _loadingReviews = true);
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/reviews/coach/${widget.session.coachID}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (data['reviews'] as List)
            .map((e) => _ReviewItem.fromJson(e))
            .toList();
        final myReview =
            list.where((r) => r.clientID == widget.clientID).isNotEmpty
                ? list.firstWhere((r) => r.clientID == widget.clientID)
                : null;

        setState(() {
          _reviews = list;
          _avgRating = (data['avg'] as num).toDouble();
          _totalReviews = data['total'] as int;
          _myReview = myReview;
          if (myReview != null) {
            _pendingRating = myReview.rating;
            _commentCtrl.text = myReview.comment ?? '';
          }
          _loadingReviews = false;
        });
      }
    } catch (e) {
      setState(() => _loadingReviews = false);
    }
  }

  Future<void> _submitReview() async {
    if (_pendingRating == 0) {
      _showSnack('Select a rating first', isError: true);
      return;
    }
    setState(() => _submittingReview = true);
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/reviews'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${widget.token}',
            },
            body: jsonEncode({
              'coachID': widget.session.coachID,
              'clientID': widget.clientID,
              'rating': _pendingRating,
              'comment': _commentCtrl.text.trim().isEmpty
                  ? null
                  : _commentCtrl.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 201) {
        _showSnack('Review saved ✓');
        setState(() {
          _showReviewForm = false;
        });
        await _fetchReviews();
      } else {
        final body = jsonDecode(res.body);
        _showSnack(body['error'] ?? 'Server error', isError: true);
      }
    } catch (e) {
      _showSnack('Connection failed', isError: true);
    } finally {
      setState(() => _submittingReview = false);
    }
  }

  Future<void> _sendInvitation() async {
    setState(() => _sendingInvite = true);
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/invitations/send'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${widget.token}',
            },
            body: jsonEncode({
              'senderID': widget.clientID,
              'coachID': widget.session.coachID,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 201) {
        _showSnack('Invitation sent to the coach ✓');
        setState(() => _inviteStatus = 'pending');
      } else if (res.statusCode == 409) {
        _showSnack('Invitation already sent', isError: true);
        setState(() => _inviteStatus = 'pending');
      } else {
        final body = jsonDecode(res.body);
        _showSnack(body['error'] ?? 'Server error', isError: true);
      }
    } catch (e) {
      _showSnack('Connection failed', isError: true);
    } finally {
      setState(() => _sendingInvite = false);
    }
  }

  Future<void> _checkInvitationStatus() async {
    try {
      final res = await http.get(
        Uri.parse(
            '$baseUrl/invitations/status/${widget.session.coachID}/${widget.clientID}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final status = data['status'];
        if (status != null) {
          setState(() => _inviteStatus = status);
        }
        if (status == 'accepted') {
          await _fetchConversation();
        }
      }
    } catch (_) {
      // Best-effort: invitation status is non-critical, ignore failures.
    }
  }

  Future<void> _fetchConversation() async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/conversations/find-or-create'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${widget.token}',
            },
            body: jsonEncode({
              'clientID': widget.clientID,
              'coachID': widget.session.coachID,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() => _conversationID = data['conversationID']);
      }
    } catch (_) {
      // Best-effort: conversation lookup is non-critical, ignore failures.
    }
  }

  void _openConversation() {
    if (_conversationID == null) return;
    Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => ClientConversationScreen(
            conversationID: _conversationID!,
            clientID: widget.clientID,
            token: widget.token,
            coachName: _coach?.fullName ?? widget.session.coachName,
            coachAvatar: _coach?.avatarUrl ?? widget.session.coachImageUrl,
            coachSpeciality:
                _coach?.speciality ?? widget.session.coachSpeciality,
          ),
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
          transitionDuration: const Duration(milliseconds: 380),
        ));
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: TextStyle(
              color: isError
                  ? Theme.of(context).colorScheme.onError
                  : Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w700)),
      backgroundColor:
          isError ? Colors.redAccent : Theme.of(context).colorScheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCoach) return _buildLoading();
    if (_errorCoach != null) return _buildError();
    return _buildContent();
  }

 Widget _buildLoading() => Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 84,
              height: 84,
              child: Image.asset(
                'assets/branding/icon_app.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 14),
           
          ],
        ),
      ),
    );

  Widget _buildError() => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
            child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Align(
                alignment: Alignment.centerLeft,
                child: _backBtn(onTap: () => Navigator.pop(context))),
          ),
          Expanded(
              child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.wifi_off_rounded,
                color: context.fitlek.textMuted, size: 48),
            const SizedBox(height: 12),
            Text(_errorCoach!,
                style:
                    TextStyle(color: context.fitlek.textMuted, fontSize: 13)),
            const SizedBox(height: 20),
            _retryBtn(onTap: _fetchAll),
          ]))),
        ])),
      );

  Widget _buildContent() {
    final s = widget.session;
    final c = _coach!;

    final imageUrl =
        (c.avatarUrl?.isNotEmpty == true) ? c.avatarUrl! : s.coachImageUrl;
    final name = c.fullName.isNotEmpty ? c.fullName : s.coachName;
    final speciality =
        (c.speciality?.isNotEmpty == true) ? c.speciality! : s.coachSpeciality;
    final rating = _avgRating > 0 ? _avgRating : (c.rating ?? s.coachRating);

    final canReview = s.isConfirmed && s.sessionStart.isBefore(DateTime.now());

    return FadeTransition(
      opacity: _fadeAnim,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: CustomScrollView(slivers: [
          SliverToBoxAdapter(
              child: _buildHero(context, imageUrl, name, speciality, rating)),
          SliverToBoxAdapter(
              child: _buildStats(rating, c.totalInvitations, _totalReviews)),
          if (c.ville != null || c.tel != null)
            SliverToBoxAdapter(child: _buildContactInfo(c)),
          if (c.instagramPage.isNotEmpty)
            SliverToBoxAdapter(child: _buildInstagram(c.instagramPage)),
          if (speciality.isNotEmpty)
            SliverToBoxAdapter(child: _buildTags(speciality)),
          if (c.bio.isNotEmpty) SliverToBoxAdapter(child: _buildBio(c.bio)),
          SliverToBoxAdapter(child: _buildInviteCTA()),
          SliverToBoxAdapter(child: _buildBookCTA(context, s)),
          SliverToBoxAdapter(child: _buildQrCode(c)), 
          SliverToBoxAdapter(child: _buildReviewsSection(rating, canReview)),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ]),
      ),
    );
  }

  Widget _buildHero(BuildContext ctx, String imageUrl, String name,
      String speciality, double rating) {
    return SizedBox(
      height: 380,
      child: Stack(children: [
        Positioned.fill(
          child: imageUrl.isNotEmpty
              ? Image.network(imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, p) =>
                      p == null ? child : Container(color: context.fitlek.card),
                  errorBuilder: (_, __, ___) => _avatarPlaceholder(name))
              : _avatarPlaceholder(name),
        ),
       Positioned.fill(
  child: DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,                                                    // Haut : image visible
          Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.3),      // Transition
          Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.85),   // Fond dominant
          Theme.of(context).scaffoldBackgroundColor,                            // Bas : opaque
        ],
        stops: const [0.0, 0.5, 0.85, 1.0],
      ),
    ),
  ),
),
        Positioned(
            top: 52,
            left: 16,
            child: SafeArea(
                child: _backBtn(
                    onTap: () => Navigator.pop(ctx), transparent: true))),
        Positioned(
          top: 52,
          right: 16,
          child: SafeArea(
              child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.verified_rounded,
                  color: Theme.of(context).colorScheme.onPrimary, size: 11),
              const SizedBox(width: 4),
              Text('VERIFIED',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4)),
            ]),
          )),
        ),
        if (_avgRating > 0 || _totalReviews > 0)
          Positioned(
            bottom: 76,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.4))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.star_rounded,
                    color: Theme.of(context).colorScheme.primary, size: 13),
                const SizedBox(width: 4),
                Text(
                    _avgRating > 0
                        ? '${_avgRating.toStringAsFixed(1)}  •  $_totalReviews reviews'
                        : '$_totalReviews reviews',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    height: 1.0)),
            const SizedBox(height: 5),
            Text(speciality,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
            // --- AJOUT : Afficher la ville si elle existe ---
            
            // --- FIN AJOUT ---
          ]),
        ),
      ]),
    );
  }

  Widget _avatarPlaceholder(String name) => Container(
        color: context.fitlek.card,
        child: Center(
            child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 72,
              fontWeight: FontWeight.w900),
        )),
      );

  Widget _buildStats(double rating, int totalInvitations, int totalReviews) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        _statBox(totalReviews > 0 ? rating.toStringAsFixed(1) : '—', 'Rating',
            Icons.star_rounded),
        const SizedBox(width: 10),
        _statBox('$totalReviews', 'Reviews', Icons.chat_bubble_outline_rounded),
        const SizedBox(width: 10),
        _statBox('$totalInvitations', 'Invitations', Icons.group_add_outlined),
      ]),
    );
  }

  Widget _statBox(String value, String label, IconData icon) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: context.fitlek.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.fitlek.border, width: 1),
          ),
          child: Column(children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 16),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label,
                style:
                    TextStyle(color: context.fitlek.textMuted, fontSize: 10)),
          ]),
        ),
      );

  Widget _buildContactInfo(CoachModel c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.fitlek.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.fitlek.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                  width: 3,
                  height: 16,
                  color: Theme.of(context).colorScheme.primary,
                  margin: const EdgeInsets.only(right: 10)),
              Text('Practical info',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 14),
            if (c.ville != null && c.ville!.isNotEmpty)
              _infoRow(
                icon: Icons.location_on_rounded,
                label: 'City',
                value: c.ville!,
                valueColor: Theme.of(context).colorScheme.primary,
                onTap: null,
              ),
            if (c.ville != null && c.ville!.isNotEmpty && c.tel != null)
              const SizedBox(height: 12),
            if (c.tel != null)
              _infoRow(
                icon: Icons.phone_rounded,
                label: 'Phone',
                value: c.tel!,
                valueColor: Theme.of(context).colorScheme.onSurface,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: c.tel!));
                  _showSnack('Number copied ✓');
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
    VoidCallback? onTap,
  }) {
    final child = Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon,
              color: Theme.of(context).colorScheme.primary, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      TextStyle(color: context.fitlek.textMuted, fontSize: 10)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (onTap != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2)),
            ),
            child: Text('COPY',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5)),
          ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: child,
      );
    }
    return child;
  }

  Widget _buildTags(String speciality) {
    final tags = speciality
        .split(RegExp(r'[,/]'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags
              .map((tag) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.25))),
                    child: Text(tag,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3)),
                  ))
              .toList()),
    );
  }

  Widget _buildInstagram(String handle) {
    final display = handle.startsWith('http') ? handle.split('/').last : handle;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: context.fitlek.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.fitlek.border)),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: context.fitlek.instagram.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.camera_alt_rounded,
                color: context.fitlek.instagram, size: 17),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Instagram',
                style:
                    TextStyle(color: context.fitlek.textMuted, fontSize: 10)),
            const SizedBox(height: 2),
            Text('@$display',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ]),
          const Spacer(),
          Icon(Icons.open_in_new_rounded,
              color: context.fitlek.textMuted, size: 16),
        ]),
      ),
    );
  }

  Widget _buildBio(String bio) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader('About'),
          const SizedBox(height: 12),
          Text(bio,
              style: TextStyle(
                  color: context.fitlek.textSecondary,
                  fontSize: 13.5,
                  height: 1.7,
                  letterSpacing: 0.1)),
        ]),
      );

  Widget _buildInviteCTA() {
    final String btnText;
    final IconData btnIcon;
    final Color btnColor;
    final Color textColor;
    final bool isDisabled;
    final VoidCallback? onTap;

    switch (_inviteStatus) {
      case 'accepted':
        btnText = 'SEND A MESSAGE';
        btnIcon = Icons.chat_bubble_rounded;
        btnColor = Theme.of(context).colorScheme.primary;
        textColor = Theme.of(context).colorScheme.onPrimary;
        isDisabled = false;
        onTap = _openConversation;
        break;
      case 'pending':
        btnText = 'INVITATION SENT';
        btnIcon = Icons.schedule_rounded;
        btnColor =
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.15);
        textColor = Theme.of(context).colorScheme.primary;
        isDisabled = true;
        onTap = null;
        break;
      case 'refused':
        btnText = 'INVITATION DECLINED';
        btnIcon = Icons.cancel_rounded;
        btnColor = Colors.red.withValues(alpha: 0.15);
        textColor = Colors.redAccent;
        isDisabled = true;
        onTap = null;
        break;
      default:
        btnText = 'INVITE THIS COACH';
        btnIcon = Icons.person_add_rounded;
        btnColor = Theme.of(context).colorScheme.primary;
        textColor = Theme.of(context).colorScheme.onPrimary;
        isDisabled = false;
        onTap = _sendInvitation;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: GestureDetector(
        onTap: _sendingInvite ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
            color: btnColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _inviteStatus == 'accepted'
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                  : isDisabled
                      ? (_inviteStatus == 'refused'
                          ? Colors.red.withValues(alpha: 0.4)
                          : Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.4))
                      : Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.5),
              width: 1,
            ),
            // --- MODIFICATION : Ombre de la couleur de la page au lieu de noir ---
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.20),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
            // --- FIN MODIFICATION ---
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _sendingInvite
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(btnIcon, color: textColor, size: 16),
            const SizedBox(width: 8),
            Text(
              btnText,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1.8,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildBookCTA(BuildContext ctx, ReservationModel s) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: GestureDetector(
          onTap: () => Navigator.push(
              ctx,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => BookingScreen(
                  session: s,
                  clientID: widget.clientID,
                  token: widget.token,
                ),
                transitionsBuilder: (_, anim, __, child) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: anim, curve: Curves.easeOutCubic)),
                    child: child,
                  ),
                ),
                transitionDuration: const Duration(milliseconds: 380),
              )),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 17),
            decoration: BoxDecoration(
              color: context.fitlek.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.fitlek.border),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.calendar_month_rounded,
                  color: Theme.of(context).colorScheme.onSurface, size: 16),
              const SizedBox(width: 8),
              Text('BOOK A SESSION',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.8)),
            ]),
          ),
        ),
      );

  Widget _buildReviewsSection(double rating, bool canReview) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 28, 0, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            _sectionHeader('Client reviews'),
            const Spacer(),
            if (_totalReviews > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.25))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.star_rounded,
                      color: Theme.of(context).colorScheme.primary, size: 11),
                  const SizedBox(width: 4),
                  Text('${_avgRating.toStringAsFixed(1)} / 5',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
          ]),
        ),
        if (canReview) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () => setState(() => _showReviewForm = !_showReviewForm),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                    color: _showReviewForm
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12)
                        : context.fitlek.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _showReviewForm
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.4)
                            : context.fitlek.border)),
                child: Row(children: [
                  Icon(
                      _myReview != null
                          ? Icons.edit_rounded
                          : Icons.rate_review_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16),
                  const SizedBox(width: 10),
                  Text(_myReview != null ? 'Edit my review' : 'Leave a review',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Icon(
                      _showReviewForm
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: context.fitlek.textMuted,
                      size: 18),
                ]),
              ),
            ),
          ),
        ],
        if (canReview && _showReviewForm) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildReviewForm(),
          ),
        ],
        const SizedBox(height: 16),
        if (_loadingReviews)
          Center(
              child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 2)),
          ))
        else if (_reviews.isEmpty)
          _buildEmptyReviews()
        else
          ..._reviews.map(_buildReviewCard),
      ]),
    );
  }

  Widget _buildReviewForm() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: context.fitlek.card.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Your rating',
              style: TextStyle(
                  color: context.fitlek.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
              children: List.generate(5, (i) {
            final filled = i < _pendingRating;
            return GestureDetector(
              onTap: () => setState(() => _pendingRating = i + 1),
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: AnimatedScale(
                    scale: filled ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                        filled
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: filled
                            ? Theme.of(context).colorScheme.primary
                            : context.fitlek.textMuted,
                        size: 28)),
              ),
            );
          })),
          const SizedBox(height: 14),
          Text('Comment (optional)',
              style: TextStyle(
                  color: context.fitlek.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Share your experience with this coach…',
              hintStyle:
                  TextStyle(color: context.fitlek.textMuted, fontSize: 12),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: context.fitlek.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: context.fitlek.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5)),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _submittingReview ? null : _submitReview,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                    color: _pendingRating > 0
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: _submittingReview
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.onPrimary,
                              strokeWidth: 2))
                      : Text(_myReview != null ? 'UPDATE' : 'PUBLISH REVIEW',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 1.5)),
                ),
              ),
            ),
          ),
        ]),
      );

  Widget _buildReviewCard(_ReviewItem review) {
    final isMyReview = review.clientID == widget.clientID;
    final month = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ][review.createdAt.month - 1];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: context.fitlek.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isMyReview
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                  : context.fitlek.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: isMyReview
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.15)
                    : context.fitlek.card2,
                shape: BoxShape.circle),
            child: Center(
                child: Text(
                    review.clientName.isNotEmpty
                        ? review.clientName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        color: isMyReview
                            ? Theme.of(context).colorScheme.primary
                            : context.fitlek.textSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14))),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Text(review.clientName,
                      style: TextStyle(
                          color: isMyReview
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                  if (isMyReview) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text('My review',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ]),
                const SizedBox(height: 2),
                Text('$month ${review.createdAt.year}',
                    style: TextStyle(
                        color: context.fitlek.textMuted, fontSize: 10)),
              ])),
          Row(
              children: List.generate(
                  5,
                  (i) => Icon(
                      i < review.rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 12))),
        ]),
        if (review.comment?.isNotEmpty == true) ...[
          const SizedBox(height: 10),
          Text(review.comment!,
              style: TextStyle(
                  color: context.fitlek.textSecondary,
                  fontSize: 12.5,
                  height: 1.55)),
        ],
      ]),
    );
  }

  Widget _buildEmptyReviews() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
              color: context.fitlek.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.fitlek.border)),
          child: Column(children: [
            Icon(Icons.star_border_rounded,
                color: context.fitlek.textMuted, size: 36),
            const SizedBox(height: 10),
            Text('No reviews yet',
                style: TextStyle(
                    color: context.fitlek.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Be the first to share your experience',
                style:
                    TextStyle(color: context.fitlek.textMuted, fontSize: 11)),
          ]),
        ),
      );

  Widget _sectionHeader(String title) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 3,
            height: 16,
            color: Theme.of(context).colorScheme.primary,
            margin: const EdgeInsets.only(right: 10)),
        Text(title,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
      ]);

  Widget _backBtn({required VoidCallback onTap, bool transparent = false}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: transparent
                  ? Colors.black.withValues(alpha: 0.5)
                  : context.fitlek.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: transparent
                      ? Colors.white.withValues(alpha: 0.15)
                      : context.fitlek.border)),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: transparent
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              size: 16),
        ),
      );

  Widget _retryBtn({required VoidCallback onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3))),
          child: Text('Retry',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ),
      );
}
