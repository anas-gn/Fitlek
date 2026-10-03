import {readFile} from 'node:fs/promises';
import db from './config/db.js';

try {
  const sql = await readFile(new URL('./migrations/2026_categories_favorites.sql', import.meta.url), 'utf8');
  for (const statement of sql.split(';').map(s => s.trim()).filter(Boolean)) await db.query(statement);
  console.log('Migration executed successfully');
} catch (error) {
  console.error('Migration failed:', error.code || error.message);
  process.exitCode = 1;
} finally {
  await db.end();
}
