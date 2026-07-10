import express from 'express';
import db from '../../config/db.js';

const router = express.Router();

// ─────────────────────────────────────────────
//  GET /invitations/me
//  Le coach voit TOUTES ses invitations reçues
//  (avec les infos de l'utilisateur invité)
// ─────────────────────────────────────────────
router.get('/me', async (req, res) => {
  try {
    const { coachID } = req.query;
    if (!coachID) return res.status(400).json({ error: 'coachID required' });

    const [rows] = await db.query(
      `SELECT 
         i.id,
         i.coachID,
         i.invitedUserID,
         i.status,
         i.clickedAt,
         i.respondedAt,
         CONCAT(u.firstName,' ',u.lastName) AS invitedUserName,
         u.firstName,
         u.lastName,
         u.avatarUrl AS invitedUserAvatar
       FROM invitations i 
       JOIN users u ON u.id = i.invitedUserID
       WHERE i.coachID = ?
       ORDER BY i.clickedAt DESC`,
      [coachID]
    );
    res.json(rows);
  } catch (err) { 
    res.status(500).json({ error: err.message }); 
  }
});

// ─────────────────────────────────────────────
//  POST /invitations/use
//  Le client utilise un code d'invitation
// ─────────────────────────────────────────────
router.post('/use', async (req, res) => {
  try {
    const { invitationCode, invitedUserID } = req.body;
    if (!invitationCode || !invitedUserID)
      return res.status(400).json({ error: 'invitationCode and invitedUserID required' });

    // Récupère le coach via son code d'invitation
    const [coach] = await db.query(
      'SELECT userID FROM coachprofiles WHERE invitationCode = ?', 
      [invitationCode]
    );
    if (!coach.length) return res.status(404).json({ error: 'Invalid invitation code' });

    const coachID = coach[0].userID;

    // Vérifie si déjà utilisé
    const [existing] = await db.query(
      'SELECT id FROM invitations WHERE coachID = ? AND invitedUserID = ?', 
      [coachID, invitedUserID]
    );
    if (existing.length) return res.status(409).json({ error: 'Already used' });

    // Crée l'invitation en "pending"
    const [result] = await db.query(
      'INSERT INTO invitations (coachID, invitedUserID, status) VALUES (?, ?, "pending")',
      [coachID, invitedUserID]
    );

    res.status(201).json({ 
      message: 'Invitation en attente de validation', 
      id: result.insertId 
    });
  } catch (err) { 
    res.status(500).json({ error: err.message }); 
  }
});

// ─────────────────────────────────────────────
//  POST /invitations/send
//  Le client envoie une invitation directe au coach
//  (utilisé par CoachDetailScreen)
// ─────────────────────────────────────────────
router.post('/send', async (req, res) => {
  try {
    const { senderID, coachID } = req.body;
    if (!senderID || !coachID)
      return res.status(400).json({ error: 'senderID and coachID required' });

    // Vérifie si déjà invité
    const [existing] = await db.query(
      'SELECT id FROM invitations WHERE coachID = ? AND invitedUserID = ?',
      [coachID, senderID]
    );
    if (existing.length) return res.status(409).json({ error: 'Already invited' });

    // Crée l'invitation
    const [result] = await db.query(
      'INSERT INTO invitations (coachID, invitedUserID, status) VALUES (?, ?, "pending")',
      [coachID, senderID]
    );

    res.status(201).json({ 
      message: 'Invitation envoyée', 
      id: result.insertId 
    });
  } catch (err) { 
    res.status(500).json({ error: err.message }); 
  }
});

// ─────────────────────────────────────────────
//  GET /invitations/received/:coachID
//  Vérifie si un client a déjà invité ce coach
//  (utilisé par CoachDetailScreen)
// ─────────────────────────────────────────────
router.get('/received/:coachID', async (req, res) => {
  try {
    const { coachID } = req.params;
    const [rows] = await db.query(
      'SELECT * FROM invitations WHERE coachID = ?',
      [coachID]
    );
    res.json(rows);
  } catch (err) { 
    res.status(500).json({ error: err.message }); 
  }
});

// ─────────────────────────────────────────────
//  PATCH /invitations/:id/accept
//  Le coach ACCEPTE l'invitation
// ─────────────────────────────────────────────
router.patch('/:id/accept', async (req, res) => {
  try {
    // Vérifie que l'invitation existe et est en "pending" ou "refused"
    const [rows] = await db.query(
      'SELECT * FROM invitations WHERE id = ? AND status IN ("pending", "refused")', 
      [req.params.id]
    );
    if (!rows.length) 
      return res.status(404).json({ error: 'Invitation introuvable ou déjà acceptée' });

    const inv = rows[0];

    // Met à jour l'invitation
    await db.query(
      'UPDATE invitations SET status = "accepted", respondedAt = NOW() WHERE id = ?', 
      [req.params.id]
    );

    // Met à jour les stats du coach (+1 invitation, +20 points)
    await db.query(
      'UPDATE coachprofiles SET totalInvitations = totalInvitations + 1, earnedPoints = earnedPoints + 20 WHERE userID = ?',
      [inv.coachID]
    );

    // Crée le lien coach-client
    await db.query(
      'INSERT IGNORE INTO coachclients (coachID, clientID) VALUES (?, ?)',
      [inv.coachID, inv.invitedUserID]
    );

    res.json({ 
      message: 'Invitation acceptée', 
      pointsAwarded: 20 
    });
  } catch (err) { 
    res.status(500).json({ error: err.message }); 
  }
});
// GET /invitations/status/:coachID/:clientID
router.get('/status/:coachID/:clientID', async (req, res) => {
  try {
    const { coachID, clientID } = req.params;
    const [rows] = await db.query(
      'SELECT status FROM invitations WHERE coachID = ? AND invitedUserID = ? LIMIT 1',
      [coachID, clientID]
    );
    if (!rows.length) return res.json({ status: null });
    res.json({ status: rows[0].status });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
// ─────────────────────────────────────────────
//  PATCH /invitations/:id/refuse
//  Le coach REFUSE l'invitation
// ─────────────────────────────────────────────
router.patch('/:id/refuse', async (req, res) => {
  try {
    // Vérifie que l'invitation existe et est en "pending"
    const [rows] = await db.query(
      'SELECT * FROM invitations WHERE id = ? AND status = "pending"', 
      [req.params.id]
    );
    if (!rows.length) 
      return res.status(404).json({ error: 'Invitation introuvable ou déjà traitée' });

    // Met à jour l'invitation
    await db.query(
      'UPDATE invitations SET status = "refused", respondedAt = NOW() WHERE id = ?', 
      [req.params.id]
    );

    res.json({ 
      message: 'Invitation refusée' 
    });
  } catch (err) { 
    res.status(500).json({ error: err.message }); 
  }
});

export default router;