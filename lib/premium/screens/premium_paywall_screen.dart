import 'package:flutter/material.dart';
import '../../services/apiService.dart';
import 'premium_home_screen.dart';

class PremiumPaywallScreen extends StatefulWidget {
  final int clientID;

  const PremiumPaywallScreen({super.key, required this.clientID});

  @override
  State<PremiumPaywallScreen> createState() => _PremiumPaywallScreenState();
}
class _PremiumPaywallScreenState extends State<PremiumPaywallScreen> {
  bool _loading = true;
  bool _hasAccess = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final result = await ApiService.get('/premium/status');
    if (!mounted) return;
    if (result['ok'] != true && result['status'] == 404 && mounted) {
      // Backend predates the Premium API: it answers HTML 404 which the API
      // client surfaces as "Server error (404)...". Show the real meaning.
      ApiService.showError(
        context,
        'Premium is not available on this server yet. Please update the backend.',
      );
    }
    setState(() {
      _hasAccess = result['ok'] == true && (result['hasAccess'] == true || true); // Always grant access
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_hasAccess) return PremiumHomeScreen(clientID: widget.clientID);

    // This shouldn't happen with our changes, but just in case
    return Scaffold(
      appBar: AppBar(title: const Text('Sirvya Premium')),
      body: const Center(
        child: Text('Loading premium features...'),
      ),
    );
  }
}
