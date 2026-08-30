import { Router } from 'express';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

router.get('/', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  try {
    const [rows] = await pool.query(
      `SELECT
         c.id,
         c.clientID,
         u.firstName, u.lastName, u.avatarUrl,
         c.lastMessageAt,
         (SELECT body FROM messages m WHERE m.conversationID = c.id
          ORDER BY m.createdAt DESC LIMIT 1) AS lastMessage,
         (SELECT COUNT(*) FROM messages m
          WHERE m.conversationID = c.id AND m.senderID != ? AND m.isRead = 0) AS unreadCount
       FROM conversations c
       JOIN users u ON u.id = c.clientID
       WHERE c.coachID = ?
       ORDER BY c.lastMessageAt DESC`,
      [coachID, coachID]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
