import express from 'express';
const router = express.Router();
import db from '../../config/db.js';
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
router.post('/find-or-create', async (req, res) => {
  try {
    const { clientID, coachID } = req.body;

    const [existing] = await db.query(
      'SELECT id FROM conversations WHERE clientID=? AND coachID=?',
      [clientID, coachID]
    );

    if (existing.length) {
      return res.json({ conversationID: existing[0].id, created: false });
    }

    const [result] = await db.query(
      'INSERT INTO conversations (clientID, coachID, createdAt) VALUES (?,?,NOW())',
      [clientID, coachID]
    );

    res.status(201).json({ conversationID: result.insertId, created: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
// GET /conversations/find
// Récupère une conversation spécifique client-coach (sans créer)
router.get('/find', async (req, res) => {
  try {
    const { clientID, coachID } = req.query;
    if (!clientID || !coachID) return res.status(400).json({ error: 'clientID and coachID required' });

    const [rows] = await db.query(
      'SELECT * FROM conversations WHERE clientID=? AND coachID=? LIMIT 1',
      [clientID, coachID]
    );
    if (!rows.length) return res.status(404).json({ error: 'Conversation not found' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
// GET /conversations/find
// Récupère une conversation spécifique client-coach (lecture seule, sans créer)
router.get('/find', async (req, res) => {
  try {
    const { clientID, coachID } = req.query;
    if (!clientID || !coachID) return res.status(400).json({ error: 'clientID and coachID required' });

    const [rows] = await db.query(
      'SELECT * FROM conversations WHERE clientID=? AND coachID=? LIMIT 1',
      [clientID, coachID]
    );
    if (!rows.length) return res.status(404).json({ error: 'Conversation not found' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
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

export default router;