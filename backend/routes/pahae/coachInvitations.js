import { Router } from 'express';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

router.get('/', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  try {
    const [rows] = await pool.query(
      `SELECT 
         i.id,
         i.coachID,
         i.invitedUserID,
         i.status,
         i.pointsEarned,
         i.clickedAt,
         i.respondedAt,
         u.firstName,
         u.lastName,
         u.avatarUrl
       FROM invitations i
       JOIN users u ON u.id = i.invitedUserID
       WHERE i.coachID = ?
       ORDER BY i.clickedAt DESC`,
      [coachID]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.patch('/:id/accept', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  const invitationID = req.params.id;

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const [rows] = await connection.query(
      `SELECT * FROM invitations 
       WHERE id = ? AND coachID = ? AND status = 'pending'`,
      [invitationID, coachID]
    );

    if (!rows.length) {
      await connection.rollback();
      return res.status(404).json({ 
        message: 'Invitation introuvable ou déjà traitée' 
      });
    }

    const inv = rows[0];

    await connection.query(
      `UPDATE invitations 
       SET status = 'accepted', respondedAt = NOW(), pointsEarned = 20 
       WHERE id = ?`,
      [invitationID]
    );

    await connection.query(
      `UPDATE coachprofiles 
       SET totalInvitations = totalInvitations + 1, 
           earnedPoints = earnedPoints + 20 
       WHERE userID = ?`,
      [coachID]
    );

    await connection.query(
      `INSERT IGNORE INTO coachclients (coachID, clientID) VALUES (?, ?)`,
      [coachID, inv.invitedUserID]
    );

    await connection.commit();

    res.json({ 
      message: 'Invitation acceptée', 
      pointsAwarded: 20 
    });

  } catch (err) {
    await connection.rollback();
    res.status(500).json({ message: err.message });
  } finally {
    connection.release();
  }
});

router.patch('/:id/refuse', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  const invitationID = req.params.id;

  try {
    const [rows] = await pool.query(
      `SELECT * FROM invitations 
       WHERE id = ? AND coachID = ? AND status = 'pending'`,
      [invitationID, coachID]
    );

    if (!rows.length) {
      return res.status(404).json({ 
        message: 'Invitation introuvable ou déjà traitée' 
      });
    }

    await pool.query(
      `UPDATE invitations 
       SET status = 'refused', respondedAt = NOW() 
       WHERE id = ?`,
      [invitationID]
    );

    res.json({ 
      message: 'Invitation refusée' 
    });

  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;