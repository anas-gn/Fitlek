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
    const [[counts]] = await pool.query(`SELECT
      (SELECT COUNT(*) FROM clientreferrals WHERE inviterCoachID = ?) AS clientSignups,
      (SELECT COUNT(*) FROM coachreferrals WHERE inviterCoachID = ?) AS coachSignups`, [coachID,coachID]);
    const publicBase = (process.env.PUBLIC_INVITE_URL || 'https://sirvya.com').replace(/\/$/, '');
    res.json({
      coachID,
      clientSignups: Number(counts.clientSignups),
      coachSignups: Number(counts.coachSignups),
      inviteLink: `${publicBase}/invite/${encodeURIComponent(profile.invitationCode)}`,
      invitationCode: profile.invitationCode,
      earnedPoints: profile.earnedPoints,
      totalInvitations: Number(counts.clientSignups) + Number(counts.coachSignups),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Coach-to-Coach referral history for the authenticated coach.
// Returns only safe display fields (no private/account data).
router.get('/referrals', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  try {
    const [rows] = await pool.query(
      `SELECT cr.id, cr.pointsAwarded, cr.createdAt, 'coach' AS role, 'registered' AS status,
              u.firstName, u.lastName, u.avatarUrl
       FROM coachreferrals cr JOIN users u ON u.id = cr.invitedCoachID WHERE cr.inviterCoachID = ?
       UNION ALL
       SELECT cr.id, COALESCE(i.pointsEarned,0), cr.createdAt, 'client' AS role, COALESCE(i.status,'registered'),
              u.firstName, u.lastName, u.avatarUrl
       FROM clientreferrals cr JOIN users u ON u.id = cr.invitedClientID
       LEFT JOIN invitations i ON i.coachID = cr.inviterCoachID AND i.invitedUserID = cr.invitedClientID
       WHERE cr.inviterCoachID = ? ORDER BY createdAt DESC`,
      [coachID,coachID]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
