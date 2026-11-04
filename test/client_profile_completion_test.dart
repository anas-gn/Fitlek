import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/models/client_profile_completion.dart';

void main() {
  test(
      'empty profile has actionable next step and never invents a fitness goal',
      () {
    final progress = ClientProfileCompletion({});
    expect(progress.percent, 0);
    expect(progress.next!.section, 'photo');
    expect(clientInterests(null), isEmpty);
    expect(clientInterests('invalid JSON'), isEmpty);
  });
  test('completion reflects persisted details and reaches 100%', () {
    final saved = <String, dynamic>{
      'avatarUrl': 'https://example.test/me.jpg',
      'firstName': 'Amal',
      'lastName': 'Client',
      'email': 'a@example.test',
      'phoneNumber': '+212612345678',
      'ville': 'El Jadida',
      'height': '172.5',
      'interests': '["Yoga"]'
    };
    expect(ClientProfileCompletion(saved).percent, 100);
    expect(ClientProfileCompletion(saved).isComplete, true);
    saved['phoneNumber'] = ' ';
    expect(ClientProfileCompletion(saved).percent, 87);
    expect(ClientProfileCompletion(saved).next!.section, 'phone');
    saved['phoneNumber'] = '+212612345678';
    expect(ClientProfileCompletion(saved).next, isNull);
  });
  test(
      'invalid height does not complete profile and interests normalize safely',
      () {
    for (final height in [-1, 0, 301, 'NaN', 'Infinity']) {
      expect(ClientProfileCompletion({'height': height}).completed, 0);
    }
    expect(clientInterests('[" Yoga ","Yoga","Swimming",null]'),
        ['Yoga', 'Swimming']);
  });
}
