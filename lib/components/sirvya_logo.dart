import 'package:flutter/material.dart';

/// The two ways the SIRVYA brand is displayed.
enum SirvyaLogoVariant {
  /// The "S" symbol only (square).
  mark,

  /// The "S" symbol followed by the `SIRVYA` wordmark.
  wordmark,
}

/// The single source of truth for the SIRVYA brand logo across the app.
///
/// * `wordmark` uses the pre-rendered raster assets:
///   - `assets/branding/logo_light.png` — light theme.
///   - `assets/branding/logo_dark.png`  — dark theme.
/// * `mark` uses the recolorable PNG symbol only
///   (`assets/branding/icon_app.png`).
///
/// Coloring:
/// * Provide [color] to force a color (e.g. white over a dark photo) —
///   this only affects the `mark` variant, since the wordmark PNGs are
///   pre-colored per theme.
/// * Otherwise the logo follows the theme automatically.
class SirvyaLogo extends StatelessWidget {
  static const String _lightAsset = 'assets/branding/logo_light.png';
  static const String _darkAsset = 'assets/branding/logo_dark.png';
  static const String _markAsset = 'assets/branding/icon_app.png';

  final SirvyaLogoVariant variant;

  /// Overall height of the artwork in logical pixels.
  final double height;

  /// Optional fixed width. When null, width follows the content's natural ratio.
  final double? width;

  /// Explicit color override (applies to the `mark` variant only).
  final Color? color;

  /// Accessibility label announced by screen readers.
  final String? semanticLabel;

  const SirvyaLogo({
    super.key,
    this.variant = SirvyaLogoVariant.wordmark,
    this.height = 60,
    this.width,
    this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = switch (variant) {
      SirvyaLogoVariant.mark => _buildMark(context),
      SirvyaLogoVariant.wordmark => _buildWordmark(context),
    };

    final wrapped =
        width != null ? SizedBox(width: width, child: content) : content;

    return Semantics(
      label: semanticLabel ?? 'SIRVYA',
      image: true,
      child: ExcludeSemantics(child: wrapped),
    );
  }

  /// The "S" symbol only, as a tintable PNG. Width follows the natural
  /// aspect ratio (no forced square) so it never looks squeezed.
  Widget _buildMark(BuildContext context) {
    final resolved = color ?? Theme.of(context).colorScheme.primary;
    return Image.asset(
      _markAsset,
      height: height,
      color: resolved,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _placeholder(context),
    );
  }

  /// The full "SIRVYA" wordmark, as a pre-rendered themed PNG.
  Widget _buildWordmark(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      isDark ? _darkAsset : _lightAsset,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _placeholder(context),
    );
  }

  /// Fallback placeholder when an asset fails to load.
  Widget _placeholder(BuildContext context) {
    return Container(
      height: height,
      width: height,
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'S',
          style: TextStyle(
            color: color ?? Theme.of(context).colorScheme.primary,
            fontSize: height * 0.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}