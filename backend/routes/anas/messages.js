import express from 'express';
const router = express.Router();
import db from '../../config/db.js';
import {emitMessage, emitUser} from '../../services/realtime.js';
import { createAndSendNotification } from '../../services/pushNotificationService.js';
// GET /messages/:conversationID
router.get('/:conversationID', async (req, res) => {
  try {
    const { readerID } = req.query;
    const page = Math.max(1, Math.floor(Number(req.query.page) || 1));
    const limit = Math.min(100, Math.max(1, Math.floor(Number(req.query.limit) || 50)));
    const [[member]] = await db.query('SELECT id,coachID,clientID FROM conversations WHERE id=? AND (coachID=? OR clientID=?)', [req.params.conversationID,req.user.id,req.user.id]);
    if (!member) return res.status(403).json({error:'Access denied'});
    const offset = (page - 1) * limit;

    const [rows] = await db.query(
      `SELECT m.id, m.conversationID, m.senderID, m.body, CASE WHEN m.deletedAt IS NULL THEN m.mediaUrl ELSE NULL END AS mediaUrl, m.mediaType, m.mediaExpired, m.isRead, m.createdAt, m.deletedAt,
              CONCAT(u.firstName,' ',u.lastName) AS senderName, u.avatarUrl AS senderAvatar
       FROM messages m JOIN users u ON u.id = m.senderID
       WHERE m.conversationID=? AND NOT EXISTS(SELECT 1 FROM chat_hidden_messages h WHERE h.messageID=m.id AND h.userID=?) ORDER BY m.createdAt DESC,m.id DESC LIMIT ? OFFSET ?`,
      [req.params.conversationID, req.user.id, Number(limit), Number(offset)]
    );

    // Marquer comme lus les messages des autres
    if (readerID) {
      const [read] = await db.query(
        'UPDATE messages SET isRead=1 WHERE conversationID=? AND senderID != ? AND isRead=0',
        [req.params.conversationID, req.user.id]
      );
      if (read.affectedRows) emitUser(Number(req.user.id) === Number(member.clientID) ? member.coachID : member.clientID, 'data_changed', {domain:'read_receipts',conversationID:req.params.conversationID});
    }

    res.json(rows.reverse());
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// POST /messages/:conversationID
router.post('/:conversationID', async (req, res) => {
  try {
    const { body, mediaUrl, mediaType } = req.body;
    const senderID = req.user.id;
    if (!senderID || ((!body || !body.trim()) && !mediaUrl)) return res.status(400).json({ error: 'senderID and message content required' });

    // Vérifier que la conversation existe et que l'expéditeur en fait partie
    const [conv] = await db.query(
      'SELECT id, coachID, clientID FROM conversations WHERE id=? AND (coachID=? OR clientID=?)',
      [req.params.conversationID, senderID, senderID]
    );
    if (!conv.length) return res.status(404).json({ error: 'Conversation not found or access denied' });

    const [result] = await db.query(
      'INSERT INTO messages (conversationID, senderID, body, mediaUrl, mediaType) VALUES (?,?,?,?,?)',
      [req.params.conversationID, senderID, body ? body.trim() : null, mediaUrl || null, mediaType || 'text']
    );
    await db.query(
      'UPDATE conversations SET lastMessageAt=NOW() WHERE id=?',
      [req.params.conversationID]
    );

    // Notify recipient (coach or client) via in-app & push notification
    emitMessage({id:result.insertId,conversationID:Number(req.params.conversationID),senderID:Number(senderID),body:body?.trim() || null,mediaUrl:mediaUrl || null,mediaType:mediaType || 'text',isRead:false,createdAt:new Date().toISOString()},conv[0]);
    const { coachID, clientID } = conv[0];
    const recipientID = Number(senderID) === Number(clientID) ? coachID : clientID;

    try {
      const [[sender]] = await db.query(
        'SELECT firstName, lastName, avatarUrl FROM users WHERE id=?',
        [senderID]
      );
      const senderName = sender ? `${sender.firstName} ${sender.lastName}`.trim() : 'Someone';
      let pushBody = body ? body.trim() : '';
      if (mediaType === 'image') pushBody = '📷 Sent an image';
      if (mediaType === 'audio') pushBody = '🎤 Sent an audio message';

      await createAndSendNotification({
        recipientUserID: recipientID,
        type: 'new_message',
        title: `Message from ${senderName}`,
        body: pushBody.length > 80 ? `${pushBody.substring(0, 80)}...` : pushBody,
        relatedEntityID: req.params.conversationID,
        actorName: senderName,
        actorAvatar: sender?.avatarUrl ?? null,
        uniqueKey: `message:${result.insertId}:${recipientID}`
      });
    } catch (notifyErr) {
      console.error('new_message notification failed:', notifyErr.message);
    }

    res.status(201).json({
      id: result.insertId,
      conversationID: Number(req.params.conversationID),
      senderID,
      body: body ? body.trim() : null,
      mediaUrl,
      mediaType: mediaType || 'text',
      isRead: false,
      createdAt: new Date(),
    });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

export default router;
