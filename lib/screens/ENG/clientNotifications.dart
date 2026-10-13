import '../../services/live_updates.dart';
import '../../services/notification_navigation.dart';
import 'package:flutter/material.dart';
import '../../services/apiService.dart';
import '../../theme/fitlek_theme_extension.dart';

class ClientNotificationsScreen extends StatefulWidget {
  const ClientNotificationsScreen({super.key});
  @override
  State<ClientNotificationsScreen> createState() =>
      _ClientNotificationsScreenState();
}

class _ClientNotificationsScreenState extends State<ClientNotificationsScreen> with LiveUpdates<ClientNotificationsScreen> {
  @override
  Set<String> get liveDomains => {'notifications','reservations'};
  @override
  Future<void> refreshLiveData() async { await _load(); }

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
              onPressed:
                  _items.any((item) => item['isRead'] == 0) ? _readAll : null,
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
                      itemCount: _items.isEmpty ? 1 : _items.length,
                      itemBuilder: (context, index) {
                        if (_items.isEmpty)
                          return const Padding(
                              padding: EdgeInsets.all(32),
                              child: Text('No notifications yet.'));
                        final item = _items[index];
                        final price =
                            item['type']?.toString().startsWith('price_') ??
                                false;
                        return Card(
                            color: context.fitlek.card,
                            child: ListTile(
                                leading: Icon(price
                                    ? Icons.payments_outlined
                                    : Icons.notifications_outlined),
                                title: Text(item['title'] ?? '',
                                    style: TextStyle(
                                        fontWeight: item['isRead'] == 0
                                            ? FontWeight.w700
                                            : FontWeight.w400)),
                                subtitle: Text(item['body'] ?? ''),
                                trailing:
                                    const Icon(Icons.chevron_right_rounded),
                                onTap: () => _open(item)));
                      },
                    )),
      );
}
