import express from 'express';
const router = express.Router();
import db from '../../config/db.js';
// GET /bans
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT b.*, CONCAT(u.firstName,' ',u.lastName) AS userName,
              CONCAT(a.firstName,' ',a.lastName) AS bannedByName
       FROM bans b
       JOIN users u ON u.id = b.userID
       JOIN users a ON a.id = b.bannedBy
       WHERE b.isActive=1 ORDER BY b.bannedAt DESC`
    );
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// POST /bans
router.post('/', async (req, res) => {
  try {
    const { userID, bannedBy, banType, reason, expiresAt } = req.body;
    if (!userID || !bannedBy || !banType || !reason)
      return res.status(400).json({ error: 'userID, bannedBy, banType and reason required' });
    if (banType === 'temporary' && !expiresAt)
      return res.status(400).json({ error: 'expiresAt required for temporary ban' });

    const [result] = await db.query(
      'INSERT INTO bans (userID, bannedBy, banType, reason, expiresAt) VALUES (?,?,?,?,?)',
      [userID, bannedBy, banType, reason, expiresAt || null]
    );
    await db.query('UPDATE authtokens SET revokedAt=NOW() WHERE userID=?', [userID]);

    res.status(201).json({ message: 'User banned', banID: result.insertId });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// PATCH /bans/:id/lift
router.patch('/:id/lift', async (req, res) => {
  try {
    const { liftedBy } = req.body;
    const [rows] = await db.query('SELECT * FROM bans WHERE id=? AND isActive=1', [req.params.id]);
    if (!rows.length) return res.status(404).json({ error: 'Active ban not found' });
    await db.query(
      'UPDATE bans SET isActive=0, liftedAt=NOW(), liftedBy=? WHERE id=?',
      [liftedBy || null, req.params.id]
    );
    res.json({ message: 'Ban lifted' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// GET /bans/user/:userID
router.get('/user/:userID', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT * FROM bans WHERE userID=? AND isActive=1
       AND (banType='permanent' OR expiresAt > NOW())`,
      [req.params.userID]
    );
    res.json({ isBanned: rows.length > 0, ban: rows[0] || null });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

export default router;