import '../../services/live_updates.dart';
import '../../components/notification_card.dart';
import '../../services/notification_navigation.dart';
import 'package:flutter/material.dart';
import '../../services/apiService.dart';

class ClientNotificationsScreen extends StatefulWidget {
  const ClientNotificationsScreen({super.key});
  @override
  State<ClientNotificationsScreen> createState() =>
      _ClientNotificationsScreenState();
}

class _ClientNotificationsScreenState extends State<ClientNotificationsScreen>
    with LiveUpdates<ClientNotificationsScreen> {
  @override
  Set<String> get liveDomains => {'notifications', 'reservations'};
  @override
  Future<void> refreshLiveData() async {
    await _load();
  }

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await ApiService.get('/reservations/notifications/mine');
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = result['ok'] == true
          ? null
          : result['error'] ??
              result['message'] ??
              'Could not load notifications';
      if (result['ok'] == true)
        _items = (result['data'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
    });
  }

  Future<void> _open(Map<String, dynamic> item) async {
    await ApiService.patch('/reservations/notifications/${item['id']}/read');
    if (!mounted) return;
    await NotificationNavigation.open(context, item);
    if (mounted) _load();
  }

  Future<void> _readAll() async {
    final result =
        await ApiService.patch('/reservations/notifications/read-all');
    if (!mounted) return;
    if (result['ok'] == true) {
      setState(() {
        for (final item in _items) {
          item['isRead'] = 1;
        }
      });
    } else {
      ApiService.showError(
          context, result['message'] ?? 'Could not mark notifications read.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Notifications'), actions: [
          IconButton(
              tooltip: 'Mark all as read',
              onPressed: _items.any(NotificationCard.unread) ? _readAll : null,
              icon: const Icon(Icons.done_all)),
        ]),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: TextButton(
                        onPressed: _load, child: Text('$_error · Retry')))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.isEmpty ? 2 : _items.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0)
                          return NotificationInboxIntro(
                              unreadCount:
                                  _items.where(NotificationCard.unread).length);
                        if (_items.isEmpty)
                          return const Padding(
                              padding: EdgeInsets.all(32),
                              child: Text('No notifications yet.'));
                        final item = _items[index - 1];
                        return NotificationCard(
                            item: item, onTap: () => _open(item));
                      },
                    )),
      );
}
