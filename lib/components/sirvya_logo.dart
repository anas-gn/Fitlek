import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The two ways the SIRVYA brand is displayed.
enum SirvyaLogoVariant {
  /// The "S" symbol only (square).
  mark,

  /// The "S" symbol followed by the `SIRVYA` wordmark.
  wordmark,
}

/// The single source of truth for the SIRVYA brand logo across the app.
///
/// The mark is a recolorable monochrome SVG (`assets/branding/sirvya_mark.svg`)
/// and the wordmark text is rendered with Flutter typography so it stays crisp
/// and theme-accurate at every size.
///
/// Coloring:
/// * Provide [color] to force a color (e.g. `Sand`/white over a dark photo).
/// * Otherwise the logo follows the theme via `colorScheme.primary`
///   (Cyprus in light mode, Sand in dark mode).
class SirvyaLogo extends StatelessWidget {
  static const String _markAsset = 'assets/branding/sirvya_mark.svg';

  final SirvyaLogoVariant variant;

  /// Overall height of the artwork in logical pixels (drives the mark size and,
  /// for the wordmark, the text size and spacing).
  final double height;

  /// Optional fixed width. When null, width follows the content's natural ratio.
  final double? width;

  /// Explicit color override. When null the logo follows the current theme.
  final Color? color;

  /// Accessibility label announced by screen readers.
  final String? semanticLabel;

  const SirvyaLogo({
    super.key,
    this.variant = SirvyaLogoVariant.wordmark,
    this.height = 40,
    this.width,
    this.color,
    this.semanticLabel,
  });

  Color _resolveColor(BuildContext context) =>
      color ?? Theme.of(context).colorScheme.primary;

  @override
  Widget build(BuildContext context) {
    final resolved = _resolveColor(context);

    final Widget content = switch (variant) {
      SirvyaLogoVariant.mark => _buildMark(resolved),
      SirvyaLogoVariant.wordmark => _buildWordmark(resolved),
    };

    final wrapped =
        width != null ? SizedBox(width: width, child: content) : content;

    return Semantics(
      label: semanticLabel ?? 'SIRVYA',
      image: true,
      child: ExcludeSemantics(child: wrapped),
    );
  }

  Widget _buildMark(Color resolved) {
    return SvgPicture.asset(
      _markAsset,
      height: height,
      width: height,
      colorFilter: ColorFilter.mode(resolved, BlendMode.srcIn),
      fit: BoxFit.contain,
    );
  }

  Widget _buildWordmark(Color resolved) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildMark(resolved),
        SizedBox(width: height * 0.26),
        Text(
          'SIRVYA',
          style: TextStyle(
            fontSize: height * 0.60,
            fontWeight: FontWeight.w800,
            letterSpacing: height * 0.10,
            color: resolved,
            height: 1,
          ),
        ),
      ],
    );
  }
}
