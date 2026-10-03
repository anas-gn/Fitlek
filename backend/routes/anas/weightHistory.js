import express from 'express';
const router = express.Router();
import db from '../../config/db.js';
import {requireAuth,requireRole} from '../../middleware/auth.js';

// Workout reuses these records; every read/write follows the SIRVYA identity.
router.use(requireAuth,requireRole('client','coach'),async(req,res,next)=>{
  try {
    const body=req.body??{};
    const [[account]]=await db.query('SELECT role FROM users WHERE id=?',[req.user.id]);
    if(!account||account.role!==req.user.role)return res.status(401).json({message:'authentication_expired'});
    if(req.method==='GET'){
      const clientID=Number(req.query.clientID??req.user.id);
      if(!Number.isSafeInteger(clientID)||clientID<1)return res.status(400).json({message:'invalid_client'});
      if(req.user.role==='client'&&clientID!==Number(req.user.id))return res.status(403).json({message:'unauthorized_client'});
      if(req.user.role==='coach'){
        const [linked]=await db.query('SELECT id FROM coachclients WHERE coachID=? AND clientID=?',[req.user.id,clientID]);
        if(!linked.length)return res.status(403).json({message:'unauthorized_client'});
      }
      req.queryScopeClientID=clientID;
    }else{
      if(req.user.role!=='client'||body.clientID!=null&&Number(body.clientID)!==Number(req.user.id))return res.status(403).json({message:'unauthorized_client'});
      if(req.method!=='DELETE'){
        const weight=Number(body.weight);
        if(!Number.isFinite(weight)||weight<1||weight>500||typeof body.note==='string'&&body.note.length>2000)return res.status(400).json({message:'invalid_weight'});
      }
      if(req.params.id){
        const [entry]=await db.query('SELECT id FROM weighthistory WHERE id=? AND clientID=?',[req.params.id,req.user.id]);
        if(!entry.length)return res.status(404).json({message:'weight_not_found'});
      }
    }
    next();
  }catch {res.status(500).json({message:'weight_history_error'});}
});
// GET /weight-history/me
router.get('/me', async (req, res) => {
  try {
    const clientID=req.queryScopeClientID;
    const limit=Number(req.query.limit??30),page=Number(req.query.page??1);
    if(!Number.isInteger(limit)||limit<1||limit>100||!Number.isInteger(page)||page<1||page>10000)return res.status(400).json({message:'invalid_page'});
    if (!clientID) return res.status(400).json({ error: 'clientID required' });

    const offset = (page - 1) * limit;
    const [rows] = await db.query(
      `SELECT id, clientID, weight, note, recordedAt, createdAt 
       FROM weighthistory 
       WHERE clientID=? 
       ORDER BY createdAt DESC 
       LIMIT ? OFFSET ?`,
      [clientID, Number(limit), Number(offset)]
    );
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// GET /weight-history/me/stats
router.get('/me/stats', async (req, res) => {
  try {
    const clientID=req.queryScopeClientID;
    if (!clientID) return res.status(400).json({ error: 'clientID required' });

    const [rows] = await db.query(
      `SELECT 
        (SELECT weight FROM weighthistory WHERE clientID=? ORDER BY createdAt DESC LIMIT 1) as currentWeight,
        (SELECT weight FROM weighthistory WHERE clientID=? ORDER BY createdAt ASC LIMIT 1) as startWeight,
        MAX(weight) as maxWeight,
        MIN(weight) as minWeight,
        COUNT(*) as totalEntries
       FROM weighthistory WHERE clientID=?`,
      [clientID, clientID, clientID]
    );

    const stats = rows[0];
    const totalLoss = stats.startWeight && stats.currentWeight
      ? (stats.startWeight - stats.currentWeight).toFixed(2) : 0;

    res.json({
      currentWeight: stats.currentWeight,
      startWeight: stats.startWeight,
      maxWeight: stats.maxWeight,
      minWeight: stats.minWeight,
      totalEntries: stats.totalEntries,
      totalLoss: parseFloat(totalLoss),
    });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// GET /weight-history/me/chart
// Retourne le DERNIER poids enregistré pour chaque jour (pas la moyenne)
router.get('/me/chart', async (req, res) => {
  try {
    const clientID=req.queryScopeClientID;
    if (!clientID) return res.status(400).json({ error: 'clientID required' });

    const [rows] = await db.query(
      `SELECT 
        DATE_FORMAT(createdAt, '%d/%m') as label,
        DATE(createdAt) as day,
        weight
       FROM weighthistory w1
       WHERE clientID=?
         AND createdAt = (
           SELECT MAX(w2.createdAt) 
           FROM weighthistory w2 
           WHERE w2.clientID = w1.clientID 
             AND DATE(w2.createdAt) = DATE(w1.createdAt)
         )
       GROUP BY DATE(createdAt), DATE_FORMAT(createdAt, '%d/%m'), weight
       ORDER BY day ASC
       LIMIT 30`,
      [clientID]
    );

    const data = rows.map(r => ({ label: r.label, weight: parseFloat(r.weight) }));
    res.json(data);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// POST /weight-history
router.post('/', async (req, res) => {
  try {
    const { weight, note } = req.body;const clientID=req.user.id;
    if (!clientID || weight === undefined) {
      return res.status(400).json({ error: 'clientID and weight required' });
    }

    const [result] = await db.query(
      'INSERT INTO weighthistory (clientID, weight, recordedAt, note) VALUES (?, ?, CURDATE(), ?)',
      [clientID, weight, note || null]
    );
    res.status(201).json({ message: 'Weight recorded', id: result.insertId });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// PUT /weight-history/:id
router.put('/:id', async (req, res) => {
  try {
    const { weight, note } = req.body;
    const [changed]=await db.query('UPDATE weighthistory SET weight=?, note=? WHERE id=? AND clientID=?',
      [weight, note || null, req.params.id,req.user.id]);
    if(!changed.affectedRows)return res.status(404).json({message:'weight_not_found'});
    res.json({ message: 'Weight updated' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// DELETE /weight-history/:id
router.delete('/:id', async (req, res) => {
  try {
    const [changed]=await db.query('DELETE FROM weighthistory WHERE id=? AND clientID=?', [req.params.id,req.user.id]);
    if(!changed.affectedRows)return res.status(404).json({message:'weight_not_found'});
    res.json({ message: 'Weight entry deleted' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

export default router;
