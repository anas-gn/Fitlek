import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/apiService.dart';
import 'coachEditProfile.dart';
import 'login.dart';

import '../../components/theme_selector.dart';
import '../../theme/fitlek_theme_extension.dart';
class ApiConfig {
  static const String baseUrl = 'http://localhost:3000/api';
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
  final String instagramPage;
  final String? certificateUrl;
  final String invitationCode;
  final int totalInvitations;
  final int earnedPoints;
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
    required this.instagramPage,
    this.certificateUrl,
    required this.invitationCode,
    required this.totalInvitations,
    required this.earnedPoints,
    required this.tel,
    required this.ville,
    this.price,
  });

  bool get hasCertificate => certificateUrl != null && certificateUrl!.isNotEmpty;

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
      instagramPage: json['instagramPage'] ?? '',
      certificateUrl: json['certificateUrl'],
      invitationCode: json['invitationCode'] ?? '',
      totalInvitations: int.tryParse(json['totalInvitations'].toString()) ?? 0,
      earnedPoints: int.tryParse(json['earnedPoints'].toString()) ?? 0,
      tel: json['tel']?.toString() ?? '',
      ville: json['ville']?.toString() ?? '',
      price: parsedPrice,
    );
  }
}

class RecentActivityItem {
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final DateTime? createdAt;

  RecentActivityItem({
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    this.createdAt,
  });

  factory RecentActivityItem.fromJson(Map<String, dynamic> json) {
    return RecentActivityItem(
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      avatarUrl: json['avatarUrl'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}

class DashboardStats {
  final int totalReservations;
  final int pendingReservations;
  final int confirmedReservations;
  final int totalClients;
  final int invitationPoints;
  final int totalInvitations;
  final List<RecentActivityItem> recentActivity;

  DashboardStats({
    required this.totalReservations,
    required this.pendingReservations,
    required this.confirmedReservations,
    required this.totalClients,
    required this.invitationPoints,
    required this.totalInvitations,
    required this.recentActivity,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalReservations: int.tryParse(json['totalReservations'].toString()) ?? 0,
      pendingReservations: int.tryParse(json['pendingReservations'].toString()) ?? 0,
      confirmedReservations: int.tryParse(json['confirmedReservations'].toString()) ?? 0,
      totalClients: int.tryParse(json['totalClients'].toString()) ?? 0,
      invitationPoints: int.tryParse(json['invitationPoints'].toString()) ?? 0,
      totalInvitations: int.tryParse(json['totalInvitations'].toString()) ?? 0,
      recentActivity: (json['recentActivity'] as List<dynamic>? ?? [])
          .map((e) => RecentActivityItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory DashboardStats.empty() => DashboardStats(
        totalReservations: 0,
        pendingReservations: 0,
        confirmedReservations: 0,
        totalClients: 0,
        invitationPoints: 0,
        totalInvitations: 0,
        recentActivity: [],
      );
}

class CoachClientItem {
  final int id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? avatarUrl;
  final bool isPremium;

  CoachClientItem({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.avatarUrl,
    required this.isPremium,
  });

  factory CoachClientItem.fromJson(Map<String, dynamic> json) {
    return CoachClientItem(
      id: int.tryParse(json['id'].toString()) ?? 0,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'],
      avatarUrl: json['avatarUrl'],
      isPremium: json['isPremium'] == 1 || json['isPremium'] == true,
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double radius;
  final Color? borderColor;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = const EdgeInsets.fromLTRB(16, 16, 16, 0),
    this.radius = 24,
    this.borderColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: gradient == null ? context.fitlek.card.withValues(alpha: 0.75) : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: borderColor ?? context.fitlek.border),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class RingProgress extends StatelessWidget {
  final double percentage;
  final Color color;
  final String label;
  final String sublabel;
  final String centerText;
  final double size;

  const RingProgress({
    super.key,
    required this.percentage,
    required this.color,
    required this.label,
    required this.sublabel,
    required this.centerText,
    this.size = 78,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percentage.clamp(0, 1)),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return CustomPaint(
                painter: _RingPainter(progress: value, color: color, bg: context.fitlek.border),
                child: Center(
                  child: Text(centerText,
                      style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(sublabel, style: TextStyle(color: context.fitlek.textMuted, fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bg;
  _RingPainter({required this.progress, required this.color, required this.bg});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;
    final bgPaint = Paint()
      ..color = bg
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);
    final fgPaint = Paint()
      ..shader = SweepGradient(colors: [color.withValues(alpha: 0.4), color]).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -1.5708, 6.2832 * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  DashedRectPainter({required this.color, this.radius = 20});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    const dashWidth = 8.0;
    const dashSpace = 6.0;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
  List<CoachClientItem> _clients = [];
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
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
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
        http.get(Uri.parse('${ApiConfig.baseUrl}/coach/clients'), headers: _authHeaders),
      ]);

      if (!mounted) return;

      final profileRes = results[0];
      final dashRes = results[1];
      final clientsRes = results[2];

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

      List<CoachClientItem> clients = [];
      if (clientsRes.statusCode == 200) {
        final list = jsonDecode(clientsRes.body) as List<dynamic>;
        clients = list.map((e) => CoachClientItem.fromJson(e as Map<String, dynamic>)).toList();
      }

      setState(() {
        _profile = profileData;
        _stats = stats;
        _clients = clients;
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

  int _monthlyGoal(int points) {
    if (points < 1000) return 1000;
    if (points < 2500) return 2500;
    if (points < 5000) return 5000;
    if (points < 10000) return 10000;
    return ((points ~/ 5000) + 1) * 5000;
  }

  Future<void> _openUrl(String rawUrl) async {
    var url = rawUrl.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) url = 'https://$url';
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showSnack('Invalid link', isError: true);
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) _showSnack('Unable to open link', isError: true);
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    final ok = await launchUrl(uri);
    if (!ok && mounted) _showSnack('Unable to start the call', isError: true);
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    final ok = await launchUrl(uri);
    if (!ok && mounted) _showSnack('Unable to open email', isError: true);
  }

  void _copyToClipboard(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    _showSnack('$label copied to clipboard');
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(color: isError ? Theme.of(context).colorScheme.onError : Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
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
    if (widget.onLogout != null) {
      widget.onLogout!();
      return;
    }
    await ApiService.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => FadeTransition(opacity: animation, child: const LoginScreen()),
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
      if (mounted) _showSnack('Profile photo updated ✓');
    } catch (e) {
      if (mounted) _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Widget _staggered(int index, Widget child) {
    final start = (index * 0.07).clamp(0.0, 0.6);
    final end = (start + 0.4).clamp(0.0, 1.0);
    final anim = CurvedAnimation(parent: _animCtrl, curve: Interval(start, end, curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(anim),
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

    final monthlyGoal = _monthlyGoal(s.invitationPoints);
    final goalProgress = monthlyGoal == 0 ? 0.0 : (s.invitationPoints / monthlyGoal).clamp(0.0, 1.0);
    final confirmRate = s.totalReservations == 0 ? 0.0 : (s.confirmedReservations / s.totalReservations).clamp(0.0, 1.0);

    final contactEntries = <Map<String, dynamic>>[];
    if (p.tel.isNotEmpty) {
      contactEntries.add({'icon': Icons.call_rounded, 'label': 'Call', 'color': context.fitlek.success, 'action': () => _callPhone(p.tel)});
    }
    final email = _email;
    if (email != null && email.isNotEmpty) {
      contactEntries.add({'icon': Icons.mail_rounded, 'label': 'Email', 'color': context.fitlek.info, 'action': () => _sendEmail(email)});
    }
    if (p.instagramPage.isNotEmpty) {
      contactEntries.add({
        'icon': Icons.camera_alt_rounded,
        'label': 'Instagram',
        'color': context.fitlek.instagram,
        'action': () => _openUrl(p.instagramPage.startsWith('http') ? p.instagramPage : 'https://instagram.com/${p.instagramPage}'),
      });
    }
    if (p.tel.isNotEmpty) {
      contactEntries.add({'icon': Icons.copy_rounded, 'label': 'Copy number', 'color': context.fitlek.violet, 'action': () => _copyToClipboard(p.tel, 'Number')});
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(child: _staggered(0, _buildHeader(p, s))),
        SliverToBoxAdapter(child: _staggered(1, _buildKpiGrid(p, s))),
        SliverToBoxAdapter(child: _staggered(2, _buildReservationsCard(s, confirmRate))),
        SliverToBoxAdapter(child: _staggered(3, _buildProgressSection(goalProgress, confirmRate))),
        if (_clients.isNotEmpty) SliverToBoxAdapter(child: _staggered(4, _buildClientsRow())),
        if (s.recentActivity.isNotEmpty) SliverToBoxAdapter(child: _staggered(5, _buildRecentActivity(s))),
        if (contactEntries.isNotEmpty) SliverToBoxAdapter(child: _staggered(6, _buildContactRow(contactEntries))),
        if (p.bio.isNotEmpty) SliverToBoxAdapter(child: _staggered(7, _buildBioCard(p))),
        if (p.ville.isNotEmpty) SliverToBoxAdapter(child: _staggered(8, _buildLocationCard(p))),
        if (p.hasCertificate) SliverToBoxAdapter(child: _staggered(9, _buildCertificateCard(p))),
        SliverToBoxAdapter(child: _staggered(10, _buildInvitationTicket(p))),
        SliverToBoxAdapter(child: _staggered(11, _buildEditButton())),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(child: _staggered(12, ThemeSelectorTile(controller: ThemeControllerScope.of(context)))),
        ),
        if (p.advisorID != null) SliverToBoxAdapter(child: _staggered(13, _buildAdvisorBanner(p))),
        SliverToBoxAdapter(child: _staggered(14, _buildLogoutButton())),
        const SliverToBoxAdapter(child: SizedBox(height: 36)),
      ],
    );
  }

  Widget _buildHeader(CoachProfileData p, DashboardStats s) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.04),
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.16)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -70,
            right: -55,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.07)),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle, color: context.fitlek.violet.withValues(alpha: 0.06)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text('MY PROFILE',
                        style: TextStyle(color: context.fitlek.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _openEditProfile,
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Icon(Icons.edit_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _showLogoutDialog,
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: context.fitlek.card2,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.fitlek.border),
                      ),
                      child: Icon(Icons.logout_rounded, size: 17, color: context.fitlek.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, context.fitlek.primaryDim]),
                          boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25), blurRadius: 26, spreadRadius: 2)],
                        ),
                        padding: const EdgeInsets.all(3),
                        child: ClipOval(
                          child: Container(
                            color: context.fitlek.card,
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
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2.5),
                            ),
                            child: _uploadingAvatar
                                ? Padding(
                                    padding: const EdgeInsets.all(7),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                                    ),
                                  )
                                : Icon(Icons.camera_alt_rounded, size: 15, color: Theme.of(context).colorScheme.onPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_fullName,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.w800, height: 1.1),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.verified_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 5),
                                Text('Coach SIRVYA', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                              ]),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('${s.totalClients} clients',
                                  style: TextStyle(color: context.fitlek.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _initialsAvatar() => Center(
        child: Text(_initials.isEmpty ? '?' : _initials,
            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 28, fontWeight: FontWeight.w800)),
      );

  Widget _buildKpiGrid(CoachProfileData p, DashboardStats s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _bentoTile(
              icon: Icons.emoji_events_rounded,
              value: '${s.invitationPoints}',
              label: 'Points earned',
              color: Theme.of(context).colorScheme.primary,
              big: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _bentoTile(
              icon: Icons.group_add_rounded,
              value: '${s.totalInvitations}',
              label: 'Invitations',
              color: context.fitlek.info,
              big: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bentoTile({required IconData icon, required String value, required String label, required Color color, required bool big}) {
    return Container(
      height: big ? 176 : 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.fitlek.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.fitlek.border),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Opacity(
              opacity: 0.05,
              child: Icon(icon, color: color, size: big ? 100 : 60),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: big ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
            children: [
              if (big)
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(11)),
                  child: Icon(icon, color: color, size: 19),
                ),
              if (!big)
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(9)),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(value,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w900),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              if (big) ...[
                Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 34, fontWeight: FontWeight.w900, height: 1)),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(color: context.fitlek.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
              ] else
                Padding(
                  padding: const EdgeInsets.only(left: 40, top: 2),
                  child: Text(label, style: TextStyle(color: context.fitlek.textMuted, fontSize: 10, fontWeight: FontWeight.w500)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReservationsCard(DashboardStats s, double confirmRate) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_available_rounded, size: 18, color: context.fitlek.warning),
              const SizedBox(width: 8),
              Text('Reservations', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14.5, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statBlock('${s.totalReservations}', 'Total', Theme.of(context).colorScheme.onSurface),
              _statDivider(),
              _statBlock('${s.confirmedReservations}', 'Confirmed', context.fitlek.success),
              _statDivider(),
              _statBlock('${s.pendingReservations}', 'Pending', context.fitlek.warning),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: confirmRate),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: context.fitlek.border,
                  valueColor: AlwaysStoppedAnimation<Color>(context.fitlek.success),
                  minHeight: 8,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text('${(confirmRate * 100).toStringAsFixed(0)}% confirmation rate',
              style: TextStyle(color: context.fitlek.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _statBlock(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: context.fitlek.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(width: 1, height: 34, color: context.fitlek.border);

  Widget _buildProgressSection(double goalProgress, double confirmRate) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: context.fitlek.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: context.fitlek.border)),
              child: RingProgress(
                percentage: goalProgress,
                color: Theme.of(context).colorScheme.primary,
                label: 'Goal',
                sublabel: 'Monthly points',
                centerText: '${(goalProgress * 100).toInt()}%',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: context.fitlek.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: context.fitlek.border)),
              child: RingProgress(
                percentage: confirmRate,
                color: context.fitlek.violet,
                label: 'Confirmations',
                sublabel: 'Validated sessions',
                centerText: '${(confirmRate * 100).toInt()}%',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientsRow() {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_rounded, size: 18, color: context.fitlek.info),
              const SizedBox(width: 8),
              Text('My clients', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14.5, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('${_clients.length}', style: TextStyle(color: context.fitlek.textMuted, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _clients.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final c = _clients[index];
                final initials = ((c.firstName.isNotEmpty ? c.firstName[0] : '') + (c.lastName.isNotEmpty ? c.lastName[0] : '')).toUpperCase();
                return Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.fitlek.card2,
                            border: Border.all(color: context.fitlek.border),
                          ),
                          child: ClipOval(
                            child: c.avatarUrl != null && c.avatarUrl!.isNotEmpty
                                ? Image.network(c.avatarUrl!, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Center(child: Text(initials, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w800))))
                                : Center(child: Text(initials, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w800))),
                          ),
                        ),
                        if (c.isPremium)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle, border: Border.all(color: context.fitlek.card, width: 2)),
                              child: Icon(Icons.star_rounded, size: 10, color: Theme.of(context).colorScheme.onPrimary),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 56,
                      child: Text(c.firstName, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: context.fitlek.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(DashboardStats s) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text('Recent activity', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14.5, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          ...s.recentActivity.map((a) {
            final initials = ((a.firstName.isNotEmpty ? a.firstName[0] : '') + (a.lastName.isNotEmpty ? a.lastName[0] : '')).toUpperCase();
            final dateLabel = a.createdAt != null ? '${a.createdAt!.day}/${a.createdAt!.month}/${a.createdAt!.year}' : '';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: context.fitlek.card2, border: Border.all(color: context.fitlek.border)),
                    child: ClipOval(
                      child: a.avatarUrl != null && a.avatarUrl!.isNotEmpty
                          ? Image.network(a.avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Text(initials, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w800))))
                          : Center(child: Text(initials, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w800))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('${a.firstName} ${a.lastName}'.trim(),
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Text(dateLabel, style: TextStyle(color: context.fitlek.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildContactRow(List<Map<String, dynamic>> entries) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(color: context.fitlek.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: context.fitlek.border)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: entries.map((e) {
            return GestureDetector(
              onTap: e['action'] as VoidCallback,
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: (e['color'] as Color).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: (e['color'] as Color).withValues(alpha: 0.25)),
                    ),
                    child: Icon(e['icon'] as IconData, color: e['color'] as Color, size: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(e['label'] as String, style: TextStyle(color: context.fitlek.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBioCard(CoachProfileData p) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chat_bubble_rounded, size: 18, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)),
              const SizedBox(width: 8),
              Text('About', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14.5, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          Text(p.bio, style: TextStyle(color: context.fitlek.textSecondary, fontSize: 13.5, height: 1.75)),
        ],
      ),
    );
  }

  Widget _buildCertificateCard(CoachProfileData p) {
    final url = p.certificateUrl!;
    final isImage = url.toLowerCase().endsWith('.jpg') || url.toLowerCase().endsWith('.jpeg') || url.toLowerCase().endsWith('.png') || url.toLowerCase().endsWith('.webp');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: context.fitlek.border), borderRadius: BorderRadius.circular(22)),
          child: Stack(
            children: [
              if (isImage)
                Image.network(url, height: 190, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _certificateFallback())
              else
                _certificateFallback(),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 14),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xE6000000)]),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.workspace_premium_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Verified certificate', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
                      ),
                      GestureDetector(
                        onTap: () => _openUrl(url),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(20)),
                          child: Text('VIEW', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _certificateFallback() {
    return Container(
      height: 190,
      width: double.infinity,
      color: context.fitlek.card2,
      child: Center(child: Icon(Icons.description_rounded, size: 40, color: context.fitlek.textMuted.withValues(alpha: 0.4))),
    );
  }

  Widget _buildInvitationTicket(CoachProfileData p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GestureDetector(
        onTap: () => _copyToClipboard(p.invitationCode, 'Code'),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), Theme.of(context).scaffoldBackgroundColor]),
          ),
          child: CustomPaint(
            painter: DashedRectPainter(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35), radius: 22),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.confirmation_number_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(width: 10),
                      Text('Invitation code', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Icon(Icons.copy_rounded, size: 18, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    p.invitationCode.isNotEmpty ? p.invitationCode : '—',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 4, fontFamily: 'Courier'),
                  ),
                  const SizedBox(height: 10),
                  Text('Share this code to invite new clients and earn points',
                      style: TextStyle(color: context.fitlek.textMuted.withValues(alpha: 0.85), fontSize: 11.5, height: 1.5)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdvisorBanner(CoachProfileData p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: context.fitlek.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: context.fitlek.border)),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: context.fitlek.violet.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
              child: Icon(Icons.support_agent_rounded, size: 18, color: context.fitlek.violet),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Linked advisor', style: TextStyle(color: context.fitlek.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('#${p.advisorID}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(CoachProfileData p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: context.fitlek.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: context.fitlek.border)),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: context.fitlek.info.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
              child: Icon(Icons.location_on_rounded, size: 18, color: context.fitlek.info),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Location', style: TextStyle(color: context.fitlek.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(p.ville,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w700),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GestureDetector(
        onTap: _openEditProfile,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 6))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit_rounded, size: 18, color: Theme.of(context).colorScheme.onPrimary),
              const SizedBox(width: 10),
              Text('Edit my profile',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: GestureDetector(
        onTap: _showLogoutDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: context.fitlek.error.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.fitlek.error.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, size: 18, color: context.fitlek.error),
              const SizedBox(width: 10),
              Text('Log out', style: TextStyle(color: context.fitlek.error, fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}