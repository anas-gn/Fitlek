import '../../services/media_picker_service.dart';
import '../../services/live_updates.dart';
import 'dart:convert';
import 'clientCoachDetail.dart';
import '../../models/anas/reservation.dart';
import '../../models/coach_profile_completion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/apiService.dart';
import 'coachNotifications.dart';
import 'welcome.dart';
import 'blockedUsersList.dart';
import '../../components/theme_selector.dart';
import '../../services/theme_service.dart';
import '../../constants/app_colors.dart';
import '../../theme/fitlek_theme_extension.dart';
import 'package:fitlek1/constants/urls.dart' as urls;
import 'coachAboutYou.dart';
import 'coachExpertise.dart';
import 'coachPackages.dart';
import 'coachLocations.dart';
import 'coachPhotos.dart';
import 'coachVisibility.dart';
import 'coachAccount.dart';
import 'clientCoachReviews.dart';

class ApiConfig {
  static String baseUrl = urls.baseUrl;
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
  final List<dynamic> certifications;
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
  final int? categoryID;
  final List<String> languages;
  final List<String> clientLevels;
  final bool showGender;

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
    this.categoryID,
    required this.languages,
    required this.clientLevels,
    required this.showGender,
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
      } catch (_) {
        return value
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    return [];
  }

  static List<dynamic> _parseDynamicList(dynamic value) {
    if (value is List) return value;
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return decoded;
      } catch (_) {}
    }
    return [];
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
      advisorID: json['advisorID'] != null
          ? int.tryParse(json['advisorID'].toString())
          : null,
      bio: json['bio'] ?? '',
      specialty: json['specialty']?.toString() ?? '',
      experience: json['experience']?.toString() ?? '',
      professionalTitle: json['professionalTitle']?.toString() ?? '',
      certifications: _parseDynamicList(json['certifications']),
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
      categoryID: json['categoryID'] != null
          ? int.tryParse(json['categoryID'].toString())
          : null,
      languages: _parseStringList(json['languages']),
      clientLevels: _parseStringList(json['clientLevels']),
      showGender: json['showGender'] == null
          ? true
          : (json['showGender'] == true || json['showGender'] == 1),
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
      totalReservations:
          int.tryParse(json['totalReservations'].toString()) ?? 0,
      totalClients: int.tryParse(json['totalClients'].toString()) ?? 0,
      invitationPoints: int.tryParse(json['invitationPoints'].toString()) ?? 0,
    );
  }

  factory DashboardStats.empty() => DashboardStats(
      totalReservations: 0, totalClients: 0, invitationPoints: 0);
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

class _CoachProfileState extends State<CoachProfile>
    with SingleTickerProviderStateMixin, LiveUpdates<CoachProfile> {
  @override
  Set<String> get liveDomains =>
      {'profile', 'edit', 'packages', 'notifications', 'locations', 'reviews'};
  @override
  Future<void> refreshLiveData() async {
    await _loadAll(silent: true);
  }

  bool _loading = true;
  bool _hasError = false;
  bool _uploadingAvatar = false;
  CoachProfileData? _profile;
  Map<String, dynamic> _completionData = {};
  int _packageCount = 0;
  DashboardStats _stats = DashboardStats.empty();
  List<Map<String, dynamic>> _galleryImages = [];
  late AnimationController _animCtrl;

  // Identity prefers the freshly loaded backend profile, falling back to the
  // values passed by the parent session (used during the first loading frame).
  String get _firstName => (_profile?.firstName.isNotEmpty ?? false)
      ? _profile!.firstName
      : widget.firstName;
  String get _lastName => (_profile?.lastName.isNotEmpty ?? false)
      ? _profile!.lastName
      : widget.lastName;
  String? get _avatar => (_profile?.avatarUrl?.isNotEmpty ?? false)
      ? _profile!.avatarUrl
      : widget.avatarUrl;
  String? get _email =>
      (_profile?.email.isNotEmpty ?? false) ? _profile!.email : widget.email;

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
    _animCtrl =
        AnimationController(vsync: this, duration: Duration(milliseconds: 900));
    _loadAll();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll({bool silent = false}) async {
    if (!silent)
      setState(() {
        _loading = true;
        _hasError = false;
      });
    try {
      final results = await Future.wait([
        http.get(Uri.parse('${ApiConfig.baseUrl}/coach/profile'),
            headers: _authHeaders),
        http.get(Uri.parse('${ApiConfig.baseUrl}/coach/dashboard'),
            headers: _authHeaders),
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

      final rawProfile = Map<String, dynamic>.from(jsonDecode(profileRes.body));
      final profileData = CoachProfileData.fromJson(rawProfile);
      final packages =
          await ApiService.get('/packages/me?coachID=${profileData.id}');
      if (!mounted) return;
      final wasComplete = CoachProfileCompletion(
              _completionData, _galleryImages.length, _packageCount)
          .isComplete;
      _completionData = rawProfile;
      _packageCount = packages['ok'] == true && packages['data'] is List
          ? (packages['data'] as List).length
          : 0;

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
        final galleryRes = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/coaches/${profileData.id}/images'),
            headers: _authHeaders);
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
      if (!wasComplete &&
          CoachProfileCompletion(
                  _completionData, _galleryImages.length, _packageCount)
              .isComplete) _showSnack('Profile Completed');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _loading = false;
      });
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: TextStyle(
                color: isError
                    ? Theme.of(context).colorScheme.onError
                    : Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
        backgroundColor: isError
            ? context.fitlek.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
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
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: context.fitlek.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: context.fitlek.error.withOpacity(0.2)),
                ),
                child: Icon(Icons.logout_rounded,
                    color: context.fitlek.error, size: 26),
              ),
              SizedBox(height: 20),
              Text('Log out',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text('Are you sure you want to log out?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: context.fitlek.textMuted,
                      fontSize: 13.5,
                      height: 1.5)),
              SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.fitlek.border),
                        ),
                        child: Center(
                          child: Text('Cancel',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _handleLogout,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                            color: context.fitlek.error,
                            borderRadius: BorderRadius.circular(14)),
                        child: Center(
                          child: Text('Log out',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onError,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
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
        pageBuilder: (_, animation, __) =>
            FadeTransition(opacity: animation, child: WelcomeScreen()),
        transitionDuration: Duration(milliseconds: 400),
      ),
      (_) => false,
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CoachNotifications()),
    );
  }

  void _previewAvatar() {
    if (_avatar == null || _avatar!.isEmpty) return;
    showDialog(
      context: context,
      builder: (c) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(c),
          child: InteractiveViewer(
            child: Image.network(_avatar!, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    final p = _profile;
    if (p == null || _uploadingAvatar) return;

    final picker = AppMediaPicker(context);
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
        fields: {},
        fileBytes: bytes,
        fileField: 'avatar',
        fileName: file.name,
        mimeType: mime,
      );
      if (up['ok'] != true) {
        if (mounted)
          _showSnack(up['message']?.toString() ?? 'Upload failed',
              isError: true);
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
        if (mounted)
          _showSnack(save['message']?.toString() ?? 'Error while saving',
              isError: true);
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
    final anim = CurvedAnimation(
        parent: _animCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset(0, 0.06), end: Offset.zero)
            .animate(anim),
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
            child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary, strokeWidth: 2.4),
          ),
          SizedBox(height: 16),
          Text('Loading profile...',
              style: TextStyle(
                  color: context.fitlek.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                  color: context.fitlek.card2, shape: BoxShape.circle),
              child: Icon(Icons.wifi_off_rounded,
                  color: context.fitlek.textMuted, size: 34),
            ),
            SizedBox(height: 16),
            Text('Unable to load profile',
                style: TextStyle(
                    color: context.fitlek.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
            SizedBox(height: 24),
            GestureDetector(
              onTap: _loadAll,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(14)),
                child: Text('Retry',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
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
      physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(child: _staggered(0, _buildHeaderUI())),
        SliverToBoxAdapter(child: _staggered(1, _buildProfileCardUI(p))),
        SliverToBoxAdapter(child: _staggered(2, _buildProfileCompletionUI(p))),
        SliverToBoxAdapter(child: _staggered(3, _buildSettingsCard1(p))),
        SliverToBoxAdapter(child: _staggered(4, _buildSettingsCard2(p))),
        SliverToBoxAdapter(child: _staggered(5, _buildLogoutButton())),
        SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildHeaderUI() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My profile',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCardUI(CoachProfileData p) {
    final cardColor = context.fitlek.card;
    final accentGreen = context.fitlek.success;
    final buttonLight = Theme.of(context).colorScheme.primary;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              GestureDetector(
                onTap: _previewAvatar,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.black26,
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: (_avatar != null && _avatar!.isNotEmpty)
                      ? Image.network(_avatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _initialsAvatar())
                      : _initialsAvatar(),
                ),
              ),
              SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fullName.isNotEmpty ? _fullName : 'Coach',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      p.professionalTitle.isNotEmpty
                          ? p.professionalTitle
                          : 'Personal trainer',
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                          fontSize: 14),
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                            size: 16),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            p.ville.isNotEmpty ? p.ville : 'Location not set',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                                fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.language_rounded,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Public profile',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _previewProfile(p),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.visibility_outlined,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 16),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Preview profile',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _previewProfile(CoachProfileData p) async {
    final token = await ApiService.getToken();
    if (token == null || !mounted) return;
    final session = ReservationModel(
        id: 0,
        clientID: 0,
        coachID: p.id,
        coachName: '${p.firstName} ${p.lastName}',
        coachSpeciality: p.specialties.join(', '),
        coachImageUrl: p.avatarUrl ?? '',
        coachRating: 0,
        sessionStart: DateTime.now(),
        sessionEnd: DateTime.now(),
        location: p.ville,
        status: 'pending',
        price: p.price ?? 0,
        companyName: '');
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CoachDetailScreen(
                session: session, clientID: 0, token: token, preview: true)));
  }

  Future<void> _openCompletionStep(CoachProfileData p, String section) async {
    final token = await ApiService.getToken();
    if (token == null || !mounted) return;
    final Widget page = switch (section) {
      'expertise' => CoachExpertise(profile: p, token: token),
      'locations' => CoachLocations(profile: p, token: token),
      'photos' => CoachPhotos(profile: p, token: token),
      'packages' => CoachPackages(profile: p, token: token),
      'account' =>
        CoachAccount(profile: p, token: token, onLogout: widget.onLogout),
      _ => CoachAboutYou(profile: p, token: token),
    };
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) await _loadAll();
  }

  Widget _buildProfileCompletionUI(CoachProfileData p) {
    final cardColor = context.fitlek.card;
    final accentGreen = context.fitlek.success;

    final progress = CoachProfileCompletion(
        _completionData, _galleryImages.length, _packageCount);
    if (progress.isComplete) return SizedBox.shrink();
    final complete = progress.percent;
    final next = progress.next!;
    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Profile completion',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              Text('$complete%',
                  style: TextStyle(
                      color: accentGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 12),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: complete / 100.0,
              child: Container(
                decoration: BoxDecoration(
                  color: accentGreen,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.workspace_premium_outlined,
                    color: Theme.of(context).colorScheme.onSurface, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                  child: TextButton(
                      onPressed: () => _openCompletionStep(p, next.section),
                      child: Text(next.message,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 13)))),
              Icon(Icons.chevron_right_rounded,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  size: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard1(CoachProfileData p) {
    final cardColor = context.fitlek.card;

    final specialtyText = p.specialties.isNotEmpty
        ? p.specialties.join(', ')
        : (p.specialty.isNotEmpty ? p.specialty : 'Not set');
    final expText = p.experience.isNotEmpty ? p.experience : '';
    final expertiseSubtitle = (specialtyText == 'Not set' && expText.isEmpty)
        ? 'Not set'
        : '$specialtyText${expText.isNotEmpty && specialtyText != 'Not set' ? ' · ' : ''}$expText';

    final aboutSubtitle = (p.bio.isNotEmpty || p.languages.isNotEmpty)
        ? 'Profile details configured'
        : 'Photo, bio and languages';

    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _settingsListTile(
            icon: Icons.person_outline_rounded,
            title: 'About you',
            subtitle: aboutSubtitle,
            onTap: () async {
              final token = await ApiService.getToken();
              if (token != null && mounted) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CoachAboutYou(profile: p, token: token),
                  ),
                );
                if (result == true) {
                  _loadAll();
                }
              }
            },
          ),
          Divider(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              height: 1),
          _settingsListTile(
            icon: Icons.fitness_center_rounded,
            title: 'Expertise & experience',
            subtitle: expertiseSubtitle,
            onTap: () async {
              final token = await ApiService.getToken();
              if (token != null && mounted) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CoachExpertise(profile: p, token: token),
                  ),
                );
                if (result == true) {
                  _loadAll();
                }
              }
            },
          ),
          Divider(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              height: 1),
          _settingsListTile(
            icon: Icons.receipt_long_outlined,
            title: 'Services & packages',
            subtitle: 'Manage your packages',
            onTap: () async {
              final token = await ApiService.getToken();
              if (token != null && mounted) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CoachPackages(profile: p, token: token),
                  ),
                );
                if (result == true) {
                  _loadAll();
                }
              }
            },
          ),
          Divider(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              height: 1),
          _settingsListTile(
            icon: Icons.location_on_outlined,
            title: 'Coaching locations',
            subtitle: p.ville.isNotEmpty ? p.ville : 'Manage locations',
            onTap: () async {
              final token = await ApiService.getToken();
              if (token != null && mounted) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (ctx) =>
                          CoachLocations(profile: p, token: token)),
                );
                if (result == true) _loadAll();
              }
            },
          ),
          Divider(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              height: 1),
          _settingsListTile(
            icon: Icons.photo_outlined,
            title: 'Photos',
            subtitle: '${_galleryImages.length} photos',
            onTap: () async {
              final token = await ApiService.getToken();
              if (token != null && mounted) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (ctx) => CoachPhotos(profile: p, token: token)),
                );
                if (result == true) _loadAll();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard2(CoachProfileData p) {
    final cardColor = context.fitlek.card;
    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _settingsListTile(
            icon: Icons.star_outline_rounded,
            title: 'My feedback',
            subtitle: 'Client ratings and reviews',
            onTap: () async {
              final token = await ApiService.getToken();
              if (token == null || !mounted) return;
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ClientCoachReviewsScreen(
                          coachID: widget.coachID,
                          coachName: '${p.firstName} ${p.lastName}',
                          clientID: 0,
                          token: token,
                          coachView: true)));
            },
          ),
          _settingsListTile(
            icon: Icons.campaign_outlined,
            title: 'Visibility & messaging',
            subtitle: null,
            onTap: () async {
              final token = await ApiService.getToken();
              if (token != null && mounted) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (ctx) =>
                          CoachVisibility(profile: p, token: token)),
                );
                if (result == true) _loadAll();
              }
            },
          ),
          Divider(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              height: 1),
          _settingsListTile(
            icon: Icons.settings_outlined,
            title: 'Account & referrals',
            subtitle: null,
            onTap: () async {
              final token = await ApiService.getToken();
              if (token != null && mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (ctx) => CoachAccount(
                          profile: _profile!,
                          token: token,
                          onLogout: widget.onLogout)),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: InkWell(
        onTap: _showLogoutDialog,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: context.fitlek.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.fitlek.error.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: context.fitlek.error, size: 22),
              SizedBox(width: 12),
              Text(
                'Log out',
                style: TextStyle(
                  color: context.fitlek.error,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsListTile(
      {required IconData icon,
      required String title,
      String? subtitle,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon,
                color: Theme.of(context).colorScheme.onSurface, size: 24),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  if (subtitle != null) ...[
                    SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                            fontSize: 13)),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGallery() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text('Gallery Preview',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8)),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
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
                            child: Image.network(img['urlImage'],
                                fit: BoxFit.contain),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 120,
                    margin: EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                          image: NetworkImage(img['urlImage']),
                          fit: BoxFit.cover),
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
      margin: EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: EdgeInsets.fromLTRB(20, 26, 20, 22),
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
              GestureDetector(
                onTap: _previewAvatar,
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient:
                        LinearGradient(colors: [cs.primary, f.primaryDim]),
                    boxShadow: [
                      BoxShadow(
                          color: cs.primary.withValues(alpha: 0.22),
                          blurRadius: 22,
                          spreadRadius: 1)
                    ],
                  ),
                  padding: EdgeInsets.all(3.5),
                  child: ClipOval(
                    child: Container(
                      color: f.card2,
                      child: (_avatar != null && _avatar!.isNotEmpty)
                          ? Image.network(_avatar!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _initialsAvatar())
                          : _initialsAvatar(),
                    ),
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
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(cs.onPrimary),
                            ),
                          )
                        : Icon(Icons.camera_alt_rounded,
                            size: 16, color: cs.onPrimary),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            _fullName.isNotEmpty ? _fullName : 'Coach',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: cs.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.15),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Coach',
                    style: TextStyle(
                        color: cs.primary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800)),
              ),
              if ((_email ?? '').isNotEmpty) ...[
                SizedBox(width: 10),
                Flexible(
                  child: Text(
                    _email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: f.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _initialsAvatar() => Center(
        child: Text(_initials.isEmpty ? '?' : _initials,
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 30,
                fontWeight: FontWeight.w800)),
      );

  // ── Stats row: Clients / Bookings / Points ─────────────────────────────
  Widget _buildStatsRow(DashboardStats s) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          Expanded(child: _statCard('${s.totalClients}', 'Clients')),
          SizedBox(width: 12),
          Expanded(child: _statCard('${s.totalReservations}', 'Bookings')),
          SizedBox(width: 12),
          Expanded(child: _statCard('${s.invitationPoints}', 'Points')),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: f.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: f.border),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1)),
          SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  color: f.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Professional information ───────────────────────────────────────────
  Widget _buildProfessionalInfo(CoachProfileData p) {
    final f = context.fitlek;
    final specialtyText =
        p.specialties.isNotEmpty ? p.specialties.join(', ') : p.specialty;
    final titleText =
        p.professionalTitle.isNotEmpty ? p.professionalTitle : p.experience;
    final rows = <Widget>[];
    if (titleText.isNotEmpty) {
      rows.add(_infoRow(
          Icons.workspace_premium_rounded, 'Professional Title', titleText));
    }
    if (specialtyText.isNotEmpty) {
      rows.add(
          _infoRow(Icons.fitness_center_rounded, 'Specialties', specialtyText));
    }
    if (p.certifications.isNotEmpty) {
      rows.add(_infoRow(Icons.verified_rounded, 'Certifications',
          p.certifications.join(', ')));
    }
    if (p.bio.isNotEmpty) {
      rows.add(_infoRow(Icons.description_rounded, 'Bio', p.bio));
    }
    if (p.ville.isNotEmpty) {
      rows.add(_infoRow(Icons.location_on_rounded, 'Location', p.ville));
    }

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: EdgeInsets.fromLTRB(18, 18, 18, 6),
      decoration: BoxDecoration(
        color: f.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: f.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PROFESSIONAL INFORMATION',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8)),
          SizedBox(height: 14),
          if (rows.isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 14),
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
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: f.card2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: f.border)),
            child: Icon(icon, size: 19, color: cs.primary),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: f.textMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 3),
                Text(value,
                    style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
