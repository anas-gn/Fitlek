import { Router } from 'express';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

router.get('/', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  try {
    const [rows] = await pool.query(
      `SELECT u.id, u.firstName, u.lastName, u.email, u.avatarUrl, u.isPremium
       FROM coachclients cc
       JOIN users u ON u.id = cc.clientID
       WHERE cc.coachID = ?
       ORDER BY u.firstName ASC`,
      [coachID]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.post('/:clientId/invite-premium', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  const { clientId } = req.params;
  try {
    const [[rel]] = await pool.query(
      `SELECT id FROM coachclients WHERE coachID = ? AND clientID = ?`,
      [coachID, clientId]
    );
    if (!rel) return res.status(404).json({ message: 'Client not found in your list.' });
    res.json({ message: 'Premium invitation sent.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
