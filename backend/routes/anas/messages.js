const express = require('express');
const router = express.Router();
const db = require('../../config/db');

// GET /messages/:conversationID
router.get('/:conversationID', async (req, res) => {
  try {
    const { page = 1, limit = 50, readerID } = req.query;
    const offset = (page - 1) * limit;

    const [rows] = await db.query(
      `SELECT m.*, CONCAT(u.firstName,' ',u.lastName) AS senderName, u.avatarUrl AS senderAvatar
       FROM messages m JOIN users u ON u.id = m.senderID
       WHERE m.conversationID=? ORDER BY m.createdAt ASC LIMIT ? OFFSET ?`,
      [req.params.conversationID, Number(limit), Number(offset)]
    );

    // Marquer comme lus les messages des autres
    if (readerID) {
      await db.query(
        'UPDATE messages SET isRead=1 WHERE conversationID=? AND senderID != ? AND isRead=0',
        [req.params.conversationID, readerID]
      );
    }

    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// POST /messages/:conversationID
router.post('/:conversationID', async (req, res) => {
  try {
    const { senderID, body } = req.body;
    if (!senderID || !body) return res.status(400).json({ error: 'senderID and body required' });

    // Vérifier que la conversation existe et que l'expéditeur en fait partie
    const [conv] = await db.query(
      'SELECT id FROM conversations WHERE id=? AND (coachID=? OR clientID=?)',
      [req.params.conversationID, senderID, senderID]
    );
    if (!conv.length) return res.status(404).json({ error: 'Conversation not found or access denied' });

    const [result] = await db.query(
      'INSERT INTO messages (conversationID, senderID, body) VALUES (?,?,?)',
      [req.params.conversationID, senderID, body]
    );
    await db.query(
      'UPDATE conversations SET lastMessageAt=NOW() WHERE id=?',
      [req.params.conversationID]
    );

    res.status(201).json({
      id: result.insertId,
      conversationID: Number(req.params.conversationID),
      senderID,
      body,
      isRead: false,
      createdAt: new Date(),
    });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

module.exports = router;