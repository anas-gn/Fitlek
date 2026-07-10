import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:fitlek1/models/anas/reservation.dart';
import 'package:fitlek1/models/anas/coach.dart';
import 'clientBooking.dart';
import 'clientConversation.dart';

const _lime       = Color(0xFFC6F135);
const _dark       = Color(0xFF0A0A0A);
const _card       = Color(0xFF141414);
const _cardBorder = Color(0xFF232323);
const _baseUrl    = 'http://192.168.0.232:3000/api';

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
    id:           j['id'],
    coachID:      j['coachID'],
    clientID:     j['clientID'],
    rating:       j['rating'],
    comment:      j['comment'],
    clientName:   j['clientName'] ?? 'Anonyme',
    clientAvatar: j['clientAvatar'],
    createdAt:    DateTime.parse(j['createdAt']),
  );
}

class CoachDetailScreen extends StatefulWidget {
  final ReservationModel session;
  final int    clientID;
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
  CoachModel?       _coach;
  List<_ReviewItem> _reviews     = [];
  double            _avgRating   = 0;
  int               _totalReviews = 0;
  _ReviewItem?      _myReview;

  bool    _loadingCoach   = true;
  bool    _loadingReviews = true;
  String? _errorCoach;

  int     _pendingRating  = 0;
  bool    _submittingReview = false;
  final   _commentCtrl    = TextEditingController();
  bool    _showReviewForm = false;

  bool    _sendingInvite  = false;
  String  _inviteStatus   = 'none';
  int?    _conversationID;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
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
    setState(() { _loadingCoach = true; _errorCoach = null; });
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/coaches/${widget.session.coachID}'),
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
        setState(() { _errorCoach = 'Erreur ${res.statusCode}'; _loadingCoach = false; });
      }
    } catch (e) {
      setState(() { _errorCoach = 'Impossible de joindre le serveur.'; _loadingCoach = false; });
    }
  }

  Future<void> _fetchReviews() async {
    setState(() => _loadingReviews = true);
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/reviews/coach/${widget.session.coachID}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list  = (data['reviews'] as List)
            .map((e) => _ReviewItem.fromJson(e))
            .toList();
        final myReview = list.where((r) => r.clientID == widget.clientID).isNotEmpty
            ? list.firstWhere((r) => r.clientID == widget.clientID)
            : null;

        setState(() {
          _reviews      = list;
          _avgRating    = (data['avg'] as num).toDouble();
          _totalReviews = data['total'] as int;
          _myReview     = myReview;
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
      _showSnack("Sélectionne une note d'abord", isError: true);
      return;
    }
    setState(() => _submittingReview = true);
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'coachID':  widget.session.coachID,
          'clientID': widget.clientID,
          'rating':   _pendingRating,
          'comment':  _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 201) {
        _showSnack('Avis enregistré ✓');
        setState(() { _showReviewForm = false; });
        await _fetchReviews();
      } else {
        final body = jsonDecode(res.body);
        _showSnack(body['error'] ?? 'Erreur serveur', isError: true);
      }
    } catch (e) {
      _showSnack('Connexion impossible', isError: true);
    } finally {
      setState(() => _submittingReview = false);
    }
  }

  Future<void> _sendInvitation() async {
    setState(() => _sendingInvite = true);
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/invitations/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'senderID': widget.clientID,
          'coachID':  widget.session.coachID,
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 201) {
        _showSnack('Invitation envoyée au coach ✓');
        setState(() => _inviteStatus = 'pending');
      } else if (res.statusCode == 409) {
        _showSnack('Invitation déjà envoyée', isError: true);
        setState(() => _inviteStatus = 'pending');
      } else {
        final body = jsonDecode(res.body);
        _showSnack(body['error'] ?? 'Erreur serveur', isError: true);
      }
    } catch (e) {
      _showSnack('Connexion impossible', isError: true);
    } finally {
      setState(() => _sendingInvite = false);
    }
  }

  Future<void> _checkInvitationStatus() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/invitations/status/${widget.session.coachID}/${widget.clientID}'),
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
    } catch (e) {}
  }

  Future<void> _fetchConversation() async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/conversations/find-or-create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'clientID': widget.clientID,
          'coachID': widget.session.coachID,
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() => _conversationID = data['conversationID']);
      }
    } catch (e) {}
  }

  void _openConversation() {
    if (_conversationID == null) return;
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => ClientConversationScreen(
        conversationID: _conversationID!,
        clientID: widget.clientID,
        token: widget.token,
        coachName: _coach?.fullName ?? widget.session.coachName,
        coachAvatar: _coach?.avatarUrl ?? widget.session.coachImageUrl,
        coachSpeciality: _coach?.speciality ?? widget.session.coachSpeciality,
      ),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04), end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 380),
    ));
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
      backgroundColor: isError ? Colors.redAccent : _lime,
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

  Widget _buildLoading() => const Scaffold(
    backgroundColor: _dark,
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: 28, height: 28,
        child: CircularProgressIndicator(color: _lime, strokeWidth: 2)),
      SizedBox(height: 14),
      Text('Chargement du profil…',
        style: TextStyle(color: Colors.white38, fontSize: 13)),
    ])),
  );

  Widget _buildError() => Scaffold(
    backgroundColor: _dark,
    body: SafeArea(child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Align(alignment: Alignment.centerLeft,
          child: _backBtn(onTap: () => Navigator.pop(context))),
      ),
      Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, color: Colors.white12, size: 48),
        const SizedBox(height: 12),
        Text(_errorCoach!, style: const TextStyle(color: Colors.white38, fontSize: 13)),
        const SizedBox(height: 20),
        _retryBtn(onTap: _fetchAll),
      ]))),
    ])),
  );

  Widget _buildContent() {
    final s = widget.session;
    final c = _coach!;

    final imageUrl   = (c.avatarUrl?.isNotEmpty == true) ? c.avatarUrl! : s.coachImageUrl;
    final name       = c.fullName.isNotEmpty ? c.fullName : s.coachName;
    final speciality = (c.speciality?.isNotEmpty == true) ? c.speciality! : s.coachSpeciality;
    final rating     = _avgRating > 0 ? _avgRating : (c.rating ?? s.coachRating);

    final canReview = s.isConfirmed && s.sessionStart.isBefore(DateTime.now());

    return FadeTransition(
      opacity: _fadeAnim,
      child: Scaffold(
        backgroundColor: _dark,
        body: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _buildHero(context, imageUrl, name, speciality, rating)),
          SliverToBoxAdapter(child: _buildStats(rating, c.totalInvitations, _totalReviews)),
          if (c.ville != null || c.tel != null)
            SliverToBoxAdapter(child: _buildContactInfo(c)),
          if (c.instagramPage.isNotEmpty)
            SliverToBoxAdapter(child: _buildInstagram(c.instagramPage)),
          if (speciality.isNotEmpty)
            SliverToBoxAdapter(child: _buildTags(speciality)),
          if (c.bio.isNotEmpty)
            SliverToBoxAdapter(child: _buildBio(c.bio)),
          SliverToBoxAdapter(child: _buildInviteCTA()),
          SliverToBoxAdapter(child: _buildBookCTA(context, s)),
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
              ? Image.network(imageUrl, fit: BoxFit.cover,
                  loadingBuilder: (_, child, p) =>
                      p == null ? child : Container(color: _card),
                  errorBuilder: (_, __, ___) => _avatarPlaceholder(name))
              : _avatarPlaceholder(name),
        ),
        Positioned.fill(child: DecoratedBox(
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0x55000000), Color(0xFF0A0A0A)],
            stops: [0.0, 1.0],
          )),
        )),
        Positioned(top: 52, left: 16,
          child: SafeArea(child: _backBtn(onTap: () => Navigator.pop(ctx), transparent: true))),
        Positioned(top: 52, right: 16,
          child: SafeArea(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _lime,
              borderRadius: BorderRadius.circular(20)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.verified_rounded, color: Colors.black, size: 11),
              SizedBox(width: 4),
              Text('VÉRIFIÉ', style: TextStyle(
                color: Colors.black, fontSize: 9,
                fontWeight: FontWeight.w900, letterSpacing: 1.4)),
            ]),
          )),
        ),
        if (_avgRating > 0 || _totalReviews > 0)
          Positioned(bottom: 76, right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _lime.withOpacity(0.4))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star_rounded, color: _lime, size: 13),
                const SizedBox(width: 4),
                Text(
                  _avgRating > 0
                      ? '${_avgRating.toStringAsFixed(1)}  •  $_totalReviews avis'
                      : '$_totalReviews avis',
                  style: const TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        Positioned(bottom: 20, left: 20, right: 20,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(
              color: Colors.white, fontSize: 32,
              fontWeight: FontWeight.w900, letterSpacing: -1.0, height: 1.0)),
            const SizedBox(height: 5),
            Text(speciality, style: TextStyle(
              color: Colors.white.withOpacity(0.55), fontSize: 14,
              fontWeight: FontWeight.w500)),
          ]),
        ),
      ]),
    );
  }

  Widget _avatarPlaceholder(String name) => Container(
    color: _card,
    child: Center(child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: const TextStyle(color: _lime, fontSize: 72, fontWeight: FontWeight.w900),
    )),
  );

  Widget _buildStats(double rating, int totalInvitations, int totalReviews) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        _statBox(totalReviews > 0 ? rating.toStringAsFixed(1) : '—', 'Note', Icons.star_rounded),
        const SizedBox(width: 10),
        _statBox('$totalReviews', 'Avis', Icons.chat_bubble_outline_rounded),
        const SizedBox(width: 10),
        _statBox('$totalInvitations', 'Invitations', Icons.group_add_outlined),
      ]),
    );
  }

  Widget _statBox(String value, String label, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder, width: 1),
      ),
      child: Column(children: [
        Icon(icon, color: _lime, size: 16),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(
          color: Colors.white, fontSize: 15,
          fontWeight: FontWeight.w900, letterSpacing: -0.5),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ]),
    ),
  );

  Widget _buildContactInfo(CoachModel c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 3, height: 16, color: _lime,
                margin: const EdgeInsets.only(right: 10)),
              const Text('Infos pratiques', style: TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 14),
            if (c.ville != null && c.ville!.isNotEmpty)
              _infoRow(
                icon: Icons.location_on_rounded,
                label: 'Ville',
                value: c.ville!,
                valueColor: _lime,
                onTap: null,
              ),
            if (c.ville != null && c.ville!.isNotEmpty && c.tel != null)
              const SizedBox(height: 12),
            if (c.tel != null)
              _infoRow(
                icon: Icons.phone_rounded,
                label: 'Téléphone',
                value: c.tel!,
                valueColor: Colors.white,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: c.tel!));
                  _showSnack('Numéro copié ✓');
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
            color: _lime.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _lime, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
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
              color: _lime.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _lime.withOpacity(0.2)),
            ),
            child: const Text('COPIER', style: TextStyle(
              color: _lime, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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
    final tags = speciality.split(RegExp(r'[,/]')).map((t) => t.trim())
        .where((t) => t.isNotEmpty).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Wrap(spacing: 8, runSpacing: 8, children: tags.map((tag) =>
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _lime.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _lime.withOpacity(0.25))),
          child: Text(tag, style: const TextStyle(
            color: _lime, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
        )
      ).toList()),
    );
  }

  Widget _buildInstagram(String handle) {
    final display = handle.startsWith('http') ? handle.split('/').last : handle;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _card, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _cardBorder)),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE1306C).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.camera_alt_rounded,
              color: Color(0xFFE1306C), size: 17),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Instagram',
              style: TextStyle(color: Colors.white38, fontSize: 10)),
            const SizedBox(height: 2),
            Text('@$display', style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const Spacer(),
          const Icon(Icons.open_in_new_rounded, color: Colors.white24, size: 16),
        ]),
      ),
    );
  }

  Widget _buildBio(String bio) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('À propos'),
      const SizedBox(height: 12),
      Text(bio, style: const TextStyle(
        color: Colors.white60, fontSize: 13.5, height: 1.7, letterSpacing: 0.1)),
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
        btnText = 'ENVOYER UN MESSAGE';
        btnIcon = Icons.chat_bubble_rounded;
        btnColor = _lime;
        textColor = Colors.black;
        isDisabled = false;
        onTap = _openConversation;
        break;
      case 'pending':
        btnText = 'INVITATION ENVOYÉE';
        btnIcon = Icons.schedule_rounded;
        btnColor = _lime.withOpacity(0.15);
        textColor = _lime;
        isDisabled = true;
        onTap = null;
        break;
      case 'refused':
        btnText = 'INVITATION REFUSÉE';
        btnIcon = Icons.cancel_rounded;
        btnColor = Colors.red.withOpacity(0.15);
        textColor = Colors.redAccent;
        isDisabled = true;
        onTap = null;
        break;
      default:
        btnText = 'INVITER CE COACH';
        btnIcon = Icons.person_add_rounded;
        btnColor = const Color(0xFFC6F135);
        textColor = Colors.black;
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
                  ? const Color(0xFFC6F135).withOpacity(0.5)
                  : isDisabled
                      ? (_inviteStatus == 'refused' ? Colors.red.withOpacity(0.4) : _lime.withOpacity(0.4))
                      : const Color(0xFFC6F135).withOpacity(0.5),
              width: 1,
            ),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFFC6F135).withOpacity(0.20),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _sendingInvite
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.black,
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
      onTap: () => Navigator.push(ctx, PageRouteBuilder(
        pageBuilder: (_, __, ___) => BookingScreen(
          session:  s,
          clientID: widget.clientID,
          token:    widget.token,
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04), end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 380),
      )),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _cardBorder),
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.calendar_month_rounded, color: Colors.white70, size: 16),
          SizedBox(width: 8),
          Text('RÉSERVER UNE SÉANCE',
              style: TextStyle(
                  color: Colors.white70,
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
            _sectionHeader('Avis clients'),
            const Spacer(),
            if (_totalReviews > 0) Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _lime.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _lime.withOpacity(0.25))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star_rounded, color: _lime, size: 11),
                const SizedBox(width: 4),
                Text('${_avgRating.toStringAsFixed(1)} / 5',
                  style: const TextStyle(
                    color: _lime, fontSize: 11, fontWeight: FontWeight.w700)),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _showReviewForm ? _lime.withOpacity(0.12) : _card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _showReviewForm ? _lime.withOpacity(0.4) : _cardBorder)),
                child: Row(children: [
                  Icon(
                    _myReview != null
                        ? Icons.edit_rounded
                        : Icons.rate_review_rounded,
                    color: _lime, size: 16),
                  const SizedBox(width: 10),
                  Text(
                    _myReview != null ? 'Modifier mon avis' : 'Laisser un avis',
                    style: const TextStyle(
                      color: _lime, fontSize: 13, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Icon(
                    _showReviewForm ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white38, size: 18),
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
          const Center(child: Padding(
            padding: EdgeInsets.all(24),
            child: SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(color: _lime, strokeWidth: 2)),
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
      color: _card.withOpacity(0.8),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _lime.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Ta note', style: TextStyle(
        color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Row(children: List.generate(5, (i) {
        final filled = i < _pendingRating;
        return GestureDetector(
          onTap: () => setState(() => _pendingRating = i + 1),
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: AnimatedScale(
              scale: filled ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                filled ? Icons.star_rounded : Icons.star_outline_rounded,
                color: filled ? _lime : Colors.white24,
                size: 28)),
          ),
        );
      })),
      const SizedBox(height: 14),
      const Text('Commentaire (optionnel)', style: TextStyle(
        color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextField(
        controller: _commentCtrl,
        maxLines: 3,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Partage ton expérience avec ce coach…',
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
          filled: true,
          fillColor: _dark,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _cardBorder)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _cardBorder)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _lime, width: 1.5)),
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
              color: _pendingRating > 0 ? _lime : _lime.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10)),
            child: Center(
              child: _submittingReview
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : Text(
                      _myReview != null ? "METTRE À JOUR" : "PUBLIER L'AVIS",
                      style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w900,
                        fontSize: 12, letterSpacing: 1.5)),
            ),
          ),
        ),
      ),
    ]),
  );

  Widget _buildReviewCard(_ReviewItem review) {
    final isMyReview = review.clientID == widget.clientID;
    final month = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ][review.createdAt.month - 1];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMyReview ? _lime.withOpacity(0.3) : _cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: isMyReview ? _lime.withOpacity(0.15) : Colors.white.withOpacity(0.06),
              shape: BoxShape.circle),
            child: Center(child: Text(
              review.clientName.isNotEmpty ? review.clientName[0].toUpperCase() : '?',
              style: TextStyle(
                color: isMyReview ? _lime : Colors.white54,
                fontWeight: FontWeight.w800, fontSize: 14))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(review.clientName, style: TextStyle(
                color: isMyReview ? _lime : Colors.white,
                fontWeight: FontWeight.w700, fontSize: 12)),
              if (isMyReview) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _lime.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6)),
                  child: const Text('Mon avis', style: TextStyle(
                    color: _lime, fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
            const SizedBox(height: 2),
            Text('$month ${review.createdAt.year}',
              style: const TextStyle(color: Colors.white24, fontSize: 10)),
          ])),
          Row(children: List.generate(5, (i) => Icon(
            i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: _lime, size: 12))),
        ]),
        if (review.comment?.isNotEmpty == true) ...[
          const SizedBox(height: 10),
          Text(review.comment!, style: const TextStyle(
            color: Colors.white54, fontSize: 12.5, height: 1.55)),
        ],
      ]),
    );
  }

  Widget _buildEmptyReviews() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder)),
      child: Column(children: [
        const Icon(Icons.star_border_rounded, color: Colors.white12, size: 36),
        const SizedBox(height: 10),
        const Text("Aucun avis pour l'instant",
          style: TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text("Sois le premier à partager ton expérience",
          style: TextStyle(color: Colors.white24, fontSize: 11)),
      ]),
    ),
  );

  Widget _sectionHeader(String title) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 3, height: 16, color: _lime,
      margin: const EdgeInsets.only(right: 10)),
    Text(title, style: const TextStyle(
      color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
  ]);

  Widget _backBtn({required VoidCallback onTap, bool transparent = false}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: transparent ? Colors.black.withOpacity(0.5) : _card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: transparent ? Colors.white.withOpacity(0.15) : _cardBorder)),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
      ),
    );

  Widget _retryBtn({required VoidCallback onTap}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: _lime.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _lime.withOpacity(0.3))),
        child: const Text('Réessayer', style: TextStyle(
          color: _lime, fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    );
}
