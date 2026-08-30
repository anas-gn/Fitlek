import { Router } from 'express';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';
import { createAndSendNotification } from '../../services/pushNotificationService.js';

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
         u.email,
         u.avatarUrl
       FROM invitations i
       JOIN users u ON u.id = i.invitedUserID
       WHERE i.coachID = ? AND u.role = 'client'
       ORDER BY (i.status = 'pending') DESC,
                COALESCE(i.clickedAt, i.respondedAt) DESC,
                i.id DESC`,
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
      `SELECT i.*
       FROM invitations i
       JOIN users u ON u.id = i.invitedUserID AND u.role = 'client'
       WHERE i.id = ? AND i.coachID = ? AND i.status = 'pending'
       FOR UPDATE`,
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

    // Client invitation reward. This is separate from the 40-point
    // Coach-to-Coach referral reward recorded in coachreferrals.
    await connection.query(
      `UPDATE coachprofiles
       SET earnedPoints = earnedPoints + 20
       WHERE userID = ?`,
      [coachID]
    );

    await connection.query(
      `INSERT IGNORE INTO coachclients (coachID, clientID) VALUES (?, ?)`,
      [coachID, inv.invitedUserID]
    );

    // An accepted client must immediately appear in both users' chat lists.
    // Reuse an existing conversation when one was already created elsewhere.
    let [[conversation]] = await connection.query(
      `SELECT id FROM conversations
       WHERE coachID = ? AND clientID = ?
       ORDER BY id ASC LIMIT 1`,
      [coachID, inv.invitedUserID]
    );
    if (!conversation) {
      const [conversationResult] = await connection.query(
        `INSERT INTO conversations (coachID, clientID) VALUES (?, ?)`,
        [coachID, inv.invitedUserID]
      );
      conversation = { id: conversationResult.insertId };
    }

    await connection.commit();

    // Notify client that coach accepted their request
    try {
      const [[coach]] = await pool.query('SELECT firstName, lastName, avatarUrl FROM users WHERE id = ?', [coachID]);
      const coachName = coach ? `${coach.firstName} ${coach.lastName}`.trim() : 'Coach';
      await createAndSendNotification({
        recipientUserID: inv.invitedUserID,
        type: 'invitation_accepted',
        title: 'Connection Accepted 🎉',
        body: `${coachName} accepted your connection request!`,
        relatedEntityID: invitationID,
        actorName: coachName,
        actorAvatar: coach?.avatarUrl ?? null,
        uniqueKey: `invitation_accepted:${invitationID}`
      });
    } catch (notifyErr) {
      console.error('invitation_accepted notification failed:', notifyErr.message);
    }

    res.json({
      message: 'Invitation accepted',
      pointsAwarded: 20,
      conversationID: conversation.id,
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

    // Notify client that coach declined their request
    try {
      const inv = rows[0];
      const [[coach]] = await pool.query('SELECT firstName, lastName, avatarUrl FROM users WHERE id = ?', [coachID]);
      const coachName = coach ? `${coach.firstName} ${coach.lastName}`.trim() : 'Coach';
      await createAndSendNotification({
        recipientUserID: inv.invitedUserID,
        type: 'invitation_declined',
        title: 'Invitation Status ℹ️',
        body: `${coachName} declined your connection request.`,
        relatedEntityID: invitationID,
        actorName: coachName,
        actorAvatar: coach?.avatarUrl ?? null,
        uniqueKey: `invitation_declined:${invitationID}`
      });
    } catch (notifyErr) {
      console.error('invitation_declined notification failed:', notifyErr.message);
    }

    res.json({
      message: 'Invitation declined'
    });

  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;