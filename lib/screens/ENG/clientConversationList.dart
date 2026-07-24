import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fitlek1/constants/urls.dart';
import 'clientConversation.dart';
import '../../theme/fitlek_theme_extension.dart';

class _ConversationItem {
  final int id;
  final int coachID;
  final int clientID;
  final String otherName;
  final String? otherAvatar;
  final DateTime? lastMessageAt;
  final String? lastMessage;
  final int unreadCount;

  const _ConversationItem({
    required this.id,
    required this.coachID,
    required this.clientID,
    required this.otherName,
    this.otherAvatar,
    this.lastMessageAt,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory _ConversationItem.fromJson(Map<String, dynamic> j) => _ConversationItem(
        id: j['id'],
        coachID: j['coachID'],
        clientID: j['clientID'],
        otherName: j['otherName'] ?? 'Unknown',
        otherAvatar: j['otherAvatar'],
        lastMessageAt: j['lastMessageAt'] != null ? DateTime.tryParse(j['lastMessageAt']) : null,
        lastMessage: j['lastMessage'] as String?,
        unreadCount: (j['unreadCount'] as num?)?.toInt() ?? 0,
      );
}

class ClientConversationsListScreen extends StatefulWidget {
  final int clientID;
  final String token;

  const ClientConversationsListScreen({
    super.key,
    required this.clientID,
    required this.token,
  });

  @override
  State<ClientConversationsListScreen> createState() => _ClientConversationsListScreenState();
}

class _ClientConversationsListScreenState extends State<ClientConversationsListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<_ConversationItem> _conversations = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      };

  List<_ConversationItem> get _filtered {
    if (_query.trim().isEmpty) return _conversations;
    final q = _query.trim().toLowerCase();
    return _conversations.where((c) => c.otherName.toLowerCase().contains(q)).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchConversations();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _getConversationsUrl() {
    return '$baseUrl/conversations?userID=${widget.clientID}&role=client';
  }

  Future<void> _fetchConversations() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final url = _getConversationsUrl();
      final res = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        final list = data.map((e) => _ConversationItem.fromJson(e as Map<String, dynamic>)).toList();
        list.sort((a, b) {
          if (a.lastMessageAt == null && b.lastMessageAt == null) return 0;
          if (a.lastMessageAt == null) return 1;
          if (b.lastMessageAt == null) return -1;
          return b.lastMessageAt!.compareTo(a.lastMessageAt!);
        });
        setState(() {
          _conversations = list;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Error (${res.statusCode})';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Server unreachable';
        _loading = false;
      });
    }
  }

  void _openConversation(_ConversationItem conv) {
    Navigator.push(
      context,
      _fadeSlide(
        ClientConversationScreen(
          conversationID: conv.id,
          clientID: widget.clientID,
          token: widget.token,
          coachName: conv.otherName,
          coachAvatar: conv.otherAvatar,
          coachSpeciality: null,
        ),
      ),
    ).then((_) => _fetchConversations());
  }

  PageRouteBuilder _fadeSlide(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 400),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: RefreshIndicator(
                  color: Theme.of(context).colorScheme.primary,
                  backgroundColor: context.fitlek.card,
                  onRefresh: _fetchConversations,
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.fitlek.card,
      elevation: 0,
      toolbarHeight: 56,
      leadingWidth: 44,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Icon(Icons.arrow_back_ios_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
        ),
      ),
      title: Text(
        'Messages',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      actions: const [
        
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: context.fitlek.border),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: context.fitlek.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.fitlek.border, width: 1),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(Icons.search_rounded, color: context.fitlek.textMuted, size: 19),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Search a conversation…',
                  hintStyle: TextStyle(color: context.fitlek.textMuted, fontSize: 13.5),
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
              ),
            ),
            if (_query.isNotEmpty)
              GestureDetector(
                onTap: () => _searchCtrl.clear(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.close_rounded, color: context.fitlek.textMuted, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.only(top: 8),
        children: List.generate(
          5,
          (_) => Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            height: 78,
            decoration: BoxDecoration(
              color: context.fitlek.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.fitlek.border, width: 1),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.error_outline_rounded, color: context.fitlek.textMuted, size: 48),
          const SizedBox(height: 16),
          Center(
            child: Text(_error!, style: TextStyle(color: context.fitlek.textMuted, fontSize: 14)),
          ),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: _fetchConversations,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'RETRY',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final list = _filtered;

    if (_conversations.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06), shape: BoxShape.circle),
              child: Icon(Icons.chat_bubble_outline_rounded, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), size: 32),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'No conversations',
              style: TextStyle(color: context.fitlek.textMuted, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Your conversations will appear here',
              style: TextStyle(color: context.fitlek.textMuted, fontSize: 13),
            ),
          ),
        ],
      );
    }

    if (list.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Icon(Icons.search_off_rounded, color: context.fitlek.textMuted, size: 40),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'No results for "$_query"',
              style: TextStyle(color: context.fitlek.textSecondary, fontSize: 13.5),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      itemCount: list.length,
      itemBuilder: (_, i) => _ConversationTile(
        conversation: list[i],
        onTap: () => _openConversation(list[i]),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final _ConversationItem conversation;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool hasUnread = conversation.unreadCount > 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasUnread
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : context.fitlek.border,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: hasUnread
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
            : context.fitlek.card,
        child: InkWell(
          onTap: onTap,
          splashColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
          highlightColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.03),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hasUnread
                              ? Theme.of(context).colorScheme.primary
                              : context.fitlek.border,
                          width: 1.5,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: context.fitlek.card2,
                        backgroundImage: conversation.otherAvatar != null && conversation.otherAvatar!.isNotEmpty
                            ? NetworkImage(conversation.otherAvatar!)
                            : null,
                        child: (conversation.otherAvatar == null || conversation.otherAvatar!.isEmpty)
                            ? Text(
                                conversation.otherName.isNotEmpty ? conversation.otherName[0].toUpperCase() : '?',
                                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 18, fontWeight: FontWeight.w900),
                              )
                            : null,
                      ),
                    ),
                    if (hasUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.fitlek.error,
                            shape: BoxShape.circle,
                            border: Border.all(color: context.fitlek.card, width: 1.5),
                          ),
                          child: Text(
                            conversation.unreadCount > 99 ? '99+' : '${conversation.unreadCount}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onError,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
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
                              conversation.otherName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w700,
                              ),
                            ),
                          ),
                          if (conversation.lastMessageAt != null)
                            Text(
                              _formatTime(conversation.lastMessageAt!),
                              style: TextStyle(
                                color: hasUnread ? Theme.of(context).colorScheme.primary : context.fitlek.textMuted,
                                fontSize: 11,
                                fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 12,
                            color: hasUnread ? Theme.of(context).colorScheme.primary : context.fitlek.textMuted,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              conversation.lastMessage != null && conversation.lastMessage!.isNotEmpty
                                  ? conversation.lastMessage!
                                  : 'Tap to open conversation',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: hasUnread ? Theme.of(context).colorScheme.onSurface : context.fitlek.textSecondary,
                                fontSize: 12.5,
                                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (hasUnread)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.fitlek.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${conversation.unreadCount}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onError,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                else
                  Icon(Icons.chevron_right_rounded, color: context.fitlek.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);

    if (diff.inDays == 0) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[d.weekday - 1];
    } else {
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    }
  }
}