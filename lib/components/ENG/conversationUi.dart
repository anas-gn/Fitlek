import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import '../../theme/fitlek_theme_extension.dart';
import '../../services/chat_media_store.dart';
import 'chatSelection.dart';
import 'localChatMedia.dart';

Color chatInk(BuildContext context, bool mine) =>
    mine ? const Color(0xFF123E37) : Theme.of(context).colorScheme.onSurface;

class ConversationBody extends StatelessWidget {
  final bool notice,
      loading,
      uploading,
      sending,
      batch,
      recording,
      busy,
      loadingMore,
      selecting;
  final int batchCurrent, batchTotal, unread;
  final String? error;
  final ScrollController scroll;
  final TextEditingController text;
  final FocusNode? focus;
  final List<ChatEntry> messages;
  final Set<int> selected;
  final ValueChanged<int> onSelect;
  final VoidCallback closeNotice, retry, bottom, attach, gallery, record, send;
  final VoidCallback? retryOlder;
  final ChatMediaStore? mediaStore;
  const ConversationBody(
      {super.key,
      required this.notice,
      required this.loading,
      required this.uploading,
      required this.sending,
      required this.batch,
      required this.recording,
      required this.busy,
      required this.loadingMore,
      required this.selecting,
      required this.batchCurrent,
      required this.batchTotal,
      required this.unread,
      required this.scroll,
      required this.text,
      this.focus,
      required this.messages,
      required this.selected,
      required this.onSelect,
      this.mediaStore,
      required this.closeNotice,
      required this.retry,
      required this.bottom,
      required this.attach,
      required this.gallery,
      required this.record,
      required this.send,
      this.error,
      this.retryOlder});
  @override
  Widget build(BuildContext context) => SafeArea(
      top: false,
      child: Column(children: [
        if (notice) ChatStorageNotice(onClose: closeNotice),
        if (uploading || batch || sending)
          ChatActivity(
              label: batch
                  ? 'Sending photo $batchCurrent of $batchTotal…'
                  : uploading
                      ? 'Sending your attachment…'
                      : 'Sending message…',
              progress: batch && batchTotal > 0
                  ? (batchCurrent - 1) / batchTotal
                  : null),
        if (error != null && messages.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Row(children: [
                const Expanded(
                    child: Text(
                        'Could not refresh. Your messages are still here.',
                        style: TextStyle(fontSize: 11))),
                TextButton(onPressed: retry, child: const Text('Retry'))
              ])),
        Expanded(
            child: loading
                ? const ChatLoading()
                : error != null && messages.isEmpty
                    ? Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.cloud_off_rounded, size: 36),
                        const SizedBox(height: 12),
                        Text(error!, textAlign: TextAlign.center),
                        TextButton.icon(
                            onPressed: retry,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'))
                      ]))
                    : Stack(children: [
                        ConversationTimeline(
                            controller: scroll,
                            messages: messages,
                            selecting: selecting,
                            selected: selected,
                            onSelect: onSelect,
                            loadingMore: loadingMore,
                            retryOlder: retryOlder,
                            mediaStore: mediaStore),
                        if (unread > 0)
                          Positioned(
                              bottom: 12,
                              right: 14,
                              child: FilledButton.icon(
                                  onPressed: bottom,
                                  icon: const Icon(Icons.arrow_downward_rounded,
                                      size: 17),
                                  label: Text('$unread new')))
                      ])),
        ConversationComposer(
            controller: text,
            focusNode: focus,
            recording: recording,
            busy: busy || uploading || sending || batch,
            onAttach: attach,
            onGallery: gallery,
            onRecord: record,
            onSend: send),
      ]));
}

Color chatBubbleColor(BuildContext context, bool mine) => mine
    ? const Color(0xFFF1EDE2)
    : Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1C403C)
        : const Color(0xFFE0EFEB);

class ChatEntry {
  final String id;
  final DateTime time;
  final bool mine, read, deleted, expired;
  final String? body, url;
  final String type;
  const ChatEntry(
      {required this.id,
      required this.time,
      required this.mine,
      this.read = false,
      this.deleted = false,
      this.expired = false,
      this.body,
      this.url,
      this.type = 'text'});
}

class ConversationHeader extends StatelessWidget
    implements PreferredSizeWidget {
  final String name, subtitle;
  final String? avatar;
  final VoidCallback? onAvatar;
  final List<Widget> actions;
  final bool loading;
  final ValueListenable<String?>? activity;
  const ConversationHeader(
      {super.key,
      required this.name,
      required this.subtitle,
      this.avatar,
      this.onAvatar,
      this.loading = false,
      this.activity,
      this.actions = const []});
  @override
  Size get preferredSize => const Size.fromHeight(78);
  @override
  Widget build(BuildContext context) => activity == null
      ? _bar(context, null)
      : ValueListenableBuilder<String?>(
          valueListenable: activity!,
          builder: (context, status, _) => _bar(context, status));
  Widget _bar(BuildContext context, String? status) => AppBar(
        toolbarHeight: 76,
        titleSpacing: 0,
        leadingWidth: 48,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 23)),
        title: Row(children: [
          InkWell(
              onTap: onAvatar,
              customBorder: const CircleBorder(),
              child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: context.fitlek.border, width: 1.5)),
                  child: ClipOval(
                      child: avatar?.isNotEmpty == true
                          ? Image.network(avatar!,
                              fit: BoxFit.cover,
                              cacheWidth: 144,
                              errorBuilder: (_, __, ___) => _initial(context))
                          : _initial(context)))),
          const SizedBox(width: 11),
          Expanded(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(status ?? subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        color: status != null
                            ? context.fitlek.success
                            : context.fitlek.textSecondary)),
              ])),
        ]),
        actions: actions,
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: SizedBox(
                height: 2,
                child: loading
                    ? const LinearProgressIndicator(minHeight: 2)
                    : null)),
      );
  Widget _initial(BuildContext context) => ColoredBox(
      color: context.fitlek.card,
      child: Center(
          child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w700))));
}

class ChatStorageNotice extends StatelessWidget {
  final VoidCallback onClose;
  const ChatStorageNotice({super.key, required this.onClose});
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.fromLTRB(12, 2, 12, 4),
      padding: const EdgeInsets.only(left: 13),
      decoration: BoxDecoration(
          color: context.fitlek.card, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(Icons.info_outline_rounded,
            size: 19, color: context.fitlek.textSecondary),
        const SizedBox(width: 10),
        Expanded(
            child: Text('Photos and voice notes stay on this device',
                style: TextStyle(
                    fontSize: 12, color: context.fitlek.textSecondary))),
        IconButton(
            tooltip: 'Dismiss storage notice',
            onPressed: onClose,
            icon: Icon(Icons.close_rounded,
                size: 18, color: context.fitlek.textMuted)),
      ]));
}

class ChatActivity extends StatelessWidget {
  final String label;
  final double? progress;
  const ChatActivity({super.key, required this.label, this.progress});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: context.fitlek.card,
      child: Column(children: [
        Row(children: [
          const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12)))
        ]),
        if (progress != null) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              borderRadius: BorderRadius.circular(4))
        ],
      ]));
}

class ChatLoading extends StatelessWidget {
  const ChatLoading({super.key});
  @override
  Widget build(BuildContext context) =>
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < 3; i++)
          Align(
              alignment:
                  i.isEven ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                  height: i == 1 ? 54 : 74,
                  width: i == 1 ? 180 : 230,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                      color: context.fitlek.card,
                      borderRadius: BorderRadius.circular(20)))),
        const SizedBox(height: 18),
        const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(height: 12),
        Text('Loading conversation…',
            style: TextStyle(color: context.fitlek.textMuted)),
      ]);
}

class ConversationTimeline extends StatefulWidget {
  // Chronological input, reversed viewport: older pages append beyond the
  // viewport instead of shifting the messages the user is reading.
  final List<ChatEntry> messages;
  final ScrollController controller;
  final bool selecting, loadingMore;
  final Set<int> selected;
  final ValueChanged<int> onSelect;
  final VoidCallback? retryOlder;
  final ChatMediaStore? mediaStore;
  const ConversationTimeline(
      {super.key,
      required this.messages,
      required this.controller,
      this.selecting = false,
      this.loadingMore = false,
      this.selected = const {},
      required this.onSelect,
      this.mediaStore,
      this.retryOlder});
  @override
  State<ConversationTimeline> createState() => _ConversationTimelineState();
}

class _ConversationTimelineState extends State<ConversationTimeline> {
  final _anchors = <String, GlobalKey>{};
  List<ChatEntry> get messages => widget.messages;
  ScrollController get controller => widget.controller;
  bool get selecting => widget.selecting;
  bool get loadingMore => widget.loadingMore;
  Set<int> get selected => widget.selected;
  ValueChanged<int> get onSelect => widget.onSelect;
  VoidCallback? get retryOlder => widget.retryOlder;
  @override
  void didUpdateWidget(ConversationTimeline old) {
    super.didUpdateWidget(old);
    if (!controller.hasClients ||
        controller.offset < 80 ||
        old.messages.isEmpty ||
        messages.isEmpty ||
        (old.messages.length == messages.length &&
            old.messages.last.id == messages.last.id)) {
      return;
    }
    // Capture an actually visible message before new content is laid out.
    // Keep it in the same place even when new messages arrive below it.
    final viewport = context.findRenderObject();
    if (viewport is! RenderBox || !viewport.hasSize) return;
    final top = viewport.localToGlobal(Offset.zero).dy;
    final bottom = top + viewport.size.height;
    final ids = messages.map((m) => m.id).toSet();
    final offset = controller.offset;
    for (final item in _anchors.entries) {
      final box = item.value.currentContext?.findRenderObject();
      if (!ids.contains(item.key) || box is! RenderBox || !box.hasSize)
        continue;
      final y = box.localToGlobal(Offset.zero).dy;
      if (y < top || y >= bottom) {
        continue;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            !controller.hasClients ||
            (controller.offset - offset).abs() > 1) return;
        final moved = item.value.currentContext?.findRenderObject();
        if (moved is! RenderBox || !moved.hasSize) return;
        final delta = y - moved.localToGlobal(Offset.zero).dy;
        if (delta.abs() > .5)
          controller.jumpTo((controller.offset + delta)
              .clamp(0.0, controller.position.maxScrollExtent));
      });
      break;
    }
    _anchors.removeWhere((id, _) => !ids.contains(id));
  }

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.forum_outlined, size: 42, color: context.fitlek.textMuted),
        const SizedBox(height: 16),
        const Text('Start the conversation',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('A little hello goes a long way.',
            style: TextStyle(color: context.fitlek.textMuted)),
      ]));
    }
    final items = <Object>[];
    for (var i = messages.length - 1; i >= 0; i--) {
      final message = messages[i];
      items.add(message);
      final date = message.time.toLocal();
      if (i == 0 || !_sameDay(messages[i - 1].time.toLocal(), date)) {
        items.add(DateTime(date.year, date.month, date.day));
      }
    }
    String key(Object item) =>
        item is ChatEntry ? 'message_${item.id}' : 'day_$item';
    final indices = {for (var i = 0; i < items.length; i++) key(items[i]): i};
    return ListView.builder(
        key: const PageStorageKey('conversation_timeline'),
        controller: controller,
        reverse: true,
        addRepaintBoundaries: false,
        // Compatible with the installed release compiler's framework cache.
        // ignore: deprecated_member_use
        cacheExtent: 160,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        itemCount: items.length + 1,
        findChildIndexCallback: (k) =>
            k is ValueKey<String> ? indices[k.value] : null,
        itemBuilder: (context, index) {
          if (index == items.length) {
            return loadingMore
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                        child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))))
                : retryOlder != null
                    ? Center(
                        child: TextButton.icon(
                            onPressed: retryOlder,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry older messages')))
                    : const SizedBox(height: 8);
          }
          final item = items[index];
          if (item is DateTime) {
            return Padding(
                key: ValueKey(key(item)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 17, vertical: 7),
                        decoration: BoxDecoration(
                            color: context.fitlek.card,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(_dayLabel(item),
                            style: TextStyle(
                                color: context.fitlek.textSecondary,
                                fontSize: 12)))));
          }
          final m = item as ChatEntry;
          final id = int.tryParse(m.id) ?? 0;
          return RepaintBoundary(
              key: ValueKey(key(m)),
              child: SelectableChatMessage(
                  selecting: selecting,
                  selected: selected.contains(id),
                  onToggle: () => onSelect(id),
                  child: KeyedSubtree(
                      key: _anchors.putIfAbsent(m.id, () => GlobalKey()),
                      child: ConversationBubble(
                          message: m, mediaStore: widget.mediaStore))));
        });
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
String _dayLabel(DateTime date) {
  final now = DateTime.now();
  final days = DateTime(now.year, now.month, now.day).difference(date).inDays;
  if (days == 0) return 'Today';
  if (days == 1) return 'Yesterday';
  const months = [
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
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

class ConversationBubble extends StatelessWidget {
  final ChatEntry message;
  final ChatMediaStore? mediaStore;
  const ConversationBubble({super.key, required this.message, this.mediaStore});
  @override
  Widget build(BuildContext context) {
    final m = message;
    final ink = chatInk(context, m.mine);
    final media = !m.deleted && ['image', 'audio'].contains(m.type);
    return Align(
        alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width *
                    (m.type == 'text' ? .81 : .86)),
            margin: const EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.all(m.type == 'image' && !m.deleted ? 5 : 12),
            decoration: BoxDecoration(
                color: chatBubbleColor(context, m.mine),
                borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(21),
                    topRight: const Radius.circular(21),
                    bottomLeft: Radius.circular(m.mine ? 21 : 5),
                    bottomRight: Radius.circular(m.mine ? 5 : 21))),
            child: DefaultTextStyle(
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: ink, fontSize: 15, height: 1.4),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: m.mine
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (m.deleted)
                        Text(
                            m.mine
                                ? 'You deleted this message'
                                : 'This message was deleted',
                            style: const TextStyle(
                                fontStyle: FontStyle.italic, fontSize: 13))
                      else if (media)
                        LocalChatMedia(
                            store: mediaStore,
                            messageID: int.tryParse(m.id) ?? 0,
                            url: m.url,
                            type: m.type,
                            expired: m.expired,
                            isMe: m.mine,
                            caption: m.body)
                      else
                        Text(m.body ?? ''),
                      const SizedBox(height: 5),
                      Padding(
                          padding: EdgeInsets.only(
                              right: m.type == 'image' ? 6 : 0,
                              bottom: m.type == 'image' ? 3 : 0),
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                    '${m.time.toLocal().hour.toString().padLeft(2, '0')}:${m.time.toLocal().minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                        color: ink.withValues(alpha: .6),
                                        fontSize: 10,
                                        height: 1)),
                                if (m.mine) ...[
                                  const SizedBox(width: 5),
                                  Icon(
                                      int.tryParse(m.id) == null
                                          ? Icons.schedule_rounded
                                          : m.read
                                              ? Icons.done_all_rounded
                                              : Icons.done_rounded,
                                      color: m.read
                                          ? const Color(0xFF269A84)
                                          : ink.withValues(alpha: .6),
                                      size: 15)
                                ],
                              ])),
                    ]))));
  }
}

class ConversationComposer extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool recording, busy;
  final VoidCallback onAttach, onGallery, onRecord, onSend;
  const ConversationComposer(
      {super.key,
      required this.controller,
      this.focusNode,
      required this.recording,
      required this.busy,
      required this.onAttach,
      required this.onGallery,
      required this.onRecord,
      required this.onSend});
  @override
  State<ConversationComposer> createState() => _ConversationComposerState();
}

class _ConversationComposerState extends State<ConversationComposer> {
  Timer? _timer;
  int _seconds = 0;
  @override
  void didUpdateWidget(ConversationComposer old) {
    super.didUpdateWidget(old);
    if (widget.recording && !old.recording) {
      _seconds = 0;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _seconds++);
      });
    } else if (!widget.recording && old.recording) {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: widget.controller,
          builder: (context, value, _) {
            final hasText = value.text.trim().isNotEmpty;
            return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _circle(
                  context,
                  'Attach photos',
                  Icons.add_rounded,
                  widget.busy || widget.recording ? null : widget.onAttach,
                  false),
              const SizedBox(width: 8),
              Expanded(
                  child: Container(
                      decoration: BoxDecoration(
                          color: context.fitlek.card,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: context.fitlek.border)),
                      child: Row(children: [
                        Expanded(
                            child: widget.recording
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 15),
                                    child: Text(
                                        'Recording ${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                            color: context.fitlek.error,
                                            fontSize: 13)))
                                : TextField(
                                    controller: widget.controller,
                                    focusNode: widget.focusNode,
                                    readOnly: widget.busy,
                                    minLines: 1,
                                    maxLines: 4,
                                    style: const TextStyle(fontSize: 14),
                                    decoration: InputDecoration(
                                        hintText: 'Write a message…',
                                        hintStyle: TextStyle(
                                            color: context.fitlek.textMuted),
                                        filled: false,
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 14)))),
                        if (!widget.recording)
                          IconButton(
                              tooltip: 'Photo gallery',
                              onPressed: widget.busy ? null : widget.onGallery,
                              icon: Icon(Icons.image_outlined,
                                  size: 22,
                                  color: context.fitlek.textSecondary)),
                      ]))),
              const SizedBox(width: 8),
              if (widget.busy)
                const SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                        child: SizedBox(
                            width: 21,
                            height: 21,
                            child: CircularProgressIndicator(strokeWidth: 2))))
              else
                _circle(
                    context,
                    widget.recording
                        ? 'Stop recording and send'
                        : hasText
                            ? 'Send message'
                            : 'Record voice message',
                    widget.recording
                        ? Icons.stop_rounded
                        : hasText
                            ? Icons.arrow_upward_rounded
                            : Icons.mic_none_rounded,
                    widget.recording || !hasText
                        ? widget.onRecord
                        : widget.onSend,
                    true),
            ]);
          }));
  Widget _circle(BuildContext context, String label, IconData icon,
          VoidCallback? tap, bool primary) =>
      SizedBox(
          width: 48,
          height: 48,
          child: IconButton.filled(
              tooltip: label,
              onPressed: tap,
              style: IconButton.styleFrom(
                  backgroundColor:
                      primary ? const Color(0xFFB6E3D3) : context.fitlek.card,
                  foregroundColor: primary
                      ? const Color(0xFF123E37)
                      : Theme.of(context).colorScheme.onSurface),
              icon: Icon(icon, size: 25)));
}
