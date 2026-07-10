import express from 'express';
const router = express.Router();
import db from '../../config/db.js';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';

const JWT_SECRET = process.env.JWT_SECRET || 'fitlek_secret';

// ─────────────────────────────────────────────────────────────────────
// POST /auth/register - Enregistre nouvel utilisateur + crée profil si nécessaire
// ─────────────────────────────────────────────────────────────────────
router.post('/register', async (req, res) => {
  try {
    const { firstName, lastName, email, password, gender, role = 'client', advisorID } = req.body;
    
    // Validation des champs obligatoires
    if (!firstName || !lastName || !email || !password || !gender) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Vérifier si l'email existe déjà
    const [existing] = await db.query('SELECT id FROM users WHERE email = ?', [email]);
    if (existing.length) {
      return res.status(409).json({ error: 'Email already registered' });
    }

    // Hasher le mot de passe
    const passwordHash = await bcrypt.hash(password, 12);
    
    // Créer l'utilisateur
    const [result] = await db.query(
      'INSERT INTO users (firstName, lastName, email, passwordHash, gender, role) VALUES (?,?,?,?,?,?)',
      [firstName, lastName, email, passwordHash, gender, role]
    );
    const userID = result.insertId;

    // ─────────────────────────────────────────────────────────────────
    // ✨ NOUVEAU : Auto-créer le profil Advisor avec profil vide
    // ─────────────────────────────────────────────────────────────────
    if (role === 'advisor') {
      try {
        await db.query(
          'INSERT INTO advisorprofiles (userID, specialty) VALUES (?,?)',
          [userID, 'À compléter']
        );
      } catch (err) {
        console.error('Failed to create advisor profile:', err);
        // Non-fatal, continue
      }
    }

    // ─────────────────────────────────────────────────────────────────
    // ✨ NOUVEAU : Auto-créer le profil Coach AVEC advisorID si fourni
    // ─────────────────────────────────────────────────────────────────
    if (role === 'coach') {
      try {
        const invCode = crypto.randomBytes(6).toString('hex').toUpperCase();
        
        // ✅ Passer advisorID (peut être null ou un nombre)
        const coach_advisorID = advisorID || null;
        
        await db.query(
          'INSERT INTO coachprofiles (userID, bio, instagramPage, certificateUrl, invitationCode, advisorID) VALUES (?,?,?,?,?,?)',
          [userID, '', '', '', invCode, coach_advisorID]
        );
      } catch (err) {
        console.error('Failed to create coach profile:', err);
        // Non-fatal, continue
      }
    }

    res.status(201).json({ message: 'User created', userID });
  } catch (err) { 
    res.status(500).json({ error: err.message }); 
  }
});

// ─────────────────────────────────────────────────────────────────────
// POST /auth/login - Authentification utilisateur
// ─────────────────────────────────────────────────────────────────────
router.post('/login', async (req, res) => {
  try {
    const { email, password, deviceInfo } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }

    const [rows] = await db.query('SELECT * FROM users WHERE email = ?', [email]);
    if (!rows.length) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = rows[0];
    
    // Vérifier le mot de passe
    if (!await bcrypt.compare(password, user.passwordHash)) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Vérifier si l'utilisateur est banni
    const [bans] = await db.query(
      `SELECT id FROM bans WHERE userID=? AND isActive=1
       AND (banType='permanent' OR expiresAt > NOW())`,
      [user.id]
    );
    if (bans.length) {
      return res.status(403).json({ error: 'Account is banned' });
    }

    // Créer les tokens
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

// ─────────────────────────────────────────────────────────────────────
// POST /auth/refresh - Rafraîchit le token d'accès
// ─────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────
// POST /auth/logout - Déconnexion
// ─────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────
// POST /auth/forgot-password - Demande de réinitialisation de mot de passe
// ─────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────
// POST /auth/reset-password - Réinitialise le mot de passe
// ─────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────
// POST /auth/sync-profiles - Crée les profils manquants (maintenance)
// Utile pour synchroniser les anciens utilisateurs
// ─────────────────────────────────────────────────────────────────────
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
        [advisor.id, 'À compléter']
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
        [coach.id, '', '', '', invCode, null]  // ← advisorID = null pour les anciens coaches
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
// ─── POST /auth/check-email ────────────────────────────────────────
// Vérifie si l'email existe (étape 1 simplifiée)
router.post('/check-email', async (req, res) => {
  try {
    const { email } = req.body;
    const [users] = await db.query('SELECT id FROM users WHERE email=?', [email]);
    res.json({ exists: users.length > 0 });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── POST /auth/reset-password-direct ──────────────────────────────
// Réinitialise directement sans token (étape 2 simplifiée)
router.post('/reset-password-direct', async (req, res) => {
  try {
    const { email, newPassword } = req.body;
    if (!email || !newPassword) {
      return res.status(400).json({ error: 'Email and password required' });
    }

    const [users] = await db.query('SELECT id FROM users WHERE email=?', [email]);
    if (!users.length) {
      return res.status(404).json({ error: 'User not found' });
    }

    const passwordHash = await bcrypt.hash(newPassword, 12);
    await db.query('UPDATE users SET passwordHash=? WHERE id=?', [passwordHash, users[0].id]);
    
    res.json({ message: 'Password updated successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
export default router;