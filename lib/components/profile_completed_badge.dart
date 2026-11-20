import 'package:flutter/material.dart';
import 'package:fitlek1/l10n/app_localizations.dart';
import '../theme/fitlek_theme_extension.dart';

class ProfileCompletedBadge extends StatelessWidget {
  const ProfileCompletedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final success = context.fitlek.success;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.profileCompletedBadgeLabel,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: success.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: success.withValues(alpha: .3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle_outline_rounded, size: 18, color: success),
          const SizedBox(width: 7),
          Flexible(
              child: Text(l10n.profileCompletedBadgeLabel,
                  style: TextStyle(
                      color: success,
                      fontSize: 12,
                      fontWeight: FontWeight.w700))),
        ]),
      ),
    );
  }
}
