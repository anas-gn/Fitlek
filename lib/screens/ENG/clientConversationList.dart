import '../../services/live_updates.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fitlek1/constants/urls.dart';
import 'clientConversation.dart';
import '../../theme/fitlek_theme_extension.dart';
import '../../components/ENG/imagePreview.dart';

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

  factory _ConversationItem.fromJson(Map<String, dynamic> j) =>
      _ConversationItem(
        id: j['id'],
        coachID: j['coachID'],
        clientID: j['clientID'],
        otherName: j['otherName'] ?? 'Unknown',
        otherAvatar: j['otherAvatar'],
        lastMessageAt: j['lastMessageAt'] != null
            ? DateTime.tryParse(j['lastMessageAt'])
            : null,
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
  State<ClientConversationsListScreen> createState() =>
      _ClientConversationsListScreenState();
}

class _ClientConversationsListScreenState extends State<ClientConversationsListScreen> with LiveUpdates<ClientConversationsListScreen> {
  @override
  Set<String> get liveDomains => {'chat-actions','messages','read_receipts','conversations','bans'};
  @override
  Future<void> refreshLiveData() async { await _fetchConversations(silent:true); }

  final TextEditingController _searchCtrl = TextEditingController();

  List<_ConversationItem> _conversations = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      };

  int _selectedFilter = 0;

  List<_ConversationItem> get _filtered {
    var list = _conversations;
    if (_selectedFilter == 1) {
      list = list.where((c) => c.unreadCount > 0).toList();
    }
    if (_query.trim().isEmpty) return list;
    final q = _query.trim().toLowerCase();
    return list.where((c) => c.otherName.toLowerCase().contains(q)).toList();
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

  Future<void> _fetchConversations({bool silent = false}) async {
    if (!silent) setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final url = _getConversationsUrl();
      final res = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        final list = data
            .map((e) => _ConversationItem.fromJson(e as Map<String, dynamic>))
            .toList();
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
            position: Tween<Offset>(begin: Offset(0, 0.04), end: Offset.zero)
                .animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        transitionDuration: Duration(milliseconds: 400),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilters(),
            Expanded(
              child: RefreshIndicator(
                color: context.fitlek.border,
                backgroundColor: Theme.of(context).colorScheme.primary,
                onRefresh: _fetchConversations,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: Theme.of(context).colorScheme.onSurface, size: 24),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Messages',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Échangez avec vos coachs',
                    style: TextStyle(
                        color: context.fitlek.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.fitlek.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.edit_square,
                color: Theme.of(context).colorScheme.primary, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _selectedFilter = 0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedFilter == 0
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: _selectedFilter == 0
                    ? null
                    : Border.all(color: context.fitlek.border),
              ),
              child: Text(
                'Tous',
                style: TextStyle(
                  color: _selectedFilter == 0
                      ? Theme.of(context).colorScheme.onPrimary
                      : context.fitlek.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => _selectedFilter = 1),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedFilter == 1
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: _selectedFilter == 1
                    ? null
                    : Border.all(color: context.fitlek.border),
              ),
              child: Text(
                'Non lus',
                style: TextStyle(
                  color: _selectedFilter == 1
                      ? Theme.of(context).colorScheme.onPrimary
                      : context.fitlek.textSecondary,
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
      padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: context.fitlek.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.fitlek.border, width: 1),
        ),
        child: Row(
          children: [
            SizedBox(width: 14),
            Icon(Icons.search_rounded,
                color: context.fitlek.textMuted, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Rechercher une conversation',
                  hintStyle:
                      TextStyle(color: context.fitlek.textMuted, fontSize: 14),
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
                onTap: () => _searchCtrl.clear(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.close_rounded,
                      color: context.fitlek.textMuted, size: 18),
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
        padding: EdgeInsets.only(top: 8),
        children: List.generate(
          5,
          (_) => Container(
            margin: EdgeInsets.fromLTRB(16, 0, 16, 8),
            height: 70,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                  bottom: BorderSide(color: context.fitlek.border, width: 1)),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return ListView(
        children: [
          SizedBox(height: 60),
          Icon(Icons.error_outline_rounded,
              color: context.fitlek.textMuted, size: 48),
          SizedBox(height: 16),
          Center(
            child: Text(_error!,
                style:
                    TextStyle(color: context.fitlek.textMuted, fontSize: 14)),
          ),
          SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: _fetchConversations,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3)),
                ),
                child: Text(
                  'RETRY',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1),
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
          SizedBox(height: 80),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.06),
                  shape: BoxShape.circle),
              child: Icon(Icons.chat_bubble_outline_rounded,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                  size: 32),
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: Text(
              'No conversations',
              style: TextStyle(
                  color: context.fitlek.textMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(height: 8),
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
          SizedBox(height: 80),
          Center(
            child: Icon(Icons.search_off_rounded,
                color: context.fitlek.textMuted, size: 40),
          ),
          SizedBox(height: 16),
          Center(
            child: Text(
              'No results for "$_query"',
              style: TextStyle(
                  color: context.fitlek.textSecondary, fontSize: 13.5),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: 4, bottom: 16),
      itemCount: list.length + 1,
      itemBuilder: (_, i) {
        if (i == list.length) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Retrouvez ici toutes vos conversations.',
                style: TextStyle(color: context.fitlek.textMuted, fontSize: 12),
              ),
            ),
          );
        }
        return _ConversationTile(
          conversation: list[i],
          onTap: () => _openConversation(list[i]),
        );
      },
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
    return InkWell(
      onTap: onTap,
      splashColor: context.fitlek.border.withOpacity(0.3),
      highlightColor: context.fitlek.border.withOpacity(0.1),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border:
              Border(bottom: BorderSide(color: context.fitlek.card, width: 1)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (conversation.otherAvatar != null &&
                    conversation.otherAvatar!.isNotEmpty) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ImagePreview(
                              imageUrl: conversation.otherAvatar!,
                              tag: 'list_avatar_${conversation.id}')));
                }
              },
              child: CircleAvatar(
                radius: 26,
                backgroundColor: context.fitlek.border,
                backgroundImage: conversation.otherAvatar != null &&
                        conversation.otherAvatar!.isNotEmpty
                    ? NetworkImage(conversation.otherAvatar!)
                    : null,
                child: (conversation.otherAvatar == null ||
                        conversation.otherAvatar!.isEmpty)
                    ? Text(
                        conversation.otherName.isNotEmpty
                            ? conversation.otherName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w900),
                      )
                    : null,
              ),
            ),
            SizedBox(width: 14),
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
                            fontSize: 16,
                            fontWeight:
                                hasUnread ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (conversation.lastMessageAt != null)
                        Text(
                          _formatTime(conversation.lastMessageAt!),
                          style: TextStyle(
                            color: hasUnread
                                ? Theme.of(context).colorScheme.primary
                                : context.fitlek.textMuted,
                            fontSize: 12,
                            fontWeight:
                                hasUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      if (conversation.lastMessage
                              ?.toLowerCase()
                              .contains('photo') ==
                          true) ...[
                        Icon(Icons.image_outlined,
                            size: 14, color: context.fitlek.textMuted),
                        SizedBox(width: 4),
                      ] else if (conversation.lastMessage
                              ?.toLowerCase()
                              .contains('vocal') ==
                          true) ...[
                        Icon(Icons.mic,
                            size: 14, color: context.fitlek.textMuted),
                        SizedBox(width: 4),
                      ] else ...[
                        if (!hasUnread &&
                            conversation.lastMessage != null &&
                            conversation.lastMessage!.isNotEmpty) ...[
                          Icon(Icons.done_all,
                              size: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary), // Assume read for now
                          SizedBox(width: 4),
                        ],
                      ],
                      Expanded(
                        child: Text(
                          conversation.lastMessage != null &&
                                  conversation.lastMessage!.isNotEmpty
                              ? conversation.lastMessage!
                              : 'Appuyez pour ouvrir',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: hasUnread
                                ? Theme.of(context).colorScheme.onSurface
                                : context.fitlek.textMuted,
                            fontSize: 14,
                            fontWeight:
                                hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
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

  String _formatTime(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);

    if (diff.inDays == 0) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      const days = ['Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.'];
      return days[d.weekday - 1];
    } else {
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    }
  }
}
