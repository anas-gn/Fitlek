import '../../components/ENG/chatImageBatchPreview.dart';
import '../../components/ENG/chatSelection.dart';
import '../../services/chat_media_store.dart';
import '../../components/ENG/localChatMedia.dart';
import '../../services/media_picker_service.dart';
import '../../services/live_updates.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/coachConversation.dart';
import '../../models/coachMessage.dart';
import '../../services/apiService.dart';

import '../../theme/fitlek_theme_extension.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
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

class _CoachChatState extends State<CoachChat> with LiveUpdates<CoachChat> {
  StreamSubscription<Map<String, dynamic>>? _socketMessages;
  @override
  Set<String> get liveDomains => {'read_receipts', 'chat-actions', 'all'};
  @override
  Future<void> refreshLiveData() async {
    await _loadMessages(silent: true);
  }

  bool _selecting = false;
  bool _deleting = false;
  final Set<int> _selected = {};
  void _toggleSelected(int id) {
    if (id <= 0 || _deleting) return;
    if (!_selected.contains(id) && _selected.length >= 100) {
      ApiService.showError(context, 'Select up to 100 messages at a time.');
      return;
    }
    setState(() {
      _selecting = true;
      if (!_selected.add(id)) _selected.remove(id);
    });
  }

  Widget _selectionBar() => ChatSelectionBar(
      count: _selected.length,
      onClose: () => setState(() {
            _selecting = false;
            _selected.clear();
          }),
      onSelectAll: () => setState(() {
            _selected.addAll(_messages
                .map((m) => int.tryParse(m.id) ?? 0)
                .where((id) => id > 0)
                .take(100));
          }),
      onDelete: _deleteSelected);
  Future<void> _deleteSelected() async {
    if (_deleting || _selected.isEmpty) return;
    final selected = _messages
        .where((m) => _selected.contains(int.tryParse(m.id) ?? 0))
        .toList();
    final now = DateTime.now();
    final everyone = selected.isNotEmpty &&
        selected.every((m) =>
            m.isFromCoach &&
            !m.deleted &&
            now.difference(m.timestamp).inSeconds < 1800);
    final scope = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text('Delete ${_selected.length} messages?'),
                content: const Text(
                    'Delete for everyone is available for your own messages during the first 30 minutes.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, 'me'),
                      child: const Text('Delete for me')),
                  if (everyone)
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, 'everyone'),
                        child: const Text('Delete for everyone'))
                ]));
    if (scope == null || !mounted) return;
    _deleting = true;
    final ids = _selected.toList();
    try {
      final result = await ApiService.post(
          '/chat-actions/${widget.conversation.id}/delete',
          {'messageIDs': ids, 'scope': scope});
      if (!mounted) return;
      if (result['ok'] != true) {
        ApiService.showError(
            context, result['message'] ?? 'Could not delete messages.');
        return;
      }
      for (final id in ids) {
        try {
          await ChatMediaStore.instance.deleteLocal(id, removeThumbnail: true);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => ids.contains(int.tryParse(m.id) ?? 0));
        _selected.clear();
        _selecting = false;
      });
      await _loadMessages(silent: true);
    } finally {
      _deleting = false;
    }
  }

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
    _socketMessages?.cancel();
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
    _socketMessages?.cancel();
    _socketMessages = socketService.messages.listen((data) {
      if (!mounted) return;
      // If message is from someone else, we add it to the list
      if (data['conversationID'].toString() == widget.conversation.id &&
          data['senderID'].toString() != _coachID &&
          !_messages.any((m) => m.id == data['id'].toString())) {
        setState(() {
          _messages.add(CoachMessage(
            id: data['id'].toString(),
            conversationId: widget.conversation.id,
            senderId: data['senderID'].toString(),
            text: data['body'],
            mediaUrl: data['mediaUrl'],
            mediaType: data['mediaType'] ?? 'text',
            mediaExpired:
                data['mediaExpired'] == 1 || data['mediaExpired'] == true,
            timestamp: data['createdAt'] != null
                ? DateTime.parse(data['createdAt'])
                : DateTime.now(),
            isFromCoach: false,
            isRead: data['isRead'] == 1 || data['isRead'] == true,
          ));
        });
        _scrollToBottom();
        _loadMessages(silent: true);
      }
    });
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final result =
        await ApiService.get('/coach/chat/${widget.conversation.id}');
    if (!mounted) return;
    if (result['ok'] == true) {
      final list = List<dynamic>.from(result['data'] ?? []);
      setState(() {
        _messages = list
            .map((m) => CoachMessage(
                  id: m['id'].toString(),
                  conversationId: widget.conversation.id,
                  senderId: m['senderID'].toString(),
                  deleted: m['deletedAt'] != null,
                  text: m['body'],
                  mediaUrl: m['mediaUrl'],
                  mediaType: m['mediaType'] ?? 'text',
                  mediaExpired:
                      m['mediaExpired'] == 1 || m['mediaExpired'] == true,
                  timestamp: m['createdAt'] != null
                      ? DateTime.parse(m['createdAt'])
                      : DateTime.now(),
                  isFromCoach: m['senderID'].toString() == _coachID,
                  isRead: m['isRead'] == 1 || m['isRead'] == true,
                ))
            .toList();
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
            duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _sendMessage() async {
    if (_batchSending) return;
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
      isRead: false,
    );
    setState(() => _messages.add(tempMsg));
    _scrollToBottom();

    final result = await ApiService.post(
        '/coach/chat/${widget.conversation.id}',
        {'body': text, 'mediaType': 'text'});
    if (!mounted) return;
    if (result['ok'] != true) {
      setState(() => _messages.remove(tempMsg));
      ApiService.showError(context, result['message'] ?? 'Send failed.');
    } else {
      setState(() => _messages.remove(tempMsg));
      await _loadMessages(silent: true);
    }
  }

  void _showAttachOptions() {
    if (_batchSending || _isUploadingMedia) return;
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.fitlek.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _attachOption(Icons.camera_alt_rounded, 'Camera', cs.primary, () {
                Navigator.pop(context);
                _pickAndSendSingleImage(ImageSource.camera);
              }),
              _attachOption(Icons.photo_library_rounded, 'Gallery', cs.primary,
                  () {
                Navigator.pop(context);
                _pickAndSendMultipleImages();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachOption(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<String?> _showCaptionDialog(XFile file) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.fitlek.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.all(16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: kIsWeb
                  ? Image.network(file.path, height: 200, fit: BoxFit.cover)
                  : Image.file(File(file.path), height: 200, fit: BoxFit.cover),
            ),
            SizedBox(height: 16),
            TextField(
              controller: ctrl,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Ajouter une lÃ©gende...',
                hintStyle: TextStyle(color: context.fitlek.textMuted),
                border: InputBorder.none,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Annuler',
                  style: TextStyle(color: context.fitlek.textMuted))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: Text('Envoyer',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary))),
        ],
      ),
    );
  }

  Future<void> _pickAndSendSingleImage(ImageSource source) async {
    final picker = AppMediaPicker(context);
    final xFile = await picker.pickImage(source: source, imageQuality: 70);
    if (xFile == null) return;

    final caption = await _showCaptionDialog(xFile);
    if (caption == null) return;

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
      await _sendMediaMessage(result['url'], 'image', caption: caption);
    } else {
      setState(() => _isUploadingMedia = false);
      ApiService.showError(
          context, result['message']?.toString() ?? 'Image upload failed');
    }
  }

  bool _batchSending = false;
  int _batchCurrent = 0, _batchTotal = 0;
  Future<void> _pickAndSendMultipleImages() async {
    if (_batchSending || _isUploadingMedia) return;
    final files =
        await AppMediaPicker(context).pickMultiImage(imageQuality: 85);
    if (!mounted || files.isEmpty) return;
    if (files.length > 30) {
      ApiService.showError(context, 'Choose up to 30 photos per batch.');
      return;
    }
    final caption = await previewChatImages(context, files);
    if (!mounted || caption == null) return;
    setState(() {
      _batchSending = true;
      _isUploadingMedia = true;
      _batchTotal = files.length;
    });
    int failed = 0;
    try {
      for (int i = 0; i < files.length; i++) {
        if (!mounted) return;
        setState(() {
          _batchCurrent = i + 1;
          _isUploadingMedia = true;
        });
        try {
          final result = await ApiService.uploadMultipart('/upload/chat-image',
              fields: {},
              fileBytes: await files[i].readAsBytes(),
              fileField: 'image',
              fileName: files[i].name,
              mimeType: 'image/jpeg');
          if (!mounted) return;
          if (result['ok'] == true && result['url'] != null) {
            if (!await _sendMediaMessage(result['url'], 'image',
                caption: i == 0 ? caption : null)) failed++;
          } else {
            failed++;
          }
        } catch (_) {
          failed++;
        }
      }
      if (mounted && failed > 0)
        ApiService.showError(
            context, '$failed photos could not be sent. The others were sent.');
    } finally {
      if (mounted)
        setState(() {
          _batchSending = false;
          _isUploadingMedia = false;
        });
    }
  }

  Future<void> _toggleRecording() async {
    if (_batchSending) return;
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
          await _audioRecorder.start(RecordConfig(encoder: AudioEncoder.aacLc),
              path: '');
        } else {
          final dir = await getTemporaryDirectory();
          final path =
              '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _audioRecorder.start(RecordConfig(encoder: AudioEncoder.aacLc),
              path: path);
        }
        setState(() => _isRecording = true);
      } else if (mounted) {
        ApiService.showError(context,
            'Allow microphone access for Sirvya in your phone Settings to record voice messages.');
      }
    }
  }

  Future<bool> _sendMediaMessage(String url, String type,
      {String? caption}) async {
    final tempMsg = CoachMessage(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversation.id,
      senderId: _coachID ?? '',
      text: caption,
      mediaUrl: url,
      mediaType: type,
      timestamp: DateTime.now(),
      isFromCoach: true,
      isRead: false,
    );
    setState(() {
      _messages.add(tempMsg);
      _isUploadingMedia = false;
    });
    _scrollToBottom();

    final result =
        await ApiService.post('/coach/chat/${widget.conversation.id}', {
      'body': caption,
      'mediaUrl': url,
      'mediaType': type,
    });
    if (!mounted) return false;
    if (result['ok'] != true) {
      setState(() => _messages.remove(tempMsg));
      ApiService.showError(context, result['message'] ?? 'Send failed.');
    } else {
      setState(() => _messages.remove(tempMsg));
      await _loadMessages(silent: true);
      return true;
    }
    return false;
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
      body: SafeArea(
          child: Column(children: [
        _buildAppBar(),
        Container(
          width: double.infinity,
          color: context.fitlek.card,
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 16, color: context.fitlek.textMuted),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  _batchSending
                      ? 'Sending photo $_batchCurrent of $_batchTotal…'
                      : 'Photos and voice messages are saved on your phone. Use Select messages to delete in bulk.',
                  style: TextStyle(
                      color: context.fitlek.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        Expanded(
            child: _loading
                ? Center(
                    child:
                        CircularProgressIndicator(color: context.fitlek.border))
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => SelectableChatMessage(
                        selecting: _selecting,
                        selected:
                            _selected.contains(int.tryParse(_messages[i].id)),
                        onToggle: () =>
                            _toggleSelected(int.tryParse(_messages[i].id) ?? 0),
                        child: _buildBubble(_messages[i])))),
        _buildInputBar(),
      ])),
    );
  }

  Widget _buildAppBar() {
    if (_selecting) return _selectionBar();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(bottom: BorderSide(color: context.fitlek.card))),
      child: Row(children: [
        GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: Theme.of(context).colorScheme.onSurface, size: 24),
            )),
        SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            if (widget.conversation.clientPhotoUrl.isNotEmpty) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ImagePreview(
                          imageUrl: widget.conversation.clientPhotoUrl,
                          tag: 'header_avatar')));
            }
          },
          child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.fitlek.border, width: 1.5)),
              child: ClipOval(
                  child: widget.conversation.clientPhotoUrl.isNotEmpty
                      ? Image.network(widget.conversation.clientPhotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.person,
                              color: context.fitlek.textMuted, size: 20))
                      : Icon(Icons.person,
                          color: context.fitlek.textMuted, size: 20))),
        ),
        SizedBox(width: 12),
        Expanded(
            child: Text(widget.conversation.clientName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold))),
        IconButton(
            tooltip: 'Select messages',
            onPressed: () => setState(() => _selecting = true),
            icon: const Icon(Icons.checklist)),
        _buildMoreMenu(),
      ]),
    );
  }

  Widget _buildBubble(CoachMessage message) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final isCoach = message.isFromCoach;
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isCoach ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCoach) ...[
            Container(
                width: 30,
                height: 30,
                margin: EdgeInsets.only(right: 8, bottom: 2),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: f.border)),
                child: ClipOval(
                    child: widget.conversation.clientPhotoUrl.isNotEmpty
                        ? Image.network(widget.conversation.clientPhotoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.person,
                                color: f.textMuted, size: 14))
                        : Icon(Icons.person, color: f.textMuted, size: 14))),
          ],
          Flexible(
              child: Column(
            crossAxisAlignment:
                isCoach ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.68),
                padding: EdgeInsets.all(
                    message.mediaType == 'image' && !message.mediaExpired
                        ? 4
                        : 10),
                decoration: BoxDecoration(
                  color: isCoach
                      ? Theme.of(context).colorScheme.primary
                      : context.fitlek.border,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(isCoach ? 16 : 4),
                      bottomRight: Radius.circular(isCoach ? 4 : 16)),
                ),
                child: _buildBubbleContent(message, isCoach),
              ),
              SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(_formatTime(message.timestamp),
                      style: TextStyle(
                          color: isCoach
                              ? Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withValues(alpha: 0.6)
                              : context.fitlek.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500)),
                  if (isCoach) ...[
                    SizedBox(width: 4),
                    Icon(
                      message.isRead
                          ? Icons.done_all_rounded
                          : Icons.done_rounded,
                      color: message.isRead
                          ? Color(0xFF00A884)
                          : Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withValues(alpha: 0.6),
                      size: 14,
                    ),
                  ],
                ],
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildBubbleContent(CoachMessage message, bool isCoach) {
    final fgColor = isCoach
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;

    if (message.deleted)
      return Text(
          isCoach
              ? 'You deleted this message'
              : 'This message was deleted by the sender',
          style: TextStyle(color: fgColor, fontStyle: FontStyle.italic));
    if (message.mediaType == 'image' || message.mediaType == 'audio') {
      return LocalChatMedia(
          key: ValueKey('media_${message.id}'),
          messageID: int.tryParse(message.id) ?? 0,
          url: message.mediaUrl,
          type: message.mediaType,
          expired: message.mediaExpired,
          isMe: isCoach,
          caption: message.text);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5),
      child: Text(message.text ?? '',
          style: TextStyle(
              color: fgColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4)),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration:
          BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
      child: Row(children: [
        GestureDetector(
          onTap: _showAttachOptions,
          child: Padding(
            padding: EdgeInsets.only(bottom: 10, right: 8),
            child: Icon(Icons.add,
                color: Theme.of(context).colorScheme.onSurface, size: 28),
          ),
        ),
        Expanded(
            child: Container(
          decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.fitlek.border, width: 1.5)),
          child: TextField(
            controller: _msgCtrl,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface, fontSize: 15),
            decoration: InputDecoration(
                hintText:
                    _isRecording ? 'Recording...' : 'Ã‰crire un message...',
                hintStyle:
                    TextStyle(color: context.fitlek.textMuted, fontSize: 15),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            onSubmitted: (_) => _sendMessage(),
            readOnly: _isRecording || _isUploadingMedia,
          ),
        )),
        SizedBox(width: 10),
        if (_isUploadingMedia)
          SizedBox(
              width: 46,
              height: 46,
              child: Center(
                  child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                      strokeWidth: 2)))
        else if (_msgCtrl.text.isEmpty && !_isRecording)
          GestureDetector(
              onTap: _toggleRecording,
              child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: context.fitlek.border, shape: BoxShape.circle),
                  child: Icon(Icons.mic_none_rounded,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 22)))
        else if (_isRecording)
          GestureDetector(
              onTap: _toggleRecording,
              child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.redAccent.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: Offset(0, 4))
                      ]),
                  child: Icon(Icons.stop_rounded,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 20)))
        else
          GestureDetector(
              onTap: _sendMessage,
              child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: context.fitlek.border, shape: BoxShape.circle),
                  child: Icon(Icons.send_rounded,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 20))),
      ]),
    );
  }

  Widget _buildMoreMenu() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded,
          color: Theme.of(context).colorScheme.onSurface, size: 24),
      color: context.fitlek.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: Offset(0, 40),
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
              Icon(Icons.flag_rounded,
                  color: context.fitlek.textMuted, size: 18),
              SizedBox(width: 8),
              Text('Report Client',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'block',
          child: Row(
            children: [
              Icon(Icons.block_rounded, color: context.fitlek.error, size: 18),
              SizedBox(width: 8),
              Text('Block Client',
                  style: TextStyle(
                      color: context.fitlek.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  void _showReportDialog() {
    String? selectedReason;
    final reasons = [
      'Spam',
      'Harassment',
      'Inappropriate content',
      'Fraud / Scam',
      'Other'
    ];
    final name = widget.conversation.clientName.isNotEmpty
        ? widget.conversation.clientName
        : 'this client';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: context.fitlek.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Report $name',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Why are you reporting this user? We take these reports seriously.',
                  style:
                      TextStyle(color: context.fitlek.textMuted, fontSize: 13)),
              SizedBox(height: 16),
              ...reasons.map((r) => RadioListTile<String>(
                    title: Text(r,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 13)),
                    value: r,
                    groupValue: selectedReason,
                    activeColor: Theme.of(context).colorScheme.primary,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onChanged: (val) =>
                        setDialogState(() => selectedReason = val),
                  )),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: TextStyle(color: context.fitlek.textMuted))),
            TextButton(
              onPressed: selectedReason == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      _submitReport(selectedReason!);
                    },
              child: Text('Submit',
                  style: TextStyle(
                      color: selectedReason == null
                          ? context.fitlek.textMuted
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold)),
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
    final name = widget.conversation.clientName.isNotEmpty
        ? widget.conversation.clientName
        : 'this client';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.fitlek.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Block $name?',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text(
          'They won\'t be able to find your profile or send you messages. They will not be notified that you blocked them.',
          style: TextStyle(color: context.fitlek.textMuted),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(color: context.fitlek.textMuted))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              _submitBlock();
            },
            child: Text('Block',
                style: TextStyle(
                    color: context.fitlek.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitBlock() async {
    try {
      final res = await ApiService.post('/ugc/block-conversation',
          {'conversationID': int.tryParse(widget.conversation.id) ?? 0});
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
