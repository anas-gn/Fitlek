import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/services/referral_link_service.dart';
void main() {
 test('invitation links normalize codes and ignore other app links', () {
  expect(ReferralLinkService.parseCode(Uri.parse('sirvya://invite?code=ab12cd')), 'AB12CD');
  expect(ReferralLinkService.parseCode(Uri.parse('sirvya://payment?code=ab12cd')), isNull);
  expect(ReferralLinkService.parseCode(Uri.parse('sirvya://invite?code=%3Cscript%3E')), isNull);
 });
 test('scanner accepts a shared QR link and existing plain codes', () {
  expect(ReferralLinkService.codeFromQr('https://api.example.com/api/invite/AB12CD'), 'AB12CD');
  expect(ReferralLinkService.codeFromQr('sirvya://invite?code=ab12cd'), 'AB12CD');
  expect(ReferralLinkService.codeFromQr('ab12cd'), 'AB12CD');
  expect(ReferralLinkService.codeFromQr('https://example.com/other/AB12CD'), isNull);
 });
}
