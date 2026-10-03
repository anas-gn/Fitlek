SET @superset_column_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'premium_routine_exercises'
    AND COLUMN_NAME = 'supersetGroup'
);

SET @superset_sql := IF(
  @superset_column_exists = 0,
  'ALTER TABLE premium_routine_exercises ADD COLUMN supersetGroup VARCHAR(64) NULL',
  'SELECT 1'
);

PREPARE superset_statement FROM @superset_sql;
EXECUTE superset_statement;
DEALLOCATE PREPARE superset_statement;
