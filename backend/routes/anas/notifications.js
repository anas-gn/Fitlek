import express from 'express';
import db from '../../config/db.js';
import {requireAuth,requireRole} from '../../middleware/auth.js';
const router=express.Router();
router.use(requireAuth,requireRole('client','coach'));
router.get('/',async(req,res)=>{
  const page=Number(req.query.page||1);if(!Number.isSafeInteger(page)||page<1||page>10000)return res.status(400).json({message:'Invalid page'});
  try{const [rows]=await db.query('SELECT * FROM notifications WHERE recipientUserID=? ORDER BY createdAt DESC,id DESC LIMIT 31 OFFSET ?',[req.user.id,(page-1)*30]);res.json({data:rows.slice(0,30),hasMore:rows.length>30});}
  catch{res.status(500).json({message:'Failed to load notifications.'});}
});
router.put('/:id/read',async(req,res)=>{
  const id=Number(req.params.id);if(!Number.isSafeInteger(id)||id<1)return res.status(400).json({message:'Invalid notification'});
  try{const [rows]=await db.query('SELECT id FROM notifications WHERE id=? AND recipientUserID=?',[id,req.user.id]);if(!rows.length)return res.status(404).json({message:'Notification not found'});await db.query('UPDATE notifications SET isRead=1 WHERE id=? AND recipientUserID=?',[id,req.user.id]);res.json({saved:true});}
  catch{res.status(500).json({message:'Failed to update notification.'});}
});
export default router;
