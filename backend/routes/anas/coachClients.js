import express from 'express';
const router = express.Router();
import db from '../../config/db.js';
import {ownIdentity} from '../../middleware/ownership.js';
// GET /coach-clients/me
router.get('/me', ownIdentity('coachID',['coach']), async (req, res) => {
  try {
    const coachID=req.user.id;
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
router.post('/', (_req,res)=>res.status(410).json({error:'Create connections through an invitation accepted by the Coach.'}));

// DELETE /coach-clients/:clientID
router.delete('/:clientID', async (req, res) => {
  try {
    const coachID=Number(req.query.coachID);
    if(!((req.user.role==='coach' && coachID===Number(req.user.id)) || (req.user.role==='client' && Number(req.params.clientID)===Number(req.user.id)))) return res.status(403).json({error:'Access denied.'});
    await db.query(
      'DELETE FROM coachclients WHERE coachID=? AND clientID=?', [coachID, req.params.clientID]
    );
    res.json({ message: 'Client unlinked' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

export default router;