const express = require('express');
const router = express.Router();
const db = require('../../config/db');

// GET /weight-history/me
router.get('/me', async (req, res) => {
  try {
    const { clientID, limit = 30, page = 1 } = req.query;
    if (!clientID) return res.status(400).json({ error: 'clientID required' });

    const offset = (page - 1) * limit;
    const [rows] = await db.query(
      `SELECT id, clientID, weight, note, recordedAt, createdAt 
       FROM weighthistory 
       WHERE clientID=? 
       ORDER BY createdAt DESC 
       LIMIT ? OFFSET ?`,
      [clientID, Number(limit), Number(offset)]
    );
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// GET /weight-history/me/stats
router.get('/me/stats', async (req, res) => {
  try {
    const { clientID } = req.query;
    if (!clientID) return res.status(400).json({ error: 'clientID required' });

    const [rows] = await db.query(
      `SELECT 
        (SELECT weight FROM weighthistory WHERE clientID=? ORDER BY createdAt DESC LIMIT 1) as currentWeight,
        (SELECT weight FROM weighthistory WHERE clientID=? ORDER BY createdAt ASC LIMIT 1) as startWeight,
        MAX(weight) as maxWeight,
        MIN(weight) as minWeight,
        COUNT(*) as totalEntries
       FROM weighthistory WHERE clientID=?`,
      [clientID, clientID, clientID]
    );

    const stats = rows[0];
    const totalLoss = stats.startWeight && stats.currentWeight
      ? (stats.startWeight - stats.currentWeight).toFixed(2) : 0;

    res.json({
      currentWeight: stats.currentWeight,
      startWeight: stats.startWeight,
      maxWeight: stats.maxWeight,
      minWeight: stats.minWeight,
      totalEntries: stats.totalEntries,
      totalLoss: parseFloat(totalLoss),
    });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// GET /weight-history/me/chart
// Retourne le DERNIER poids enregistré pour chaque jour (pas la moyenne)
router.get('/me/chart', async (req, res) => {
  try {
    const { clientID } = req.query;
    if (!clientID) return res.status(400).json({ error: 'clientID required' });

    const [rows] = await db.query(
      `SELECT 
        DATE_FORMAT(createdAt, '%d/%m') as label,
        DATE(createdAt) as day,
        weight
       FROM weighthistory w1
       WHERE clientID=?
         AND createdAt = (
           SELECT MAX(w2.createdAt) 
           FROM weighthistory w2 
           WHERE w2.clientID = w1.clientID 
             AND DATE(w2.createdAt) = DATE(w1.createdAt)
         )
       GROUP BY DATE(createdAt), DATE_FORMAT(createdAt, '%d/%m'), weight
       ORDER BY day ASC
       LIMIT 30`,
      [clientID]
    );

    const data = rows.map(r => ({ label: r.label, weight: parseFloat(r.weight) }));
    res.json(data);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// POST /weight-history
router.post('/', async (req, res) => {
  try {
    const { clientID, weight, note } = req.body;
    if (!clientID || weight === undefined) {
      return res.status(400).json({ error: 'clientID and weight required' });
    }

    const [result] = await db.query(
      'INSERT INTO weighthistory (clientID, weight, recordedAt, note) VALUES (?, ?, CURDATE(), ?)',
      [clientID, weight, note || null]
    );
    res.status(201).json({ message: 'Weight recorded', id: result.insertId });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// PUT /weight-history/:id
router.put('/:id', async (req, res) => {
  try {
    const { weight, note } = req.body;
    await db.query('UPDATE weighthistory SET weight=?, note=? WHERE id=?',
      [weight, note || null, req.params.id]);
    res.json({ message: 'Weight updated' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// DELETE /weight-history/:id
router.delete('/:id', async (req, res) => {
  try {
    await db.query('DELETE FROM weighthistory WHERE id=?', [req.params.id]);
    res.json({ message: 'Weight entry deleted' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

module.exports = router;