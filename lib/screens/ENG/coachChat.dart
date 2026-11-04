import '../../services/conversation_activity.dart';
import '../../components/ENG/conversationUi.dart';
import '../../components/app_dialog.dart';
import '../../components/ENG/chatImageBatchPreview.dart';
import '../../components/ENG/chatSelection.dart';
import '../../services/chat_media_store.dart';
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
  final Future<Map<String, dynamic>> Function(String)? loadData;
  final bool connectRealtime;
  const CoachChat(
      {super.key,
      required this.conversation,
      this.loadData,
      this.connectRealtime = true});
  @override
  State<CoachChat> createState() => _CoachChatState();
}

class _CoachChatState extends State<CoachChat> with LiveUpdates<CoachChat> {
  @override
  bool get enableLiveUpdates => widget.connectRealtime;
  Future<Map<String, dynamic>> _get(String path) =>
      widget.loadData?.call(path) ?? ApiService.get(path);
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
        builder: (ctx) => AppDialog(
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
  bool _showStorageNotice = true,
      _fetching = false,
      _fetchAgain = false,
      _olderFailed = false;
  int _unreadNew = 0;
  bool _recordBusy = false;
  late final ConversationActivity _activity;
  void _draftChanged() => _activity.textChanged(_msgCtrl.text);
  bool _isRecording = false;
  bool _sending = false, _loadingMore = false, _hasMore = true;
  int _page = 1;
  String? _error;
  bool _isUploadingMedia = false;

  @override
  void initState() {
    super.initState();
    _activity = ConversationActivity(
        conversationID: widget.conversation.id,
        userID: null,
        enabled: widget.connectRealtime);
    _msgCtrl.addListener(_draftChanged);
    _loadCoachId();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _msgCtrl.removeListener(_draftChanged);
    _activity.dispose();
    _socketMessages?.cancel();
    if (widget.connectRealtime) {
      SocketService().leaveRoom(widget.conversation.id);
    }
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _loadCoachId() async {
    final profile = await _get('/coach/profile');
    if (!mounted) return;
    if (profile['ok'] == true) {
      _coachID = profile['id'].toString();
    }
    _activity.userID = int.tryParse(_coachID ?? '');
    await _loadMessages();
    if (widget.connectRealtime) _initSocket();
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
        _activity.messageReceived(int.tryParse('${data['senderID']}') ?? -1);
        final follow = _nearLatest;
        setState(() {
          if (!follow) _unreadNew++;
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
        if (follow) _scrollToBottom();
        _loadMessages(silent: true);
      }
    });
  }

  bool get _nearLatest => !_scrollCtrl.hasClients || _scrollCtrl.offset < 80;
  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    if (_scrollCtrl.offset < 80 && _unreadNew > 0) {
      setState(() => _unreadNew = 0);
    }
    if (_scrollCtrl.position.maxScrollExtent > 0 &&
        _scrollCtrl.offset >= _scrollCtrl.position.maxScrollExtent - 160 &&
        !_loadingMore &&
        !_olderFailed &&
        _hasMore &&
        !_loading) {
      _loadOlder();
    }
  }

  CoachMessage _decode(Map<String, dynamic> m) => CoachMessage(
      id: '${m['id']}',
      conversationId: widget.conversation.id,
      senderId: '${m['senderID']}',
      deleted: m['deletedAt'] != null,
      text: m['body'],
      mediaUrl: m['mediaUrl'],
      mediaType: m['mediaType'] ?? 'text',
      mediaExpired: m['mediaExpired'] == 1 || m['mediaExpired'] == true,
      timestamp: DateTime.tryParse('${m['createdAt']}') ?? DateTime.now(),
      isFromCoach: '${m['senderID']}' == _coachID,
      isRead: m['isRead'] == 1 || m['isRead'] == true);
  String _historyUrl(int page) =>
      '/messages/${widget.conversation.id}?page=$page&limit=50&readerID=$_coachID';
  Future<void> _loadMessages({bool silent = false}) async {
    if (_fetching) {
      _fetchAgain = true;
      return;
    }
    _fetching = true;
    final initial = _messages.isEmpty;
    final follow = _nearLatest;
    if (mounted)
      setState(() {
        if (!silent && initial) _loading = true;
      });
    try {
      final result = await _get(_historyUrl(1));
      if (result['ok'] != true) throw Exception('Could not load messages');
      final rows = (result['data'] as List)
          .map((m) => _decode(Map<String, dynamic>.from(m)))
          .toList();
      if (!mounted) return;
      final last = _messages.isEmpty ? '' : _messages.last.id;
      setState(() {
        final merged = {for (final m in _messages) m.id: m};
        for (final m in rows) {
          merged[m.id] = m;
        }
        _messages = merged.values.toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        if (initial) {
          _page = 1;
          _hasMore = rows.length >= 50;
        }
        _loading = false;
        _error = null;
      });
      if (!initial &&
          follow &&
          _nearLatest &&
          rows.isNotEmpty &&
          rows.last.id != last) {
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not refresh messages. Check your connection.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _fetching = false);
      } else {
        _fetching = false;
      }
      if (_fetchAgain && mounted) {
        _fetchAgain = false;
        unawaited(_loadMessages(silent: true));
      }
    }
  }

  Future<void> _loadOlder() async {
    if (_loadingMore || !_hasMore) return;
    setState(() {
      _loadingMore = true;
      _olderFailed = false;
    });
    try {
      final result = await _get(_historyUrl(_page + 1));
      if (result['ok'] != true) throw Exception('Could not load messages');
      final rows = (result['data'] as List)
          .map((m) => _decode(Map<String, dynamic>.from(m)))
          .toList();
      if (!mounted) return;
      setState(() {
        final merged = {for (final m in _messages) m.id: m};
        for (final m in rows) {
          merged.putIfAbsent(m.id, () => m);
        }
        _messages = merged.values.toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _page++;
        _hasMore = rows.length >= 50;
      });
    } catch (_) {
      if (mounted) setState(() => _olderFailed = true);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _scrollToBottom() {
    if (_unreadNew > 0 && mounted) setState(() => _unreadNew = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic);
      }
    });
  }

  void _sendMessage() async {
    if (_batchSending || _sending || _isUploadingMedia) return;
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
    setState(() {
      _messages.add(tempMsg);
      _sending = true;
    });
    _scrollToBottom();

    final result = await ApiService.post(
        '/coach/chat/${widget.conversation.id}',
        {'body': text, 'mediaType': 'text'});
    if (!mounted) return;
    setState(() => _sending = false);
    if (result['ok'] != true) {
      _msgCtrl.text = text;
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
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
          const SizedBox(height: 8),
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
      builder: (ctx) => AppDialog(
        backgroundColor: context.fitlek.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: kIsWeb
                  ? Image.network(file.path, height: 200, fit: BoxFit.cover)
                  : Image.file(File(file.path), height: 200, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
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
    if (!mounted || caption == null) return;

    setState(() => _isUploadingMedia = true);
    try {
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
    } catch (_) {
      if (mounted) {
        ApiService.showError(
            context, 'Could not send the photo. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isUploadingMedia = false);
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
                caption: i == 0 ? caption : null)) {
              failed++;
            }
          } else {
            failed++;
          }
        } catch (_) {
          failed++;
        }
      }
      if (mounted && failed > 0) {
        ApiService.showError(
            context, '$failed photos could not be sent. The others were sent.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _batchSending = false;
          _isUploadingMedia = false;
        });
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (_batchSending || _recordBusy || _isUploadingMedia || _sending) return;
    setState(() => _recordBusy = true);
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        if (!mounted) return;
        setState(() => _isRecording = false);
        _activity.recording(false);
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
            await _audioRecorder.start(
                const RecordConfig(encoder: AudioEncoder.aacLc),
                path: '');
          } else {
            final dir = await getTemporaryDirectory();
            final path =
                '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
            await _audioRecorder.start(
                const RecordConfig(encoder: AudioEncoder.aacLc),
                path: path);
          }
          if (!mounted) {
            await _audioRecorder.stop();
            return;
          }
          setState(() => _isRecording = true);
          _activity.recording(true);
        } else if (mounted) {
          ApiService.showError(context,
              'Allow microphone access for Sirvya in your phone Settings to record voice messages.');
        }
      }
    } catch (_) {
      if (mounted) {
        ApiService.showError(
            context, 'Could not record or send audio. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _recordBusy = false;
          _isUploadingMedia = false;
        });
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
      _sending = true;
    });
    _scrollToBottom();

    final result =
        await ApiService.post('/coach/chat/${widget.conversation.id}', {
      'body': caption,
      'mediaUrl': url,
      'mediaType': type,
    });
    if (!mounted) return false;
    setState(() {
      _sending = false;
      _isUploadingMedia = false;
    });
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

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _selecting
            ? _selectionBar() as PreferredSizeWidget
            : ConversationHeader(
                loading: _fetching && !_loading,
                activity: _activity,
                name: widget.conversation.clientName,
                subtitle: 'Client · Private conversation',
                avatar: widget.conversation.clientPhotoUrl,
                onAvatar: () {
                  final avatar = widget.conversation.clientPhotoUrl;
                  if (avatar.isNotEmpty) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ImagePreview(
                                imageUrl: avatar, tag: 'header_avatar')));
                  }
                },
                actions: [_buildMoreMenu()]),
        body: ConversationBody(
            notice: _showStorageNotice,
            loading: _loading,
            error: _error,
            uploading: _isUploadingMedia,
            sending: _sending,
            batch: _batchSending,
            recording: _isRecording,
            busy: _recordBusy,
            loadingMore: _loadingMore,
            selecting: _selecting,
            selected: _selected,
            onSelect: _toggleSelected,
            batchCurrent: _batchCurrent,
            batchTotal: _batchTotal,
            unread: _unreadNew,
            scroll: _scrollCtrl,
            text: _msgCtrl,
            messages: _messages
                .map((m) => ChatEntry(
                    id: m.id,
                    time: m.timestamp,
                    mine: m.isFromCoach,
                    read: m.isRead,
                    deleted: m.deleted,
                    expired: m.mediaExpired,
                    body: m.text,
                    url: m.mediaUrl,
                    type: m.mediaType))
                .toList(),
            closeNotice: () => setState(() => _showStorageNotice = false),
            retry: () => _loadMessages(silent: true),
            retryOlder: _olderFailed ? _loadOlder : null,
            bottom: _scrollToBottom,
            attach: _showAttachOptions,
            gallery: _pickAndSendMultipleImages,
            record: _toggleRecording,
            send: _sendMessage),
      );

  Widget _buildMoreMenu() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded,
          color: Theme.of(context).colorScheme.onSurface, size: 24),
      color: context.fitlek.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 40),
      onSelected: (val) {
        if (val == 'select') {
          setState(() => _selecting = true);
        } else if (val == 'refresh') {
          _loadMessages(silent: true);
        } else if (val == 'report') {
          _showReportDialog();
        } else if (val == 'block') {
          _showBlockDialog();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'select', child: Text('Select messages')),
        const PopupMenuItem(value: 'refresh', child: Text('Refresh messages')),
        PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.flag_rounded,
                  color: context.fitlek.textMuted, size: 18),
              const SizedBox(width: 8),
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
              const SizedBox(width: 8),
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
        builder: (ctx, setDialogState) => AppDialog(
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
              const SizedBox(height: 16),
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
    final clientID = int.tryParse(widget.conversation.clientId) ?? 0;
    if (clientID <= 0) {
      ApiService.showError(context, 'Unable to identify client to report');
      return;
    }
    try {
      final res = await ApiService.post('/ugc/report', {
        'reportedID': clientID,
        'reason': reason,
        'type': 'user',
        'entityID': int.tryParse(widget.conversation.id),
      });
      if (!mounted) return;
      if (res['ok'] == true) {
        ApiService.showSuccess(context, 'Report submitted successfully.');
      } else {
        ApiService.showError(context, 'Failed to submit report');
      }
    } catch (_) {
      if (!mounted) return;
      ApiService.showError(context, 'Network error');
    }
  }

  void _showBlockDialog() {
    final name = widget.conversation.clientName.isNotEmpty
        ? widget.conversation.clientName
        : 'this client';
    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
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
    final clientID = int.tryParse(widget.conversation.clientId) ?? 0;
    if (clientID <= 0) {
      ApiService.showError(context, 'Unable to identify client to block');
      return;
    }
    try {
      final res = await ApiService.post('/ugc/block', {
        'blockedID': clientID,
      });
      if (!mounted) return;
      if (res['ok'] == true) {
        ApiService.showSuccess(context, 'User blocked.');
        if (mounted) Navigator.pop(context, true);
      } else {
        ApiService.showError(context, 'Failed to block user');
      }
    } catch (_) {
      if (!mounted) return;
      ApiService.showError(context, 'Network error');
    }
  }
}
