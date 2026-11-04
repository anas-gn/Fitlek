import 'package:flutter/material.dart';
import '../theme/fitlek_theme_extension.dart';

class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final bool compact;
  const NotificationCard(
      {super.key,
      required this.item,
      required this.onTap,
      this.compact = false});

  static bool unread(Map<String, dynamic> item) =>
      item['isRead'] != 1 && item['isRead'] != true && item['isRead'] != '1';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final fresh = unread(item);
    final type = '${item['type'] ?? ''}';
    final (icon, label, accent) = type.startsWith('nutrition_')
        ? (Icons.restaurant_outlined, 'YOUR NUTRITION', f.success)
        : type.startsWith('price_')
            ? (Icons.payments_outlined, 'PRICING', f.warning)
            : type.contains('message')
                ? (Icons.chat_bubble_outline_rounded, 'MESSAGE', f.info)
                : type.contains('review')
                    ? (Icons.star_outline_rounded, 'FEEDBACK', f.warning)
                    : type.contains('reservation') || type.contains('session')
                        ? (
                            Icons.calendar_today_outlined,
                            'YOUR SESSIONS',
                            f.success
                          )
                        : type.contains('invitation')
                            ? (
                                Icons.people_outline_rounded,
                                'CONNECTIONS',
                                f.violet
                              )
                            : (
                                Icons.auto_awesome_outlined,
                                'SIRVYA UPDATE',
                                cs.primary
                              );
    return Padding(
        padding: EdgeInsets.only(bottom: compact ? 0 : 12),
        child: Material(
            color: f.card,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: fresh
                                ? accent.withValues(alpha: .32)
                                : f.border),
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accent.withValues(alpha: fresh ? .08 : .025),
                              Colors.transparent
                            ])),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                  color: accent.withValues(alpha: .11),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                      color: accent.withValues(alpha: .12))),
                              child: Icon(icon, color: accent, size: 22)),
                          const SizedBox(width: 13),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Row(children: [
                                  Expanded(
                                      child: Text(label,
                                          style: TextStyle(
                                              color: accent,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.3))),
                                  if (fresh)
                                    Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                            color: accent,
                                            shape: BoxShape.circle)),
                                ]),
                                const SizedBox(height: 7),
                                Text('${item['title'] ?? 'Sirvya'}',
                                    maxLines: compact ? 1 : 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: cs.onSurface,
                                        fontSize: 14,
                                        fontWeight: fresh
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        height: 1.3)),
                                if ('${item['body'] ?? ''}'.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text('${item['body']}',
                                      maxLines: compact ? 2 : 5,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: f.textSecondary,
                                          fontSize: 12,
                                          height: 1.5)),
                                ],
                                if (!compact) ...[
                                  const SizedBox(height: 13),
                                  Row(children: [
                                    Expanded(
                                        child: Text(_time(item['createdAt']),
                                            style: TextStyle(
                                                color: f.textMuted,
                                                fontSize: 10))),
                                    Text('View',
                                        style: TextStyle(
                                            color: cs.primary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 5),
                                    Icon(Icons.arrow_forward_rounded,
                                        color: cs.primary, size: 14),
                                  ]),
                                ],
                              ])),
                        ])))));
  }

  String _time(dynamic value) {
    final date = DateTime.tryParse('$value')?.toLocal();
    if (date == null) return '';
    final age = DateTime.now().difference(date);
    if (age.inMinutes < 1) return 'Just now';
    if (age.inMinutes < 60) return '${age.inMinutes} min ago';
    if (age.inHours < 24) return '${age.inHours} hours ago';
    if (age.inDays == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class NotificationInboxIntro extends StatelessWidget {
  final int unreadCount;
  const NotificationInboxIntro({super.key, required this.unreadCount});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Your latest updates',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.6)),
          const SizedBox(height: 5),
          Text(
              unreadCount == 0
                  ? 'You’re all caught up.'
                  : '$unreadCount unread · Keep your journey moving.',
              style: TextStyle(color: context.fitlek.textMuted, fontSize: 12)),
        ])),
      ]));
}
