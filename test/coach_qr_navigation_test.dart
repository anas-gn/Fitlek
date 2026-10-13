import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/services/coach_qr_navigation.dart';
void main() {
 test('QR resolves coach from server independently of loaded Explore results', () async {
  String? requested;
  final id = await CoachQrNavigation.resolveCoachId('https://api.example.com/api/invite/AB12CD',get:(path) async {
   requested=path;return {'ok':true,'data':[{'id':87}]};
  });
  expect(id,87);expect(requested,'/coaches?invitationCode=AB12CD&limit=1');
 });
 test('unknown code is distinct from server failure', () async {
  expect(await CoachQrNavigation.resolveCoachId('AB12CD',get:(_)async=>{'ok':true,'data':[]}),isNull);
  await expectLater(CoachQrNavigation.resolveCoachId('AB12CD',get:(_)async=>{'ok':false}),throwsException);
 });
 test('invalid QR never requests an account', () async {
  bool called=false;
  expect(await CoachQrNavigation.resolveCoachId('https://example.com/payment',get:(_)async{called=true;return {}; }),isNull);
  expect(called,false);
 });
}
