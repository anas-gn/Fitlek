import express from 'express';
const router = express.Router();
import db from '../../config/db.js';

router.get('/', async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    const [rows] = await db.query(
      `SELECT a.id, a.title, a.content, a.imageUrl, a.link, a.publishedAt,
              u.firstName, u.lastName, u.avatarUrl AS authorAvatar
       FROM actualites a
       JOIN users u ON u.id = a.adminID
       WHERE a.isPublished = 1
       ORDER BY a.publishedAt DESC
       LIMIT ? OFFSET ?`,
      [Number(limit), Number(offset)]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT a.id, a.title, a.content, a.imageUrl, a.link, a.publishedAt,
              u.firstName, u.lastName, u.avatarUrl AS authorAvatar
       FROM actualites a
       JOIN users u ON u.id = a.adminID
       WHERE a.id = ? AND a.isPublished = 1`,
      [req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Article not found' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const { adminID, title, content, imageUrl, link, isPublished = 1 } = req.body;
    if (!adminID || !title) {
      return res.status(400).json({ error: 'adminID and title are required' });
    }

    const [result] = await db.query(
      `INSERT INTO actualites (adminID, title, content, imageUrl, link, isPublished)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [adminID, title, content || null, imageUrl || null, link || null, isPublished]
    );
    res.status(201).json({ id: result.insertId, message: 'Article created' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const { title, content, imageUrl, link, isPublished } = req.body;

    const [existing] = await db.query(
      'SELECT id FROM actualites WHERE id = ?', [req.params.id]
    );
    if (!existing.length) return res.status(404).json({ error: 'Article not found' });

    await db.query(
      `UPDATE actualites
       SET title = COALESCE(?, title),
           content = COALESCE(?, content),
           imageUrl = COALESCE(?, imageUrl),
           link = COALESCE(?, link),
           isPublished = COALESCE(?, isPublished)
       WHERE id = ?`,
      [title || null, content || null, imageUrl || null, link || null,
       isPublished ?? null, req.params.id]
    );
    res.json({ message: 'Article updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const [result] = await db.query(
      'DELETE FROM actualites WHERE id = ?', [req.params.id]
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Article not found' });
    }
    res.json({ message: 'Article deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;