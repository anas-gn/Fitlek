import express from 'express';
const router = express.Router();
import db from '../../config/db.js';
import bcrypt from 'bcrypt';
import admin from '../../config/firebase.js';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import { sendOTPEmail, resend } from '../../config/resend.js';
import { requireAuth } from '../../middleware/auth.js';

const JWT_SECRET = process.env.JWT_SECRET;

// Coach-to-Coach referral reward (backend-controlled â€” never sent by the client).
const REFERRAL_REWARD_POINTS = 40;

// Normalize a referral/invitation code the same way everywhere.
function normalizeReferralCode(raw) {
  return (raw ?? '').toString().trim().toUpperCase();
}

// Generate a unique coach invitation code (does not expose the DB id).
async function generateUniqueInvitationCode(conn) {
  for (let i = 0; i < 6; i++) {
    const code = crypto.randomBytes(6).toString('hex').toUpperCase();
    const [dup] = await conn.query(
      'SELECT id FROM coachprofiles WHERE invitationCode = ? LIMIT 1',
      [code]
    );
    if (!dup.length) return code;
  }
  // Extremely unlikely fallback: longer token.
  return crypto.randomBytes(9).toString('hex').toUpperCase();
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// GET /auth/validate-referral?code=XXXX
// Public, minimal-info check used for live feedback during Coach signup.
// Reveals ONLY whether the code is a valid coach referral code.
// Final/authoritative validation still happens inside /auth/register.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
router.get('/validate-referral', async (req, res) => {
  try {
    const code = normalizeReferralCode(req.query.code);
    if (!code) return res.json({ valid: false });
    const [rows] = await db.query(
      `SELECT cp.userID
       FROM coachprofiles cp
       JOIN users u ON u.id = cp.userID
       WHERE cp.invitationCode = ? AND u.role = 'coach'
       LIMIT 1`,
      [code]
    );
    res.json({ valid: rows.length > 0 });
  } catch (err) {
    res.status(500).json({ error: 'Validation failed' });
  }
});

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// POST /auth/register - Enregistre nouvel utilisateur + crÃ©e profil si nÃ©cessaire
// Optional coach-to-coach referral: when a new COACH provides a valid
// `referralCode`, the inviting coach earns REFERRAL_REWARD_POINTS exactly once.
// The whole operation is atomic.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
router.post('/register', async (req, res) => {
  const { firstName, lastName, email, password, gender, role = 'client', advisorID, acceptedTerms, termsAccepted } = req.body;

  // Validation des champs obligatoires
  if (!firstName || !lastName || !email || !password || !gender) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  const isAccepted = acceptedTerms === true || acceptedTerms === 'true' || acceptedTerms === 1 || termsAccepted === true || termsAccepted === 1;
  if (!isAccepted) {
    return res.status(400).json({ error: 'You must review and accept the Sirvya Terms of Service & Legal Framework to sign up.' });
  }

  // Referral code only applies to coach registrations.
  const referralCode = role === 'coach' ? normalizeReferralCode(req.body.referralCode) : '';

  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();

    // Check if email OTP was verified
    const [verifiedOTP] = await conn.query(
      `SELECT id FROM otp_verifications WHERE LOWER(email) = LOWER(?) AND type = 'signup' AND isVerified = 1 AND createdAt > DATE_SUB(NOW(), INTERVAL 30 MINUTE) LIMIT 1`,
      [email]
    );
    if (!verifiedOTP.length) {
      await conn.rollback();
      return res.status(400).json({ error: 'Please verify your email address with the OTP code sent to your email.' });
    }

    // VÃ©rifier si l'email existe dÃ©jÃ 
    const [existing] = await conn.query('SELECT id FROM users WHERE email = ?', [email]);

    if (existing.length) {
      await conn.rollback();
      return res.status(409).json({ error: 'Email already registered' });
    }
    // Authoritatively validate the referral code BEFORE creating anything.
    let inviterCoachID = null;
    if (referralCode) {
      const [inviterRows] = await conn.query(
        `SELECT cp.userID AS inviterID
         FROM coachprofiles cp
         JOIN users u ON u.id = cp.userID
         WHERE cp.invitationCode = ? AND u.role = 'coach'
         LIMIT 1`,
        [referralCode]
      );
      if (!inviterRows.length) {
        await conn.rollback();
        return res.status(400).json({ error: 'This invitation code is invalid.' });
      }
      inviterCoachID = inviterRows[0].inviterID;
    }

    // Hasher le mot de passe
    const passwordHash = await bcrypt.hash(password, 12);

    // CrÃ©er l'utilisateur avec validation des conditions d'utilisation
    const [result] = await conn.query(
      'INSERT INTO users (firstName, lastName, email, passwordHash, gender, role, termsAccepted, termsAcceptedAt) VALUES (?,?,?,?,?,?,1,NOW())',
      [firstName, lastName, email, passwordHash, gender, role]
    );
    const userID = result.insertId;

    // Auto-crÃ©er le profil Advisor avec profil vide
    if (role === 'advisor') {
      await conn.query(
        'INSERT INTO advisorprofiles (userID, specialty) VALUES (?,?)',
        [userID, 'Ã€ complÃ©ter']
      );
    }

    // Auto-crÃ©er le profil Coach (code unique) + Ã©ventuel referral
    if (role === 'coach') {
      const invCode = await generateUniqueInvitationCode(conn);
      const coach_advisorID = advisorID || null;
      await conn.query(
        'INSERT INTO coachprofiles (userID, bio, instagramPage, certificateUrl, invitationCode, advisorID) VALUES (?,?,?,?,?,?)',
        [userID, '', '', '', invCode, coach_advisorID]
      );

      if (inviterCoachID) {
        // Durable once-only guard: UNIQUE(invitedCoachID) on coachreferrals.
        await conn.query(
          'INSERT INTO coachreferrals (inviterCoachID, invitedCoachID, invitationCode, pointsAwarded) VALUES (?,?,?,?)',
          [inviterCoachID, userID, referralCode, REFERRAL_REWARD_POINTS]
        );
        // Reward amount is decided here, not by the client.
        await conn.query(
          'UPDATE coachprofiles SET earnedPoints = earnedPoints + ?, totalInvitations = totalInvitations + 1 WHERE userID = ?',
          [REFERRAL_REWARD_POINTS, inviterCoachID]
        );
      }
    }

    await conn.commit();
    res.status(201).json({ message: 'User created', userID });
  } catch (err) {
    await conn.rollback();
    if (err && err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ error: 'This referral has already been recorded.' });
    }
    res.status(500).json({ error: err.message });
  } finally {
    conn.release();
  }
});

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// POST /auth/login - Authentification utilisateur
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
router.post('/login', async (req, res) => {
  try {
    const { email, password, deviceInfo } = req.body;
// Debug login for development
if (email === "debug@debug.com" && password === "debug") {
  const userID = 1;
  const [rows] = await db.query("SELECT * FROM users WHERE id = ?", [userID]);
  let user;
  if (rows.length) {
    user = rows[0];
  } else {
    // Fallback user data
    user = {
      id: userID,
      firstName: "Debug",
      lastName: "User",
      email: email,
      role: "client",
      avatarUrl: null,
      isPremium: false,
      isApproved: true
    };
  }
  // Detect Google-only accounts that have no password set
  if (!user.passwordHash && user.authProvider === "google") {
    return res.status(403).json({
      error: "This account was created with Google Sign-In. Please use the Google button to log in, or set a password first.",
      authProvider: "google",
    });
  }
  // VÃ©rifier si l'utilisateur est banni
  const [bans] = await db.query(
    `SELECT id FROM bans WHERE userID=? AND isActive=1
     AND (banType='permanent' OR expiresAt > NOW())`,
    [user.id]
  );
  if (bans.length) {
    return res.status(403).json({ error: "Account is banned" });
  }
  // CrÃ©er les tokens
  const accessToken = jwt.sign({ id: user.id, role: user.role }, JWT_SECRET, { expiresIn: "7d" });
  const refreshToken = crypto.randomBytes(64).toString("hex");
  const expiresAt = new Date(Date.now() + 30 * 86400000);
  await db.query(
    "INSERT INTO authtokens (userID, refreshToken, deviceInfo, expiresAt) VALUES (?,?,?,?)",
    [user.id, refreshToken, deviceInfo || null, expiresAt]
  );
  return res.json({
    accessToken,
    refreshToken,
    user: {
      id: user.id,
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      role: user.role,
      avatarUrl: user.avatarUrl,
      isPremium: user.isPremium,
      isApproved: user.isApproved,
    },
  });
}
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }

    const [rows] = await db.query(
      'SELECT * FROM users WHERE LOWER(email) = LOWER(?) LIMIT 1',
      [String(email).trim()]
    );
    if (!rows.length) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = rows[0];

    // Detect Google-only accounts that have no password set
    if (!user.passwordHash && user.authProvider === 'google') {
      return res.status(403).json({
        error: 'This account was created with Google Sign-In. Please use the Google button to log in, or set a password first.',
        authProvider: 'google',
      });
    }

    // VÃ©rifier le mot de passe
    if (!user.passwordHash || !await bcrypt.compare(password, user.passwordHash)) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // VÃ©rifier si l'utilisateur est banni
    const [bans] = await db.query(
      `SELECT id FROM bans WHERE userID=? AND isActive=1
       AND (banType='permanent' OR expiresAt > NOW())`,
      [user.id]
    );
    if (bans.length) {
      return res.status(403).json({ error: 'Account is banned' });
    }

    // CrÃ©er les tokens
    const accessToken = jwt.sign({ id: user.id, role: user.role }, JWT_SECRET, { expiresIn: '7d' });
    const refreshToken = crypto.randomBytes(64).toString('hex');
    const expiresAt = new Date(Date.now() + 30 * 86400000);

    await db.query(
      'INSERT INTO authtokens (userID, refreshToken, deviceInfo, expiresAt) VALUES (?,?,?,?)',
      [user.id, refreshToken, deviceInfo || null, expiresAt]
    );

    res.json({
      accessToken,
      refreshToken,
      user: {
        id: user.id,
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        role: user.role,
        avatarUrl: user.avatarUrl,
        isPremium: user.isPremium,
        isApproved: user.isApproved,
      },
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// POST /auth/refresh - RafraÃ®chit le token d'accÃ¨s
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
router.post('/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ error: 'Refresh token required' });
    }

    const [rows] = await db.query(
      'SELECT * FROM authtokens WHERE refreshToken=? AND revokedAt IS NULL AND expiresAt > NOW()',
      [refreshToken]
    );
    if (!rows.length) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }

    const [users] = await db.query('SELECT id, role FROM users WHERE id=?', [rows[0].userID]);
    if (!users.length) {
      return res.status(401).json({ error: 'User not found' });
    }

    const accessToken = jwt.sign({ id: users[0].id, role: users[0].role }, JWT_SECRET, { expiresIn: '7d' });
    res.json({ accessToken });
  } catch (err) { 
    res.status(500).json({ error: err.message }); 
  }
});

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// POST /auth/logout - DÃ©connexion
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
router.post('/logout', async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ error: 'Refresh token required' });
    }
    
    await db.query('UPDATE authtokens SET revokedAt=NOW() WHERE refreshToken=?', [refreshToken]);
    res.json({ message: 'Logged out' });
  } catch (err) { 
    res.status(500).json({ error: err.message }); 
  }
});

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// POST /auth/forgot-password - Demande de rÃ©initialisation de mot de passe
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;
    const [users] = await db.query('SELECT id FROM users WHERE email=?', [email]);
    if (!users.length) {
      return res.json({ message: 'If the email exists, a reset link was sent' });
    }

    const token = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 3600000);
    await db.query(
      'INSERT INTO passwordresettokens (userID, token, expiresAt) VALUES (?,?,?)',
      [users[0].id, token, expiresAt]
    );
    // TODO: send email with reset link
    res.json({ message: 'Reset link sent', _devToken: token });
  } catch (err) { 
    res.status(500).json({ error: err.message }); 
  }
});

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// POST /auth/reset-password - RÃ©initialise le mot de passe
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
router.post('/reset-password', async (req, res) => {
  try {
    const { token, newPassword } = req.body;
    if (!token || !newPassword) {
      return res.status(400).json({ error: 'Token and password required' });
    }

    const [rows] = await db.query(
      'SELECT * FROM passwordresettokens WHERE token=? AND usedAt IS NULL AND expiresAt > NOW()',
      [token]
    );
    if (!rows.length) {
      return res.status(400).json({ error: 'Invalid or expired token' });
    }

    const passwordHash = await bcrypt.hash(newPassword, 12);
    await db.query('UPDATE users SET passwordHash=? WHERE id=?', [passwordHash, rows[0].userID]);
    await db.query('UPDATE passwordresettokens SET usedAt=NOW() WHERE id=?', [rows[0].id]);
    res.json({ message: 'Password reset successfully' });
  } catch (err) { 
    res.status(500).json({ error: err.message }); 
  }
});

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// POST /auth/sync-profiles - CrÃ©e les profils manquants (maintenance)
// Utile pour synchroniser les anciens utilisateurs
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
router.post('/sync-profiles', async (req, res) => {
  try {
    // Trouvez les advisors sans profil
    const [advisorsNoProfile] = await db.query(
      `SELECT u.id FROM users u
       LEFT JOIN advisorprofiles ap ON ap.userID = u.id
       WHERE u.role='advisor' AND ap.id IS NULL`
    );

    for (const advisor of advisorsNoProfile) {
      await db.query(
        'INSERT INTO advisorprofiles (userID, specialty) VALUES (?,?)',
        [advisor.id, 'Ã€ complÃ©ter']
      ).catch(err => console.error(`Failed to sync advisor ${advisor.id}:`, err));
    }

    // Trouvez les coaches sans profil
    const [coachesNoProfile] = await db.query(
      `SELECT u.id FROM users u
       LEFT JOIN coachprofiles cp ON cp.userID = u.id
       WHERE u.role='coach' AND cp.id IS NULL`
    );

    for (const coach of coachesNoProfile) {
      const invCode = crypto.randomBytes(6).toString('hex').toUpperCase();
      await db.query(
        'INSERT INTO coachprofiles (userID, bio, instagramPage, certificateUrl, invitationCode, advisorID) VALUES (?,?,?,?,?,?)',
        [coach.id, '', '', '', invCode, null]  // â† advisorID = null pour les anciens coaches
      ).catch(err => console.error(`Failed to sync coach ${coach.id}:`, err));
    }

    res.json({
      message: 'Sync completed',
      advisorsSynced: advisorsNoProfile.length,
      coachesSynced: coachesNoProfile.length,
    });
  } catch (err) { 
    res.status(500).json({ error: err.message }); 
  }
});
// â”€â”€â”€ OTP ROUTES (SIGN UP & FORGOT PASSWORD) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

// Generate 6-digit numeric OTP
function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// 1. POST /auth/send-signup-otp
router.post('/send-signup-otp', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ error: 'Email is required' });

    const normalizedEmail = email.trim().toLowerCase();

    // Check if email already registered
    const [users] = await db.query('SELECT id FROM users WHERE LOWER(email) = ?', [normalizedEmail]);
    if (users.length) {
      return res.status(409).json({ error: 'This email is already registered.' });
    }

    const otp = generateOTP();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Store in DB
    await db.query(
      'INSERT INTO otp_verifications (email, otp, type, expiresAt) VALUES (?, ?, "signup", ?)',
      [normalizedEmail, otp, expiresAt]
    );

    // Send email via Resend
    await sendOTPEmail({ to: normalizedEmail, otp, type: 'signup' });

    res.json({ message: 'Verification code sent to your email.' });
  } catch (err) {
    console.error('send-signup-otp error:', err);
    res.status(500).json({ error: 'Failed to send verification email. ' + (err.message || '') });
  }
});

// 2. POST /auth/verify-signup-otp
router.post('/verify-signup-otp', async (req, res) => {
  try {
    const { email, otp } = req.body;
    if (!email || !otp) return res.status(400).json({ error: 'Email and OTP code are required' });

    const normalizedEmail = email.trim().toLowerCase();
    const cleanOTP = otp.toString().trim();

    const [rows] = await db.query(
      `SELECT id FROM otp_verifications
       WHERE LOWER(email) = ? AND otp = ? AND type = 'signup' AND isVerified = 0 AND expiresAt > NOW()
       ORDER BY id DESC LIMIT 1`,
      [normalizedEmail, cleanOTP]
    );

    if (!rows.length) {
      return res.status(400).json({ error: 'Invalid or expired verification code.' });
    }

    await db.query('UPDATE otp_verifications SET isVerified = 1 WHERE id = ?', [rows[0].id]);
    res.json({ verified: true, message: 'Email verified successfully.' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 3. POST /auth/send-forgot-otp
router.post('/send-forgot-otp', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ error: 'Email is required' });

    const normalizedEmail = email.trim().toLowerCase();

    // Check if user exists
    const [users] = await db.query('SELECT id FROM users WHERE LOWER(email) = ?', [normalizedEmail]);
    if (!users.length) {
      return res.status(404).json({ error: 'No account found with this email address.' });
    }

    const otp = generateOTP();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    await db.query(
      'INSERT INTO otp_verifications (email, otp, type, expiresAt) VALUES (?, ?, "forgot_password", ?)',
      [normalizedEmail, otp, expiresAt]
    );

    await sendOTPEmail({ to: normalizedEmail, otp, type: 'forgot_password' });

    res.json({ message: 'Password reset code sent to your email.' });
  } catch (err) {
    console.error('send-forgot-otp error:', err);
    res.status(500).json({ error: 'Failed to send password reset email. ' + (err.message || '') });
  }
});

// 4. POST /auth/verify-forgot-otp
router.post('/verify-forgot-otp', async (req, res) => {
  try {
    const { email, otp } = req.body;
    if (!email || !otp) return res.status(400).json({ error: 'Email and OTP code are required' });

    const normalizedEmail = email.trim().toLowerCase();
    const cleanOTP = otp.toString().trim();

    const [rows] = await db.query(
      `SELECT id FROM otp_verifications
       WHERE LOWER(email) = ? AND otp = ? AND type = 'forgot_password' AND isVerified = 0 AND expiresAt > NOW()
       ORDER BY id DESC LIMIT 1`,
      [normalizedEmail, cleanOTP]
    );

    if (!rows.length) {
      return res.status(400).json({ error: 'Invalid or expired verification code.' });
    }

    await db.query('UPDATE otp_verifications SET isVerified = 1 WHERE id = ?', [rows[0].id]);
    res.json({ verified: true, message: 'Code verified successfully.' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 5. POST /auth/reset-password-otp
router.post('/reset-password-otp', async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body;
    if (!email || !newPassword) {
      return res.status(400).json({ error: 'Email and new password are required' });
    }

    const normalizedEmail = email.trim().toLowerCase();

    // Verify OTP was validated
    const [rows] = await db.query(
      `SELECT id FROM otp_verifications
       WHERE LOWER(email) = ? AND type = 'forgot_password' AND isVerified = 1 AND createdAt > DATE_SUB(NOW(), INTERVAL 30 MINUTE)
       ORDER BY id DESC LIMIT 1`,
      [normalizedEmail]
    );

    if (!rows.length) {
      return res.status(400).json({ error: 'Verification session expired. Please request a new code.' });
    }

    const [users] = await db.query('SELECT id FROM users WHERE LOWER(email) = ?', [normalizedEmail]);
    if (!users.length) {
      return res.status(404).json({ error: 'User not found.' });
    }

    const passwordHash = await bcrypt.hash(newPassword, 12);
    await db.query('UPDATE users SET passwordHash = ? WHERE id = ?', [passwordHash, users[0].id]);

    res.json({ message: 'Password updated successfully.' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 6. POST /auth/fcm-token
router.post('/fcm-token', requireAuth, async (req, res) => {
  try {
    const { token } = req.body;
    if (!token) return res.status(400).json({ error: 'Token is required' });

    await db.query(
      'UPDATE users SET fcmToken = ? WHERE id = ?',
      [token, req.user.id]
    );

    res.json({ success: true, message: 'FCM Token updated successfully.' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// POST /auth/google - Google Sign-In / Sign-Up (unified)
// Accepts idTokens from all registered OAuth clients (Android, Web, Server).
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
router.post('/google', async (req, res) => {
  const { idToken, role: requestedRole = 'client', referralCode, firstName: reqFirstName, lastName: reqLastName } = req.body;

  if (!idToken) {
    return res.status(400).json({ error: 'idToken is required' });
  }

  // Verify the Firebase ID Token using Firebase Admin SDK
  // Works natively on Web (firebase_auth) and Mobile (firebase_auth + google_sign_in)
  let decodedToken;
  try {
    decodedToken = await admin.auth().verifyIdToken(idToken);
  } catch (err) {
    console.error('Firebase token verification failed:', err.message);
    return res.status(401).json({ error: 'Invalid or expired Google token. Please try again.' });
  }

  if (!decodedToken.email_verified) {
    return res.status(401).json({ error: 'Your Google account email is not verified.' });
  }

  const email = (decodedToken.email || '').toLowerCase();
  const googleId = decodedToken.uid;
  const firstName = decodedToken.name ? decodedToken.name.split(' ')[0] : (reqFirstName || '');
  const lastName = decodedToken.name ? decodedToken.name.split(' ').slice(1).join(' ') : (reqLastName || '');
  const avatarUrl = decodedToken.picture || null;

  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();

    // â”€â”€ 1. Look up existing user by googleId OR email â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    let [rows] = await conn.query(
      'SELECT * FROM users WHERE googleId = ? OR LOWER(email) = ? LIMIT 1',
      [googleId, email]
    );
    let user = rows[0];
    let isNewUser = false;

    if (user) {
      // â”€â”€ 2a. Existing user: check ban â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      const [bans] = await conn.query(
        `SELECT id FROM bans WHERE userID=? AND isActive=1
         AND (banType='permanent' OR expiresAt > NOW()) LIMIT 1`,
        [user.id]
      );
      if (bans.length) {
        await conn.rollback();
        return res.status(403).json({ error: 'This account has been suspended.' });
      }

      // â”€â”€ 2b. Link Google ID to existing email+password account â”€â”€â”€â”€â”€â”€â”€â”€â”€
      const updates = [];
      const params = [];
      if (!user.googleId) { updates.push('googleId = ?'); params.push(googleId); }
      // Update avatar if they didn't set one manually
      if (!user.avatarUrl && avatarUrl) { updates.push('avatarUrl = ?'); params.push(avatarUrl); }
      // Mark authProvider as 'both' if they had a password already
      if (user.passwordHash && user.authProvider !== 'both') {
        updates.push("authProvider = 'both'");
      } else if (!user.passwordHash && user.authProvider !== 'google') {
        updates.push("authProvider = 'google'");
      }
      if (updates.length) {
        params.push(user.id);
        await conn.query(`UPDATE users SET ${updates.join(', ')} WHERE id = ?`, params);
        // Re-fetch updated user
        [[user]] = await conn.query('SELECT * FROM users WHERE id = ?', [user.id]);
      }
    } else {
      // â”€â”€ 3. New user: create account â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      isNewUser = true;
      const safeRole = ['client', 'coach'].includes(requestedRole) ? requestedRole : 'client';

      // For coaches, validate referral code if provided
      let inviterCoachID = null;
      const normalizedReferral = normalizeReferralCode(referralCode);
      if (safeRole === 'coach' && normalizedReferral) {
        const [inviterRows] = await conn.query(
          `SELECT cp.userID AS inviterID FROM coachprofiles cp
           JOIN users u ON u.id = cp.userID
           WHERE cp.invitationCode = ? AND u.role = 'coach' LIMIT 1`,
          [normalizedReferral]
        );
        if (!inviterRows.length) {
          await conn.rollback();
          return res.status(400).json({ error: 'This invitation code is invalid.' });
        }
        inviterCoachID = inviterRows[0].inviterID;
      }

      const [result] = await conn.query(
        `INSERT INTO users (firstName, lastName, email, passwordHash, googleId, authProvider, role, avatarUrl, isApproved, termsAccepted, termsAcceptedAt)
         VALUES (?, ?, ?, NULL, ?, 'google', ?, ?, 1, 1, NOW())`,
        [firstName, lastName, email, googleId, safeRole, avatarUrl]
      );
      const userID = result.insertId;

      // Create role-specific profile
      if (safeRole === 'coach') {
        const invCode = await generateUniqueInvitationCode(conn);
        await conn.query(
          'INSERT INTO coachprofiles (userID, bio, instagramPage, certificateUrl, invitationCode) VALUES (?,?,?,?,?)',
          [userID, '', '', '', invCode]
        );
        if (inviterCoachID) {
          await conn.query(
            'INSERT INTO coachreferrals (inviterCoachID, invitedCoachID, invitationCode, pointsAwarded) VALUES (?,?,?,?)',
            [inviterCoachID, userID, normalizedReferral, REFERRAL_REWARD_POINTS]
          );
          await conn.query(
            'UPDATE coachprofiles SET earnedPoints = earnedPoints + ?, totalInvitations = totalInvitations + 1 WHERE userID = ?',
            [REFERRAL_REWARD_POINTS, inviterCoachID]
          );
        }
      }

      [[user]] = await conn.query('SELECT * FROM users WHERE id = ?', [userID]);
    }

    await conn.commit();

    // â”€â”€ 4. Generate JWT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    const accessToken = jwt.sign(
      { id: user.id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    return res.status(200).json({
      accessToken,
      isNewUser,
      hasPassword: !!user.passwordHash,
      user: {
        id: user.id,
        role: user.role,
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        avatarUrl: user.avatarUrl,
        isApproved: user.isApproved,
        isPremium: user.isPremium,
      },
    });
  } catch (err) {
    await conn.rollback();
    console.error('Google auth error:', err);
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ error: 'An account with this email already exists.' });
    }
    return res.status(500).json({ error: 'Authentication failed: ' + err.message });
  } finally {
    conn.release();
  }
});

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// POST /auth/set-password
// Allows a Google-authenticated user to set a password for email login.
// Requires a valid JWT (the user must be logged in via Google first).
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
router.post('/set-password', requireAuth, async (req, res) => {
  try {
    const { password } = req.body;
    if (!password || password.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters.' });
    }

    const [rows] = await db.query('SELECT id, passwordHash, authProvider FROM users WHERE id = ?', [req.user.id]);
    if (!rows.length) {
      return res.status(404).json({ error: 'User not found.' });
    }

    const passwordHash = await bcrypt.hash(password, 12);
    await db.query(
      "UPDATE users SET passwordHash = ?, authProvider = 'both' WHERE id = ?",
      [passwordHash, req.user.id]
    );
    const { token } = req.body;
    if (!token) return res.status(400).json({ error: 'Token is required' });

    await db.query(
      'UPDATE users SET fcmToken = ? WHERE id = ?',
      [token, req.user.id]
    );

    res.json({ success: true, message: 'FCM Token updated successfully.' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
// ————————————————————————————————————————————————————————————————————————————————————————
// POST /auth/google - Google Sign-In / Sign-Up (unified)
// Accepts idTokens from all registered OAuth clients (Android, Web, Server).
// ————————————————————————————————————————————————————————————————————————————————————————
router.post('/google', async (req, res) => {
  const { idToken, role: requestedRole = 'client', referralCode, firstName: reqFirstName, lastName: reqLastName } = req.body;

  if (!idToken) {
    return res.status(400).json({ error: 'idToken is required' });
  }

  // Verify the Firebase ID Token using Firebase Admin SDK
  // Works natively on Web (firebase_auth) and Mobile (firebase_auth + google_sign_in)
  let decodedToken;
  try {
    decodedToken = await admin.auth().verifyIdToken(idToken);
  } catch (err) {
    console.error('Firebase token verification failed:', err.message);
    return res.status(401).json({ error: 'Invalid or expired Google token. Please try again.' });
  }

  if (!decodedToken.email_verified) {
    return res.status(401).json({ error: 'Your Google account email is not verified.' });
  }

  const email = (decodedToken.email || '').toLowerCase();
  const googleId = decodedToken.uid;
  const firstName = decodedToken.name ? decodedToken.name.split(' ')[0] : (reqFirstName || '');
  const lastName = decodedToken.name ? decodedToken.name.split(' ').slice(1).join(' ') : (reqLastName || '');
  const avatarUrl = decodedToken.picture || null;

  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();

    // ——— 1. Look up existing user by googleId OR email ————————————————————
    let [rows] = await conn.query(
      'SELECT * FROM users WHERE googleId = ? OR LOWER(email) = ? LIMIT 1',
      [googleId, email]
    );
    let user = rows[0];
    let isNewUser = false;

    if (user) {
      // ——— 2a. Existing user: check ban ———————————————————————————————————————————
      const [bans] = await conn.query(
        `SELECT id FROM bans WHERE userID=? AND isActive=1
         AND (banType='permanent' OR expiresAt > NOW()) LIMIT 1`,
        [user.id]
      );
      if (bans.length) {
        await conn.rollback();
        return res.status(403).json({ error: 'This account has been suspended.' });
      }

      // ——— 2b. Link Google ID to existing email+password account —————————————
      const updates = [];
      const params = [];
      if (!user.googleId) { updates.push('googleId = ?'); params.push(googleId); }
      // Update avatar if they didn't set one manually
      if (!user.avatarUrl && avatarUrl) { updates.push('avatarUrl = ?'); params.push(avatarUrl); }
      // Mark authProvider as 'both' if they had a password already
      if (user.passwordHash && user.authProvider !== 'both') {
        updates.push("authProvider = 'both'");
      } else if (!user.passwordHash && user.authProvider !== 'google') {
        updates.push("authProvider = 'google'");
      }
      if (updates.length) {
        params.push(user.id);
        await conn.query(`UPDATE users SET ${updates.join(', ')} WHERE id = ?`, params);
        // Re-fetch updated user
        [[user]] = await conn.query('SELECT * FROM users WHERE id = ?', [user.id]);
      }
    } else {
      // ——— 3. New user: create account ————————————————————————————————————————————————
      isNewUser = true;
      const safeRole = ['client', 'coach'].includes(requestedRole) ? requestedRole : 'client';

      // For coaches, validate referral code if provided
      let inviterCoachID = null;
      const normalizedReferral = normalizeReferralCode(referralCode);
      if (safeRole === 'coach' && normalizedReferral) {
        const [inviterRows] = await conn.query(
          `SELECT cp.userID AS inviterID FROM coachprofiles cp
           JOIN users u ON u.id = cp.userID
           WHERE cp.invitationCode = ? AND u.role = 'coach' LIMIT 1`,
          [normalizedReferral]
        );
        if (!inviterRows.length) {
          await conn.rollback();
          return res.status(400).json({ error: 'This invitation code is invalid.' });
        }
        inviterCoachID = inviterRows[0].inviterID;
      }

      const [result] = await conn.query(
        `INSERT INTO users (firstName, lastName, email, passwordHash, googleId, authProvider, role, avatarUrl, isApproved, termsAccepted, termsAcceptedAt)
         VALUES (?, ?, ?, NULL, ?, 'google', ?, ?, 1, 1, NOW())`,
        [firstName, lastName, email, googleId, safeRole, avatarUrl]
      );
      const userID = result.insertId;

      // Create role-specific profile
      if (safeRole === 'coach') {
        const invCode = await generateUniqueInvitationCode(conn);
        await conn.query(
          'INSERT INTO coachprofiles (userID, bio, instagramPage, certificateUrl, invitationCode) VALUES (?,?,?,?,?)',
          [userID, '', '', '', invCode]
        );
        if (inviterCoachID) {
          await conn.query(
            'INSERT INTO coachreferrals (inviterCoachID, invitedCoachID, invitationCode, pointsAwarded) VALUES (?,?,?,?)',
            [inviterCoachID, userID, normalizedReferral, REFERRAL_REWARD_POINTS]
          );
          await conn.query(
            'UPDATE coachprofiles SET earnedPoints = earnedPoints + ?, totalInvitations = totalInvitations + 1 WHERE userID = ?',
            [REFERRAL_REWARD_POINTS, inviterCoachID]
          );
        }
      }

      [[user]] = await conn.query('SELECT * FROM users WHERE id = ?', [userID]);
    }

    await conn.commit();

    // ——— 4. Generate JWT —————————————————————————————————————————————————————————
    const accessToken = jwt.sign(
      { id: user.id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    return res.status(200).json({
      accessToken,
      isNewUser,
      hasPassword: !!user.passwordHash,
      user: {
        id: user.id,
        role: user.role,
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        avatarUrl: user.avatarUrl,
        isApproved: user.isApproved,
        isPremium: user.isPremium,
      },
    });
  } catch (err) {
    await conn.rollback();
    console.error('Google auth error:', err);
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ error: 'An account with this email already exists.' });
    }
    return res.status(500).json({ error: 'Authentication failed: ' + err.message });
  } finally {
    conn.release();
  }
});

// ————————————————————————————————————————————————————————————————————————————————————————
// POST /auth/set-password
// Allows a Google-authenticated user to set a password for email login.
// Requires a valid JWT (the user must be logged in via Google first).
// ————————————————————————————————————————————————————————————————————————————————————————
router.post('/set-password', requireAuth, async (req, res) => {
  try {
    const { password } = req.body;
    if (!password || password.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters.' });
    }

    const [rows] = await db.query('SELECT id, passwordHash, authProvider FROM users WHERE id = ?', [req.user.id]);
    if (!rows.length) {
      return res.status(404).json({ error: 'User not found.' });
    }

    const passwordHash = await bcrypt.hash(password, 12);
    await db.query(
      "UPDATE users SET passwordHash = ?, authProvider = 'both' WHERE id = ?",
      [passwordHash, req.user.id]
    );

    res.json({ message: 'Password set successfully. You can now log in with your email and password.' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Alias for Apple Sign-In
router.post('/apple', (req, res) => {
  // We reuse the /google logic because Apple tokens are also verified via Firebase Auth,
  // and they share the same schema (googleId maps to Firebase UID, authProvider maps to 'google' or 'both').
  return router.handle({ ...req, url: '/google', originalUrl: req.originalUrl.replace('/apple', '/google') }, res);
});

// ─────────────────────────────────────────────────────────────────────────────
// ACCOUNT DELETION FLOW
// Compliant with Apple App Store Review Guidelines §5.1.1 and Google Play
// User Data policy. The flow requires OTP confirmation via email and blocks
// deletion when the user has upcoming (pending/confirmed) reservations.
// ─────────────────────────────────────────────────────────────────────────────

// ── GET /auth/check-delete-eligibility ───────────────────────────────────────
// Returns { eligible: bool, reason?: string }
// Checks if the authenticated user has any pending or confirmed future bookings.
router.get('/check-delete-eligibility', requireAuth, async (req, res) => {
  try {
    const userID = req.user.id;
    const role   = req.user.role;

    let blocked = false;
    let reason  = null;

    if (role === 'client') {
      const [rows] = await db.query(
        `SELECT id FROM reservations
         WHERE clientID = ? AND status IN ('pending','confirmed')
           AND reservedDate >= CURDATE()
         LIMIT 1`,
        [userID]
      );
      if (rows.length) {
        blocked = true;
        reason  = 'You have upcoming sessions with a coach. Please cancel them before deleting your account.';
      }
    } else if (role === 'coach') {
      const [rows] = await db.query(
        `SELECT id FROM reservations
         WHERE coachID = ? AND status IN ('pending','confirmed')
           AND reservedDate >= CURDATE()
         LIMIT 1`,
        [userID]
      );
      if (rows.length) {
        blocked = true;
        reason  = 'You have upcoming bookings with clients. Please resolve all pending and confirmed sessions before deleting your account.';
      }
    }

    res.json({ eligible: !blocked, reason });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── POST /auth/request-delete-otp ────────────────────────────────────────────
// Sends a 6-digit OTP to the user's email. Blocks if there are upcoming bookings.
router.post('/request-delete-otp', requireAuth, async (req, res) => {
  try {
    const userID = req.user.id;
    const role   = req.user.role;

    // Fetch user email
    const [users] = await db.query('SELECT email FROM users WHERE id = ? LIMIT 1', [userID]);
    if (!users.length) return res.status(404).json({ error: 'User not found.' });
    const email = users[0].email;

    // Block if upcoming bookings exist
    let blocked = false;
    let blockReason = null;
    if (role === 'client') {
      const [rows] = await db.query(
        `SELECT id FROM reservations
         WHERE clientID = ? AND status IN ('pending','confirmed')
           AND reservedDate >= CURDATE() LIMIT 1`,
        [userID]
      );
      if (rows.length) { blocked = true; blockReason = 'You have upcoming sessions with a coach. Please cancel them before deleting your account.'; }
    } else if (role === 'coach') {
      const [rows] = await db.query(
        `SELECT id FROM reservations
         WHERE coachID = ? AND status IN ('pending','confirmed')
           AND reservedDate >= CURDATE() LIMIT 1`,
        [userID]
      );
      if (rows.length) { blocked = true; blockReason = 'You have upcoming bookings with clients. Please resolve all pending and confirmed sessions before deleting your account.'; }
    }

    if (blocked) {
      return res.status(409).json({ blocked: true, reason: blockReason });
    }

    const otp = generateOTP();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    await db.query(
      'INSERT INTO otp_verifications (email, otp, type, expiresAt) VALUES (?, ?, "account_deletion", ?)',
      [email.toLowerCase(), otp, expiresAt]
    );

    // Send OTP email with deletion-specific template
    const htmlContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: #0b1d28; margin: 0; padding: 40px 20px; color: #ffffff; }
          .card { max-width: 500px; margin: 0 auto; background-color: #122836; border-radius: 16px; border: 1px solid #1e3a4c; padding: 40px 30px; text-align: center; box-shadow: 0 10px 30px rgba(0,0,0,0.3); }
          .logo-container { margin-bottom: 24px; text-align: center; }
          .logo-img { height: 75px; width: auto; max-width: 240px; border: 0; display: inline-block; object-fit: contain; }
          h1 { font-size: 22px; font-weight: 800; color: #ffffff; margin-bottom: 12px; }
          p { font-size: 14px; color: #a0b3c6; line-height: 1.6; margin-bottom: 28px; }
          .otp-box { background: linear-gradient(135deg, #e53e3e 0%, #c53030 100%); color: #ffffff; font-size: 36px; font-weight: 900; letter-spacing: 8px; padding: 18px 24px; border-radius: 12px; display: inline-block; margin-bottom: 28px; }
          .warning-box { background: rgba(229,62,62,0.12); border: 1px solid rgba(229,62,62,0.3); border-radius: 10px; padding: 14px 18px; margin-bottom: 24px; font-size: 13px; color: #fc8181; text-align: left; }
          .footer { font-size: 12px; color: #5a738e; margin-top: 32px; border-top: 1px solid #1e3a4c; padding-top: 20px; }
        </style>
      </head>
      <body>
        <div class="card">
          <div class="logo-container">
            <img class="logo-img" src="https://raw.githubusercontent.com/anas-gn/Fitlek/main/assets/branding/logo_dark.png" alt="SIRVYA" />
          </div>
          <h1>Account Deletion Request</h1>
          <p>You requested to permanently delete your Sirvya account. Use the code below to confirm. This action <strong>cannot be undone</strong>.</p>
          <div class="warning-box">
            ⚠️ All your personal data, sessions, messages, and progress will be permanently erased. Some anonymised data may be retained for fraud prevention.
          </div>
          <div class="otp-box">${otp}</div>
          <p style="margin-bottom: 0;">This code expires in <strong>10 minutes</strong>. If you did NOT request this, please ignore this email — your account is safe.</p>
          <div class="footer">
            &copy; ${new Date().getFullYear()} DevUnivers (Morocco) - Sirvya Platform
          </div>
        </div>
      </body>
      </html>
    `;

    const SENDER_EMAIL = process.env.SENDER_EMAIL || 'Sirvya <noreply@devunivers.com>';
    await resend.emails.send({
      from: SENDER_EMAIL,
      to: [email],
      subject: `Your Sirvya Account Deletion Code: ${otp}`,
      html: htmlContent,
    });

    res.json({ message: 'A verification code has been sent to your email address.' });
  } catch (err) {
    console.error('request-delete-otp error:', err);
    res.status(500).json({ error: 'Failed to send verification email. ' + (err.message || '') });
  }
});

// ── POST /auth/confirm-delete-account ────────────────────────────────────────
// Verifies the OTP then permanently deletes the account.
// Retains an audit row in deleted_accounts (email hash + role) for fraud prevention.
router.post('/confirm-delete-account', requireAuth, async (req, res) => {
  const { otp } = req.body;
  if (!otp) return res.status(400).json({ error: 'Verification code is required.' });

  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();

    const userID = req.user.id;

    // Fetch user before deletion (need email + role for audit)
    const [users] = await conn.query('SELECT email, role FROM users WHERE id = ? LIMIT 1', [userID]);
    if (!users.length) {
      await conn.rollback();
      return res.status(404).json({ error: 'User not found.' });
    }
    const { email, role } = users[0];
    const normalizedEmail = email.toLowerCase();
    const cleanOTP = otp.toString().trim();

    // Verify OTP
    const [otpRows] = await conn.query(
      `SELECT id FROM otp_verifications
       WHERE LOWER(email) = ? AND otp = ? AND type = 'account_deletion'
         AND isVerified = 0 AND expiresAt > NOW()
       ORDER BY id DESC LIMIT 1`,
      [normalizedEmail, cleanOTP]
    );
    if (!otpRows.length) {
      await conn.rollback();
      return res.status(400).json({ error: 'Invalid or expired verification code. Please request a new one.' });
    }

    // Mark OTP as used
    await conn.query('UPDATE otp_verifications SET isVerified = 1 WHERE id = ?', [otpRows[0].id]);

    // Create SHA-256 hash of email for audit (not reversible)
    const emailHash = crypto.createHash('sha256').update(normalizedEmail).digest('hex');
    const clientIP  = req.headers['x-forwarded-for']?.split(',')[0]?.trim() || req.socket?.remoteAddress || null;

    // Insert audit row BEFORE deleting the user
    await conn.query(
      'INSERT INTO deleted_accounts (original_user_id, email_hash, role, deletion_ip) VALUES (?, ?, ?, ?)',
      [userID, emailHash, role, clientIP]
    );

    // Revoke all auth tokens
    await conn.query('UPDATE authtokens SET revokedAt = NOW() WHERE userID = ?', [userID]);

    // Delete the user — FK CASCADE removes all related data automatically:
    // profiles, reservations, messages, conversations, notifications, weight history, etc.
    await conn.query('DELETE FROM users WHERE id = ?', [userID]);

    await conn.commit();

    res.json({ deleted: true, message: 'Your account has been permanently deleted.' });
  } catch (err) {
    await conn.rollback();
    console.error('confirm-delete-account error:', err);
    res.status(500).json({ error: 'Failed to delete account. ' + (err.message || '') });
  } finally {
    conn.release();
  }
});

export default router;


