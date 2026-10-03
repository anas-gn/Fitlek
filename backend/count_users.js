import db from './config/db.js';

try {
  const [[row]] = await db.query('SELECT COUNT(*) AS count FROM users');
  console.log(`Total users: ${row.count}`);
} catch (error) {
  console.error('Unable to count users:', error.code || error.message);
  process.exitCode = 1;
} finally {
  await db.end();
}
