const express = require('express');
const router = express.Router();
const db = require('../../config/db');

router.get('/', async (req, res) => {
  try {
    const { page = 1, limit = 20, search, invitationCode } = req.query;
    const offset = (page - 1) * limit;
    let sql = `SELECT u.id, u.firstName, u.lastName, u.email, u.gender, u.avatarUrl,
               u.isPremium, cp.bio, cp.instagramPage, cp.invitationCode,
               cp.totalInvitations, cp.earnedPoints ,cp.tel ,cp.price
               FROM users u JOIN coachProfiles cp ON cp.userID = u.id
               WHERE u.role='coach' AND u.isApproved=1`;
    const params = [];

    // Recherche par invitationCode (recherche exacte)
    if (invitationCode) {
      sql += ' AND cp.invitationCode = ?';
      params.push(invitationCode);
    }

    // Recherche textuelle (nom/prénom)
    if (search) {
      sql += ' AND (u.firstName LIKE ? OR u.lastName LIKE ? OR cp.invitationCode LIKE ?)';
      params.push(`%${search}%`, `%${search}%`, `%${search}%`);
    }

    sql += ' ORDER BY cp.earnedPoints DESC LIMIT ? OFFSET ?';
    params.push(Number(limit), Number(offset));
    const [rows] = await db.query(sql, params);
    res.json(rows);
  } catch (err) { 
    res.status(500).json({ error: err.message }); 
  }
});

router.get('/:id', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT u.id, u.firstName, u.lastName, u.avatarUrl, u.isPremium,
              cp.bio, cp.instagramPage, cp.invitationCode, cp.totalInvitations, cp.earnedPoints, cp.tel, cp.price
       FROM users u JOIN coachProfiles cp ON cp.userID = u.id
       WHERE u.id=? AND u.role='coach' AND u.isApproved=1`,
      [req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Coach not found' });
    res.json(rows[0]);
  } catch (err) { 
    res.status(500).json({ error: err.message }); 
  }
});

router.get('/me/profile', async (req, res) => {
  try {
    const { userID } = req.query;
    const [rows] = await db.query('SELECT * FROM coachProfiles WHERE userID=?', [userID]);
    if (!rows.length) return res.status(404).json({ error: 'Profile not found' });
    res.json(rows[0]);
  } catch (err) { 
    res.status(500).json({ error: err.message }); 
  }
});

router.post('/me/profile', async (req, res) => {
  try {
    const { userID, bio, instagramPage, certificateUrl, invitationCode, advisorID, tel, price } = req.body;

    if (!userID || !bio || !instagramPage || !certificateUrl || !invitationCode) {
      return res.status(400).json({ 
        error: 'Missing required fields',
        required: ['userID', 'bio', 'instagramPage', 'certificateUrl', 'invitationCode'],
        optional: ['advisorID', 'tel', 'price']
      });
    }

    await db.query(
      'INSERT INTO coachProfiles (userID, bio, instagramPage, certificateUrl, invitationCode, advisorID) VALUES (?,?,?,?,?,?)',
      [userID, bio, instagramPage, certificateUrl, invitationCode, advisorID || null]
    );

    res.status(201).json({ 
      message: 'Coach profile created',
      userID,
      advisorID: advisorID || null
    });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ error: 'Invitation code already taken' });
    }
    res.status(500).json({ error: err.message });
  }
});

router.put('/me/profile', async (req, res) => {
  try {
    const { userID, bio, instagramPage, certificateUrl, tel, price } = req.body;

    const [existing] = await db.query('SELECT id FROM coachProfiles WHERE userID=?', [userID]);
    if (!existing.length) {
      return res.status(404).json({ error: 'Coach profile not found' });
    }

    await db.query(
      'UPDATE coachProfiles SET bio=?, instagramPage=?, certificateUrl=?, tel=?, price=? WHERE userID=?',
      [bio, instagramPage, certificateUrl, tel, price, userID]
    );

    res.json({ message: 'Profile updated' });
  } catch (err) { 
    res.status(500).json({ error: err.message }); 
  }
});

router.get('/me/stats', async (req, res) => {
  try {
    const { userID } = req.query;
    const [rows] = await db.query(
      'SELECT totalInvitations, earnedPoints, tel, price FROM coachProfiles WHERE userID=?', 
      [userID]
    );
    res.json(rows[0] || {});
  } catch (err) { 
    res.status(500).json({ error: err.message }); 
  }
});

module.exports = router;