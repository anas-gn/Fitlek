import {readFile} from 'node:fs/promises';
import db from '../config/db.js';
import {ensureGoogleAuthSchema} from '../config/googleAuthSchema.js';
import {ensureAppCompatibilitySchema} from '../config/appCompatibilitySchema.js';
import {ensureWorkoutSchema} from '../config/workoutSchema.js';
import * as schema from '../config/ensureSchema.js';

// This initializes an EMPTY, disposable CI schema. Never run against app data.
if(process.env.CI!=='true'||!['localhost','127.0.0.1','::1'].includes(process.env.DB_HOST)||!/^sirvya_ci(?:_[a-z0-9]+)?$/.test(process.env.DB_NAME??''))throw new Error('CI bootstrap requires a disposable local sirvya_ci database');
try{
  const [[count]]=await db.query('SELECT COUNT(*) AS n FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE()');
  if(count.n!==0)throw new Error('CI bootstrap refuses a nonempty database');
  const sql=await readFile(new URL('../sirvya_schema.sql',import.meta.url),'utf8');
  for(const statement of sql.replace(/^--.*$/gm,'').split(';').map(s=>s.trim()).filter(Boolean))await db.query(statement);
  await ensureGoogleAuthSchema(db);await ensureAppCompatibilitySchema(db);
  for(const name of ['ensureReferralSchema','ensureClientInvitationSchema','ensureNotificationSchema','ensureCoachProfileColumns','ensureTermsAcceptedColumn','ensureOTPSchema','ensureFcmTokenColumn','ensureAppVersionSchema','ensureDeletedAccountsSchema','ensureUgcComplianceSchema','ensureCoachImagesSchema'])await schema[name]();
  await ensureWorkoutSchema(db);
  // SQL session variables and PREPARE/EXECUTE must share one connection.
  const connection=await db.getConnection();
  try{
    for(const name of ['2026_premium_subscriptions.sql','2026_premium_workouts.sql','2026_premium_exercise_seed.sql','2026_premium_superset_upgrade.sql']){
      const sql=await readFile(new URL('../migrations/'+name,import.meta.url),'utf8');
      for(const statement of sql.replace(/^--.*$/gm,'').split(';').map(s=>s.trim()).filter(Boolean))await connection.query(statement);
    }
  }finally{connection.release();}
  console.log('Disposable CI schema initialized');
}finally{await db.end();}
