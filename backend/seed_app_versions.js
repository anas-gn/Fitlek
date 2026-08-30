import mysql from 'mysql2/promise';
import dotenv from 'dotenv';
dotenv.config();

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT ? Number(process.env.DB_PORT) : 3306,
});

async function seed() {
  try {
    // Create the table if it doesn't already exist
    await pool.query(`
      CREATE TABLE IF NOT EXISTS app_versions (
        id INT AUTO_INCREMENT PRIMARY KEY,
        platform VARCHAR(10) NOT NULL UNIQUE,
        latest_version VARCHAR(20) NOT NULL,
        min_required_version VARCHAR(20) NOT NULL,
        store_url TEXT NOT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Table app_versions ready');

    // Insert or update Android row
    await pool.query(`
      INSERT INTO app_versions (platform, latest_version, min_required_version, store_url)
      VALUES ('android', '1.0.0', '1.0.0', 'https://play.google.com/store/apps/details?id=com.sirvya.app')
      ON DUPLICATE KEY UPDATE
        latest_version = VALUES(latest_version),
        min_required_version = VALUES(min_required_version),
        store_url = VALUES(store_url)
    `);
    console.log('✅ Android version row inserted/updated');

    // Insert or update iOS row (update the ID when published to App Store)
    await pool.query(`
      INSERT INTO app_versions (platform, latest_version, min_required_version, store_url)
      VALUES ('ios', '1.0.0', '1.0.0', 'https://apps.apple.com/app/sirvya/id0000000000')
      ON DUPLICATE KEY UPDATE
        latest_version = VALUES(latest_version),
        min_required_version = VALUES(min_required_version),
        store_url = VALUES(store_url)
    `);
    console.log('✅ iOS version row inserted/updated');

    console.log('\n✅ Done! Current app_versions table:');
    const [rows] = await pool.query('SELECT * FROM app_versions');
    console.table(rows);
  } catch (err) {
    console.error('❌ Error:', err.message);
  } finally {
    await pool.end();
  }
}

seed();
