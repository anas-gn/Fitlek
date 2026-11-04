import 'dart:async';
import 'package:flutter/material.dart';
import '../services/connection_recovery.dart';
import '../services/socketService.dart';
import 'app_dialog.dart';

class ConnectionRecoveryPrompt extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final bool enabled;
  const ConnectionRecoveryPrompt(
      {super.key,
      required this.child,
      required this.navigatorKey,
      this.enabled = true});

  @override
  State<ConnectionRecoveryPrompt> createState() =>
      _ConnectionRecoveryPromptState();
}

class _ConnectionRecoveryPromptState extends State<ConnectionRecoveryPrompt> {
  bool _showing = false;
  DateTime? _dismissedAt;

  @override
  void initState() {
    super.initState();
    ConnectionRecovery.failure.addListener(_schedule);
    _schedule();
  }

  @override
  void didUpdateWidget(covariant ConnectionRecoveryPrompt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) _schedule();
  }

  void _schedule() {
    if (!mounted ||
        !widget.enabled ||
        _showing ||
        ConnectionRecovery.failure.value == null) {
      return;
    }
    if (_dismissedAt != null &&
        DateTime.now().difference(_dismissedAt!) <
            const Duration(seconds: 20)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _show());
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _show() async {
    if (!mounted ||
        !widget.enabled ||
        _showing ||
        ConnectionRecovery.failure.value == null) {
      return;
    }
    final overlay = widget.navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    _showing = true;
    try {
      final retry = await showDialog<bool>(
        context: overlay.context,
        builder: (context) => AppDialog(
          icon: Icon(Icons.wifi_off_rounded,
              color: Theme.of(context).colorScheme.primary),
          title: const Text('Check your connection'),
          content: const Text(ConnectionRecovery.message),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Later')),
            FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh app')),
          ],
        ),
      );
      if (!mounted) return;
      _dismissedAt = DateTime.now();
      ConnectionRecovery.failure.value = null;
      if (retry == true) {
        unawaited(SocketService().connect());
        ConnectionRecovery.refreshApp();
      }
    } finally {
      _showing = false;
    }
  }

  @override
  void dispose() {
    ConnectionRecovery.failure.removeListener(_schedule);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
