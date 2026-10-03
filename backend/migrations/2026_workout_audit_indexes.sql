CREATE INDEX idx_workout_session_history ON workout_sessions (clientID, status, startedAt, id);
CREATE INDEX idx_workout_set_exercise_session ON workout_sets (exerciseID, workoutSessionID, workoutExerciseID, setNumber);
CREATE INDEX idx_workout_coach_client ON workout_plans (coachID, clientID, status);
