import { Router } from 'express';
import bcrypt from 'bcrypt';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

router.get('/', requireAuth, requireRole('manager'), async (req, res) => {
  const managerID = req.user.id;
  try {
    const [[user]] = await pool.query(
      `SELECT id, firstName, lastName, email, avatarUrl FROM users WHERE id = ?`,
      [managerID]
    );
    if (!user) return res.status(404).json({ message: 'Profile not found.' });
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.put('/', requireAuth, requireRole('manager'), async (req, res) => {
  const managerID = req.user.id;
  const { firstName, lastName, email } = req.body;
  if (!firstName || !lastName || !email) {
    return res.status(400).json({ message: 'firstName, lastName and email are required.' });
  }
  try {
    const [[dup]] = await pool.query(
      `SELECT id FROM users WHERE email = ? AND id != ?`, [email, managerID]);
    if (dup) return res.status(409).json({ message: 'Email already in use.' });
    await pool.query(
      `UPDATE users SET firstName = ?, lastName = ?, email = ? WHERE id = ?`,
      [firstName, lastName, email, managerID]
    );
    res.json({ message: 'Profile updated.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.put('/password', requireAuth, requireRole('manager'), async (req, res) => {
  const managerID = req.user.id;
  const { currentPassword, newPassword } = req.body;
  if (!currentPassword || !newPassword) {
    return res.status(400).json({ message: 'currentPassword and newPassword are required.' });
  }
  if (newPassword.length < 6) {
    return res.status(400).json({ message: 'Password must be at least 6 characters.' });
  }
  try {
    const [[user]] = await pool.query(
      `SELECT passwordHash FROM users WHERE id = ?`, [managerID]);
    const match = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!match) return res.status(401).json({ message: 'Current password is incorrect.' });
    const newHash = await bcrypt.hash(newPassword, 12);
    await pool.query(`UPDATE users SET passwordHash = ? WHERE id = ?`, [newHash, managerID]);
    res.json({ message: 'Password updated.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
