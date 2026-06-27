import { Router } from 'express';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

router.get('/', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  try {
    const [rows] = await pool.query(
      `SELECT i.id, i.pointsEarned, i.clickedAt,
              u.firstName, u.lastName
       FROM invitations i
       JOIN users u ON u.id = i.invitedUserID
       WHERE i.coachID = ?
       ORDER BY i.clickedAt DESC`,
      [coachID]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
