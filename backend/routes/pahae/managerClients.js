import { Router } from 'express';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

router.get('/', requireAuth, requireRole('manager'), async (req, res) => {
  const { search, filter } = req.query;
  try {
    let query = `
      SELECT u.id, u.firstName, u.lastName, u.email, u.gender,
             u.avatarUrl, u.isPremium, u.role,
             EXISTS(
               SELECT 1 FROM bans b
               WHERE b.userID = u.id AND b.isActive = 1
                 AND (b.expiresAt IS NULL OR b.expiresAt > NOW())
             ) AS isBanned
      FROM users u
      WHERE u.role IN ('client','admin')`;
    const params = [];
    if (search) {
      query += ` AND (u.firstName LIKE ? OR u.lastName LIKE ? OR u.email LIKE ?)`;
      const s = `%${search}%`;
      params.push(s, s, s);
    }
    if (filter === 'Premium')      query += ` AND u.isPremium = 1 AND u.role = 'client'`;
    else if (filter === 'Standard') query += ` AND u.isPremium = 0 AND u.role = 'client'`;
    else if (filter === 'Banned')   query += ` AND EXISTS(SELECT 1 FROM bans b WHERE b.userID = u.id AND b.isActive = 1 AND (b.expiresAt IS NULL OR b.expiresAt > NOW()))`;
    else if (filter === 'Remote Admin') query += ` AND u.role = 'admin'`;
    query += ` ORDER BY u.firstName ASC`;
    const [rows] = await pool.query(query, params);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.delete('/:id', requireAuth, requireRole('manager'), async (req, res) => {
  const { id } = req.params;
  try {
    const [[user]] = await pool.query(
      `SELECT id FROM users WHERE id = ? AND role IN ('client','admin')`,
      [id]
    );
    if (!user) return res.status(404).json({ message: 'Client not found.' });
    await pool.query(`DELETE FROM users WHERE id = ?`, [id]);
    res.json({ message: 'Client deleted.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.patch('/:id/make-admin', requireAuth, requireRole('manager'), async (req, res) => {
  const { id } = req.params;
  try {
    const [[user]] = await pool.query(
      `SELECT id, role FROM users WHERE id = ? AND role = 'client'`,
      [id]
    );
    if (!user) return res.status(404).json({ message: 'Client not found.' });
    await pool.query(`UPDATE users SET role = 'admin' WHERE id = ?`, [id]);
    res.json({ message: 'Client promoted to admin.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.post('/:id/ban', requireAuth, requireRole('manager'), async (req, res) => {
  const managerID = req.user.id;
  const { id } = req.params;
  const { banType, reason, expiresAt } = req.body;
  if (!banType || !reason) return res.status(400).json({ message: 'banType and reason are required.' });
  if (banType === 'temporary' && !expiresAt) {
    return res.status(400).json({ message: 'expiresAt is required for temporary bans.' });
  }
  try {
    const [[user]] = await pool.query(
      `SELECT id FROM users WHERE id = ? AND role IN ('client','admin','coach')`,
      [id]
    );
    if (!user) return res.status(404).json({ message: 'User not found.' });
    await pool.query(
      `INSERT INTO bans (userID, bannedBy, banType, reason, expiresAt)
       VALUES (?, ?, ?, ?, ?)`,
      [id, managerID, banType, reason, banType === 'permanent' ? null : expiresAt]
    );
    res.status(201).json({ message: 'User banned.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
