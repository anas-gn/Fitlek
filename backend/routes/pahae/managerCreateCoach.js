import { Router } from 'express';
import bcrypt from 'bcrypt';
import multer from 'multer';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/jpg', 'application/pdf'];
    if (allowed.includes(file.mimetype)) cb(null, true);
    else cb(new Error('Only JPG, PNG or PDF files are allowed.'));
  },
});

function generateInvitationCode(userId) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let suffix = '';
  for (let i = 0; i < 5; i++) suffix += chars.charAt(Math.floor(Math.random() * chars.length));
  return `COACH-${userId}-${suffix}`;
}

router.post('/', requireAuth, requireRole('manager'), upload.single('certificate'), async (req, res) => {
  const { firstName, lastName, email, gender, bio, instagramPage } = req.body;
  if (!firstName || !lastName || !email || !gender || !bio || !instagramPage) {
    return res.status(400).json({ message: 'All fields are required.' });
  }
  if (!req.file) {
    return res.status(400).json({ message: 'Certificate file is required.' });
  }
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const [[existing]] = await conn.query('SELECT id FROM users WHERE email = ?', [email]);
    if (existing) { await conn.rollback(); return res.status(409).json({ message: 'Email already in use.' }); }
    const tempPassword = Math.random().toString(36).slice(-8);
    const passwordHash = await bcrypt.hash(tempPassword, 12);
    const [userResult] = await conn.query(
      `INSERT INTO users (firstName, lastName, email, passwordHash, role, gender, isApproved)
       VALUES (?, ?, ?, ?, 'coach', ?, 1)`,
      [firstName, lastName, email, passwordHash, gender]
    );
    const userId = userResult.insertId;
    const invitationCode = generateInvitationCode(userId);
    await conn.query(
      `INSERT INTO coachProfiles (userID, bio, instagramPage, certificateUrl, invitationCode)
       VALUES (?, ?, ?, ?, ?)`,
      [userId, bio, instagramPage, req.file.buffer, invitationCode]
    );
    await conn.commit();
    res.status(201).json({ id: userId, invitationCode, tempPassword, message: 'Coach created.' });
  } catch (err) {
    await conn.rollback();
    res.status(500).json({ message: err.message });
  } finally {
    conn.release();
  }
});

export default router;
