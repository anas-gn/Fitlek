import 'dart:convert';
import 'package:fitlek1/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';

import '../../services/apiService.dart';
import '../../services/locale_service.dart';
import '../../components/theme_selector.dart';
import '../../services/theme_service.dart';
import '../../constants/app_colors.dart';
import '../../theme/fitlek_theme_extension.dart';
import 'coachProfile.dart' show CoachProfileData, ApiConfig;
import 'coachNotifications.dart';
import 'blockedUsersList.dart' hide ApiConfig;
import 'welcome.dart';
import 'coachChangeEmail.dart';
import 'coachChangePhone.dart';
import 'coachChangePassword.dart';
class CoachAccount extends StatefulWidget {
  final CoachProfileData profile;
  final String token;
  final VoidCallback? onLogout;

  const CoachAccount({
    super.key,
    required this.profile,
    required this.token,
    this.onLogout,
  });

  @override
  State<CoachAccount> createState() => _CoachAccountState();
}

class _CoachAccountState extends State<CoachAccount> {
  late bool _publicProfile;
  late String _email;
  late String _phone;

  @override
  void initState() {
    super.initState();
    _publicProfile = widget.profile.publicProfile;
    _email = widget.profile.email;
    _phone = widget.profile.tel;
  }

  Future<void> _togglePublicProfile(bool val) async {
    setState(() => _publicProfile = val);
    try {
      await http.put(
        Uri.parse('${ApiConfig.baseUrl}/coach/me/profile'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'publicProfile': val ? 1 : 0}),
      );
    } catch (e) {
      debugPrint('Failed to update publicProfile');
    }
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

  void _copyToClipboard(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    _showSnack(AppLocalizations.of(context).coachAccountCopiedToClipboard(label));
  }

  String _themeLabel(AppThemeMode mode) {
    final l10n = AppLocalizations.of(context);
    return switch (mode) {
      AppThemeMode.light => l10n.coachAccountThemeLight,
      AppThemeMode.dark => l10n.coachAccountThemeDark,
      AppThemeMode.system => l10n.coachAccountThemeSystem,
    };
  }

  String _currentLocaleLabel() {
    final l10n = AppLocalizations.of(context);
    final code = LocaleService.locale.value?.languageCode;
    if (code == 'en') return l10n.languageEnglish;
    if (code == 'fr') return l10n.languageFrench;
    return l10n.languageSystem;
  }

  void _showLanguageSheet() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ValueListenableBuilder<Locale?>(
        valueListenable: LocaleService.locale,
        builder: (ctx, currentLocale, _) {
          final l10n = AppLocalizations.of(ctx);
          final options = <(Locale?, String)>[
            (null, l10n.languageSystem),
            (const Locale('en'), l10n.languageEnglish),
            (const Locale('fr'), l10n.languageFrench),
          ];
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: BoxDecoration(
              color: f.card,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
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
                        color: f.border,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(l10n.language,
                    style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                ...options.map((opt) {
                  final selected =
                      currentLocale?.languageCode == opt.$1?.languageCode;
                  return GestureDetector(
                    onTap: () async {
                      await LocaleService.set(opt.$1);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? cs.primary.withValues(alpha: 0.1)
                            : f.card2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: selected
                                ? cs.primary.withValues(alpha: 0.4)
                                : f.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.language_rounded,
                              color: selected ? cs.primary : f.textMuted,
                              size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(opt.$2,
                                style: TextStyle(
                                    color: cs.onSurface,
                                    fontSize: 14,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500)),
                          ),
                          if (selected)
                            Icon(Icons.check_circle_rounded,
                                color: cs.primary, size: 20),
                        ],
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
          final l10n = AppLocalizations.of(ctx);
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
                setSheet(() { loading = false; errorMsg = body['reason'] as String? ?? l10n.coachAccountDeleteCannotNow; });
                return;
              }
              if (res.statusCode != 200) {
                setSheet(() { loading = false; errorMsg = body['error'] as String? ?? l10n.coachAccountDeleteSendCodeFailed; });
                return;
              }
              setSheet(() { loading = false; step = 2; otpValue = ''; errorMsg = null; });
              startCountdown();
            } catch (_) {
              setSheet(() { loading = false; errorMsg = l10n.coachAccountServerUnreachable; });
            }
          }

          Future<void> confirmDelete() async {
            if (otpValue.length != 6) {
              setSheet(() => errorMsg = l10n.coachAccountEnterFullCode);
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
                if (widget.onLogout != null) {
                  widget.onLogout!();
                }
                return;
              }
              setSheet(() { loading = false; errorMsg = body['error'] as String? ?? l10n.coachAccountVerificationFailed; });
            } catch (_) {
              setSheet(() { loading = false; errorMsg = l10n.coachAccountServerUnreachable; });
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
                    decoration: BoxDecoration(color: errorColor.withOpacity(0.12), shape: BoxShape.circle),
                    child: Icon(Icons.delete_forever_rounded, color: errorColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.coachAccountDeleteTitle, style: TextStyle(color: cs.onSurface, fontSize: 17, fontWeight: FontWeight.w800)),
                      Text(l10n.coachAccountDeletePermanentSubtitle, style: TextStyle(color: textMuted, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: errorColor.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: errorColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.coachAccountDeleteWhatWillBeDeleted, style: TextStyle(color: errorColor, fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ...[
                      l10n.coachAccountDeleteItem1,
                      l10n.coachAccountDeleteItem2,
                      l10n.coachAccountDeleteItem3,
                      l10n.coachAccountDeleteItem4,
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
                        l10n.coachAccountDeleteUnderstandCheckbox,
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
                  decoration: BoxDecoration(color: errorColor.withOpacity(0.07), borderRadius: BorderRadius.circular(8)),
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
                        child: Center(child: Text(l10n.coachAccountCancel,
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
                          color: understood ? errorColor : errorColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: loading
                              ? const SizedBox(width: 18, height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(l10n.coachAccountDeleteSendCodeButton,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.8)),
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
                      decoration: BoxDecoration(color: errorColor.withOpacity(0.12), shape: BoxShape.circle),
                      child: Icon(Icons.mark_email_read_rounded, color: errorColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.coachAccountDeleteVerifyTitle, style: TextStyle(color: cs.onSurface, fontSize: 17, fontWeight: FontWeight.w800)),
                        Text(l10n.coachAccountDeleteCheckEmailSubtitle, style: TextStyle(color: textMuted, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(l10n.coachAccountDeleteEnterCodeInstructions,
                  style: TextStyle(color: textMuted, fontSize: 13, height: 1.5)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: errorColor.withOpacity(0.4), width: 1.5),
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
                      Text(l10n.coachAccountDeleteCodeExpiresIn(mins, secs), style: TextStyle(color: textMuted, fontSize: 12))
                    else
                      Text(l10n.coachAccountDeleteCodeExpired, style: TextStyle(color: errorColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    GestureDetector(
                      onTap: canResend && !loading ? requestOtp : null,
                      child: Text(l10n.coachAccountDeleteResendCode, style: TextStyle(
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
                    decoration: BoxDecoration(color: errorColor.withOpacity(0.07), borderRadius: BorderRadius.circular(8)),
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
                          child: Center(child: Text(l10n.coachAccountBack,
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
                            color: otpValue.length == 6 ? errorColor : errorColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: loading
                                ? const SizedBox(width: 18, height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(l10n.coachAccountDeleteConfirmButton,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
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

  void _showThemeSheet(ThemeController controller) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final l10n = AppLocalizations.of(context);
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
              Text(l10n.coachAccountAppearance, style: TextStyle(color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(l10n.coachAccountChooseAppTheme, style: TextStyle(color: f.textMuted, fontSize: 12)),
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
                      color: selected ? cs.primary.withOpacity(0.1) : f.card2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? cs.primary.withOpacity(0.4) : f.border),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: selected ? cs.primary : f.textMuted, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_themeLabel(mode),
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

  void _showQrDialog(String code) {
    final l10n = AppLocalizations.of(context);
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
              Text(l10n.coachAccountScanToInvite,
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
                  _copyToClipboard(code, l10n.coachAccountCode);
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(14)),
                  child: Center(
                    child: Text(l10n.coachAccountCopyCode,
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

  Widget _buildReferralCard(CoachProfileData p) {
    final l10n = AppLocalizations.of(context);
    final code = p.invitationCode.isNotEmpty ? p.invitationCode : '—';
    const onDark = AppColors.sand;
    final onDarkMuted = AppColors.sand.withOpacity(0.62);
    final accent = context.fitlek.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cyprus, AppColors.primaryDim],
        ),
        boxShadow: [BoxShadow(color: AppColors.cyprus.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.coachAccountReferralTitle,
                    style: const TextStyle(color: onDark, fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.sand.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.monetization_on_rounded, size: 14, color: accent),
                  const SizedBox(width: 5),
                  Text('${p.earnedPoints}', style: const TextStyle(color: onDark, fontSize: 12.5, fontWeight: FontWeight.w800)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(l10n.coachAccountReferralSubtitle, style: TextStyle(color: accent, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.sand.withOpacity(0.14)),
            ),
            child: Row(
              children: [
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
                  onTap: () => _copyToClipboard(p.invitationCode, l10n.coachAccountCode),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(color: onDark, borderRadius: BorderRadius.circular(10)),
                    child: Text(l10n.coachAccountCopy, style: const TextStyle(color: AppColors.cyprus, fontSize: 13, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.coachAccountReferralRewardDesc(p.referralReward),
            style: TextStyle(color: onDarkMuted, fontSize: 11.5, height: 1.5, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _settingsDivider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Divider(height: 1, thickness: 1, color: context.fitlek.border.withOpacity(0.6)),
      );

  Widget _settingsRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    Color? labelColor,
    String? value,
    String? subtitle,
    String? trailingText,
    Widget? trailingWidget,
    bool showChevron = true,
    VoidCallback? onTap,
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
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(label,
                          style: TextStyle(color: labelColor ?? cs.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
                      if (value != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: f.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: f.textMuted, fontSize: 11, height: 1.3)),
                  ],
                ],
              ),
            ),
            if (trailingText != null) ...[
              const SizedBox(width: 8),
              Text(trailingText, style: TextStyle(color: f.textMuted, fontSize: 12.5, fontWeight: FontWeight.w500)),
            ],
            if (trailingWidget != null) ...[
              const SizedBox(width: 8),
              trailingWidget,
            ],
            if (showChevron) ...[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: f.textMuted, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final f = context.fitlek;
    final cs = Theme.of(context).colorScheme;
    final controller = ThemeControllerScope.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F261F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.coachAccountTitle, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildReferralCard(widget.profile),
            Container(
              decoration: BoxDecoration(
                color: f.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: f.border),
              ),
              child: Column(
                children: [
                  _settingsRow(
                    icon: Icons.lock_outline_rounded,
                    iconColor: cs.primary,
                    label: l10n.coachAccountPrivateAccount,
                    showChevron: false,
                    trailingWidget: Transform.scale(
                      scale: 0.9,
                      child: Switch(
                        value: !_publicProfile,
                        onChanged: (val) => _togglePublicProfile(!val),
                        activeColor: Colors.white,
                        activeTrackColor: cs.primary,
                        inactiveThumbColor: Colors.white70,
                        inactiveTrackColor: f.border,
                        trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
                      ),
                    ),
                    onTap: () => _togglePublicProfile(_publicProfile),
                  ),
                  _settingsDivider(),
                  _settingsRow(
                    icon: Icons.mail_outline_rounded,
                    iconColor: cs.primary,
                    label: l10n.coachAccountEmail,
                    value: _email,
                    subtitle: l10n.coachAccountChangeEmailSubtitle,
                    onTap: () async {
                      final newEmail = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CoachChangeEmail(token: widget.token)),
                      );
                      if (newEmail != null && newEmail is String) {
                        setState(() => _email = newEmail);
                        _showSnack(l10n.coachAccountEmailUpdated);
                      }
                    },
                  ),
                  _settingsDivider(),
                  _settingsRow(
                    icon: Icons.phone_outlined,
                    iconColor: cs.primary,
                    label: l10n.coachAccountPhone,
                    value: _phone,
                    onTap: () async {
                      final newPhoneStr = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CoachChangePhone(token: widget.token, currentPhone: _phone)),
                      );
                      if (newPhoneStr != null && newPhoneStr is String) {
                        setState(() => _phone = newPhoneStr);
                        _showSnack(l10n.coachAccountPhoneUpdated);
                      }
                    },
                  ),
                  _settingsDivider(),
                  _settingsRow(
                    icon: Icons.security_rounded,
                    iconColor: cs.primary,
                    label: l10n.coachAccountPasswordSecurity,
                    onTap: () async {
                      final success = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CoachChangePassword(token: widget.token)),
                      );
                      if (success == true) {
                        _showSnack(l10n.coachAccountPasswordUpdated);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
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
                      label: l10n.coachAccountAppearance,
                      trailingText: _themeLabel(controller.mode),
                      onTap: () => _showThemeSheet(controller),
                    ),
                  ),
                  _settingsDivider(),
                  ValueListenableBuilder<Locale?>(
                    valueListenable: LocaleService.locale,
                    builder: (context, _, __) => _settingsRow(
                      icon: Icons.language_rounded,
                      iconColor: cs.primary,
                      label: l10n.language,
                      trailingText: _currentLocaleLabel(),
                      onTap: _showLanguageSheet,
                    ),
                  ),
                  _settingsDivider(),
                  _settingsRow(
                    icon: Icons.notifications_none_rounded,
                    iconColor: cs.primary,
                    label: l10n.coachAccountNotifications,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CoachNotifications()),
                      );
                    },
                  ),
                  _settingsDivider(),
                  _settingsRow(
                    icon: Icons.block_rounded,
                    iconColor: cs.primary,
                    label: l10n.coachAccountBlockedUsers,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BlockedUsersList(token: widget.token)),
                      );
                    },
                  ),

                  _settingsDivider(),
                  _settingsRow(
                    icon: Icons.delete_forever_rounded,
                    iconColor: f.textMuted,
                    label: l10n.coachAccountDeleteAccount,
                    labelColor: f.textMuted,
                    showChevron: false,
                    onTap: _showDeleteAccountSheet,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
