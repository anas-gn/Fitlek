import fs from 'node:fs/promises';
import db from '../config/db.js';
if(!['localhost','127.0.0.1','::1'].includes(process.env.DB_HOST))throw Error('Schema audit requires local MySQL');
try {
  const tables=['exercises','workout_plans','workout_days','workout_exercises','workout_sessions','workout_sets','workout_preferences','workout_exercise_preferences','workout_schedule','workout_schedule_dates','workout_alerts','workout_media','workout_imports','workout_import_exercises'];
  const [[server]]=await db.query('SELECT VERSION() version');
  const [columns]=await db.query('SELECT TABLE_NAME,COLUMN_NAME,COLUMN_TYPE,IS_NULLABLE,COLUMN_KEY FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME IN (?)',[tables]);
  const [keys]=await db.query('SELECT TABLE_NAME,CONSTRAINT_NAME,REFERENCED_TABLE_NAME,DELETE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME IN (?)',[tables]);
  const [indexes]=await db.query('SELECT TABLE_NAME,INDEX_NAME,COLUMN_NAME,SEQ_IN_INDEX,NON_UNIQUE FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME IN (?) ORDER BY TABLE_NAME,INDEX_NAME,SEQ_IN_INDEX',[tables]);
  const [relations]=await db.query('SELECT TABLE_NAME,COLUMN_NAME,REFERENCED_TABLE_NAME,REFERENCED_COLUMN_NAME FROM information_schema.KEY_COLUMN_USAGE WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME IN (?) AND REFERENCED_TABLE_NAME IS NOT NULL',[tables]);
  const orphans={};for(const relation of relations){const {TABLE_NAME:table,COLUMN_NAME:column,REFERENCED_TABLE_NAME:parent,REFERENCED_COLUMN_NAME:pk}=relation;
    if(![table,column,parent,pk].every(v=>/^[a-zA-Z][a-zA-Z0-9_]*$/.test(v)))throw Error('Unexpected database identifier');
    const [[row]]=await db.query(`SELECT COUNT(*) count FROM ${table} c LEFT JOIN ${parent} p ON p.${pk}=c.${column} WHERE c.${column} IS NOT NULL AND p.${pk} IS NULL`);orphans[`${table}.${column}`]=row.count;}
  const [planQuery]=await db.query("EXPLAIN SELECT * FROM workout_plans WHERE coachID=0 AND clientID=0 AND status='assigned'");
  const [historyQuery]=await db.query("EXPLAIN SELECT * FROM workout_sessions WHERE clientID=0 AND status='completed' ORDER BY startedAt,id LIMIT 30");
  const result={verifiedAt:new Date().toISOString(),mysqlVersion:server.version,tables,columns,foreignKeys:keys,indexes,orphans,explain:{planQuery,historyQuery}};
  if(tables.some(t=>!columns.some(c=>c.TABLE_NAME===t&&c.COLUMN_KEY==='PRI')))throw Error('Missing core primary key');
  if(Object.values(orphans).some(n=>Number(n)!==0))throw Error('Orphan workout records found');
  await fs.writeFile(new URL('../../docs/verification/workout-schema-audit.json',import.meta.url),JSON.stringify(result,null,2)+'\n');
  console.log('Verified '+tables.length+' MySQL tables, primary keys, '+keys.length+' foreign keys and no relational orphans.');
}finally{await db.end();}
