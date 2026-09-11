import express from 'express';
const router = express.Router();
import pool from '../../config/db.js';

// Block a user
router.post('/block', async (req, res) => {
  const blockerID = req.user.id;
  const { blockedID } = req.body;

  if (!blockedID) {
    return res.status(400).json({ error: 'blockedID is required' });
  }

  if (blockerID == blockedID) {
    return res.status(400).json({ error: 'You cannot block yourself' });
  }

  try {
    await pool.query(
      `INSERT IGNORE INTO user_blocks (blockerID, blockedID) VALUES (?, ?)`,
      [blockerID, blockedID]
    );
    res.json({ success: true, message: 'User blocked successfully' });
  } catch (error) {
    console.error('❌ Error blocking user:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Unblock a user
router.post('/unblock', async (req, res) => {
  const blockerID = req.user.id;
  const { blockedID } = req.body;

  if (!blockedID) {
    return res.status(400).json({ error: 'blockedID is required' });
  }

  try {
    await pool.query(
      `DELETE FROM user_blocks WHERE blockerID = ? AND blockedID = ?`,
      [blockerID, blockedID]
    );
    res.json({ success: true, message: 'User unblocked successfully' });
  } catch (error) {
    console.error('❌ Error unblocking user:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get list of blocked users
router.get('/blocked', async (req, res) => {
  const blockerID = req.user.id;

  try {
    const [rows] = await pool.query(
      `SELECT u.id, u.firstName, u.lastName, u.avatarUrl, u.role
       FROM user_blocks b
       JOIN users u ON b.blockedID = u.id
       WHERE b.blockerID = ?
       ORDER BY b.createdAt DESC`,
      [blockerID]
    );
    res.json(rows);
  } catch (error) {
    console.error('❌ Error fetching blocked users:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Report a user or message
router.post('/report', async (req, res) => {
  const reporterID = req.user.id;
  const { reportedID, reason, type = 'user', entityID = null } = req.body;

  if (!reportedID || !reason) {
    return res.status(400).json({ error: 'reportedID and reason are required' });
  }

  try {
    await pool.query(
      `INSERT INTO user_reports (reporterID, reportedID, reason, type, entityID)
       VALUES (?, ?, ?, ?, ?)`,
      [reporterID, reportedID, reason, type, entityID]
    );
    res.json({ success: true, message: 'Report submitted successfully' });
  } catch (error) {
    console.error('❌ Error reporting user:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
