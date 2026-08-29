import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/urls.dart';

/// Wraps [child] and silently checks for app updates in the background.
/// No loading spinner is shown — the check runs after the UI is already
/// displayed. Only if an update is required/available is a dialog shown.
class AppVersionChecker extends StatefulWidget {
  final Widget child;

  const AppVersionChecker({super.key, required this.child});

  @override
  State<AppVersionChecker> createState() => _AppVersionCheckerState();
}

class _AppVersionCheckerState extends State<AppVersionChecker> {
  @override
  void initState() {
    super.initState();
    // Delay slightly so the first frame is rendered before we hit the network.
    Future.delayed(const Duration(seconds: 2), _checkVersionInBackground);
  }

  Future<void> _checkVersionInBackground() async {
    // Version checking is only applicable to mobile (Android/iOS).
    if (kIsWeb || !mounted) return;

    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;
      final String platform = Platform.isIOS ? 'ios' : 'android';

      final response = await http
          .get(Uri.parse('$baseUrl/app-version?platform=$platform'))
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final versionInfo = data['data'];
          final String latestVersion = versionInfo['latest_version'];
          final String minRequiredVersion = versionInfo['min_required_version'];
          final String storeUrl = versionInfo['store_url'];

          if (_isUpdateRequired(currentVersion, minRequiredVersion)) {
            _showUpdateDialog(storeUrl, force: true);
          } else if (_isUpdateRequired(currentVersion, latestVersion)) {
            _showUpdateDialog(storeUrl, force: false);
          }
        }
      }
    } catch (e) {
      // Silently ignore — network errors should never affect the user experience.
      debugPrint('Background version check failed (non-critical): $e');
    }
  }

  bool _isUpdateRequired(String currentVersion, String requiredVersion) {
    final currentParts = currentVersion.split('.').map(int.parse).toList();
    final requiredParts = requiredVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < requiredParts.length; i++) {
      if (i >= currentParts.length) return true;
      if (requiredParts[i] > currentParts[i]) return true;
      if (requiredParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  void _showUpdateDialog(String storeUrl, {required bool force}) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: !force,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: !force,
          child: AlertDialog(
            title: Text(force ? 'Update Required' : 'Update Available'),
            content: Text(
              force
                  ? 'A new version of the app is required to continue. Please update to the latest version.'
                  : 'A new version of the app is available. Would you like to update now?',
            ),
            actions: [
              if (!force)
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Later'),
                ),
              ElevatedButton(
                onPressed: () async {
                  final uri = Uri.parse(storeUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text('Update Now'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Always show the child immediately — no blocking spinner.
    return widget.child;
  }
}
