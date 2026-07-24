import 'package:flutter/material.dart';
import '../../services/apiService.dart';
import '../../models/coachConversation.dart';
import 'coachChat.dart';

import '../../theme/fitlek_theme_extension.dart';
class CoachConversations extends StatefulWidget {
  const CoachConversations({super.key});
  @override
  State<CoachConversations> createState() => _CoachConversationsState();
}

class _CoachConversationsState extends State<CoachConversations> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _loading = true;
  List<CoachConversation> _conversations = [];

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ApiService.get('/coach/conversations');
    if (!mounted) return;
    if (result['ok'] == true) {
      final list = List<dynamic>.from(result['data'] ?? []);
      setState(() {
        _conversations = list.map((c) => CoachConversation(
          id: c['id'].toString(),
          clientId: c['clientID'].toString(),
          clientName: '${c['firstName']} ${c['lastName']}',
          clientPhotoUrl: c['avatarUrl'] ?? '',
          lastMessage: c['lastMessage'] ?? '',
          lastMessageTime: c['lastMessageAt'] != null ? DateTime.parse(c['lastMessageAt']) : DateTime.now(),
          unreadCount: (c['unreadCount'] as num?)?.toInt() ?? 0,
        )).toList();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  List<CoachConversation> get _filtered {
    if (_query.isEmpty) return _conversations;
    return _conversations.where((c) => c.clientName.toLowerCase().contains(_query.toLowerCase())).toList();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Messages', style: TextStyle(color: cs.onSurface, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(color: f.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: f.border)),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(color: cs.onSurface, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: TextStyle(color: f.textMuted, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: f.textMuted, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
              ),
            ),
          ]),
        ),
        Expanded(child: _loading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : _filtered.isEmpty
            ? Center(child: Text('No conversations found', style: TextStyle(color: f.textMuted, fontSize: 15)))
            : RefreshIndicator(
                color: cs.primary, backgroundColor: f.card,
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _buildTile(_filtered[i]),
                ),
              )),
      ]),
    );
  }

  Widget _buildTile(CoachConversation conv) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final hasUnread = conv.unreadCount > 0;
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CoachChat(conversation: conv)));
        _load();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: hasUnread ? cs.primary.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hasUnread ? cs.primary.withValues(alpha: 0.15) : Colors.transparent),
        ),
        child: Row(children: [
          Stack(children: [
            Container(width: 52, height: 52,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(
                color: hasUnread ? cs.primary : f.border, width: 1.5)),
              child: ClipOval(child: conv.clientPhotoUrl.isNotEmpty
                ? Image.network(conv.clientPhotoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.person, color: f.textMuted, size: 26))
                : Icon(Icons.person, color: f.textMuted, size: 26))),
            if (hasUnread) Positioned(right: 0, top: 0, child: Container(
              width: 18, height: 18,
              decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
              child: Center(child: Text('${conv.unreadCount}', style: TextStyle(color: cs.onPrimary, fontSize: 10, fontWeight: FontWeight.w800))))),
          ]),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(conv.clientName, style: TextStyle(color: cs.onSurface, fontSize: 15, fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500))),
              Text(_timeAgo(conv.lastMessageTime), style: TextStyle(
                color: hasUnread ? cs.primary : f.textMuted,
                fontSize: 11, fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400)),
            ]),
            const SizedBox(height: 3),
            Text(conv.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: hasUnread ? f.textSecondary : f.textMuted,
                fontSize: 13, fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400)),
          ])),
        ]),
      ),
    );
  }
}
