import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/screens/ENG/nutritionGoal.dart';
import 'package:fitlek1/components/nutrition_goal_card.dart';
import 'package:fitlek1/theme/app_theme.dart';
import 'nutrition_tracker_test.dart' show TestDiary;

Map<String, dynamic> fixture() => {
      'goalType': 'lose',
      'age': 30,
      'height': 175,
      'currentWeight': 80,
      'targetWeight': 75,
      'activity': 'light',
      'diet': 'balanced',
      'timeZone': 'Africa/Casablanca',
      'status': 'active',
      'revision': 1,
      'targets': {'calories': 2200, 'protein': 120, 'carbs': 250, 'fat': 70},
      'reminders': {
        'enabled': false,
        'calorieAlerts': true,
        'monthly': true,
        'yearly': true,
        'weekly': true,
        'mealIdeas': false
      }
    };

class GoalService extends TestDiary {
  Map<String, dynamic>? saved;
  bool fail = false;
  final periods = <String>[];
  @override
  Future<Map<String, dynamic>> goalPlan() async => {
        'plan': saved ?? fixture(),
        'progress': {
          'currentWeight': 77.5,
          'targetWeight': 75,
          'percent': 50,
          'measurements': 2
        }
      };
  @override
  Future<void> savePlan(Map<String, dynamic> plan) async {
    if (fail) throw Exception('Could not save right now');
    saved = plan;
  }

  @override
  Future<Map<String, dynamic>> review(DateTime from, DateTime to) async {
    periods.add('${from.year}-${from.month}:${to.year}-${to.month}');
    return {
      'loggedDays': 12,
      'meals': 30,
      'dailyAverages': {
        'calories': 2100,
        'protein': 110,
        'carbs': 230,
        'fat': 75
      },
      'weight': {'checkIns': 3, 'first': 80, 'latest': 78.5, 'change': -1.5}
    };
  }
}

void main() {
  test(
      'optional maintenance estimate has adult eligibility and range boundaries',
      () {
    expect(
        maintenanceCalories(
            age: 30,
            height: 180,
            weight: 80,
            sex: 'male',
            activity: 'low',
            eligible: true),
        2150);
    expect(
        maintenanceCalories(
            age: 30,
            height: 170,
            weight: 70,
            sex: 'female',
            activity: 'low',
            eligible: true),
        1750);
    expect(
        maintenanceCalories(
            age: 17,
            height: 170,
            weight: 70,
            sex: 'female',
            activity: 'low',
            eligible: true),
        isNull);
    expect(
        maintenanceCalories(
            age: 30,
            height: 170,
            weight: 70,
            sex: 'female',
            activity: 'low',
            eligible: false),
        isNull);
  });
  for (final dark in [true, false]) {
    testWidgets(
        'profile goal can be edited and reminders are opt-in, dark=$dark',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 820));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final service = GoalService();
      addTearDown(service.close);
      await tester.pumpWidget(MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: Scaffold(
              body: ListView(children: [
            NutritionGoalCard(clientID: 7, token: 'test', service: service)
          ]))));
      await tester.pumpAndSettle();
      expect(find.text('Lose weight gradually'), findsOneWidget);
      expect(find.text('Active · Reminders off'), findsOneWidget);
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Nutrition reminders'));
      await tester.pumpAndSettle();
      await tester
          .tap(find.widgetWithText(SwitchListTile, 'Nutrition reminders'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save my goal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save my goal'));
      await tester.pumpAndSettle();
      expect(service.saved?['reminders']['enabled'], true);
      expect(service.saved?['timeZone'], 'Africa/Casablanca');
      expect(service.saved?['targets']['protein'], 120);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
      'signup supports balanced tracking without forcing numerical targets',
      (tester) async {
    Map<String, dynamic>? result;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      result = await Navigator.push<Map<String, dynamic>>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NutritionGoalScreen(
                                  signup: true, initial: {'age': 15})));
                    },
                    child: const Text('Set up'))))));
    await tester.tap(find.text('Set up'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('goal-calories')), findsNothing);
    await tester.ensureVisible(find.text('Use this goal'));
    await tester.tap(find.text('Use this goal'));
    await tester.pumpAndSettle();
    expect(result?['goalType'], 'balanced');
    expect(result?['targets']['calories'], isNull);
    expect(result?['reminders']['enabled'], false);
    expect(result?['reminders']['calorieAlerts'], false);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'off-screen required fields still prevent an incomplete weight goal from saving',
      (tester) async {
    final service = GoalService();
    addTearDown(service.close);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: NutritionGoalScreen(
            service: service, initial: {'goalType': 'lose', 'age': 30})));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save my goal'));
    await tester.tap(find.text('Save my goal'));
    await tester.pumpAndSettle();
    expect(service.saved, isNull);
    expect(find.text('Add Height (cm)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'monthly and yearly reviews use real logged-day averages and weight check-ins',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = GoalService();
    addTearDown(service.close);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark, home: NutritionReviewScreen(service: service)));
    await tester.pumpAndSettle();
    expect(find.text('12 days logged'), findsOneWidget);
    expect(find.textContaining('Unlogged days'), findsOneWidget);
    await tester.tap(find.text('Yearly'));
    await tester.pumpAndSettle();
    expect(service.periods.last, endsWith('-1'));
    await tester.scrollUntilVisible(find.text('Weight check-ins'), 150);
    expect(tester.takeException(), isNull);
  });
}
