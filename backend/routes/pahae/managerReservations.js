import { Router } from 'express';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

router.get('/', requireAuth, requireRole('manager'), async (req, res) => {
  const { search, filter } = req.query;
  try {
    let query = `
      SELECT r.id,
             DATE_FORMAT(r.reservedDate, '%Y-%m-%d') AS reservedDate,
             TIME_FORMAT(r.reservedTime, '%H:%i')    AS reservedTime,
             r.status,
             r.cancellationReason, r.rejectionReason, r.cancelledBy,
             cl.id AS clientID, cl.firstName AS clientFirstName,
             cl.lastName AS clientLastName, cl.avatarUrl AS clientAvatarUrl,
             co.id AS coachID, co.firstName AS coachFirstName,
             co.lastName AS coachLastName, co.avatarUrl AS coachAvatarUrl
      FROM reservations r
      JOIN users cl ON cl.id = r.clientID
      JOIN users co ON co.id = r.coachID
      WHERE 1=1`;
    const params = [];
    if (search) {
      query += ` AND (cl.firstName LIKE ? OR cl.lastName LIKE ?
                   OR co.firstName LIKE ? OR co.lastName LIKE ?)`;
      const s = `%${search}%`;
      params.push(s, s, s, s);
    }
    if (filter && filter !== 'All') {
      query += ` AND r.status = ?`;
      params.push(filter.toLowerCase());
    }
    query += ` ORDER BY r.reservedDate DESC, r.reservedTime DESC`;
    const [rows] = await pool.query(query, params);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.delete('/:id', requireAuth, requireRole('manager'), async (req, res) => {
  const { id } = req.params;
  try {
    const [[res_]] = await pool.query(`SELECT id FROM reservations WHERE id = ?`, [id]);
    if (!res_) return res.status(404).json({ message: 'Reservation not found.' });
    await pool.query(`DELETE FROM reservations WHERE id = ?`, [id]);
    res.json({ message: 'Reservation deleted.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
