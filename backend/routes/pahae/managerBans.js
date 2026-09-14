import { Router } from 'express';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

router.get('/', requireAuth, requireRole('manager'), async (req, res) => {
  const { filter } = req.query;
  try {
    let query = `
      SELECT b.id, b.banType, b.reason, b.bannedAt, b.expiresAt, b.isActive,
             u.id AS userID, u.firstName, u.lastName, u.avatarUrl, u.role AS userRole
      FROM bans b
      JOIN users u ON u.id = b.userID
      WHERE b.isActive = 1 AND (b.expiresAt IS NULL OR b.expiresAt > NOW())`;
    const params = [];
    if (filter === 'Temporary')  query += ` AND b.banType = 'temporary'`;
    if (filter === 'Permanent')  query += ` AND b.banType = 'permanent'`;
    if (filter === 'Clients')    query += ` AND u.role = 'client'`;
    if (filter === 'Coaches')    query += ` AND u.role = 'coach'`;
    query += ` ORDER BY b.bannedAt DESC`;
    const [rows] = await pool.query(query, params);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.patch('/:id/unban', requireAuth, requireRole('manager'), async (req, res) => {
  const managerID = req.user.id;
  const { id } = req.params;
  try {
    const [[ban]] = await pool.query(
      `SELECT id FROM bans WHERE id = ? AND isActive = 1`, [id]);
    if (!ban) return res.status(404).json({ message: 'Active ban not found.' });
    await pool.query(
      `UPDATE bans SET isActive = 0, liftedAt = NOW(), liftedBy = ? WHERE id = ?`,
      [managerID, id]
    );
    res.json({ message: 'User unbanned.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
