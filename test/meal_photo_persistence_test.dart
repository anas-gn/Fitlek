import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlek1/services/apiService.dart';
import 'package:fitlek1/services/meal_scan_service.dart';
import 'package:fitlek1/services/nutrition_diary_service.dart';
import 'meal_result_test.dart' show sampleMeal;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const paths = MethodChannel('plugins.flutter.io/path_provider');
  late Directory documents;

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('sirvya-meal-photos-');
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(paths, (_) async => documents.path);
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(paths, null);
    await documents.delete(recursive: true);
  });

  test('logout keeps device photos and account-specific links across sign-ins',
      () async {
    final source =
        await File('${documents.path}/camera.jpg').writeAsBytes([1, 2, 3, 4]);
    final meal = sampleMeal()..photoPath = source.path;
    Map<String, dynamic>? remote;
    var uploads = 0;
    final service =
        NutritionDiaryService(7, 'test', client: MockClient((r) async {
      if (r.method == 'PUT') {
        uploads++;
        remote = jsonDecode(r.body);
        expect(remote!.containsKey('photoPath'), isFalse);
        expect(remote!.containsKey('photoData'), isFalse);
        return http.Response('{}', 200);
      }
      return http.Response(
          jsonEncode({
            'meals': [remote]
          }),
          200);
    }));
    addTearDown(service.close);
    await service.save(meal);
    await source.delete(); // Camera's temporary file is no longer needed.
    final photo = File(meal.photoPath);
    await ApiService.saveRole('client');
    await ApiService.saveUserData(7, 'Client');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_only', 'discard this');
    await ApiService.clearToken();
    expect(prefs.getString('role'), isNull);
    expect(prefs.getInt('userId'), isNull);
    expect(prefs.getString('session_only'), isNull);
    expect(await photo.readAsBytes(), [1, 2, 3, 4]);
    expect((await MealScanService.history(7)).single.photoPath, photo.path);
    expect(await MealScanService.history(8), isEmpty);

    await ApiService.saveUserData(7, 'Client');
    expect(
        (await service.day(meal.createdAt)).meals.single.photoPath, photo.path);
    expect(uploads, 1); // Logging out did not lose the sync record either.
    await ApiService.clearToken();
    expect((await MealScanService.history(7)).single.photoPath, photo.path);
  });

  test('older logout damage recovers only the signed-in client local photo',
      () async {
    final meal = sampleMeal()..photoBytes = Uint8List.fromList([9, 8, 7]);
    await MealScanService.save(
        7, meal); // Missing temporary path uses held bytes.
    final saved = File(meal.photoPath);
    expect(await saved.readAsBytes(), [9, 8, 7]);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('meal_history_v1_7'); // Previous app's logout behavior.
    final remote = meal.nutritionJson();
    NutritionDiaryService service(int id) => NutritionDiaryService(id, 'test',
        client: MockClient((_) async => http.Response(
            jsonEncode({
              'meals': [remote]
            }),
            200)));
    final owner = service(7), other = service(8);
    addTearDown(owner.close);
    addTearDown(other.close);
    expect(
        (await owner.day(meal.createdAt)).meals.single.photoPath, saved.path);
    expect((await other.day(meal.createdAt)).meals.single.photoPath, isEmpty);
    final unsafe = ScannedMeal.fromJson({...remote, 'id': '../7/test'});
    await MealScanService.restorePhotos(8, [unsafe]);
    expect(unsafe.photoPath, isEmpty);
  });

  test(
      'explicit meal deletion still removes its photo and preserves other accounts',
      () async {
    final first = sampleMeal()..photoBytes = Uint8List.fromList([1]);
    final second = sampleMeal()..photoBytes = Uint8List.fromList([2]);
    await MealScanService.save(7, first);
    await MealScanService.save(8, second);
    final service =
        NutritionDiaryService(7, 'test', client: MockClient((r) async {
      expect(r.method, 'DELETE');
      return http.Response('{}', 200);
    }));
    addTearDown(service.close);
    await service.delete(first);
    expect(await File(first.photoPath).exists(), isFalse);
    expect(await MealScanService.history(7), isEmpty);
    expect(await File(second.photoPath).readAsBytes(), [2]);
    expect(
        (await MealScanService.history(8)).single.photoPath, second.photoPath);
  });
}
