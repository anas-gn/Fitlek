import express from 'express';
const router = express.Router();
import db from '../../config/db.js';
// GET /coach-clients/me
router.get('/me', async (req, res) => {
  try {
    const { coachID } = req.query;
    const requesterID = req.user.id;
    const [rows] = await db.query(
      `SELECT u.id, u.firstName, u.lastName, u.email, u.avatarUrl, cc.createdAt AS linkedAt
       FROM coachclients cc JOIN users u ON u.id = cc.clientID
       WHERE cc.coachID=? 
         AND u.id NOT IN (SELECT blockedID FROM user_blocks WHERE blockerID = ?)
         AND u.id NOT IN (SELECT blockerID FROM user_blocks WHERE blockedID = ?)
       ORDER BY cc.createdAt DESC`,
      [coachID, requesterID, requesterID]
    );
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// POST /coach-clients
router.post('/', async (req, res) => {
  try {
    const { coachID, clientID } = req.body;
    if (!coachID || !clientID) return res.status(400).json({ error: 'coachID and clientID required' });
    await db.query('INSERT IGNORE INTO coachclients (coachID, clientID) VALUES (?,?)', [coachID, clientID]);
    res.status(201).json({ message: 'Client linked to coach' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// DELETE /coach-clients/:clientID
router.delete('/:clientID', async (req, res) => {
  try {
    const { coachID } = req.query;
    await db.query(
      'DELETE FROM coachclients WHERE coachID=? AND clientID=?', [coachID, req.params.clientID]
    );
    res.json({ message: 'Client unlinked' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

export default router;