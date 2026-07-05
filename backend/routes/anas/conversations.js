const express = require('express');
const router = express.Router();
const db = require('../../config/db');

// GET /conversations
router.get('/', async (req, res) => {
  try {
    const { userID, role } = req.query;
    let sql, params;
    if (role === 'client') {
      sql = `SELECT cv.*, CONCAT(co.firstName,' ',co.lastName) AS otherName, co.avatarUrl AS otherAvatar
             FROM conversations cv JOIN users co ON co.id = cv.coachID
             WHERE cv.clientID=? ORDER BY cv.lastMessageAt DESC`;
      params = [userID];
    } else if (role === 'coach') {
      sql = `SELECT cv.*, CONCAT(c.firstName,' ',c.lastName) AS otherName, c.avatarUrl AS otherAvatar
             FROM conversations cv JOIN users c ON c.id = cv.clientID
             WHERE cv.coachID=? ORDER BY cv.lastMessageAt DESC`;
      params = [userID];
    } else {
      sql = 'SELECT * FROM conversations ORDER BY lastMessageAt DESC';
      params = [];
    }
    const [rows] = await db.query(sql, params);
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// POST /conversations
router.post('/', async (req, res) => {
  try {
    const { coachID, clientID } = req.body;
    if (!coachID || !clientID)
      return res.status(400).json({ error: 'coachID and clientID required' });

    const [existing] = await db.query(
      'SELECT * FROM conversations WHERE coachID=? AND clientID=?', [coachID, clientID]
    );
    if (existing.length) return res.json(existing[0]);

    const [result] = await db.query(
      'INSERT INTO conversations (coachID, clientID) VALUES (?,?)', [coachID, clientID]
    );
    res.status(201).json({ id: result.insertId, coachID, clientID });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

module.exports = router;