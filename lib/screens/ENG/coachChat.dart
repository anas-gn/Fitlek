import 'package:flutter/material.dart';
import '../../models/coachConversation.dart';
import '../../models/coachMessage.dart';
import '../../services/apiService.dart';

import '../../theme/fitlek_theme_extension.dart';
class CoachChat extends StatefulWidget {
  final CoachConversation conversation;
  const CoachChat({super.key, required this.conversation});
  @override
  State<CoachChat> createState() => _CoachChatState();
}

class _CoachChatState extends State<CoachChat> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _loading = true;
  List<CoachMessage> _messages = [];
  String? _coachID;

  @override
  void initState() {
    super.initState();
    _loadCoachId();
  }

  @override
  void dispose() { _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  Future<void> _loadCoachId() async {
    final profile = await ApiService.get('/coach/profile');
    if (!mounted) return;
    if (profile['ok'] == true) {
      _coachID = profile['id'].toString();
    }
    await _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    final result = await ApiService.get('/coach/chat/${widget.conversation.id}');
    if (!mounted) return;
    if (result['ok'] == true) {
      final list = List<dynamic>.from(result['data'] ?? []);
      setState(() {
        _messages = list.map((m) => CoachMessage(
          id: m['id'].toString(),
          conversationId: widget.conversation.id,
          senderId: m['senderID'].toString(),
          text: m['body'] ?? '',
          timestamp: m['createdAt'] != null ? DateTime.parse(m['createdAt']) : DateTime.now(),
          isFromCoach: m['senderID'].toString() == _coachID,
        )).toList();
        _loading = false;
      });
      _scrollToBottom();
    } else {
      setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();

    // Optimistic add
    final tempMsg = CoachMessage(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversation.id,
      senderId: _coachID ?? '',
      text: text,
      timestamp: DateTime.now(),
      isFromCoach: true,
    );
    setState(() => _messages.add(tempMsg));
    _scrollToBottom();

    final result = await ApiService.post('/coach/chat/${widget.conversation.id}', {'body': text});
    if (!mounted) return;
    if (result['ok'] != true) {
      setState(() => _messages.remove(tempMsg));
      ApiService.showError(context, result['message'] ?? 'Send failed.');
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(child: Column(children: [
        _buildAppBar(),
        Expanded(child: _loading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _buildBubble(_messages[i]))),
        _buildInputBar(),
      ])),
    );
  }

  Widget _buildAppBar() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, border: Border(bottom: BorderSide(color: f.border))),
    child: Row(children: [
      GestureDetector(onTap: () => Navigator.of(context).pop(),
        child: Container(width: 38, height: 38,
          decoration: BoxDecoration(color: f.card, borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface, size: 17))),
      const SizedBox(width: 12),
      Container(width: 40, height: 40,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: cs.primary.withValues(alpha: 0.4), width: 1.5)),
        child: ClipOval(child: widget.conversation.clientPhotoUrl.isNotEmpty
          ? Image.network(widget.conversation.clientPhotoUrl, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(Icons.person, color: f.textMuted, size: 20))
          : Icon(Icons.person, color: f.textMuted, size: 20))),
      const SizedBox(width: 10),
      Expanded(child: Text(widget.conversation.clientName,
        maxLines: 1, overflow: TextOverflow.ellipsis,
        style: TextStyle(color: cs.onSurface, fontSize: 15, fontWeight: FontWeight.w700))),
    ]),
  );
  }

  Widget _buildBubble(CoachMessage message) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final isCoach = message.isFromCoach;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isCoach ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCoach) ...[
            Container(width: 30, height: 30, margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: f.border)),
              child: ClipOval(child: widget.conversation.clientPhotoUrl.isNotEmpty
                ? Image.network(widget.conversation.clientPhotoUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.person, color: f.textMuted, size: 14))
                : Icon(Icons.person, color: f.textMuted, size: 14))),
          ],
          Flexible(child: Column(
            crossAxisAlignment: isCoach ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  color: isCoach ? cs.primary : f.card,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isCoach ? 18 : 4),
                    bottomRight: Radius.circular(isCoach ? 4 : 18)),
                  boxShadow: isCoach ? [BoxShadow(color: cs.primary.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))] : null),
                child: Text(message.text, style: TextStyle(color: isCoach ? cs.onPrimary : cs.onSurface, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4))),
              const SizedBox(height: 4),
              Text(_formatTime(message.timestamp), style: TextStyle(color: f.textMuted, fontSize: 10, fontWeight: FontWeight.w500)),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
    decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, border: Border(top: BorderSide(color: f.border))),
    child: Row(children: [
      Expanded(child: Container(
        decoration: BoxDecoration(color: f.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: f.border)),
        child: TextField(
          controller: _msgCtrl,
          style: TextStyle(color: cs.onSurface, fontSize: 14),
          decoration: InputDecoration(hintText: 'Type a message...', hintStyle: TextStyle(color: f.textMuted, fontSize: 14),
            border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
          onSubmitted: (_) => _sendMessage()),
      )),
      const SizedBox(width: 10),
      GestureDetector(onTap: _sendMessage,
        child: Container(width: 46, height: 46,
          decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]),
          child: Icon(Icons.send_rounded, color: cs.onPrimary, size: 20))),
    ]),
  );
  }
}
