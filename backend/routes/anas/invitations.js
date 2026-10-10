import express from 'express';
import {ownIdentity} from '../../middleware/ownership.js';
import safeCoachInvitations from '../pahae/coachInvitations.js';
import db from '../../config/db.js';
import { createAndSendNotification } from '../../services/pushNotificationService.js';

const router = express.Router();

// ─────────────────────────────────────────────
//  GET /invitations/me
//  Le coach voit TOUTES ses invitations reçues
//  (avec les infos de l'utilisateur invité)
// ─────────────────────────────────────────────
router.get('/me', ownIdentity('coachID',['coach']), async (req, res) => {
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
router.post('/use', ownIdentity('invitedUserID',['client']), async (req, res) => {
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
      'INSERT INTO invitations (coachID, invitedUserID, status, pointsEarned) VALUES (?, ?, "pending", 0)',
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
router.post('/send', ownIdentity('senderID',['client']), async (req, res) => {
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

    // Crée l'invitation (clickedAt defaults to CURRENT_TIMESTAMP in DB).
    const [result] = await db.query(
      'INSERT INTO invitations (coachID, invitedUserID, status, pointsEarned, clickedAt) VALUES (?, ?, "pending", 0, NOW())',
      [coachID, senderID]
    );

    // Notify the coach via in-app & push notification
    try {
      const [[client]] = await db.query(
        'SELECT firstName, lastName, avatarUrl FROM users WHERE id = ?',
        [senderID]
      );
      const clientName = client
        ? `${client.firstName || ''} ${client.lastName || ''}`.trim() || 'A client'
        : 'A client';
      await createAndSendNotification({
        recipientUserID: coachID,
        type: 'new_invitation',
        title: 'New Connection Request 🤝',
        body: `${clientName} wants to connect with you.`,
        relatedEntityID: result.insertId,
        actorName: clientName,
        actorAvatar: client?.avatarUrl ?? null,
        uniqueKey: `invitation:${result.insertId}:coach:${coachID}`
      });
    } catch (notifyErr) {
      console.error('new_invitation notification failed:', notifyErr.message);
    }

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
router.patch('/:id/accept', (req,res,next)=>safeCoachInvitations.handle(req,res,next));
// GET /invitations/status/:coachID/:clientID
router.get('/status/:coachID/:clientID', async (req, res) => {
  try {
    const { coachID, clientID } = req.params;
    if(!((req.user.role==='coach' && Number(coachID)===Number(req.user.id)) || (req.user.role==='client' && Number(clientID)===Number(req.user.id)))) return res.status(403).json({error:'Access denied.'});
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
router.patch('/:id/refuse', (req,res,next)=>safeCoachInvitations.handle(req,res,next));

export default router;