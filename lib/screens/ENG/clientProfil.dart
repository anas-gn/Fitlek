import '../../components/nutrition_goal_card.dart';
import 'nutritionTracker.dart';
import '../../services/media_picker_service.dart';
import '../../services/image_upload_service.dart';
import '../../services/live_updates.dart';
import '../../components/account_password_sheet.dart';
import '../../components/client_profile_overview.dart';
import '../../components/category_icon.dart';
import '../../models/client_profile_completion.dart';
import 'coachChangePhone.dart' show CoachChangePhone;
import 'dart:convert';
import 'dart:async';
import '../../components/weight_progress_view.dart';
import '../../models/weight_entry.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/connection_recovery.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fitlek1/constants/urls.dart';
import 'package:fitlek1/services/apiService.dart';
import 'welcome.dart';
import 'blockedUsersList.dart';
import 'clientCoachFavorites.dart';
import 'clientChangeEmail.dart';
import 'userLocationSettings.dart';
import 'clientNotifications.dart';
import 'package:fitlek1/l10n/app_localizations.dart';
import '../../services/locale_service.dart';
import '../../components/theme_selector.dart';
import '../../theme/fitlek_theme_extension.dart';
import 'package:http_parser/http_parser.dart';
import '../../components/ENG/imagePreview.dart';

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

class ClientProfileScreen extends StatefulWidget {
  final int clientID;
  final bool embedded;
  final String token;
  final VoidCallback? onLogout;
  final http.Client? apiClient;

  const ClientProfileScreen({
    super.key,
    this.embedded = false,
    required this.clientID,
    required this.token,
    this.onLogout,
    this.apiClient,
  });

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen>
    with SingleTickerProviderStateMixin, LiveUpdates<ClientProfileScreen> {
  @override
  Set<String> get liveDomains =>
      {'clients', 'profile', 'edit', 'weight-history', 'reservations'};
  @override
  Future<void> refreshLiveData() async {
    if (!_isEditing && !_saving) {
      await Future.wait([_fetchProfile(silent: true), _fetchWeightData()]);
    }
  }

  late TabController _tabController;
  late final http.Client _api;

  bool _loadingProfile = true;
  String? _loadError;
  bool _saving = false;
  bool _saveSuccess = false;
  Timer? _savedIndicatorTimer;
  bool _isEditing = false;

  String? _avatarUrl;
  bool _uploadingAvatar = false;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  Map<String, dynamic> _savedProfile = {};
  String _phone = '', _city = '';
  List<String> _interests = [];
  List<Map<String, dynamic>> _categories = [];
  final _profileScroll = ScrollController();

  String _selectedGender = 'Female';

  List<WeightEntry> _weightData = [];
  String? _weightError;
  _WeightStats _weightStats = const _WeightStats();
  bool _loadingWeight = false;

  int _sessionsCount = 0;

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

  @override
  void initState() {
    super.initState();
    _api = widget.apiClient ?? http.Client();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_tabController.index > 0 && _profileScroll.hasClients) {
        _profileScroll.animateTo(_profileScroll.position.maxScrollExtent,
            duration: Duration(
                milliseconds:
                    MediaQuery.disableAnimationsOf(context) ? 0 : 300),
            curve: Curves.easeOutCubic);
      }
      if (_tabController.index == 1 && _weightData.isEmpty && !_loadingWeight) {
        _fetchWeightData();
      }
    });
    _fetchProfile();
    _fetchWeightData();
    _fetchCategories();
  }

  @override
  void dispose() {
    _savedIndicatorTimer?.cancel();
    if (widget.apiClient == null) _api.close();
    _tabController.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _heightCtrl.dispose();
    _profileScroll.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loadingProfile = true;
        _loadError = null;
      });
    }
    try {
      final res = await _api
          .get(
            Uri.parse('$baseUrl/clients/me?userID=${widget.clientID}'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (!mounted) return;
        if (!silent || (!_isEditing && !_saving)) _populateForm(data);
        if (mounted) {
          setState(() {
            _loadingProfile = false;
            _loadError = null;
          });
        }
        _fetchSessionsCount();
      } else {
        final body = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _loadError = body['error'] ??
                AppLocalizations.of(context)
                    .clientProfilServerError(res.statusCode);
            _loadingProfile = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        final connectionFailed = ConnectionRecovery.report(e);
        final l10n = AppLocalizations.of(context);
        setState(() {
          _loadError = connectionFailed
              ? l10n.clientProfilCheckConnection
              : l10n.clientProfilLoadFailed;
          _loadingProfile = false;
        });
      }
    }
  }

  void _populateForm(Map<String, dynamic> data) {
    _savedProfile = Map<String, dynamic>.from(data);
    _firstNameCtrl.text = data['firstName'] ?? '';
    _lastNameCtrl.text = data['lastName'] ?? '';
    _emailCtrl.text = data['email'] ?? '';
    _avatarUrl = data['avatarUrl'] as String?;
    _selectedGender = data['gender'] as String? ?? 'Other';
    final h = _parseDouble(data['height']);
    _heightCtrl.text = h != null ? h.toStringAsFixed(1) : '';
    _phone = '${data['phoneNumber'] ?? ''}';
    _city = '${data['ville'] ?? ''}';
    _interests = clientInterests(data['interests']);
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await _api
          .get(Uri.parse('$baseUrl/categories'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (mounted && response.statusCode == 200) {
        setState(() => _categories = (jsonDecode(response.body) as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList());
      }
    } catch (_) {/* Existing interests remain available while offline. */}
  }

  Future<void> _changePhone() async {
    final phone = await Navigator.push<String>(
        context,
        MaterialPageRoute(
            builder: (_) =>
                CoachChangePhone(token: widget.token, currentPhone: _phone)));
    if (!mounted || phone == null) return;
    setState(() {
      _phone = phone;
      _savedProfile['phoneNumber'] = phone;
    });
    if (!_isEditing) await _fetchProfile(silent: true);
  }

  Future<void> _changeLocation() async {
    final city = await Navigator.push<String>(context,
        MaterialPageRoute(builder: (_) => const UserLocationSettings()));
    if (!mounted || city == null) return;
    setState(() {
      _city = city;
      _savedProfile['ville'] = city;
    });
    if (!_isEditing) await _fetchProfile(silent: true);
  }

  void _cancelEditing() => setState(() {
        _populateForm(_savedProfile);
        _isEditing = false;
      });

  void _completeProfile(String section) {
    switch (section) {
      case 'photo':
        _pickAndUploadAvatar();
        return;
      case 'phone':
        _changePhone();
        return;
      case 'location':
        _changeLocation();
        return;
      case 'email':
        _changeEmail();
        return;
      default:
        setState(() => _isEditing = true);
        _tabController.animateTo(0);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _profileScroll.hasClients) {
            _profileScroll.animateTo(_profileScroll.position.maxScrollExtent,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic);
          }
        });
    }
  }

  Future<void> _changeEmail() async {
    final email = await Navigator.push<String>(
        context,
        MaterialPageRoute(
            builder: (_) =>
                ClientChangeEmailScreen(currentEmail: _emailCtrl.text)));
    if (!mounted || email == null) return;
    setState(() {
      _emailCtrl.text = email;
      _savedProfile['email'] = email;
    });
  }

  Future<void> _fetchSessionsCount() async {
    try {
      final res = await _api
          .get(
            Uri.parse(
              '$baseUrl/reservations?userID=${widget.clientID}&role=client',
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

  Future<void> _fetchWeightData() async {
    if (_loadingWeight || !mounted) return;
    setState(() => _loadingWeight = true);
    try {
      final responses = await Future.wait([
        _api
            .get(
                Uri.parse(
                    '$baseUrl/weight-history/me?clientID=${widget.clientID}&limit=90'),
                headers: _headers)
            .timeout(const Duration(seconds: 10)),
        _api
            .get(
                Uri.parse(
                    '$baseUrl/weight-history/me/stats?clientID=${widget.clientID}'),
                headers: _headers)
            .timeout(const Duration(seconds: 10)),
      ]);
      if (responses.any((response) => response.statusCode != 200)) {
        throw Exception('History unavailable');
      }
      final rows = jsonDecode(responses[0].body) as List;
      final entries = rows
          .whereType<Map>()
          .map((row) => WeightEntry.fromJson(Map<String, dynamic>.from(row)))
          .whereType<WeightEntry>()
          .toList();
      final stats = jsonDecode(responses[1].body) as Map<String, dynamic>;
      double? weight(dynamic raw) {
        final value = _parseDouble(raw);
        return value != null && value.isFinite && value > 0 && value <= 500
            ? value
            : null;
      }

      if (mounted) {
        setState(() {
          _weightData = weightPeriod(entries, null, DateTime.now());
          _weightStats = _WeightStats(
              current: weight(stats['currentWeight']),
              start: weight(stats['startWeight']),
              max: weight(stats['maxWeight']),
              min: weight(stats['minWeight']),
              total: int.tryParse('${stats['totalEntries']}') ?? 0);
          _weightError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _weightError =
            AppLocalizations.of(context).clientProfilWeightLoadFailed);
      }
    } finally {
      if (mounted) setState(() => _loadingWeight = false);
    }
  }

  Future<void> _addWeight(double weight) async {
    final response = await _api
        .post(Uri.parse('$baseUrl/weight-history'),
            headers: _headers,
            body: jsonEncode({'clientID': widget.clientID, 'weight': weight}))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 201) {
      throw Exception(
          AppLocalizations.of(context).clientProfilWeightSaveFailed);
    }
    if (!mounted) return;
    _showSnack(AppLocalizations.of(context).clientProfilWeightSaved);
    await _fetchWeightData();
  }

  Future<void> _pickAndUploadAvatar() async {
    final errorColor = context.fitlek.error;
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
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload/avatar?userID=${widget.clientID}'),
      );
      request.headers['Authorization'] = 'Bearer ${widget.token}';

      final image =
          await ImageUploadService.prepare(await file.readAsBytes(), file.name);
      request.files.add(http.MultipartFile.fromBytes('avatar', image.bytes,
          filename: image.filename,
          contentType: MediaType.parse(image.mimeType)));

      final streamedRes = await request.send().timeout(
            const Duration(seconds: 30),
          );
      final res = await http.Response.fromStream(streamedRes);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final newUrl = data['url'] as String;

        final update = await _api
            .put(
              Uri.parse('$baseUrl/clients/me'),
              headers: _headers,
              body: jsonEncode({
                'userID': widget.clientID,
                'avatarUrl': newUrl,
              }),
            )
            .timeout(const Duration(seconds: 10));

        if (update.statusCode != 200) {
          throw Exception(
              AppLocalizations.of(context).clientProfilPhotoSaveFailed);
        }
        if (mounted) {
          setState(() {
            _avatarUrl = newUrl;
            _savedProfile['avatarUrl'] = newUrl;
          });
        }
        _showSnack(AppLocalizations.of(context).clientProfilPhotoUpdated);
      } else {
        final body = jsonDecode(res.body);
        _showSnack(
            body['error'] ??
                AppLocalizations.of(context).clientProfilUploadError,
            color: errorColor);
      }
    } catch (e) {
      ConnectionRecovery.report(e);
      if (mounted) {
        _showSnack(
            AppLocalizations.of(context)
                .clientProfilGenericError(e.toString()),
            color: errorColor);
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _saveProfile() async {
    final errorColor = context.fitlek.error;
    final l10n = AppLocalizations.of(context);
    if (_saving) return;
    if (_firstNameCtrl.text.trim().isEmpty ||
        _lastNameCtrl.text.trim().isEmpty) {
      _showSnack(l10n.clientProfilNameRequired, color: errorColor);
      return;
    }
    final heightText = _heightCtrl.text.trim().replaceAll(',', '.');
    final height = heightText.isEmpty ? null : double.tryParse(heightText);
    if (heightText.isNotEmpty &&
        (height == null || !height.isFinite || height <= 0 || height > 300)) {
      _showSnack(l10n.clientProfilInvalidHeight, color: errorColor);
      return;
    }
    setState(() => _saving = true);
    try {
      final res = await _api
          .put(
            Uri.parse('$baseUrl/clients/me'),
            headers: _headers,
            body: jsonEncode({
              'userID': widget.clientID,
              'firstName': _firstNameCtrl.text.trim(),
              'lastName': _lastNameCtrl.text.trim(),
              'gender': _selectedGender,
              'height': height,
              'interests': _interests,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['profile'] is! Map) {
          throw Exception('Could not confirm saved profile.');
        }
        if (mounted) {
          setState(() {
            _populateForm(Map<String, dynamic>.from(data['profile']));
            _isEditing = false;
            _saveSuccess = true;
            _saving = false;
          });
        }
        _savedIndicatorTimer?.cancel();
        _savedIndicatorTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _saveSuccess = false);
        });
      } else {
        final data = jsonDecode(res.body);
        if (mounted) setState(() => _saving = false);
        _showSnack(
          data['error'] ?? AppLocalizations.of(context).clientProfilSaveFailed,
          color: errorColor,
        );
      }
    } catch (e) {
      ConnectionRecovery.report(e);
      if (mounted) setState(() => _saving = false);
      _showSnack(AppLocalizations.of(context).clientProfilServerUnreachable,
          color: errorColor);
    }
  }

  void _toggleEdit() =>
      _isEditing ? _saveProfile() : setState(() => _isEditing = true);

  void _openFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientCoachFavoriteScreen(
          clientID: widget.clientID,
          token: widget.token,
        ),
      ),
    );
  }

  void _showDeleteAccountSheet() {
    int step = 1;
    bool understood = false;
    bool loading = false;
    String? errorMsg;
    String otpValue = '';
    int secondsLeft = 600;
    bool canResend = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Future<void> startCountdown() async {
            setSheet(() {
              secondsLeft = 600;
              canResend = false;
            });
            while (secondsLeft > 0) {
              await Future.delayed(const Duration(seconds: 1));
              if (!ctx.mounted) return;
              setSheet(() => secondsLeft--);
            }
            if (ctx.mounted) setSheet(() => canResend = true);
          }

          Future<void> requestOtp() async {
            setSheet(() {
              loading = true;
              errorMsg = null;
            });
            try {
              final res = await _api
                  .post(
                    Uri.parse('$baseUrl/auth/request-delete-otp'),
                    headers: _headers,
                  )
                  .timeout(const Duration(seconds: 15));

              final body = jsonDecode(res.body) as Map<String, dynamic>;
              if (res.statusCode == 409 && body['blocked'] == true) {
                setSheet(() {
                  loading = false;
                  errorMsg = body['reason'] as String? ??
                      AppLocalizations.of(ctx).clientProfilDeleteBlockedDefault;
                });
                return;
              }
              if (res.statusCode != 200) {
                setSheet(() {
                  loading = false;
                  errorMsg = body['error'] as String? ??
                      AppLocalizations.of(ctx).clientProfilSendCodeFailed;
                });
                return;
              }
              setSheet(() {
                loading = false;
                step = 2;
                otpValue = '';
                errorMsg = null;
              });
              startCountdown();
            } catch (_) {
              setSheet(() {
                loading = false;
                errorMsg =
                    AppLocalizations.of(ctx).clientProfilServerUnreachable;
              });
            }
          }

          Future<void> confirmDelete() async {
            if (otpValue.length != 6) {
              setSheet(() => errorMsg =
                  AppLocalizations.of(ctx).clientProfilEnterFullCode);
              return;
            }
            setSheet(() {
              loading = true;
              errorMsg = null;
            });
            try {
              final res = await _api
                  .post(
                    Uri.parse('$baseUrl/auth/confirm-delete-account'),
                    headers: _headers,
                    body: jsonEncode({'otp': otpValue}),
                  )
                  .timeout(const Duration(seconds: 15));

              final body = jsonDecode(res.body) as Map<String, dynamic>;
              if (res.statusCode == 200 && body['deleted'] == true) {
                if (ctx.mounted) Navigator.pop(ctx);
                _goToLogin();
                return;
              }
              setSheet(() {
                loading = false;
                errorMsg = body['error'] as String? ??
                    AppLocalizations.of(ctx).clientProfilVerificationFailed;
              });
            } catch (_) {
              setSheet(() {
                loading = false;
                errorMsg =
                    AppLocalizations.of(ctx).clientProfilServerUnreachable;
              });
            }
          }

          final errorColor = context.fitlek.error;
          final cardColor = context.fitlek.card;
          final borderColor = context.fitlek.border;
          final textMuted = context.fitlek.textMuted;
          final cs = Theme.of(context).colorScheme;
          final l10n = AppLocalizations.of(ctx);

          Widget buildStep1() => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: borderColor,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: errorColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.delete_forever_rounded,
                            color: errorColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.clientProfilDeleteAccountTitle,
                              style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800)),
                          Text(l10n.clientProfilDeletePermanentSubtitle,
                              style: TextStyle(color: textMuted, fontSize: 12)),
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
                      border:
                          Border.all(color: errorColor.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.clientProfilDeleteWhatWillBeDeleted,
                            style: TextStyle(
                                color: errorColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        ...[
                          l10n.clientProfilDeleteItemProfile,
                          l10n.clientProfilDeleteItemSessions,
                          l10n.clientProfilDeleteItemMessages,
                          l10n.clientProfilDeleteItemWeight,
                        ].map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Row(
                                children: [
                                  Icon(Icons.remove_circle_outline,
                                      color: errorColor, size: 13),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(item,
                                          style: TextStyle(
                                              color: textMuted, fontSize: 12))),
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
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: understood ? errorColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: understood ? errorColor : borderColor,
                              width: 1.5,
                            ),
                          ),
                          child: understood
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 14)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.clientProfilDeleteUnderstandCheckbox,
                            style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 12.5,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (errorMsg != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: errorColor.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_rounded,
                              color: errorColor, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(errorMsg!,
                                  style: TextStyle(
                                      color: errorColor, fontSize: 12))),
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
                            child: Center(
                              child: Text(l10n.clientProfilCancel,
                                  style: TextStyle(
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                            ),
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
                              color: understood
                                  ? errorColor
                                  : errorColor.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(l10n.clientProfilSendCode,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          letterSpacing: 0.8)),
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
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: errorColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.mark_email_read_rounded,
                          color: errorColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.clientProfilVerifyIdentityTitle,
                            style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 17,
                                fontWeight: FontWeight.w800)),
                        Text(l10n.clientProfilVerifyCheckEmailSubtitle,
                            style: TextStyle(color: textMuted, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.clientProfilVerifyInstructions,
                  style: TextStyle(color: textMuted, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: errorColor.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 10,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      hintText: '● ● ● ● ● ●',
                      hintStyle: TextStyle(
                          color: borderColor, fontSize: 22, letterSpacing: 8),
                    ),
                    onChanged: (v) => setSheet(() => otpValue = v.trim()),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!canResend)
                      Text(l10n.clientProfilCodeExpiresIn(mins, secs),
                          style: TextStyle(color: textMuted, fontSize: 12))
                    else
                      Text(l10n.clientProfilCodeExpired,
                          style: TextStyle(
                              color: errorColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    GestureDetector(
                      onTap: canResend && !loading ? requestOtp : null,
                      child: Text(
                        l10n.clientProfilResendCode,
                        style: TextStyle(
                          color: canResend ? errorColor : textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          decoration:
                              canResend ? TextDecoration.underline : null,
                        ),
                      ),
                    ),
                  ],
                ),
                if (errorMsg != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: errorColor.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: errorColor, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(errorMsg!,
                                style: TextStyle(
                                    color: errorColor, fontSize: 12))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: loading
                            ? null
                            : () => setSheet(() {
                                  step = 1;
                                  errorMsg = null;
                                }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Center(
                            child: Text(l10n.clientProfilBack,
                                style: TextStyle(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: (otpValue.length == 6 && !loading)
                            ? confirmDelete
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: otpValue.length == 6
                                ? errorColor
                                : errorColor.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(l10n.clientProfilDeleteAccountBtn,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        letterSpacing: 0.5)),
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
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: step == 1
                    ? KeyedSubtree(
                        key: const ValueKey('step1'), child: buildStep1())
                    : KeyedSubtree(
                        key: const ValueKey('step2'), child: buildStep2()),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _goToLogin() async {
    await ApiService.clearToken();
    if (widget.onLogout != null) {
      widget.onLogout!();
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const WelcomeScreen(),
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
    final l10n = AppLocalizations.of(context);
    switch (g) {
      case 'Male':
        return l10n.clientProfilGenderMale;
      case 'Female':
        return l10n.clientProfilGenderFemale;
      default:
        return l10n.clientProfilGenderOther;
    }
  }

  String _calcBMI() {
    final w = _weightStats.current;
    final height = _parseDouble(_savedProfile['height']);
    if (w == null || w <= 0 || height == null || height <= 0) return '—';
    final h = height / 100;
    return (w / (h * h)).toStringAsFixed(1);
  }

  Future<void> _showChangePasswordSheet() async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AccountPasswordSheet(token: widget.token),
    );
    if (mounted && updated == true) {
      _showSnack(AppLocalizations.of(context).clientProfilPasswordUpdated);
    }
  }

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
                AppLocalizations.of(context).clientProfilLoadingProfile,
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
                    AppLocalizations.of(context).clientProfilRetry,
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

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: !_isEditing
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                  child: Row(children: [
                    OutlinedButton(
                        onPressed: _saving ? null : _cancelEditing,
                        child: Text(l10n.clientProfilCancel)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: FilledButton.icon(
                            onPressed: _saving ? null : _saveProfile,
                            icon: _saving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.check_rounded, size: 18),
                            label: Text(_saving
                                ? l10n.clientProfilSaving
                                : l10n.clientProfilSaveChanges))),
                  ]))),
      body: SafeArea(
          child: NestedScrollView(
        controller: _profileScroll,
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              sliver: SliverToBoxAdapter(
                  child: ClientProfileIdentityCard(
                      profile: _savedProfile,
                      uploading: _uploadingAvatar,
                      onAvatar: () {
                        if (_avatarUrl == null || _avatarUrl!.isEmpty) {
                          _pickAndUploadAvatar();
                          return;
                        }
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ImagePreview(
                                    imageUrl: _avatarUrl!,
                                    tag: 'client_avatar_${widget.clientID}')));
                      },
                      onChangePhoto: _pickAndUploadAvatar))),
          SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                  child: ClientProfileCompletionCard(
                      completion: ClientProfileCompletion(_savedProfile),
                      onComplete: _completeProfile))),
          SliverToBoxAdapter(child: _buildStatsRow()),
          SliverPersistentHeader(
              pinned: true,
              delegate: _ClientProfileTabs(
                  background: Theme.of(context).scaffoldBackgroundColor,
                  child: _buildTabBar())),
        ],
        body: TabBarView(controller: _tabController, children: [
          _buildProfileTab(),
          _buildProgressTab(),
          NutritionTrackerScreen(
              clientID: widget.clientID, token: widget.token, embedded: true)
        ]),
      )),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(l10n.clientProfilHeaderTitle,
                    style: TextStyle(
                        fontSize: 32,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 6),
                Text(
                    _saveSuccess
                        ? l10n.clientProfilHeaderSavedSubtitle
                        : l10n.clientProfilHeaderDefaultSubtitle,
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: _saveSuccess
                            ? context.fitlek.success
                            : context.fitlek.textMuted)),
              ])),
          const SizedBox(width: 12),
          IconButton.outlined(
              tooltip: _isEditing
                  ? l10n.clientProfilCancelEditingTooltip
                  : l10n.clientProfilEditProfileTooltip,
              onPressed: _saving
                  ? null
                  : _isEditing
                      ? _cancelEditing
                      : _toggleEdit,
              icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_outlined,
                  size: 20)),
        ]));
  }

  Widget _buildStatsRow() {
    final l10n = AppLocalizations.of(context);
    final height = _parseDouble(_savedProfile['height']);
    final values = [
      (
        Icons.calendar_today_outlined,
        l10n.clientProfilStatSessions,
        '$_sessionsCount'
      ),
      (
        Icons.monitor_weight_outlined,
        l10n.clientProfilStatCurrentWeight,
        _weightStats.current == null
            ? '—'
            : l10n
                .clientProfilWeightValueKg(_weightStats.current!.toStringAsFixed(1))
      ),
      (
        Icons.height_rounded,
        l10n.clientProfilStatHeight,
        height == null
            ? '—'
            : l10n.clientProfilHeightValueCm(
                height.toStringAsFixed(height % 1 == 0 ? 0 : 1))
      ),
    ];
    return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
            children: values.indexed
                .map((entry) => Expanded(
                        child: Container(
                      margin: EdgeInsets.only(right: entry.$1 < 2 ? 10 : 0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 16),
                      decoration: BoxDecoration(
                          color: context.fitlek.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: context.fitlek.border)),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(entry.$2.$1,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 12),
                            FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(entry.$2.$3,
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface))),
                            const SizedBox(height: 5),
                            Text(entry.$2.$2,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: context.fitlek.textMuted)),
                          ]),
                    )))
                .toList()));
  }

  Widget _buildTabBar() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Container(
        height: 44,
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
          tabs: [
            Tab(text: l10n.clientProfilTabMyDetails),
            Tab(text: l10n.clientProfilTabMyProgress),
            Tab(text: l10n.clientProfilTabNutrition),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    final l10n = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        if (!_isEditing) {
          await Future.wait(
              [_fetchProfile(silent: true), _fetchWeightData()]);
        }
      },
      child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            NutritionGoalCard(clientID: widget.clientID, token: widget.token),
            if (_isEditing)
              Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                      l10n.clientProfilEditInstructions,
                      style: TextStyle(
                          color: context.fitlek.textSecondary,
                          fontSize: 12))),
            _profileGroup(
                l10n.clientProfilGroupAboutTitle,
                l10n.clientProfilGroupAboutSubtitle,
                [
                  _formRow(l10n.clientProfilFirstName, _firstNameCtrl,
                      Icons.person_outline_rounded,
                      fieldKey: 'First name'),
                  _formRow(l10n.clientProfilLastName, _lastNameCtrl,
                      Icons.person_outline_rounded,
                      fieldKey: 'Last name'),
                  _buildGenderSelector(),
                  _formRow(l10n.clientProfilHeightCm, _heightCtrl,
                      Icons.height_rounded,
                      fieldKey: 'Height (cm)',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true)),
                ]),
            const SizedBox(height: 16),
            _profileGroup(
                l10n.clientProfilGroupInterestsTitle,
                l10n.clientProfilGroupInterestsSubtitle,
                [_buildInterests()]),
            const SizedBox(height: 16),
            _profileGroup(
                l10n.clientProfilGroupAccountTitle,
                l10n.clientProfilGroupAccountSubtitle,
                [
                  _settingsRow(
                      Icons.mail_outline_rounded,
                      l10n.clientProfilEmailAddress,
                      _emailCtrl.text.isEmpty
                          ? l10n.clientProfilAddEmail
                          : _emailCtrl.text,
                      _changeEmail),
                  _settingsRow(
                      Icons.phone_outlined,
                      l10n.clientProfilPhoneNumber,
                      _phone.isEmpty ? l10n.clientProfilAddPhone : _phone,
                      _changePhone),
                  _settingsRow(
                      Icons.location_on_outlined,
                      l10n.clientProfilMyLocation,
                      _city.isEmpty ? l10n.clientProfilSetCity : _city,
                      _changeLocation),
                ]),
            const SizedBox(height: 16),
            _profileGroup(
                l10n.clientProfilGroupSirvyaTitle,
                l10n.clientProfilGroupSirvyaSubtitle,
                [
                  _settingsRow(
                      Icons.favorite_border_rounded,
                      l10n.clientProfilFavoriteCoaches,
                      l10n.clientProfilFavoriteCoachesSubtitle,
                      _openFavorites),
                  _settingsRow(
                      Icons.notifications_none_rounded,
                      l10n.clientProfilNotifications,
                      l10n.clientProfilNotificationsSubtitle,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const ClientNotificationsScreen()))),
                  _settingsRow(
                      Icons.lock_outline_rounded,
                      l10n.clientProfilPasswordSecurity,
                      l10n.clientProfilPasswordSecuritySubtitle,
                      _showChangePasswordSheet),
                  _settingsRow(
                      Icons.block_outlined,
                      l10n.clientProfilBlockedAccounts,
                      l10n.clientProfilBlockedAccountsSubtitle,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  BlockedUsersList(token: widget.token)))),
                  const SizedBox(height: 10),
                  ThemeSelectorTile(
                      controller: ThemeControllerScope.of(context)),
                  _buildLanguageSelectorTile(),
                ]),
            const SizedBox(height: 22),
            OutlinedButton.icon(
                onPressed: _goToLogin,
                icon: Icon(Icons.logout_rounded,
                    color: context.fitlek.error, size: 18),
                label: Text(l10n.clientProfilLogOut,
                    style: TextStyle(color: context.fitlek.error)),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                        color: context.fitlek.error.withValues(alpha: .3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)))),
            TextButton(
                onPressed: _showDeleteAccountSheet,
                child: Text(l10n.clientProfilDeleteMyAccount,
                    style: TextStyle(
                        color: context.fitlek.textMuted, fontSize: 12))),
          ]),
    );
  }

  String _localeLabel(AppLocalizations l10n, Locale? loc) {
    if (loc == null) return l10n.languageSystem;
    switch (loc.languageCode) {
      case 'fr':
        return l10n.languageFrench;
      case 'en':
      default:
        return l10n.languageEnglish;
    }
  }

  Widget _buildLanguageSelectorTile() {
    final cs = Theme.of(context).colorScheme;
    final fitlek = context.fitlek;
    return ValueListenableBuilder<Locale?>(
      valueListenable: LocaleService.locale,
      builder: (context, currentLocale, _) {
        final l10n = AppLocalizations.of(context);
        return GestureDetector(
          onTap: () => _showLanguageSheet(context),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: fitlek.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: fitlek.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.language_rounded,
                      color: cs.primary, size: 15),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.language,
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _localeLabel(l10n, currentLocale),
                        style: TextStyle(color: fitlek.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: fitlek.textMuted, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fitlek = context.fitlek;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ValueListenableBuilder<Locale?>(
        valueListenable: LocaleService.locale,
        builder: (ctx, currentLocale, _) {
          final l10n = AppLocalizations.of(ctx);
          final options = <({Locale? locale, String label, IconData icon})>[
            (
              locale: null,
              label: l10n.languageSystem,
              icon: Icons.brightness_auto_rounded
            ),
            (
              locale: const Locale('en'),
              label: l10n.languageEnglish,
              icon: Icons.language_rounded
            ),
            (
              locale: const Locale('fr'),
              label: l10n.languageFrench,
              icon: Icons.translate_rounded
            ),
          ];

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: BoxDecoration(
              color: fitlek.card,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: fitlek.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.language,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                ...options.map((opt) {
                  final selected =
                      currentLocale?.languageCode == opt.locale?.languageCode;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () {
                        LocaleService.set(opt.locale);
                        Navigator.pop(ctx);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? cs.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? cs.primary : fitlek.border,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              opt.icon,
                              size: 18,
                              color: selected ? cs.primary : fitlek.textMuted,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                opt.label,
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                            if (selected)
                              Icon(Icons.check_circle_rounded,
                                  color: cs.primary, size: 18),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _profileGroup(String title, String subtitle, List<Widget> children) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: context.fitlek.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: context.fitlek.border)),
        child: Material(
            type: MaterialType.transparency,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 5),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: context.fitlek.textMuted)),
              const SizedBox(height: 14),
              ...children,
            ])),
      );

  Widget _settingsRow(
          IconData icon, String title, String subtitle, VoidCallback? onTap) =>
      ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
        minLeadingWidth: 30,
        leading: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: .07),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon,
                size: 19, color: Theme.of(context).colorScheme.primary)),
        title: Text(title,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface)),
        subtitle: Text(subtitle,
            style: TextStyle(
                fontSize: 11, height: 1.5, color: context.fitlek.textMuted)),
        trailing: onTap == null
            ? null
            : Icon(Icons.chevron_right_rounded,
                size: 20, color: context.fitlek.textMuted),
      );

  Widget _buildInterests() {
    final l10n = AppLocalizations.of(context);
    final catalog = <String, String>{
      for (final category in _categories)
        '${category['name']}': '${category['icon'] ?? 'fitness_center'}'
    };
    for (final interest in _interests) {
      catalog.putIfAbsent(interest, () => 'fitness_center');
    }
    if (!_isEditing && _interests.isEmpty) {
      return TextButton.icon(
          onPressed: () => _completeProfile('interests'),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(l10n.clientProfilChooseInterests));
    }
    if (_isEditing && catalog.isEmpty) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            l10n.clientProfilInterestsLoadFailed,
            style: TextStyle(color: context.fitlek.textMuted, fontSize: 12)),
        TextButton(
            onPressed: _fetchCategories, child: Text(l10n.clientProfilTryAgain))
      ]);
    }
    return Wrap(
        spacing: 8,
        runSpacing: 6,
        children: (_isEditing ? catalog.keys : _interests).map((name) {
          final selected = _interests.contains(name);
          if (!_isEditing) {
            return Chip(
              label: Text(name,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface)),
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: .08),
              side: BorderSide(color: context.fitlek.border),
              avatar: CategoryIcon(
                  name: catalog[name]!,
                  size: 17,
                  color: Theme.of(context).colorScheme.primary),
            );
          }
          return FilterChip(
              selectedColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: .14),
              labelStyle:
                  TextStyle(color: Theme.of(context).colorScheme.onSurface),
              label: Text(name, style: const TextStyle(fontSize: 12)),
              selected: selected,
              showCheckmark: false,
              avatar: CategoryIcon(
                  name: catalog[name]!,
                  size: 17,
                  color: Theme.of(context).colorScheme.primary),
              onSelected: !_isEditing
                  ? null
                  : (value) {
                      if (value && _interests.length >= 5) {
                        _showSnack(l10n.clientProfilMaxInterests);
                        return;
                      }
                      setState(() {
                        if (value) {
                          _interests.add(name);
                        } else {
                          _interests.remove(name);
                        }
                      });
                    });
        }).toList());
  }

  Widget _buildGenderSelector() {
    final l10n = AppLocalizations.of(context);
    if (!_isEditing) {
      return _settingsRow(Icons.wc_outlined, l10n.clientProfilGender,
          _genderDisplay(_selectedGender), null);
    }
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DropdownButtonFormField<String>(
          initialValue: ['Male', 'Female', 'Other'].contains(_selectedGender)
              ? _selectedGender
              : 'Other',
          decoration: InputDecoration(
              labelText: l10n.clientProfilGender,
              prefixIcon: const Icon(Icons.wc_outlined)),
          items: ['Male', 'Female', 'Other']
              .map((gender) => DropdownMenuItem(
                  value: gender, child: Text(_genderDisplay(gender))))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _selectedGender = value);
          },
        ));
  }

  Widget _formRow(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    String? fieldKey,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    final l10n = AppLocalizations.of(context);
    if (!_isEditing) {
      return _settingsRow(
          icon,
          label,
          ctrl.text.isEmpty ? l10n.clientProfilNotAddedYet : ctrl.text,
          null);
    }
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
                        key: ValueKey('client-profile-${fieldKey ?? label}'),
                        controller: ctrl,
                        keyboardType: keyboardType,
                        maxLines: maxLines,
                        readOnly: readOnly,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                    : Text(
                        ctrl.text.isEmpty
                            ? l10n.clientProfilNotAddedYet
                            : ctrl.text,
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

  Widget _buildProgressTab() => WeightProgressView(
        entries: _weightData,
        current: _weightStats.current,
        start: _weightStats.start,
        total: _weightStats.total,
        bmi: _calcBMI(),
        loading: _loadingWeight,
        error: _weightError,
        onRefresh: _fetchWeightData,
        onAdd: _addWeight,
      );
}

class _ClientProfileTabs extends SliverPersistentHeaderDelegate {
  final Widget child;
  final Color background;
  _ClientProfileTabs({required this.child, required this.background});
  @override
  double get minExtent => 68;
  @override
  double get maxExtent => 68;
  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      ColoredBox(color: background, child: child);
  @override
  bool shouldRebuild(covariant _ClientProfileTabs oldDelegate) =>
      oldDelegate.child != child || oldDelegate.background != background;
}
