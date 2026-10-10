import { readFile } from 'node:fs/promises';
import exercises from '../data/workoutExercises.js';

export async function ensureWorkoutSchema(db) {
  await db.query(`CREATE TABLE IF NOT EXISTS workout_backup_restores (
    userID BIGINT UNSIGNED NOT NULL, fingerprint CHAR(64) NOT NULL,
    restoredAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY(userID,fingerprint), FOREIGN KEY(userID) REFERENCES users(id) ON DELETE CASCADE
  ) ENGINE=InnoDB`);
  const sql = await readFile(new URL('../migrations/2026_sirvya_workout.sql', import.meta.url), 'utf8');
  for (const statement of sql.split(';').map(s => s.trim()).filter(Boolean)) await db.query(statement);
  await db.query('ALTER TABLE workout_plans MODIFY coachID BIGINT UNSIGNED NULL');
  const [effortColumns]=await db.query("SELECT DATA_TYPE,NUMERIC_SCALE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='workout_sets' AND COLUMN_NAME='rir'");
  if(effortColumns.some(c=>c.DATA_TYPE!=='decimal'||Number(c.NUMERIC_SCALE)<2))await db.query('ALTER TABLE workout_sets MODIFY rir DECIMAL(4,2) NULL');
  const additions = {
    exercises: {bodyPart: 'VARCHAR(80) NULL', ownerID: 'BIGINT UNSIGNED NULL', instructionTranslations: 'JSON NULL',isPrivate:'TINYINT(1) NOT NULL DEFAULT 0', archivedAt:'DATETIME NULL'},
    workout_exercises: {configuration: 'JSON NULL'},
    workout_days: {configuration: 'JSON NULL'},
    workout_sessions: {execution: 'JSON NULL', revision: 'INT NOT NULL DEFAULT 1', excludedFromProgression: 'TINYINT(1) NOT NULL DEFAULT 0'},
    workout_sets: {details: 'JSON NULL'},
  };
  for (const [table, columns] of Object.entries(additions)) {
    const [existing] = await db.query('SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?', [table]);
    const names = new Set(existing.map(c => c.COLUMN_NAME));
    for (const [name, definition] of Object.entries(columns)) if (!names.has(name)) await db.query(`ALTER TABLE ${table} ADD COLUMN ${name} ${definition}`);
  }
  await db.query('UPDATE exercises SET isPrivate=1 WHERE ownerID IS NOT NULL');
  // Millisecond chronology matters for immediate retries / subsequent sessions.
  const [dates]=await db.query("SELECT COLUMN_NAME,DATETIME_PRECISION FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='workout_sessions' AND COLUMN_NAME IN ('startedAt','completedAt')");
  for(const date of dates)if(Number(date.DATETIME_PRECISION)<3){
    const definition=date.COLUMN_NAME==='startedAt'?'NOT NULL DEFAULT CURRENT_TIMESTAMP(3)':'NULL';
    await db.query(`ALTER TABLE workout_sessions MODIFY ${date.COLUMN_NAME} DATETIME(3) ${definition}`);
  }
  for(const [table,column,name] of [['exercises','ownerID','fk_workout_exercise_owner'],['workout_plans','coachID','fk_workout_plan_coach']]){
    const [keys]=await db.query('SELECT rc.CONSTRAINT_NAME,rc.DELETE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS rc JOIN information_schema.KEY_COLUMN_USAGE k ON k.CONSTRAINT_SCHEMA=rc.CONSTRAINT_SCHEMA AND k.CONSTRAINT_NAME=rc.CONSTRAINT_NAME AND k.TABLE_NAME=rc.TABLE_NAME WHERE rc.CONSTRAINT_SCHEMA=DATABASE() AND k.TABLE_NAME=? AND k.COLUMN_NAME=?',[table,column]);
    if(keys.some(k=>k.DELETE_RULE==='SET NULL'))continue;
    for(const key of keys){if(!/^[a-zA-Z0-9_]+$/.test(key.CONSTRAINT_NAME))throw new Error('Invalid schema constraint');await db.query(`ALTER TABLE ${table} DROP FOREIGN KEY ${key.CONSTRAINT_NAME}`);}
    await db.query(`ALTER TABLE ${table} ADD CONSTRAINT ${name} FOREIGN KEY (${column}) REFERENCES users(id) ON DELETE SET NULL`);
  }
  const extra = await readFile(new URL('../migrations/2026_workout_experience.sql', import.meta.url), 'utf8');
  for (const statement of extra.split(';').map(s => s.trim()).filter(Boolean)) await db.query(statement);
  const weekly = await readFile(new URL('../migrations/2026_workout_week_plan.sql', import.meta.url), 'utf8');
  for (const statement of weekly.split(';').map(s => s.trim()).filter(Boolean)) await db.query(statement);
  const [exercisePreferences]=await db.query("SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='workout_exercise_preferences'");
  if(!exercisePreferences.some(c=>c.COLUMN_NAME==='workingWeight'))await db.query('ALTER TABLE workout_exercise_preferences ADD COLUMN workingWeight DECIMAL(8,3) NULL');
  const indexes=await readFile(new URL('../migrations/2026_workout_audit_indexes.sql',import.meta.url),'utf8');
  for(const statement of indexes.split(';').map(s=>s.trim()).filter(Boolean)){
    const [,name,table]=statement.match(/^CREATE INDEX ([a-z_]+) ON ([a-z_]+)/);
    const [existing]=await db.query('SELECT INDEX_NAME FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=? AND INDEX_NAME=?',[table,name]);
    if(!existing.length)await db.query(statement);
  }
  const [alertColumns]=await db.query("SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='workout_alerts'");
  if(!alertColumns.some(c=>c.COLUMN_NAME==='claimedAt'))await db.query('ALTER TABLE workout_alerts ADD COLUMN claimedAt DATETIME NULL');
  for (const e of exercises) {
    await db.query(`INSERT IGNORE INTO exercises
      (name, muscleGroup, secondaryMuscles, equipment, exerciseType, isBodyweight, isTimed, instructions, externalSource, externalId)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'sirvya', ?)`,
    [e.name, e.muscleGroup, JSON.stringify(e.secondaryMuscles), e.equipment, e.exerciseType,
      e.isBodyweight ? 1 : 0, e.isTimed ? 1 : 0, JSON.stringify(e.instructions), e.externalId]);
  }
  // Metadata-only backfill. Existing exercise IDs, instructions and media are unchanged.
  const bodyParts=JSON.parse(await readFile(new URL('../data/exerciseBodyParts.json',import.meta.url),'utf8'));
  const [missingParts]=await db.query("SELECT id,externalId FROM exercises WHERE externalSource='exercises-dataset' AND bodyPart IS NULL");
  for(let i=0;i<missingParts.length;i+=100){
    const batch=missingParts.slice(i,i+100).filter(e=>bodyParts[e.externalId]);
    if(batch.length)await db.query(`UPDATE exercises SET bodyPart=CASE id ${batch.map(()=> 'WHEN ? THEN ?').join(' ')} END WHERE id IN (?)`,[...batch.flatMap(e=>[e.id,bodyParts[e.externalId]]),batch.map(e=>e.id)]);
  }
  const metadata=JSON.parse(await readFile(new URL('../data/exerciseMetadata.json',import.meta.url),'utf8'));
  // Stable source identities; one batch query per 100 rows, no network at startup.
  for(let i=0;i<metadata.length;i+=100){
    const rows=metadata.slice(i,i+100).map(e=>[e.name,e.muscleGroup,JSON.stringify(e.secondaryMuscles),e.equipment,e.exerciseType,e.isBodyweight?1:0,e.exerciseType==='reps'?0:1,JSON.stringify(e.instructions),JSON.stringify(e.instructionTranslations),'exercises-dataset',e.externalId,e.bodyPart??bodyParts[e.externalId]??null]);
    await db.query(`INSERT IGNORE INTO exercises (name,muscleGroup,secondaryMuscles,equipment,exerciseType,isBodyweight,isTimed,instructions,instructionTranslations,externalSource,externalId,bodyPart) VALUES ?`,[rows]);
  }
}
