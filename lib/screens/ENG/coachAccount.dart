import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';

import '../../services/apiService.dart';
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
    _showSnack('$label copied to clipboard');
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
                if (widget.onLogout != null) {
                  widget.onLogout!();
                }
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
                    decoration: BoxDecoration(color: errorColor.withOpacity(0.12), shape: BoxShape.circle),
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
                  color: errorColor.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: errorColor.withOpacity(0.2)),
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
                          color: understood ? errorColor : errorColor.withOpacity(0.3),
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
                      decoration: BoxDecoration(color: errorColor.withOpacity(0.12), shape: BoxShape.circle),
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
                            color: otpValue.length == 6 ? errorColor : errorColor.withOpacity(0.3),
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
                      color: selected ? cs.primary.withOpacity(0.1) : f.card2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? cs.primary.withOpacity(0.4) : f.border),
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

  Widget _buildReferralCard(CoachProfileData p) {
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
              const Expanded(
                child: Text('Coach Referral',
                    style: TextStyle(color: onDark, fontSize: 18, fontWeight: FontWeight.w800)),
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
          Text('Invite friends and earn rewards', style: TextStyle(color: accent, fontSize: 12.5, fontWeight: FontWeight.w600)),
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

    return Scaffold(
      backgroundColor: const Color(0xFF0F261F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Account & referrals', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
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
                    label: 'Private account',
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
                    label: 'Email',
                    value: _email,
                    subtitle: 'Change email with verification.',
                    onTap: () async {
                      final newEmail = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CoachChangeEmail(token: widget.token)),
                      );
                      if (newEmail != null && newEmail is String) {
                        setState(() => _email = newEmail);
                        _showSnack('Email updated successfully');
                      }
                    },
                  ),
                  _settingsDivider(),
                  _settingsRow(
                    icon: Icons.phone_outlined,
                    iconColor: cs.primary,
                    label: 'Phone',
                    value: _phone,
                    onTap: () async {
                      final newPhoneStr = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CoachChangePhone(token: widget.token, currentPhone: _phone)),
                      );
                      if (newPhoneStr != null && newPhoneStr is String) {
                        setState(() => _phone = newPhoneStr);
                        _showSnack('Phone updated successfully');
                      }
                    },
                  ),
                  _settingsDivider(),
                  _settingsRow(
                    icon: Icons.security_rounded,
                    iconColor: cs.primary,
                    label: 'Password & security',
                    onTap: () async {
                      final success = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CoachChangePassword(token: widget.token)),
                      );
                      if (success == true) {
                        _showSnack('Password updated successfully');
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
                    icon: Icons.delete_forever_rounded,
                    iconColor: f.textMuted,
                    label: 'Delete Account',
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
