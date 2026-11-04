import {Router} from 'express';
import db from '../../config/db.js';
import {acknowledgeMedia} from '../../services/chatMediaDelivery.js';
const router=Router();
router.get('/removed',async(req,res)=>{
 try {
  const after=Math.max(0,Number(req.query.after)||0);
  const [rows]=await db.query(`SELECT m.id,m.deletedAt FROM messages m JOIN conversations c ON c.id=m.conversationID
    WHERE (c.coachID=? OR c.clientID=?) AND m.id>? AND (m.deletedAt IS NOT NULL OR
    EXISTS(SELECT 1 FROM chat_hidden_messages h WHERE h.messageID=m.id AND h.userID=?)) ORDER BY m.id ASC LIMIT 100`,[req.user.id,req.user.id,after,req.user.id]);
  res.json(rows);
 }catch(_){res.status(503).json({error:'Media removal temporarily unavailable'});}
});
router.get('/pending',async(req,res)=>{
 try {
  const after=Math.max(0,Number(req.query.after)||0);
  const [rows]=await db.query(`SELECT m.id,m.mediaUrl,m.mediaType,m.mediaExpired FROM messages m
    JOIN conversations c ON c.id=m.conversationID WHERE (c.coachID=? OR c.clientID=?)
    AND m.mediaType IN ('image','audio') AND m.mediaExpired=0 AND m.deletedAt IS NULL AND m.id>?
    AND NOT EXISTS(SELECT 1 FROM chat_hidden_messages h WHERE h.messageID=m.id AND h.userID=?)
    AND NOT EXISTS(SELECT 1 FROM chat_media_receipts r WHERE r.messageID=m.id AND r.userID=?)
    ORDER BY m.id ASC LIMIT 50`,[req.user.id,req.user.id,after,req.user.id,req.user.id]);
  res.json(rows);
 } catch(_){res.status(503).json({error:'Media delivery temporarily unavailable'});}
});
router.post('/:id/saved',async(req,res)=>{
 if (!/^[1-9]\d*$/.test(req.params.id) || !/^[a-f0-9]{64}$/.test(req.body.sha256 ?? '')) return res.status(400).json({error:'A saved-file checksum is required'});
 try {await acknowledgeMedia(db,req.user.id,req.params.id,req.body.sha256);res.json({saved:true});}
 catch(error){res.status(error.status || 503).json({error:error.status ? error.message : 'Could not confirm saved media'});}
});
export default router;
