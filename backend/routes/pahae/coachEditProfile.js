import { Router } from 'express';
import bcrypt from 'bcrypt';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

function normalizeStringList(value, maxItems, maxLength) {
  if (!Array.isArray(value)) return null;
  const unique = new Map();
  for (const item of value) {
    if (typeof item !== 'string') continue;
    const normalized = item.trim();
    if (!normalized || normalized.length > maxLength) continue;
    unique.set(normalized.toLowerCase(), normalized);
    if (unique.size >= maxItems) break;
  }
  return [...unique.values()];
}

function normalizeOptionalString(value, { maxLength = 255, allowEmpty = true } = {}) {
  if (value === undefined) return undefined;
  if (value === null) return allowEmpty ? '' : null;
  const trimmed = String(value).trim();
  if (!allowEmpty && !trimmed) return null;
  if (trimmed.length > maxLength) return null;
  return trimmed;
}

router.put('/', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  const {
    firstName, lastName, email, gender, bio, specialty, experience, professionalTitle,
    certifications, specialties, publicProfile, directMessaging,
    instagramPage, avatarUrl, tel, ville,
  } = req.body;

  if (!firstName || !lastName || !gender || !bio) {
    return res.status(400).json({
      message: 'First name, last name, gender and bio are required.',
    });
  }

  const firstNameValue = String(firstName).trim();
  const lastNameValue = String(lastName).trim();
  const genderValue = String(gender).trim();
  const bioValue = String(bio).trim();

  if (!firstNameValue || !lastNameValue || !genderValue || !bioValue) {
    return res.status(400).json({
      message: 'First name, last name, gender and bio are required.',
    });
  }

  // Email is optional in the payload; when provided it must be a valid unique address.
  let emailValue = undefined;
  if (email !== undefined && email !== null) {
    emailValue = String(email).trim().toLowerCase();
    if (!emailValue || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(emailValue)) {
      return res.status(400).json({ message: 'A valid email address is required.' });
    }
  }

  const telValue = normalizeOptionalString(tel, { maxLength: 40 });
  const villeValue = normalizeOptionalString(ville, { maxLength: 120 });
  const instagramValue = normalizeOptionalString(instagramPage, { maxLength: 120 });
  const specialtyValue = normalizeOptionalString(specialty, { maxLength: 120 }) ?? '';
  const experienceValue = normalizeOptionalString(experience, { maxLength: 150 }) ?? '';

  let professionalTitleValue = undefined;
  if (professionalTitle !== undefined) {
    professionalTitleValue = String(professionalTitle ?? '').trim();
    if (professionalTitleValue.length > 150) {
      return res.status(400).json({ message: 'Professional title is too long.' });
    }
  }

  const certificationList = certifications === undefined
    ? null
    : normalizeStringList(certifications, 10, 120);
  const specialtyList = specialties === undefined
    ? null
    : normalizeStringList(specialties, 10, 60);

  if (certifications !== undefined && certificationList === null) {
    return res.status(400).json({ message: 'Certifications must be a list.' });
  }
  if (specialties !== undefined && specialtyList === null) {
    return res.status(400).json({ message: 'Specialties must be a list.' });
  }

  const publicProfileValue = publicProfile === undefined
    ? null
    : (publicProfile === true || publicProfile === 1 ? 1 : 0);
  const directMessagingValue = directMessaging === undefined
    ? null
    : (directMessaging === true || directMessaging === 1 ? 1 : 0);

  // Price is intentionally ignored: coaches do not set a price in the app.
  // Never touch coachprofiles.price from this endpoint.

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    if (emailValue !== undefined) {
      const [[existing]] = await conn.query(
        `SELECT id FROM users WHERE email = ? AND id != ? LIMIT 1`,
        [emailValue, coachID]
      );
      if (existing) {
        await conn.rollback();
        return res.status(409).json({ message: 'This email is already used by another account.' });
      }
    }

    // Build users UPDATE dynamically so we only change provided fields.
    const userSets = ['firstName = ?', 'lastName = ?', 'gender = ?'];
    const userParams = [firstNameValue, lastNameValue, genderValue];

    if (emailValue !== undefined) {
      userSets.push('email = ?');
      userParams.push(emailValue);
    }
    if (avatarUrl) {
      userSets.push('avatarUrl = ?');
      userParams.push(String(avatarUrl).trim());
    }
    userParams.push(coachID);

    await conn.query(
      `UPDATE users SET ${userSets.join(', ')} WHERE id = ?`,
      userParams
    );

    // Build coachprofiles UPDATE — do NOT include price.
    const profileSets = [
      'bio = ?',
      'specialty = ?',
      'experience = ?',
      'professionalTitle = COALESCE(?, professionalTitle)',
      'certifications = COALESCE(?, certifications)',
      'specialties = COALESCE(?, specialties)',
      'publicProfile = COALESCE(?, publicProfile)',
      'directMessaging = COALESCE(?, directMessaging)',
    ];
    const profileParams = [
      bioValue,
      specialtyValue,
      experienceValue,
      professionalTitleValue === undefined ? null : professionalTitleValue,
      certificationList === null ? null : JSON.stringify(certificationList),
      specialtyList === null ? null : JSON.stringify(specialtyList),
      publicProfileValue,
      directMessagingValue,
    ];

    if (instagramValue !== undefined) {
      profileSets.push('instagramPage = ?');
      profileParams.push(instagramValue);
    }
    if (telValue !== undefined) {
      profileSets.push('tel = ?');
      profileParams.push(telValue || null);
    }
    if (villeValue !== undefined) {
      profileSets.push('ville = ?');
      profileParams.push(villeValue || null);
    }

    profileParams.push(coachID);

    await conn.query(
      `UPDATE coachprofiles SET ${profileSets.join(', ')} WHERE userID = ?`,
      profileParams
    );

    await conn.commit();
    res.json({ message: 'Profile updated.' });
  } catch (err) {
    await conn.rollback();
    // Duplicate email unique index fallback.
    if (err && (err.code === 'ER_DUP_ENTRY' || String(err.message).includes('Duplicate'))) {
      return res.status(409).json({ message: 'This email is already used by another account.' });
    }
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
    if (!user) return res.status(404).json({ message: 'User not found.' });
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
