import { Router } from 'express';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

// Coach-to-Coach referral reward, mirrored from the auth signup flow
// (backend/routes/anas/auth.js REFERRAL_REWARD_POINTS). Surfaced read-only so
// the profile UI can display the real reward instead of hardcoding a value.
const REFERRAL_REWARD_POINTS = 40;

function parseStringList(value) {
  if (!value) return [];
  try {
    const parsed = typeof value === 'string' ? JSON.parse(value) : value;
    return Array.isArray(parsed)
      ? parsed.filter((item) => typeof item === 'string' && item.trim()).map((item) => item.trim())
      : [];
  } catch {
    return [];
  }
}

router.get('/', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  try {
    const [[row]] = await pool.query(
      `SELECT u.id, u.firstName, u.lastName, u.email, u.gender, u.avatarUrl,
              cp.bio, cp.specialty, cp.experience, cp.professionalTitle,
              cp.certifications, cp.specialties, cp.publicProfile, cp.directMessaging,
              cp.instagramPage, cp.invitationCode,
              cp.totalInvitations, cp.earnedPoints,
              cp.tel, cp.price, cp.ville, cp.certificateUrl, cp.advisorID
       FROM users u
       JOIN coachprofiles cp ON cp.userID = u.id
       WHERE u.id = ?`,
      [coachID]
    );
    if (!row) return res.status(404).json({ message: 'Profile not found.' });
    res.json({
      ...row,
      certifications: parseStringList(row.certifications),
      specialties: parseStringList(row.specialties),
      publicProfile: Boolean(row.publicProfile),
      directMessaging: Boolean(row.directMessaging),
      referralReward: REFERRAL_REWARD_POINTS,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
