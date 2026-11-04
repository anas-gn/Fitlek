import express from 'express';
const router = express.Router();
import db from '../../config/db.js';

// GET /packages/coach/:coachID  – Public list of a coach's packages
router.get('/coach/:coachID', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT id, coachID, name, description, sessions, duration, price, isPriceOnRequest, locations, imageUrl, isActive, createdAt, updatedAt
       FROM coach_packages
       WHERE coachID = ? AND isActive = 1
       ORDER BY sortOrder ASC, id ASC`,
      [req.params.coachID]
    );
    res.json(rows);
  } catch (err) {
    console.error('Packages Error (POST):', err);
    res.status(500).json({ error: err.message });
  }
});

// GET /packages/me  – Coach fetches their own packages (including inactive)
router.get('/me', async (req, res) => {
  try {
    const { coachID } = req.query;
    if (!coachID) return res.status(400).json({ error: 'coachID required' });
    const [rows] = await db.query(
      `SELECT id, coachID, name, description, sessions, duration, price, isPriceOnRequest, locations, imageUrl, isActive, sortOrder, createdAt, updatedAt
       FROM coach_packages
       WHERE coachID = ?
       ORDER BY sortOrder ASC, id ASC`,
      [coachID]
    );
    res.json(rows);
  } catch (err) {
    console.error('Packages Error (POST):', err);
    res.status(500).json({ error: err.message });
  }
});

// POST /packages  – Coach creates a package (max 3)
router.post('/', async (req, res) => {
  try {
    const { coachID, name, description, sessions, duration, price, isPriceOnRequest, locations, imageUrl } = req.body;
    if (!coachID || !name) {
      return res.status(400).json({ error: 'coachID and name are required' });
    }

    // Enforce max 3 packages
    const [[{ count }]] = await db.query(
      'SELECT COUNT(*) as count FROM coach_packages WHERE coachID = ?',
      [coachID]
    );
    if (Number(count) >= 3) {
      return res.status(400).json({ error: 'Maximum 3 packages allowed' });
    }

    // Determine sort order
    const [[maxSort]] = await db.query(
      'SELECT COALESCE(MAX(sortOrder), 0) as maxSort FROM coach_packages WHERE coachID = ?',
      [coachID]
    );
    const sortOrder = Number(maxSort.maxSort) + 1;

    const [result] = await db.query(
      `INSERT INTO coach_packages (coachID, name, description, sessions, duration, price, isPriceOnRequest, locations, imageUrl, sortOrder)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        coachID,
        name.trim(),
        description?.trim() || null,
        sessions ? Number(sessions) : null,
        duration ? Number(duration) : null,
        price !== undefined && price !== null && price !== '' ? Number(price) : null,
        isPriceOnRequest ? 1 : 0,
        locations ? JSON.stringify(locations) : null,
        imageUrl || null,
        sortOrder,
      ]
    );
    res.status(201).json({ message: 'Package created', id: result.insertId });
  } catch (err) {
    console.error('Packages Error (POST):', err);
    res.status(500).json({ error: err.message });
  }
});

// PUT /packages/:id  – Coach updates a package
router.put('/:id', async (req, res) => {
  try {
    const { coachID, name, description, sessions, duration, price, isPriceOnRequest, locations, imageUrl, isActive } = req.body;
    if (!coachID) return res.status(400).json({ error: 'coachID required' });

    const [rows] = await db.query(
      'SELECT id FROM coach_packages WHERE id = ? AND coachID = ?',
      [req.params.id, coachID]
    );
    if (!rows.length) return res.status(404).json({ error: 'Package not found' });

    const updates = [];
    const values = [];

    if (name !== undefined) { updates.push('name = ?'); values.push(name.trim()); }
    if (description !== undefined) { updates.push('description = ?'); values.push(description?.trim() || null); }
    if (sessions !== undefined) { updates.push('sessions = ?'); values.push(sessions ? Number(sessions) : null); }
    if (duration !== undefined) { updates.push('duration = ?'); values.push(duration ? Number(duration) : null); }
    if (price !== undefined) { updates.push('price = ?'); values.push(price !== null && price !== '' ? Number(price) : null); }
    if (isPriceOnRequest !== undefined) { updates.push('isPriceOnRequest = ?'); values.push(isPriceOnRequest ? 1 : 0); }
    if (locations !== undefined) { updates.push('locations = ?'); values.push(locations ? JSON.stringify(locations) : null); }
    if (imageUrl !== undefined) { updates.push('imageUrl = ?'); values.push(imageUrl || null); }
    if (isActive !== undefined) { updates.push('isActive = ?'); values.push(isActive ? 1 : 0); }

    if (updates.length > 0) {
      updates.push('updatedAt = CURRENT_TIMESTAMP');
      values.push(req.params.id, coachID);
      await db.query(
        `UPDATE coach_packages SET ${updates.join(', ')} WHERE id = ? AND coachID = ?`,
        values
      );
    }
    res.json({ message: 'Package updated' });
  } catch (err) {
    console.error('Packages Error (POST):', err);
    res.status(500).json({ error: err.message });
  }
});

// DELETE /packages/:id  – Coach deletes a package
router.delete('/:id', async (req, res) => {
  try {
    const coachID = req.body.coachID || req.query.coachID;
    if (!coachID) return res.status(400).json({ error: 'coachID required' });

    const [rows] = await db.query(
      'SELECT id FROM coach_packages WHERE id = ? AND coachID = ?',
      [req.params.id, coachID]
    );
    if (!rows.length) return res.status(404).json({ error: 'Package not found' });

    await db.query('DELETE FROM coach_packages WHERE id = ? AND coachID = ?', [
      req.params.id,
      coachID,
    ]);
    res.json({ message: 'Package deleted' });
  } catch (err) {
    console.error('Packages Error (POST):', err);
    res.status(500).json({ error: err.message });
  }
});

export default router;
