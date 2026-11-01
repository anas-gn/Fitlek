import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../components/sirvya_logo.dart';
import '../../constants/app_colors.dart';
import '../../mainLayoutCoach.dart';
import '../../services/apiService.dart';
import '../../services/media_picker_service.dart';
import '../../services/referral_link_service.dart';
import 'clientQrScanner.dart';
import 'login.dart';

const _red = Color(0xFFFF5252);
const _bgImage = 'assets/branding/sirvya1.jfif';

/// Étape obligatoire après l'inscription d'un coach.
/// Reste affichée à chaque ouverture de l'app jusqu'à l'approbation
/// (QR valide ou certificat approuvé par le manager).
class CoachOnboarding extends StatefulWidget {
  const CoachOnboarding({super.key});

  @override
  State<CoachOnboarding> createState() => _CoachOnboardingState();
}

enum _StepState { done, active, todo }

class _CoachOnboardingState extends State<CoachOnboarding>
    with TickerProviderStateMixin {
  bool _busy = false;
  bool _pending = false;
  bool _checking = true; // vérification initiale en cours
  bool _offline = false; // impossible de vérifier (réseau)
  String? _error;
  Timer? _poll;

  late final AnimationController _enter;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450))
      ..forward();
    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enter, curve: Curves.easeOut));
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _bootstrap();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _enter.dispose();
    _pulse.dispose();
    super.dispose();
  }

  // ───────────────────────── LOGIQUE ─────────────────────────

  bool _isApproved(Map r) =>
      r['isApproved'] == true || '${r['isApproved']}' == '1';

  Future<String> _key() async {
    final prefs = await SharedPreferences.getInstance();
    return 'coach_onboarding_${prefs.getInt('userId')}';
  }

  Future<void> _markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(await _key(), true);
  }

  void _enterApp() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainLayoutCoach(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
        (_) => false);
  }

  /// Décide à chaque ouverture : entrer, attendre ou choisir.
  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final base = await _key();

    // 1. QR déjà validé sur cet appareil → entrée directe
    if (prefs.getBool(base) == true) {
      _enterApp();
      return;
    }

    // 2. Vérité serveur : le manager a-t-il approuvé ce coach ?
    final r = await ApiService.get('/coaches/me/profile');
    if (!mounted) return;
    if (r['ok'] != true) {
      // On ne laisse JAMAIS entrer si on ne peut pas vérifier
      setState(() {
        _checking = false;
        _offline = true;
      });
      return;
    }
    if (_isApproved(r)) {
      await prefs.remove('${base}_pending');
      await _markDone();
      _enterApp();
      return;
    }

    // 3. Pas approuvé : on reste sur la page (choix ou attente)
    final wasPending = prefs.getBool('${base}_pending') == true;
    setState(() {
      _checking = false;
      _offline = false;
    });
    if (wasPending) _startWaiting();
  }

  void _retry() {
    setState(() {
      _checking = true;
      _offline = false;
    });
    _bootstrap();
  }

  // ── Option 1 : QR code d'un coach invitant → entrée directe ──
  Future<void> _scanQr() async {
    if (_busy) return;
    final scanned = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const ClientQrScannerScreen()));
    if (scanned == null || !mounted) return;
    final code = ReferralLinkService.codeFromQr(scanned);
    if (code == null) {
      setState(() => _error = 'This QR code is not a valid coach invitation.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await ApiService.get(
        '/auth/validate-referral?code=${Uri.encodeQueryComponent(code)}');
    if (!mounted) return;
    if (r['ok'] == true && r['valid'] == true) {
      await _markDone();
      _enterApp();
    } else {
      setState(() {
        _busy = false;
        _error = 'This invitation code is not recognized.';
      });
    }
  }

  // ── Option 2 : photo du certificat → attente d'approbation ──
  Future<void> _takePhoto() async {
    if (_busy) return;
    final file = await AppMediaPicker(context)
        .pickImage(source: ImageSource.camera, imageQuality: 85);
    if (file == null || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await ApiService.uploadMultipart(
      '/upload/certification',
      fields: const {},
      fileBytes: await file.readAsBytes(),
      fileField: 'certificate',
      fileName: file.name,
      mimeType: 'image/jpeg',
    );
    if (!mounted) return;
    if (r['ok'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${await _key()}_pending', true);
      setState(() {
        _busy = false;
        _error = null;
      });
      _startWaiting();
    } else {
      setState(() {
        _busy = false;
        _error = r['message']?.toString() ?? 'Upload failed.';
      });
    }
  }

  void _startWaiting() {
    setState(() => _pending = true);
    _enter
      ..reset()
      ..forward();
    _checkApproved();
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) => _checkApproved());
  }

  Future<void> _checkApproved() async {
    final r = await ApiService.get('/coaches/me/profile');
    if (!mounted || r['ok'] != true) return;
    if (_isApproved(r)) {
      _poll?.cancel();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${await _key()}_pending');
      await _markDone();
      _enterApp();
    }
  }

  Future<void> _logout() async {
    await ApiService.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // étape obligatoire : pas de retour possible
      child: Theme(
        data: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(children: [
            Positioned.fill(
              child: Image.asset(
                _bgImage,
                fit: BoxFit.cover,
                frameBuilder: (_, child, frame, __) => frame == null
                    ? Container(color: const Color(0xFF111111))
                    : child,
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFF111111)),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
                child: Container(color: Colors.black.withValues(alpha: 0.25)),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.cyprus.withValues(alpha: 0.05),
                      AppColors.cyprus.withValues(alpha: 0.55),
                      AppColors.cyprus.withValues(alpha: 0.92),
                      AppColors.cyprus,
                    ],
                    stops: const [0.0, 0.28, 0.5, 0.78, 1.0],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(children: [
                _topBar(),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: FadeTransition(
                          opacity: _fade,
                          child: SlideTransition(
                            position: _slide,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _checking
                                  ? KeyedSubtree(
                                      key: const ValueKey('load'),
                                      child: _loadingView())
                                  : _offline
                                      ? KeyedSubtree(
                                          key: const ValueKey('off'),
                                          child: _offlineView())
                                      : _pending
                                          ? KeyedSubtree(
                                              key: const ValueKey('wait'),
                                              child: _waiting())
                                          : KeyedSubtree(
                                              key: const ValueKey('choose'),
                                              child: _choices()),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _topBar() => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
        child: Row(children: [
          const SirvyaLogo(variant: SirvyaLogoVariant.wordmark, height: 20),
          const Spacer(),
          TextButton.icon(
            onPressed: _logout,
            icon: Icon(Icons.logout_rounded,
                size: 16, color: Colors.white.withValues(alpha: 0.6)),
            label: Text('Log out',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
      );

  // ── Chargement initial ──
  Widget _loadingView() => const SizedBox(
        height: 300,
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
                color: AppColors.sand, strokeWidth: 2.5),
          ),
        ),
      );

  // ── Impossible de vérifier (réseau) ──
  Widget _offlineView() => Column(children: [
        const SizedBox(height: 60),
        Icon(Icons.wifi_off_rounded,
            color: Colors.white.withValues(alpha: 0.5), size: 52),
        const SizedBox(height: 16),
        const Text('Unable to verify your account',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Check your connection and try again.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
        const SizedBox(height: 24),
        _PressableScale(
          onTap: _retry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(
                color: AppColors.sand, borderRadius: BorderRadius.circular(14)),
            child: const Text('RETRY',
                style: TextStyle(
                    color: AppColors.cyprus,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5)),
          ),
        ),
      ]);

  // ── Écran 1 : les deux choix ──
  Widget _choices() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _badge('VERIFICATION'),
          const SizedBox(height: 16),
          const Text('Verify your\ncoach account',
              style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.08,
                  letterSpacing: -1)),
          const SizedBox(height: 10),
          Text('This step is required to access SIRVYA as a coach.',
              style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.white.withValues(alpha: 0.65))),
          const SizedBox(height: 28),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _busy ? 0.45 : 1,
            child: Column(children: [
              _OptionCard(
                icon: Icons.qr_code_scanner_rounded,
                tag: 'INSTANT ACCESS',
                title: 'Scan an invitation QR code',
                description:
                    'Scan the QR code of the coach who invited you and enter right away.',
                highlighted: true,
                onTap: _busy ? null : _scanQr,
              ),
              const SizedBox(height: 18),
              _orDivider(),
              const SizedBox(height: 18),
              _OptionCard(
                icon: Icons.photo_camera_rounded,
                tag: 'REVIEW · UP TO 48H',
                title: 'Take a photo of your certificate',
                description:
                    'Our team checks your credentials. You enter once your request is approved.',
                highlighted: false,
                onTap: _busy ? null : _takePhoto,
              ),
            ]),
          ),
          if (_busy) ...[
            const SizedBox(height: 24),
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: AppColors.sand, strokeWidth: 2.5),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 18),
            _errorBanner(_error!),
          ],
          const SizedBox(height: 28),
          Row(children: [
            Icon(Icons.lock_outline_rounded,
                size: 14, color: Colors.white.withValues(alpha: 0.45)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your documents are only used to verify your identity as a coach.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11.5,
                    height: 1.4),
              ),
            ),
          ]),
          const SizedBox(height: 24),
        ],
      );

  // ── Écran 2 : en attente d'approbation ──
  Widget _waiting() => Column(
        children: [
          const SizedBox(height: 36),
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.sand.withValues(alpha: 0.10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.sand
                        .withValues(alpha: 0.10 + 0.18 * _pulse.value),
                    blurRadius: 24 + 30 * _pulse.value,
                    spreadRadius: 2 + 8 * _pulse.value,
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.sand.withValues(alpha: 0.16),
                  border: Border.all(
                      color: AppColors.sand.withValues(alpha: 0.45),
                      width: 1.5),
                ),
                child: const Icon(Icons.hourglass_top_rounded,
                    color: AppColors.sand, size: 38),
              ),
            ),
          ),
          const SizedBox(height: 28),
          _badge('PENDING REVIEW'),
          const SizedBox(height: 16),
          const Text('Waiting for\napproval',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.08,
                  letterSpacing: -1)),
          const SizedBox(height: 12),
          Text(
              'Your certificate was sent. You will get access as soon as our team approves it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: Colors.white.withValues(alpha: 0.65))),
          const SizedBox(height: 28),
          _glass(
            child: Column(children: [
              _timelineStep(Icons.check_rounded, 'Certificate sent',
                  'We received your photo.', _StepState.done),
              _timelineStep(Icons.manage_search_rounded, 'Under review',
                  'Usually within 48 hours.', _StepState.active),
              _timelineStep(Icons.verified_rounded, 'Approved',
                  'You get full access to SIRVYA.', _StepState.todo,
                  last: true),
            ]),
          ),
          const SizedBox(height: 24),
          _PressableScale(
            onTap: _checkApproved,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.sand,
                    AppColors.sand.withValues(alpha: 0.85)
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.sand.withValues(alpha: 0.35),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded,
                      color: AppColors.cyprus, size: 18),
                  SizedBox(width: 10),
                  Text('CHECK STATUS',
                      style: TextStyle(
                          color: AppColors.cyprus,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_error != null) ...[
            _errorBanner(_error!),
            const SizedBox(height: 12),
          ],
          TextButton.icon(
            onPressed: _busy ? null : _takePhoto,
            icon: const Icon(Icons.photo_camera_outlined,
                color: AppColors.sand, size: 16),
            label: const Text('Send another photo',
                style: TextStyle(
                    color: AppColors.sand,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 24),
        ],
      );

  // ───────────────────────── Petits composants ─────────────────────────

  Widget _badge(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.sand.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.sand,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6)),
      );

  Widget _orDivider() => Row(children: [
        Expanded(
            child: Divider(
                color: Colors.white.withValues(alpha: 0.15), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('OR',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2)),
        ),
        Expanded(
            child: Divider(
                color: Colors.white.withValues(alpha: 0.15), thickness: 1)),
      ]);

  Widget _glass({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: child,
      );

  Widget _errorBanner(String msg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _red.withValues(alpha: 0.1),
          border: Border.all(color: _red.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded, color: _red, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(msg,
                  style: const TextStyle(
                      color: _red,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600))),
        ]),
      );

  Widget _timelineStep(IconData icon, String title, String sub, _StepState state,
      {bool last = false}) {
    final done = state == _StepState.done;
    final active = state == _StepState.active;
    final color =
        done || active ? AppColors.sand : Colors.white.withValues(alpha: 0.3);
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 36,
          child: Column(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.sand : Colors.transparent,
                border: Border.all(color: color, width: active ? 2 : 1.5),
              ),
              child: Icon(icon,
                  size: 17, color: done ? AppColors.cyprus : color),
            ),
            if (!last)
              Expanded(
                child: Container(
                  width: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: done
                      ? AppColors.sand.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.12),
                ),
              ),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 18, top: 4),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      color: done || active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(sub,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ───────────────────────── Carte d'option ─────────────────────────

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String tag, title, description;
  final bool highlighted;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.icon,
    required this.tag,
    required this.title,
    required this.description,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: highlighted
              ? AppColors.sand.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: highlighted
                ? AppColors.sand
                : Colors.white.withValues(alpha: 0.15),
            width: highlighted ? 1.5 : 1,
          ),
          boxShadow: highlighted
              ? [
                  BoxShadow(
                    color: AppColors.sand.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color:
                  AppColors.sand.withValues(alpha: highlighted ? 0.22 : 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.sand, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tag,
                  style: TextStyle(
                      color: AppColors.sand.withValues(alpha: 0.85),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4)),
              const SizedBox(height: 5),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.25)),
              const SizedBox(height: 4),
              Text(description,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                      height: 1.4)),
            ]),
          ),
          const SizedBox(width: 8),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: highlighted ? AppColors.sand : Colors.transparent,
              border: Border.all(
                  color: highlighted
                      ? AppColors.sand
                      : Colors.white.withValues(alpha: 0.3),
                  width: 1.5),
            ),
            child: Icon(Icons.arrow_forward_rounded,
                size: 16,
                color: highlighted ? AppColors.cyprus : Colors.white70),
          ),
        ]),
      ),
    );
  }
}

// ───────────────────────── Effet de pression ─────────────────────────

class _PressableScale extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  const _PressableScale({required this.onTap, required this.child});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  double _scale = 1.0;

  void _set(double v) {
    if (widget.onTap == null) return;
    setState(() => _scale = v);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _set(0.97),
        onTapUp: (_) => _set(1.0),
        onTapCancel: () => _set(1.0),
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      );
}