import 'package:flutter/material.dart';
import '../../components/sirvya_logo.dart';
import '../../theme/fitlek_theme_extension.dart';

/// Coach Header — same visual structure and quality as the Client Header
/// (see `clientHome._buildHeader` / `AppHeader`): reusable Fitlek logo on the
/// left, coach identity + notification + avatar on the right.
///
/// All coach data is backend-driven (passed from the authenticated session in
/// `MainLayoutCoach`). Nothing here is hardcoded.
class CoachHeader extends StatelessWidget {
  final String coachName;
  final String avatarUrl;

  /// Used only for the avatar initial fallback when no avatar is available.
  final String? firstName;

  /// Real unread notifications count. A badge is shown only when this is > 0.
  final int unreadCount;

  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;

  const CoachHeader({
    super.key,
    required this.coachName,
    required this.avatarUrl,
    this.firstName,
    this.unreadCount = 0,
    this.onNotificationTap,
    this.onAvatarTap,
  });

  String get _initial {
    final source = (firstName != null && firstName!.trim().isNotEmpty)
        ? firstName!.trim()
        : coachName.trim();
    return source.isNotEmpty ? source[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final f = context.fitlek;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom:
              BorderSide(color: cs.primary.withValues(alpha: 0.12), width: 1),
        ),
      ),
      child: Row(
        children: [
          // ── Brand area (SIRVYA logo) ──
          const SirvyaLogo(variant: SirvyaLogoVariant.wordmark, height: 28),

          const Spacer(),

          // ── Notification button (real unread badge) ──
          _buildNotificationButton(context, cs, f),
          const SizedBox(width: 12),

          // ── Coach avatar (real backend photo) ──
          _buildAvatar(context, cs, f),
        ],
      ),
    );
  }

  Widget _buildNotificationButton(
      BuildContext context, ColorScheme cs, FitlekColors f) {
    return Semantics(
      button: true,
      label: unreadCount > 0
          ? 'Notifications, $unreadCount unread'
          : 'Notifications',
      child: GestureDetector(
        onTap: onNotificationTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: f.card2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: f.border.withValues(alpha: 0.6), width: 1),
              ),
              child: Icon(Icons.notifications_outlined,
                  color: cs.primary, size: 20),
            ),
            // Real unread badge only — never a fake number.
            if (unreadCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(
                    color: f.error,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 1.5),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cs.onError,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, ColorScheme cs, FitlekColors f) {
    return Semantics(
      button: true,
      label: 'Open Coach Profile',
      child: GestureDetector(
        onTap: onAvatarTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: cs.primary, width: 2),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: f.card2,
                backgroundImage:
                    avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty
                    ? Text(
                        _initial,
                        style: TextStyle(
                          color: cs.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: f.success,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
