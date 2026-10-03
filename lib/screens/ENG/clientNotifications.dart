import 'package:flutter/material.dart';
import '../../theme/fitlek_theme_extension.dart';
import '../../services/apiService.dart';
import '../../models/workout.dart';
import 'workout/workout_home.dart';
import 'workout/active_workout.dart';
import 'workout/workout_ui.dart';

class ClientNotificationsScreen extends StatefulWidget {
  const ClientNotificationsScreen({super.key});

  @override
  State<ClientNotificationsScreen> createState() =>
      _ClientNotificationsScreenState();
}

class _ClientNotificationsScreenState extends State<ClientNotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true, _more = false;
  int _page = 1;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    setState(() => _loading = true);
    final page = more ? _page + 1 : 1;
    final response = await ApiService.get('/notifications?page=$page');
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (response['ok'] != true) {
        _error = response['message'];
        return;
      }
      _error = null;
      _notifications = more
          ? [..._notifications, ...workoutRows(response['data'])]
          : workoutRows(response['data']);
      _page = page;
      _more = response['hasMore'] == true;
    });
  }

  Future<void> _open(Map<String, dynamic> n) async {
    final r = await ApiService.put('/notifications/${n['id']}/read', {});
    if (!mounted) return;
    if (r['ok'] != true) {
      ApiService.showError(context, r['message']);
      return;
    }
    setState(() => n['isRead'] = 1);
    if ('${n['type']}'.startsWith('workout')) {
      await Navigator.push(
          context,
          WorkoutRoute(
              builder: (_) => n['type'] == 'workout_rest' &&
                      workoutInt(n['relatedEntityID']) > 0
                  ? ActiveWorkoutScreen(
                      sessionID: workoutInt(n['relatedEntityID']))
                  : const WorkoutHomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: IconThemeData(color: cs.onSurface),
      ),
      body: _loading && _notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!),
                  TextButton(onPressed: _load, child: const Text('Try again'))
                ]))
              : _notifications.isNotEmpty
                  ? RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            ..._notifications.map((n) => Card(
                                child: ListTile(
                                    leading: Icon(
                                        '${n['type']}'.startsWith('workout')
                                            ? Icons.fitness_center_rounded
                                            : Icons.notifications_outlined,
                                        color: cs.primary),
                                    title: Text('${n['title']}',
                                        style: TextStyle(
                                            fontWeight: n['isRead'] == 1
                                                ? FontWeight.w400
                                                : FontWeight.w700)),
                                    subtitle: Text(
                                        '${n['body']}\n${workoutDate(n['createdAt'])}'),
                                    isThreeLine: true,
                                    onTap: () => _open(n),
                                    trailing: n['isRead'] == 1
                                        ? null
                                        : Icon(Icons.circle,
                                            size: 8, color: cs.primary)))),
                            if (_more)
                              TextButton(
                                  onPressed: () => _load(more: true),
                                  child: const Text('Load more'))
                          ]))
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none_rounded,
                              color: f.textMuted, size: 60),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet.',
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We will notify you when something arrives.',
                            style: TextStyle(color: f.textMuted, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
