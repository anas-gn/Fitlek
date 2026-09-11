import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import '../constants/urls.dart' as urls;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;

  /// Connect to the socket server
  void connect() {
    if (_socket != null && _socket!.connected) return;

    final socketUrl = urls.baseUrl.replaceAll('/api', '');
    
    _socket = IO.io(socketUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .build()
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      if (kDebugMode) debugPrint('Socket connected: ${_socket!.id}');
    });

    _socket!.onDisconnect((_) {
      if (kDebugMode) debugPrint('Socket disconnected');
    });
  }

  /// Join a conversation room
  void joinRoom(String conversationId) {
    if (_socket != null) {
      _socket!.emit('join_room', {'conversationId': conversationId});
    }
  }

  /// Leave a conversation room
  void leaveRoom(String conversationId) {
    if (_socket != null) {
      _socket!.emit('leave_room', {'conversationId': conversationId});
    }
  }

  /// Listen for incoming messages
  void onNewMessage(Function(Map<String, dynamic>) callback) {
    if (_socket != null) {
      _socket!.on('new_message', (data) => callback(data));
    }
  }

  /// Remove listener
  void offNewMessage() {
    if (_socket != null) {
      _socket!.off('new_message');
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
  }
}
