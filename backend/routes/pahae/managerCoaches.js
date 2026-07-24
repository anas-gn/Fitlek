import { Router } from 'express';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

router.get('/', requireAuth, requireRole('manager'), async (req, res) => {
  const { search, filter } = req.query;
  try {
    let query = `
      SELECT u.id, u.firstName, u.lastName, u.email, u.gender, u.avatarUrl, u.isApproved,
             cp.bio, cp.instagramPage, cp.invitationCode, cp.earnedPoints, cp.totalInvitations,
             (cp.certificateUrl IS NOT NULL) AS hasCertificate,
             (SELECT COUNT(*) FROM coachClients cc WHERE cc.coachID = u.id) AS totalClients,
             (SELECT COUNT(*) FROM reservations r WHERE r.coachID = u.id) AS totalReservations,
             EXISTS(
               SELECT 1 FROM bans b
               WHERE b.userID = u.id AND b.isActive = 1
                 AND (b.expiresAt IS NULL OR b.expiresAt > NOW())
             ) AS isBanned
      FROM users u
      JOIN coachProfiles cp ON cp.userID = u.id
      WHERE u.role = 'coach'`;
    const params = [];
    if (search) {
      query += ` AND (u.firstName LIKE ? OR u.lastName LIKE ? OR u.email LIKE ?)`;
      const s = `%${search}%`;
      params.push(s, s, s);
    }
    if (filter === 'Active')  query += ` AND u.isApproved = 1 AND NOT EXISTS(SELECT 1 FROM bans b WHERE b.userID = u.id AND b.isActive = 1)`;
    if (filter === 'Banned')  query += ` AND EXISTS(SELECT 1 FROM bans b WHERE b.userID = u.id AND b.isActive = 1 AND (b.expiresAt IS NULL OR b.expiresAt > NOW()))`;
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
    const [[coach]] = await pool.query(
      `SELECT id FROM users WHERE id = ? AND role = 'coach'`, [id]);
    if (!coach) return res.status(404).json({ message: 'Coach not found.' });
    await pool.query(`DELETE FROM users WHERE id = ?`, [id]);
    res.json({ message: 'Coach deleted.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
