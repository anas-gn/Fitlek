import {withCoachDistances} from '../../services/coachDistance.js';
import express from 'express';
const router = express.Router();
import pool from '../../config/db.js';

// POST /favorites/toggle - toggle a coach favorite
router.post('/toggle', async (req, res) => {
  const clientID = req.user?.id || req.body.clientID;
  const { coachID } = req.body;

  if (!clientID || !coachID) {
    return res.status(400).json({ error: 'clientID and coachID are required' });
  }

  try {
    // Check if already favorited
    const [existing] = await pool.query(
      `SELECT id FROM coach_favorites WHERE clientID = ? AND coachID = ?`,
      [clientID, coachID]
    );

    if (existing.length > 0) {
      // Remove favorite
      await pool.query(
        `DELETE FROM coach_favorites WHERE clientID = ? AND coachID = ?`,
        [clientID, coachID]
      );
      res.json({ favorited: false, message: 'Favorite removed' });
    } else {
      // Add favorite
      await pool.query(
        `INSERT INTO coach_favorites (clientID, coachID) VALUES (?, ?)`,
        [clientID, coachID]
      );
      res.json({ favorited: true, message: 'Favorite added' });
    }
  } catch (error) {
    console.error('Error toggling favorite:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /favorites - get favorite coach IDs for a client
router.get('/', async (req, res) => {
  const clientID = req.user?.id || req.query.clientID;

  if (!clientID) {
    return res.status(400).json({ error: 'clientID is required' });
  }

  try {
    const [rows] = await pool.query(
      `SELECT coachID FROM coach_favorites WHERE clientID = ? ORDER BY createdAt DESC`,
      [clientID]
    );
    res.json(rows.map(r => r.coachID));
  } catch (error) {
    console.error('Error fetching favorites:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /favorites/coaches - get full coach profiles for a client's favorites
router.get('/coaches', async (req, res) => {
  const clientID = req.user?.id || req.query.clientID;

  if (!clientID) {
    return res.status(400).json({ error: 'clientID is required' });
  }

  try {
    const [rows] = await pool.query(
      `SELECT u.id, u.firstName, u.lastName, u.email, u.gender, u.avatarUrl,
              u.isPremium, u.isApproved, cp.bio, cp.instagramPage, cp.invitationCode,
              cp.totalInvitations, cp.earnedPoints, cp.tel, cp.price, cp.ville, cp.categoryID,
              cat.name AS categoryName, cat.icon AS categoryIcon,
              cp.certifications, cp.specialties
       FROM coach_favorites cf
       JOIN users u ON cf.coachID = u.id
       JOIN coachprofiles cp ON u.id = cp.userID
       LEFT JOIN categories cat ON cat.id = cp.categoryID
       WHERE cf.clientID = ?
       ORDER BY cf.createdAt DESC`,
      [clientID]
    );
    res.json(await withCoachDistances(pool, rows, req.user));
  } catch (error) {
    console.error('Error fetching favorite coaches:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
