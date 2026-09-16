import { Router } from 'express';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

router.put('/:id', requireAuth, requireRole('manager'), async (req, res) => {
  const { id } = req.params;
  const { firstName, lastName, email, gender } = req.body;
  if (!firstName || !lastName || !email || !gender) {
    return res.status(400).json({ message: 'All fields are required.' });
  }
  try {
    const [[user]] = await pool.query(
      `SELECT id FROM users WHERE id = ? AND role IN ('client','admin')`,
      [id]
    );
    if (!user) return res.status(404).json({ message: 'Client not found.' });
    const [[dup]] = await pool.query(
      `SELECT id FROM users WHERE email = ? AND id != ?`,
      [email, id]
    );
    if (dup) return res.status(409).json({ message: 'Email already in use.' });
    await pool.query(
      `UPDATE users SET firstName = ?, lastName = ?, email = ?, gender = ? WHERE id = ?`,
      [firstName, lastName, email, gender, id]
    );
    res.json({ message: 'Client updated.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
