import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/services/campaign_service.dart';
import 'package:fitlek1/theme/app_theme.dart';

void main() {
  for (final light in [false, true]) {
    testWidgets(
        'campaign popup fits small screens and returns the selected action, light=$light',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      bool? action;
      await tester.pumpWidget(MaterialApp(
          theme: light ? AppTheme.light : AppTheme.dark,
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () async {
                        action = await showDialog<bool>(
                            context: context,
                            builder: (_) => CampaignDialog(item: {
                                  'title': 'Meet your next coach',
                                  'body': List.filled(
                                          25, 'A personalized experience.')
                                      .join(' '),
                                  'buttonLabel': 'Find my coach',
                                  'destination': '/explore'
                                }));
                      },
                      child: const Text('Open'))))));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Find my coach'));
      await tester.pumpAndSettle();
      expect(action, isTrue);
      expect(find.byType(CampaignDialog), findsNothing);
    });
  }
}
