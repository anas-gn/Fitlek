import 'package:flutter/material.dart';
import '../../services/apiService.dart';
import '../../theme/fitlek_theme_extension.dart';

/// Coach Notification Center. All data is real, from `/coach/notifications`.
/// Tapping a notification marks it read on the backend and returns a typed
/// result so the shared Coach layout can navigate to the correct existing
/// destination (chat / calendar) without duplicating the layout.
class CoachNotifications extends StatefulWidget {
  const CoachNotifications({super.key});

  @override
  State<CoachNotifications> createState() => _CoachNotificationsState();
}

class _CoachNotificationsState extends State<CoachNotifications> {
  static const int _pageSize = 30;

  final _scrollCtrl = ScrollController();
  bool _loading = true;
  bool _error = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  final List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 240) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    final res = await ApiService.get('/coach/notifications?page=1&limit=$_pageSize');
    if (!mounted) return;
    if (res['ok'] == true) {
      final list = List<Map<String, dynamic>>.from(
          (res['data'] ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
      setState(() {
        _items
          ..clear()
          ..addAll(list);
        _page = 1;
        _hasMore = list.length == _pageSize;
        _loading = false;
      });
    } else {
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    setState(() => _loadingMore = true);
    final next = _page + 1;
    final res = await ApiService.get('/coach/notifications?page=$next&limit=$_pageSize');
    if (!mounted) return;
    if (res['ok'] == true) {
      final list = List<Map<String, dynamic>>.from(
          (res['data'] ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
      setState(() {
        _items.addAll(list);
        _page = next;
        _hasMore = list.length == _pageSize;
        _loadingMore = false;
      });
    } else {
      setState(() => _loadingMore = false);
    }
  }

  int get _unreadCount => _items.where((n) => n['isRead'] == 0 || n['isRead'] == false).length;

  Future<void> _markAllRead() async {
    final res = await ApiService.patch('/coach/notifications/read-all', {});
    if (!mounted) return;
    if (res['ok'] == true) {
      setState(() {
        for (final n in _items) {
          n['isRead'] = 1;
        }
      });
    } else {
      _snack(res['message']?.toString() ?? 'Could not update notifications');
    }
  }

  Future<void> _onTapNotification(Map<String, dynamic> n) async {
    // Mark read on the backend (best-effort) before navigating.
    await ApiService.patch('/coach/notifications/${n['id']}/read', {});
    if (!mounted) return;
    Navigator.of(context).pop({
      'type': n['type'],
      'relatedEntityID': n['relatedEntityID'],
      'actorName': n['actorName'],
      'actorAvatar': n['actorAvatar'],
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  ({IconData icon, Color color}) _typeStyle(String? type) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    switch (type) {
      case 'new_message':
        return (icon: Icons.chat_bubble_rounded, color: cs.primary);
      case 'new_reservation':
        return (icon: Icons.event_available_rounded, color: f.info);
      case 'upcoming_session':
        return (icon: Icons.alarm_rounded, color: f.warning);
      default:
        return (icon: Icons.notifications_rounded, color: f.textMuted);
    }
  }

  String _timeAgo(dynamic raw) {
    if (raw == null) return '';
    final d = DateTime.tryParse(raw.toString());
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: cs.onSurface),
        title: Text('Notifications',
            style: TextStyle(color: cs.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
        actions: [
          if (!_loading && !_error && _unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _markAllRead,
                child: Text('Mark all read',
                    style: TextStyle(color: cs.primary, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _loading
                ? _buildSkeleton()
                : _error
                    ? _buildError()
                    : _items.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            color: cs.primary,
                            backgroundColor: context.fitlek.card,
                            onRefresh: _load,
                            child: ListView.builder(
                              controller: _scrollCtrl,
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _items.length + (_hasMore ? 1 : 0),
                              itemBuilder: (_, i) {
                                if (i >= _items.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(child: SizedBox(
                                      width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2))),
                                  );
                                }
                                return _buildTile(_items[i]);
                              },
                            ),
                          ),
          ),
        ),
      ),
    );
  }

  Widget _buildTile(Map<String, dynamic> n) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final isRead = n['isRead'] == 1 || n['isRead'] == true;
    final style = _typeStyle(n['type']?.toString());
    return GestureDetector(
      onTap: () => _onTapNotification(n),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? f.card : cs.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isRead ? f.border : cs.primary.withValues(alpha: 0.25)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: style.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(style.icon, color: style.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text((n['title'] ?? '').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 14,
                          fontWeight: isRead ? FontWeight.w600 : FontWeight.w800)),
                ),
                if (!isRead) ...[
                  const SizedBox(width: 8),
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle)),
                ],
              ]),
              const SizedBox(height: 3),
              Text((n['body'] ?? '').toString(),
                  style: TextStyle(color: f.textSecondary, fontSize: 13, height: 1.35)),
              const SizedBox(height: 6),
              Text(_timeAgo(n['createdAt']),
                  style: TextStyle(color: f.textMuted, fontSize: 11.5)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildSkeleton() {
    final f = context.fitlek;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        height: 78,
        decoration: BoxDecoration(
          color: f.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: f.border),
        ),
        child: Row(children: [
          const SizedBox(width: 14),
          Container(width: 42, height: 42, decoration: BoxDecoration(color: f.card2, borderRadius: BorderRadius.circular(12))),
          const SizedBox(width: 12),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 140, height: 12, decoration: BoxDecoration(color: f.card2, borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 8),
            Container(width: 220, height: 10, decoration: BoxDecoration(color: f.card2, borderRadius: BorderRadius.circular(6))),
          ])),
          const SizedBox(width: 14),
        ]),
      ),
    );
  }

  Widget _buildError() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.wifi_off_rounded, color: f.textMuted, size: 52),
        const SizedBox(height: 12),
        Text('Unable to load notifications', style: TextStyle(color: f.textMuted, fontSize: 15)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _load,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
            decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(14)),
            child: Text('Retry', style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ),
      ]),
    );
  }

  Widget _buildEmpty() {
    final f = context.fitlek;
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.notifications_none_rounded, color: f.textMuted, size: 60),
                const SizedBox(height: 14),
                Text('No notifications yet.',
                    style: TextStyle(color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Messages, reservations and session reminders will appear here.',
                    textAlign: TextAlign.center, style: TextStyle(color: f.textMuted, fontSize: 13)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
