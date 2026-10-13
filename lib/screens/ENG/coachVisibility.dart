import 'package:flutter/material.dart';
import '../../services/apiService.dart';
import '../../theme/fitlek_theme_extension.dart';
import 'coachProfile.dart' show CoachProfileData;

class CoachVisibility extends StatefulWidget {
  final CoachProfileData profile;
  final String token;

  const CoachVisibility({super.key, required this.profile, required this.token});

  @override
  State<CoachVisibility> createState() => _CoachVisibilityState();
}

class _CoachVisibilityState extends State<CoachVisibility> {
  late bool _publicProfile;
  late bool _directMessaging;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _publicProfile = widget.profile.publicProfile;
    _directMessaging = widget.profile.directMessaging;
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: TextStyle(
              color: isError ? Theme.of(context).colorScheme.onError : Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            )),
        backgroundColor: isError ? context.fitlek.error : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final res = await ApiService.put('/coaches/me/profile', {
        'userID': widget.profile.id,
        'publicProfile': _publicProfile ? 1 : 0,
        'directMessaging': _directMessaging ? 1 : 0,
      });
      if (res['ok'] == true || res['message'] != null) {
        if (mounted) Navigator.pop(context, true);
      } else {
        _showSnack(res['error'] ?? 'Failed to update visibility & messaging', isError: true);
      }
    } catch (e) {
      _showSnack('Network error', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fitlek;
    return Scaffold(
      backgroundColor: const Color(0xFF0F261F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Visibility & messaging', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Profile visibility'),
            const SizedBox(height: 8),
            Text(
              'Control who can see your profile on the platform.',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A32),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Public profile', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text('Your profile is visible to all users', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _publicProfile,
                    onChanged: (val) => setState(() => _publicProfile = val),
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            _buildSectionTitle('Messaging settings'),
            const SizedBox(height: 8),
            Text(
              'Control who can send you direct messages.',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A32),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Direct messaging', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text('Allow users to send you messages directly', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _directMessaging,
                    onChanged: (val) => setState(() => _directMessaging = val),
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
