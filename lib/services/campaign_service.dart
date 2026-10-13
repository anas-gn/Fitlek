import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'apiService.dart';
import 'notification_navigation.dart';
import '../globals.dart';
import '../models/anas/coach.dart';
import '../models/anas/reservation.dart';
import '../screens/ENG/clientCoachDetail.dart';

class CampaignService {
  static Timer? _timer;
  static bool _busy = false;
  static int _generation = 0;
  static BuildContext? _rootContext;
  static void start(BuildContext context) {
    _rootContext = context;
    _timer?.cancel();
    ++_generation;
    WidgetsBinding.instance.addPostFrameCallback((_) => check());
    _timer = Timer.periodic(const Duration(seconds: 45), (_) => check());
  }

  static void stop() {
    _rootContext = null;
    ++_generation;
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> check() async {
    if (_busy ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed)
      return;
    final root = _rootContext;
    // Avoid interrupting booking, chat, or profile edits with advertising.
    if (root == null || !root.mounted || ModalRoute.of(root)?.isCurrent != true)
      return;
    _busy = true;
    final generation = _generation;
    try {
      final token = await ApiService.getToken();
      if (token == null) return;
      final result = await ApiService.get('/campaigns/active');
      if (result['ok'] != true ||
          generation != _generation ||
          token != await ApiService.getToken()) return;
      final items = result['items'];
      if (items is! List || items.isEmpty) return;
      final context = _rootContext;
      if (context == null ||
          !context.mounted ||
          ModalRoute.of(context)?.isCurrent != true) return;
      final item = Map<String, dynamic>.from(items.first);
      final seen = await ApiService.post('/campaigns/${item['id']}/seen', {});
      if (seen['ok'] != true || seen['shouldShow'] != true ||
          !context.mounted ||
          generation != _generation ||
          token != await ApiService.getToken()) return;
      await show(context, item);
    } catch (_) {/* Retry on the next foreground check. */} finally {
      _busy = false;
    }
  }

  static Future<void> openNotification(BuildContext context, String id) async {
    if (int.tryParse(id) == null) return;
    final item = await ApiService.get('/campaigns/$id');
    if (!context.mounted) return;
    if (item['ok'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('This announcement has expired or is unavailable.')));
      return;
    }
    await ApiService.post('/campaigns/$id/seen', {});
    if (!context.mounted) return;
    if ('${item['destination'] ?? ''}'.isEmpty) {
      await show(context, item);
      return;
    }
    await openDestination(context, '${item['destination']}');
  }

  static Future<void> show(
      BuildContext context, Map<String, dynamic> item) async {
    final open = await showDialog<bool>(
        context: context, builder: (_) => CampaignDialog(item: item));
    if (open == true &&
        context.mounted &&
        '${item['destination'] ?? ''}'.isNotEmpty) {
      await openDestination(context, '${item['destination']}');
    }
  }

  static Future<void> openDestination(
      BuildContext context, String destination) async {
    final uri = Uri.tryParse(destination);
    if (uri != null &&
        ['http', 'https', 'mailto', 'tel', 'sms'].contains(uri.scheme)) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      } catch (_) {}
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open this link.')));
      return;
    }
    final session =
        RegExp(r'^/sessions/([1-9][0-9]*)$').firstMatch(destination);
    if (session != null) {
      await NotificationNavigation.open(context,
          {'type': 'new_reservation', 'relatedEntityID': session.group(1)});
      return;
    }
    final profile = RegExp(r'^/coaches/([1-9][0-9]*)$').firstMatch(destination);
    if (profile != null) {
      final user = await ApiService.getUserData(),
          token = await ApiService.getToken();
      final result = await ApiService.get('/coaches/${profile.group(1)}');
      if (!context.mounted ||
          result['ok'] != true ||
          user == null ||
          token == null) return;
      final coach = CoachModel.fromJson(result);
      final reservation = ReservationModel(
          id: 0,
          clientID: int.parse('${user['id']}'),
          coachID: coach.id,
          coachName: coach.fullName,
          coachSpeciality: coach.displaySpecialties,
          coachImageUrl: coach.avatarUrl ?? '',
          coachRating: coach.rating ?? 0,
          sessionStart: DateTime.now(),
          sessionEnd: DateTime.now().add(const Duration(hours: 1)),
          location: 'To be defined',
          status: 'pending',
          price: 0,
          companyName: 'Independent');
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CoachDetailScreen(
              session: reservation,
              token: token,
              clientID: int.parse('${user['id']}'))));
      return;
    }
    campaignDestination.value = null;
    campaignDestination.value = destination;
  }
}

class CampaignDialog extends StatelessWidget {
  final Map<String, dynamic> item;
  const CampaignDialog({super.key, required this.item});
  @override
  Widget build(BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(children: [
          Expanded(child: Text('${item['title'] ?? 'What’s new at Sirvya'}')),
          IconButton(
              tooltip: 'Close announcement',
              onPressed: () => Navigator.pop(context, false),
              icon: const Icon(Icons.close))
        ]),
        content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              if ('${item['imageUrl'] ?? ''}'.isNotEmpty)
                Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network('${item['imageUrl']}',
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink()))),
              Text('${item['body'] ?? ''}'),
            ]))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not now')),
          if ('${item['destination'] ?? ''}'.isNotEmpty)
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('${item['buttonLabel'] ?? ''}'.trim().isEmpty
                    ? 'Learn more'
                    : '${item['buttonLabel']}'))
        ],
      );
}
