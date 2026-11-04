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

function parseJsonList(value) {
  if (!value) return [];
  try {
    const parsed = typeof value === 'string' ? JSON.parse(value) : value;
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

router.get('/', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  try {
    const [[row]] = await pool.query(
      `SELECT u.id, u.firstName, u.lastName, u.email, u.gender, u.avatarUrl, u.phoneNumber,
              cp.bio, cp.specialty, cp.experience, cp.professionalTitle,
              cp.certifications, cp.specialties, cp.publicProfile, cp.directMessaging,
              cp.instagramPage, cp.invitationCode,
              cp.totalInvitations, cp.earnedPoints,
              COALESCE(NULLIF(TRIM(u.phoneNumber), ''), cp.tel) AS tel,
              cp.price, cp.ville, cp.certificateUrl, cp.advisorID,
              cp.languages, cp.showGender, cp.categoryID, cp.clientLevels, cp.coachingFormats, cp.gymName, cp.gymAddress, cp.gymImage, cp.serviceArea
       FROM users u
       JOIN coachprofiles cp ON cp.userID = u.id
       WHERE u.id = ?`,
      [coachID]
    );
    if (!row) return res.status(404).json({ message: 'Profile not found.' });
    res.json({
      ...row,
      certifications: parseJsonList(row.certifications),
      specialties: parseStringList(row.specialties),
      languages: parseStringList(row.languages),
      clientLevels: parseStringList(row.clientLevels),
      showGender: Boolean(row.showGender ?? 1),
      publicProfile: Boolean(row.publicProfile),
      directMessaging: Boolean(row.directMessaging),
      referralReward: REFERRAL_REWARD_POINTS,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
