import db from '../config/db.js';

export async function requirePremiumAccess(req, res, next) {
  // Always allow access for free version
  next();
}
