import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/apiService.dart';
import 'coachEditProfile.dart';
import 'coachNotifications.dart';
import 'welcome.dart';
import 'blockedUsersList.dart';
import '../../components/theme_selector.dart';
import '../../services/theme_service.dart';
import '../../constants/app_colors.dart';
import '../../theme/fitlek_theme_extension.dart';
import 'package:fitlek1/constants/urls.dart' as urls;

class ApiConfig {
  static const String baseUrl = urls.baseUrl;
}

class CoachProfileData {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String gender;
  final String? avatarUrl;
  final int? advisorID;
  final String bio;
  final String specialty;
  final String experience;
  final String professionalTitle;
  final List<String> certifications;
  final List<String> specialties;
  final bool publicProfile;
  final bool directMessaging;
  final String instagramPage;
  final String? certificateUrl;
  final String invitationCode;
  final int totalInvitations;
  final int earnedPoints;
  final int referralReward;
  final String tel;
  final String ville;
  final double? price;

  CoachProfileData({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.gender,
    this.avatarUrl,
    this.advisorID,
    required this.bio,
    required this.specialty,
    required this.experience,
    required this.professionalTitle,
    required this.certifications,
    required this.specialties,
    required this.publicProfile,
    required this.directMessaging,
    required this.instagramPage,
    this.certificateUrl,
    required this.invitationCode,
    required this.totalInvitations,
    required this.earnedPoints,
    required this.referralReward,
    required this.tel,
    required this.ville,
    this.price,
  });

  bool get hasProfessionalInfo =>
      specialty.isNotEmpty ||
      experience.isNotEmpty ||
      professionalTitle.isNotEmpty ||
      specialties.isNotEmpty ||
      bio.isNotEmpty ||
      ville.isNotEmpty;

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded
              .map((e) => e?.toString().trim() ?? '')
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } catch (_) {}
    }
    return const [];
  }

  factory CoachProfileData.fromJson(Map<String, dynamic> json) {
    double? parsedPrice;
    if (json['price'] != null) {
      parsedPrice = double.tryParse(json['price'].toString());
    }
    return CoachProfileData(
      id: int.tryParse(json['id'].toString()) ?? 0,
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      advisorID: json['advisorID'] != null ? int.tryParse(json['advisorID'].toString()) : null,
      bio: json['bio'] ?? '',
      specialty: json['specialty']?.toString() ?? '',
      experience: json['experience']?.toString() ?? '',
      professionalTitle: json['professionalTitle']?.toString() ?? '',
      certifications: _parseStringList(json['certifications']),
      specialties: _parseStringList(json['specialties']),
      publicProfile: json['publicProfile'] == null
          ? true
          : (json['publicProfile'] == true || json['publicProfile'] == 1),
      directMessaging: json['directMessaging'] == null
          ? true
          : (json['directMessaging'] == true || json['directMessaging'] == 1),
      instagramPage: json['instagramPage'] ?? '',
      certificateUrl: json['certificateUrl'],
      invitationCode: json['invitationCode'] ?? '',
      totalInvitations: int.tryParse(json['totalInvitations'].toString()) ?? 0,
      earnedPoints: int.tryParse(json['earnedPoints'].toString()) ?? 0,
      referralReward: int.tryParse(json['referralReward'].toString()) ?? 20,
      tel: json['tel']?.toString() ?? '',
      ville: json['ville']?.toString() ?? '',
      price: parsedPrice,
    );
  }
}

class DashboardStats {
  final int totalReservations;
  final int totalClients;
  final int invitationPoints;

  DashboardStats({
    required this.totalReservations,
    required this.totalClients,
    required this.invitationPoints,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalReservations: int.tryParse(json['totalReservations'].toString()) ?? 0,
      totalClients: int.tryParse(json['totalClients'].toString()) ?? 0,
      invitationPoints: int.tryParse(json['invitationPoints'].toString()) ?? 0,
    );
  }

  factory DashboardStats.empty() =>
      DashboardStats(totalReservations: 0, totalClients: 0, invitationPoints: 0);
}

class CoachProfile extends StatefulWidget {
  final int coachID;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String? email;
  final String token;
  final VoidCallback? onLogout;

  /// Called after the coach successfully updates their profile/avatar so the
  /// shared Coach Header (owned by MainLayoutCoach) can refresh its identity.
  final VoidCallback? onProfileUpdated;

  const CoachProfile({
    super.key,
    required this.coachID,
    required this.firstName,
    required this.lastName,
    required this.token,
    this.avatarUrl,
    this.email,
    this.onLogout,
    this.onProfileUpdated,
  });

  @override
  State<CoachProfile> createState() => _CoachProfileState();
}

class _CoachProfileState extends State<CoachProfile> with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _hasError = false;
  bool _uploadingAvatar = false;
  CoachProfileData? _profile;
  DashboardStats _stats = DashboardStats.empty();
  List<Map<String, dynamic>> _galleryImages = [];
  late AnimationController _animCtrl;

  // Identity prefers the freshly loaded backend profile, falling back to the
  // values passed by the parent session (used during the first loading frame).
  String get _firstName => (_profile?.firstName.isNotEmpty ?? false) ? _profile!.firstName : widget.firstName;
  String get _lastName => (_profile?.lastName.isNotEmpty ?? false) ? _profile!.lastName : widget.lastName;
  String? get _avatar => (_profile?.avatarUrl?.isNotEmpty ?? false) ? _profile!.avatarUrl : widget.avatarUrl;
  String? get _email => (_profile?.email.isNotEmpty ?? false) ? _profile!.email : widget.email;

  String get _fullName => '$_firstName $_lastName'.trim();
  String get _initials {
    final f = _firstName.isNotEmpty ? _firstName[0] : '';
    final l = _lastName.isNotEmpty ? _lastName[0] : '';
    return (f + l).toUpperCase();
  }

  Map<String, String> get _authHeaders => {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      };

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _loadAll();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final results = await Future.wait([
        http.get(Uri.parse('${ApiConfig.baseUrl}/coach/profile'), headers: _authHeaders),
        http.get(Uri.parse('${ApiConfig.baseUrl}/coach/dashboard'), headers: _authHeaders),
      ]);

      if (!mounted) return;

      final profileRes = results[0];
      final dashRes = results[1];

      if (profileRes.statusCode != 200) {
        setState(() {
          _hasError = true;
          _loading = false;
        });
        return;
      }

      final profileData = CoachProfileData.fromJson(jsonDecode(profileRes.body));

      DashboardStats stats = DashboardStats.empty();
      if (dashRes.statusCode == 200) {
        stats = DashboardStats.fromJson(jsonDecode(dashRes.body));
      }

      setState(() {
        _profile = profileData;
        _stats = stats;
      });

      // Now fetch gallery images using the coach ID
      try {
        final galleryRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/coaches/${profileData.id}/images'), headers: _authHeaders);
        if (galleryRes.statusCode == 200) {
          final galleryData = jsonDecode(galleryRes.body);
          if (galleryData is List) {
            setState(() {
              _galleryImages = List<Map<String, dynamic>>.from(galleryData);
            });
          }
        }
      } catch (_) {}

      setState(() {
        _loading = false;
      });
      _animCtrl.forward(from: 0);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _loading = false;
      });
    }
  }

  void _copyToClipboard(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    _showSnack('$label copied to clipboard');
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: TextStyle(
                color: isError ? Theme.of(context).colorScheme.onError : Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
        backgroundColor: isError ? context.fitlek.error : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLogoutDialog() {
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
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: context.fitlek.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: context.fitlek.error.withValues(alpha: 0.2)),
                ),
                child: Icon(Icons.logout_rounded, color: context.fitlek.error, size: 26),
              ),
              const SizedBox(height: 20),
              Text('Log out', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Are you sure you want to log out?',
                  textAlign: TextAlign.center, style: TextStyle(color: context.fitlek.textMuted, fontSize: 13.5, height: 1.5)),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.fitlek.border),
                        ),
                        child: Center(
                          child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _handleLogout,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(color: context.fitlek.error, borderRadius: BorderRadius.circular(14)),
                        child: Center(
                          child: Text('Log out',
                              style: TextStyle(color: Theme.of(context).colorScheme.onError, fontWeight: FontWeight.w700, fontSize: 14)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    Navigator.pop(context);
    await ApiService.clearToken();
    if (widget.onLogout != null) {
      widget.onLogout!();
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => FadeTransition(opacity: animation, child: const WelcomeScreen()),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (_) => false,
    );
  }

  Future<void> _openEditProfile() async {
    if (_profile == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CoachEditProfile(profile: _profile!, token: widget.token),
      ),
    );
    if (changed == true) {
      await _loadAll();
      widget.onProfileUpdated?.call();
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CoachNotifications()),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    final p = _profile;
    if (p == null || _uploadingAvatar) return;

    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await file.readAsBytes();
      final ext = file.name.split('.').last.toLowerCase();
      final mime = ext == 'png'
          ? 'image/png'
          : ext == 'webp'
              ? 'image/webp'
              : 'image/jpeg';

      final up = await ApiService.uploadMultipart(
        '/coach/avatar',
        fields: const {},
        fileBytes: bytes,
        fileField: 'avatar',
        fileName: file.name,
        mimeType: mime,
      );
      if (up['ok'] != true) {
        if (mounted) _showSnack(up['message']?.toString() ?? 'Upload failed', isError: true);
        return;
      }
      final newUrl = up['url']?.toString();
      if (newUrl == null || newUrl.isEmpty) {
        if (mounted) _showSnack('Upload failed', isError: true);
        return;
      }

      // Persist the new avatar via the secure edit endpoint (req.user.id).
      final save = await ApiService.put('/coach/profile/edit', {
        'firstName': p.firstName,
        'lastName': p.lastName,
        'gender': p.gender,
        'bio': p.bio,
        'specialty': p.specialty,
        'experience': p.experience,
        'professionalTitle': p.professionalTitle,
        'certifications': p.certifications,
        'specialties': p.specialties,
        'publicProfile': p.publicProfile,
        'directMessaging': p.directMessaging,
        'instagramPage': p.instagramPage,
        'avatarUrl': newUrl,
        'tel': p.tel,
        'ville': p.ville,
      });
      if (save['ok'] != true) {
        if (mounted) _showSnack(save['message']?.toString() ?? 'Error while saving', isError: true);
        return;
      }

      await _loadAll();
      widget.onProfileUpdated?.call();
      if (mounted) _showSnack('Profile photo updated');
    } catch (e) {
      if (mounted) _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Widget _staggered(int index, Widget child) {
    final start = (index * 0.08).clamp(0.0, 0.6);
    final end = (start + 0.4).clamp(0.0, 1.0);
    final anim = CurvedAnimation(parent: _animCtrl, curve: Interval(start, end, curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(anim),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: _loading
            ? _buildLoading()
            : _hasError
                ? _buildError()
                : RefreshIndicator(
                    color: Theme.of(context).colorScheme.primary,
                    backgroundColor: context.fitlek.card,
                    onRefresh: _loadAll,
                    child: _buildContent(),
                  ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary, strokeWidth: 2.4),
          ),
          const SizedBox(height: 16),
          Text('Loading profile...',
              style: TextStyle(color: context.fitlek.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(color: context.fitlek.card2, shape: BoxShape.circle),
              child: Icon(Icons.wifi_off_rounded, color: context.fitlek.textMuted, size: 34),
            ),
            const SizedBox(height: 16),
            Text('Unable to load profile',
                style: TextStyle(color: context.fitlek.textMuted, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _loadAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(14)),
                child: Text('Retry', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final p = _profile!;
    final s = _stats;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(child: _staggered(0, _buildProfileCard(p))),
        SliverToBoxAdapter(child: _staggered(1, _buildStatsRow(s))),
        if (_galleryImages.isNotEmpty) SliverToBoxAdapter(child: _staggered(2, _buildGallery())),
        SliverToBoxAdapter(child: _staggered(2, _buildProfessionalInfo(p))),
        SliverToBoxAdapter(child: _staggered(3, _buildReferralCard(p))),
        SliverToBoxAdapter(child: _staggered(4, _buildSettings())),
        SliverToBoxAdapter(child: _staggered(5, _buildFooter())),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }

  Widget _buildGallery() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text('Gallery Preview', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _galleryImages.length,
              itemBuilder: (ctx, i) {
                final img = _galleryImages[i];
                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (c) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: EdgeInsets.zero,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(c),
                          child: InteractiveViewer(
                            child: Image.network(img['urlImage'], fit: BoxFit.contain),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(image: NetworkImage(img['urlImage']), fit: BoxFit.cover),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Profile identity card ──────────────────────────────────────────────
  Widget _buildProfileCard(CoachProfileData p) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
      decoration: BoxDecoration(
        color: f.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: f.border),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [cs.primary, f.primaryDim]),
                  boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.22), blurRadius: 22, spreadRadius: 1)],
                ),
                padding: const EdgeInsets.all(3.5),
                child: ClipOval(
                  child: Container(
                    color: f.card2,
                    child: (_avatar != null && _avatar!.isNotEmpty)
                        ? Image.network(_avatar!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _initialsAvatar())
                        : _initialsAvatar(),
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: GestureDetector(
                  onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: f.card, width: 3),
                    ),
                    child: _uploadingAvatar
                        ? Padding(
                            padding: const EdgeInsets.all(8),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
                            ),
                          )
                        : Icon(Icons.camera_alt_rounded, size: 16, color: cs.onPrimary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _fullName.isNotEmpty ? _fullName : 'Coach',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: cs.onSurface, fontSize: 22, fontWeight: FontWeight.w800, height: 1.15),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Coach',
                    style: TextStyle(color: cs.primary, fontSize: 11.5, fontWeight: FontWeight.w800)),
              ),
              if ((_email ?? '').isNotEmpty) ...[
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    _email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: f.textMuted, fontSize: 12.5, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: _openEditProfile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_rounded, size: 17, color: cs.onPrimary),
                  const SizedBox(width: 9),
                  Text('Edit Profile',
                      style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialsAvatar() => Center(
        child: Text(_initials.isEmpty ? '?' : _initials,
            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 30, fontWeight: FontWeight.w800)),
      );

  // ── Stats row: Clients / Bookings / Points ─────────────────────────────
  Widget _buildStatsRow(DashboardStats s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          Expanded(child: _statCard('${s.totalClients}', 'Clients')),
          const SizedBox(width: 12),
          Expanded(child: _statCard('${s.totalReservations}', 'Bookings')),
          const SizedBox(width: 12),
          Expanded(child: _statCard('${s.invitationPoints}', 'Points')),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: f.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: f.border),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: cs.onSurface, fontSize: 24, fontWeight: FontWeight.w900, height: 1)),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: f.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Professional information ───────────────────────────────────────────
  Widget _buildProfessionalInfo(CoachProfileData p) {
    final f = context.fitlek;
    final specialtyText = p.specialties.isNotEmpty
        ? p.specialties.join(', ')
        : p.specialty;
    final titleText = p.professionalTitle.isNotEmpty ? p.professionalTitle : p.experience;
    final rows = <Widget>[];
    if (titleText.isNotEmpty) {
      rows.add(_infoRow(Icons.workspace_premium_rounded, 'Professional Title', titleText));
    }
    if (specialtyText.isNotEmpty) {
      rows.add(_infoRow(Icons.fitness_center_rounded, 'Specialties', specialtyText));
    }
    if (p.certifications.isNotEmpty) {
      rows.add(_infoRow(Icons.verified_rounded, 'Certifications', p.certifications.join(', ')));
    }
    if (p.bio.isNotEmpty) {
      rows.add(_infoRow(Icons.description_rounded, 'Bio', p.bio));
    }
    if (p.ville.isNotEmpty) {
      rows.add(_infoRow(Icons.location_on_rounded, 'Location', p.ville));
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
      decoration: BoxDecoration(
        color: f.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: f.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PROFESSIONAL INFORMATION',
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
          const SizedBox(height: 14),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                'Add your professional details from Edit Profile.',
                style: TextStyle(color: f.textMuted, fontSize: 13, height: 1.5),
              ),
            )
          else
            ...rows,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: f.card2, borderRadius: BorderRadius.circular(12), border: Border.all(color: f.border)),
            child: Icon(icon, size: 19, color: cs.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: f.textMuted, fontSize: 11.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(value, style: TextStyle(color: cs.onSurface, fontSize: 14.5, fontWeight: FontWeight.w600, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Coach referral card (dark) ─────────────────────────────────────────
  Widget _buildReferralCard(CoachProfileData p) {
    final code = p.invitationCode.isNotEmpty ? p.invitationCode : '—';
    const onDark = AppColors.sand;
    final onDarkMuted = AppColors.sand.withValues(alpha: 0.62);
    final accent = context.fitlek.success;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cyprus, AppColors.primaryDim],
        ),
        boxShadow: [BoxShadow(color: AppColors.cyprus.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Coach Referral',
                    style: TextStyle(color: onDark, fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.sand.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.monetization_on_rounded, size: 14, color: accent),
                  const SizedBox(width: 5),
                  Text('${p.earnedPoints}', style: const TextStyle(color: onDark, fontSize: 12.5, fontWeight: FontWeight.w800)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Invite friends and earn rewards', style: TextStyle(color: accent, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),

          // ── Code + QR ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.sand.withValues(alpha: 0.14)),
            ),
            child: Row(
              children: [
                // QR miniature cliquable → ouvre le grand QR en popup
                GestureDetector(
                  onTap: () => _showQrDialog(code),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: onDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: QrImageView(
                      data: code,
                      version: QrVersions.auto,
                      size: 48,
                      backgroundColor: onDark,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: onDark, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ),
                GestureDetector(
                  onTap: () => _copyToClipboard(p.invitationCode, 'Code'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(color: onDark, borderRadius: BorderRadius.circular(10)),
                    child: const Text('Copy', style: TextStyle(color: AppColors.cyprus, fontSize: 13, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Earn ${p.referralReward} bonus points for every professional coach you onboard to the SIRVYA ecosystem.',
            style: TextStyle(color: onDarkMuted, fontSize: 11.5, height: 1.5, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // ── QR code popup (grand format) ────────────────────────────────────────
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
              Text('Scan to invite',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: QrImageView(
                  data: code,
                  version: QrVersions.auto,
                  size: 220,
                ),
              ),
              const SizedBox(height: 16),
              Text(code,
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  _copyToClipboard(code, 'Code');
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(14)),
                  child: Center(
                    child: Text('Copy code',
                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Settings group: Appearance / Notifications / Logout / Delete Account ───
  Widget _buildSettings() {
    final f = context.fitlek;
    final cs = Theme.of(context).colorScheme;
    final controller = ThemeControllerScope.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(
        color: f.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: f.border),
      ),
      child: Column(
        children: [
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => _settingsRow(
              icon: Icons.brightness_6_rounded,
              iconColor: cs.primary,
              label: 'Appearance',
              trailingText: ThemeService.label(controller.mode),
              onTap: () => _showThemeSheet(controller),
            ),
          ),
          _settingsDivider(),
          _settingsRow(
            icon: Icons.notifications_none_rounded,
            iconColor: cs.primary,
            label: 'Notifications',
            onTap: _openNotifications,
          ),
          _settingsDivider(),
          _settingsRow(
            icon: Icons.block_rounded,
            iconColor: cs.primary,
            label: 'Blocked Users',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BlockedUsersList(token: widget.token)),
              );
            },
          ),
          _settingsDivider(),
          _settingsRow(
            icon: Icons.logout_rounded,
            iconColor: f.error,
            label: 'Logout',
            labelColor: f.error,
            showChevron: false,
            onTap: _showLogoutDialog,
          ),
          _settingsDivider(),
          _settingsRow(
            icon: Icons.delete_forever_rounded,
            iconColor: f.textMuted,
            label: 'Delete Account',
            labelColor: f.textMuted,
            showChevron: false,
            onTap: _showDeleteAccountSheet,
          ),
        ],
      ),
    );
  }

  void _showThemeSheet(ThemeController controller) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ListenableBuilder(
        listenable: controller,
        builder: (ctx, _) => Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: BoxDecoration(
            color: f.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: f.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Appearance', style: TextStyle(color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Choose the app theme', style: TextStyle(color: f.textMuted, fontSize: 12)),
              const SizedBox(height: 16),
              ...AppThemeMode.values.map((mode) {
                final selected = controller.mode == mode;
                final icon = mode == AppThemeMode.light
                    ? Icons.light_mode_rounded
                    : mode == AppThemeMode.dark
                        ? Icons.dark_mode_rounded
                        : Icons.brightness_auto_rounded;
                return GestureDetector(
                  onTap: () {
                    controller.setMode(mode);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? cs.primary.withValues(alpha: 0.1) : f.card2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? cs.primary.withValues(alpha: 0.4) : f.border),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: selected ? cs.primary : f.textMuted, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(ThemeService.label(mode),
                              style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                        ),
                        if (selected) Icon(Icons.check_circle_rounded, color: cs.primary, size: 20),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsDivider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Divider(height: 1, thickness: 1, color: context.fitlek.border.withValues(alpha: 0.6)),
      );

  Widget _settingsRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    Color? labelColor,
    String? trailingText,
    bool showChevron = true,
    required VoidCallback onTap,
  }) {
    final f = context.fitlek;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(color: labelColor ?? cs.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            if (trailingText != null)
              Text(trailingText, style: TextStyle(color: f.textMuted, fontSize: 12.5, fontWeight: FontWeight.w500)),
            if (showChevron) ...[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: f.textMuted, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Center(
        child: Text('CRAFTED BY SIRVYA SYSTEMS',
            style: TextStyle(
              color: context.fitlek.textMuted.withValues(alpha: 0.7),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            )),
      ),
    );
  }

  // ── Account Deletion Flow ──────────────────────────────────────
  void _showDeleteAccountSheet() {
    int step = 1;
    bool understood = false;
    bool loading = false;
    String? errorMsg;
    String otpValue = '';
    int secondsLeft = 600;
    bool canResend = false;

    final apiHeaders = {
      'Authorization': 'Bearer ${widget.token}',
      'Content-Type': 'application/json',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Future<void> startCountdown() async {
            setSheet(() { secondsLeft = 600; canResend = false; });
            while (secondsLeft > 0) {
              await Future.delayed(const Duration(seconds: 1));
              if (!ctx.mounted) return;
              setSheet(() => secondsLeft--);
            }
            if (ctx.mounted) setSheet(() => canResend = true);
          }

          Future<void> requestOtp() async {
            setSheet(() { loading = true; errorMsg = null; });
            try {
              final res = await http.post(
                Uri.parse('${ApiConfig.baseUrl}/auth/request-delete-otp'),
                headers: apiHeaders,
              ).timeout(const Duration(seconds: 15));
              final body = jsonDecode(res.body) as Map<String, dynamic>;
              if (res.statusCode == 409 && body['blocked'] == true) {
                setSheet(() { loading = false; errorMsg = body['reason'] as String? ?? 'Cannot delete account right now.'; });
                return;
              }
              if (res.statusCode != 200) {
                setSheet(() { loading = false; errorMsg = body['error'] as String? ?? 'Failed to send code.'; });
                return;
              }
              setSheet(() { loading = false; step = 2; otpValue = ''; errorMsg = null; });
              startCountdown();
            } catch (_) {
              setSheet(() { loading = false; errorMsg = 'Unable to reach the server.'; });
            }
          }

          Future<void> confirmDelete() async {
            if (otpValue.length != 6) {
              setSheet(() => errorMsg = 'Please enter the full 6-digit code.');
              return;
            }
            setSheet(() { loading = true; errorMsg = null; });
            try {
              final res = await http.post(
                Uri.parse('${ApiConfig.baseUrl}/auth/confirm-delete-account'),
                headers: apiHeaders,
                body: jsonEncode({'otp': otpValue}),
              ).timeout(const Duration(seconds: 15));
              final body = jsonDecode(res.body) as Map<String, dynamic>;
              if (res.statusCode == 200 && body['deleted'] == true) {
                if (ctx.mounted) Navigator.pop(ctx);
                _handleLogout();
                return;
              }
              setSheet(() { loading = false; errorMsg = body['error'] as String? ?? 'Verification failed.'; });
            } catch (_) {
              setSheet(() { loading = false; errorMsg = 'Unable to reach the server.'; });
            }
          }

          final f  = context.fitlek;
          final cs = Theme.of(context).colorScheme;
          final errorColor  = f.error;
          final borderColor = f.border;
          final textMuted   = f.textMuted;

          Widget buildStep1() => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: errorColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: Icon(Icons.delete_forever_rounded, color: errorColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Delete Account', style: TextStyle(color: cs.onSurface, fontSize: 17, fontWeight: FontWeight.w800)),
                      Text('This action is permanent', style: TextStyle(color: textMuted, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: errorColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: errorColor.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('What will be deleted:', style: TextStyle(color: errorColor, fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ...[
                      'Your coach profile and personal information',
                      'All client relationships and bookings',
                      'Messages and conversations',
                      'Referral points and invitation history',
                    ].map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        children: [
                          Icon(Icons.remove_circle_outline, color: errorColor, size: 13),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item, style: TextStyle(color: textMuted, fontSize: 12))),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => setSheet(() => understood = !understood),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: understood ? errorColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: understood ? errorColor : borderColor, width: 1.5),
                      ),
                      child: understood ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'I understand this action is irreversible and all my data will be permanently deleted.',
                        style: TextStyle(color: cs.onSurface, fontSize: 12.5, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: errorColor.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(Icons.warning_rounded, color: errorColor, size: 14),
                      const SizedBox(width: 8),
                      Expanded(child: Text(errorMsg!, style: TextStyle(color: errorColor, fontSize: 12))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Center(child: Text('Cancel',
                            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 14))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: (understood && !loading) ? requestOtp : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: understood ? errorColor : errorColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: loading
                              ? const SizedBox(width: 18, height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('SEND CODE',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.8)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );

          Widget buildStep2() {
            final mins = (secondsLeft ~/ 60).toString().padLeft(2, '0');
            final secs = (secondsLeft % 60).toString().padLeft(2, '0');
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: errorColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: Icon(Icons.mark_email_read_rounded, color: errorColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Verify your identity', style: TextStyle(color: cs.onSurface, fontSize: 17, fontWeight: FontWeight.w800)),
                        Text('Check your email for the code', style: TextStyle(color: textMuted, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Enter the 6-digit code sent to your email address to confirm account deletion.',
                  style: TextStyle(color: textMuted, fontSize: 13, height: 1.5)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: errorColor.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: TextField(
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurface, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 10),
                    decoration: InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      hintText: '● ● ● ● ● ●',
                      hintStyle: TextStyle(color: borderColor, fontSize: 22, letterSpacing: 8),
                    ),
                    onChanged: (v) => setSheet(() => otpValue = v.trim()),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!canResend)
                      Text('Code expires in $mins:$secs', style: TextStyle(color: textMuted, fontSize: 12))
                    else
                      Text('Code expired', style: TextStyle(color: errorColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    GestureDetector(
                      onTap: canResend && !loading ? requestOtp : null,
                      child: Text('Resend code', style: TextStyle(
                        color: canResend ? errorColor : textMuted,
                        fontSize: 12, fontWeight: FontWeight.w700,
                        decoration: canResend ? TextDecoration.underline : null,
                      )),
                    ),
                  ],
                ),
                if (errorMsg != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: errorColor.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: errorColor, size: 14),
                        const SizedBox(width: 8),
                        Expanded(child: Text(errorMsg!, style: TextStyle(color: errorColor, fontSize: 12))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: loading ? null : () => setSheet(() { step = 1; errorMsg = null; }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Center(child: Text('Back',
                              style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 14))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: (otpValue.length == 6 && !loading) ? confirmDelete : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: otpValue.length == 6 ? errorColor : errorColor.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: loading
                                ? const SizedBox(width: 18, height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('DELETE ACCOUNT',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: BoxDecoration(
                color: f.card,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: step == 1
                    ? KeyedSubtree(key: const ValueKey('step1'), child: buildStep1())
                    : KeyedSubtree(key: const ValueKey('step2'), child: buildStep2()),
              ),
            ),
          );
        },
      ),
    );
  }
}