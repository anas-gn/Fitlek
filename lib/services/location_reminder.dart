import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'apiService.dart';
import '../screens/ENG/userLocationSettings.dart';

class LocationReminder {
  // In memory only: reset when the app process starts again, not on tab changes.
  static final Set<String> _checked = {};
  static Future<void> showOnce(BuildContext context, String role) async {
    try {
      final user = await ApiService.getUserData();
      if (user == null || !context.mounted) return;
      final key = '$role:${user['id']}';
      if (!_checked.add(key)) return;
      final saved = await ApiService.get('/locations/me');
      if (saved['ok'] != true || !context.mounted) return;
      final permission = await Geolocator.checkPermission();
      final active = (permission == LocationPermission.whileInUse || permission == LocationPermission.always) &&
          await Geolocator.isLocationServiceEnabled() &&
          saved['latitude'] != null && saved['longitude'] != null &&
          (saved['autoRefresh'] == 1 || saved['autoRefresh'] == true);
      if (active || !context.mounted) return;
      final enable = await showDialog<bool>(context: context,
          builder: (_) => LocationReminderDialog(role: role));
      if (enable == true && context.mounted) {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UserLocationSettings()));
      }
    } catch (_) {}
  }
}

class LocationReminderDialog extends StatelessWidget {
  final String role;
  const LocationReminderDialog({super.key, required this.role});
  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: const Icon(Icons.near_me_rounded, size: 36),
    title: Text(role == 'coach' ? 'Help nearby clients find you' : 'Find coaches closer to you'),
    content: SingleChildScrollView(child: Text(role == 'coach'
        ? 'Enable location to help clients discover you nearby and see an approximate distance. Only your city and distance are shown; your address stays private.'
        : 'Enable location for nearby coach recommendations and approximate distances. Only your city is public; your address stays private.')),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not now')),
      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Enable location')),
    ],
  );
}
