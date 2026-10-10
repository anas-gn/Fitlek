import express from 'express';
const router = express.Router();
import db from '../../config/db.js';
import {ownIdentity} from '../../middleware/ownership.js';
// ─── Routes spécifiques d'abord (/me avant /:userId) ───
//
// GET /advisors/me?userID=:id  — Profil de l'advisor actuel
router.get('/me', ownIdentity('userID',['advisor']), async (req, res) => {
  try {
    const userID=req.user.id;
    if (!userID) return res.status(400).json({ error: 'userID required' });
    const [rows] = await db.query(
      `SELECT ap.*, u.createdAt AS userCreatedAt
       FROM advisorprofiles ap
       JOIN users u ON u.id = ap.userID
       WHERE ap.userID = ?`,
      [userID]
    );
    if (!rows.length) return res.status(404).json({ error: 'Not found' });
    const row = rows[0];
    res.json({
      ...row,
      createdAt: row.createdAt || row.userCreatedAt,
    });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// POST /advisors/me  — Créer le profil advisor
router.post('/me', ownIdentity('userID',['advisor']), async (req, res) => {
  try {
    const { specialty, location, companyName } = req.body;
    const userID=req.user.id;
    if (!userID || !specialty) return res.status(400).json({ error: 'userID and specialty required' });
    await db.query(
      'INSERT INTO advisorprofiles (userID, specialty, location, companyName) VALUES (?,?,?,?)',
      [userID, specialty, location || null, companyName || null]
    );
    res.status(201).json({ message: 'Advisor profile created' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// PUT /advisors/me  — Modifier le profil advisor
router.put('/me', ownIdentity('userID',['advisor']), async (req, res) => {
  try {
    const { specialty, location, companyName } = req.body;
    const userID=req.user.id;
    if (!userID) return res.status(400).json({ error: 'userID required' });
    await db.query(
      'UPDATE advisorprofiles SET specialty=?, location=?, companyName=? WHERE userID=?',
      [specialty || null, location || null, companyName || null, userID]
    );
    res.json({ message: 'Updated' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ─── Routes paramétrées ensuite (:userId) ───
//
// GET /advisors/:userId/coaches  — Coaches liés à cet advisor
router.get('/:userId/coaches', async (req, res) => {
  if (!['manager','admin'].includes(req.user.role) && !(req.user.role==='advisor' && Number(req.params.userId)===Number(req.user.id))) return res.status(403).json({error:'Access denied.'});
  try {
    const [rows] = await db.query(
      `SELECT u.id, u.firstName, u.lastName, u.avatarUrl,
              u.isPremium, u.isApproved,
              cp.bio, cp.instagramPage, cp.invitationCode,
              cp.earnedPoints, cp.totalInvitations
       FROM users u
       JOIN coachprofiles cp ON cp.userID = u.id
       WHERE u.role = 'coach'
         AND cp.advisorID = ?
       ORDER BY cp.earnedPoints DESC`,
      [req.params.userId]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur.', error: err.message });
  }
});

// GET /advisors/:advisorID/revenue  — Revenus par mois (6 derniers mois)
router.get('/:advisorID/revenue', async (req, res) => {
  if (!['manager','admin'].includes(req.user.role) && !(req.user.role==='advisor' && Number(req.params.advisorID)===Number(req.user.id))) return res.status(403).json({error:'Access denied.'});
  try {
    const [rows] = await db.query(
      `SELECT
         DATE_FORMAT(r.reservedDate, '%Y-%m') AS month,
         DATE_FORMAT(r.reservedDate, '%b')    AS label,
         COUNT(*)                             AS sessions,
         SUM(r.price)                         AS revenue
       FROM reservations r
       JOIN coachprofiles cp ON cp.userID = r.coachID
       WHERE cp.advisorID = ?
         AND r.status = 'confirmed'
         AND r.reservedDate >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
       GROUP BY DATE_FORMAT(r.reservedDate, '%Y-%m'), DATE_FORMAT(r.reservedDate, '%b')
       ORDER BY month ASC`,
      [req.params.advisorID]
    );
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});
// GET /advisors/:advisorID/images  — Images de la salle (table imageAdvisor)
router.get('/:advisorID/images', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT id, UrlImage AS urlImage
       FROM imageadvisor
       WHERE idAdvisor = ?
       ORDER BY id ASC`,
      [req.params.advisorID]
    );
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});
// GET /advisors  — Liste de tous les advisors
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT u.id, u.firstName, u.lastName, u.email, u.avatarUrl,
              ap.specialty, ap.location, ap.companyName, ap.createdAt,ap.ville
       FROM users u JOIN advisorprofiles ap ON ap.userID = u.id
       WHERE u.role='advisor' ORDER BY u.createdAt DESC`
    );
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

export default router;