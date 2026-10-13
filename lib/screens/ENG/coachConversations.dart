import '../../services/live_updates.dart';
import 'package:flutter/material.dart';
import '../../services/apiService.dart';
import '../../models/coachConversation.dart';
import 'coachChat.dart';
import '../../theme/fitlek_theme_extension.dart';
import '../../components/ENG/imagePreview.dart';
class CoachConversations extends StatefulWidget {
  const CoachConversations({super.key});
  @override
  State<CoachConversations> createState() => _CoachConversationsState();
}

class _CoachConversationsState extends State<CoachConversations> with LiveUpdates<CoachConversations> {
  @override
  Set<String> get liveDomains => {'chat-actions','messages','read_receipts','conversations','bans'};
  @override
  Future<void> refreshLiveData() async { await _load(silent:true); }

  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _loading = true;
  List<CoachConversation> _conversations = [];
  int _selectedFilter = 0;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
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
    var list = _conversations;
    if (_selectedFilter == 1) {
      list = list.where((c) => c.unreadCount > 0).toList();
    }
    if (_query.isEmpty) return list;
    return list.where((c) => c.clientName.toLowerCase().contains(_query.toLowerCase())).toList();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      const days = ['Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.'];
      return days[dt.weekday - 1];
    } else {
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1914),
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildFilters(),
          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1C3731)))
            : _filtered.isEmpty
              ? const Center(child: Text('Aucune conversation', style: TextStyle(color: Colors.white54, fontSize: 15)))
              : RefreshIndicator(
                  color: const Color(0xFF1C3731), backgroundColor: const Color(0xFFE8E6D9),
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: _filtered.length + 1,
                    itemBuilder: (_, i) {
                      if (i == _filtered.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'Retrouvez ici toutes vos conversations.',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ),
                        );
                      }
                      return _buildTile(_filtered[i]);
                    },
                  ),
                )),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Messages',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Échangez avec vos clients',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF132B25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.edit_square, color: Color(0xFF86D5DD), size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _selectedFilter = 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedFilter == 0 ? const Color(0xFFE8E6D9) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: _selectedFilter == 0 ? null : Border.all(color: const Color(0xFF1C3731)),
              ),
              child: Text(
                'Tous',
                style: TextStyle(
                  color: _selectedFilter == 0 ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => _selectedFilter = 1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedFilter == 1 ? const Color(0xFFE8E6D9) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: _selectedFilter == 1 ? null : Border.all(color: const Color(0xFF1C3731)),
              ),
              child: Text(
                'Non lus',
                style: TextStyle(
                  color: _selectedFilter == 1 ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFF132B25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1C3731), width: 1),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Rechercher une conversation',
                  hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isCollapsed: true,
                ),
              ),
            ),
            if (_query.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(CoachConversation conv) {
    final hasUnread = conv.unreadCount > 0;
    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CoachChat(conversation: conv)));
        _load();
      },
      splashColor: const Color(0xFF1C3731).withValues(alpha: 0.3),
      highlightColor: const Color(0xFF1C3731).withValues(alpha: 0.1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF132B25), width: 1)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (conv.clientPhotoUrl.isNotEmpty) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ImagePreview(imageUrl: conv.clientPhotoUrl, tag: 'list_avatar_${conv.id}')));
                }
              },
              child: CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF1C3731),
                backgroundImage: conv.clientPhotoUrl.isNotEmpty ? NetworkImage(conv.clientPhotoUrl) : null,
                child: conv.clientPhotoUrl.isEmpty
                    ? Text(
                        conv.clientName.isNotEmpty ? conv.clientName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.clientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        _timeAgo(conv.lastMessageTime),
                        style: TextStyle(
                          color: hasUnread ? const Color(0xFF86D5DD) : Colors.white54,
                          fontSize: 12,
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (conv.lastMessage.toLowerCase().contains('photo') == true) ...[
                        const Icon(Icons.image_outlined, size: 14, color: Colors.white54),
                        const SizedBox(width: 4),
                      ] else if (conv.lastMessage.toLowerCase().contains('vocal') == true) ...[
                        const Icon(Icons.mic, size: 14, color: Colors.white54),
                        const SizedBox(width: 4),
                      ] else ...[
                        if (!hasUnread && conv.lastMessage.isNotEmpty) ...[
                          const Icon(Icons.done_all, size: 14, color: Color(0xFF86D5DD)),
                          const SizedBox(width: 4),
                        ],
                      ],
                      Expanded(
                        child: Text(
                          conv.lastMessage.isNotEmpty ? conv.lastMessage : 'Appuyez pour ouvrir',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: hasUnread ? Colors.white : Colors.white54,
                            fontSize: 14,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF86D5DD),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${conv.unreadCount}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
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
