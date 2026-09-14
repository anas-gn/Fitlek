import express from 'express';
const router = express.Router();
import db from '../../config/db.js';
import fs from 'fs';
import path from 'path';
router.get('/', async (req, res) => {
  try {
    const { page = 1, limit = 20, search, invitationCode } = req.query;
    const offset = (page - 1) * limit;
    const requesterID = req.user.id;
    let sql = `SELECT u.id, u.firstName, u.lastName, u.email, u.gender, u.avatarUrl,
               u.isPremium, cp.bio, cp.instagramPage, cp.invitationCode,
               cp.totalInvitations, cp.earnedPoints ,cp.tel ,cp.price , cp.ville
               FROM users u JOIN coachprofiles cp ON cp.userID = u.id
               WHERE u.role='coach' AND u.isApproved=1
                 AND u.id NOT IN (SELECT blockedID FROM user_blocks WHERE blockerID = ?)
                 AND u.id NOT IN (SELECT blockerID FROM user_blocks WHERE blockedID = ?)`;
    const params = [requesterID, requesterID];

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
    const requesterID = req.user.id;
    const [rows] = await db.query(
      `SELECT u.id, u.firstName, u.lastName, u.avatarUrl, u.isPremium,
              cp.bio, cp.instagramPage, cp.invitationCode, cp.totalInvitations, 
              cp.earnedPoints, cp.tel, cp.price, cp.ville   
       FROM users u JOIN coachprofiles cp ON cp.userID = u.id
       WHERE u.id=? AND u.role='coach' AND u.isApproved=1
         AND u.id NOT IN (SELECT blockedID FROM user_blocks WHERE blockerID = ?)
         AND u.id NOT IN (SELECT blockerID FROM user_blocks WHERE blockedID = ?)`,
      [req.params.id, requesterID, requesterID]
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
    const [rows] = await db.query('SELECT * FROM coachprofiles WHERE userID=?', [userID]);
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
      'INSERT INTO coachprofiles (userID, bio, instagramPage, certificateUrl, invitationCode, advisorID , ville) VALUES (?,?,?,?,?,?)',
      [userID, bio, instagramPage, certificateUrl, invitationCode, advisorID || null, req.body.ville || null]
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
    const { userID, bio, instagramPage, certificateUrl, tel, price, ville } = req.body;

    const [existing] = await db.query('SELECT id FROM coachprofiles WHERE userID=?', [userID]);
    if (!existing.length) {
      return res.status(404).json({ error: 'Coach profile not found' });
    }

    await db.query(
      'UPDATE coachprofiles SET bio=?, instagramPage=?, certificateUrl=?, tel=?, price=COALESCE(?, price), ville=? WHERE userID=?',
      [bio, instagramPage, certificateUrl, tel, price ?? null, ville || null, userID]
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
      'SELECT totalInvitations, earnedPoints, tel, price, ville FROM coachprofiles WHERE userID=?', 
      [userID]
    );
    res.json(rows[0] || {});
  } catch (err) { 
    res.status(500).json({ error: err.message }); 
  }
});

// GET /coaches/:id/images  — Images for coach gallery
router.get('/:id/images', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT id, urlImage
       FROM coachimages
       WHERE coachID = ?
       ORDER BY id ASC`,
      [req.params.id]
    );
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// DELETE /coaches/:id/images/:imageId
router.delete('/:id/images/:imageId', async (req, res) => {
  try {
    // Get the image url first to delete the file
    const [rows] = await db.query('SELECT urlImage FROM coachimages WHERE id = ? AND coachID = ?', [req.params.imageId, req.params.id]);
    if (rows.length > 0) {
      const url = rows[0].urlImage;
      const filename = url.split('/').pop();
      const filepath = path.join(process.cwd(), 'uploads', 'coach_gallery', filename);
      
      if (fs.existsSync(filepath)) {
        fs.unlinkSync(filepath);
      }
      
      await db.query('DELETE FROM coachimages WHERE id = ? AND coachID = ?', [req.params.imageId, req.params.id]);
      res.json({ message: 'Image deleted' });
    } else {
      res.status(404).json({ error: 'Image not found' });
    }
  } catch (err) { res.status(500).json({ error: err.message }); }
});

export default router;