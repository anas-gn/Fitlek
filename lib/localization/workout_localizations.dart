import 'package:flutter/material.dart';
import '../services/locale_service.dart';
import 'workout_strings.dart';

String workoutTranslate(String value, String language, [int depth = 0]) {
  if (language == 'en' || depth > 3) return value;
  final index = language == 'es' ? 1 : 0;
  final exact = workoutStrings[value];
  if (exact != null) return exact[index];
  for (final entry
      in workoutStrings.entries.where((e) => e.key.contains('{0}'))) {
    final ids = <int>[];
    final pattern = StringBuffer('^');
    int start = 0;
    for (final m in RegExp(r'\{(\d+)\}').allMatches(entry.key)) {
      pattern.write(RegExp.escape(entry.key.substring(start, m.start)));
      pattern.write('([\\s\\S]*?)');
      ids.add(int.parse(m.group(1)!));
      start = m.end;
    }
    pattern.write(RegExp.escape(entry.key.substring(start)));
    pattern.write(r'$');
    final match = RegExp(pattern.toString()).firstMatch(value);
    if (match == null) continue;
    var translated = entry.value[index];
    for (var i = 0; i < ids.length; i++) {
      translated = translated.replaceAll('{${ids[i]}}',
          workoutTranslate(match.group(i + 1)!, language, depth + 1));
    }
    return translated;
  }
  return value;
}

extension WorkoutTranslation on String {
  String workoutTr(BuildContext context) => workoutTranslate(
      this,
      Localizations.maybeLocaleOf(context)?.languageCode ??
          LocaleService.instance.locale.languageCode);
}

class WorkoutLabel extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool? softWrap;
  const WorkoutLabel(this.data,
      {super.key,
      this.style,
      this.textAlign,
      this.overflow,
      this.maxLines,
      this.softWrap});
  @override
  Widget build(BuildContext context) => Text(data.workoutTr(context),
      style: style,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      softWrap: softWrap);
}
