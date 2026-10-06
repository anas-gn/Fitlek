import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../services/apiService.dart';
import '../../../services/workout_service.dart';
import '../login.dart';
import '../../../localization/workout_localizations.dart';
export '../../../localization/workout_localizations.dart';

const workoutRoutineIcons = <String, IconData>{
  'strength': Icons.fitness_center_rounded,
  'cardio': Icons.directions_run_rounded,
  'recovery': Icons.spa_rounded,
  'mobility': Icons.self_improvement_rounded
};

// Scoped to Workout. SIRVYA's other screens retain their existing design.
ThemeData workoutTheme(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final surface = dark ? const Color(0xff1c1c1e) : Colors.white;
  final background = dark ? Colors.black : const Color(0xfff2f2f7);
  final accent = dark ? const Color(0xff30d158) : const Color(0xff34c759);
  final scheme = ColorScheme.fromSeed(
          seedColor: accent,
          brightness: dark ? Brightness.dark : Brightness.light)
      .copyWith(
          primary: accent,
          surface: surface,
          onSurface: dark ? Colors.white : Colors.black,
          onSurfaceVariant:
              dark ? const Color(0xff98989f) : const Color(0xff8e8e93),
          onPrimary: Colors.black);
  return ThemeData(
      fontFamily: 'SirvyaWorkout',
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: ThemeData(brightness: scheme.brightness)
          .textTheme
          .copyWith(
              headlineLarge: TextStyle(
                  fontSize: 34,
                  height: 1.06,
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
                  color: scheme.onSurface))
          .apply(fontFamily: 'SirvyaWorkout'),
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
          backgroundColor: background,
          constraints: const BoxConstraints(maxWidth: 560),
          showDragHandle: true,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)))),
      chipTheme:
          ChipThemeData(side: BorderSide.none, showCheckmark: false, backgroundColor: surface, selectedColor: accent, padding: const EdgeInsets.symmetric(horizontal: 5), labelStyle: TextStyle(fontFamily: 'SirvyaWorkout', fontSize: 14, color: scheme.onSurface), shape: const StadiumBorder()));
}

class WorkoutPageHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool back;
  final double textScale;
  final List<Widget> actions;
  const WorkoutPageHeader(
      {super.key,
      required this.title,
      this.subtitle,
      this.textScale = 1,
      this.back = false,
      this.actions = const []});

  @override
  Size get preferredSize =>
      Size.fromHeight(76 * textScale.clamp(1, 3) + (textScale > 1 ? 8 : 0));

  @override
  Widget build(BuildContext context) => SizedBox(
      height: preferredSize.height + MediaQuery.paddingOf(context).top,
      child: SafeArea(
          bottom: false,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                if (back) ...[
                  IconButton.filledTonal(
                      tooltip:
                          MaterialLocalizations.of(context).backButtonTooltip,
                      style: IconButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.surface),
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.chevron_left, size: 22)),
                  const SizedBox(width: 12),
                ],
                Expanded(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      WorkoutLabel(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 34,
                              height: 1.06,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -.9)),
                      if (subtitle != null)
                        WorkoutLabel(subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 15,
                                height: 1.2,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                    ])),
                ...actions,
              ]))));
}

class WorkoutSegments<T extends Object> extends StatelessWidget {
  final T selected;
  final Map<T, String> choices;
  final ValueChanged<T> onChanged;
  const WorkoutSegments(
      {super.key,
      required this.selected,
      required this.choices,
      required this.onChanged});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<T>(
          groupValue: selected,
          backgroundColor:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: .08),
          thumbColor: Theme.of(context).colorScheme.surface,
          children: {
            for (final entry in choices.entries)
              entry.key: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: WorkoutLabel(entry.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected == entry.key
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: selected == entry.key
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)))
          },
          onValueChanged: (value) {
            if (value != null) onChanged(value);
          }));
}

class WorkoutScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body, bottomNavigationBar, floatingActionButton;
  final double maxWidth;
  const WorkoutScaffold(
      {super.key,
      this.appBar,
      this.body,
      this.bottomNavigationBar,
      this.maxWidth = 640,
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
                      constraints: BoxConstraints(maxWidth: maxWidth),
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
  WorkoutRoute({required WidgetBuilder builder, super.settings})
      : super(builder: (context) => WorkoutScope(builder: builder));
}

Future<T?> workoutDialog<T>(
    {required BuildContext context, required WidgetBuilder builder}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = DialogRoute<T>(
      context: context,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      builder: (context) => WorkoutScope(builder: builder));
  final result = await navigator.push(route);
  // Editors may release their controllers once the closing route is disposed.
  await route.completed;
  return result;
}

Future<T?> workoutSheet<T>(
    {required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = false}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = ModalBottomSheetRoute<T>(
      builder: (context) => WorkoutScope(builder: builder),
      capturedThemes:
          InheritedTheme.capture(from: context, to: navigator.context),
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      isScrollControlled: isScrollControlled,
      useSafeArea: true);
  final result = await navigator.push(route);
  await route.completed;
  return result;
}

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

class WorkoutMetricGrid extends StatelessWidget {
  final Map<String, String> metrics;
  final Map<String, Color> valueColors;
  const WorkoutMetricGrid(
      {super.key, required this.metrics, this.valueColors = const {}});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, size) => GridView.count(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: size.maxWidth >= 800 ? 4 : 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          mainAxisExtent: 78 *
              (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1, 2),
          children: metrics.entries
              .map((m) => Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(
                                  const {
                                    'Workouts': Icons.fitness_center,
                                    'This month': Icons.calendar_today_outlined,
                                    'Week streak':
                                        Icons.local_fire_department_outlined,
                                    'Weight 30d': Icons.monitor_weight_outlined
                                  }[m.key],
                                  size: 13,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                              const SizedBox(width: 5),
                              Expanded(
                                  child: WorkoutLabel(m.key,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 13,
                                          height: 1.2,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant))),
                            ]),
                            const SizedBox(height: 4),
                            Expanded(
                                child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.bottomLeft,
                                    child: WorkoutLabel(m.value,
                                        style: TextStyle(
                                            fontSize: 24,
                                            height: 1.1,
                                            color: valueColors[m.key],
                                            fontWeight: FontWeight.w600))))
                          ]))))
              .toList()));
}

class WorkoutColumns extends StatelessWidget {
  final Widget first, second;
  const WorkoutColumns({super.key, required this.first, required this.second});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, size) => size.maxWidth < 800
          ? Column(children: [first, second])
          : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: first),
              const SizedBox(width: 16),
              Expanded(child: second)
            ]));
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
          'exercise_name_exists':
              'An exercise with this name already exists. Choose it from the library or use a different name.',
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

String workoutExerciseTitle(String value) =>
    value.replaceAllMapped(RegExp(r'(^|\s)[a-z]'), (m) => m[0]!.toUpperCase());
