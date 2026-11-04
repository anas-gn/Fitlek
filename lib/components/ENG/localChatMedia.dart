import '../app_dialog.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/chat_media_store.dart';
import '../../services/apiService.dart';
import 'audioPlayerWidget.dart';
import 'imagePreview.dart';

class LocalChatMedia extends StatefulWidget {
  final int messageID;
  final String? url, caption;
  final String type;
  final bool expired, isMe;
  final ChatMediaStore? store;
  const LocalChatMedia(
      {super.key,
      required this.messageID,
      required this.url,
      required this.type,
      required this.expired,
      required this.isMe,
      this.store,
      this.caption});
  @override
  State<LocalChatMedia> createState() => _LocalChatMediaState();
}

class _LocalChatMediaState extends State<LocalChatMedia> {
  Color get _ink => widget.isMe
      ? const Color(0xFF123E37)
      : Theme.of(context).colorScheme.onSurface;
  Future<SavedChatMedia>? _loading;
  StreamSubscription<int>? _changes;
  ChatMediaStore get _store => widget.store ?? ChatMediaStore.instance;
  @override
  void initState() {
    super.initState();
    _changes = _store.mediaChanges.stream.listen((id) {
      if (id == widget.messageID) _refresh();
    });
  }

  @override
  void didUpdateWidget(LocalChatMedia old) {
    super.didUpdateWidget(old);
    if (old.messageID != widget.messageID ||
        old.url != widget.url ||
        old.expired != widget.expired) {
      _loading = null;
    }
  }

  @override
  void dispose() {
    _changes?.cancel();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() => _loading = null);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AppDialog(
                title: const Text('Delete from this phone?'),
                content: const Text(
                    'The message stays in your history. Once the server copy is removed, this file cannot be downloaded again.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete file'))
                ]));
    if (confirmed == true) await _store.deleteLocal(widget.messageID);
  }

  Widget _missing(String? thumbnail) {
    return GestureDetector(
      onTap: () => ApiService.showError(context,
          "This file was stored on the original device. Deleting the app removes local photos and voice notes. Ask the sender to resend it."),
      child: Container(
          width: 190,
          height: widget.type == 'image' ? 140 : 64,
          decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: .08),
              borderRadius: BorderRadius.circular(14)),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(fit: StackFit.expand, children: [
                if (thumbnail != null)
                  ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Image.file(File(thumbnail),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox())),
                Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                      widget.type == 'image'
                          ? Icons.image_not_supported_outlined
                          : Icons.volume_off_outlined,
                      size: 24,
                      color: _ink),
                  const SizedBox(height: 6),
                  Text("Not on this device",
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _ink)),
                ])),
              ]))),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Temporary optimistic bubbles wait for the server's real message ID.
    if (widget.messageID <= 0) return _frame(_waiting('Sending…'));
    _loading ??= _store.resolve(
        widget.messageID, widget.url, widget.type, widget.expired);
    return FutureBuilder<SavedChatMedia>(
        future: _loading,
        builder: (context, snapshot) {
          Widget media;
          final saved = snapshot.data;
          if (snapshot.hasError) {
            media = Center(
                child: TextButton.icon(
                    onPressed: _refresh,
                    style: TextButton.styleFrom(foregroundColor: _ink),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Retry download')));
          } else if (saved == null) {
            media = _waiting('Downloading…');
          } else if (saved.filePath == null) {
            media = _missing(saved.thumbnailPath);
          } else {
            final file = saved.filePath!;
            media = GestureDetector(
              onLongPress: saved.remote ? null : _delete,
              child: widget.type == 'audio'
                  ? AudioPlayerWidget(
                      url: widget.url,
                      isMe: widget.isMe,
                      isExpired: widget.expired,
                      localPath: saved.remote ? null : file)
                  : GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ImagePreview(
                                  imageUrl: file,
                                  tag: 'chat_media_${widget.messageID}',
                                  localFile: !saved.remote))),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: saved.remote
                              ? Image.network(file,
                                  fit: BoxFit.cover,
                                  cacheWidth: 900,
                                  frameBuilder:
                                      (_, child, frame, synchronous) =>
                                          synchronous || frame != null
                                              ? child
                                              : _waiting('Loading photo…'),
                                  errorBuilder: (_, __, ___) =>
                                      _missing(saved.thumbnailPath))
                              : Image.file(File(file),
                                  fit: BoxFit.cover,
                                  cacheWidth: 900,
                                  frameBuilder:
                                      (_, child, frame, synchronous) =>
                                          synchronous || frame != null
                                              ? child
                                              : _waiting('Loading photo…'),
                                  errorBuilder: (_, __, ___) =>
                                      _missing(saved.thumbnailPath))),
                    ),
            );
          }
          return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _frame(media),
                if (widget.caption?.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Text(widget.caption!))
                ]
              ]);
        });
  }

  Widget _frame(Widget child) => widget.type == 'image'
      ? SizedBox(
          width: double.infinity,
          child: AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(17), child: child)))
      : SizedBox(width: 280, height: 53, child: child);

  Widget _waiting(String label) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
            width: 21,
            height: 21,
            child: CircularProgressIndicator(strokeWidth: 2, color: _ink)),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 10, color: _ink)),
      ]));
}
