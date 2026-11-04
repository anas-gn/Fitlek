import { Router } from 'express';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

import {sendDueSessionReminders} from '../../services/sessionReminders.js';
import {createAndSendNotification} from '../../services/pushNotificationService.js';
async function generateDueSessionReminders() {
  await sendDueSessionReminders(pool, createAndSendNotification);
}

// GET /coach/notifications?page=1&limit=30
router.get('/', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  const page = Math.max(1, Number(req.query.page) || 1);
  const limit = Math.min(100, Math.max(1, Number(req.query.limit) || 30));
  const offset = (page - 1) * limit;
  try {
    await generateDueSessionReminders(coachID);
    const [rows] = await pool.query(
      `SELECT id, type, title, body, relatedEntityID, actorName, actorAvatar, isRead, createdAt
       FROM notifications
       WHERE recipientUserID = ?
       ORDER BY createdAt DESC
       LIMIT ? OFFSET ?`,
      [coachID, limit, offset]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Failed to load notifications.' });
  }
});

// GET /coach/notifications/unread-count
router.get('/unread-count', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  try {
    await generateDueSessionReminders(coachID);
    const [[row]] = await pool.query(
      `SELECT COUNT(*) AS count FROM notifications WHERE recipientUserID = ? AND isRead = 0`,
      [coachID]
    );
    res.json({ count: Number(row.count) || 0 });
  } catch (err) {
    res.status(500).json({ message: 'Failed to load unread count.' });
  }
});

// PATCH /coach/notifications/:id/read
router.patch('/:id/read', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  const { id } = req.params;
  try {
    const [result] = await pool.query(
      `UPDATE notifications SET isRead = 1 WHERE id = ? AND recipientUserID = ?`,
      [id, coachID]
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Notification not found.' });
    }
    res.json({ message: 'Notification marked as read.' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to update notification.' });
  }
});

// PATCH /coach/notifications/read-all
router.patch('/read-all', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  try {
    await pool.query(
      `UPDATE notifications SET isRead = 1 WHERE recipientUserID = ? AND isRead = 0`,
      [coachID]
    );
    res.json({ message: 'All notifications marked as read.' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to update notifications.' });
  }
});

export default router;
