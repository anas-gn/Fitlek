import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/services/workout_service.dart';
import 'package:fitlek1/screens/ENG/workout/workout_ui.dart';

void main() {
  tearDown(() => WorkoutService.preferences = {});

  test('history and dashboard honor the configured training date near midnight',
      () {
    WorkoutService.preferences = {'timeZone': 'Africa/Casablanca'};
    expect(workoutDate('2024-02-04T23:30:00Z'), '05/02/2024');
    final now = WorkoutService.trainingTime(DateTime.utc(2024, 2, 4, 23, 30));
    expect(now.weekday, DateTime.monday);
    expect(now.day, 5);
    WorkoutService.preferences = {'timeZone': 'Pacific/Honolulu'};
    expect(workoutDate('2024-02-05T00:30:00Z'), '04/02/2024');
  });

  test(
      'bodyweight DATE values retain their calendar date in all training zones',
      () {
    for (final zone in ['Pacific/Honolulu', 'Pacific/Kiritimati', 'UTC']) {
      WorkoutService.preferences = {'timeZone': zone};
      expect(workoutDate('2024-02-05'), '05/02/2024');
    }
  });

  test('training date conversion follows daylight-saving transitions', () {
    WorkoutService.preferences = {'timeZone': 'America/New_York'};
    expect(
        WorkoutService.trainingTime(DateTime.utc(2024, 3, 10, 6, 30)).hour, 1);
    expect(
        WorkoutService.trainingTime(DateTime.utc(2024, 3, 10, 7, 30)).hour, 3);
    expect(workoutDate('not-a-date'), '');
  });
}
