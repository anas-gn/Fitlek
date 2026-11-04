import 'package:flutter/material.dart';
import '../services/app_version_policy.dart';
import '../theme/fitlek_theme_extension.dart';

class AppUpdatePrompt extends StatefulWidget {
  final AppVersionCheck check;
  final bool mandatory;
  final Future<bool> Function(Uri) openStore;
  final Future<void> Function()? recheck;
  final VoidCallback? dismiss;
  const AppUpdatePrompt(
      {super.key,
      required this.check,
      required this.mandatory,
      required this.openStore,
      this.recheck,
      this.dismiss});
  @override
  State<AppUpdatePrompt> createState() => _AppUpdatePromptState();
}

class _AppUpdatePromptState extends State<AppUpdatePrompt> {
  bool _opening = false, _checking = false;
  String? _error;
  Future<void> _update() async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final uri = Uri.tryParse(widget.check.policy.storeUrl);
      if (uri?.host == 'apps.apple.com' &&
          !RegExp(r'/id[1-9]\d*(?:/|$)').hasMatch(uri!.path)) {
        throw const FormatException(
            'The update link is not configured yet. Please contact Sirvya support.');
      }
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty ||
          !await widget.openStore(uri)) {
        throw StateError('Store unavailable');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error is FormatException
            ? error.message
            : 'Could not open the store. Please try again or check for the update in your app store.');
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _recheck() async {
    if (_checking || widget.recheck == null) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      await widget.recheck!();
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme, f = context.fitlek;
    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      decoration: BoxDecoration(
          color: f.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: f.border),
          boxShadow: [
            BoxShadow(
                color: f.shadow, blurRadius: 36, offset: const Offset(0, 14))
          ]),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 26),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [cs.primary.withValues(alpha: 0.16), f.card2])),
            child: Center(
                child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                        color: f.card, borderRadius: BorderRadius.circular(22)),
                    child: Icon(Icons.system_update_rounded,
                        size: 36, color: cs.primary)))),
        Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.mandatory ? 'UPDATE REQUIRED' : 'NEW VERSION',
                      style: TextStyle(
                          color: cs.primary,
                          fontSize: 10,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Text(
                      widget.mandatory
                          ? 'Update Sirvya to continue'
                          : 'A fresh version of Sirvya',
                      style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 25,
                          height: 1.15,
                          letterSpacing: -0.5,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Text(
                      widget.mandatory
                          ? 'This version is no longer supported. Install the latest version to keep using the app.'
                          : 'The latest version is ready. Update now for the latest improvements.',
                      style: TextStyle(
                          color: f.textSecondary, fontSize: 14, height: 1.5)),
                  const SizedBox(height: 20),
                  Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: f.card2,
                          borderRadius: BorderRadius.circular(14)),
                      child: Wrap(spacing: 14, runSpacing: 8, children: [
                        Text('Installed ${widget.check.installedVersion}',
                            style: TextStyle(
                                color: f.textSecondary, fontSize: 12)),
                        Text('Minimum ${widget.check.policy.minimumVersion}',
                            style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ])),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Semantics(
                        liveRegion: true,
                        child: Text(_error!,
                            style: TextStyle(color: cs.error, height: 1.4))),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                          onPressed: _opening ? null : _update,
                          icon: _opening
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.open_in_new_rounded, size: 18),
                          label: Text(
                              _opening ? 'Opening the store…' : 'Update now'))),
                  if (widget.mandatory && widget.recheck != null)
                    Center(
                        child: TextButton(
                            onPressed: _checking ? null : _recheck,
                            child:
                                Text(_checking ? 'Checking…' : 'Check again'))),
                  if (!widget.mandatory)
                    Center(
                        child: TextButton(
                            onPressed: widget.dismiss,
                            child: const Text('Later'))),
                ])),
      ])),
    );
  }
}
