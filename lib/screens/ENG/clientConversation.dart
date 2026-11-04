import '../../services/conversation_activity.dart';
import '../../components/ENG/conversationUi.dart';
import '../../components/app_dialog.dart';
import '../../components/ENG/chatImageBatchPreview.dart';
import '../../components/ENG/chatSelection.dart';
import '../../services/chat_media_store.dart';
import '../../services/media_picker_service.dart';
import '../../services/live_updates.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fitlek1/constants/urls.dart';
import '../../theme/fitlek_theme_extension.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/apiService.dart';
import '../../components/ENG/imagePreview.dart';
import '../../services/socketService.dart';
import 'package:flutter/foundation.dart'; // Add kIsWeb

class _Message {
  final int id;
  final int conversationID;
  final int senderID;
  final String? body;
  final String? mediaUrl;
  final String mediaType;
  final bool mediaExpired;
  final bool deleted;
  final bool isRead;
  final DateTime createdAt;
  final String? senderName;
  final String? senderAvatar;

  const _Message({
    required this.id,
    required this.conversationID,
    required this.senderID,
    this.body,
    this.mediaUrl,
    this.mediaType = 'text',
    this.mediaExpired = false,
    this.deleted = false,
    required this.isRead,
    required this.createdAt,
    this.senderName,
    this.senderAvatar,
  });

  _Message asDeleted() => _Message(
      id: id,
      conversationID: conversationID,
      senderID: senderID,
      body: 'This message was deleted',
      mediaType: 'text',
      deleted: true,
      isRead: isRead,
      createdAt: createdAt,
      senderName: senderName,
      senderAvatar: senderAvatar);

  factory _Message.fromJson(Map<String, dynamic> j) => _Message(
        deleted: j['deletedAt'] != null,
        id: j['id'],
        conversationID: j['conversationID'],
        senderID: j['senderID'],
        body: j['body'],
        mediaUrl: j['mediaUrl'],
        mediaType: j['mediaType'] ?? 'text',
        mediaExpired: j['mediaExpired'] == 1 || j['mediaExpired'] == true,
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
  final int? coachID;
  final String? coachName;
  final String? coachAvatar;
  final String? coachSpeciality;
  final http.Client? httpClient;
  final bool connectRealtime;

  const ClientConversationScreen({
    super.key,
    required this.conversationID,
    required this.clientID,
    required this.token,
    this.coachID,
    this.coachName,
    this.coachAvatar,
    this.coachSpeciality,
    this.httpClient,
    this.connectRealtime = true,
  });

  @override
  State<ClientConversationScreen> createState() =>
      _ClientConversationScreenState();
}

class _ClientConversationScreenState extends State<ClientConversationScreen>
    with LiveUpdates<ClientConversationScreen> {
  @override
  bool get enableLiveUpdates => widget.connectRealtime;
  late final http.Client _http = widget.httpClient ?? http.Client();
  int? _resolvedCoachID;

  Future<int?> _getCoachID() async {
    if (_resolvedCoachID != null && _resolvedCoachID! > 0) {
      return _resolvedCoachID;
    }
    for (final m in _messages) {
      if (m.senderID != widget.clientID && m.senderID > 0) {
        _resolvedCoachID = m.senderID;
        return _resolvedCoachID;
      }
    }
    try {
      final res = await _http.get(
        Uri.parse('$baseUrl/conversations'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        for (final item in list) {
          if (item['id'] == widget.conversationID) {
            final cid = item['coachID'];
            if (cid != null) {
              _resolvedCoachID = int.tryParse('$cid');
              return _resolvedCoachID;
            }
          }
        }
      }
    } catch (_) {}
    return _resolvedCoachID;
  }
  @override
  Set<String> get liveDomains => {'read_receipts', 'chat-actions', 'all'};
  @override
  Future<void> refreshLiveData() async {
    final hidden =
        await ApiService.get('/chat-actions/${widget.conversationID}/hidden');
    if (!mounted) return;
    if (hidden['ok'] == true && hidden['data'] is List) {
      final rows = hidden['data'] as List;
      final ids = rows
          .where((m) => m['hidden'] == 1 || m['hidden'] == true)
          .map((m) => int.tryParse('${m['id']}'))
          .toSet();
      final deleted = rows
          .where((m) => m['deletedAt'] != null)
          .map((m) => int.tryParse('${m['id']}'))
          .toSet();
      setState(() {
        _messages.removeWhere((m) => ids.contains(m.id));
        _messages = _messages
            .map((m) => deleted.contains(m.id) ? m.asDeleted() : m)
            .toList();
      });
    }
    await _fetchMessages(silent: true);
  }

  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

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
            _selected.addAll(
                _messages.map((m) => m.id).where((id) => id > 0).take(100));
          }),
      onDelete: _deleteSelected);
  Future<void> _deleteSelected() async {
    if (_deleting || _selected.isEmpty) return;
    final selected = _messages.where((m) => _selected.contains(m.id)).toList();
    final now = DateTime.now();
    final everyone = selected.isNotEmpty &&
        selected.every((m) =>
            _isMe(m) &&
            !m.deleted &&
            now.difference(m.createdAt).inSeconds < 1800);
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
          '/chat-actions/${widget.conversationID}/delete',
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
        _messages.removeWhere((m) => ids.contains(m.id));
        _selected.clear();
        _selecting = false;
      });
      await _fetchMessages();
    } finally {
      _deleting = false;
    }
  }

  List<_Message> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  StreamSubscription<Map<String, dynamic>>? _socketMessages;

  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

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
  bool _isUploadingMedia = false;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      };

  @override
  void initState() {
    super.initState();
    _resolvedCoachID = widget.coachID;
    _activity = ConversationActivity(
        conversationID: widget.conversationID.toString(),
        userID: widget.clientID,
        enabled: widget.connectRealtime);
    _msgCtrl.addListener(_draftChanged);
    _fetchMessages();
    if (widget.connectRealtime) _initSocket();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _msgCtrl.removeListener(_draftChanged);
    _activity.dispose();
    _socketMessages?.cancel();
    if (widget.connectRealtime) {
      SocketService().leaveRoom(widget.conversationID.toString());
    }
    if (widget.httpClient == null) _http.close();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();

    _audioRecorder.dispose();
    super.dispose();
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
      _loadMore();
    }
  }

  String _getMessagesUrl(int pageNum) {
    return '$baseUrl/messages/${widget.conversationID}?page=$pageNum&limit=50&readerID=${widget.clientID}';
  }

  String _getSendUrl() {
    return '$baseUrl/messages/${widget.conversationID}';
  }

  void _initSocket() {
    final socketService = SocketService();
    socketService.connect();
    socketService.joinRoom(widget.conversationID.toString());
    _socketMessages?.cancel();
    _socketMessages = socketService.messages.listen((data) {
      if (!mounted) return;
      // If message is from someone else, we add it to the list
      if (data['conversationID'].toString() ==
              widget.conversationID.toString() &&
          data['senderID'].toString() != widget.clientID.toString() &&
          !_messages.any((m) => m.id.toString() == data['id'].toString())) {
        _activity.messageReceived(int.tryParse('${data['senderID']}') ?? -1);
        final follow = _nearLatest;
        setState(() {
          if (!follow) _unreadNew++;
          _messages.add(_Message.fromJson(data));
        });
        if (follow) _scrollToBottom();
        _fetchMessages(silent: true);
      }
    });
  }

  Future<void> _fetchMessages({bool silent = false}) async {
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
      final res = await _http
          .get(Uri.parse(_getMessagesUrl(1)), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw Exception('Could not load messages');
      final rows = (jsonDecode(res.body) as List)
          .map((m) => _Message.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      if (!mounted) return;
      final last = _messages.isEmpty ? 0 : _messages.last.id;
      setState(() {
        final merged = {for (final m in _messages) m.id: m};
        for (final m in rows) {
          merged[m.id] = m;
        }
        _messages = merged.values.toList()
          ..sort((a, b) => a.id.compareTo(b.id));
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
        unawaited(_fetchMessages(silent: true));
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() {
      _loadingMore = true;
      _olderFailed = false;
    });
    try {
      final res = await _http
          .get(Uri.parse(_getMessagesUrl(_page + 1)), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw Exception('Could not load messages');
      final rows = (jsonDecode(res.body) as List)
          .map((m) => _Message.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      if (!mounted) return;
      setState(() {
        final merged = {for (final m in _messages) m.id: m};
        for (final m in rows) {
          merged.putIfAbsent(m.id, () => m);
        }
        _messages = merged.values.toList()
          ..sort((a, b) => a.id.compareTo(b.id));
        _page++;
        _hasMore = rows.length >= 50;
      });
    } catch (_) {
      if (mounted) setState(() => _olderFailed = true);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_batchSending || _sending || _isUploadingMedia) return;
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    _msgCtrl.clear();

    try {
      final url = _getSendUrl();
      final res = await _http
          .post(
            Uri.parse(url),
            headers: _headers,
            body: jsonEncode({
              'senderID': widget.clientID,
              'body': text,
              'mediaType': 'text',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 201) {
        await _fetchMessages(silent: true);
        if (mounted) _scrollToBottom();
      } else {
        if (mounted) {
          _msgCtrl.text = text;
          _showSnack('Could not send. Your message is ready to retry.',
              isError: true);
        }
      }
    } catch (_) {
      if (mounted) {
        _msgCtrl.text = text;
        _showSnack('Could not send. Your message is ready to retry.',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
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
    if (!mounted || caption == null) return; // User cancelled

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
        _showSnack(result['message']?.toString() ?? 'Image upload failed',
            isError: true);
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
            final res = await _http.get(Uri.parse(path));
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
            _showSnack('Audio upload failed', isError: true);
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
          _showSnack(
              'Allow microphone access for Sirvya in your phone Settings to record voice messages.',
              isError: true);
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
    setState(() => _sending = true);
    try {
      final reqUrl = _getSendUrl();
      final res = await _http
          .post(
            Uri.parse(reqUrl),
            headers: _headers,
            body: jsonEncode({
              'senderID': widget.clientID,
              'mediaUrl': url,
              'mediaType': type,
              if (caption != null && caption.isNotEmpty) 'body': caption,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 201) {
        await _fetchMessages(silent: true);
        return true;
      } else {
        _showSnack('Failed to send media message', isError: true);
      }
    } catch (_) {
      _showSnack('Network error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _isUploadingMedia = false;
        });
      }
    }
    return false;
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

  bool _isMe(_Message m) => m.senderID == widget.clientID;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _selecting
            ? _selectionBar() as PreferredSizeWidget
            : ConversationHeader(
                loading: _fetching && !_loading,
                activity: _activity,
                name: widget.coachName ?? 'Conversation',
                subtitle: widget.coachSpeciality ?? 'Fitness coach',
                avatar: widget.coachAvatar,
                onAvatar: () {
                  final avatar = widget.coachAvatar;
                  if (avatar?.isNotEmpty == true) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ImagePreview(
                                imageUrl: avatar!, tag: 'header_avatar')));
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
            focus: _focusNode,
            messages: _messages
                .map((m) => ChatEntry(
                    id: '${m.id}',
                    time: m.createdAt,
                    mine: _isMe(m),
                    read: m.isRead,
                    deleted: m.deleted,
                    expired: m.mediaExpired,
                    body: m.body,
                    url: m.mediaUrl,
                    type: m.mediaType))
                .toList(),
            closeNotice: () => setState(() => _showStorageNotice = false),
            retry: () => _fetchMessages(silent: true),
            retryOlder: _olderFailed ? _loadMore : null,
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
          _fetchMessages(silent: true);
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
              Text('Report Coach',
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
              Text('Block Coach',
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
    final name = widget.coachName ?? 'this coach';

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

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: TextStyle(
              color: isError
                  ? Theme.of(context).colorScheme.onError
                  : Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w700)),
      backgroundColor:
          isError ? Colors.redAccent : Theme.of(context).colorScheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _submitReport(String reason) async {
    final coachID = await _getCoachID();
    if (coachID == null || coachID <= 0) {
      _showSnack('Unable to identify coach to report', isError: true);
      return;
    }
    try {
      final res = await _http.post(
        Uri.parse('$baseUrl/ugc/report'),
        headers: _headers,
        body: jsonEncode({
          'reportedID': coachID,
          'reason': reason,
          'type': 'user',
          'entityID': widget.conversationID,
        }),
      );
      if (res.statusCode == 200) {
        _showSnack('Report submitted successfully.');
      } else {
        _showSnack('Failed to submit report', isError: true);
      }
    } catch (_) {
      _showSnack('Network error', isError: true);
    }
  }

  void _showBlockDialog() {
    final name = widget.coachName ?? 'this coach';
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
    final coachID = await _getCoachID();
    if (coachID == null || coachID <= 0) {
      _showSnack('Unable to identify coach to block', isError: true);
      return;
    }
    try {
      final res = await _http.post(
        Uri.parse('$baseUrl/ugc/block'),
        headers: _headers,
        body: jsonEncode({'blockedID': coachID}),
      );
      if (res.statusCode == 200) {
        _showSnack('User blocked.');
        if (mounted) Navigator.pop(context, true);
      } else {
        _showSnack('Failed to block user', isError: true);
      }
    } catch (_) {
      _showSnack('Network error', isError: true);
    }
  }
}
