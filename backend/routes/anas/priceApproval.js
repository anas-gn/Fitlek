import {Router} from 'express';
import {presentSessionLocation} from '../../services/sessionLocation.js';
import {sessionClock,validOffer,expirePriceRequests} from '../../services/priceApproval.js';
export function priceApprovalRouter(db,notify){
 const router=Router();
 router.patch('/notifications/read-all',async(req,res)=>{try{await db.query('UPDATE notifications SET isRead=1 WHERE recipientUserID=? AND isRead=0',[req.user.id]);res.json({ok:true})}catch(error){res.status(500).json({error:error.message})}});
 router.get('/invitations/:id/details',async(req,res)=>{try{const [[row]]=await db.query('SELECT i.id,cv.id AS conversationID FROM invitations i LEFT JOIN conversations cv ON cv.coachID=i.coachID AND cv.clientID=i.invitedUserID WHERE i.id=? AND (i.invitedUserID=? OR i.coachID=?)',[req.params.id,req.user.id,req.user.id]);if(!row)return res.status(404).json({error:'Connection request unavailable'});res.json(row)}catch(error){res.status(500).json({error:error.message})}});
 router.get('/notifications/unread',async(req,res)=>{try{const [[row]]=await db.query('SELECT COUNT(*) AS count FROM notifications WHERE recipientUserID=? AND isRead=0',[req.user.id]);res.json(row)}catch(error){res.status(500).json({error:error.message})}});
 router.patch('/notifications/:id/read',async(req,res)=>{try{await db.query('UPDATE notifications SET isRead=1 WHERE id=? AND recipientUserID=?',[req.params.id,req.user.id]);res.json({ok:true})}catch(error){res.status(500).json({error:error.message})}});
 router.get('/notifications/mine',async(req,res)=>{
  try{const [rows]=await db.query('SELECT id,type,title,body,relatedEntityID,actorName,actorAvatar,isRead,createdAt FROM notifications WHERE recipientUserID=? ORDER BY createdAt DESC LIMIT 50',[req.user.id]);res.json(rows)}catch(error){res.status(500).json({error:error.message})}
 });
 router.get('/:id/details',async(req,res)=>{
  try{await expirePriceRequests(db,notify);const [rows]=await db.query("SELECT r.*,cr.rating AS reviewRating,cr.comment AS reviewComment,CONCAT(u.firstName,' ',u.lastName) AS coachName,u.avatarUrl AS coachAvatar FROM reservations r JOIN users u ON u.id=r.coachID LEFT JOIN coachreviews cr ON cr.coachID=r.coachID AND cr.clientID=r.clientID WHERE r.id=? AND (r.clientID=? OR r.coachID=?)",[req.params.id,req.user.id,req.user.id]);if(!rows.length)return res.status(404).json({error:'Session not found'});res.json(presentSessionLocation(rows[0]))}catch(error){res.status(500).json({error:error.message})}
 });
 async function mutate(req,res,action){
  if(action==='offer'&&!validOffer(req.body.price))return res.status(400).json({error:'Enter a valid price in MAD (up to two decimals).'});
  await expirePriceRequests(db,notify);
  const tx=await db.getConnection();let notification;
  try{
   await tx.beginTransaction();
   const [[row]]=await tx.query('SELECT *,TIMESTAMP(reservedDate,reservedTime)<=DATE_ADD(?,INTERVAL 2 HOUR) AS deadlinePassed FROM reservations WHERE id=? FOR UPDATE',[sessionClock(),req.params.id]);
   if(!row){const e=new Error('Session not found');e.status=404;throw e}
   if((action==='offer'&&(req.user.role!=='coach'||Number(row.coachID)!==Number(req.user.id)))||(action!=='offer'&&(req.user.role!=='client'||Number(row.clientID)!==Number(req.user.id)))){const e=new Error('Access denied');e.status=403;throw e}
   if(row.status!=='pending'||row.deadlinePassed||!['awaiting','proposed'].includes(row.pricingStatus))throw new Error('This price request is no longer available.');
   if(action==='offer'){
    if(row.pricingStatus==='proposed')throw new Error('An offer is already waiting for the client.');
    await tx.query("UPDATE reservations SET pricingStatus='proposed',proposedPrice=?,quoteVersion=quoteVersion+1,priceProposedAt=NOW() WHERE id=?",[Number(req.body.price),row.id]);
    notification={recipientUserID:row.clientID,type:'price_proposed',title:'Price approval needed',body:`Your coach proposed ${Number(req.body.price).toFixed(2)} MAD. Accept or decline in Session details before the two-hour deadline.`,relatedEntityID:row.id,uniqueKey:`price_offer:${row.id}:${row.quoteVersion+1}`};
   }else{
    if(row.pricingStatus!=='proposed'||Number(req.body.quoteVersion)!==Number(row.quoteVersion))throw new Error('The offer changed. Refresh the session before responding.');
    if(action==='accept')await tx.query("UPDATE reservations SET price=proposedPrice,pricingStatus='accepted',priceAcceptedAt=NOW(),status='confirmed' WHERE id=?",[row.id]);
    else await tx.query("UPDATE reservations SET pricingStatus='declined',status='cancelled',cancellationReason='Client declined the proposed price' WHERE id=?",[row.id]);
    notification={recipientUserID:row.coachID,type:action==='accept'?'price_accepted':'price_declined',title:action==='accept'?'Price accepted — session confirmed':'Price declined',body:action==='accept'?'The client accepted your price. The session is confirmed.':'The client declined your price. This booking is cancelled.',relatedEntityID:row.id,uniqueKey:`price_reply:${row.id}:${row.quoteVersion}`};
   }
   await tx.commit();
  }catch(error){await tx.rollback();return res.status(error.status||409).json({error:error.message})}finally{tx.release()}
  try{await notify(notification)}catch(error){console.error('Price notification failed',error.message)}
  res.json({ok:true});
 }
 router.patch('/:id/price',async(req,res)=>{try{await mutate(req,res,'offer')}catch(error){res.status(500).json({error:error.message})}});
 for(const action of ['accept','decline'])router.patch(`/:id/price/${action}`,async(req,res)=>{try{await mutate(req,res,action)}catch(error){res.status(500).json({error:error.message})}});
 return router;
}
