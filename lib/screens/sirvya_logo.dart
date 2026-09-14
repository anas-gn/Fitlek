import 'dart:async';
import 'package:flutter/material.dart';
import '../../components/sirvya_logo.dart';
import 'workout_webview.dart';
import '../../constants/app_colors.dart';
import '../../theme/fitlek_theme_extension.dart';

/// Clickable SIRVYA logo placed in the client home header. By default a tap opens the
/// openGym workout WebView (`WorkoutWebviewScreen`) in a full-screen push — the logo is
/// the app's entry point into the embedded workout experience. Pass a custom `onTap` to
/// override that behaviour (e.g. a wrapped screen that needs its own context first).
class WorkoutLogo extends StatelessWidget {
  final SirvyaLogoVariant variant;

  /// Overall height of the artwork in logical pixels.
  final double height;

  /// Optional tap handler. When null the widget pushes `WorkoutWebviewScreen`.
  final VoidCallback? onTap;

  const WorkoutLogo({
    super.key,
    this.variant = SirvyaLogoVariant.wordmark,
    this.height = 18,
    this.onTap,
  });

  void _openWorkout(BuildContext context) {
    if (onTap != null) return onTap!();
    unawaited(Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WorkoutWebviewScreen()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: GestureDetector(
        onTap: () => _openWorkout(context),
        behavior: HitTestBehavior.opaque,
        child: SirvyaLogo(variant: variant, height: height),
      ),
    );
  }
}