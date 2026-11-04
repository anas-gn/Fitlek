import express from 'express';
const router = express.Router();
import db from '../../config/db.js';
import { signupDetails } from '../../services/signupDetails.js';
const ownProfileColumns = 'id, firstName, lastName, email, phoneNumber, gender, avatarUrl, isPremium, isApproved, height, ville, interests, createdAt';
function ownClient(req, res) {
  if (req.user?.role !== 'client') { res.status(403).json({error: 'Client access required.'}); return false; }
  const supplied = req.method === 'GET' ? req.query.userID : req.body?.userID;
  if (supplied !== undefined && String(supplied) !== String(req.user.id)) {
    res.status(403).json({error: 'You can only access your own profile.'}); return false;
  }
  return true;
}
router.get('/me', async (req, res) => {
  try {
    if (!ownClient(req, res)) return;
    const userID = req.user.id;
    const [rows] = await db.query(
      `SELECT ${ownProfileColumns} FROM users WHERE id=? AND role='client'`,
      [userID]
    );
    if (!rows.length) return res.status(404).json({ error: 'Not found' });
    res.json(rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
});
// GET /reservations/client/:clientID/count
router.get('/client/:clientID/count', async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT COUNT(*) as count FROM reservations WHERE clientID=? AND coachID=?',
      [req.params.clientID, req.query.coachID]
    );
    res.json({ count: rows[0].count });
  } catch (err) { res.status(500).json({ error: err.message }); }
});
router.put('/me', async (req, res) => {
  try {
    if (!ownClient(req, res)) return;
    const input = req.body ?? {}, fields = [], values = [];
    const invalid = message => res.status(400).json({error: message});
    for (const key of ['firstName', 'lastName']) if (input[key] !== undefined) {
      if (typeof input[key] !== 'string' || !input[key].trim() || input[key].trim().length > 100) return invalid('Enter a valid first and last name.');
      fields.push(`${key}=?`); values.push(input[key].trim());
    }
    if (input.gender !== undefined) {
      if (!['Male','Female','Other'].includes(input.gender)) return invalid('Choose a valid gender.');
      fields.push('gender=?'); values.push(input.gender);
    }
    if (input.height !== undefined) {
      const height = input.height === null || input.height === '' ? null : Number(input.height);
      if (height !== null && (!Number.isFinite(height) || height <= 0 || height > 300)) return invalid('Enter a valid height in centimetres.');
      fields.push('height=?'); values.push(height);
    }
    for (const [key, max] of [['avatarUrl', 500], ['ville', 255]]) if (input[key] !== undefined) {
      if (input[key] !== null && (typeof input[key] !== 'string' || input[key].length > max)) return invalid('Invalid profile details.');
      fields.push(`${key}=?`); values.push(input[key]?.trim() || null);
    }
    if (input.interests !== undefined) {
      let interests;
      try { interests = signupDetails({interests: input.interests}).interests; }
      catch (error) { return invalid(error.message); }
      fields.push('interests=?'); values.push(JSON.stringify(interests));
    }
    if (!fields.length) return invalid('No profile changes provided.');
    await db.query(`UPDATE users SET ${fields.join(', ')} WHERE id=? AND role='client'`, [...values, req.user.id]);
    const [[profile]] = await db.query(`SELECT ${ownProfileColumns} FROM users WHERE id=? AND role='client'`, [req.user.id]);
    if (!profile) return res.status(404).json({error: 'Client not found.'});
    res.json({ message: 'Profile updated', profile });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.get('/:id', async (req, res) => {
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

router.get('/', async (req, res) => {
  try {
    const { page = 1, limit = 20, search } = req.query;
    const offset = (page - 1) * limit;
    const requesterID = req.user.id;
    let sql = `SELECT id, firstName, lastName, email, gender, isPremium, isApproved, height, createdAt 
               FROM users WHERE role="client"
                 AND id NOT IN (SELECT blockedID FROM user_blocks WHERE blockerID = ?)
                 AND id NOT IN (SELECT blockerID FROM user_blocks WHERE blockedID = ?)`;
    const params = [requesterID, requesterID];
    if (search) {
      sql += ' AND (firstName LIKE ? OR lastName LIKE ? OR email LIKE ?)';
      params.push(`%${search}%`, `%${search}%`, `%${search}%`);
    }
    sql += ' ORDER BY createdAt DESC LIMIT ? OFFSET ?';
    params.push(Number(limit), Number(offset));
    const [rows] = await db.query(sql, params);
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

export default router;
