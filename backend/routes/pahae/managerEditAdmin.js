import { Router } from 'express';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

router.put('/:id', requireAuth, requireRole('manager'), async (req, res) => {
  const { id } = req.params;
  const { firstName, lastName, email } = req.body;
  if (!firstName || !lastName || !email) {
    return res.status(400).json({ message: 'All fields are required.' });
  }
  try {
    const [[admin]] = await pool.query(
      `SELECT id FROM users WHERE id = ? AND role = 'admin'`, [id]);
    if (!admin) return res.status(404).json({ message: 'Admin not found.' });
    const [[dup]] = await pool.query(
      `SELECT id FROM users WHERE email = ? AND id != ?`, [email, id]);
    if (dup) return res.status(409).json({ message: 'Email already in use.' });
    await pool.query(
      `UPDATE users SET firstName = ?, lastName = ?, email = ? WHERE id = ?`,
      [firstName, lastName, email, id]
    );
    res.json({ message: 'Admin updated.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
