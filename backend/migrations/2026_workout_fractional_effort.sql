-- Preserve existing integer ratings while supporting the reference's .5 steps.
ALTER TABLE workout_sets MODIFY rir DECIMAL(4,2) NULL;
