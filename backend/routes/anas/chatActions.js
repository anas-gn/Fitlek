import {Router} from 'express';
import db from '../../config/db.js';
import {deleteChatMessages} from '../../services/chatDeletion.js';
import {emitUser} from '../../services/realtime.js';
const router=Router();
router.get('/:conversationID/hidden',async(req,res)=>{
 try {
  const [rows]=await db.query(`SELECT m.id,m.deletedAt,(h.userID IS NOT NULL) AS hidden FROM messages m JOIN conversations c ON c.id=m.conversationID
    LEFT JOIN chat_hidden_messages h ON h.messageID=m.id AND h.userID=? WHERE c.id=? AND (c.coachID=? OR c.clientID=?) AND (h.userID IS NOT NULL OR m.deletedAt IS NOT NULL)`,[req.user.id,req.params.conversationID,req.user.id,req.user.id]);
  res.json(rows);
 }catch(_){res.status(503).json({message:'Chat temporarily unavailable.'});}
});
router.post('/:conversationID/delete',async(req,res)=>{
 const {messageIDs,scope}=req.body;
 if(!['me','everyone'].includes(scope)||!Array.isArray(messageIDs)||messageIDs.length<1||messageIDs.length>100||messageIDs.some(id=>!Number.isSafeInteger(id)||id<=0)||new Set(messageIDs).size!==messageIDs.length||!/^[1-9]\d*$/.test(req.params.conversationID)) return res.status(400).json({message:'Invalid message selection.'});
 try {
  const conversation=await deleteChatMessages(db,req.user.id,req.params.conversationID,messageIDs,scope);
  const event={domain:'chat-actions',conversationID:conversation.id};
  emitUser(req.user.id,'data_changed',event);
  if(scope==='everyone') emitUser(Number(req.user.id)===Number(conversation.coachID)?conversation.clientID:conversation.coachID,'data_changed',event);
  res.json({ok:true});
 }catch(error){res.status(error.status||500).json({message:error.status?error.message:'Could not delete messages. Please try again.'});}
});
export default router;
