import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  const _LogoWatermark({this.size = 320});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.035,
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

class _Message {
  final int id;
  final int conversationID;
  final int senderID;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String? senderName;
  final String? senderAvatar;

  const _Message({
    required this.id,
    required this.conversationID,
    required this.senderID,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.senderName,
    this.senderAvatar,
  });

  factory _Message.fromJson(Map<String, dynamic> j) => _Message(
        id: j['id'],
        conversationID: j['conversationID'],
        senderID: j['senderID'],
        body: j['body'] ?? '',
        isRead: j['isRead'] == 1 || j['isRead'] == true,
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        senderName: j['senderName'],
        senderAvatar: j['senderAvatar'],
      );
}

class ClientConversationScreen extends StatefulWidget {
  final int conversationID;
  final int clientID;
  final String token;
  final String? coachName;
  final String? coachAvatar;
  final String? coachSpeciality;

  const ClientConversationScreen({
    super.key,
    required this.conversationID,
    required this.clientID,
    required this.token,
    this.coachName,
    this.coachAvatar,
    this.coachSpeciality,
  });

  @override
  State<ClientConversationScreen> createState() => _ClientConversationScreenState();
}

class _ClientConversationScreenState extends State<ClientConversationScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<_Message> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  Timer? _refreshTimer;

  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + widget.token,
      };

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchMessages(silent: true);
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 100 && !_loadingMore && _hasMore) {
      _loadMore();
    }
  }

  String _getMessagesUrl(int pageNum) {
    return _baseUrl +
        '/messages/' +
        widget.conversationID.toString() +
        '?page=' +
        pageNum.toString() +
        '&limit=50' +
        '&readerID=' +
        widget.clientID.toString();
  }

  String _getSendUrl() {
    return _baseUrl + '/messages/' + widget.conversationID.toString();
  }

  Future<void> _fetchMessages({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final url = _getMessagesUrl(1);
      final res = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        final msgs = data.map((e) => _Message.fromJson(e as Map<String, dynamic>)).toList();

        if (mounted) {
          setState(() {
            _messages = msgs;
            _loading = false;
            _error = null;
          });
          _scrollToBottom();
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Erreur (' + res.statusCode.toString() + ')';
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Serveur inaccessible';
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final url = _getMessagesUrl(nextPage);
      final res = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        final newMsgs = data.map((e) => _Message.fromJson(e as Map<String, dynamic>)).toList();

        if (mounted) {
          setState(() {
            if (newMsgs.isEmpty) {
              _hasMore = false;
            } else {
              _messages.insertAll(0, newMsgs);
              _page = nextPage;
            }
            _loadingMore = false;
          });
        }
      } else {
        setState(() => _loadingMore = false);
      }
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    _msgCtrl.clear();

    try {
      final url = _getSendUrl();
      final res = await http
          .post(
            Uri.parse(url),
            headers: _headers,
            body: jsonEncode({
              'senderID': widget.clientID,
              'body': text,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 201) {
        await _fetchMessages(silent: true);
      } else {
        _msgCtrl.text = text;
      }
    } catch (_) {
      _msgCtrl.text = text;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  bool _isMe(_Message msg) => msg.senderID == widget.clientID;

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  List<dynamic> _buildTimeline() {
    final items = <dynamic>[];
    DateTime? lastDate;
    for (final m in _messages) {
      final d = DateTime(m.createdAt.year, m.createdAt.month, m.createdAt.day);
      if (lastDate == null || d != lastDate) {
        items.add(d);
        lastDate = d;
      }
      items.add(m);
    }
    return items;
  }

  String _formatDivider(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return 'Hier';
    const m = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return d.day.toString() + ' ' + m[d.month - 1] + ' ' + d.year.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              right: -80,
              top: 60,
              child: _LogoWatermark(size: 300),
            ),
            Column(
              children: [
                Expanded(child: _buildMessagesList()),
                _buildInputBar(),
              ],
            ),
          ],
        ),
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
      title: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _lime, width: 2),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF1A1A1A),
              backgroundImage: widget.coachAvatar != null && widget.coachAvatar!.isNotEmpty
                  ? NetworkImage(widget.coachAvatar!)
                  : null,
              child: (widget.coachAvatar == null || widget.coachAvatar!.isEmpty)
                  ? Text(
                      widget.coachName != null && widget.coachName!.isNotEmpty ? widget.coachName![0].toUpperCase() : '?',
                      style: const TextStyle(color: _lime, fontSize: 14, fontWeight: FontWeight.w900),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.coachName ?? 'Conversation',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.coachSpeciality != null)
                  Text(
                    widget.coachSpeciality!,
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white54, size: 20),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _cardBorder),
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: _lime, strokeWidth: 2),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.error_outline_rounded, color: Colors.white24, size: 40),
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.white38, fontSize: 13)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _fetchMessages,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _lime.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _lime.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'RÉESSAYER',
                    style: TextStyle(color: _lime, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: _lime.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(Icons.chat_bubble_outline_rounded, color: _lime.withOpacity(0.4), size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Commencez la conversation',
              style: TextStyle(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Envoyez votre premier message',
              style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12),
            ),
          ],
        ),
      );
    }

    final timeline = _buildTimeline();

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: timeline.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (_loadingMore && i == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(color: _lime, strokeWidth: 2),
              ),
            ),
          );
        }

        final item = timeline[i - (_loadingMore ? 1 : 0)];

        if (item is DateTime) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _cardBorder, width: 1),
                ),
                child: Text(
                  _formatDivider(item),
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ),
            ),
          );
        }

        final msg = item as _Message;
        final isMe = _isMe(msg);
        final idx = _messages.indexOf(msg);
        final next = idx + 1 < _messages.length ? _messages[idx + 1] : null;
        final isLastOfGroup = next == null || next.senderID != msg.senderID || !_isSameDay(next.createdAt, msg.createdAt);
        final showAvatar = !isMe && isLastOfGroup;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe)
                SizedBox(
                  width: 32,
                  child: showAvatar
                      ? Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _lime.withOpacity(0.3), width: 1.5),
                          ),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xFF1A1A1A),
                            backgroundImage: msg.senderAvatar != null && msg.senderAvatar!.isNotEmpty
                                ? NetworkImage(msg.senderAvatar!)
                                : null,
                            child: (msg.senderAvatar == null || msg.senderAvatar!.isEmpty)
                                ? Text(
                                    msg.senderName != null && msg.senderName!.isNotEmpty ? msg.senderName![0].toUpperCase() : '?',
                                    style: const TextStyle(color: _lime, fontSize: 10, fontWeight: FontWeight.w900),
                                  )
                                : null,
                          ),
                        )
                      : null,
                ),
              if (!isMe) const SizedBox(width: 8),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? _lime : _card,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: isMe ? null : Border.all(color: _cardBorder, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        msg.body,
                        style: TextStyle(color: isMe ? Colors.black : Colors.white, fontSize: 13.5, height: 1.4),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(msg.createdAt),
                            style: TextStyle(
                              color: isMe ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.3),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              msg.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                              color: Colors.black.withOpacity(0.5),
                              size: 12,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: _card,
        border: Border(top: BorderSide(color: _cardBorder, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _cardBorder, width: 1),
              ),
              child: TextField(
                controller: _msgCtrl,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Écrivez un message...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: (_sending || _msgCtrl.text.trim().isEmpty) ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (_sending || _msgCtrl.text.trim().isEmpty) ? _lime.withOpacity(0.25) : _lime,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _sending
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime d) {
    return d.hour.toString().padLeft(2, '0') + ':' + d.minute.toString().padLeft(2, '0');
  }
}