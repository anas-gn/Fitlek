import '../../components/ENG/chatImageBatchPreview.dart';
import '../../components/ENG/chatSelection.dart';
import '../../services/chat_media_store.dart';
import '../../components/ENG/localChatMedia.dart';
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
  State<ClientConversationScreen> createState() =>
      _ClientConversationScreenState();
}

class _ClientConversationScreenState extends State<ClientConversationScreen>
    with LiveUpdates<ClientConversationScreen> {
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
  Timer? _refreshTimer;
  StreamSubscription<Map<String, dynamic>>? _socketMessages;

  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isUploadingMedia = false;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      };

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _initSocket();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _socketMessages?.cancel();
    SocketService().leaveRoom(widget.conversationID.toString());
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _refreshTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 100 &&
        !_loadingMore &&
        _hasMore) {
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
        setState(() {
          _messages.add(_Message.fromJson(data));
        });
        _scrollToBottom();
        _fetchMessages(silent: true);
      }
    });
  }

  Future<void> _fetchMessages({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final url = _getMessagesUrl(1);
      final res = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        final msgs = data
            .map((e) => _Message.fromJson(e as Map<String, dynamic>))
            .toList();

        if (mounted) {
          setState(() {
            if (silent) {
              final merged = <int, _Message>{
                for (final m in _messages) m.id: m
              };
              for (final m in msgs) {
                merged[m.id] = m;
              }
              _messages = merged.values.toList()
                ..sort((a, b) => a.id.compareTo(b.id));
            } else {
              _messages = msgs;
              _page = 1;
            }
            _loading = false;
            _error = null;
          });
          _scrollToBottom();
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Error (${res.statusCode})';
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Server unreachable';
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
      final res = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        final newMsgs = data
            .map((e) => _Message.fromJson(e as Map<String, dynamic>))
            .toList();

        if (mounted) {
          setState(() {
            if (newMsgs.isEmpty) {
              _hasMore = false;
            } else {
              final existing = _messages.map((m) => m.id).toSet();
              _messages.insertAll(
                  0, newMsgs.where((m) => !existing.contains(m.id)));
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
    if (_batchSending) return;
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
              'mediaType': 'text',
            }),
          )
          .timeout(Duration(seconds: 10));

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
    if (caption == null) return; // User cancelled

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
      _showSnack(result['message']?.toString() ?? 'Image upload failed',
          isError: true);
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
          _showSnack('Audio upload failed', isError: true);
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
        _showSnack(
            'Allow microphone access for Sirvya in your phone Settings to record voice messages.',
            isError: true);
      }
    }
  }

  Future<bool> _sendMediaMessage(String url, String type,
      {String? caption}) async {
    setState(() => _sending = true);
    try {
      final reqUrl = _getSendUrl();
      final res = await http
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
          .timeout(Duration(seconds: 10));

      if (res.statusCode == 201) {
        await _fetchMessages(silent: true);
        return true;
      } else {
        _showSnack('Failed to send media message', isError: true);
      }
    } catch (_) {
      _showSnack('Network error', isError: true);
    } finally {
      if (mounted)
        setState(() {
          _sending = false;
          _isUploadingMedia = false;
        });
    }
    return false;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  bool _isMe(_Message msg) => msg.senderID == widget.clientID;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
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
    if (_selecting) return _selectionBar() as PreferredSizeWidget;
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      toolbarHeight: 64,
      leadingWidth: 44,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Padding(
          padding: EdgeInsets.only(left: 12),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: Theme.of(context).colorScheme.onSurface, size: 24),
        ),
      ),
      title: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (widget.coachAvatar != null &&
                  widget.coachAvatar!.isNotEmpty) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ImagePreview(
                          imageUrl: widget.coachAvatar!, tag: 'header_avatar'),
                    ));
              }
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: context.fitlek.border, width: 2),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: context.fitlek.border,
                backgroundImage:
                    widget.coachAvatar != null && widget.coachAvatar!.isNotEmpty
                        ? NetworkImage(widget.coachAvatar!)
                        : null,
                child: (widget.coachAvatar == null ||
                        widget.coachAvatar!.isEmpty)
                    ? Text(
                        widget.coachName != null && widget.coachName!.isNotEmpty
                            ? widget.coachName![0].toUpperCase()
                            : '?',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w900),
                      )
                    : null,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.coachName ?? 'Conversation',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.coachSpeciality != null)
                  Text(
                    widget.coachSpeciality!,
                    style: TextStyle(
                        color: context.fitlek.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
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
            tooltip: 'Select messages',
            onPressed: () => setState(() => _selecting = true),
            icon: const Icon(Icons.checklist)),
        _buildMoreMenu(),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Container(height: 1, color: context.fitlek.card),
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_loading) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary, strokeWidth: 2),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 60),
              Icon(Icons.error_outline_rounded,
                  color: context.fitlek.textMuted, size: 40),
              SizedBox(height: 12),
              Text(_error!,
                  style:
                      TextStyle(color: context.fitlek.textMuted, fontSize: 13)),
              SizedBox(height: 16),
              GestureDetector(
                onTap: _fetchMessages,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
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
                        fontSize: 11,
                        letterSpacing: 1),
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
              decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.08),
                  shape: BoxShape.circle),
              child: Icon(Icons.chat_bubble_outline_rounded,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.4),
                  size: 28),
            ),
            SizedBox(height: 16),
            Text(
              'Start the conversation',
              style: TextStyle(
                  color: context.fitlek.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              'Send your first message',
              style: TextStyle(color: context.fitlek.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final timeline = _buildTimeline();

    return ListView.builder(
      controller: _scrollCtrl,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: timeline.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (_loadingMore && i == 0) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 2),
              ),
            ),
          );
        }

        final item = timeline[i - (_loadingMore ? 1 : 0)];

        if (item is DateTime) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: context.fitlek.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatDivider(item),
                  style: TextStyle(
                      color: context.fitlek.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
          );
        }

        final msg = item as _Message;
        final isMe = _isMe(msg);
        final idx = _messages.indexOf(msg);
        final next = idx + 1 < _messages.length ? _messages[idx + 1] : null;
        final isLastOfGroup = next == null ||
            next.senderID != msg.senderID ||
            !_isSameDay(next.createdAt, msg.createdAt);
        final showAvatar = !isMe && isLastOfGroup;

        return SelectableChatMessage(
            selecting: _selecting,
            selected: _selected.contains(msg.id),
            onToggle: () => _toggleSelected(msg.id),
            child: Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment:
                    isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  if (!isMe)
                    SizedBox(
                      width: 32,
                      child: showAvatar
                          ? Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.3),
                                    width: 1.5),
                              ),
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: context.fitlek.card2,
                                backgroundImage: msg.senderAvatar != null &&
                                        msg.senderAvatar!.isNotEmpty
                                    ? NetworkImage(msg.senderAvatar!)
                                    : null,
                                child: (msg.senderAvatar == null ||
                                        msg.senderAvatar!.isEmpty)
                                    ? Text(
                                        msg.senderName != null &&
                                                msg.senderName!.isNotEmpty
                                            ? msg.senderName![0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900),
                                      )
                                    : null,
                              ),
                            )
                          : null,
                    ),
                  if (!isMe) SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.68),
                      padding: EdgeInsets.all(
                          msg.mediaType == 'image' && !msg.mediaExpired
                              ? 4
                              : 10),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Theme.of(context).colorScheme.primary
                            : context.fitlek.border,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildBubbleContent(msg, isMe),
                          SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                _formatTime(msg.createdAt),
                                style: TextStyle(
                                  color: isMe
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                          .withValues(alpha: 0.6)
                                      : context.fitlek.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (isMe) ...[
                                SizedBox(width: 4),
                                Icon(
                                  msg.isRead
                                      ? Icons.done_all_rounded
                                      : Icons.done_rounded,
                                  color: msg.isRead
                                      ? Color(0xFF00A884)
                                      : Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                          .withValues(
                                              alpha:
                                                  0.6), // WhatsApp blue tick equivalent
                                  size: 14,
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
            ));
      },
    );
  }

  Widget _buildBubbleContent(_Message message, bool isMe) {
    final fgColor = isMe
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;

    if (message.deleted)
      return Text(
          isMe
              ? 'You deleted this message'
              : 'This message was deleted by the sender',
          style: TextStyle(color: fgColor, fontStyle: FontStyle.italic));
    if (message.mediaType == 'image' || message.mediaType == 'audio') {
      return LocalChatMedia(
          key: ValueKey('media_${message.id}'),
          messageID: message.id,
          url: message.mediaUrl,
          type: message.mediaType,
          expired: message.mediaExpired,
          isMe: isMe,
          caption: message.body);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5),
      child: Text(message.body ?? '',
          style: TextStyle(color: fgColor, fontSize: 13.5, height: 1.4)),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
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
                border: Border.all(color: context.fitlek.border, width: 1.5),
              ),
              child: TextField(
                controller: _msgCtrl,
                focusNode: _focusNode,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _sendMessage(),
                readOnly: _isRecording || _isUploadingMedia,
                decoration: InputDecoration(
                  hintText:
                      _isRecording ? 'Recording...' : 'Ã‰crire un message...',
                  hintStyle:
                      TextStyle(color: context.fitlek.textMuted, fontSize: 15),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          if (_isUploadingMedia)
            SizedBox(
                width: 44,
                height: 44,
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
              onTap: _sending ? null : _sendMessage,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _sending
                      ? context.fitlek.border.withValues(alpha: 0.5)
                      : context.fitlek.border,
                  shape: BoxShape.circle,
                ),
                child: _sending
                    ? Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.onSurface,
                              strokeWidth: 2),
                        ),
                      )
                    : Icon(Icons.send_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 20),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime d) {
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
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
              SizedBox(width: 8),
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
      margin: EdgeInsets.all(16),
    ));
  }

  Future<void> _submitReport(String reason) async {
    // We need the coach ID to report them.
    // In this screen, we only have the conversation ID, we'd ideally pass the coachID but we don't have it easily.
    // So we'll use a specific /report-conversation endpoint or fetch the coach ID.
    // Since we only have `conversationID`, I'll use a new body structure.
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/ugc/report'),
        headers: _headers,
        body: jsonEncode({
          'reportedID': widget
              .conversationID, // This might need server-side resolution if type='conversation'
          'reason': reason,
          'type': 'conversation',
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
      final res = await http.post(
        Uri.parse('$baseUrl/ugc/block-conversation'),
        headers: _headers,
        body: jsonEncode({'conversationID': widget.conversationID}),
      );
      if (res.statusCode == 200) {
        _showSnack('User blocked.');
        if (mounted) Navigator.pop(context);
      } else {
        _showSnack('Failed to block user', isError: true);
      }
    } catch (_) {
      _showSnack('Network error', isError: true);
    }
  }
}
