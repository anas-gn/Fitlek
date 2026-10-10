import {requireRole} from './auth.js';

export function ownIdentity(field = 'userID', roles = []) {
  return (req, res, next) => {
    if (roles.length && !roles.includes(req.user?.role)) return requireRole(...roles)(req,res,next);
    const supplied = req.query[field] ?? req.body?.[field];
    if (supplied != null && Number(supplied) !== Number(req.user.id)) return res.status(403).json({error: 'Access denied.'});
    next();
  };
}
