import express from 'express';
import db from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = express.Router();
router.use(requireAuth, requireRole('coach', 'manager', 'admin'));

router.get('/clients/:clientID/history', async (req, res) => {
  const clientID = Number(req.params.clientID);
  if (!Number.isInteger(clientID) || clientID <= 0) return res.status(400).json({ error: 'Invalid client.' });
  try {
    if (req.user.role === 'coach') {
      const [assignment] = await db.query(
        'SELECT id FROM coachclients WHERE coachID = ? AND clientID = ? LIMIT 1',
        [req.user.id, clientID],
      );
      if (!assignment.length) return res.status(403).json({ error: 'Client is not assigned to this coach.' });
    }
    const [rows] = await db.query(
      `SELECT s.id, s.status, s.startedAt, s.completedAt, r.name AS routineName,
        COUNT(ws.id) AS setCount
       FROM premium_workout_sessions s
       LEFT JOIN premium_routines r ON r.id = s.routineID
       LEFT JOIN premium_workout_sets ws ON ws.sessionID = s.id
       WHERE s.userID = ? GROUP BY s.id, s.status, s.startedAt, s.completedAt, r.name
       ORDER BY s.startedAt DESC LIMIT 100`,
      [clientID],
    );
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: 'Unable to load client workout history.' });
  }
});

export default router;
