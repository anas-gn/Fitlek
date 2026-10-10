import jwt from 'jsonwebtoken';
import db from '../config/db.js';

// ─────────────────────────────────────────────────────────────────────
// Secret JWT - DOIT correspondre à celui de routes/anas/auth.js
// ─────────────────────────────────────────────────────────────────────
const JWT_SECRET = process.env.JWT_SECRET;

// ─────────────────────────────────────────────────────────────────────
// Middleware : Vérifier le token JWT
// ─────────────────────────────────────────────────────────────────────
export async function requireAuth(req, res, next) {
  const header = req.headers.authorization;

  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Missing or invalid token.' });
  }

  const token = header.split(' ')[1];

  let payload;
  try {
    payload = jwt.verify(token, JWT_SECRET);
    if (!Number.isSafeInteger(payload.id) || payload.id < 1) throw new Error('Invalid identity');
  } catch {
    return res.status(401).json({ message: 'Token expired or invalid.' });
  }
  let user;
  try {
    [[user]] = await db.query(`SELECT id,role,tokenVersion,
      EXISTS(SELECT 1 FROM bans WHERE userID=users.id AND isActive=1 AND (banType='permanent' OR expiresAt>NOW())) AS banned
      FROM users WHERE id=?`,[payload.id]);
  } catch {
    // Pool/protocol/time-out failures must not make the app discard a valid
    // signed-in account or its pending offline sets.
    return res.status(503).json({message: 'Authentication temporarily unavailable.'});
  }
  if (!user || user.banned || user.role !== payload.role || Number(payload.tokenVersion ?? 0) !== Number(user.tokenVersion)) {
    return res.status(401).json({message: 'Token expired or invalid.'});
  }
  req.user = {...payload, id: user.id, role: user.role};
  next();
}

// ─────────────────────────────────────────────────────────────────────
// Middleware : Vérifier le rôle de l'utilisateur
// ─────────────────────────────────────────────────────────────────────
export function requireRole(...roles) {
  return (req, res, next) => {
    if (!roles.includes(req.user?.role)) {
      return res.status(403).json({ message: 'Access denied.' });
    }
    next();
  };
}
