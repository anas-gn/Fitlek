import 'package:flutter/material.dart';
import '../../constants/names.dart';

import '../../theme/fitlek_theme_extension.dart';
class ManagerHeader extends StatelessWidget {
  final String managerName;
  final String avatarUrl;
  final VoidCallback? onNotificationTap;

  const ManagerHeader({
    super.key,
    required this.managerName,
    required this.avatarUrl,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: context.fitlek.card,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: context.fitlek.card2,
                  child: Icon(Icons.manage_accounts_rounded,
                      color: Theme.of(context).colorScheme.primary, size: 22),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppNames.appName,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3,
                ),
              ),
              Text(
                managerName,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), width: 1),
            ),
            child: Text(
              'MANAGER',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onNotificationTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.fitlek.card2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: context.fitlek.border, width: 1),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.notifications_outlined,
                      color: Theme.of(context).colorScheme.onSurface, size: 20),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
