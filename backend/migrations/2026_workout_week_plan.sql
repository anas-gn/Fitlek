CREATE TABLE IF NOT EXISTS workout_week_days (
  userID BIGINT UNSIGNED NOT NULL,
  weekday TINYINT UNSIGNED NOT NULL,
  PRIMARY KEY (userID, weekday),
  FOREIGN KEY (userID) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS workout_week_schedule (
  userID BIGINT UNSIGNED NOT NULL,
  weekday TINYINT UNSIGNED NOT NULL,
  workoutDayID BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (userID, weekday, workoutDayID),
  FOREIGN KEY (userID, weekday) REFERENCES workout_week_days(userID, weekday) ON DELETE CASCADE,
  FOREIGN KEY (workoutDayID) REFERENCES workout_days(id) ON DELETE CASCADE
);
