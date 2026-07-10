import 'package:flutter/material.dart';
import '../../models/coachConversation.dart';
import '../../models/coachMessage.dart';
import '../../services/apiService.dart';

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
      backgroundColor: Colors.black,
      body: SafeArea(child: Column(children: [
        _buildAppBar(),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFA3FF12)))
          : ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _buildBubble(_messages[i]))),
        _buildInputBar(),
      ])),
    );
  }

  Widget _buildAppBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(color: Colors.black, border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06)))),
    child: Row(children: [
      GestureDetector(onTap: () => Navigator.of(context).pop(),
        child: Container(width: 38, height: 38,
          decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 17))),
      const SizedBox(width: 12),
      Container(width: 40, height: 40,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFA3FF12).withOpacity(0.4), width: 1.5)),
        child: ClipOval(child: widget.conversation.clientPhotoUrl.isNotEmpty
          ? Image.network(widget.conversation.clientPhotoUrl, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white54, size: 20))
          : const Icon(Icons.person, color: Colors.white54, size: 20))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.conversation.clientName, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        Row(children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFA3FF12), shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text('Online', style: TextStyle(color: const Color(0xFFA3FF12).withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
        ]),
      ])),
      Container(width: 38, height: 38,
        decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.call_rounded, color: Color(0xFFA3FF12), size: 18)),
    ]),
  );

  Widget _buildBubble(CoachMessage message) {
    final isCoach = message.isFromCoach;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isCoach ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCoach) ...[
            Container(width: 30, height: 30, margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.1))),
              child: ClipOval(child: widget.conversation.clientPhotoUrl.isNotEmpty
                ? Image.network(widget.conversation.clientPhotoUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white54, size: 14))
                : const Icon(Icons.person, color: Colors.white54, size: 14))),
          ],
          Flexible(child: Column(
            crossAxisAlignment: isCoach ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  color: isCoach ? const Color(0xFFA3FF12) : const Color(0xFF161616),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isCoach ? 18 : 4),
                    bottomRight: Radius.circular(isCoach ? 4 : 18)),
                  boxShadow: isCoach ? [BoxShadow(color: const Color(0xFFA3FF12).withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))] : null),
                child: Text(message.text, style: TextStyle(color: isCoach ? Colors.black : Colors.white, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4))),
              const SizedBox(height: 4),
              Text(_formatTime(message.timestamp), style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 10, fontWeight: FontWeight.w500)),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildInputBar() => Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
    decoration: BoxDecoration(color: Colors.black, border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06)))),
    child: Row(children: [
      Expanded(child: Container(
        decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.08))),
        child: TextField(
          controller: _msgCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(hintText: 'Type a message...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
            border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
          onSubmitted: (_) => _sendMessage()),
      )),
      const SizedBox(width: 10),
      GestureDetector(onTap: _sendMessage,
        child: Container(width: 46, height: 46,
          decoration: BoxDecoration(color: const Color(0xFFA3FF12), shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: const Color(0xFFA3FF12).withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))]),
          child: const Icon(Icons.send_rounded, color: Colors.black, size: 20))),
    ]),
  );
}
