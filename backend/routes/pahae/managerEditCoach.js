import { Router } from 'express';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

router.put('/:id', requireAuth, requireRole('manager'), async (req, res) => {
  const { id } = req.params;
  const { firstName, lastName, email, gender, bio, instagramPage } = req.body;
  if (!firstName || !lastName || !email || !gender || !bio || !instagramPage) {
    return res.status(400).json({ message: 'All fields are required.' });
  }
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const [[coach]] = await conn.query(
      `SELECT id FROM users WHERE id = ? AND role = 'coach'`, [id]);
    if (!coach) { await conn.rollback(); return res.status(404).json({ message: 'Coach not found.' }); }
    const [[dup]] = await conn.query(`SELECT id FROM users WHERE email = ? AND id != ?`, [email, id]);
    if (dup) { await conn.rollback(); return res.status(409).json({ message: 'Email already in use.' }); }
    await conn.query(
      `UPDATE users SET firstName = ?, lastName = ?, email = ?, gender = ? WHERE id = ?`,
      [firstName, lastName, email, gender, id]
    );
    await conn.query(
      `UPDATE coachProfiles SET bio = ?, instagramPage = ? WHERE userID = ?`,
      [bio, instagramPage, id]
    );
    await conn.commit();
    res.json({ message: 'Coach updated.' });
  } catch (err) {
    await conn.rollback();
    res.status(500).json({ message: err.message });
  } finally {
    conn.release();
  }
});

export default router;
