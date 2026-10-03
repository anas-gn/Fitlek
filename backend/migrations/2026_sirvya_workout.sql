-- Additive SIRVYA Workout schema. Uses the existing database and users.
CREATE TABLE IF NOT EXISTS exercises (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(160) NOT NULL,
  description TEXT NULL,
  muscleGroup VARCHAR(80) NOT NULL,
  secondaryMuscles JSON NULL,
  equipment VARCHAR(80) NOT NULL,
  exerciseType ENUM('reps','timed','cardio') NOT NULL DEFAULT 'reps',
  isBodyweight TINYINT(1) NOT NULL DEFAULT 0,
  isTimed TINYINT(1) NOT NULL DEFAULT 0,
  imageUrl VARCHAR(500) NULL,
  videoUrl VARCHAR(500) NULL,
  instructions JSON NOT NULL,
  externalSource VARCHAR(80) NOT NULL DEFAULT 'sirvya',
  externalId VARCHAR(160) NOT NULL,
  archivedAt DATETIME NULL,
  UNIQUE KEY uq_exercise_source (externalSource, externalId),
  KEY idx_exercise_filter (muscleGroup, equipment, exerciseType)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS workout_plans (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  coachID BIGINT UNSIGNED NOT NULL,
  clientID BIGINT UNSIGNED NOT NULL,
  name VARCHAR(160) NOT NULL,
  description TEXT NULL,
  status ENUM('draft','assigned','archived') NOT NULL DEFAULT 'draft',
  revision INT NOT NULL DEFAULT 1,
  createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_workout_client (clientID, status),
  FOREIGN KEY (coachID) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (clientID) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS workout_days (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  workoutPlanID BIGINT UNSIGNED NOT NULL,
  name VARCHAR(160) NOT NULL,
  dayOfWeek INT NULL,
  sortOrder INT NOT NULL DEFAULT 0,
  FOREIGN KEY (workoutPlanID) REFERENCES workout_plans(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS workout_exercises (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  workoutDayID BIGINT UNSIGNED NOT NULL,
  exerciseID BIGINT UNSIGNED NOT NULL,
  sortOrder INT NOT NULL DEFAULT 0,
  targetSets INT NOT NULL DEFAULT 3,
  targetReps INT NULL,
  targetWeight DECIMAL(8,2) NULL,
  targetDurationSeconds INT NULL,
  restSeconds INT NOT NULL DEFAULT 90,
  notes TEXT NULL,
  supersetGroup VARCHAR(64) NULL,
  FOREIGN KEY (workoutDayID) REFERENCES workout_days(id) ON DELETE CASCADE,
  FOREIGN KEY (exerciseID) REFERENCES exercises(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS workout_sessions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  workoutPlanID BIGINT UNSIGNED NOT NULL,
  workoutDayID BIGINT UNSIGNED NULL,
  clientID BIGINT UNSIGNED NOT NULL,
  -- Immutable prescription (including original workoutExerciseID) for history/edit safety.
  prescription JSON NOT NULL,
  status ENUM('active','completed','cancelled') NOT NULL DEFAULT 'active',
  startedAt DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  completedAt DATETIME(3) NULL,
  durationSeconds INT NULL,
  notes TEXT NULL,
  -- MySQL permits multiple NULLs. Only one active session per client.
  -- Maintained atomically on session start/finish to preserve account deletion cascades.
  activeClientID BIGINT UNSIGNED NULL,
  UNIQUE KEY uq_workout_active_client (activeClientID),
  KEY idx_workout_session_date (clientID, startedAt),
  FOREIGN KEY (workoutPlanID) REFERENCES workout_plans(id) ON DELETE CASCADE,
  FOREIGN KEY (workoutDayID) REFERENCES workout_days(id) ON DELETE SET NULL,
  FOREIGN KEY (clientID) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS workout_sets (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  workoutSessionID BIGINT UNSIGNED NOT NULL,
  -- Snapshot ID, intentionally no FK: prescriptions may subsequently be edited.
  workoutExerciseID BIGINT UNSIGNED NOT NULL,
  exerciseID BIGINT UNSIGNED NOT NULL,
  setNumber INT NOT NULL,
  reps INT NULL,
  weight DECIMAL(8,2) NULL,
  durationSeconds INT NULL,
  rpe DECIMAL(3,1) NULL,
  rir INT NULL,
  completedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_workout_set (workoutSessionID, workoutExerciseID, setNumber),
  FOREIGN KEY (workoutSessionID) REFERENCES workout_sessions(id) ON DELETE CASCADE,
  FOREIGN KEY (exerciseID) REFERENCES exercises(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
