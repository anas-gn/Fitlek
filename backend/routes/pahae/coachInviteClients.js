import { Router } from 'express';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

router.get('/', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  try {
    const [[profile]] = await pool.query(
      `SELECT invitationCode, earnedPoints, totalInvitations
       FROM coachprofiles WHERE userID = ?`,
      [coachID]
    );
    if (!profile) return res.status(404).json({ message: 'Coach profile not found.' });
    res.json({
      coachID,
      invitationCode: profile.invitationCode,
      earnedPoints: profile.earnedPoints,
      totalInvitations: profile.totalInvitations,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
