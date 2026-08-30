import { Router } from 'express';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

router.get('/', requireAuth, requireRole('manager'), async (req, res) => {
  const { search, filter } = req.query;
  try {
    let query = `
      SELECT u.id, u.firstName, u.lastName, u.email, u.avatarUrl,
             ap.specialty, u.createdAt
      FROM users u
      JOIN advisorProfiles ap ON ap.userID = u.id
      WHERE u.role = 'advisor'`;
    const params = [];
    if (search) {
      query += ` AND (u.firstName LIKE ? OR u.lastName LIKE ? OR u.email LIKE ? OR ap.specialty LIKE ?)`;
      const s = `%${search}%`;
      params.push(s, s, s, s);
    }
    if (filter && filter !== 'All') {
      query += ` AND ap.specialty = ?`;
      params.push(filter);
    }
    query += ` ORDER BY u.firstName ASC`;
    const [rows] = await pool.query(query, params);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.delete('/:id', requireAuth, requireRole('manager'), async (req, res) => {
  const { id } = req.params;
  try {
    const [[adv]] = await pool.query(
      `SELECT id FROM users WHERE id = ? AND role = 'advisor'`, [id]);
    if (!adv) return res.status(404).json({ message: 'Advisor not found.' });
    await pool.query(`DELETE FROM users WHERE id = ?`, [id]);
    res.json({ message: 'Advisor deleted.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
