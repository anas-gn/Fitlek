import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/components/location_picker.dart';
import 'package:fitlek1/theme/app_theme.dart';

void main() {
  testWidgets(
      'detected city and address are read-only and refresh opt-out preserves GPS',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Map<String, dynamic>? selected;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
            body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: LocationPicker(initial: {
            'city': 'Casablanca',
            'latitude': 33.5,
            'longitude': -7.6,
            'fullAddress': 'Private old address',
            'autoRefresh': true
          }, onChanged: (value) => selected = value),
        ))));
    expect(find.text('Keep my location updated'), findsOneWidget);
    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields.every((field) => field.readOnly), isTrue);
    expect(fields.first.controller!.text, 'Casablanca');
    expect(fields.last.controller!.text, 'Private old address');
    expect(find.text('Use my current location'), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    expect(selected?['city'], 'Casablanca');
    expect(selected?['latitude'], 33.5);
    expect(selected?['longitude'], -7.6);
    expect(selected?['fullAddress'], 'Private old address');
    expect(selected?['autoRefresh'], false);
    expect(tester.takeException(), isNull);
  });
}
