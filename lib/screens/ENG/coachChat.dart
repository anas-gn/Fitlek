import 'package:flutter/material.dart';
import '../../models/coachConversation.dart';
import '../../models/coachMessage.dart';
import '../../services/apiService.dart';

import '../../theme/fitlek_theme_extension.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../components/ENG/audioPlayerWidget.dart';
import '../../components/ENG/imagePreview.dart';
import '../../services/socketService.dart';
import 'package:flutter/foundation.dart'; // Add kIsWeb
import 'package:http/http.dart' as http; // Add http

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

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordedFilePath;
  bool _isUploadingMedia = false;

  @override
  void initState() {
    super.initState();
    _loadCoachId();
  }

  @override
  void dispose() {
    SocketService().offNewMessage();
    SocketService().leaveRoom(widget.conversation.id);
    _msgCtrl.dispose(); 
    _scrollCtrl.dispose(); 
    _audioRecorder.dispose();
    super.dispose(); 
  }

  Future<void> _loadCoachId() async {
    final profile = await ApiService.get('/coach/profile');
    if (!mounted) return;
    if (profile['ok'] == true) {
      _coachID = profile['id'].toString();
    }
    await _loadMessages();
    _initSocket();
  }

  void _initSocket() {
    final socketService = SocketService();
    socketService.connect();
    socketService.joinRoom(widget.conversation.id);
    socketService.onNewMessage((data) {
      if (!mounted) return;
      // If message is from someone else, we add it to the list
      if (data['senderID'].toString() != _coachID) {
        setState(() {
          _messages.add(CoachMessage(
            id: data['id'].toString(),
            conversationId: widget.conversation.id,
            senderId: data['senderID'].toString(),
            text: data['body'],
            mediaUrl: data['mediaUrl'],
            mediaType: data['mediaType'] ?? 'text',
            mediaExpired: data['mediaExpired'] == 1 || data['mediaExpired'] == true,
            timestamp: data['createdAt'] != null ? DateTime.parse(data['createdAt']) : DateTime.now(),
            isFromCoach: false,
          ));
        });
        _scrollToBottom();
      }
    });
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
          text: m['body'],
          mediaUrl: m['mediaUrl'],
          mediaType: m['mediaType'] ?? 'text',
          mediaExpired: m['mediaExpired'] == 1 || m['mediaExpired'] == true,
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

    final result = await ApiService.post('/coach/chat/${widget.conversation.id}', {'body': text, 'mediaType': 'text'});
    if (!mounted) return;
    if (result['ok'] != true) {
      setState(() => _messages.remove(tempMsg));
      ApiService.showError(context, result['message'] ?? 'Send failed.');
    }
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (xFile == null) return;

    setState(() => _isUploadingMedia = true);
    final bytes = await xFile.readAsBytes();
    final result = await ApiService.uploadMultipart(
      '/upload/chat-image',
      fields: {},
      fileBytes: bytes,
      fileField: 'image',
      fileName: xFile.name,
      mimeType: 'image/webp',
    );

    if (!mounted) return;
    if (result['ok'] == true && result['url'] != null) {
      await _sendMediaMessage(result['url'], 'image');
    } else {
      setState(() => _isUploadingMedia = false);
      ApiService.showError(context, 'Image upload failed');
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        setState(() => _isUploadingMedia = true);
        Uint8List bytes;
        if (kIsWeb) {
          final res = await http.get(Uri.parse(path));
          bytes = res.bodyBytes;
        } else {
          final file = File(path);
          bytes = await file.readAsBytes();
        }
        
        final result = await ApiService.uploadMultipart(
          '/upload/chat-audio',
          fields: {},
          fileBytes: bytes,
          fileField: 'audio',
          fileName: 'audio.m4a',
          mimeType: 'audio/mp4',
        );

        if (!mounted) return;
        if (result['ok'] == true && result['url'] != null) {
          await _sendMediaMessage(result['url'], 'audio');
        } else {
          setState(() => _isUploadingMedia = false);
          ApiService.showError(context, 'Audio upload failed');
        }
      }
    } else {
      if (await _audioRecorder.hasPermission()) {
        if (kIsWeb) {
          await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: '');
        } else {
          final dir = await getTemporaryDirectory();
          final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
        }
        setState(() => _isRecording = true);
      }
    }
  }

  Future<void> _sendMediaMessage(String url, String type) async {
    final tempMsg = CoachMessage(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversation.id,
      senderId: _coachID ?? '',
      text: null,
      mediaUrl: url,
      mediaType: type,
      timestamp: DateTime.now(),
      isFromCoach: true,
    );
    setState(() {
      _messages.add(tempMsg);
      _isUploadingMedia = false;
    });
    _scrollToBottom();

    final result = await ApiService.post('/coach/chat/${widget.conversation.id}', {
      'body': null,
      'mediaUrl': url,
      'mediaType': type,
    });
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
        Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Media (images & audio) will be automatically removed after 7 days.',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
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
      _buildMoreMenu(),
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
                padding: EdgeInsets.all(message.mediaType == 'image' && !message.mediaExpired ? 4 : 11),
                decoration: BoxDecoration(
                  color: isCoach ? cs.primary : f.card,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isCoach ? 18 : 4),
                    bottomRight: Radius.circular(isCoach ? 4 : 18)),
                  boxShadow: isCoach ? [BoxShadow(color: cs.primary.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))] : null),
                child: _buildBubbleContent(message, isCoach),
              ),
              const SizedBox(height: 4),
              Text(_formatTime(message.timestamp), style: TextStyle(color: f.textMuted, fontSize: 10, fontWeight: FontWeight.w500)),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildBubbleContent(CoachMessage message, bool isCoach) {
    final cs = Theme.of(context).colorScheme;
    final fgColor = isCoach ? cs.onPrimary : cs.onSurface;

    if (message.mediaType == 'image') {
      if (message.mediaExpired || message.mediaUrl == null) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_not_supported_rounded, color: fgColor.withValues(alpha: 0.7), size: 20),
            const SizedBox(width: 8),
            Text('Image Expired', style: TextStyle(color: fgColor.withValues(alpha: 0.8), fontSize: 13, fontStyle: FontStyle.italic)),
          ],
        );
      }
      return GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => ImagePreview(imageUrl: message.mediaUrl!, tag: message.id),
          ));
        },
        child: Hero(
          tag: message.id,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CachedNetworkImage(
              imageUrl: message.mediaUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 150, height: 150, color: fgColor.withValues(alpha: 0.1),
                child: Center(child: CircularProgressIndicator(color: fgColor, strokeWidth: 2)),
              ),
              errorWidget: (context, url, error) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_not_supported_rounded, color: fgColor.withValues(alpha: 0.7), size: 20),
              const SizedBox(width: 8),
              Text('Image Expired', style: TextStyle(color: fgColor.withValues(alpha: 0.8), fontSize: 13, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ),
      ),
      );
    } else if (message.mediaType == 'audio') {
      return AudioPlayerWidget(
        url: message.mediaUrl,
        isMe: isCoach,
        isExpired: message.mediaExpired,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Text(message.text ?? '', style: TextStyle(color: fgColor, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4)),
    );
  }

  Widget _buildInputBar() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
    decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, border: Border(top: BorderSide(color: f.border))),
    child: Row(children: [
      GestureDetector(
        onTap: _pickAndSendImage,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.add_photo_alternate_rounded, color: f.textMuted, size: 24),
        ),
      ),
      Expanded(child: Container(
        decoration: BoxDecoration(color: f.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: f.border)),
        child: TextField(
          controller: _msgCtrl,
          style: TextStyle(color: cs.onSurface, fontSize: 14),
          decoration: InputDecoration(hintText: _isRecording ? 'Recording...' : 'Type a message...', hintStyle: TextStyle(color: f.textMuted, fontSize: 14),
            border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
          onSubmitted: (_) => _sendMessage(),
          readOnly: _isRecording || _isUploadingMedia,
        ),
      )),
      const SizedBox(width: 10),
      if (_isUploadingMedia)
        SizedBox(width: 46, height: 46, child: Center(child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2)))
      else if (_msgCtrl.text.isEmpty && !_isRecording)
        GestureDetector(onTap: _toggleRecording,
          child: Container(width: 46, height: 46,
            decoration: BoxDecoration(color: f.card, shape: BoxShape.circle, border: Border.all(color: f.border)),
            child: Icon(Icons.mic_none_rounded, color: cs.primary, size: 22)))
      else if (_isRecording)
        GestureDetector(onTap: _toggleRecording,
          child: Container(width: 46, height: 46,
            decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]),
            child: Icon(Icons.stop_rounded, color: Colors.white, size: 20)))
      else
        GestureDetector(onTap: _sendMessage,
          child: Container(width: 46, height: 46,
            decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]),
            child: Icon(Icons.send_rounded, color: cs.onPrimary, size: 20))),
    ]),
  );
  }

  Widget _buildMoreMenu() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: context.fitlek.textMuted, size: 20),
      color: context.fitlek.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 40),
      onSelected: (val) {
        if (val == 'report') {
          _showReportDialog();
        } else if (val == 'block') {
          _showBlockDialog();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.flag_rounded, color: context.fitlek.textMuted, size: 18),
              const SizedBox(width: 8),
              Text('Report Client', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'block',
          child: Row(
            children: [
              Icon(Icons.block_rounded, color: context.fitlek.error, size: 18),
              const SizedBox(width: 8),
              Text('Block Client', style: TextStyle(color: context.fitlek.error, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  void _showReportDialog() {
    String? selectedReason;
    final reasons = ['Spam', 'Harassment', 'Inappropriate content', 'Fraud / Scam', 'Other'];
    final name = widget.conversation.clientName.isNotEmpty ? widget.conversation.clientName : 'this client';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: context.fitlek.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Report $name', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Why are you reporting this user? We take these reports seriously.', style: TextStyle(color: context.fitlek.textMuted, fontSize: 13)),
              const SizedBox(height: 16),
              ...reasons.map((r) => RadioListTile<String>(
                title: Text(r, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13)),
                value: r,
                groupValue: selectedReason,
                activeColor: Theme.of(context).colorScheme.primary,
                contentPadding: EdgeInsets.zero,
                dense: true,
                onChanged: (val) => setDialogState(() => selectedReason = val),
              )),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: context.fitlek.textMuted))),
            TextButton(
              onPressed: selectedReason == null ? null : () async {
                Navigator.pop(ctx);
                _submitReport(selectedReason!);
              },
              child: Text('Submit', style: TextStyle(color: selectedReason == null ? context.fitlek.textMuted : Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport(String reason) async {
    try {
      final res = await ApiService.post('/ugc/report', {
        'reportedID': int.tryParse(widget.conversation.id) ?? 0,
        'reason': reason,
        'type': 'conversation',
      });
      if (res['ok'] == true) {
        ApiService.showSuccess(context, 'Report submitted successfully.');
      } else {
        ApiService.showError(context, 'Failed to submit report');
      }
    } catch (_) {
      ApiService.showError(context, 'Network error');
    }
  }

  void _showBlockDialog() {
    final name = widget.conversation.clientName.isNotEmpty ? widget.conversation.clientName : 'this client';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.fitlek.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Block $name?', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text(
          'They won\'t be able to find your profile or send you messages. They will not be notified that you blocked them.',
          style: TextStyle(color: context.fitlek.textMuted),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: context.fitlek.textMuted))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              _submitBlock();
            },
            child: Text('Block', style: TextStyle(color: context.fitlek.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitBlock() async {
    try {
      final res = await ApiService.post('/ugc/block-conversation', {'conversationID': int.tryParse(widget.conversation.id) ?? 0});
      if (res['ok'] == true) {
        ApiService.showSuccess(context, 'User blocked.');
        if (mounted) Navigator.pop(context);
      } else {
        ApiService.showError(context, 'Failed to block user');
      }
    } catch (_) {
      ApiService.showError(context, 'Network error');
    }
  }
}
