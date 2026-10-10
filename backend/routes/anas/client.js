import express from 'express';
const router = express.Router();
import db from '../../config/db.js';
import {ownIdentity} from '../../middleware/ownership.js';
import {requireRole} from '../../middleware/auth.js';
const canReadClient = async (req,res,next) => {
  const id=Number(req.params.id ?? req.params.clientID);
  if (id===Number(req.user.id) || ['manager','admin'].includes(req.user.role)) return next();
  if (req.user.role==='coach') {
    const [links]=await db.query('SELECT id FROM coachclients WHERE coachID=? AND clientID=?',[req.user.id,id]);
    if (links.length) return next();
  }
  return res.status(403).json({error:'Access denied.'});
};
router.get('/me', ownIdentity(), async (req, res) => {
  try {
    const userID = req.user.id;
    const [rows] = await db.query(
      'SELECT id, firstName, lastName, email, gender, avatarUrl, isPremium, isApproved, height, createdAt FROM users WHERE id=?',
      [userID]
    );
    if (!rows.length) return res.status(404).json({ error: 'Not found' });
    res.json(rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
});
// GET /reservations/client/:clientID/count
router.get('/client/:clientID/count', canReadClient, async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT COUNT(*) as count FROM reservations WHERE clientID=? AND coachID=?',
      [req.params.clientID, req.user.role==='coach'?req.user.id:req.query.coachID]
    );
    res.json({ count: rows[0].count });
  } catch (err) { res.status(500).json({ error: err.message }); }
});
router.put('/me', ownIdentity(), async (req, res) => {
  try {
    const { firstName, lastName, gender, avatarUrl, height } = req.body;
    const userID=req.user.id;
    await db.query(
      'UPDATE users SET firstName=?, lastName=?, gender=?, avatarUrl=?, height=? WHERE id=?',
      [firstName, lastName, gender, avatarUrl, height, userID]
    );
    res.json({ message: 'Profile updated' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.get('/:id', canReadClient, async (req, res) => {
  try {
    const requesterID = req.user.id;
    const [rows] = await db.query(
      `SELECT id, firstName, lastName, email, gender, avatarUrl, isPremium, isApproved, height, createdAt 
       FROM users 
       WHERE id=? AND role="client"
         AND id NOT IN (SELECT blockedID FROM user_blocks WHERE blockerID = ?)
         AND id NOT IN (SELECT blockerID FROM user_blocks WHERE blockedID = ?)`,
      [req.params.id, requesterID, requesterID]
    );
    if (!rows.length) return res.status(404).json({ error: 'Client not found' });
    res.json(rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.get('/', requireRole('coach','manager','admin'), async (req, res) => {
  try {
    const { page = 1, limit = 20, search } = req.query;
    const offset = (page - 1) * limit;
    const requesterID = req.user.id;
    let sql = `SELECT id, firstName, lastName, email, gender, isPremium, isApproved, height, createdAt 
               FROM users WHERE role="client"
                 AND id NOT IN (SELECT blockedID FROM user_blocks WHERE blockerID = ?)
                 AND id NOT IN (SELECT blockerID FROM user_blocks WHERE blockedID = ?)`;
    const params = [requesterID, requesterID];
    if(req.user.role==='coach'){sql+=' AND EXISTS(SELECT 1 FROM coachclients cc WHERE cc.clientID=users.id AND cc.coachID=?)';params.push(req.user.id);}
    if (search) {
      sql += ' AND (firstName LIKE ? OR lastName LIKE ? OR email LIKE ?)';
      params.push(`%${search}%`, `%${search}%`, `%${search}%`);
    }
    sql += ' ORDER BY createdAt DESC LIMIT ? OFFSET ?';
    params.push(Math.min(100,Math.max(1,Number(limit)||20)), Math.max(0,Number(offset)||0));
    const [rows] = await db.query(sql, params);
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

export default router;