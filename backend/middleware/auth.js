import jwt from 'jsonwebtoken';

// ─────────────────────────────────────────────────────────────────────
// Secret JWT - DOIT correspondre à celui de routes/anas/auth.js
// ─────────────────────────────────────────────────────────────────────
const JWT_SECRET = process.env.JWT_SECRET || 'fitlek_secret';

// ─────────────────────────────────────────────────────────────────────
// Middleware : Vérifier le token JWT
// ─────────────────────────────────────────────────────────────────────
export function requireAuth(req, res, next) {
  const header = req.headers.authorization;

  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Missing or invalid token.' });
  }

  const token = header.split(' ')[1];

  try {
    const payload = jwt.verify(token, JWT_SECRET);
    req.user = payload;
    next();
  } catch {
    return res.status(401).json({ message: 'Token expired or invalid.' });
  }
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