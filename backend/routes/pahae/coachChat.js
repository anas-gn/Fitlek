import { Router } from 'express';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

router.get('/:conversationId', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  const { conversationId } = req.params;
  try {
    const [[conv]] = await pool.query(
      `SELECT id FROM conversations WHERE id = ? AND coachID = ?`,
      [conversationId, coachID]
    );
    if (!conv) return res.status(403).json({ message: 'Access denied.' });
    const [messages] = await pool.query(
      `SELECT id, senderID, body, isRead, createdAt
       FROM messages WHERE conversationID = ?
       ORDER BY createdAt ASC`,
      [conversationId]
    );
    await pool.query(
      `UPDATE messages SET isRead = 1
       WHERE conversationID = ? AND senderID != ? AND isRead = 0`,
      [conversationId, coachID]
    );
    res.json(messages);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.post('/:conversationId', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  const { conversationId } = req.params;
  const { body } = req.body;
  if (!body || !body.trim()) return res.status(400).json({ message: 'Message body is required.' });
  try {
    const [[conv]] = await pool.query(
      `SELECT id FROM conversations WHERE id = ? AND coachID = ?`,
      [conversationId, coachID]
    );
    if (!conv) return res.status(403).json({ message: 'Access denied.' });
    const [result] = await pool.query(
      `INSERT INTO messages (conversationID, senderID, body) VALUES (?, ?, ?)`,
      [conversationId, coachID, body.trim()]
    );
    await pool.query(
      `UPDATE conversations SET lastMessageAt = NOW() WHERE id = ?`,
      [conversationId]
    );
    res.status(201).json({ id: result.insertId, body: body.trim(), senderID: coachID });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
