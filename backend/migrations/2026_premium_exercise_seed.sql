INSERT INTO premium_exercises
  (name, description, muscleGroup, equipment, exerciseType, isBodyweight)
SELECT * FROM (
  SELECT 'Push-up', 'Keep your body straight and lower under control.', 'Chest', 'Bodyweight', 'reps', 1
  UNION ALL SELECT 'Bodyweight Squat', 'Lower until your thighs are near parallel, then stand tall.', 'Legs', 'Bodyweight', 'reps', 1
  UNION ALL SELECT 'Pull-up', 'Pull your chest toward the bar without swinging.', 'Back', 'Pull-up bar', 'reps', 1
  UNION ALL SELECT 'Dumbbell Bench Press', 'Press dumbbells upward while keeping your shoulders stable.', 'Chest', 'Dumbbells', 'reps', 0
  UNION ALL SELECT 'Goblet Squat', 'Hold one dumbbell at your chest and squat with a tall torso.', 'Legs', 'Dumbbell', 'reps', 0
  UNION ALL SELECT 'Dumbbell Row', 'Pull the dumbbell toward your hip while bracing your back.', 'Back', 'Dumbbell', 'reps', 0
  UNION ALL SELECT 'Plank', 'Brace your core and keep a straight line from shoulders to ankles.', 'Core', 'Bodyweight', 'timed', 1
  UNION ALL SELECT 'Dead Hang', 'Hang from the bar with controlled shoulders.', 'Grip', 'Pull-up bar', 'timed', 1
  UNION ALL SELECT 'Barbell Deadlift', 'Lift from the floor with a neutral spine and stable hips.', 'Posterior chain', 'Barbell', 'reps', 0
  UNION ALL SELECT 'Stationary Bike', 'Steady cycling effort recorded by duration.', 'Cardio', 'Bike', 'cardio', 0
) AS seed
WHERE NOT EXISTS (SELECT 1 FROM premium_exercises LIMIT 1);
