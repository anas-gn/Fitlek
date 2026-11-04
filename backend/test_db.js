import pool from './config/db.js';

async function test() {
  try {
    const [rows] = await pool.query(
      `SELECT id, name, icon, sortOrder FROM categories ORDER BY sortOrder ASC`
    );
    console.log(rows);
  } catch (error) {
    console.error('❌ Error fetching categories:', error);
  }
  process.exit(0);
}

test();
