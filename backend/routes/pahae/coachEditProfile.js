import { Router } from 'express';
import bcrypt from 'bcrypt';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

router.put('/', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  const { firstName, lastName, gender, bio, instagramPage, avatarUrl } = req.body;
  if (!firstName || !lastName || !gender || !bio || !instagramPage) {
    return res.status(400).json({ message: 'All fields are required.' });
  }
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const userUpdate = avatarUrl
      ? `UPDATE users SET firstName = ?, lastName = ?, gender = ?, avatarUrl = ? WHERE id = ?`
      : `UPDATE users SET firstName = ?, lastName = ?, gender = ? WHERE id = ?`;
    const userParams = avatarUrl
      ? [firstName, lastName, gender, avatarUrl, coachID]
      : [firstName, lastName, gender, coachID];
    await conn.query(userUpdate, userParams);
    await conn.query(
      `UPDATE coachProfiles SET bio = ?, instagramPage = ? WHERE userID = ?`,
      [bio, instagramPage, coachID]
    );
    await conn.commit();
    res.json({ message: 'Profile updated.' });
  } catch (err) {
    await conn.rollback();
    res.status(500).json({ message: err.message });
  } finally {
    conn.release();
  }
});

router.put('/password', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  const { currentPassword, newPassword } = req.body;
  if (!currentPassword || !newPassword) {
    return res.status(400).json({ message: 'currentPassword and newPassword are required.' });
  }
  if (newPassword.length < 6) {
    return res.status(400).json({ message: 'Password must be at least 6 characters.' });
  }
  try {
    const [[user]] = await pool.query(
      `SELECT passwordHash FROM users WHERE id = ?`,
      [coachID]
    );
    const match = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!match) return res.status(401).json({ message: 'Current password is incorrect.' });
    const newHash = await bcrypt.hash(newPassword, 12);
    await pool.query(`UPDATE users SET passwordHash = ? WHERE id = ?`, [newHash, coachID]);
    res.json({ message: 'Password updated.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
