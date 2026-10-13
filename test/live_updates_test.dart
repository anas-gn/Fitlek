import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlek1/services/live_updates.dart';
import 'package:fitlek1/services/socketService.dart';
import 'package:fitlek1/services/notification_delivery_gate.dart';

class LiveProbe extends StatefulWidget {
  final VoidCallback refreshed;
  const LiveProbe(this.refreshed, {super.key});
  @override
  State<LiveProbe> createState() => _LiveProbeState();
}

class _LiveProbeState extends State<LiveProbe> with LiveUpdates<LiveProbe> {
  @override
  Set<String> get liveDomains => {'reservations'};
  @override
  Future<void> refreshLiveData() async {
    widget.refreshed();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  test('one sound/banner for socket and Firebase copies of an alert', () {
    final gate = NotificationDeliveryGate();
    expect(gate.accept({'notificationID': 42}), isTrue);
    expect(gate.accept({'notificationID': '42'}), isFalse);
    expect(gate.accept({'notificationID': 43}), isTrue);
    gate.clear();
    expect(gate.accept({'notificationID': 42}), isTrue);
  });
  testWidgets(
      'live updates filter domains, debounce bursts, catch up and unsubscribe',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    int calls = 0;
    await tester.pumpWidget(MaterialApp(home: LiveProbe(() => calls++)));
    SocketService().invalidate('packages');
    await tester.pump(const Duration(milliseconds: 300));
    expect(calls, 0);
    SocketService().invalidate('reservations');
    SocketService().invalidate('reservations');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(calls, 1);
    SocketService().invalidate('all');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(calls, 2);
    await tester.pumpWidget(const SizedBox());
    SocketService().invalidate('reservations');
    await tester.pump(const Duration(milliseconds: 300));
    expect(calls, 2);
    SocketService().disconnect();
  });
}
