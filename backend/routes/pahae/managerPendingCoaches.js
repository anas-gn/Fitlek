import { Router } from 'express';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

router.get('/', requireAuth, requireRole('manager'), async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT u.id, u.firstName, u.lastName, u.email, u.gender, u.avatarUrl,
              cp.bio, cp.instagramPage,
              (cp.certificateUrl IS NOT NULL) AS hasCertificate
       FROM users u
       JOIN coachProfiles cp ON cp.userID = u.id
       WHERE u.role = 'coach' AND u.isApproved = 0
       ORDER BY u.createdAt ASC`
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.patch('/:id/accept', requireAuth, requireRole('manager'), async (req, res) => {
  const { id } = req.params;
  try {
    const [[coach]] = await pool.query(
      `SELECT id FROM users WHERE id = ? AND role = 'coach' AND isApproved = 0`, [id]);
    if (!coach) return res.status(404).json({ message: 'Pending coach not found.' });
    await pool.query(`UPDATE users SET isApproved = 1 WHERE id = ?`, [id]);
    res.json({ message: 'Coach approved.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.patch('/:id/reject', requireAuth, requireRole('manager'), async (req, res) => {
  const { id } = req.params;
  const { reason } = req.body;
  if (!reason) return res.status(400).json({ message: 'Rejection reason is required.' });
  try {
    const [[coach]] = await pool.query(
      `SELECT id FROM users WHERE id = ? AND role = 'coach' AND isApproved = 0`, [id]);
    if (!coach) return res.status(404).json({ message: 'Pending coach not found.' });
    await pool.query(`DELETE FROM users WHERE id = ?`, [id]);
    res.json({ message: 'Coach rejected and removed.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/:id/certificate', requireAuth, requireRole('manager'), async (req, res) => {
  const { id } = req.params;
  try {
    const [[row]] = await pool.query(
      `SELECT cp.certificateUrl FROM coachProfiles cp
       JOIN users u ON u.id = cp.userID
       WHERE u.id = ? AND u.role = 'coach' AND u.isApproved = 0`,
      [id]
    );
    if (!row || !row.certificateUrl) {
      return res.status(404).json({ message: 'Certificate not found.' });
    }
    const base64 = Buffer.from(row.certificateUrl).toString('base64');
    res.json({ base64 });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
