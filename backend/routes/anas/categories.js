import express from 'express';
const router = express.Router();
import pool from '../../config/db.js';

// GET /categories — list all categories
router.get('/', async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT id, name, icon, sortOrder FROM categories ORDER BY sortOrder ASC`
    );
    res.json(rows);
  } catch (error) {
    console.error('❌ Error fetching categories:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
