import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/models/coach_profile_completion.dart';
void main() {
  test('all profile fields are needed and next step updates', () {
    final data = <String,dynamic>{};
    expect(CoachProfileCompletion(data,0,0).percent,0);
    expect(CoachProfileCompletion(data,0,0).next!.message,contains('profile photo'));
    for (final field in ['avatarUrl','firstName','lastName','email','tel','gender','professionalTitle','bio','languages','instagramPage','specialties','experience','clientLevels','certifications','ville','coachingFormats','serviceArea','gymName','gymAddress','gymImage']) {
      data[field]='filled';
    }
    final withoutPackage=CoachProfileCompletion(data,0,0);
    expect(withoutPackage.isComplete,false);expect(withoutPackage.next!.section,'packages');
    expect(CoachProfileCompletion(data,0,1).next!.section,'photos');
    final complete=CoachProfileCompletion(data,1,1);
    expect(complete.isComplete,true);expect(complete.percent,100);expect(complete.next,isNull);
    data['languages']='[]';
    expect(CoachProfileCompletion(data,1,1).next!.message,contains('languages'));
    expect(CoachProfileCompletion(data,1,1).percent,lessThan(100));
    data['languages']=['English'];data['gymAddress']='   ';
    expect(CoachProfileCompletion(data,1,1).next!.message,contains('gym address'));
  });
}
