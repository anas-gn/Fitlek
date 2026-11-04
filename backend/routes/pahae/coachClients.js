import { Router } from 'express';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

// A booking establishes a coaching relationship, even without an invitation.
const clientActivity = `SELECT clientID, COUNT(*) AS sessionCount,
  SUM(status = 'pending' AND TIMESTAMP(reservedDate,reservedTime) >= NOW()) AS pendingCount,
  SUM(status = 'confirmed' AND TIMESTAMP(reservedDate,reservedTime) >= NOW()) AS upcomingCount,
  MIN(CASE WHEN status = 'confirmed' AND TIMESTAMP(reservedDate,reservedTime) >= NOW()
    THEN TIMESTAMP(reservedDate,reservedTime) END) AS nextSessionAt,
  MIN(createdAt) AS firstBookingAt
  FROM reservations WHERE coachID = ? GROUP BY clientID`;
async function relationship(coachID, clientId) {
  const [[rel]] = await pool.query(
    `SELECT createdAt AS linkedAt, 1 AS isLinked FROM coachclients WHERE coachID = ? AND clientID = ?
     UNION ALL
     SELECT MIN(createdAt) AS linkedAt, 0 AS isLinked FROM reservations
     WHERE coachID = ? AND clientID = ? HAVING COUNT(*) > 0 LIMIT 1`,
    [coachID, clientId, coachID, clientId]);
  return rel;
}

router.get('/', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  try {
    const [rows] = await pool.query(
      `SELECT u.id, u.firstName, u.lastName, u.email, u.avatarUrl, u.isPremium,
              COALESCE(cc.createdAt, activity.firstBookingAt) AS linkedAt,
              (cc.clientID IS NOT NULL) AS isLinked,
              COALESCE(activity.sessionCount,0) AS sessionCount,
              COALESCE(activity.pendingCount,0) AS pendingCount,
              COALESCE(activity.upcomingCount,0) AS upcomingCount, activity.nextSessionAt
       FROM users u
       LEFT JOIN coachclients cc ON cc.clientID = u.id AND cc.coachID = ?
       LEFT JOIN (${clientActivity}) activity ON activity.clientID = u.id
       WHERE u.role = 'client' AND (cc.clientID IS NOT NULL OR activity.clientID IS NOT NULL)
       ORDER BY u.firstName ASC`,
      [coachID, coachID]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Client details are scoped to an invitation or booking with this coach.
router.get('/:clientId', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  const { clientId } = req.params;
  try {
    const rel = await relationship(coachID, clientId);
    if (!rel) return res.status(403).json({ message: 'This client is not linked to you.' });

    const [[client]] = await pool.query(
      `SELECT id, firstName, lastName, email, gender, avatarUrl, isPremium, height, createdAt
       FROM users WHERE id = ? AND role = 'client'`,
      [clientId]
    );
    if (!client) return res.status(404).json({ message: 'Client not found.' });

    const [[stats]] = await pool.query(
      `SELECT
         COUNT(*) AS total,
         SUM(status = 'confirmed') AS confirmed,
         SUM(status = 'pending' AND TIMESTAMP(reservedDate,reservedTime) >= NOW()) AS pending,
         SUM(status = 'cancelled') AS cancelled,
         SUM(status = 'confirmed' AND TIMESTAMP(reservedDate,reservedTime) >= NOW()) AS upcoming
       FROM reservations WHERE coachID = ? AND clientID = ?`,
      [coachID, clientId]
    );

    const [recentSessions] = await pool.query(
      `SELECT id, reservedDate, reservedTime, status, location, pricingStatus, price, proposedPrice
       FROM reservations WHERE coachID = ? AND clientID = ?
       ORDER BY reservedDate DESC, reservedTime DESC LIMIT 5`,
      [coachID, clientId]
    );

    res.json({
      ...client,
      linkedAt: rel.linkedAt,
      isLinked: Boolean(rel.isLinked),
      reservations: {
        total: Number(stats.total) || 0,
        confirmed: Number(stats.confirmed) || 0,
        pending: Number(stats.pending) || 0,
        cancelled: Number(stats.cancelled) || 0,
        upcoming: Number(stats.upcoming) || 0,
      },
      recentSessions,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Open (or reuse) the conversation with a linked client. Reuses the existing
// conversations table + the existing secure coach chat endpoints.
router.post('/:clientId/conversation', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  const { clientId } = req.params;
  try {
    const rel = await relationship(coachID, clientId);
    if (!rel) return res.status(403).json({ message: 'This client is not linked to you.' });

    const [[blocked]] = await pool.query(
      `SELECT id FROM user_blocks WHERE (blockerID = ? AND blockedID = ?)
       OR (blockerID = ? AND blockedID = ?) LIMIT 1`,
      [coachID, clientId, clientId, coachID]);
    if (blocked) return res.status(403).json({ message: 'Messaging is unavailable for this client.' });

    const [[existing]] = await pool.query(
      `SELECT id FROM conversations WHERE coachID = ? AND clientID = ?`,
      [coachID, clientId]
    );
    if (existing) return res.json({ conversationID: existing.id, created: false });

    const [result] = await pool.query(
      `INSERT INTO conversations (coachID, clientID) VALUES (?, ?)`,
      [coachID, clientId]
    );
    res.status(201).json({ conversationID: result.insertId, created: true });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Unlink a client from the authenticated coach (scoped to req.user.id).
router.delete('/:clientId', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  const { clientId } = req.params;
  try {
    const [result] = await pool.query(
      `DELETE FROM coachclients WHERE coachID = ? AND clientID = ?`,
      [coachID, clientId]
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'This client is not linked to you.' });
    }
    res.json({ message: 'Client removed from your list.' });
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
