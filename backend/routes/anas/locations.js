import {Router} from 'express';
import db from '../../config/db.js';
import {requireRole} from '../../middleware/auth.js';
import {saveUserLocation,normalizeLocation} from '../../services/userLocation.js';
const router=Router();
router.use(requireRole('client','coach'));
router.get('/me',async(req,res)=>{
  try{const [[row]]=await db.query('SELECT *,UNIX_TIMESTAMP(updatedAt) AS updatedAtEpoch FROM user_locations WHERE userID=?',[req.user.id]);if(row)return res.json(row);const [[user]]=await db.query('SELECT ville FROM users WHERE id=?',[req.user.id]);res.json({city:String(user?.ville||'').split(',')[0].trim(),autoRefresh:0});}catch(error){res.status(500).json({error:'Could not load your location.'});}
});
router.put('/me',async(req,res)=>{
  try{normalizeLocation(req.body);}catch(error){return res.status(400).json({error:error.message});}
  const tx=await db.getConnection();
  try{await tx.beginTransaction();const location=await saveUserLocation(tx,req.user.id,req.user.role,req.body);await tx.commit();res.json({city:location.city});}
  catch(error){await tx.rollback();res.status(500).json({error:'Could not save your location.'});}finally{tx.release();}
});
export default router;
