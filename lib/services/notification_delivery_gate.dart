/// Firebase and the live connection can deliver the same persistent alert.
class NotificationDeliveryGate {
  final _seen = <String>{};
  bool accept(Map<String, dynamic> item) {
    final id = '${item['notificationID'] ?? item['messageID'] ?? ''}';
    if (id.isEmpty) return true;
    if (!_seen.add(id)) return false;
    if (_seen.length > 500) _seen.remove(_seen.first);
    return true;
  }

  void clear() => _seen.clear();
}
