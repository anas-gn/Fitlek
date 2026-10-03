int workoutInt(dynamic value) => int.tryParse('$value') ?? 0;
double? workoutNumber(dynamic value) =>
    value == null ? null : double.tryParse('$value');
List<Map<String, dynamic>> workoutRows(dynamic value) => value is List
    ? value.map((e) => Map<String, dynamic>.from(e as Map)).toList()
    : [];

class Exercise {
  final int id;
  final int? ownerID;
  final String name, muscleGroup, equipment, type;
  final bool isBodyweight, favorite;
  final String personalNotes;
  final String? description, imageUrl, videoUrl;
  final List<String> instructions, secondaryMuscles;
  const Exercise(
      {required this.id,
      this.ownerID,
      required this.name,
      required this.muscleGroup,
      required this.equipment,
      required this.type,
      required this.isBodyweight,
      this.favorite = false,
      this.personalNotes = '',
      this.description,
      this.imageUrl,
      this.videoUrl,
      this.instructions = const [],
      this.secondaryMuscles = const []});
  bool get isTimed => type != 'reps';
  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
      id: workoutInt(j['exerciseID'] ?? j['id']),
      ownerID: j['ownerID'] == null ? null : workoutInt(j['ownerID']),
      name: j['name'] ?? '',
      muscleGroup: j['muscleGroup'] ?? '',
      equipment: j['equipment'] ?? '',
      type: j['exerciseType'] ?? 'reps',
      isBodyweight: j['isBodyweight'] == true || j['isBodyweight'] == 1,
      favorite: j['favorite'] == true || j['favorite'] == 1,
      personalNotes: j['personalNotes'] ?? '',
      description: j['description'],
      imageUrl: j['imageUrl'],
      videoUrl: j['videoUrl'],
      instructions:
          (j['instructions'] as List? ?? []).map((e) => '$e').toList(),
      secondaryMuscles:
          (j['secondaryMuscles'] as List? ?? []).map((e) => '$e').toList());
}

class WorkoutExercise {
  final int id;
  final Exercise exercise;
  int sets, restSeconds;
  int? reps, durationSeconds;
  double? weight;
  String notes, supersetGroup;
  Map<String, dynamic> configuration;
  bool get supportsLoad => exercise.type != 'cardio';
  bool get hasPrescribedLoad =>
      supportsLoad && (!exercise.isBodyweight || (weight ?? 0) > 0);
  final Map<String, dynamic> recommendation;
  WorkoutExercise(
      {this.id = 0,
      required this.exercise,
      this.sets = 3,
      this.reps,
      this.durationSeconds,
      this.weight,
      this.restSeconds = 90,
      this.notes = '',
      this.supersetGroup = '',
      Map<String, dynamic>? configuration,
      this.recommendation = const {}})
      : configuration = configuration ?? {};
  factory WorkoutExercise.fromJson(Map<String, dynamic> j) => WorkoutExercise(
      id: workoutInt(j['id']),
      exercise: Exercise.fromJson(j),
      sets: workoutInt(j['targetSets']),
      reps: j['targetReps'] == null ? null : workoutInt(j['targetReps']),
      durationSeconds: j['targetDurationSeconds'] == null
          ? null
          : workoutInt(j['targetDurationSeconds']),
      weight: workoutNumber(j['targetWeight']),
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
  final int id;
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
  final int? reps, durationSeconds, rir;
  final double? weight, rpe;
  final Map<String, dynamic> details;
  WorkoutSet.fromJson(Map<String, dynamic> j)
      : id = workoutInt(j['id']),
        workoutExerciseID = workoutInt(j['workoutExerciseID']),
        setNumber = workoutInt(j['setNumber']),
        reps = j['reps'] == null ? null : workoutInt(j['reps']),
        durationSeconds = j['durationSeconds'] == null
            ? null
            : workoutInt(j['durationSeconds']),
        rir = j['rir'] == null ? null : workoutInt(j['rir']),
        weight = workoutNumber(j['weight']),
        rpe = workoutNumber(j['rpe']),
        details = Map<String, dynamic>.from(j['details'] ?? {});
  bool get isWarmup => details['phase'] == 'warmup';
  Map<String, dynamic> toJson() => {
        'id': id,
        'workoutExerciseID': workoutExerciseID,
        'setNumber': setNumber,
        'reps': reps,
        'weight': weight,
        'durationSeconds': durationSeconds,
        'rpe': rpe,
        'rir': rir,
        'details': details
      };
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
