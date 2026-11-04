import express from 'express';
const router = express.Router();
import pool from '../../config/db.js';

// GET /categories — list all categories
router.get('/', async (req, res) => {
  try {
    const { hasCoaches } = req.query;
    if (hasCoaches === 'true' || hasCoaches === '1') {
      const [rows] = await pool.query(
        `SELECT c.id, c.name, c.icon, c.sortOrder, COUNT(cp.id) AS coachCount
         FROM categories c
         JOIN coachprofiles cp ON cp.categoryID = c.id
         JOIN users u ON u.id = cp.userID AND u.role = 'coach'
         GROUP BY c.id
         HAVING coachCount > 0
         ORDER BY c.sortOrder ASC`
      );
      return res.json(rows);
    }

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
