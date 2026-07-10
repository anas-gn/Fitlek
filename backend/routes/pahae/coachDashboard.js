import { Router } from 'express';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

router.get('/', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  try {
    const [[totals]] = await pool.query(
      `SELECT
         COUNT(*) AS totalReservations,
         SUM(status = 'pending')   AS pendingReservations,
         SUM(status = 'confirmed') AS confirmedReservations
       FROM reservations WHERE coachID = ?`,
      [coachID]
    );
    const [[clientCount]] = await pool.query(
      `SELECT COUNT(*) AS totalClients FROM coachclients WHERE coachID = ?`,
      [coachID]
    );
    const [[points]] = await pool.query(
      `SELECT earnedPoints, totalInvitations FROM coachprofiles WHERE userID = ?`,
      [coachID]
    );
    const [recentActivity] = await pool.query(
      `SELECT u.firstName, u.lastName, u.avatarUrl, r.createdAt
       FROM reservations r
       JOIN users u ON u.id = r.clientID
       WHERE r.coachID = ?
       ORDER BY r.createdAt DESC
       LIMIT 5`,
      [coachID]
    );
    res.json({
      totalReservations:   Number(totals.totalReservations),
      pendingReservations:  Number(totals.pendingReservations),
      confirmedReservations: Number(totals.confirmedReservations),
      totalClients:         Number(clientCount.totalClients),
      invitationPoints:     Number(points?.earnedPoints ?? 0),
      totalInvitations:     Number(points?.totalInvitations ?? 0),
      recentActivity,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
