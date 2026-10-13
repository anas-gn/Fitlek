import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlek1/services/onboarding_service.dart';
import 'package:fitlek1/services/apiService.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('introduction shows once and remains dismissed after logout', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await OnboardingService.showOnce(), isTrue);
    expect(await OnboardingService.showOnce(), isFalse);
    await ApiService.clearToken();
    expect(await OnboardingService.showOnce(), isFalse);
  });
  test('returning signed-in accounts bypass introduction', () async {
    SharedPreferences.setMockInitialValues({});
    await ApiService.saveToken('test');
    expect(await OnboardingService.showOnce(), isFalse);
  });
  test('existing accounts without the new flag bypass intro after logout', () async {
    SharedPreferences.setMockInitialValues({'role': 'client'});
    await ApiService.clearToken();
    expect(await OnboardingService.showOnce(), isFalse);
  });
}
