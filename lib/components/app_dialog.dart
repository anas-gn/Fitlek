import 'package:flutter/material.dart';
import '../theme/fitlek_theme_extension.dart';

/// Consistent, scrollable presentation for input and confirmation dialogs.
class AppDialog extends StatelessWidget {
  final Widget? title, content, icon;
  final List<Widget>? actions;
  final Color? backgroundColor, surfaceTintColor;
  final ShapeBorder? shape;
  final EdgeInsetsGeometry? titlePadding, contentPadding, actionsPadding;
  final EdgeInsets insetPadding;
  final bool scrollable;
  final double? elevation;
  final MainAxisAlignment? actionsAlignment;
  const AppDialog(
      {super.key,
      this.title,
      this.content,
      this.actions,
      this.icon,
      this.backgroundColor,
      this.surfaceTintColor,
      this.shape,
      this.titlePadding,
      this.contentPadding,
      this.actionsPadding,
      this.elevation,
      this.actionsAlignment,
      this.insetPadding =
          const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      this.scrollable = true});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<FitlekColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? FitlekColors.dark
            : FitlekColors.light);
    return AlertDialog(
      backgroundColor: backgroundColor ?? colors.card,
      surfaceTintColor: surfaceTintColor ?? Colors.transparent,
      shape: shape ??
          RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
              side: BorderSide(color: cs.primary.withValues(alpha: .18))),
      elevation: elevation ?? 18,
      insetPadding: insetPadding,
      scrollable: scrollable,
      titlePadding: titlePadding ?? const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding:
          contentPadding ?? const EdgeInsets.fromLTRB(24, 20, 24, 12),
      actionsPadding:
          actionsPadding ?? const EdgeInsets.fromLTRB(16, 8, 16, 20),
      actionsAlignment: actionsAlignment ?? MainAxisAlignment.end,
      title: title == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                              color: cs.primary.withValues(alpha: .16))),
                      child: icon ??
                          Icon(Icons.info_outline_rounded,
                              color: cs.primary, size: 20)),
                  const SizedBox(width: 12),
                  Text('SIRVYA',
                      style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2)),
                  const SizedBox(width: 12),
                  Expanded(child: Divider(color: colors.border)),
                ]),
                const SizedBox(height: 19),
                DefaultTextStyle.merge(
                    style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.5,
                        height: 1.2),
                    child: title!),
              ],
            ),
      content: content == null
          ? null
          : DefaultTextStyle.merge(
              style: TextStyle(
                  color: colors.textSecondary, fontSize: 14, height: 1.55),
              child: content!),
      actions: actions,
    );
  }
}
