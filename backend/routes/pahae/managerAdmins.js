import { Router } from 'express';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

router.get('/', requireAuth, requireRole('manager'), async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT id, firstName, lastName, email, avatarUrl, createdAt
       FROM users WHERE role = 'admin'
       ORDER BY firstName ASC`
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.patch('/:id/unremote', requireAuth, requireRole('manager'), async (req, res) => {
  const { id } = req.params;
  try {
    const [[admin]] = await pool.query(
      `SELECT id FROM users WHERE id = ? AND role = 'admin'`, [id]);
    if (!admin) return res.status(404).json({ message: 'Admin not found.' });
    await pool.query(`UPDATE users SET role = 'client' WHERE id = ?`, [id]);
    res.json({ message: 'Admin returned to client.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.delete('/:id', requireAuth, requireRole('manager'), async (req, res) => {
  const { id } = req.params;
  try {
    const [[admin]] = await pool.query(
      `SELECT id FROM users WHERE id = ? AND role = 'admin'`, [id]);
    if (!admin) return res.status(404).json({ message: 'Admin not found.' });
    await pool.query(`DELETE FROM users WHERE id = ?`, [id]);
    res.json({ message: 'Admin deleted.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
