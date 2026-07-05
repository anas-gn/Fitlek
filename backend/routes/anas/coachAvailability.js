const express = require('express');
const router = express.Router();
const db = require('../../config/db');

// GET /availability/:coachID
router.get('/:coachID', async (req, res) => {
  try {
    const { date } = req.query;
    let sql = 'SELECT * FROM coachAvailabilityBlocks WHERE coachID=?';
    const params = [req.params.coachID];
    if (date) { sql += ' AND blockedDate=?'; params.push(date); }
    sql += ' ORDER BY blockedDate, startTime';
    const [rows] = await db.query(sql, params);
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// POST /availability
router.post('/', async (req, res) => {
  try {
    const { coachID, blockedDate, startTime, endTime, note } = req.body;
    if (!coachID || !blockedDate || !startTime || !endTime)
      return res.status(400).json({ error: 'coachID, blockedDate, startTime and endTime required' });

    const [result] = await db.query(
      'INSERT INTO coachAvailabilityBlocks (coachID, blockedDate, startTime, endTime, note) VALUES (?,?,?,?,?)',
      [coachID, blockedDate, startTime, endTime, note || null]
    );
    res.status(201).json({ message: 'Block created', id: result.insertId });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// DELETE /availability/:id
router.delete('/:id', async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT id FROM coachAvailabilityBlocks WHERE id=?', [req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Block not found' });
    await db.query('DELETE FROM coachAvailabilityBlocks WHERE id=?', [req.params.id]);
    res.json({ message: 'Block deleted' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

module.exports = router;