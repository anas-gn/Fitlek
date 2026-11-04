import 'chat_media_store.dart';
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/widgets.dart';
import '../constants/urls.dart' as urls;
import 'apiService.dart';

class SocketService with WidgetsBindingObserver {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();
  IO.Socket? _socket;
  Timer? _mediaSyncTimer;
  String? _token;
  bool _observing = false;
  int _generation = 0;
  final _rooms = <String>{};
  final _updates = StreamController<Map<String, dynamic>>.broadcast();
  final _notifications = StreamController<Map<String, dynamic>>.broadcast();
  final _messages = StreamController<Map<String, dynamic>>.broadcast();
  final _activities = StreamController<Map<String, dynamic>>.broadcast();
  final _localActivities = <String, String>{};
  final connected = ValueNotifier<bool>(false);
  Stream<Map<String, dynamic>> get updates => _updates.stream;
  Stream<Map<String, dynamic>> get notifications => _notifications.stream;
  Stream<Map<String, dynamic>> get messages => _messages.stream;
  Stream<Map<String, dynamic>> get activities => _activities.stream;
  StreamSubscription<Map<String, dynamic>>? _legacyMessageSubscription;

  Future<void> connect() async {
    final generation = _generation;
    final token = await ApiService.getToken();
    if (generation != _generation || token == null || token.isEmpty) return;
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    if (_socket != null && token == _token) {
      if (!_socket!.connected) _socket!.connect();
      return;
    }
    _socket?.dispose();
    _token = token;
    final socket = IO.io(
        urls.baseUrl.replaceFirst(RegExp(r'/api/?$'), ''),
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .enableForceNew()
            .disableAutoConnect()
            .build());
    _socket = socket;
    socket.onConnect((_) {
      connected.value = true;
      unawaited(ChatMediaStore.instance.syncPending());
      _mediaSyncTimer?.cancel();
      _mediaSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
        if (socket.connected) unawaited(ChatMediaStore.instance.syncPending());
      });
      for (final room in _rooms) {
        _join(socket, room);
      }
      invalidate(
          'all'); // Catch up after offline periods, server restarts and resume.
    });
    socket.onDisconnect((_) {
      connected.value = false;
      _activities.add({'reset': true});
    });
    socket.on('conversation_activity', (data) {
      if (data is Map) _activities.add(Map<String, dynamic>.from(data));
    });
    socket.on('data_changed', (data) {
      if (data is Map && data['domain'] == 'chat-actions')
        unawaited(ChatMediaStore.instance.syncPending());
      if (data is Map) _updates.add(Map<String, dynamic>.from(data));
    });
    socket.on('notification_created', (data) {
      if (data is Map) _notifications.add(Map<String, dynamic>.from(data));
      invalidate('notifications');
    });
    socket.on('new_message', (data) {
      unawaited(ChatMediaStore.instance.syncPending());
      if (data is Map) _messages.add(Map<String, dynamic>.from(data));
      invalidate('messages');
    });
    socket.connect();
  }

  void invalidate(String domain) => _updates.add({'domain': domain});
  void joinRoom(String id) {
    _rooms.add(id);
    final socket = _socket;
    if (socket != null && socket.connected) _join(socket, id);
  }

  void _join(IO.Socket socket, String id) {
    socket.emitWithAck('join_room', {'conversationId': id}, ack: (data) {
      if (data is Map && data['ok'] == true && _rooms.contains(id)) {
        final activity = _localActivities[id];
        if (activity != null && socket.connected)
          socket.emit('conversation_activity',
              {'conversationID': id, 'activity': activity});
      }
    });
  }

  void sendChatActivity(String id, String activity) {
    if (activity == 'idle') {
      _localActivities.remove(id);
    } else {
      _localActivities[id] = activity;
    }
    // Ephemeral presence must never queue and replay an old "typing" state.
    if (_socket?.connected == true && _rooms.contains(id))
      _socket!.emit('conversation_activity',
          {'conversationID': id, 'activity': activity});
  }

  void leaveRoom(String id) {
    sendChatActivity(id, 'idle');
    _rooms.remove(id);
    _socket?.emit('leave_room', {'conversationId': id});
  }

  void onNewMessage(void Function(Map<String, dynamic>) callback) {
    _legacyMessageSubscription?.cancel();
    _legacyMessageSubscription = messages.listen(callback);
  }

  void offNewMessage() {
    _legacyMessageSubscription?.cancel();
    _legacyMessageSubscription = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      connect();
      invalidate('all');
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _socket?.disconnect();
    }
  }

  void disconnect() {
    _mediaSyncTimer?.cancel();
    _mediaSyncTimer = null;
    _generation++;
    _socket?.dispose();
    _socket = null;
    _token = null;
    _rooms.clear();
    _localActivities.clear();
    connected.value = false;
    _activities.add({'reset': true});
    offNewMessage();
    if (_observing) WidgetsBinding.instance.removeObserver(this);
    _observing = false;
  }
}
