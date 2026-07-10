import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../services/apiService.dart';
import 'login.dart';

class ApiConfig {
  static const String baseUrl = 'http://localhost:3000/api';
}

class FitlekColors {
  static const Color bg = Color(0xFF060607);
  static const Color card = Color(0xFF121214);
  static const Color card2 = Color(0xFF17181B);
  static const Color border = Color(0xFF232427);
  static const Color lime = Color(0xFFC6F135);
  static const Color limeDim = Color(0xFF8FBE1D);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFA3A7AE);
  static const Color textMuted = Color(0xFF6C7076);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF6A623);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF4E9BFF);
  static const Color violet = Color(0xFFA277FF);
  static const Color instagram = Color(0xFFE1306C);
}

class CoachProfileData {
  final int id;
  final int userID;
  final int? advisorID;
  final String bio;
  final String instagramPage;
  final String? certificateUrl;
  final String invitationCode;
  final int totalInvitations;
  final int earnedPoints;
  final String tel;
  final double? price;

  CoachProfileData({
    required this.id,
    required this.userID,
    this.advisorID,
    required this.bio,
    required this.instagramPage,
    this.certificateUrl,
    required this.invitationCode,
    required this.totalInvitations,
    required this.earnedPoints,
    required this.tel,
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
      userID: int.tryParse(json['userID'].toString()) ?? 0,
      advisorID: json['advisorID'] != null ? int.tryParse(json['advisorID'].toString()) : null,
      bio: json['bio'] ?? '',
      instagramPage: json['instagramPage'] ?? '',
      certificateUrl: json['certificateUrl'],
      invitationCode: json['invitationCode'] ?? '',
      totalInvitations: int.tryParse(json['totalInvitations'].toString()) ?? 0,
      earnedPoints: int.tryParse(json['earnedPoints'].toString()) ?? 0,
      tel: json['tel']?.toString() ?? '',
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
              color: gradient == null ? FitlekColors.card.withOpacity(0.75) : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: borderColor ?? FitlekColors.border),
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
                painter: _RingPainter(progress: value, color: color, bg: Colors.white.withOpacity(0.06)),
                child: Center(
                  child: Text(centerText,
                      style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(sublabel, style: const TextStyle(color: FitlekColors.textMuted, fontSize: 10, fontWeight: FontWeight.w500)),
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
      ..shader = SweepGradient(colors: [color.withOpacity(0.4), color]).createShader(Rect.fromCircle(center: center, radius: radius))
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

  const CoachProfile({
    super.key,
    required this.coachID,
    required this.firstName,
    required this.lastName,
    required this.token,
    this.avatarUrl,
    this.email,
    this.onLogout,
  });

  @override
  State<CoachProfile> createState() => _CoachProfileState();
}

class _CoachProfileState extends State<CoachProfile> with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _hasError = false;
  CoachProfileData? _profile;
  DashboardStats _stats = DashboardStats.empty();
  List<CoachClientItem> _clients = [];
  late AnimationController _animCtrl;

  String get _fullName => '${widget.firstName} ${widget.lastName}'.trim();
  String get _initials {
    final f = widget.firstName.isNotEmpty ? widget.firstName[0] : '';
    final l = widget.lastName.isNotEmpty ? widget.lastName[0] : '';
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
        http.get(Uri.parse('${ApiConfig.baseUrl}/coaches/me/profile?userID=${widget.coachID}'), headers: _authHeaders),
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
      _showSnack('Lien invalide', isError: true);
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) _showSnack("Impossible d'ouvrir le lien", isError: true);
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    final ok = await launchUrl(uri);
    if (!ok && mounted) _showSnack("Impossible de lancer l'appel", isError: true);
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    final ok = await launchUrl(uri);
    if (!ok && mounted) _showSnack("Impossible d'ouvrir l'email", isError: true);
  }

  void _copyToClipboard(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    _showSnack('$label copié dans le presse-papiers');
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13)),
        backgroundColor: isError ? FitlekColors.error : FitlekColors.lime,
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
        backgroundColor: FitlekColors.card,
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
                  color: FitlekColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: FitlekColors.error.withOpacity(0.2)),
                ),
                child: const Icon(Icons.logout_rounded, color: FitlekColors.error, size: 26),
              ),
              const SizedBox(height: 20),
              const Text('Déconnexion', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Voulez-vous vraiment vous déconnecter ?',
                  textAlign: TextAlign.center, style: TextStyle(color: FitlekColors.textMuted, fontSize: 13.5, height: 1.5)),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: FitlekColors.bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: FitlekColors.border),
                        ),
                        child: const Center(
                          child: Text('Annuler', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
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
                        decoration: BoxDecoration(color: FitlekColors.error, borderRadius: BorderRadius.circular(14)),
                        child: const Center(
                          child: Text('Se déconnecter',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
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
      backgroundColor: FitlekColors.bg,
      body: SafeArea(
        top: false,
        child: _loading
            ? _buildLoading()
            : _hasError
                ? _buildError()
                : RefreshIndicator(
                    color: FitlekColors.lime,
                    backgroundColor: FitlekColors.card,
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
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(color: FitlekColors.lime, strokeWidth: 2.4),
          ),
          const SizedBox(height: 16),
          const Text('Chargement du profil...',
              style: TextStyle(color: FitlekColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
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
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), shape: BoxShape.circle),
              child: const Icon(Icons.wifi_off_rounded, color: Colors.white12, size: 34),
            ),
            const SizedBox(height: 16),
            const Text('Impossible de charger le profil',
                style: TextStyle(color: FitlekColors.textMuted, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _loadAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: BoxDecoration(color: FitlekColors.lime, borderRadius: BorderRadius.circular(14)),
                child: const Text('Réessayer', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 13)),
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
      contactEntries.add({'icon': Icons.call_rounded, 'label': 'Appeler', 'color': FitlekColors.success, 'action': () => _callPhone(p.tel)});
    }
    if (widget.email != null && widget.email!.isNotEmpty) {
      contactEntries.add({'icon': Icons.mail_rounded, 'label': 'Email', 'color': FitlekColors.info, 'action': () => _sendEmail(widget.email!)});
    }
    if (p.instagramPage.isNotEmpty) {
      contactEntries.add({
        'icon': Icons.camera_alt_rounded,
        'label': 'Instagram',
        'color': FitlekColors.instagram,
        'action': () => _openUrl(p.instagramPage.startsWith('http') ? p.instagramPage : 'https://instagram.com/${p.instagramPage}'),
      });
    }
    if (p.tel.isNotEmpty) {
      contactEntries.add({'icon': Icons.copy_rounded, 'label': 'Copier n°', 'color': FitlekColors.violet, 'action': () => _copyToClipboard(p.tel, 'Numéro')});
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
        if (p.hasCertificate) SliverToBoxAdapter(child: _staggered(8, _buildCertificateCard(p))),
        SliverToBoxAdapter(child: _staggered(9, _buildInvitationTicket(p))),
        if (p.advisorID != null) SliverToBoxAdapter(child: _staggered(10, _buildAdvisorBanner(p))),
        SliverToBoxAdapter(child: _staggered(11, _buildLogoutButton())),
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B2408), Color(0xFF10130A), FitlekColors.bg],
        ),
        border: Border.all(color: FitlekColors.lime.withOpacity(0.16)),
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
              decoration: BoxDecoration(shape: BoxShape.circle, color: FitlekColors.lime.withOpacity(0.07)),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle, color: FitlekColors.violet.withOpacity(0.06)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(20)),
                    child: const Text('MON PROFIL',
                        style: TextStyle(color: FitlekColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showLogoutDialog,
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: const Icon(Icons.logout_rounded, size: 17, color: Colors.white70),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [FitlekColors.lime, FitlekColors.limeDim]),
                      boxShadow: [BoxShadow(color: FitlekColors.lime.withOpacity(0.25), blurRadius: 26, spreadRadius: 2)],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: ClipOval(
                      child: Container(
                        color: FitlekColors.card,
                        child: widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
                            ? Image.network(widget.avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _initialsAvatar())
                            : _initialsAvatar(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_fullName,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.1),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: FitlekColors.lime.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: FitlekColors.lime.withOpacity(0.3)),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.verified_rounded, size: 14, color: FitlekColors.lime),
                                const SizedBox(width: 5),
                                const Text('Coach Fitlek', style: TextStyle(color: FitlekColors.lime, fontSize: 11, fontWeight: FontWeight.w700)),
                              ]),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('${s.totalClients} clients',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
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
            style: const TextStyle(color: FitlekColors.lime, fontSize: 28, fontWeight: FontWeight.w800)),
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
              label: 'Points gagnés',
              color: FitlekColors.lime,
              big: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _bentoTile(
                  icon: Icons.group_add_rounded,
                  value: '${s.totalInvitations}',
                  label: 'Invitations',
                  color: FitlekColors.info,
                  big: false,
                ),
                const SizedBox(height: 12),
                _bentoTile(
                  icon: Icons.payments_rounded,
                  value: p.price != null ? '${p.price!.toStringAsFixed(0)} MAD' : '—',
                  label: 'Par séance',
                  color: FitlekColors.success,
                  big: false,
                ),
              ],
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
        color: FitlekColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FitlekColors.border),
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
                  decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(11)),
                  child: Icon(icon, color: color, size: 19),
                ),
              if (!big)
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(9)),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(value,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              if (big) ...[
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, height: 1)),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(color: FitlekColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
              ] else
                Padding(
                  padding: const EdgeInsets.only(left: 40, top: 2),
                  child: Text(label, style: const TextStyle(color: FitlekColors.textMuted, fontSize: 10, fontWeight: FontWeight.w500)),
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
            children: const [
              Icon(Icons.event_available_rounded, size: 18, color: FitlekColors.warning),
              SizedBox(width: 8),
              Text('Réservations', style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statBlock('${s.totalReservations}', 'Total', Colors.white),
              _statDivider(),
              _statBlock('${s.confirmedReservations}', 'Confirmées', FitlekColors.success),
              _statDivider(),
              _statBlock('${s.pendingReservations}', 'En attente', FitlekColors.warning),
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
                  backgroundColor: Colors.white.withOpacity(0.06),
                  valueColor: const AlwaysStoppedAnimation<Color>(FitlekColors.success),
                  minHeight: 8,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text('${(confirmRate * 100).toStringAsFixed(0)}% de confirmation',
              style: const TextStyle(color: FitlekColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
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
          Text(label, style: const TextStyle(color: FitlekColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(width: 1, height: 34, color: FitlekColors.border);

  Widget _buildProgressSection(double goalProgress, double confirmRate) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: FitlekColors.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: FitlekColors.border)),
              child: RingProgress(
                percentage: goalProgress,
                color: FitlekColors.lime,
                label: 'Objectif',
                sublabel: 'Points mensuel',
                centerText: '${(goalProgress * 100).toInt()}%',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: FitlekColors.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: FitlekColors.border)),
              child: RingProgress(
                percentage: confirmRate,
                color: FitlekColors.violet,
                label: 'Confirmations',
                sublabel: 'Séances validées',
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
              const Icon(Icons.groups_rounded, size: 18, color: FitlekColors.info),
              const SizedBox(width: 8),
              const Text('Mes clients', style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('${_clients.length}', style: const TextStyle(color: FitlekColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700)),
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
                            color: FitlekColors.card2,
                            border: Border.all(color: FitlekColors.border),
                          ),
                          child: ClipOval(
                            child: c.avatarUrl != null && c.avatarUrl!.isNotEmpty
                                ? Image.network(c.avatarUrl!, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Center(child: Text(initials, style: const TextStyle(color: FitlekColors.lime, fontSize: 13, fontWeight: FontWeight.w800))))
                                : Center(child: Text(initials, style: const TextStyle(color: FitlekColors.lime, fontSize: 13, fontWeight: FontWeight.w800))),
                          ),
                        ),
                        if (c.isPremium)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(color: FitlekColors.lime, shape: BoxShape.circle, border: Border.all(color: FitlekColors.card, width: 2)),
                              child: const Icon(Icons.star_rounded, size: 10, color: Colors.black),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 56,
                      child: Text(c.firstName, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: FitlekColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
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
            children: const [
              Icon(Icons.history_rounded, size: 18, color: FitlekColors.lime),
              SizedBox(width: 8),
              Text('Activité récente', style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800)),
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
                    decoration: BoxDecoration(shape: BoxShape.circle, color: FitlekColors.card2, border: Border.all(color: FitlekColors.border)),
                    child: ClipOval(
                      child: a.avatarUrl != null && a.avatarUrl!.isNotEmpty
                          ? Image.network(a.avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Text(initials, style: const TextStyle(color: FitlekColors.lime, fontSize: 11, fontWeight: FontWeight.w800))))
                          : Center(child: Text(initials, style: const TextStyle(color: FitlekColors.lime, fontSize: 11, fontWeight: FontWeight.w800))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('${a.firstName} ${a.lastName}'.trim(),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Text(dateLabel, style: const TextStyle(color: FitlekColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
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
        decoration: BoxDecoration(color: FitlekColors.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: FitlekColors.border)),
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
                      color: (e['color'] as Color).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: (e['color'] as Color).withOpacity(0.25)),
                    ),
                    child: Icon(e['icon'] as IconData, color: e['color'] as Color, size: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(e['label'] as String, style: const TextStyle(color: FitlekColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600)),
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
              Icon(Icons.chat_bubble_rounded, size: 18, color: FitlekColors.lime.withOpacity(0.7)),
              const SizedBox(width: 8),
              const Text('À propos', style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          Text(p.bio, style: const TextStyle(color: FitlekColors.textSecondary, fontSize: 13.5, height: 1.75)),
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
          decoration: BoxDecoration(border: Border.all(color: FitlekColors.border), borderRadius: BorderRadius.circular(22)),
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
                      const Icon(Icons.workspace_premium_rounded, size: 18, color: FitlekColors.lime),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Certificat vérifié', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
                      ),
                      GestureDetector(
                        onTap: () => _openUrl(url),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(color: FitlekColors.lime, borderRadius: BorderRadius.circular(20)),
                          child: const Text('VOIR', style: TextStyle(color: Colors.black, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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
      color: FitlekColors.card2,
      child: Center(child: Icon(Icons.description_rounded, size: 40, color: FitlekColors.textMuted.withOpacity(0.4))),
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
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [FitlekColors.lime.withOpacity(0.1), FitlekColors.bg]),
          ),
          child: CustomPaint(
            painter: DashedRectPainter(color: FitlekColors.lime.withOpacity(0.35), radius: 22),
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
                        decoration: BoxDecoration(color: FitlekColors.lime.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.confirmation_number_rounded, size: 18, color: FitlekColors.lime),
                      ),
                      const SizedBox(width: 10),
                      const Text("Code d'invitation", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Icon(Icons.copy_rounded, size: 18, color: FitlekColors.lime.withOpacity(0.8)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    p.invitationCode.isNotEmpty ? p.invitationCode : '—',
                    style: const TextStyle(color: FitlekColors.lime, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 4, fontFamily: 'Courier'),
                  ),
                  const SizedBox(height: 10),
                  Text('Partagez ce code pour inviter de nouveaux clients et gagner des points',
                      style: TextStyle(color: FitlekColors.textMuted.withOpacity(0.85), fontSize: 11.5, height: 1.5)),
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
        decoration: BoxDecoration(color: FitlekColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: FitlekColors.border)),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: FitlekColors.violet.withOpacity(0.12), borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.support_agent_rounded, size: 18, color: FitlekColors.violet),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Conseiller lié', style: TextStyle(color: FitlekColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('#${p.advisorID}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
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
            color: FitlekColors.error.withOpacity(0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: FitlekColors.error.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.logout_rounded, size: 18, color: FitlekColors.error),
              SizedBox(width: 10),
              Text('Se déconnecter', style: TextStyle(color: FitlekColors.error, fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}