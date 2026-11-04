import 'dart:async';
import 'package:flutter/widgets.dart';
import 'socketService.dart';

/// Only transmits activity labels; never drafts, audio data, or keystrokes.
class ConversationActivity extends ValueNotifier<String?>
    with WidgetsBindingObserver {
  final String conversationID;
  int? userID;
  final bool enabled;
  final void Function(String, String) _send;
  final DateTime Function() _clock;
  StreamSubscription<Map<String, dynamic>>? _subscription;
  Timer? _typingIdle, _heartbeat, _remoteExpiry;
  String _local = 'idle', _lastText = '';
  DateTime? _lastSent;
  bool _recording = false, _foreground = true;
  ConversationActivity(
      {required this.conversationID,
      this.userID,
      this.enabled = true,
      void Function(String, String)? send,
      Stream<Map<String, dynamic>>? events,
      DateTime Function()? clock})
      : _send = send ?? SocketService().sendChatActivity,
        _clock = clock ?? DateTime.now,
        super(null) {
    if (!enabled) return;
    WidgetsBinding.instance.addObserver(this);
    _subscription = (events ?? SocketService().activities).listen(_receive);
  }
  void _receive(Map<String, dynamic> event) {
    if (event['reset'] == true) {
      _remoteExpiry?.cancel();
      value = null;
      return;
    }
    if ('${event['conversationID']}' != conversationID ||
        '${event['userID']}' == '$userID') return;
    _remoteExpiry?.cancel();
    value = switch (event['activity']) {
      'typing' => 'Typing…',
      'recording' => 'Recording a voice message…',
      _ => null
    };
    if (value != null)
      _remoteExpiry = Timer(
          Duration(
              milliseconds: (int.tryParse('${event['expiresInMs']}') ?? 7000)
                  .clamp(1000, 10000)),
          () => value = null);
  }

  void textChanged(String text) {
    if (text == _lastText) return;
    _lastText = text;
    _typingIdle?.cancel();
    if (_recording) return;
    if (text.trim().isEmpty) {
      _publish('idle');
      return;
    }
    _publish('typing');
    _typingIdle = Timer(const Duration(seconds: 2), () => _publish('idle'));
  }

  void recording(bool active) {
    if (_recording == active) return;
    _recording = active;
    _typingIdle?.cancel();
    _heartbeat?.cancel();
    _publish(active ? 'recording' : 'idle');
    if (active)
      _heartbeat = Timer.periodic(
          const Duration(seconds: 3), (_) => _publish('recording'));
  }

  void _publish(String activity) {
    if (!enabled || !_foreground && activity != 'idle') return;
    final now = _clock();
    if (_local == activity &&
        _lastSent != null &&
        now.difference(_lastSent!).inMilliseconds < 1200) return;
    _local = activity;
    _lastSent = now;
    _send(conversationID, activity);
  }

  void stopTyping() {
    _typingIdle?.cancel();
    if (!_recording) _publish('idle');
  }

  void messageReceived(int senderID) {
    if (senderID != userID) {
      _remoteExpiry?.cancel();
      value = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _typingIdle?.cancel();
      _publish('idle');
      value = null;
    } else if (_recording) _publish('recording');
  }

  @override
  void dispose() {
    _publish('idle');
    _typingIdle?.cancel();
    _heartbeat?.cancel();
    _remoteExpiry?.cancel();
    _subscription?.cancel();
    if (enabled) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
