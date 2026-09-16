import fs from 'fs';
import mysql from 'mysql2/promise';

async function run() {
  try {
    const sql = fs.readFileSync('migrations/2026_categories_favorites.sql', 'utf8');
    const conn = await mysql.createConnection({
      host: '51.170.143.251',
      user: 'sirvya',
      password: 'Sirvya@Backend2026',
      database: 'sirvya',
      port: 3306,
      multipleStatements: true
    });
    console.log('Connected to DB');
    const [results] = await conn.query(sql);
    console.log('Migration executed successfully');
    conn.end();
  } catch (e) {
    console.error('Migration failed:', e);
  }
}
run();
