import '../../services/live_updates.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fitlek1/constants/urls.dart';
import 'package:fitlek1/models/anas/reservation.dart';
import 'package:fitlek1/models/anas/coach.dart';
import 'package:fitlek1/models/anas/coachPackage.dart';
import 'package:fitlek1/models/anas/review.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'clientBooking.dart';
import 'clientCoachReviews.dart';
import 'clientConversation.dart';
import '../../theme/fitlek_theme_extension.dart';
import '../../components/ENG/imagePreview.dart';
import 'package:url_launcher/url_launcher.dart';

class CoachDetailScreen extends StatefulWidget {
  final ReservationModel session;
  final int clientID;
  final String token;
  final bool preview;

  const CoachDetailScreen({
    super.key,
    required this.session,
    required this.clientID,
    required this.token,
    this.preview = false,
  });

  @override
  State<CoachDetailScreen> createState() => _CoachDetailScreenState();
}

class _CoachDetailScreenState extends State<CoachDetailScreen> with SingleTickerProviderStateMixin, LiveUpdates<CoachDetailScreen> {
  @override
  Set<String> get liveDomains => {'coaches','profile','edit','packages','reviews','locations','availability','calendar','reservations','favorites','bans'};
  @override
  Future<void> refreshLiveData() async { await Future.wait([_fetchAll(silent:true),_fetchPackages(),_fetchAvailability()]); }

  CoachModel? _coach;
  List<ReviewItem> _reviews = [];
  double _avgRating = 0;
  int _totalReviews = 0;
  ReviewItem? _myReview;

  bool _loadingCoach = true;
  bool _loadingReviews = true;
  bool _loadingGallery = true;
  String? _errorCoach;

  List<Map<String, dynamic>> _galleryImages = [];
  final PageController _galleryController = PageController();
  int _galleryIndex = 0;

  int _pendingRating = 0;
  bool _submittingReview = false;
  final _commentCtrl = TextEditingController();
  bool _showReviewForm = false;

  bool _isFavorite = false;
  bool _togglingFavorite = false;

  bool _sendingInvite = false;
  String _inviteStatus = 'none';
  int? _conversationID;

  List<CoachPackage> _packages = [];
  bool _loadingPackages = true;

  Map<String, List<String>> _blockedSlots = {};
  Map<String, List<String>> _reservedSlots = {};
  int _selectedDayIndex = 0;
  bool _loadingAvailability = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _fetchAll();
    if (!widget.preview) {
      _checkInvitationStatus();
      _fetchFavoriteStatus();
    }
    _fetchPackages();
    _fetchAvailability();
  }

  @override
  void dispose() {
    _galleryController.dispose();
    _animCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchFavoriteStatus() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/favorites?clientID=${widget.clientID}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        final ids = data.map((e) => e as int).toSet();
        if (mounted) {
          setState(() => _isFavorite = ids.contains(widget.session.coachID));
        }
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    if (widget.preview) return;
    if (_togglingFavorite) return;
    final previous = _isFavorite;
    setState(() {
      _togglingFavorite = true;
      _isFavorite = !previous;
    });
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/favorites/toggle'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${widget.token}',
            },
            body: jsonEncode({
              'clientID': widget.clientID,
              'coachID': widget.session.coachID,
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 || res.statusCode == 201) {
        _showSnack(
            previous ? 'Removed from favorites' : 'Added to favorites ✓');
      } else {
        if (mounted) setState(() => _isFavorite = previous);
        _showSnack('Failed to update favorites', isError: true);
      }
    } catch (_) {
      if (mounted) setState(() => _isFavorite = previous);
      _showSnack('Connection failed', isError: true);
    } finally {
      if (mounted) setState(() => _togglingFavorite = false);
    }
  }

  Future<void> _fetchAll({bool silent = false}) async {
    await Future.wait([_fetchCoach(silent:silent), _fetchReviews(silent:silent), _fetchGallery(silent:silent)]);
    if (mounted && !silent) _animCtrl.forward();
  }

  Future<void> _fetchPackages() async {
    try {
      final coachID = widget.session.coachID;
      final res = await http.get(
        Uri.parse('$baseUrl/packages/coach/$coachID'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 && mounted) {
        final List data = jsonDecode(res.body);
        setState(() {
          _packages = data.map((e) => CoachPackage.fromJson(e)).toList();
          _loadingPackages = false;
        });
      } else {
        if (mounted) setState(() => _loadingPackages = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPackages = false);
    }
  }

  Future<void> _fetchAvailability() async {
    try {
      final coachID = widget.session.coachID;
      final today = DateTime.now();
      final endDay = today.add(const Duration(days: 4));
      final fromStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final toStr =
          '${endDay.year}-${endDay.month.toString().padLeft(2, '0')}-${endDay.day.toString().padLeft(2, '0')}';

      final blockRes = await http.get(
        Uri.parse('$baseUrl/availability/$coachID'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      ).timeout(const Duration(seconds: 8));

      final resRes = await http.get(
        Uri.parse(
            '$baseUrl/reservations?role=coach&userID=$coachID&from=$fromStr&to=$toStr'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      ).timeout(const Duration(seconds: 8));

      if (!mounted) return;

      final Map<String, List<String>> blocked = {};
      final Map<String, List<String>> reserved = {};
      final allSlots = [
        '08:00',
        '09:00',
        '10:00',
        '11:00',
        '12:00',
        '13:00',
        '14:00',
        '15:00',
        '16:00',
        '17:00',
        '18:00',
        '19:00',
        '20:00',
        '21:00',
        '22:00'
      ];

      if (blockRes.statusCode == 200) {
        final List blocks = jsonDecode(blockRes.body);
        for (final b in blocks) {
          final dateKey = (b['blockedDate'] as String).substring(0, 10);
          final start = (b['startTime'] as String).substring(0, 5);
          final end = (b['endTime'] as String).substring(0, 5);
          for (final slot in allSlots) {
            if (slot.compareTo(start) >= 0 && slot.compareTo(end) < 0) {
              blocked.putIfAbsent(dateKey, () => []).add(slot);
            }
          }
        }
      }

      if (resRes.statusCode == 200) {
        final List reservations = jsonDecode(resRes.body);
        for (final r in reservations) {
          final status = r['status'] as String;
          if (status == 'cancelled') continue;
          final dateKey = (r['reservedDate'] as String).substring(0, 10);
          final time = (r['reservedTime'] as String).substring(0, 5);
          reserved.putIfAbsent(dateKey, () => []).add(time);
        }
      }

      setState(() {
        _blockedSlots = blocked;
        _reservedSlots = reserved;
        _loadingAvailability = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingAvailability = false);
    }
  }

  Future<void> _fetchGallery({bool silent = false}) async {
    if (!silent) setState(() => _loadingGallery = true);
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/coaches/${widget.session.coachID}/images'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _galleryImages = List<Map<String, dynamic>>.from(data);
            _loadingGallery = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingGallery = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingGallery = false);
    }
  }

  Future<void> _fetchCoach({bool silent = false}) async {
    if (!silent) setState(() {
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
      if (!mounted) return;
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

  Future<void> _fetchReviews({bool silent = false}) async {
    if (!silent) setState(() => _loadingReviews = true);
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/reviews/coach/${widget.session.coachID}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      ).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (data['reviews'] as List)
            .map((e) => ReviewItem.fromJson(e))
            .toList();
        final myReview =
            list.where((r) => r.clientID == widget.clientID).isNotEmpty
                ? list.firstWhere((r) => r.clientID == widget.clientID)
                : null;
        setState(() {
          _reviews = list;
          _avgRating = double.tryParse('${data['avg']}') ?? 0;
          _totalReviews = int.tryParse('${data['total']}') ?? 0;
          _myReview = myReview;
          if (myReview != null && !silent) {
            _pendingRating = myReview.rating;
            _commentCtrl.text = myReview.comment ?? '';
          }
          _loadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  Future<void> _submitReview() async {
    if (widget.preview) return;
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
        setState(() => _showReviewForm = false);
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
    if (widget.preview) return;
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
    } catch (_) {}
  }

  Future<void> _fetchConversation() async {
    if (widget.preview) return;
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
    } catch (_) {}
  }

  Future<void> _openConversation() async {
    if (widget.preview) return;
    if (widget.clientID == null) {
      _showSnack('Please login to message the coach', isError: true);
      return;
    }
    if (_conversationID == null) {
      await _fetchConversation();
    }
    if (_conversationID == null) {
      _showSnack('Unable to start conversation. Please try again.',
          isError: true);
      return;
    }
    if (!mounted) return;
    Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => ClientConversationScreen(
            conversationID: _conversationID!,
            clientID: widget.clientID!,
            token: widget.token,
            coachName: _coach?.fullName ?? widget.session.coachName,
            coachAvatar: _coach?.avatarUrl ?? widget.session.coachImageUrl,
            coachSpeciality:
                _coach?.displaySpecialties ?? widget.session.coachSpeciality,
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

  void _showReportDialog(String name, int coachID) {
    String? selectedReason;
    final reasons = [
      'Spam',
      'Harassment',
      'Inappropriate content',
      'Fraud / Scam',
      'Other'
    ];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: context.fitlek.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Report $name',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Why are you reporting this user? We take these reports seriously.',
                  style:
                      TextStyle(color: context.fitlek.textMuted, fontSize: 13)),
              const SizedBox(height: 16),
              ...reasons.map((r) => RadioListTile<String>(
                    title: Text(r,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 13)),
                    value: r,
                    groupValue: selectedReason,
                    activeColor: Theme.of(context).colorScheme.primary,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onChanged: (val) =>
                        setDialogState(() => selectedReason = val),
                  )),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: TextStyle(color: context.fitlek.textMuted))),
            TextButton(
              onPressed: selectedReason == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      _submitReport(coachID, selectedReason!);
                    },
              child: Text('Submit',
                  style: TextStyle(
                      color: selectedReason == null
                          ? context.fitlek.textMuted
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport(int reportedID, String reason) async {
    if (widget.preview) return;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/ugc/report'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'reportedID': reportedID,
          'reason': reason,
          'type': 'user',
        }),
      );
      if (res.statusCode == 200) {
        _showSnack('Report submitted successfully.');
      } else {
        _showSnack('Failed to submit report', isError: true);
      }
    } catch (_) {
      _showSnack('Network error', isError: true);
    }
  }

  void _showBlockDialog(String name, int coachID) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.fitlek.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Block $name?',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w800)),
        content: Text(
          'They won\'t be able to find your profile or send you messages. They will not be notified that you blocked them.',
          style: TextStyle(color: context.fitlek.textMuted),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(color: context.fitlek.textMuted))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              _submitBlock(coachID);
            },
            child: Text('Block',
                style: TextStyle(
                    color: context.fitlek.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitBlock(int blockedID) async {
    if (widget.preview) return;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/ugc/block'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'blockedID': blockedID}),
      );
      if (res.statusCode == 200) {
        _showSnack('User blocked.');
        if (mounted) Navigator.pop(context);
      } else {
        _showSnack('Failed to block user', isError: true);
      }
    } catch (_) {
      _showSnack('Network error', isError: true);
    }
  }

  void _showQrDialog(String code) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: context.fitlek.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: QrImageView(
                    data: code, version: QrVersions.auto, size: 220),
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
                child: Image.asset('assets/branding/icon_app.png',
                    fit: BoxFit.contain),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 2),
              ),
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
        (c.displaySpecialties.isNotEmpty && c.displaySpecialties != 'Coach')
            ? c.displaySpecialties
            : (s.coachSpeciality.isNotEmpty ? s.coachSpeciality : '');
    final rating = _avgRating > 0 ? _avgRating : (c.rating ?? s.coachRating);
    final canReview = !widget.preview &&
        s.isConfirmed &&
        s.sessionStart.isBefore(DateTime.now());

    return FadeTransition(
      opacity: _fadeAnim,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: CustomScrollView(slivers: [
          SliverToBoxAdapter(
              child: _buildHero(context, imageUrl, name, speciality, c)),
          SliverToBoxAdapter(
              child: _buildStats(rating, c.totalInvitations, _totalReviews)),
          SliverToBoxAdapter(child: _buildPriceBar()),
          if (c.bio.isNotEmpty) SliverToBoxAdapter(child: _buildBio(c.bio)),
          if ((c.specialties != null && c.specialties!.isNotEmpty) ||
              speciality.isNotEmpty)
            SliverToBoxAdapter(child: _buildTags(c, speciality)),
          if (c.certifications != null && c.certifications!.isNotEmpty)
            SliverToBoxAdapter(child: _buildCertifications(c)),
          if (_packages.isNotEmpty)
            SliverToBoxAdapter(child: _buildPackagesSection()),
          if (!_loadingGallery && _galleryImages.isNotEmpty)
            SliverToBoxAdapter(child: _buildGallery(speciality)),
          SliverToBoxAdapter(
              child: IgnorePointer(
                  ignoring: widget.preview, child: _buildAvailability())),
          if (c.hasGym) SliverToBoxAdapter(child: _buildGym(c)),
          SliverToBoxAdapter(child: _buildPracticalInfo(c)),
          SliverToBoxAdapter(child: _buildReviewsSection(rating, canReview)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ]),
        bottomNavigationBar: SafeArea(
          child: IgnorePointer(
              ignoring: widget.preview,
              child: _buildPrimaryActions(context, s, c)),
        ),
      ),
    );
  }

  Widget _sectionHeaderWithIcon(String title, IconData icon,
      {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildCertifications(CoachModel c) {
    final certs = c.certifications;
    if (certs == null || certs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeaderWithIcon(
              'Certifications', Icons.workspace_premium_outlined),
          const SizedBox(height: 16),
          ...certs
              .map((cert) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C2420),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                              c.isApproved
                                  ? Icons.verified_user_outlined
                                  : Icons.workspace_premium_outlined,
                              color: Colors.white,
                              size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cert,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(
                                    c.isApproved
                                        ? 'Verified by Sirvya'
                                        : 'Self-reported',
                                    style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.7),
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  void _navigateToBooking([CoachPackage? pkg]) {
    if (widget.preview) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => BookingScreen(
          session: widget.session,
          clientID: widget.clientID,
          token: widget.token,
          packages: _packages,
          initialPackage: pkg,
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );
  }

  void _openAllPackagesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFF0F2C24),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            color: Colors.white, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Coaching packages',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
              Expanded(
                child: _packages.isEmpty
                    ? Center(
                        child: Text(
                          'No packages available for this coach.',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6)),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _packages.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (c, idx) {
                          final pkg = _packages[idx];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0C2420),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        pkg.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (pkg.price != null)
                                      Text(
                                        '${pkg.price!.toInt()} MAD',
                                        style: const TextStyle(
                                          color: Color(0xFF38BDF8),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                                if (pkg.description != null &&
                                    pkg.description!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    pkg.description!,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.7),
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded,
                                        color: Color(0xFF94A8A3), size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${pkg.sessions ?? 1} session${pkg.sessions != null && pkg.sessions! > 1 ? 's' : ''} · 60 min${pkg.sessions != null && pkg.sessions! > 1 ? ' each' : ''}',
                                      style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.6),
                                          fontSize: 12),
                                    ),
                                    const Spacer(),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _navigateToBooking(pkg);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF38BDF8),
                                        foregroundColor: Colors.black,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                      child: const Text(
                                        'Choose & Book',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPackagesSection() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeaderWithIcon(
          'Coaching packages',
          Icons.inventory_2_outlined,
          trailing: GestureDetector(
            onTap: _openAllPackagesSheet,
            child: const Text('See all >',
                style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 16),
        if (_loadingPackages)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Color(0xFF38BDF8), strokeWidth: 2)),
            ),
          )
        else if (_packages.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0C2420),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Text('No packages available for this coach.',
                style: TextStyle(color: f.textMuted, fontSize: 13)),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _packages
                  .map((pkg) => _buildClientPackageCard(pkg, cs, f))
                  .toList(),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: Color(0xFF94A8A3), size: 14),
            const SizedBox(width: 6),
            Text('Agree on the price before confirmation.',
                style: TextStyle(color: f.textMuted, fontSize: 12)),
          ],
        ),
      ]),
    );
  }

  Widget _buildClientPackageCard(
      CoachPackage pkg, ColorScheme cs, FitlekColors f) {
    return GestureDetector(
      onTap: () => _navigateToBooking(pkg),
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0C2420),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pkg.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800)),
            if (pkg.description != null && pkg.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(pkg.description!,
                  style: TextStyle(
                      color: f.textSecondary, fontSize: 12.5, height: 1.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            Container(
                width: double.infinity,
                height: 1,
                color: Colors.white.withValues(alpha: 0.05)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    color: Color(0xFF94A8A3), size: 14),
                const SizedBox(width: 6),
                Text(
                    '${pkg.sessions ?? 1} session${pkg.sessions != null && pkg.sessions! > 1 ? 's' : ''} · 60 min${pkg.sessions != null && pkg.sessions! > 1 ? ' each' : ''}',
                    style: TextStyle(color: f.textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.layers_outlined,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                            pkg.price != null
                                ? '${pkg.price!.toInt()} MAD'
                                : 'On request',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                  ),
                  child: const Text('Book >',
                      style: TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pkgTag(String label, IconData icon, ColorScheme cs, FitlekColors f,
          {bool colored = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colored ? cs.primary.withValues(alpha: 0.1) : f.card2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: colored ? cs.primary.withValues(alpha: 0.3) : f.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 10, color: colored ? cs.primary : f.textMuted),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: colored ? cs.primary : f.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _buildHero(BuildContext ctx, String imageUrl, String name,
      String speciality, CoachModel c) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (imageUrl.isNotEmpty) {
          Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) =>
                  ImagePreview(imageUrl: imageUrl, tag: 'coach_detail_hero'),
            ),
          );
        }
      },
      onPanEnd: (details) {
        final v = details.velocity.pixelsPerSecond;
        if (v.dy > 250 || v.dx > 250) Navigator.pop(ctx);
      },
      child: SizedBox(
        height: 420,
        child: Stack(fit: StackFit.expand, children: [
          imageUrl.isNotEmpty
              ? Hero(
                  tag: 'coach_detail_hero',
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, p) => p == null
                        ? child
                        : Container(color: context.fitlek.card),
                    errorBuilder: (_, __, ___) => _avatarPlaceholder(name),
                  ),
                )
              : _avatarPlaceholder(name),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    Colors.transparent,
                    Theme.of(context)
                        .scaffoldBackgroundColor
                        .withValues(alpha: 0.55),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 0.35, 0.75, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _backBtn(onTap: () => Navigator.pop(ctx), transparent: true),
                  const Spacer(),
                  Row(children: [
                    GestureDetector(
                      onTap: _toggleFavorite,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: _isFavorite ? Colors.redAccent : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildMoreMenu(c),
                  ]),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.2,
                            height: 1.0)),
                  ),
                  if (c.isApproved) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.verified_rounded,
                        color: Color(0xFF38BDF8), size: 22),
                  ]
                ],
              ),
              if (speciality.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(children: [
                  Flexible(
                    child: Text(speciality,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
              ],
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.location_on_rounded,
                    color: Colors.white.withValues(alpha: 0.6), size: 14),
                const SizedBox(width: 4),
                Flexible(child: Text(c.locationLabel,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500))),
                if (c.isAvailableToday) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C381E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Available today',
                          style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildMoreMenu(CoachModel c) {
    final name = c.fullName.isNotEmpty ? c.fullName : widget.session.coachName;
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child:
            const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 18),
      ),
      color: context.fitlek.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      offset: const Offset(0, 44),
      onSelected: (val) {
        if (val == 'report') {
          _showReportDialog(name, c.id);
        } else if (val == 'block') {
          _showBlockDialog(name, c.id);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'report',
          child: Row(children: [
            Icon(Icons.flag_rounded, color: context.fitlek.textMuted, size: 18),
            const SizedBox(width: 10),
            Text('Report Coach',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
        PopupMenuItem(
          value: 'block',
          child: Row(children: [
            Icon(Icons.block_rounded, color: context.fitlek.error, size: 18),
            const SizedBox(width: 10),
            Text('Block Coach',
                style: TextStyle(
                    color: context.fitlek.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ],
    );
  }

  Widget _buildStats(double rating, int totalInvitations, int totalReviews) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F2C24),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              _statSegment(
                rating > 0 ? rating.toStringAsFixed(1) : '—',
                'Rating',
                Icons.star_rounded,
              ),
              VerticalDivider(
                  color: Colors.white.withValues(alpha: 0.1),
                  thickness: 1,
                  width: 1),
              _statSegment(
                '$totalReviews',
                'Reviews',
                Icons.chat_bubble_outline_rounded,
              ),
              VerticalDivider(
                  color: Colors.white.withValues(alpha: 0.1),
                  thickness: 1,
                  width: 1),
              _statSegment(
                '$totalInvitations',
                'Clients',
                Icons.people_outline_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statSegment(String value, String label, IconData icon) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBar() {
    double? minPrice;
    if (_packages.isNotEmpty) {
      final validPrices =
          _packages.map((p) => p.price).whereType<double>().toList();
      if (validPrices.isNotEmpty) {
        minPrice = validPrices.reduce((a, b) => a < b ? a : b);
      }
    }

    final title = minPrice != null
        ? 'From ${minPrice.toStringAsFixed(0)} MAD'
        : 'Price on request';
    final subtitle = minPrice != null
        ? 'Session rates starting from ${minPrice.toStringAsFixed(0)} MAD'
        : 'Contact the coach for session rates';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4E2), // Pale beige color
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.layers_outlined, color: Colors.black, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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

  Widget _buildPrimaryActions(
      BuildContext ctx, ReservationModel s, CoachModel c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
            top: BorderSide(
                color: Colors.white.withValues(alpha: 0.1), width: 1)),
      ),
      child: Row(children: [
        Expanded(flex: 3, child: _buildBookBtn(ctx, s)),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: _buildMessageBtn()),
      ]),
    );
  }

  Widget _buildMessageBtn() {
    return GestureDetector(
      onTap: _openConversation,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F2C24),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF38BDF8)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.chat_bubble_outline_rounded,
              color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Message',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ]),
      ),
    );
  }

  Widget _buildBookBtn(BuildContext ctx, ReservationModel s) => GestureDetector(
        onTap: () => Navigator.push(
            ctx,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => BookingScreen(
                session: s,
                clientID: widget.clientID,
                token: widget.token,
                packages: _packages,
              ),
              transitionsBuilder: (_, anim, __, child) => FadeTransition(
                opacity: anim,
                child: child,
              ),
            )),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4E2), // Pale beige color
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.calendar_month_outlined,
                color: Colors.black, size: 20),
            const SizedBox(width: 8),
            const Text('Request booking',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 14)),
          ]),
        ),
      );

  Widget _buildTags(CoachModel c, String fallbackSpeciality) {
    List<String> tags = [];
    if (c.specialties != null && c.specialties!.isNotEmpty) {
      tags = c.specialties!;
    } else if (fallbackSpeciality.isNotEmpty) {
      tags = fallbackSpeciality
          .split(RegExp(r'[,/]'))
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
    }
    if (tags.isEmpty) return const SizedBox.shrink();

    IconData getIconForTag(String tag) {
      final t = tag.toLowerCase();
      if (t.contains('strength')) return Icons.fitness_center_rounded;
      if (t.contains('power')) return Icons.bar_chart_rounded;
      if (t.contains('recover')) return Icons.eco_rounded;
      if (t.contains('cardio')) return Icons.directions_run_rounded;
      return Icons.bolt_rounded;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeaderWithIcon('Specialties', Icons.fitness_center_rounded),
          const SizedBox(height: 16),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) {
                final isInsta = tag.startsWith('@') ||
                    tag.toLowerCase().contains('instagram');
                return GestureDetector(
                  onTap: isInsta
                      ? () async {
                          String username = tag.trim();
                          while (username.startsWith('@')) {
                            username = username.substring(1).trim();
                          }
                          if (username.contains('instagram.com/')) {
                            username = username
                                .split('instagram.com/')
                                .last
                                .split('?')
                                .first
                                .replaceAll('/', '');
                          }
                          final url =
                              Uri.parse('https://instagram.com/$username');
                          try {
                            await launchUrl(url,
                                mode: LaunchMode.externalApplication);
                          } catch (_) {
                            await launchUrl(url);
                          }
                        }
                      : null,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                        color: const Color(0xFF0C2420),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF1E5C53))),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        isInsta
                            ? const InstagramIcon(size: 14)
                            : Icon(getIconForTag(tag),
                                color: const Color(0xFF38BDF8), size: 14),
                        const SizedBox(width: 6),
                        Text(tag,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              }).toList()),
        ],
      ),
    );
  }

  Widget _buildBio(String bio) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 8),
              const Text('About',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          Text(bio,
              style: TextStyle(
                  color: context.fitlek.textSecondary,
                  fontSize: 14,
                  height: 1.72,
                  letterSpacing: 0.1)),
        ]),
      );

  void _openGallery(int initialIndex, String speciality) {
    int currentIndex = initialIndex;
    final controller = PageController(initialPage: initialIndex);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              centerTitle: true,
              title: Text(
                '${currentIndex + 1}/${_galleryImages.length}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
            extendBodyBehindAppBar: true,
            body: PageView.builder(
              itemCount: _galleryImages.length,
              controller: controller,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Center(
                    child: Hero(
                      tag: 'gallery_${_galleryImages[index]['id']}',
                      child: Image.network(
                        _galleryImages[index]['urlImage'],
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image,
                            color: Colors.white,
                            size: 50),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  Widget _galleryPhoto(int index) => Image.network(
        _galleryImages[index]['urlImage'],
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => ColoredBox(
            color: context.fitlek.card2,
            child: Center(
                child: Icon(Icons.broken_image_outlined,
                    color: context.fitlek.textMuted))),
      );

  Widget _buildGallery(String speciality) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.photo_library_outlined,
              color: Theme.of(context).colorScheme.onSurface, size: 20),
          const SizedBox(width: 8),
          Expanded(
              child: Text('Coaching gallery',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w800))),
          TextButton(
              onPressed: () => _openGallery(_galleryIndex, speciality),
              child: Text('View all (${_galleryImages.length})',
                  style: TextStyle(color: primary, fontSize: 12))),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1.65,
              child: PageView.builder(
                controller: _galleryController,
                itemCount: _galleryImages.length,
                onPageChanged: (index) => setState(() => _galleryIndex = index),
                itemBuilder: (_, index) => GestureDetector(
                  onTap: () => _openGallery(index, speciality),
                  child: Stack(fit: StackFit.expand, children: [
                    Hero(
                        tag: 'gallery_${_galleryImages[index]['id']}',
                        child: _galleryPhoto(index)),
                    Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(14, 24, 14, 12),
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.8)
                              ])),
                          child: Row(children: [
                            Expanded(
                                child: Text(
                                    speciality.isNotEmpty
                                        ? speciality
                                        : 'Coaching',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600))),
                            const SizedBox(width: 12),
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white24)),
                                child: Text(
                                    '${index + 1} / ${_galleryImages.length}',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12))),
                          ]),
                        )),
                  ]),
                ),
              ),
            )),
        if (_galleryImages.length > 1) ...[
          const SizedBox(height: 8),
          SizedBox(
              height: 66,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _galleryImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) => GestureDetector(
                  onTap: () => _galleryController.animateToPage(index,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut),
                  child: Container(
                      width: 100,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _galleryIndex == index
                                  ? primary
                                  : context.fitlek.border,
                              width: 2)),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: _galleryPhoto(index))),
                ),
              )),
        ],
      ]),
    );
  }

  Widget _buildAvailability() {
    final today = DateTime.now();
    final days = List.generate(3, (i) => today.add(Duration(days: i)));

    String getDayName(DateTime d) =>
        ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];
    String getMonthName(DateTime d) => [
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
        ][d.month - 1];

    final selectedDate = days[_selectedDayIndex];
    final selectedDateStr =
        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    final blockedSlots = _blockedSlots[selectedDateStr] ?? [];
    final reservedSlots = _reservedSlots[selectedDateStr] ?? [];

    final allSlots = [
      '08:00',
      '09:00',
      '10:00',
      '11:00',
      '12:00',
      '13:00',
      '14:00',
      '15:00',
      '16:00',
      '17:00',
      '18:00',
      '19:00',
      '20:00',
      '21:00',
      '22:00'
    ];
    final isToday = selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;
    final currentHourStr =
        '${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text('Availability',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => BookingScreen(
                      session: widget.session,
                      clientID: widget.clientID,
                      token: widget.token,
                      packages: _packages,
                    ),
                    transitionsBuilder: (_, anim, __, child) => FadeTransition(
                      opacity: anim,
                      child: child,
                    ),
                  ),
                ),
                child: const Text('See all >',
                    style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (int i = 0; i < days.length; i++) ...[
                _dateChip(
                    getDayName(days[i]),
                    '${getMonthName(days[i])} ${days[i].day}',
                    _selectedDayIndex == i, () {
                  setState(() => _selectedDayIndex = i);
                }),
                if (i < days.length - 1) const SizedBox(width: 8),
              ],
              const SizedBox(width: 16),
              Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(width: 16),
              Expanded(
                child: _loadingAvailability
                    ? const Center(
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFF38BDF8))))
                    : allSlots.isEmpty
                        ? const Text('No slots available',
                            style: TextStyle(color: Colors.grey, fontSize: 12))
                        : Builder(
                            builder: (context) {
                              final availableList = allSlots
                                  .where((s) {
                                    if (isToday) {
                                      final currentHour =
                                          '${today.hour.toString().padLeft(2, '0')}:00';
                                      return s.compareTo(currentHour) >= 0;
                                    }
                                    return true;
                                  })
                                  .take(4)
                                  .toList();

                              if (availableList.isEmpty) {
                                return const Text('No slots available',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 12));
                              }

                              Widget buildSlot(String time) {
                                final isPastToday = isToday &&
                                    time.compareTo(currentHourStr) <= 0;
                                final isBooked = blockedSlots.contains(time) ||
                                    reservedSlots.contains(time) ||
                                    isPastToday;
                                return _timeChip(
                                    time,
                                    false,
                                    isBooked
                                        ? null
                                        : () {
                                            Navigator.push(
                                              context,
                                              PageRouteBuilder(
                                                pageBuilder: (_, __, ___) =>
                                                    BookingScreen(
                                                  session: widget.session,
                                                  clientID: widget.clientID,
                                                  token: widget.token,
                                                  packages: _packages,
                                                  initialDate: selectedDate,
                                                  initialTime: time,
                                                ),
                                                transitionsBuilder:
                                                    (_, anim, __, child) =>
                                                        FadeTransition(
                                                  opacity: anim,
                                                  child: child,
                                                ),
                                              ),
                                            );
                                          },
                                    width: null);
                              }

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                          child: buildSlot(availableList[0])),
                                      const SizedBox(width: 6),
                                      if (availableList.length > 1)
                                        Expanded(
                                            child: buildSlot(availableList[1]))
                                      else
                                        const Expanded(child: SizedBox()),
                                    ],
                                  ),
                                  if (availableList.length > 2) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                            child: buildSlot(availableList[2])),
                                        const SizedBox(width: 6),
                                        if (availableList.length > 3)
                                          Expanded(
                                              child:
                                                  buildSlot(availableList[3]))
                                        else
                                          const Expanded(child: SizedBox()),
                                      ],
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateChip(String day, String date, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0C2420),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected
                  ? const Color(0xFF38BDF8)
                  : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(day,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: selected ? 1 : 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(date,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: selected ? 1 : 0.7),
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _timeChip(String time, bool selected, VoidCallback? onTap,
      {double? width}) {
    final bool available = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: available
              ? const Color(0xFF0C2420)
              : Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected
                  ? const Color(0xFF38BDF8)
                  : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(
          time,
          style: TextStyle(
            color: available
                ? Colors.white.withValues(alpha: selected ? 1 : 0.7)
                : Colors.white.withValues(alpha: 0.3),
            fontSize: 13,
            decoration:
                available ? TextDecoration.none : TextDecoration.lineThrough,
          ),
        ),
      ),
    );
  }

  Widget _buildGym(CoachModel c) {
    final image = c.gymImage?.trim() ?? '';
    final address = c.gymAddress?.trim() ?? '';
    final tag = 'coach_gym_${c.id}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: context.fitlek.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.fitlek.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Associated gym',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.location_on_rounded,
                color: Theme.of(context).colorScheme.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(c.gymName!.trim(),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(address,
                        style: TextStyle(
                            color: context.fitlek.textSecondary,
                            fontSize: 12,
                            height: 1.4)),
                  ],
                ])),
          ]),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: image.isEmpty
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ImagePreview(imageUrl: image, tag: tag))),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 2.4,
                  child: Stack(fit: StackFit.expand, children: [
                    ColoredBox(
                        color: context.fitlek.card2,
                        child: Center(
                            child: Icon(Icons.fitness_center_rounded,
                                size: 38, color: context.fitlek.textMuted))),
                    if (image.isNotEmpty) ...[
                      Hero(
                          tag: tag,
                          child: Image.network(image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                  child: Icon(Icons.broken_image_outlined,
                                      color: context.fitlek.textMuted)))),
                      Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.fullscreen_rounded,
                                  color: Colors.white, size: 20))),
                    ],
                  ]),
                )),
          ),
        ]),
      ),
    );
  }

  Widget _buildPracticalInfo(CoachModel c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Practical info',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF0F2C24),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                _practicalRow(Icons.location_on, 'Casablanca', null),
                Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                if (c.instagramPage.isNotEmpty) ...[
                  Builder(builder: (context) {
                    String handle = c.instagramPage.trim();
                    while (handle.startsWith('@')) {
                      handle = handle.substring(1).trim();
                    }
                    if (handle.contains('instagram.com/')) {
                      handle = handle
                          .split('instagram.com/')
                          .last
                          .split('?')
                          .first
                          .replaceAll('/', '');
                    }
                    return _practicalRow(
                      Icons.camera_alt,
                      '@$handle',
                      Icons.open_in_new,
                      customIcon: const InstagramIcon(size: 20),
                      onTap: () async {
                        final url = Uri.parse('https://instagram.com/$handle');
                        try {
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                        } catch (_) {
                          await launchUrl(url);
                        }
                      },
                    );
                  }),
                  Divider(
                      color: Colors.white.withValues(alpha: 0.05), height: 1),
                ],
                _practicalRow(
                  Icons.qr_code_2,
                  'Coach QR code',
                  Icons.chevron_right,
                  onTap: () {
                    if (c.invitationCode.isNotEmpty) {
                      _showQrDialog(c.invitationCode);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _practicalRow(IconData icon, String text, IconData? trailingIcon,
      {VoidCallback? onTap, Widget? customIcon}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              customIcon ??
                  Icon(icon,
                      color: Colors.white.withValues(alpha: 0.7), size: 20),
              const SizedBox(width: 16),
              Expanded(
                  child: Text(text,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500))),
              if (trailingIcon != null)
                Icon(trailingIcon,
                    color: Colors.white.withValues(alpha: 0.5), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrCode(CoachModel c) {
    final code = c.invitationCode;
    if (code.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.fitlek.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.fitlek.border),
        ),
        child: Column(
          children: [
            Row(children: [_sectionHeader('Coach QR Code')]),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => _showQrDialog(code),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                    data: code, version: QrVersions.auto, size: 150),
              ),
            ),
            const SizedBox(height: 10),
            Text('Tap to enlarge',
                style:
                    TextStyle(color: context.fitlek.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  void _openAllReviews() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ClientCoachReviewsScreen(
          coachID: widget.session.coachID,
          coachName: _coach?.fullName ?? widget.session.coachName,
          clientID: widget.clientID,
          token: widget.token,
          initialReviews: _reviews,
          initialAvgRating: _avgRating,
          initialTotalReviews: _totalReviews,
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );
  }

  Widget _buildReviewsSection(double rating, bool canReview) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 32, 0, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Client reviews',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              GestureDetector(
                onTap: _openAllReviews,
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFF38BDF8), size: 16),
                    const SizedBox(width: 4),
                    Text(
                        '${_avgRating.toStringAsFixed(1)} · $_totalReviews reviews >',
                        style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
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
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                    color: _showReviewForm
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1)
                        : context.fitlek.card,
                    borderRadius: BorderRadius.circular(14),
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
        const SizedBox(height: 18),
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
        else ...[
          ..._reviews.take(5).map(_buildReviewCard),
          if (_reviews.length > 5 || _totalReviews > 5) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _openAllReviews,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View all ${_totalReviews > _reviews.length ? _totalReviews : _reviews.length} reviews',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded,
                          color: Color(0xFF38BDF8), size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ]),
    );
  }

  Widget _buildReviewForm() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: context.fitlek.card,
            borderRadius: BorderRadius.circular(16),
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
          const SizedBox(height: 10),
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
                        size: 30)),
              ),
            );
          })),
          const SizedBox(height: 16),
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
                      : Text(
                          _myReview != null
                              ? 'Update review'
                              : 'Publish review',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 0.4)),
                ),
              ),
            ),
          ),
        ]),
      );

  Widget _buildReviewCard(ReviewItem review) {
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: context.fitlek.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isMyReview
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                  : context.fitlek.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 38,
            height: 38,
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
                        fontSize: 15))),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Flexible(
                    child: Text(
                      review.clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: isMyReview
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ),
                  if (isMyReview) ...[
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
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
                      size: 13))),
        ]),
        if (review.comment?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          Text(review.comment!,
              style: TextStyle(
                  color: context.fitlek.textSecondary,
                  fontSize: 13,
                  height: 1.58)),
        ],
      ]),
    );
  }

  Widget _buildEmptyReviews() {
    final canReview = !widget.preview &&
        widget.session.isConfirmed &&
        widget.session.sessionStart.isBefore(DateTime.now());
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
            color: context.fitlek.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.fitlek.border)),
        child: Column(children: [
          Icon(Icons.star_border_rounded,
              color: context.fitlek.textMuted, size: 38),
          const SizedBox(height: 10),
          Text('No reviews yet',
              style: TextStyle(
                  color: context.fitlek.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          if (canReview) ...[
            const SizedBox(height: 4),
            Text('Be the first to share your experience',
                style:
                    TextStyle(color: context.fitlek.textMuted, fontSize: 11)),
          ],
        ]),
      ),
    );
  }

  Widget _avatarPlaceholder(String name) => Container(
        color: context.fitlek.card,
        child: Center(
            child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 80,
              fontWeight: FontWeight.w900),
        )),
      );

  Widget _sectionHeader(String title) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 3,
            height: 17,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
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
                  ? Colors.black.withValues(alpha: 0.45)
                  : context.fitlek.card,
              borderRadius: BorderRadius.circular(11),
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

class InstagramIcon extends StatelessWidget {
  final double size;
  const InstagramIcon({super.key, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.25),
        gradient: const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xFFFEDA77),
            Color(0xFFF58529),
            Color(0xFFDD2A7B),
            Color(0xFF8134AF),
            Color(0xFF515BD4),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.7,
            height: size * 0.7,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: size * 0.08),
              borderRadius: BorderRadius.circular(size * 0.2),
            ),
          ),
          Container(
            width: size * 0.35,
            height: size * 0.35,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: size * 0.08),
              shape: BoxShape.circle,
            ),
          ),
          Positioned(
            top: size * 0.18,
            right: size * 0.18,
            child: Container(
              width: size * 0.1,
              height: size * 0.1,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
