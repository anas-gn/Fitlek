import 'dart:convert';

class ProfileCompletionStep {
  final String message, section;
  final bool filled;
  const ProfileCompletionStep(this.message, this.section, this.filled);
}

class CoachProfileCompletion {
  final List<ProfileCompletionStep> steps = [];
  CoachProfileCompletion(Map<String, dynamic> data, int photos, int packages) {
    bool filled(String key) {
      final value = data[key];
      if (value == null) return false;
      if (value is List)
        return value.any((e) => e != null && e.toString().trim().isNotEmpty);
      final text = value.toString().trim();
      if (text.startsWith('[')) {
        try {
          return (jsonDecode(text) as List).isNotEmpty;
        } catch (_) {
          return false;
        }
      }
      return text.isNotEmpty;
    }

    void add(String key, String label, String section) =>
        steps.add(ProfileCompletionStep(
            'Add $label to your profile.', section, filled(key)));
    add('avatarUrl', 'a profile photo', 'about');
    add('firstName', 'your first name', 'about');
    add('lastName', 'your last name', 'about');
    add('email', 'your email', 'account');
    add('tel', 'your phone number', 'account');
    add('gender', 'your gender', 'about');
    add('professionalTitle', 'your professional title', 'about');
    add('bio', 'your biography', 'about');
    add('languages', 'your languages', 'about');
    add('instagramPage', 'your Instagram page', 'about');
    add('specialties', 'your specialties', 'expertise');
    add('experience', 'your experience', 'expertise');
    add('clientLevels', 'the client levels you coach', 'expertise');
    add('certifications', 'a certification', 'expertise');
    add('ville', 'your city', 'locations');
    add('coachingFormats', 'your coaching formats', 'locations');
    add('serviceArea', 'your service area', 'locations');
    add('gymName', 'your gym name', 'locations');
    add('gymAddress', 'your gym address', 'locations');
    add('gymImage', 'a gym photo', 'locations');
    steps.add(ProfileCompletionStep(
        'Add a coaching package.', 'packages', packages > 0));
    steps.add(ProfileCompletionStep(
        'Add a photo to your coaching gallery.', 'photos', photos > 0));
  }
  bool get isComplete => steps.every((step) => step.filled);
  int get percent => isComplete
      ? 100
      : (steps.where((step) => step.filled).length * 100 / steps.length)
          .floor();
  ProfileCompletionStep? get next =>
      steps.where((step) => !step.filled).firstOrNull;
}
