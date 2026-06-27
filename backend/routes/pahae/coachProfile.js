import { Router } from 'express';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

router.get('/', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  try {
    const [[row]] = await pool.query(
      `SELECT u.id, u.firstName, u.lastName, u.email, u.gender, u.avatarUrl,
              cp.bio, cp.instagramPage, cp.invitationCode,
              cp.totalInvitations, cp.earnedPoints
       FROM users u
       JOIN coachProfiles cp ON cp.userID = u.id
       WHERE u.id = ?`,
      [coachID]
    );
    if (!row) return res.status(404).json({ message: 'Profile not found.' });
    res.json(row);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
