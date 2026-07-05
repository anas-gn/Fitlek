const express = require('express');
const router  = express.Router();
const db      = require('../../config/db');

// GET /reviews/coach/:coachID
router.get('/coach/:coachID', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT cr.id, cr.coachID, cr.clientID, cr.rating, cr.comment, cr.createdAt,
              CONCAT(u.firstName,' ',u.lastName) AS clientName,
              u.avatarUrl AS clientAvatar
       FROM coachreviews cr
       JOIN users u ON u.id = cr.clientID
       WHERE cr.coachID = ?
       ORDER BY cr.createdAt DESC`,
      [req.params.coachID]
    );
    const total  = rows.length;
    const avgRaw = total ? rows.reduce((s, r) => s + r.rating, 0) / total : 0;
    const avg    = Math.round(avgRaw * 10) / 10;
    res.json({ avg, total, reviews: rows });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// GET /reviews/coach/:coachID/mine?clientID=
router.get('/coach/:coachID/mine', async (req, res) => {
  try {
    const { clientID } = req.query;
    if (!clientID) return res.status(400).json({ error: 'clientID required' });
    const [rows] = await db.query(
      'SELECT * FROM coachreviews WHERE coachID=? AND clientID=?',
      [req.params.coachID, clientID]
    );
    res.json(rows[0] || null);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// POST /reviews
router.post('/', async (req, res) => {
  try {
    const { coachID, clientID, rating, comment } = req.body;
    if (!coachID || !clientID || !rating)
      return res.status(400).json({ error: 'coachID, clientID and rating required' });
    if (rating < 1 || rating > 5)
      return res.status(400).json({ error: 'rating must be between 1 and 5' });

    // Vérifie qu'une séance confirmée existe
    const [sessions] = await db.query(
      `SELECT id FROM reservations
       WHERE clientID=? AND coachID=? AND status='confirmed'
       LIMIT 1`,
      [clientID, coachID]
    );
    if (!sessions.length)
      return res.status(403).json({ error: 'No confirmed session found with this coach' });

    await db.query(
      `INSERT INTO coachreviews (coachID, clientID, rating, comment)
       VALUES (?,?,?,?)
       ON DUPLICATE KEY UPDATE rating=VALUES(rating), comment=VALUES(comment), updatedAt=NOW()`,
      [coachID, clientID, rating, comment || null]
    );
    res.status(201).json({ message: 'Review saved' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// DELETE /reviews/:coachID?clientID=
router.delete('/:coachID', async (req, res) => {
  try {
    const { clientID } = req.query;
    if (!clientID) return res.status(400).json({ error: 'clientID required' });
    await db.query(
      'DELETE FROM coachreviews WHERE coachID=? AND clientID=?',
      [req.params.coachID, clientID]
    );
    res.json({ message: 'Review deleted' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

module.exports = router;