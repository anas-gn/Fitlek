const express = require('express');
const router = express.Router();
const db = require('../../config/db');
const crypto = require('crypto');

// ═══════════════════════════════════════════════════════════════
// GET /invitations/me  —  Invitations envoyées par un coach
// ═══════════════════════════════════════════════════════════════
router.get('/me', async (req, res) => {
  try {
    const { coachID } = req.query;
    const [rows] = await db.query(
      `SELECT i.*, CONCAT(u.firstName,' ',u.lastName) AS invitedUserName
       FROM invitations i
       JOIN users u ON u.id = i.invitedUserID
       WHERE i.coachID=? ORDER BY i.clickedAt DESC`,
      [coachID]
    );
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ═══════════════════════════════════════════════════════════════
// POST /invitations/use  —  Utiliser un code d'invitation
// ═══════════════════════════════════════════════════════════════
router.post('/use', async (req, res) => {
  try {
    const { invitationCode, invitedUserID } = req.body;
    if (!invitationCode || !invitedUserID)
      return res.status(400).json({ error: 'invitationCode and invitedUserID required' });

    const [coach] = await db.query(
      'SELECT userID FROM coachProfiles WHERE invitationCode=?', [invitationCode]
    );
    if (!coach.length) return res.status(404).json({ error: 'Invalid invitation code' });

    const coachID = coach[0].userID;
    const [existing] = await db.query(
      'SELECT id FROM invitations WHERE coachID=? AND invitedUserID=?', [coachID, invitedUserID]
    );
    if (existing.length) return res.status(409).json({ error: 'Already used' });

    await db.query(
      'INSERT INTO invitations (coachID, invitedUserID, pointsEarned) VALUES (?,?,20)',
      [coachID, invitedUserID]
    );
    await db.query(
      'UPDATE coachProfiles SET totalInvitations=totalInvitations+1, earnedPoints=earnedPoints+20 WHERE userID=?',
      [coachID]
    );

    res.status(201).json({ message: 'Invitation registered', pointsAwarded: 20 });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ═══════════════════════════════════════════════════════════════
// POST /invitations/send  —  Envoyer une invitation À un coach
// (Le client envoie une invitation au coach pour le rejoindre)
// ═══════════════════════════════════════════════════════════════
router.post('/send', async (req, res) => {
  try {
    const { senderID, coachID, message } = req.body;

    // ── Validation ─────────────────────────────────────────────
    if (!senderID || !coachID) {
      return res.status(400).json({ error: 'senderID and coachID are required' });
    }

    // ── Vérifier l'expéditeur ──────────────────────────────────
    const [sender] = await db.query(
      'SELECT id, role FROM users WHERE id=?', [senderID]
    );
    if (!sender.length) {
      return res.status(404).json({ error: 'Sender not found' });
    }

    // ── Vérifier le coach ──────────────────────────────────────
    const [coach] = await db.query(
      `SELECT cp.userID, cp.invitationCode,
              u.email, CONCAT(u.firstName,' ',u.lastName) AS coachName
       FROM coachProfiles cp
       JOIN users u ON u.id = cp.userID
       WHERE cp.userID=?`,
      [coachID]
    );
    if (!coach.length) {
      return res.status(404).json({ error: 'Coach not found' });
    }

    // ── Auto-invitation interdite ──────────────────────────────
    if (parseInt(senderID) === parseInt(coachID)) {
      return res.status(400).json({ error: 'Cannot invite yourself' });
    }

    // ── Vérifier doublon ─────────────────────────────────────
    const [existing] = await db.query(
      'SELECT id FROM invitations WHERE coachID=? AND invitedUserID=?',
      [coachID, senderID]
    );
    if (existing.length) {
      return res.status(409).json({ error: 'Invitation already exists' });
    }

    // ── Créer l'invitation ─────────────────────────────────────
    const [result] = await db.query(
      `INSERT INTO invitations (coachID, invitedUserID, pointsEarned, clickedAt)
       VALUES (?, ?, 0, NOW())`,
      [coachID, senderID]
    );

    res.status(201).json({
      message: 'Invitation sent successfully',
      invitationId: result.insertId,
      coachName: coach[0].coachName,
      coachEmail: coach[0].email
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ═══════════════════════════════════════════════════════════════
// GET /invitations/received/:coachID  —  Invitations reçues
// par un coach (les clients qui l'ont invité)
// ═══════════════════════════════════════════════════════════════
router.get('/received/:coachID', async (req, res) => {
  try {
    const { coachID } = req.params;
    const [rows] = await db.query(
      `SELECT i.*,
        CONCAT(u.firstName,' ',u.lastName) AS senderName,
        u.avatarUrl AS senderAvatar
       FROM invitations i
       JOIN users u ON u.id = i.invitedUserID
       WHERE i.coachID=? AND i.pointsEarned = 0
       ORDER BY i.clickedAt DESC`,
      [coachID]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ═══════════════════════════════════════════════════════════════
// PATCH /invitations/:id/accept  —  Accepter une invitation
// (Le coach accepte → points gagnés)
// ═══════════════════════════════════════════════════════════════
router.patch('/:id/accept', async (req, res) => {
  try {
    const { id } = req.params;

    const [invitation] = await db.query(
      'SELECT * FROM invitations WHERE id=?', [id]
    );
    if (!invitation.length) {
      return res.status(404).json({ error: 'Invitation not found' });
    }

    // Déjà traitée (points déjà gagnés = déjà acceptée)
    if (invitation[0].pointsEarned > 0) {
      return res.status(400).json({ error: 'Invitation already accepted' });
    }

    // Mettre à jour l'invitation avec les points
    await db.query(
      'UPDATE invitations SET pointsEarned=20, clickedAt=NOW() WHERE id=?',
      [id]
    );

    // Incrémenter les stats du coach
    await db.query(
      'UPDATE coachProfiles SET totalInvitations=totalInvitations+1, earnedPoints=earnedPoints+20 WHERE userID=?',
      [invitation[0].coachID]
    );

    res.json({ message: 'Invitation accepted', pointsAwarded: 20 });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ═══════════════════════════════════════════════════════════════
// DELETE /invitations/:id  —  Refuser/supprimer une invitation
// ═══════════════════════════════════════════════════════════════
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const [invitation] = await db.query(
      'SELECT * FROM invitations WHERE id=?', [id]
    );
    if (!invitation.length) {
      return res.status(404).json({ error: 'Invitation not found' });
    }

    await db.query('DELETE FROM invitations WHERE id=?', [id]);
    res.json({ message: 'Invitation deleted' });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;