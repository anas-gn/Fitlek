import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'login.dart';
import '../../components/theme_selector.dart';
import '../../theme/fitlek_theme_extension.dart';
import '../../components/sirvya_logo.dart';
// ⚠️ adapte ce chemin vers ton fichier LoginScreen
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
// ─────────────────────────────────────────────
//  Constants
// ─────────────────────────────────────────────

const _baseUrl = 'http://localhost:3000/api';

// ─────────────────────────────────────────────
//  Models (locaux légers)
// ─────────────────────────────────────────────

class _WeightEntry {
  final String label;
  final double weight;
  final String date;
  const _WeightEntry(this.label, this.weight) : date = '';
}

class _WeightStats {
  final double? current;
  final double? start;
  final double? max;
  final double? min;
  final int total;
  const _WeightStats({
    this.current,
    this.start,
    this.max,
    this.min,
    this.total = 0,
  });
}

// ─────────────────────────────────────────────
//  ClientProfileScreen
// ─────────────────────────────────────────────

class ClientProfileScreen extends StatefulWidget {
  final int clientID;
  final String token;
  final VoidCallback? onLogout;

  const ClientProfileScreen({
    super.key,
    required this.clientID,
    required this.token,
    this.onLogout,
  });

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Profile state ─────────────────────────────────────────────────
  bool _loadingProfile = true;
  String? _loadError;
  bool _saving = false;
  bool _saveSuccess = false;
  bool _isEditing = false;

  // ── Avatar ────────────────────────────────────────────────────────
  String? _avatarUrl;
  bool _uploadingAvatar = false;

  // ── Form controllers ──────────────────────────────────────────────
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _heightCtrl = TextEditingController(text: '165');
  final _goalCtrl = TextEditingController(
    text: 'Weight loss and toning',
  );

  String _selectedGender = 'Female';
  bool _isPremium = false;

  // ── Weight data (remote) ──────────────────────────────────────────
  List<_WeightEntry> _weightData = [];
  _WeightStats _weightStats = const _WeightStats();
  bool _loadingWeight = false;

  // ── Stats ─────────────────────────────────────────────────────────
  int _sessionsCount = 0;

  // ── Headers ───────────────────────────────────────────────────────
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      };

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // ✅ FIX: length=2 car on a exactement 2 onglets (PROFIL / PROGRESSION)
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_tabController.index == 1 && _weightData.isEmpty && !_loadingWeight) {
        _fetchWeightData();
      }
    });
    _fetchProfile();
    // ✅ FIX: on charge les données de poids dès le démarrage,
    // sans attendre que l'utilisateur clique sur l'onglet PROGRESSION.
    _fetchWeightData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _heightCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  // ── GET /api/clients/me ───────────────────────────────────────────

  Future<void> _fetchProfile() async {
    setState(() {
      _loadingProfile = true;
      _loadError = null;
    });
    try {
      final res = await http
          .get(
            Uri.parse('$_baseUrl/clients/me?userID=${widget.clientID}'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _populateForm(data);
        await _fetchSessionsCount();
        if (mounted) setState(() => _loadingProfile = false);
      } else {
        final body = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _loadError = body['error'] ?? 'Server error (${res.statusCode})';
            _loadingProfile = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = 'Unable to reach the server.';
          _loadingProfile = false;
        });
      }
    }
  }

  void _populateForm(Map<String, dynamic> data) {
    _firstNameCtrl.text = data['firstName'] ?? '';
    _lastNameCtrl.text = data['lastName'] ?? '';
    _emailCtrl.text = data['email'] ?? '';
    _avatarUrl = data['avatarUrl'] as String?;
    _isPremium = data['isPremium'] == 1 || data['isPremium'] == true;
    _selectedGender = data['gender'] as String? ?? 'Other';
    final h = _parseDouble(data['height']);
    _heightCtrl.text = h != null ? h.toStringAsFixed(1) : '165.0';
  }

  // ── GET /api/reservations ─────────────────────────────────────────

  Future<void> _fetchSessionsCount() async {
    try {
      final res = await http
          .get(
            Uri.parse(
              '$_baseUrl/reservations?userID=${widget.clientID}&role=client',
            ),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        if (mounted) setState(() => _sessionsCount = data.length);
      }
    } catch (_) {}
  }

  // ── GET weight history ────────────────────────────────────────────

  Future<void> _fetchWeightData() async {
    if (_loadingWeight) return;
    setState(() => _loadingWeight = true);
    try {
      final chartRes = await http
          .get(
            Uri.parse(
              '$_baseUrl/weight-history/me/chart?clientID=${widget.clientID}',
            ),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      final statsRes = await http
          .get(
            Uri.parse(
              '$_baseUrl/weight-history/me/stats?clientID=${widget.clientID}',
            ),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (chartRes.statusCode == 200) {
        final List<dynamic> rows = jsonDecode(chartRes.body);
        final entries = rows
            .map(
              (r) => _WeightEntry(
                r['label'] as String,
                _parseDouble(r['weight']) ?? 0.0,
              ),
            )
            .toList();
        if (mounted) setState(() => _weightData = entries);
      } else {
        debugPrint(
          '❌ Weight chart status: ${chartRes.statusCode} body: ${chartRes.body}',
        );
      }

      if (statsRes.statusCode == 200) {
        final s = jsonDecode(statsRes.body) as Map<String, dynamic>;
        if (mounted) {
          setState(
            () => _weightStats = _WeightStats(
              current: _parseDouble(s['currentWeight']),
              start: _parseDouble(s['startWeight']),
              max: _parseDouble(s['maxWeight']),
              min: _parseDouble(s['minWeight']),
              total: (s['totalEntries'] as num?)?.toInt() ?? 0,
            ),
          );
        }
      } else {
        debugPrint(
          '❌ Weight stats status: ${statsRes.statusCode} body: ${statsRes.body}',
        );
      }
    } catch (e) {
      debugPrint('❌ Weight fetch error: $e');
    } finally {
      if (mounted) setState(() => _loadingWeight = false);
    }
  }

  // ── POST weight entry ─────────────────────────────────────────────

  Future<void> _addWeight(double weight) async {
    final errorColor = context.fitlek.error;
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/weight-history'),
            headers: _headers,
            body: jsonEncode({'clientID': widget.clientID, 'weight': weight}),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 201) {
        _showSnack('Weight saved ✓');
        await _fetchWeightData(); // refresh
      } else {
        _showSnack('Error while saving', color: errorColor);
      }
    } catch (_) {
      _showSnack('Unable to reach the server.', color: errorColor);
    }
  }

  // ── Avatar upload ─────────────────────────────────────────────────

  Future<void> _pickAndUploadAvatar() async {
    final errorColor = context.fitlek.error;
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
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/upload/avatar?userID=${widget.clientID}'),
      );
      request.headers['Authorization'] = 'Bearer ${widget.token}';

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        final ext = file.name.split('.').last.toLowerCase();
        final mime = ext == 'png'
            ? 'image/png'
            : ext == 'webp'
                ? 'image/webp'
                : 'image/jpeg';

        request.files.add(
          http.MultipartFile.fromBytes(
            'avatar',
            bytes,
            filename: file.name,
            contentType: MediaType.parse(mime), // ← c'est ça qui manque
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('avatar', file.path),
        );
      }

      final streamedRes = await request.send().timeout(
            const Duration(seconds: 30),
          );
      final res = await http.Response.fromStream(streamedRes);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final newUrl = data['url'] as String;

        await http
            .put(
              Uri.parse('$_baseUrl/clients/me'),
              headers: _headers,
              body: jsonEncode({
                'userID': widget.clientID,
                'firstName': _firstNameCtrl.text.trim(),
                'lastName': _lastNameCtrl.text.trim(),
                'gender': _selectedGender,
                'avatarUrl': newUrl,
                'height': _parseDouble(_heightCtrl.text),
              }),
            )
            .timeout(const Duration(seconds: 10));

        if (mounted) setState(() => _avatarUrl = newUrl);
        _showSnack('Profile photo updated ✓');
      } else {
        final body = jsonDecode(res.body);
        _showSnack(body['error'] ?? 'Upload error', color: errorColor);
      }
    } catch (e) {
      _showSnack('Error: $e', color: errorColor);
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  // ── PUT /api/clients/me ───────────────────────────────────────────

  Future<void> _saveProfile() async {
    final errorColor = context.fitlek.error;
    setState(() => _saving = true);
    try {
      final res = await http
          .put(
            Uri.parse('$_baseUrl/clients/me'),
            headers: _headers,
            body: jsonEncode({
              'userID': widget.clientID,
              'firstName': _firstNameCtrl.text.trim(),
              'lastName': _lastNameCtrl.text.trim(),
              'gender': _selectedGender,
              'avatarUrl': _avatarUrl,
              'height': _parseDouble(_heightCtrl.text),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _isEditing = false;
            _saveSuccess = true;
            _saving = false;
          });
        }
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _saveSuccess = false);
        });
      } else {
        final data = jsonDecode(res.body);
        if (mounted) setState(() => _saving = false);
        _showSnack(
          data['error'] ?? 'Error while saving.',
          color: errorColor,
        );
      }
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      _showSnack('Unable to reach the server.', color: errorColor);
    }
  }

  void _toggleEdit() =>
      _isEditing ? _saveProfile() : setState(() => _isEditing = true);

  // ✅ Navigation directe vers LoginScreen — ne dépend plus de widget.onLogout
  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
      (route) => false,
    );
  }

  void _showSnack(String msg, {Color? color}) {
    final snackColor = color ?? context.fitlek.success;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: snackColor.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _genderDisplay(String g) {
    switch (g) {
      case 'Male':
        return 'Male';
      case 'Female':
        return 'Female';
      default:
        return 'Other';
    }
  }

  String _calcBMI() {
    final w = _weightStats.current ?? 68.0;
    final h = (double.tryParse(_heightCtrl.text) ?? 165.0) / 100;
    return (w / (h * h)).toStringAsFixed(1);
  }

  // ── Pop-up Changer mot de passe ───────────────────────────────────

  void _showChangePasswordSheet() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureOld = true, obscureNew = true, obscureConfirm = true;
    bool saving = false;
    String? errorMsg;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          Future<void> submit() async {
            final oldPass = oldCtrl.text.trim();
            final newPass = newCtrl.text.trim();
            final confirm = confirmCtrl.text.trim();

            if (oldPass.isEmpty || newPass.isEmpty || confirm.isEmpty) {
              setSheetState(() => errorMsg = 'All fields are required.');
              return;
            }
            if (newPass.length < 6) {
              setSheetState(
                () => errorMsg =
                    'The new password must be at least 6 characters.',
              );
              return;
            }
            if (newPass != confirm) {
              setSheetState(
                () => errorMsg = 'Passwords do not match.',
              );
              return;
            }

            setSheetState(() {
              saving = true;
              errorMsg = null;
            });

            try {
              final res = await http
                  .put(
                    Uri.parse('$_baseUrl/clients/me/password'),
                    headers: _headers,
                    body: jsonEncode({
                      'userID': widget.clientID,
                      'oldPassword': oldPass,
                      'newPassword': newPass,
                    }),
                  )
                  .timeout(const Duration(seconds: 10));

              if (res.statusCode == 200) {
                if (ctx.mounted) Navigator.pop(ctx);
                _showSnack('Password updated ✓');
              } else {
                final data = jsonDecode(res.body);
                setSheetState(() {
                  saving = false;
                  errorMsg = data['error'] ?? 'Error while updating.';
                });
              }
            } catch (e) {
              setSheetState(() {
                saving = false;
                errorMsg = 'Unable to reach the server.';
              });
            }
          }

          Widget passwordField(
            String label,
            TextEditingController c,
            bool obscure,
            VoidCallback toggle,
          ) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.fitlek.border),
              ),
              child: TextField(
                controller: c,
                obscureText: obscure,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 13),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: TextStyle(
                    color: context.fitlek.textMuted,
                    fontSize: 12,
                  ),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: context.fitlek.textMuted,
                      size: 18,
                    ),
                    onPressed: toggle,
                  ),
                ),
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: context.fitlek.card,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.fitlek.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.lock_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Change password',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  passwordField(
                    'Current password',
                    oldCtrl,
                    obscureOld,
                    () => setSheetState(() => obscureOld = !obscureOld),
                  ),
                  passwordField(
                    'New password',
                    newCtrl,
                    obscureNew,
                    () => setSheetState(() => obscureNew = !obscureNew),
                  ),
                  passwordField(
                    'Confirm password',
                    confirmCtrl,
                    obscureConfirm,
                    () => setSheetState(() => obscureConfirm = !obscureConfirm),
                  ),
                  if (errorMsg != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: context.fitlek.error,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            errorMsg!,
                            style: TextStyle(
                              color: context.fitlek.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: saving ? null : submit,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: saving
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.4)
                            : Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: saving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'UPDATE',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 1.2,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loadingProfile) return _buildLoading();
    if (_loadError != null) return _buildError();
    return _buildContent();
  }

  Widget _buildLoading() => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 2),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: TextStyle(color: context.fitlek.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );

  Widget _buildError() => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded,
                  color: context.fitlek.textMuted, size: 52),
              const SizedBox(height: 16),
              Text(
                _loadError!,
                style: TextStyle(color: context.fitlek.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _fetchProfile,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildContent() => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildProfileHero(),
              _buildStatsRow(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildProfileTab(), _buildProgressTab()],
                ),
              ),
            ],
          ),
        ),
      );

  // ── Header ────────────────────────────────────────────────────────

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SirvyaLogo(variant: SirvyaLogoVariant.wordmark, height: 55),
            const SizedBox(width: 10),
            const Spacer(),
            if (_isPremium)
              Container(
                margin: const EdgeInsets.only(right: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: context.fitlek.premium.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.fitlek.premium.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      color: context.fitlek.premium,
                      size: 12,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'PREMIUM',
                      style: TextStyle(
                        color: context.fitlek.premium,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            if (_saveSuccess)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.fitlek.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: context.fitlek.success.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: context.fitlek.success, size: 13),
                    const SizedBox(width: 6),
                    Text(
                      'Saved',
                      style: TextStyle(
                        color: context.fitlek.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            GestureDetector(
              onTap: _saving ? null : _toggleEdit,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _isEditing
                      ? Theme.of(context).colorScheme.primary
                      : context.fitlek.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _isEditing
                          ? Theme.of(context).colorScheme.primary
                          : context.fitlek.border),
                ),
                child: _saving
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        children: [
                          Icon(
                            _isEditing
                                ? Icons.save_rounded
                                : Icons.edit_rounded,
                            color: _isEditing
                                ? Theme.of(context).colorScheme.onPrimary
                                : context.fitlek.textSecondary,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isEditing ? 'Save' : 'Edit',
                            style: TextStyle(
                              color: _isEditing
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : context.fitlek.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      );

  // ── Profile hero avec avatar cliquable ────────────────────────────

  Widget _buildProfileHero() {
    final hasAvatar = _avatarUrl != null && _avatarUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2.5),
                  ),
                  child: _uploadingAvatar
                      ? CircleAvatar(
                          radius: 36,
                          backgroundColor: context.fitlek.card2,
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : CircleAvatar(
                          radius: 36,
                          backgroundColor: context.fitlek.card2,
                          backgroundImage:
                              hasAvatar ? NetworkImage(_avatarUrl!) : null,
                          child: !hasAvatar
                              ? Text(
                                  _firstNameCtrl.text.isNotEmpty
                                      ? _firstNameCtrl.text[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                )
                              : null,
                        ),
                ),
                // Badge caméra — toujours visible (pas seulement en mode edit)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _uploadingAvatar
                          ? Colors.grey
                          : Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_firstNameCtrl.text} ${_lastNameCtrl.text}'.trim(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _emailCtrl.text,
                  style:
                      TextStyle(color: context.fitlek.textMuted, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _goalCtrl.text.isNotEmpty ? _goalCtrl.text : 'No goal set',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    final currentW =
        _weightStats.current ?? double.tryParse(_heightCtrl.text) ?? 68.0;
    final stats = [
      {
        'label': 'Sessions',
        'value': '$_sessionsCount',
        'icon': Icons.bolt_rounded,
      },
      {
        'label': 'Weight',
        'value': '${currentW.toStringAsFixed(1)} kg',
        'icon': Icons.monitor_weight_rounded,
      },
      {'label': 'BMI', 'value': _calcBMI(), 'icon': Icons.favorite_rounded},
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: stats
            .asMap()
            .entries
            .map(
              (e) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: e.key < stats.length - 1 ? 10 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: context.fitlek.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.fitlek.border),
                  ),
                  child: Column(
                    children: [
                      Icon(e.value['icon'] as IconData,
                          color: Theme.of(context).colorScheme.primary,
                          size: 16),
                      const SizedBox(height: 4),
                      Text(
                        e.value['value'] as String,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        e.value['label'] as String,
                        style: TextStyle(
                          color: context.fitlek.textMuted,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────

  Widget _buildTabBar() => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: context.fitlek.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.fitlek.border),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: context.fitlek.textMuted,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
            tabs: const [
              Tab(text: 'PROFILE'),
              Tab(text: 'PROGRESS'),
            ],
          ),
        ),
      );

  // ── ONGLET 1 : Profil ─────────────────────────────────────────────

  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      children: [
        _sectionLabel('PERSONAL INFORMATION'),
        const SizedBox(height: 12),
        _formRow('First name', _firstNameCtrl, Icons.person_rounded),
        _formRow('Last name', _lastNameCtrl, Icons.person_outline_rounded),
        _formRow(
          'Email',
          _emailCtrl,
          Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        _sectionLabel('FITNESS DATA'),
        const SizedBox(height: 12),
        _buildGenderSelector(),
        _formRow(
          'Height (cm)',
          _heightCtrl,
          Icons.height_rounded,
          keyboardType: TextInputType.number,
        ),
        _formRow(
          'Fitness goal',
          _goalCtrl,
          Icons.flag_rounded,
          maxLines: 2,
        ),
        const SizedBox(height: 20),
        _sectionLabel('SECURITY'),
        const SizedBox(height: 12),
        _actionTile(
          Icons.lock_rounded,
          'Change password',
          onTap: _showChangePasswordSheet,
        ),
        _actionTile(
          Icons.notifications_rounded,
          'Notification preferences',
          onTap: () {},
        ),
        _actionTile(Icons.language_rounded, 'Language — English', onTap: () {}),
        const SizedBox(height: 12),
        ThemeSelectorTile(controller: ThemeControllerScope.of(context)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _goToLogin,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: context.fitlek.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: context.fitlek.error.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded,
                    color: context.fitlek.error, size: 16),
                const SizedBox(width: 8),
                Text(
                  'LOG OUT',
                  style: TextStyle(
                    color: context.fitlek.error,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.fitlek.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isEditing
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : context.fitlek.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.wc_rounded,
                color: Theme.of(context).colorScheme.primary, size: 15),
          ),
          const SizedBox(width: 14),
          Text(
            'Gender',
            style: TextStyle(color: context.fitlek.textSecondary, fontSize: 13),
          ),
          const Spacer(),
          if (_isEditing)
            Row(
              children: ['Male', 'Female', 'Other'].map((g) {
                final sel = g == _selectedGender;
                return GestureDetector(
                  onTap: () => setState(() => _selectedGender = g),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: sel
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: sel
                              ? Theme.of(context).colorScheme.primary
                              : context.fitlek.border),
                    ),
                    child: Text(
                      _genderDisplay(g),
                      style: TextStyle(
                        color: sel
                            ? Theme.of(context).colorScheme.onPrimary
                            : context.fitlek.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            )
          else
            Text(
              _genderDisplay(_selectedGender),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  Widget _formRow(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.fitlek.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isEditing
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : context.fitlek.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                color: Theme.of(context).colorScheme.primary, size: 15),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                      TextStyle(color: context.fitlek.textMuted, fontSize: 10),
                ),
                const SizedBox(height: 2),
                _isEditing
                    ? TextField(
                        controller: ctrl,
                        keyboardType: keyboardType,
                        maxLines: maxLines,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                    : Text(
                        ctrl.text,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ],
            ),
          ),
          if (_isEditing)
            Icon(Icons.edit_rounded, color: context.fitlek.textMuted, size: 14),
        ],
      ),
    );
  }

  Widget _actionTile(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.fitlek.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.fitlek.border),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  color: Theme.of(context).colorScheme.primary, size: 15),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                    color: context.fitlek.textSecondary, fontSize: 13),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.fitlek.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ── ONGLET 2 : Progression ────────────────────────────────────────

  Widget _buildProgressTab() {
    if (_loadingWeight && _weightData.isEmpty) {
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary, strokeWidth: 2),
        ),
      );
    }

    final current = _weightStats.current ?? 68.0;
    final start = _weightStats.start ?? current;
    final lost = start - current;

    final hasSeries = _weightData.isNotEmpty;
    final minW = hasSeries
        ? _weightData.map((e) => e.weight).reduce(math.min)
        : current - 2;
    final maxW = hasSeries
        ? _weightData.map((e) => e.weight).reduce(math.max)
        : current + 2;
    final range = (maxW - minW).abs() + 4;

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: context.fitlek.card,
      onRefresh: _fetchWeightData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        children: [
          // Stats row
          Row(
            children: [
              _progressStat(
                'Current weight',
                '${current.toStringAsFixed(1)} kg',
                Icons.monitor_weight_rounded,
                Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              _progressStat(
                lost >= 0 ? 'Lost' : 'Gained',
                '${lost >= 0 ? '-' : '+'}${lost.abs().toStringAsFixed(1)} kg',
                Icons.trending_down_rounded,
                context.fitlek.success,
              ),
              const SizedBox(width: 10),
              _progressStat(
                'BMI',
                _calcBMI(),
                Icons.favorite_rounded,
                context.fitlek.info,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Chart
          _sectionLabel('WEIGHT TREND'),
          const SizedBox(height: 14),
          if (hasSeries)
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.fitlek.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.fitlek.border),
              ),
              child: CustomPaint(
                painter: _WeightChartPainter(
                  data: _weightData,
                  minValue: minW - 2,
                  range: range,
                  lineColor: Theme.of(context).colorScheme.primary,
                  gridColor: context.fitlek.border,
                  labelColor: context.fitlek.textMuted,
                  dotBgColor: context.fitlek.card,
                ),
                size: Size.infinite,
              ),
            )
          else
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: context.fitlek.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.fitlek.border),
              ),
              child: Center(
                child: Text(
                  'Add at least 2 entries to see the chart',
                  style:
                      TextStyle(color: context.fitlek.textMuted, fontSize: 12),
                ),
              ),
            ),
          const SizedBox(height: 20),

          // Tableau historique
          if (_weightData.isNotEmpty) ...[
            _sectionLabel('HISTORY — TABLE'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: context.fitlek.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.fitlek.border),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: context.fitlek.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'PERIOD',
                            style: TextStyle(
                              color: context.fitlek.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'WEIGHT',
                            style: TextStyle(
                              color: context.fitlek.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'CHANGE',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: context.fitlek.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Rows
                  ..._weightData.asMap().entries.map((e) {
                    final prev = e.key > 0
                        ? _weightData[e.key - 1].weight
                        : e.value.weight;
                    final diff = e.value.weight - prev;
                    final isLoss = diff <= 0;
                    final isLast = e.key == _weightData.length - 1;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : Border(
                                bottom:
                                    BorderSide(color: context.fitlek.border),
                              ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              e.value.label,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${e.value.weight.toStringAsFixed(1)} kg',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: e.key == 0
                                  ? Text(
                                      '—',
                                      style: TextStyle(
                                        color: context.fitlek.textMuted,
                                        fontSize: 12,
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (isLoss
                                                ? context.fitlek.success
                                                : context.fitlek.error)
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isLoss
                                                ? Icons.arrow_downward_rounded
                                                : Icons.arrow_upward_rounded,
                                            color: isLoss
                                                ? context.fitlek.success
                                                : context.fitlek.error,
                                            size: 11,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            '${diff.abs().toStringAsFixed(1)} kg',
                                            style: TextStyle(
                                              color: isLoss
                                                  ? context.fitlek.success
                                                  : context.fitlek.error,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Add weight
          _sectionLabel('ADD AN ENTRY'),
          const SizedBox(height: 12),
          _AddWeightWidget(onAdd: _addWeight),
        ],
      ),
    );
  }

  Widget _progressStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.fitlek.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.fitlek.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: context.fitlek.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers généraux ──────────────────────────────────────────────

  Widget _sectionLabel(String label) => Row(
        children: [
          Container(
              width: 3,
              height: 14,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: context.fitlek.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ],
      );
}

// ─────────────────────────────────────────────
//  Add Weight Widget
// ─────────────────────────────────────────────

class _AddWeightWidget extends StatefulWidget {
  final Future<void> Function(double) onAdd;
  const _AddWeightWidget({required this.onAdd});

  @override
  State<_AddWeightWidget> createState() => _AddWeightWidgetState();
}

class _AddWeightWidgetState extends State<_AddWeightWidget> {
  final _ctrl = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.fitlek.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.fitlek.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.fitlek.border),
              ),
              child: TextField(
                controller: _ctrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Weight today (kg)',
                  hintStyle:
                      TextStyle(color: context.fitlek.textMuted, fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _saving
                ? null
                : () async {
                    final v = double.tryParse(_ctrl.text);
                    if (v == null) return;
                    setState(() => _saving = true);
                    await widget.onAdd(v);
                    _ctrl.clear();
                    if (mounted) setState(() => _saving = false);
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: _saving
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4)
                    : Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _saving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'ADD',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Weight Chart Painter
// ─────────────────────────────────────────────

class _WeightChartPainter extends CustomPainter {
  final List<_WeightEntry> data;
  final double minValue;
  final double range;
  final Color lineColor;
  final Color gridColor;
  final Color labelColor;
  final Color dotBgColor;

  const _WeightChartPainter({
    required this.data,
    required this.minValue,
    required this.range,
    required this.lineColor,
    required this.gridColor,
    required this.labelColor,
    required this.dotBgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final stepX = size.width / (data.length - 1);

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = data.asMap().entries.map((e) {
      final x = e.key * stepX;
      final normalized = range > 0 ? (e.value.weight - minValue) / range : 0.5;
      final y =
          size.height - (normalized * size.height * 0.85) - size.height * 0.05;
      return Offset(x, y);
    }).toList();

    final path = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      path.lineTo(p.dx, p.dy);
    }
    path
      ..lineTo(points.last.dx, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.22),
            lineColor.withValues(alpha: 0.0)
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final cp1 = Offset(
        (points[i - 1].dx + points[i].dx) / 2,
        points[i - 1].dy,
      );
      final cp2 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i].dy);
      linePath.cubicTo(
        cp1.dx,
        cp1.dy,
        cp2.dx,
        cp2.dy,
        points[i].dx,
        points[i].dy,
      );
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final dotFill = Paint()..color = lineColor;
    final dotBg = Paint()..color = dotBgColor;
    final labelStyle = TextStyle(
      color: labelColor,
      fontSize: 9,
      fontWeight: FontWeight.w600,
    );

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 5, dotBg);
      canvas.drawCircle(points[i], 4, dotFill);

      final tp = TextPainter(
        text: TextSpan(text: data[i].label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(points[i].dx - tp.width / 2, size.height - 14));

      final vp = TextPainter(
        text: TextSpan(
          text: data[i].weight.toStringAsFixed(1),
          style: TextStyle(
            color: lineColor,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      vp.paint(canvas, Offset(points[i].dx - vp.width / 2, points[i].dy - 18));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
