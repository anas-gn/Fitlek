CREATE TABLE IF NOT EXISTS premium_exercises (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(160) NOT NULL,
  description TEXT NULL,
  muscleGroup VARCHAR(100) NULL,
  equipment VARCHAR(100) NULL,
  exerciseType ENUM('reps', 'timed', 'cardio') NOT NULL DEFAULT 'reps',
  isBodyweight TINYINT(1) NOT NULL DEFAULT 0,
  imageUrl VARCHAR(500) NULL,
  videoUrl VARCHAR(500) NULL,
  createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_premium_exercise_name (name),
  KEY idx_premium_exercise_muscle (muscleGroup)
);

CREATE TABLE IF NOT EXISTS premium_routines (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  userID BIGINT UNSIGNED NOT NULL,
  name VARCHAR(160) NOT NULL,
  description TEXT NULL,
  createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_premium_routine_user (userID),
  CONSTRAINT fk_premium_routine_user FOREIGN KEY (userID) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS premium_routine_exercises (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  routineID BIGINT UNSIGNED NOT NULL,
  exerciseID BIGINT UNSIGNED NOT NULL,
  sortOrder INT NOT NULL DEFAULT 0,
  targetSets INT NOT NULL DEFAULT 3,
  targetReps INT NULL,
  targetDurationSeconds INT NULL,
  restSeconds INT NOT NULL DEFAULT 90,
  supersetGroup VARCHAR(64) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_premium_routine_exercise (routineID, exerciseID, sortOrder),
  CONSTRAINT fk_premium_routine_exercise_routine FOREIGN KEY (routineID) REFERENCES premium_routines(id) ON DELETE CASCADE,
  CONSTRAINT fk_premium_routine_exercise_exercise FOREIGN KEY (exerciseID) REFERENCES premium_exercises(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS premium_workout_sessions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  userID BIGINT UNSIGNED NOT NULL,
  routineID BIGINT UNSIGNED NULL,
  status ENUM('active', 'completed', 'cancelled') NOT NULL DEFAULT 'active',
  startedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completedAt DATETIME NULL,
  PRIMARY KEY (id),
  KEY idx_premium_session_user_date (userID, startedAt),
  CONSTRAINT fk_premium_session_user FOREIGN KEY (userID) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_premium_session_routine FOREIGN KEY (routineID) REFERENCES premium_routines(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS premium_workout_sets (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  sessionID BIGINT UNSIGNED NOT NULL,
  exerciseID BIGINT UNSIGNED NOT NULL,
  setNumber INT NOT NULL,
  weight DECIMAL(8,2) NULL,
  reps INT NULL,
  durationSeconds INT NULL,
  createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_premium_session_exercise_set (sessionID, exerciseID, setNumber),
  CONSTRAINT fk_premium_set_session FOREIGN KEY (sessionID) REFERENCES premium_workout_sessions(id) ON DELETE CASCADE,
  CONSTRAINT fk_premium_set_exercise FOREIGN KEY (exerciseID) REFERENCES premium_exercises(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS premium_body_weights (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  userID BIGINT UNSIGNED NOT NULL,
  weight DECIMAL(8,2) NOT NULL,
  unit ENUM('kg', 'lb') NOT NULL DEFAULT 'kg',
  recordedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_premium_weight_user_date (userID, recordedAt),
  CONSTRAINT fk_premium_weight_user FOREIGN KEY (userID) REFERENCES users(id) ON DELETE CASCADE
);
