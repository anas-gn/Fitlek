import 'dart:convert';

class ClientProfileStep {
  final String label, section;
  final bool filled;
  const ClientProfileStep(this.label, this.section, this.filled);
}

List<String> clientInterests(dynamic value) {
  if (value is String) {
    try {
      value = jsonDecode(value);
    } catch (_) {
      return [];
    }
  }
  if (value is! List) return [];
  return value
      .whereType<String>()
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet()
      .toList();
}

/// Completion reflects server-confirmed data, never unsaved form input.
class ClientProfileCompletion {
  final List<ClientProfileStep> steps;
  ClientProfileCompletion(Map<String, dynamic> saved)
      : steps = [
          ClientProfileStep('Add your profile photo', 'photo',
              '${saved['avatarUrl'] ?? ''}'.trim().isNotEmpty),
          ClientProfileStep('Add your first name', 'details',
              '${saved['firstName'] ?? ''}'.trim().isNotEmpty),
          ClientProfileStep('Add your last name', 'details',
              '${saved['lastName'] ?? ''}'.trim().isNotEmpty),
          ClientProfileStep('Add your email address', 'email',
              '${saved['email'] ?? ''}'.trim().isNotEmpty),
          ClientProfileStep('Add your phone number', 'phone',
              '${saved['phoneNumber'] ?? ''}'.trim().isNotEmpty),
          ClientProfileStep('Set your city', 'location',
              '${saved['ville'] ?? ''}'.trim().isNotEmpty),
          ClientProfileStep(
              'Add your height', 'details', _hasHeight(saved['height'])),
          ClientProfileStep('Choose your fitness interests', 'interests',
              clientInterests(saved['interests']).isNotEmpty),
        ];
  static bool _hasHeight(dynamic value) {
    final height = double.tryParse('$value');
    return height != null && height.isFinite && height > 0 && height <= 300;
  }

  int get completed => steps.where((s) => s.filled).length;
  double get fraction => completed / steps.length;
  int get percent => (fraction * 100).floor();
  bool get isComplete => completed == steps.length;
  ClientProfileStep? get next => steps.where((s) => !s.filled).firstOrNull;
}
