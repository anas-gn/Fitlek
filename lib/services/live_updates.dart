import 'dart:async';
import 'package:flutter/widgets.dart';
import 'socketService.dart';

/// Read screens refresh authoritative data without discarding form input or routes.
mixin LiveUpdates<T extends StatefulWidget> on State<T> {
  StreamSubscription<Map<String, dynamic>>? _liveSubscription;
  Timer? _liveDebounce;
  bool _liveBusy = false;
  bool _liveAgain = false;
  Set<String> get liveDomains;
  Future<void> refreshLiveData();

  @override
  void initState() {
    super.initState();
    SocketService().connect();
    _liveSubscription = SocketService().updates.listen((event) {
      final domain = event['domain'];
      if (domain == 'all' || liveDomains.contains(domain)) {
        _liveDebounce?.cancel();
        _liveDebounce = Timer(const Duration(milliseconds: 250), _refreshLive);
      }
    });
  }

  Future<void> _refreshLive() async {
    if (!mounted) return;
    if (_liveBusy) {
      _liveAgain = true;
      return;
    }
    _liveBusy = true;
    try {
      await refreshLiveData();
    } catch (_) {
      // Keep existing content during temporary network interruptions.
    } finally {
      _liveBusy = false;
      if (_liveAgain && mounted) {
        _liveAgain = false;
        _refreshLive();
      }
    }
  }

  @override
  void dispose() {
    _liveDebounce?.cancel();
    _liveSubscription?.cancel();
    super.dispose();
  }
}
