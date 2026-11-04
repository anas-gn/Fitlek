import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_version_policy.dart';
import 'app_update_prompt.dart';

/// An application-wide gate. Place above the Navigator in MaterialApp.builder.
class AppVersionChecker extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState>? navigatorKey;
  final Future<AppVersionCheck?> Function()? load;
  final Future<bool> Function(Uri)? openStore;
  final bool showPrompts;
  const AppVersionChecker(
      {super.key,
      required this.child,
      this.navigatorKey,
      this.load,
      this.showPrompts = true,
      this.openStore});
  @override
  State<AppVersionChecker> createState() => _AppVersionCheckerState();
}

class _AppVersionCheckerState extends State<AppVersionChecker>
    with WidgetsBindingObserver {
  AppVersionCheck? _check;
  Timer? _timer;
  bool _busy = false, _dialogShowing = false;
  String? _dismissedVersion;
  bool get _enabled =>
      widget.load != null ||
      (!kIsWeb &&
          [TargetPlatform.android, TargetPlatform.iOS]
              .contains(defaultTargetPlatform));
  bool get _blocked => _check?.required == true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
      _timer = Timer.periodic(const Duration(minutes: 5), (_) {
        if (WidgetsBinding.instance.lifecycleState ==
            AppLifecycleState.resumed) {
          _refresh();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant AppVersionChecker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showPrompts && !oldWidget.showPrompts) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _offerUpdate());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_enabled && state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_busy || !mounted) return;
    _busy = true;
    try {
      final result =
          await (widget.load?.call() ?? AppVersionRepository.check());
      if (!mounted) return;
      // A failed check cannot dismiss an already-known required update.
      setState(() {
        if (result != null) _check = result;
      });
      if (!_blocked && _check?.available == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _offerUpdate());
      }
    } catch (error) {
      debugPrint('App version check failed: $error');
    } finally {
      _busy = false;
    }
  }

  Future<bool> _openStore(Uri uri) =>
      widget.openStore?.call(uri) ??
      launchUrl(uri, mode: LaunchMode.externalApplication);

  Future<void> _offerUpdate() async {
    if (!mounted ||
        !widget.showPrompts ||
        _blocked ||
        _dialogShowing ||
        _check == null ||
        !_check!.available ||
        _dismissedVersion == _check!.policy.latestVersion) {
      return;
    }
    final navigator =
        widget.navigatorKey?.currentState ?? Navigator.maybeOf(context);
    final overlay = navigator?.overlay;
    if (overlay == null) return;
    final offer = _check!;
    _dialogShowing = true;
    try {
      await showDialog<void>(
          context: overlay.context,
          builder: (dialogContext) => Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                insetPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: AppUpdatePrompt(
                    check: offer,
                    mandatory: false,
                    openStore: _openStore,
                    dismiss: () => Navigator.of(dialogContext).pop()),
              ));
      _dismissedVersion = offer.policy.latestVersion;
    } finally {
      _dialogShowing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.showPrompts && _blocked;
    return Stack(fit: StackFit.expand, children: [
      ExcludeSemantics(
          excluding: locked,
          child: ExcludeFocus(
              excluding: locked,
              child: AbsorbPointer(
                  absorbing: locked,
                  child: TickerMode(enabled: !locked, child: widget.child)))),
      if (locked)
        Positioned.fill(
            child: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
              child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
                child: AppUpdatePrompt(
                    check: _check!,
                    mandatory: true,
                    openStore: _openStore,
                    recheck: _refresh)),
          )),
        )),
    ]);
  }
}
