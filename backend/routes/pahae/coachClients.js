import { Router } from 'express';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

router.get('/', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  try {
    const [rows] = await pool.query(
      `SELECT u.id, u.firstName, u.lastName, u.email, u.avatarUrl, u.isPremium,
              cc.createdAt AS linkedAt
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

// Client details — only for a client genuinely linked to the authenticated coach.
router.get('/:clientId', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  const { clientId } = req.params;
  try {
    const [[rel]] = await pool.query(
      `SELECT createdAt AS linkedAt FROM coachclients WHERE coachID = ? AND clientID = ?`,
      [coachID, clientId]
    );
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
         SUM(status = 'pending') AS pending,
         SUM(status = 'cancelled') AS cancelled
       FROM reservations WHERE coachID = ? AND clientID = ?`,
      [coachID, clientId]
    );

    const [recentSessions] = await pool.query(
      `SELECT id, reservedDate, reservedTime, status, location
       FROM reservations WHERE coachID = ? AND clientID = ?
       ORDER BY reservedDate DESC, reservedTime DESC LIMIT 5`,
      [coachID, clientId]
    );

    res.json({
      ...client,
      linkedAt: rel.linkedAt,
      reservations: {
        total: Number(stats.total) || 0,
        confirmed: Number(stats.confirmed) || 0,
        pending: Number(stats.pending) || 0,
        cancelled: Number(stats.cancelled) || 0,
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
    const [[rel]] = await pool.query(
      `SELECT id FROM coachclients WHERE coachID = ? AND clientID = ?`,
      [coachID, clientId]
    );
    if (!rel) return res.status(403).json({ message: 'This client is not linked to you.' });

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
