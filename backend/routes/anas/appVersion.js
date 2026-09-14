import express from 'express';
import pool from '../../config/db.js';

const router = express.Router();

// ─── ONE-TIME SETUP (run once then remove) ───────────────────────────────────
// Call: POST https://sirvya-1c5de0abe34c.herokuapp.com/api/app-version/setup
// Header: x-setup-key: sirvya-setup-2026
router.post('/setup', async (req, res) => {
  if (req.headers['x-setup-key'] !== 'sirvya-setup-2026') {
    return res.status(403).json({ success: false, message: 'Forbidden' });
  }
  try {
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

    await pool.query(`
      INSERT INTO app_versions (platform, latest_version, min_required_version, store_url)
      VALUES ('android', '1.0.0', '1.0.0', 'https://play.google.com/store/apps/details?id=com.sirvya.app')
      ON DUPLICATE KEY UPDATE
        latest_version = VALUES(latest_version),
        min_required_version = VALUES(min_required_version),
        store_url = VALUES(store_url)
    `);

    await pool.query(`
      INSERT INTO app_versions (platform, latest_version, min_required_version, store_url)
      VALUES ('ios', '1.0.0', '1.0.0', 'https://apps.apple.com/app/sirvya/id0000000000')
      ON DUPLICATE KEY UPDATE
        latest_version = VALUES(latest_version),
        min_required_version = VALUES(min_required_version),
        store_url = VALUES(store_url)
    `);

    const [rows] = await pool.query('SELECT * FROM app_versions');
    res.json({ success: true, message: 'Setup complete', data: rows });
  } catch (error) {
    console.error('Setup error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});
// ─────────────────────────────────────────────────────────────────────────────

router.get('/', async (req, res) => {
  try {
    const { platform } = req.query;

    if (!platform || !['ios', 'android'].includes(platform.toLowerCase())) {
      return res.status(400).json({
        success: false,
        message: "Invalid platform. Must be 'ios' or 'android'."
      });
    }

    const [rows] = await pool.query(
      'SELECT latest_version, min_required_version, store_url FROM app_versions WHERE platform = ? LIMIT 1',
      [platform.toLowerCase()]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Version info not found for the specified platform."
      });
    }

    res.json({
      success: true,
      data: rows[0]
    });
  } catch (error) {
    console.error('Error fetching app version info:', error);
    res.status(500).json({ success: false, message: 'Server Error' });
  }
});

export default router;
