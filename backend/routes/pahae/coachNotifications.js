import { Router } from 'express';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

// Session-reminder window (minutes before start). Reminders are generated
// on-demand (no scheduler in this project) and de-duplicated by uniqueKey.
const REMINDER_WINDOW_MINUTES = 60;

// Materialize any due upcoming-session reminders for this coach.
// Only confirmed, future sessions inside the window; INSERT IGNORE + the
// UNIQUE(uniqueKey) constraint make this safe to run on every fetch.
// Uses the DB clock for both NOW() and the session timestamp, so the same
// timezone convention applies to reservedDate/reservedTime consistently.
async function generateDueSessionReminders(coachID) {
  await pool.query(
    `INSERT IGNORE INTO notifications
       (recipientUserID, type, title, body, relatedEntityID, actorName, actorAvatar, uniqueKey)
     SELECT r.coachID,
            'upcoming_session',
            'Upcoming session',
            CONCAT('Your session with ', c.firstName, ' ', c.lastName,
                   ' starts at ', TIME_FORMAT(r.reservedTime, '%H:%i'), '.'),
            r.id,
            CONCAT(c.firstName, ' ', c.lastName),
            c.avatarUrl,
            CONCAT('session-reminder:', r.id, ':', ?, 'm:coach:', r.coachID)
     FROM reservations r
     JOIN users c ON c.id = r.clientID
     WHERE r.coachID = ?
       AND r.status = 'confirmed'
       AND TIMESTAMP(r.reservedDate, r.reservedTime) > NOW()
       AND TIMESTAMP(r.reservedDate, r.reservedTime) <= (NOW() + INTERVAL ? MINUTE)`,
    [REMINDER_WINDOW_MINUTES, coachID, REMINDER_WINDOW_MINUTES]
  );
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
