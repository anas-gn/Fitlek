import { Router } from 'express';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

const POINTS_PER_TIER = 1000;

router.get('/', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  const period = req.query.period || 'today';
  if (!['today', 'week', 'month'].includes(period)) {
    return res.status(400).json({ message: 'Invalid dashboard period.' });
  }

  let rDateFilter = '';
  let rcDateFilter = '';
  if (period === 'today') {
    rDateFilter = 'AND r.reservedDate = CURDATE()';
    rcDateFilter = 'AND DATE(clients.createdAt) = CURDATE()';
  } else if (period === 'week') {
    rDateFilter = 'AND YEARWEEK(r.reservedDate, 1) = YEARWEEK(CURDATE(), 1)';
    rcDateFilter = 'AND YEARWEEK(clients.createdAt, 1) = YEARWEEK(CURDATE(), 1)';
  } else if (period === 'month') {
    rDateFilter = 'AND MONTH(r.reservedDate) = MONTH(CURDATE()) AND YEAR(r.reservedDate) = YEAR(CURDATE())';
    rcDateFilter = 'AND MONTH(clients.createdAt) = MONTH(CURDATE()) AND YEAR(clients.createdAt) = YEAR(CURDATE())';
  }

  try {
    const [[verification]] = await pool.query('SELECT isApproved FROM users WHERE id=?', [coachID]);
    const [
      [[totals]],
      [[clientCount]],
      [[filteredClientCount]],
      [[points]],
      [[weeklyInvitations]],
      [recentReservations],
      [notifications],
      [recentClientInvitations],
    ] = await Promise.all([
      pool.query(
        `SELECT
           COUNT(*) AS totalReservations,
           COALESCE(SUM(r.status = 'pending'), 0) AS pendingReservations,
           COALESCE(SUM(r.status = 'confirmed'), 0) AS confirmedReservations,
           COALESCE(SUM(CASE WHEN r.status = 'confirmed'
             AND r.pricingStatus IN ('fixed', 'accepted') THEN r.price ELSE 0 END), 0) AS confirmedValue
         FROM reservations r WHERE r.coachID = ? ${rDateFilter}`,
        [coachID]
      ),
      pool.query(
        `SELECT COUNT(*) AS totalClients FROM (
           SELECT clientID FROM coachclients WHERE coachID = ?
           UNION SELECT clientID FROM reservations WHERE coachID = ?
         ) clients JOIN users u ON u.id = clients.clientID AND u.role = 'client'`,
        [coachID, coachID]
      ),
      pool.query(
        `SELECT COUNT(*) AS periodClients FROM (
           SELECT clientID, MIN(createdAt) AS createdAt FROM (
             SELECT clientID, createdAt FROM coachclients WHERE coachID = ?
             UNION ALL SELECT clientID, createdAt FROM reservations WHERE coachID = ?
           ) relationships GROUP BY clientID
         ) clients JOIN users u ON u.id = clients.clientID AND u.role = 'client'
         WHERE 1=1 ${rcDateFilter}`,
        [coachID, coachID]
      ),
      pool.query(
        `SELECT earnedPoints, totalInvitations FROM coachprofiles WHERE userID = ?`,
        [coachID]
      ),
      pool.query(
        `SELECT COUNT(*) AS count
         FROM coachreferrals
         WHERE inviterCoachID = ? AND createdAt >= (NOW() - INTERVAL 7 DAY)`,
        [coachID]
      ),
      pool.query(
        `SELECT r.id, r.reservedDate, r.reservedTime, r.status,
                u.id AS clientID, u.firstName, u.lastName, u.avatarUrl
         FROM reservations r
         JOIN users u ON u.id = r.clientID
         WHERE r.coachID = ?
           AND r.status IN ('pending', 'confirmed')
           AND TIMESTAMP(r.reservedDate, r.reservedTime) >= NOW()
         ORDER BY r.reservedDate ASC, r.reservedTime ASC
         LIMIT 5`,
        [coachID]
      ),
      pool.query(
        `SELECT id, type, title, body, relatedEntityID, actorName,
                actorAvatar, isRead, createdAt
         FROM notifications
         WHERE recipientUserID = ?
         ORDER BY createdAt DESC
         LIMIT 5`,
        [coachID]
      ),
      pool.query(
        `SELECT i.id, i.invitedUserID, i.status, i.pointsEarned,
                i.clickedAt, i.respondedAt,
                u.firstName, u.lastName, u.email, u.avatarUrl
         FROM invitations i
         JOIN users u ON u.id = i.invitedUserID AND u.role = 'client'
         WHERE i.coachID = ?
         ORDER BY (i.status = 'pending') DESC, i.clickedAt DESC
         LIMIT 5`,
        [coachID]
      ),
    ]);

    const invitationPoints = Number(points?.earnedPoints ?? 0);
    const currentTier = Math.floor(invitationPoints / POINTS_PER_TIER) + 1;
    const pointsInTier = invitationPoints % POINTS_PER_TIER;
    const tierProgress = Math.round((pointsInTier / POINTS_PER_TIER) * 100);

    res.json({
      isVerified: Number(verification?.isApproved) === 1,
      totalReservations: Number(totals.totalReservations),
      pendingReservations: Number(totals.pendingReservations),
      confirmedReservations: Number(totals.confirmedReservations),
      confirmedValue: Number(totals.confirmedValue ?? 0),
      totalClients: Number(clientCount.totalClients),
      periodClients: Number(filteredClientCount.periodClients),
      invitationPoints,
      totalInvitations: Number(points?.totalInvitations ?? 0),
      invitationsThisWeek: Number(weeklyInvitations.count ?? 0),
      pointsTier: {
        current: currentTier,
        next: currentTier + 1,
        progress: tierProgress,
        pointsRemaining: POINTS_PER_TIER - pointsInTier,
      },
      recentReservations,
      notifications,
      recentClientInvitations,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
