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
    const [rows] = await pool.query(
      `SELECT u.id, u.firstName, u.lastName, u.email, u.passwordHash, u.role,
              u.avatarUrl, u.isApproved, u.gender,
              cp.invitationCode, cp.earnedPoints, cp.totalInvitations
       FROM users u
       LEFT JOIN coachProfiles cp ON cp.userID = u.id
       WHERE u.email = ? AND u.role = 'coach'`,
      [email]
    );
    if (rows.length === 0) {
      return res.status(401).json({ message: 'Invalid credentials.' });
    }
    const coach = rows[0];
    const match = await bcrypt.compare(password, coach.passwordHash);
    if (!match) {
      return res.status(401).json({ message: 'Invalid credentials.' });
    }
    if (!coach.isApproved) {
      return res.status(403).json({ message: 'Your account is pending approval.' });
    }
    const [banRows] = await pool.query(
      `SELECT id FROM bans
       WHERE userID = ? AND isActive = 1
         AND (expiresAt IS NULL OR expiresAt > NOW())
       LIMIT 1`,
      [coach.id]
    );
    if (banRows.length > 0) {
      return res.status(403).json({ message: 'Your account has been banned.' });
    }
    const token = jwt.sign(
      { id: coach.id, role: 'coach' },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );
    res.json({
      token,
      coach: {
        id: coach.id,
        firstName: coach.firstName,
        lastName: coach.lastName,
        email: coach.email,
        avatarUrl: coach.avatarUrl,
        invitationCode: coach.invitationCode,
        earnedPoints: coach.earnedPoints,
        totalInvitations: coach.totalInvitations,
      }
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
