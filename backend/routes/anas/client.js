import express from 'express';
const router = express.Router();
import db from '../../config/db.js';
router.get('/me', async (req, res) => {
  try {
    const userID = req.query.userID;
    const [rows] = await db.query(
      'SELECT id, firstName, lastName, email, gender, avatarUrl, isPremium, isApproved, height, createdAt FROM users WHERE id=?',
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
    const { userID, firstName, lastName, gender, avatarUrl, height } = req.body;
    await db.query(
      'UPDATE users SET firstName=?, lastName=?, gender=?, avatarUrl=?, height=? WHERE id=?',
      [firstName, lastName, gender, avatarUrl, height, userID]
    );
    res.json({ message: 'Profile updated' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.get('/:id', async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT id, firstName, lastName, email, gender, avatarUrl, isPremium, isApproved, height, createdAt FROM users WHERE id=? AND role="client"',
      [req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Client not found' });
    res.json(rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.get('/', async (req, res) => {
  try {
    const { page = 1, limit = 20, search } = req.query;
    const offset = (page - 1) * limit;
    let sql = 'SELECT id, firstName, lastName, email, gender, isPremium, isApproved, height, createdAt FROM users WHERE role="client"';
    const params = [];
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