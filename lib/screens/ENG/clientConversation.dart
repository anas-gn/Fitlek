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
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/apiService.dart';
import '../../components/ENG/audioPlayerWidget.dart';
import 'package:flutter/foundation.dart'; // Add kIsWeb
import 'package:http/http.dart' as http; // Add http


class _Message {
  final int id;
  final int conversationID;
  final int senderID;
  final String? body;
  final String? mediaUrl;
  final String mediaType;
  final bool mediaExpired;
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
    required this.isRead,
    required this.createdAt,
    this.senderName,
    this.senderAvatar,
  });

  factory _Message.fromJson(Map<String, dynamic> j) => _Message(
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
    _audioRecorder.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 100 && !_loadingMore && _hasMore) {
      _loadMore();
    }
  }

  String _getMessagesUrl(int pageNum) {
    return '$baseUrl/messages/${widget.conversationID}?page=$pageNum&limit=50&readerID=${widget.clientID}';
  }

  String _getSendUrl() {
    return '$baseUrl/messages/${widget.conversationID}';
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
              'mediaType': 'text',
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
      _showSnack('Image upload failed', isError: true);
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
          _showSnack('Audio upload failed', isError: true);
        }
      }
    } else {
      if (await _audioRecorder.hasPermission()) {
        if (kIsWeb) {
          await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc));
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
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 201) {
        await _fetchMessages(silent: true);
      } else {
        _showSnack('Failed to send media message', isError: true);
      }
    } catch (_) {
      _showSnack('Network error', isError: true);
    } finally {
      if (mounted) setState(() { _sending = false; _isUploadingMedia = false; });
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

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
      backgroundColor: context.fitlek.card,
      elevation: 0,
      toolbarHeight: 56,
      leadingWidth: 44,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Icon(Icons.arrow_back_ios_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
        ),
      ),
      title: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: context.fitlek.card2,
              backgroundImage: widget.coachAvatar != null && widget.coachAvatar!.isNotEmpty
                  ? NetworkImage(widget.coachAvatar!)
                  : null,
              child: (widget.coachAvatar == null || widget.coachAvatar!.isEmpty)
                  ? Text(
                      widget.coachName != null && widget.coachName!.isNotEmpty ? widget.coachName![0].toUpperCase() : '?',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 14, fontWeight: FontWeight.w900),
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
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.coachSpeciality != null)
                  Text(
                    widget.coachSpeciality!,
                    style: TextStyle(color: context.fitlek.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _buildMoreMenu(),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: context.fitlek.border),
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_loading) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary, strokeWidth: 2),
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
              Icon(Icons.error_outline_rounded, color: context.fitlek.textMuted, size: 40),
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: context.fitlek.textMuted, fontSize: 13)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _fetchMessages,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'RETRY',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1),
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
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(Icons.chat_bubble_outline_rounded, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4), size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'Start the conversation',
              style: TextStyle(color: context.fitlek.textMuted, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: timeline.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (_loadingMore && i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary, strokeWidth: 2),
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
                  color: context.fitlek.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.fitlek.border, width: 1),
                ),
                child: Text(
                  _formatDivider(item),
                  style: TextStyle(color: context.fitlek.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.5),
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
                            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), width: 1.5),
                          ),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: context.fitlek.card2,
                            backgroundImage: msg.senderAvatar != null && msg.senderAvatar!.isNotEmpty
                                ? NetworkImage(msg.senderAvatar!)
                                : null,
                            child: (msg.senderAvatar == null || msg.senderAvatar!.isEmpty)
                                ? Text(
                                    msg.senderName != null && msg.senderName!.isNotEmpty ? msg.senderName![0].toUpperCase() : '?',
                                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 10, fontWeight: FontWeight.w900),
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
                  padding: EdgeInsets.all(msg.mediaType == 'image' && !msg.mediaExpired ? 4 : 10),
                  decoration: BoxDecoration(
                    color: isMe ? Theme.of(context).colorScheme.primary : context.fitlek.card,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: isMe ? null : Border.all(color: context.fitlek.border, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildBubbleContent(msg, isMe),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(msg.createdAt),
                            style: TextStyle(
                              color: isMe ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.6) : context.fitlek.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              msg.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                              color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.6),
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

  Widget _buildBubbleContent(_Message message, bool isMe) {
    final cs = Theme.of(context).colorScheme;
    final fgColor = isMe ? cs.onPrimary : cs.onSurface;

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
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
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
      );
    } else if (message.mediaType == 'audio') {
      return AudioPlayerWidget(
        url: message.mediaUrl,
        isMe: isMe,
        isExpired: message.mediaExpired,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Text(message.body ?? '', style: TextStyle(color: fgColor, fontSize: 13.5, height: 1.4)),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: context.fitlek.card,
        border: Border(top: BorderSide(color: context.fitlek.border, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: _pickAndSendImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.add_photo_alternate_rounded, color: context.fitlek.textMuted, size: 24),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.fitlek.inputFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.fitlek.border, width: 1),
              ),
              child: TextField(
                controller: _msgCtrl,
                focusNode: _focusNode,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _sendMessage(),
                readOnly: _isRecording || _isUploadingMedia,
                decoration: InputDecoration(
                  hintText: _isRecording ? 'Recording...' : 'Write a message...',
                  hintStyle: TextStyle(color: context.fitlek.textMuted, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (_isUploadingMedia)
            SizedBox(width: 44, height: 44, child: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary, strokeWidth: 2)))
          else if (_msgCtrl.text.isEmpty && !_isRecording)
            GestureDetector(onTap: _toggleRecording,
              child: Container(width: 44, height: 44,
                decoration: BoxDecoration(color: context.fitlek.card, shape: BoxShape.circle, border: Border.all(color: context.fitlek.border)),
                child: Icon(Icons.mic_none_rounded, color: Theme.of(context).colorScheme.primary, size: 22)))
          else if (_isRecording)
            GestureDetector(onTap: _toggleRecording,
              child: Container(width: 44, height: 44,
                decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]),
                child: const Icon(Icons.stop_rounded, color: Colors.white, size: 20)))
          else
            GestureDetector(
              onTap: _sending ? null : _sendMessage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _sending ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.25) : Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _sending
                    ? Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary, strokeWidth: 2),
                        ),
                      )
                    : Icon(Icons.send_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 20),
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
              Text('Report Coach', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'block',
          child: Row(
            children: [
              Icon(Icons.block_rounded, color: context.fitlek.error, size: 18),
              const SizedBox(width: 8),
              Text('Block Coach', style: TextStyle(color: context.fitlek.error, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  void _showReportDialog() {
    String? selectedReason;
    final reasons = ['Spam', 'Harassment', 'Inappropriate content', 'Fraud / Scam', 'Other'];
    final name = widget.coachName ?? 'this coach';

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

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: TextStyle(color: isError ? Theme.of(context).colorScheme.onError : Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w700)),
      backgroundColor: isError ? Colors.redAccent : Theme.of(context).colorScheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
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
          'reportedID': widget.conversationID, // This might need server-side resolution if type='conversation'
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