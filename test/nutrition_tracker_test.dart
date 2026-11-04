import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlek1/services/meal_scan_service.dart';
import 'package:fitlek1/services/nutrition_diary_service.dart';
import 'package:fitlek1/screens/ENG/nutritionTracker.dart';
import 'package:fitlek1/theme/app_theme.dart';

ScannedMeal sample(
        {String id = 'meal_1',
        double calories = 450,
        String type = 'lunch',
        String day = '2026-10-15'}) =>
    ScannedMeal(
        id: id,
        name: 'Chicken tagine',
        notes: '',
        confidence: 'medium',
        createdAt: DateTime.utc(2026, 10, 15, 12),
        mealDate: day,
        mealType: type,
        portion: 1,
        photoPath: '',
        ingredients: [
          MealIngredient(
              name: 'Chicken',
              grams: 150,
              calories: calories,
              protein: 35,
              carbs: 40,
              fat: 16)
        ]);

class TestDiary extends NutritionDiaryService {
  final meals = <ScannedMeal>[sample()];
  final dates = <String>[];
  bool failSave = false;
  Map<String, double?>? savedGoals;
  TestDiary() : super(7, 'test');
  @override
  Future<NutritionDay> day(DateTime date) async {
    dates.add(ScannedMeal.dayKey(date));
    return NutritionDay(meals
        .where((meal) => meal.mealDate == ScannedMeal.dayKey(date))
        .toList());
  }

  @override
  Future<Map<String, dynamic>> goalPlan() async => {'plan': null};
  @override
  Future<Map<String, double?>> goals() async =>
      {'calories': 2000, 'protein': 120, 'carbs': 250, 'fat': 70};
  @override
  Future<void> save(ScannedMeal meal) async {
    if (failSave) throw Exception('Network');
    meals.removeWhere((old) => old.id == meal.id);
    meals.add(meal);
  }

  @override
  Future<void> delete(ScannedMeal meal) async {
    meals.removeWhere((old) => old.id == meal.id);
  }

  @override
  Future<void> saveGoals(Map<String, double?> goals) async {
    savedGoals = goals;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('opening and saving daily targets preserves decimal values',
      (tester) async {
    final service = TestDiary();
    addTearDown(service.close);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
            body: NutritionGoalsSheet(
                goals: const {'protein': 130.5}, service: service))));
    await tester.pumpAndSettle();
    expect(find.text('130.5'), findsOneWidget);
    await tester.ensureVisible(find.text('Save targets'));
    await tester.tap(find.text('Save targets'));
    await tester.pumpAndSettle();
    expect(service.savedGoals?['protein'], 130.5);
    expect(service.savedGoals?['calories'], isNull);
  });
  test(
      'account history migrates once, retries keep IDs and sends no local photos',
      () async {
    final folder =
        await Directory.systemTemp.createTemp('sirvya-nutrition-test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => folder.path);
    addTearDown(() async {
      await folder.delete(recursive: true);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('plugins.flutter.io/path_provider'), null);
    });
    final records = <String, dynamic>{};
    var puts = 0;
    var fail = false;
    final service =
        NutritionDiaryService(7, 'test', client: MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer test');
      if (request.method == 'PUT') {
        if (fail) return http.Response('{"message":"offline"}', 503);
        puts++;
        final data = jsonDecode(request.body) as Map<String, dynamic>;
        expect(data.containsKey('photoPath'), false);
        expect(data.containsKey('photoData'), false);
        records[data['id']] = data;
        return http.Response(jsonEncode(data), 200);
      }
      if (request.method == 'DELETE') {
        records.remove(request.url.pathSegments.last);
        return http.Response('', 204);
      }
      return http.Response(
          jsonEncode({
            'meals': records.values
                .where((meal) =>
                    meal['mealDate'] == request.url.queryParameters['date'])
                .toList()
          }),
          200);
    }));
    addTearDown(service.close);
    final prefs = await SharedPreferences.getInstance();
    final old = sample().toJson()
      ..remove('mealDate')
      ..remove('mealType');
    await prefs.setString('meal_history_v1_7', jsonEncode([old]));
    expect((await service.day(DateTime(2026, 10, 15))).total('calories'), 450);
    await service.day(DateTime(2026, 10, 15));
    expect(puts, 1);
    final edited = sample(calories: 600, type: 'dinner');
    fail = true;
    await expectLater(service.save(edited), throwsException);
    fail = false;
    expect((await service.day(DateTime(2026, 10, 15))).total('calories'), 600);
    expect(records.length, 1);
    expect(puts, 2);
    expect((await service.day(DateTime(2026, 10, 14))).meals, isEmpty);
    final other = NutritionDiaryService(8, 'other',
        client: MockClient((_) async => http.Response('{"meals":[]}', 200)));
    addTearDown(other.close);
    expect((await other.day(DateTime(2026, 10, 15))).meals, isEmpty);
    await service.delete(edited);
    expect(records, isEmpty);
    expect(await MealScanService.history(7), isEmpty);
  });
  for (final dark in [true, false]) {
    testWidgets(
        'daily totals, dates and meal removal fit small screens, dark=$dark',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final service = TestDiary();
      addTearDown(service.close);
      await tester.pumpWidget(MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: NutritionTrackerScreen(
              clientID: 7,
              token: 'test',
              service: service,
              initialDate: DateTime(2026, 10, 15))));
      await tester.pumpAndSettle();
      expect(find.text('450'), findsOneWidget);
      expect(find.text('35.0 g'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Previous day'));
      await tester.pumpAndSettle();
      expect(find.text('0'), findsOneWidget);
      await tester.tap(find.byTooltip('Next day'));
      await tester.pumpAndSettle();
      expect(find.text('450'), findsOneWidget);
      await tester.scrollUntilVisible(
          find.byTooltip('Remove Chicken tagine'), 200);
      await tester.tap(find.byTooltip('Remove Chicken tagine'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete meal'));
      await tester.pumpAndSettle();
      expect(service.meals, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
      'manual logging preserves failed input and retry creates one meal',
      (tester) async {
    final service = TestDiary()..failSave = true;
    addTearDown(service.close);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
            body: NutritionEntrySheet(
                date: DateTime(2026, 10, 15), service: service))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Harira');
    for (final key in nutritionKeys) {
      await tester.enterText(find.byKey(ValueKey('manual-$key')),
          key == 'calories' ? '320,5' : '20');
    }
    await tester.ensureVisible(find.text('Save meal'));
    await tester.tap(find.text('Save meal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save to Lunch'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not sync'), findsOneWidget);
    expect(find.text('Harira'), findsOneWidget);
    service.failSave = false;
    await tester.ensureVisible(find.text('Save meal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save meal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save to Lunch'));
    await tester.pumpAndSettle();
    expect(service.meals.where((meal) => meal.name == 'Harira').length, 1);
    expect(service.meals.last.total('calories'), 320.5);
  });
}
