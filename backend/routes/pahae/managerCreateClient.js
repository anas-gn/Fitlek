import { Router } from 'express';
import bcrypt from 'bcrypt';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

router.post('/', requireAuth, requireRole('manager'), async (req, res) => {
  const { firstName, lastName, email, gender } = req.body;
  if (!firstName || !lastName || !email || !gender) {
    return res.status(400).json({ message: 'firstName, lastName, email and gender are required.' });
  }
  try {
    const [[existing]] = await pool.query(`SELECT id FROM users WHERE email = ?`, [email]);
    if (existing) return res.status(409).json({ message: 'Email already in use.' });
    const tempPassword = Math.random().toString(36).slice(-8);
    const passwordHash = await bcrypt.hash(tempPassword, 12);
    const [result] = await pool.query(
      `INSERT INTO users (firstName, lastName, email, passwordHash, role, gender)
       VALUES (?, ?, ?, ?, 'client', ?)`,
      [firstName, lastName, email, passwordHash, gender]
    );
    res.status(201).json({
      id: result.insertId,
      firstName,
      lastName,
      email,
      gender,
      tempPassword,
      message: 'Client created.',
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
