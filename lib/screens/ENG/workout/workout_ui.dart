import 'package:flutter/material.dart';
import '../../../services/apiService.dart';
import '../../../services/workout_service.dart';
import '../login.dart';
import '../../../localization/workout_localizations.dart';
export '../../../localization/workout_localizations.dart';

// Scoped to Workout. SIRVYA's other screens retain their existing design.
ThemeData workoutTheme(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final surface = dark ? const Color(0xff1d1d20) : Colors.white;
  final background = dark ? const Color(0xff080809) : const Color(0xfff3f3f8);
  final accent = dark ? const Color(0xff42d46b) : const Color(0xff248a3d);
  final scheme = ColorScheme.fromSeed(
          seedColor: accent,
          brightness: dark ? Brightness.dark : Brightness.light)
      .copyWith(
          primary: accent,
          surface: surface,
          onPrimary: dark ? Colors.black : Colors.white);
  return ThemeData(
      fontFamily: 'SirvyaWorkout',
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: ThemeData(brightness: scheme.brightness).textTheme.copyWith(
          headlineLarge: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
              color: scheme.onSurface),
          titleLarge: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
              color: scheme.onSurface),
          titleMedium: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface),
          bodyLarge: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: scheme.onSurface)),
      appBarTheme: AppBarTheme(
          backgroundColor: background,
          foregroundColor: scheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
              fontFamily: 'SirvyaWorkout',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface)),
      cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      dividerTheme: DividerThemeData(
          color: scheme.onSurface.withValues(alpha: 0.14), thickness: 0.5),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: dark ? const Color(0xff2b2b2e) : const Color(0xffececf0),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none)),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: scheme.onPrimary,
              elevation: 0,
              minimumSize: const Size(44, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)))),
      dialogTheme: DialogThemeData(
          backgroundColor: surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
      bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: surface,
          showDragHandle: true,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
      chipTheme: ChipThemeData(
          side: BorderSide.none,
          backgroundColor: scheme.primary.withValues(alpha: 0.12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
}

class WorkoutScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body, bottomNavigationBar, floatingActionButton;
  const WorkoutScaffold(
      {super.key,
      this.appBar,
      this.body,
      this.bottomNavigationBar,
      this.floatingActionButton});
  @override
  Widget build(BuildContext context) => Theme(
      data: workoutTheme(context),
      child: Builder(
          builder: (context) => Scaffold(
              appBar: appBar,
              body: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: body)),
              bottomNavigationBar: bottomNavigationBar,
              floatingActionButton: floatingActionButton)));
}

class WorkoutScope extends StatelessWidget {
  final WidgetBuilder builder;
  const WorkoutScope({super.key, required this.builder});
  @override
  Widget build(BuildContext context) =>
      Theme(data: workoutTheme(context), child: Builder(builder: builder));
}

class WorkoutRoute<T> extends MaterialPageRoute<T> {
  WorkoutRoute({required WidgetBuilder builder})
      : super(builder: (context) => WorkoutScope(builder: builder));
}

Future<T?> workoutDialog<T>(
        {required BuildContext context, required WidgetBuilder builder}) =>
    showDialog<T>(
        context: context, builder: (context) => WorkoutScope(builder: builder));
Future<T?> workoutSheet<T>(
        {required BuildContext context,
        required WidgetBuilder builder,
        bool isScrollControlled = false}) =>
    showModalBottomSheet<T>(
        context: context,
        isScrollControlled: isScrollControlled,
        builder: (context) => WorkoutScope(builder: builder));

class WorkoutMetric extends StatelessWidget {
  final String value, label;
  const WorkoutMetric(this.value, this.label, {super.key});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        WorkoutLabel(value,
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5)),
        const SizedBox(height: 4),
        WorkoutLabel(label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant))
      ]);
}

class WorkoutOfflineNotice extends StatelessWidget {
  const WorkoutOfflineNotice({super.key});
  @override
  Widget build(BuildContext context) => const Card(
      child: ListTile(
          leading: Icon(Icons.cloud_off_rounded),
          title: WorkoutLabel('Offline — showing saved data'),
          subtitle: WorkoutLabel(
              'Reconnect to refresh. Workout sets stay on this device until synced.')));
}

// Labels share SIRVYA's English/French/Spanish locale and language preference.
class WorkoutText {
  static const title = 'Workout';
  static const library = 'Exercise library';
  static const history = 'Workout history';
  static const progress = 'Progress';
  static const retry = 'Try again';
  static const cancel = 'Cancel';
  static const save = 'Save';
  static const complete = 'Complete';
  static const start = 'Start workout';
  static const resume = 'Resume workout';
  static const noPlans =
      'No workout plans yet. Your coach can assign your first plan.';
  static const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  static String error(Object e) {
    if (e is! WorkoutApiException) {
      return 'Unable to load Workout. Please try again.';
    }
    if (e.status == 0) {
      return 'Check your connection and try again. Your saved sets are safe.';
    }
    if (e.status == 401) {
      return 'Your session has expired. Please sign in again.';
    }
    if (e.status == 403) {
      return 'You do not have access to this workout or client.';
    }
    return const {
          'exercise_in_use':
              'This exercise is used in a routine or workout. Keep its measurement type or create a new exercise.',
          'workout_not_found': 'This workout is no longer available.',
          'exercise_not_found': 'This exercise is no longer available.',
          'active_workout_exists':
              'Resume or cancel your active workout before starting another.',
          'plan_changed':
              'This plan changed. Reopen it before saving your edits.',
          'workout_closed': 'This workout has already ended.',
          'invalid_set': 'Enter repetitions or duration and a valid weight.',
          'pending_sets': 'Sync your pending sets before changing the workout.',
          'recorded_exercise':
              'Undo the recorded sets before removing or swapping this exercise.',
          'session_changed':
              'This workout changed on another device. Reopen it before saving.',
          'invalid_effort': 'Use one effort scale: RPE or RIR.',
          'invalid_import': 'The history file contains invalid data.',
          'invalid_import_date':
              'Check the dates and time zone in the history file.',
          'unsupported_import':
              'Choose a Strong, Hevy, FitNotes CSV or SIRVYA JSON file.',
          'unmapped_exercise':
              'Match every exercise or allow private custom exercises.',
          'invalid_media':
              'Choose a valid image or MP4 video within the upload limit.',
          'too_many_media': 'Remove an attachment before adding another.',
          'invalid_target':
              'Repetition exercises need reps. Timed exercises need duration.',
          'invalid_superset': 'Keep exercises in each superset together.',
          'empty_plan':
              'Add at least one exercise to each day before assigning.',
          'invalid_workout': 'Check the workout fields and try again.',
          'incomplete_workout': 'Some sets are incomplete.',
          'workout_unavailable':
              'Workout is temporarily unavailable. Please try again.',
        }[e.code] ??
        'Unable to save or load Workout. Please try again.';
  }
}

void workoutError(BuildContext context, Object error) =>
    ApiService.showError(context, WorkoutText.error(error).workoutTr(context));

class WorkoutFailure extends StatelessWidget {
  final Object error;
  final VoidCallback retry;
  const WorkoutFailure({super.key, required this.error, required this.retry});
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline_rounded, size: 36),
            const SizedBox(height: 12),
            WorkoutLabel(WorkoutText.error(error), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: retry, child: const WorkoutLabel(WorkoutText.retry)),
            if (error is WorkoutApiException &&
                (error as WorkoutApiException).status == 401)
              TextButton(
                  onPressed: () async {
                    await ApiService.clearToken();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false);
                  },
                  child: const WorkoutLabel('Sign in again'))
          ])));
}

String workoutDate(dynamic value) {
  final d = DateTime.tryParse('$value')?.toLocal();
  return d == null
      ? ''
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

String workoutValue(num? value) =>
    value == null ? '—' : value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
String workoutClock(int seconds) =>
    '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
