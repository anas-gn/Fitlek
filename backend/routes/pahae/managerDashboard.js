import { Router } from 'express';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

router.get('/', requireAuth, requireRole('manager'), async (req, res) => {
  try {
    const [[counts]] = await pool.query(
      `SELECT
         SUM(role = 'client')  AS totalClients,
         SUM(role = 'coach')   AS totalCoaches,
         SUM(role = 'admin')   AS totalAdmins,
         SUM(role = 'advisor') AS totalAdvisors
       FROM users`
    );
    const [[resCounts]] = await pool.query(
      `SELECT
         COUNT(*)                        AS totalReservations,
         SUM(status = 'confirmed')       AS confirmedReservations,
         SUM(status = 'pending')         AS pendingReservations,
         SUM(status = 'cancelled')       AS cancelledReservations
       FROM reservations`
    );
    const [[banCount]] = await pool.query(
      `SELECT COUNT(*) AS activeBans FROM bans
       WHERE isActive = 1 AND (expiresAt IS NULL OR expiresAt > NOW())`
    );
    const [[pendingCount]] = await pool.query(
      `SELECT COUNT(*) AS pendingCoaches FROM users
       WHERE role = 'coach' AND isApproved = 0`
    );
    res.json({
      totalClients:          Number(counts.totalClients),
      totalCoaches:          Number(counts.totalCoaches),
      totalAdmins:           Number(counts.totalAdmins),
      totalAdvisors:         Number(counts.totalAdvisors),
      totalReservations:     Number(resCounts.totalReservations),
      confirmedReservations: Number(resCounts.confirmedReservations),
      pendingReservations:   Number(resCounts.pendingReservations),
      cancelledReservations: Number(resCounts.cancelledReservations),
      activeBans:            Number(banCount.activeBans),
      pendingCoaches:        Number(pendingCount.pendingCoaches),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
