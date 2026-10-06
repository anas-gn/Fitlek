int workoutInt(dynamic value) => int.tryParse('$value') ?? 0;
double? workoutNumber(dynamic value) =>
    value == null ? null : double.tryParse('$value');
List<Map<String, dynamic>> workoutRows(dynamic value) => value is List
    ? value.map((e) => Map<String, dynamic>.from(e as Map)).toList()
    : [];

class Exercise {
  final int id;
  final int? ownerID;
  final double bestWeight;
  final int usageCount;
  final String name, muscleGroup, equipment, type, bodyPart;
  final bool isBodyweight, favorite;
  final String personalNotes;
  final String? description, imageUrl, videoUrl, externalSource, externalId;
  final List<String> instructions, secondaryMuscles;
  const Exercise(
      {required this.id,
      this.ownerID,
      this.bestWeight = 0,
      this.usageCount = 0,
      required this.name,
      required this.muscleGroup,
      required this.equipment,
      required this.type,
      this.bodyPart = '',
      required this.isBodyweight,
      this.favorite = false,
      this.personalNotes = '',
      this.description,
      this.imageUrl,
      this.videoUrl,
      this.externalSource,
      this.externalId,
      this.instructions = const [],
      this.secondaryMuscles = const []});
  Exercise copyWith({String? type, bool? isBodyweight}) => Exercise(
      id: id,
      ownerID: ownerID,
      name: name,
      muscleGroup: muscleGroup,
      bodyPart: bodyPart,
      equipment: equipment,
      type: type ?? this.type,
      isBodyweight: isBodyweight ?? this.isBodyweight,
      favorite: favorite,
      bestWeight: bestWeight,
      usageCount: usageCount,
      personalNotes: personalNotes,
      description: description,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      externalSource: externalSource,
      externalId: externalId,
      instructions: instructions,
      secondaryMuscles: secondaryMuscles);
  bool get isTimed => type != 'reps';
  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
      id: workoutInt(j['exerciseID'] ?? j['id']),
      bestWeight: workoutNumber(j['bestWeight']) ?? 0,
      usageCount: workoutInt(j['usageCount']),
      ownerID: j['ownerID'] == null ? null : workoutInt(j['ownerID']),
      name: j['name'] ?? '',
      muscleGroup: j['muscleGroup'] ?? '',
      equipment: j['equipment'] ?? '',
      bodyPart: j['bodyPart'] ?? j['muscleGroup'] ?? '',
      type: j['exerciseType'] ?? 'reps',
      isBodyweight: j['isBodyweight'] == true || j['isBodyweight'] == 1,
      favorite: j['favorite'] == true || j['favorite'] == 1,
      personalNotes: j['personalNotes'] ?? '',
      description: j['description'],
      imageUrl: j['imageUrl'],
      videoUrl: j['videoUrl'],
      externalSource: j['externalSource'],
      externalId: j['externalId'],
      instructions:
          (j['instructions'] as List? ?? []).map((e) => '$e').toList(),
      secondaryMuscles:
          (j['secondaryMuscles'] as List? ?? []).map((e) => '$e').toList());
}

class WorkoutExercise {
  int id;
  final Exercise exercise;
  int sets, restSeconds;
  int? reps, durationSeconds;
  double? weight;
  final double? workingWeight;
  String notes, supersetGroup;
  Map<String, dynamic> configuration;
  bool get supportsLoad => exercise.type != 'cardio';
  bool get hasPrescribedLoad =>
      supportsLoad && (!exercise.isBodyweight || (weight ?? 0) > 0);
  final Map<String, dynamic> recommendation;
  WorkoutExercise(
      {this.id = 0,
      required Exercise exercise,
      this.sets = 3,
      this.reps,
      this.durationSeconds,
      this.weight,
      this.workingWeight,
      this.restSeconds = 90,
      this.notes = '',
      this.supersetGroup = '',
      Map<String, dynamic>? configuration,
      this.recommendation = const {}})
      : exercise = exercise.copyWith(
            type: configuration?['mode'] as String?,
            isBodyweight: configuration?['bodyweight'] as bool?),
        configuration = configuration ?? {};
  factory WorkoutExercise.fromJson(Map<String, dynamic> j) => WorkoutExercise(
      id: workoutInt(j['id']),
      exercise: Exercise.fromJson(j),
      sets: workoutInt(j['targetSets']),
      reps: j['targetReps'] == null ? null : workoutInt(j['targetReps']),
      durationSeconds: j['targetDurationSeconds'] == null
          ? null
          : workoutInt(j['targetDurationSeconds']),
      weight: workoutNumber(j['targetWeight']),
      workingWeight: workoutNumber(j['workingWeight']),
      restSeconds: workoutInt(j['restSeconds']),
      notes: j['notes'] ?? '',
      supersetGroup: j['supersetGroup'] ?? '',
      configuration: Map<String, dynamic>.from(j['configuration'] ?? {}),
      recommendation: Map<String, dynamic>.from(j['recommendation'] ?? {}));
  Map<String, dynamic> toJson() => {
        if (id > 0) 'id': id,
        'exerciseID': exercise.id,
        'targetSets': sets,
        'targetReps': reps,
        'targetWeight': weight,
        'targetDurationSeconds': durationSeconds,
        'restSeconds': restSeconds,
        'notes': notes,
        'supersetGroup': supersetGroup,
        'configuration': configuration
      };
}

class WorkoutDay {
  int id;
  String name;
  int? dayOfWeek;
  List<WorkoutExercise> exercises;
  Map<String, dynamic> configuration;
  WorkoutDay(
      {this.id = 0,
      required this.name,
      this.dayOfWeek,
      Map<String, dynamic>? configuration,
      List<WorkoutExercise>? exercises})
      : configuration = configuration ?? {},
        exercises = exercises ?? [];
  factory WorkoutDay.fromJson(Map<String, dynamic> j) => WorkoutDay(
      id: workoutInt(j['id']),
      name: j['name'] ?? '',
      dayOfWeek: j['dayOfWeek'] == null ? null : workoutInt(j['dayOfWeek']),
      configuration: Map<String, dynamic>.from(j['configuration'] ?? {}),
      exercises:
          workoutRows(j['exercises']).map(WorkoutExercise.fromJson).toList());
  Map<String, dynamic> toJson() => {
        if (id > 0) 'id': id,
        'name': name,
        'dayOfWeek': dayOfWeek,
        'configuration': configuration,
        'exercises': exercises.map((e) => e.toJson()).toList()
      };
}

class WorkoutPlan {
  final int id, clientID, coachID, revision;
  final String name, description, status, clientName;
  final List<WorkoutDay> days;
  WorkoutPlan.fromJson(Map<String, dynamic> j)
      : id = workoutInt(j['id']),
        clientID = workoutInt(j['clientID']),
        coachID = workoutInt(j['coachID']),
        revision = workoutInt(j['revision']),
        name = j['name'] ?? '',
        description = j['description'] ?? '',
        status = j['status'] ?? 'draft',
        clientName = '${j['firstName'] ?? ''} ${j['lastName'] ?? ''}'.trim(),
        days = workoutRows(j['days']).map(WorkoutDay.fromJson).toList();
}

class WorkoutSet {
  final int id, workoutExerciseID, setNumber;
  final String? exerciseType;
  final DateTime? performedAt;
  final int? reps, durationSeconds;
  final double? weight, rpe, rir;
  final Map<String, dynamic> details;
  WorkoutSet.fromJson(Map<String, dynamic> j)
      : id = workoutInt(j['id']),
        workoutExerciseID = workoutInt(j['workoutExerciseID']),
        setNumber = workoutInt(j['setNumber']),
        exerciseType = j['exerciseType'] as String?,
        performedAt =
            DateTime.tryParse('${j['startedAt'] ?? j['completedAt']}'),
        reps = j['reps'] == null ? null : workoutInt(j['reps']),
        durationSeconds = j['durationSeconds'] == null
            ? null
            : workoutInt(j['durationSeconds']),
        rir = workoutNumber(j['rir']),
        weight = workoutNumber(j['weight']),
        rpe = workoutNumber(j['rpe']),
        details = Map<String, dynamic>.from(j['details'] ?? {});
  bool get isWarmup => details['phase'] == 'warmup';
  Map<String, dynamic> toJson() => {
        'id': id,
        'workoutExerciseID': workoutExerciseID,
        'setNumber': setNumber,
        if (exerciseType != null) 'exerciseType': exerciseType,
        'reps': reps,
        'weight': weight,
        'durationSeconds': durationSeconds,
        'rpe': rpe,
        'rir': rir,
        'details': details
      };
}

WorkoutSet? workoutPreviousSet(
    WorkoutExercise exercise, List<WorkoutSet> rows, int number) {
  var eligible = rows
      .where((s) =>
          !s.isWarmup &&
          (s.exerciseType == null ||
              s.exerciseType == exercise.exercise.type) &&
          (exercise.exercise.isTimed
              ? (s.durationSeconds ?? 0) > 0
              : (s.reps ?? 0) > 0))
      .toList();
  final slot =
      eligible.where((s) => s.workoutExerciseID == exercise.id).toList();
  if (slot.isNotEmpty) {
    eligible = slot;
  } else if (eligible.isNotEmpty) {
    final firstSlot = eligible.first.workoutExerciseID;
    eligible = eligible.where((s) => s.workoutExerciseID == firstSlot).toList();
  }
  eligible.sort((a, b) => a.setNumber.compareTo(b.setNumber));
  return eligible.isEmpty
      ? null
      : eligible[(number - 1).clamp(0, eligible.length - 1)];
}

// Last performed values seed the row; only fields decided by a progression
// rule replace them. Coach prescriptions remain separate immutable targets.
class WorkoutSetPrefill {
  final double weight;
  final int reps, seconds;
  WorkoutSetPrefill(WorkoutExercise exercise,
      {WorkoutSet? saved, WorkoutSet? previous})
      : weight = saved?.weight ??
            (_progresses(exercise) &&
                    (exercise.recommendation['policy'] != 'time')
                ? exercise.weight ?? 0
                : (exercise.workingWeight ?? 0) > 0
                    ? exercise.workingWeight!
                    : previous?.weight ?? exercise.weight ?? 0),
        reps = saved?.reps ??
            (_progresses(exercise) &&
                    (exercise.recommendation['policy'] == 'double' ||
                        [
                          'increase_reps',
                          'increase_sets',
                          'add_load_or_variation'
                        ].contains(exercise.recommendation['reason']))
                ? exercise.reps ?? 10
                : previous?.reps ?? exercise.reps ?? 10),
        seconds = saved?.durationSeconds ??
            (_progresses(exercise) &&
                    exercise.recommendation['policy'] == 'time'
                ? exercise.durationSeconds ?? 45
                : previous?.durationSeconds ?? exercise.durationSeconds ?? 45);
  static bool _progresses(WorkoutExercise exercise) =>
      exercise.recommendation['policy'] != null &&
      exercise.recommendation['policy'] != 'off' &&
      !['first_session', 'prescribed']
          .contains(exercise.recommendation['reason']);
}

class WorkoutSession {
  final bool historical;
  final bool offline;
  final int id, revision;
  final String notes;
  final String status, planName, dayName;
  final DateTime startedAt;
  final List<WorkoutExercise> exercises;
  final List<WorkoutSet> sets;
  final Map<int, List<WorkoutSet>> previous;
  WorkoutSession.fromJson(Map<String, dynamic> j)
      : historical = j['prescription']['historical'] == true,
        offline = j['offline'] == true,
        id = workoutInt(j['id']),
        revision = workoutInt(j['revision'] ?? 1),
        notes = j['notes'] ?? '',
        status = j['status'] ?? 'active',
        startedAt = DateTime.parse(j['startedAt']),
        planName = j['prescription']['planName'] ?? '',
        dayName = j['prescription']['dayName'] ?? '',
        exercises = workoutRows(j['prescription']['exercises'])
            .map(WorkoutExercise.fromJson)
            .toList(),
        sets = workoutRows(j['sets']).map(WorkoutSet.fromJson).toList(),
        previous = (j['previous'] as Map? ?? {}).map((k, v) => MapEntry(
            workoutInt(k), workoutRows(v).map(WorkoutSet.fromJson).toList()));
}

List<WorkoutExercise> moveWorkoutGroup(
    List<WorkoutExercise> exercises, int index, int offset) {
  final groups = <List<WorkoutExercise>>[];
  for (final e in exercises) {
    if (e.supersetGroup.isNotEmpty &&
        groups.isNotEmpty &&
        groups.last.last.supersetGroup == e.supersetGroup) {
      groups.last.add(e);
    } else {
      groups.add([e]);
    }
  }
  final current = groups.indexWhere((g) => g.contains(exercises[index])),
      next = current + offset;
  if (next < 0 || next >= groups.length) return [...exercises];
  final group = groups.removeAt(current);
  groups.insert(next, group);
  return groups.expand((g) => g).toList();
}

List<List<WorkoutExercise>> workoutExerciseGroups(
    List<WorkoutExercise> exercises) {
  final groups = <List<WorkoutExercise>>[];
  for (final exercise in exercises) {
    if (exercise.supersetGroup.isNotEmpty &&
        groups.isNotEmpty &&
        groups.last.last.supersetGroup == exercise.supersetGroup) {
      groups.last.add(exercise);
    } else {
      groups.add([exercise]);
    }
  }
  return groups;
}

void moveWorkoutExercise(
    List<WorkoutExercise> exercises, int index, int offset) {
  final target = index + offset;
  if (index < 0 ||
      index >= exercises.length ||
      target < 0 ||
      target >= exercises.length) {
    return;
  }
  final selected = exercises[index];
  exercises[index] = exercises[target];
  exercises[target] = selected;
  cleanupWorkoutSupersets(exercises);
}

void cleanupWorkoutSupersets(List<WorkoutExercise> exercises) {
  for (final group in workoutExerciseGroups(exercises)) {
    if (group.length == 1) group.first.supersetGroup = '';
  }
}
