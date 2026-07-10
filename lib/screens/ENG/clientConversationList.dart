import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'clientConversation.dart';

const _lime = Color(0xFFC6F135);
const _dark = Color(0xFF0A0A0A);
const _card = Color(0xFF141414);
const _cardBorder = Color(0xFF232323);
const _baseUrl = 'http://192.168.0.232:3000/api';

class _FitlekLogoPainter extends CustomPainter {
  final Color strokeColor;
  final Color circleColor;

  const _FitlekLogoPainter({required this.strokeColor, required this.circleColor});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 132;
    final scaleY = size.height / 120;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    canvas.drawCircle(const Offset(65.6104, 17.25), 17.25, Paint()..color = circleColor);

    final path = Path()
      ..moveTo(5.8103, 21.85)
      ..cubicTo(19.2827, 35.9, 45.0007, 47.25, 64.4603, 47.7336)
      ..moveTo(125.41, 21.85)
      ..cubicTo(112.388, 36.0329, 83.709, 48.212, 64.4603, 47.7336)
      ..moveTo(64.4603, 47.7336)
      ..lineTo(64.4603, 106.95)
      ..cubicTo(87.8436, 95.8333, 128.4, 73.37, 103.56, 72.45)
      ..cubicTo(78.7203, 71.53, 36.477, 72.0666, 18.4603, 72.45);

    canvas.drawPath(
      path,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16.1
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FitlekLogoPainter oldDelegate) => false;
}

class _LogoWatermark extends StatelessWidget {
  final double size;
  const _LogoWatermark({this.size = 360});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.04,
        child: SizedBox(
          width: size,
          height: size * 120 / 132,
          child: CustomPaint(
            painter: _FitlekLogoPainter(strokeColor: Colors.white, circleColor: _lime),
          ),
        ),
      ),
    );
  }
}

class _ConversationItem {
  final int id;
  final int coachID;
  final int clientID;
  final String otherName;
  final String? otherAvatar;
  final DateTime? lastMessageAt;

  const _ConversationItem({
    required this.id,
    required this.coachID,
    required this.clientID,
    required this.otherName,
    this.otherAvatar,
    this.lastMessageAt,
  });

  factory _ConversationItem.fromJson(Map<String, dynamic> j) => _ConversationItem(
        id: j['id'],
        coachID: j['coachID'],
        clientID: j['clientID'],
        otherName: j['otherName'] ?? 'Inconnu',
        otherAvatar: j['otherAvatar'],
        lastMessageAt: j['lastMessageAt'] != null ? DateTime.tryParse(j['lastMessageAt']) : null,
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
        'Authorization': 'Bearer ' + widget.token,
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
    return _baseUrl + '/conversations?userID=' + widget.clientID.toString() + '&role=client';
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
          _error = 'Erreur (' + res.statusCode.toString() + ')';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Serveur inaccessible';
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
      backgroundColor: _dark,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Positioned(
            right: -70,
            bottom: -30,
            child: _LogoWatermark(size: 380),
          ),
          Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: RefreshIndicator(
                  color: _lime,
                  backgroundColor: _card,
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
      backgroundColor: _card,
      elevation: 0,
      toolbarHeight: 56,
      leadingWidth: 44,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
        ),
      ),
      title: const Text(
        'Messages',
        style: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _cardBorder),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _cardBorder, width: 1),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.3), size: 19),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Rechercher une conversation…',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13.5),
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
                  child: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.3), size: 18),
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
              color: _card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _cardBorder, width: 1),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 60),
          const Icon(Icons.error_outline_rounded, color: Colors.white24, size: 48),
          const SizedBox(height: 16),
          Center(
            child: Text(_error!, style: const TextStyle(color: Colors.white38, fontSize: 14)),
          ),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: _fetchConversations,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _lime.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _lime.withOpacity(0.3)),
                ),
                child: const Text(
                  'RÉESSAYER',
                  style: TextStyle(color: _lime, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1),
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
              decoration: BoxDecoration(color: _lime.withOpacity(0.06), shape: BoxShape.circle),
              child: Icon(Icons.chat_bubble_outline_rounded, color: _lime.withOpacity(0.3), size: 32),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Aucune conversation',
              style: TextStyle(color: Colors.white38, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Vos conversations apparaîtront ici',
              style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13),
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
            child: Icon(Icons.search_off_rounded, color: Colors.white.withOpacity(0.2), size: 40),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Aucun résultat pour "$_query"',
              style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13.5),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: _card,
        child: InkWell(
          onTap: onTap,
          splashColor: _lime.withOpacity(0.06),
          highlightColor: _lime.withOpacity(0.03),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _cardBorder, width: 1.5),
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFF1A1A1A),
                    backgroundImage: conversation.otherAvatar != null && conversation.otherAvatar!.isNotEmpty
                        ? NetworkImage(conversation.otherAvatar!)
                        : null,
                    child: (conversation.otherAvatar == null || conversation.otherAvatar!.isEmpty)
                        ? Text(
                            conversation.otherName.isNotEmpty ? conversation.otherName[0].toUpperCase() : '?',
                            style: const TextStyle(color: _lime, fontSize: 18, fontWeight: FontWeight.w900),
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
                              conversation.otherName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (conversation.lastMessageAt != null)
                            Text(
                              _formatTime(conversation.lastMessageAt!),
                              style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11, fontWeight: FontWeight.w400),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 12, color: Colors.white.withOpacity(0.25)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'Appuyez pour ouvrir la conversation',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12.5, fontWeight: FontWeight.w400),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 20),
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
      return d.hour.toString().padLeft(2, '0') + ':' + d.minute.toString().padLeft(2, '0');
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return days[d.weekday - 1];
    } else {
      return d.day.toString().padLeft(2, '0') + '/' + d.month.toString().padLeft(2, '0');
    }
  }
}