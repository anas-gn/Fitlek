import { Router } from 'express';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import pool from '../../config/db.js';

const router = Router();

router.post('/', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ message: 'Email and password are required.' });
  }
  try {
    const [[user]] = await pool.query(
      `SELECT id, firstName, lastName, email, passwordHash, role, avatarUrl
       FROM users WHERE email = ? AND role = 'manager'`,
      [email]
    );
    if (!user) return res.status(401).json({ message: 'Invalid credentials.' });
    const match = await bcrypt.compare(password, user.passwordHash);
    if (!match) return res.status(401).json({ message: 'Invalid credentials.' });
    const token = jwt.sign(
      { id: user.id, role: 'manager' },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );
    res.json({
      token,
      manager: {
        id: user.id,
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        avatarUrl: user.avatarUrl,
      }
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
