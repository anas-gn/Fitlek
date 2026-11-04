import {withCoachDistances} from '../../services/coachDistance.js';
import express from 'express';
const router = express.Router();
import db from '../../config/db.js';
import fs from 'fs';
import path from 'path';
import {coachMapPoint} from '../../services/coachMap.js';
import {requireRole} from '../../middleware/auth.js';

router.get('/map', requireRole('client'), async (req, res) => {
  try {
    const [rows] = await db.query(`SELECT u.id,l.latitude,l.longitude FROM users u
      JOIN coachprofiles cp ON cp.userID=u.id JOIN user_locations l ON l.userID=u.id
      WHERE u.role='coach' AND l.latitude IS NOT NULL AND l.longitude IS NOT NULL
      AND u.id NOT IN (SELECT blockedID FROM user_blocks WHERE blockerID=?)
      AND u.id NOT IN (SELECT blockerID FROM user_blocks WHERE blockedID=?)`, [req.user.id,req.user.id]);
    res.json(rows.map(coachMapPoint).filter(Boolean));
  } catch (error) {
    res.status(500).json({error:'Could not load coach locations.'});
  }
});
router.get('/', async (req, res) => {
  try {
    const { page = 1, limit = 20, search, invitationCode, categoryID, specialty } = req.query;
    const offset = (page - 1) * limit;
    const requesterID = req.user.id;
    let sql = `SELECT u.id, u.firstName, u.lastName, u.email, u.gender, u.avatarUrl,
               u.isPremium, cp.bio, cp.instagramPage, cp.invitationCode,
               cp.totalInvitations, cp.earnedPoints, cp.tel, cp.price, cp.ville, cp.categoryID,
               cat.name AS categoryName, cat.icon AS categoryIcon,
               cp.certifications, cp.specialties,
               u.isApproved,
               (SELECT MIN(price) FROM coach_packages WHERE coachID = u.id AND isActive = 1) AS minPrice,
               (CASE WHEN EXISTS (
                   SELECT 1 FROM coachavailabilityblocks 
                   WHERE coachID = u.id 
                   AND blockedDate = CURRENT_DATE() 
                   AND startTime <= CURRENT_TIME() 
                   AND endTime >= '23:59:00'
               ) THEN 0 ELSE 1 END) AS isAvailableToday
               FROM users u JOIN coachprofiles cp ON cp.userID = u.id
               LEFT JOIN categories cat ON cat.id = cp.categoryID
               WHERE u.role='coach'
                 AND u.id NOT IN (SELECT blockedID FROM user_blocks WHERE blockerID = ?)
                 AND u.id NOT IN (SELECT blockerID FROM user_blocks WHERE blockedID = ?)`;
    const params = [requesterID, requesterID];

    // Recherche par catégorie
    if (categoryID) {
      sql += ' AND cp.categoryID = ?';
      params.push(Number(categoryID));
    }

    // Recherche par spécialité
    if (specialty && specialty !== 'All') {
      sql += ' AND (cp.specialties LIKE ? OR cp.specialty LIKE ?)';
      params.push(`%${specialty}%`, `%${specialty}%`);
    }

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
    res.json(await withCoachDistances(db, rows, req.user));
  } catch (err) { 
    res.status(500).json({ error: err.message }); 
  }
});

// GET /api/coaches/specialties — returns list of filled specialties with coach count
router.get('/specialties', async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT cp.specialties, cp.specialty
      FROM users u
      JOIN coachprofiles cp ON cp.userID = u.id
      WHERE u.role = 'coach'
    `);

    const [categories] = await db.query('SELECT id, name, icon FROM categories ORDER BY sortOrder ASC');
    const categoryByName = new Map(categories.map(category => [category.name.trim().toLocaleLowerCase(), category]));
    const countMap = new Map();
    for (const row of rows) {
      const set = new Set();
      if (row.specialties) {
        try {
          let list = [];
          if (typeof row.specialties === 'string') {
            if (row.specialties.trim().startsWith('[')) {
              list = JSON.parse(row.specialties);
            } else {
              list = row.specialties.split(/[,/]/).map(s => s.trim());
            }
          } else if (Array.isArray(row.specialties)) {
            list = row.specialties;
          }
          for (const s of list) {
            const trimmed = String(s).trim();
            if (trimmed) set.add(trimmed);
          }
        } catch (_) {}
      }
      if (row.specialty && String(row.specialty).trim()) {
        set.add(String(row.specialty).trim());
      }
      for (const spec of set) {
        countMap.set(spec, (countMap.get(spec) || 0) + 1);
      }
    }

    const result = Array.from(countMap.entries())
      .filter(([name, count]) => count > 0)
      .map(([name, coachCount], index) => ({
        id: categoryByName.get(name.toLocaleLowerCase())?.id ?? index + 1,
        name,
        coachCount,
        icon: categoryByName.get(name.toLocaleLowerCase())?.icon ?? 'fitness_center'
      }))
      .sort((a, b) => b.coachCount - a.coachCount || a.name.localeCompare(b.name));

    res.json(result);
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
              cp.earnedPoints, cp.tel, cp.price, cp.ville, cp.categoryID,
              cat.name AS categoryName, cat.icon AS categoryIcon,
              cp.certifications, cp.specialties, cp.gymName, cp.gymAddress, cp.gymImage,
              u.isApproved,
              (SELECT MIN(price) FROM coach_packages WHERE coachID = u.id AND isActive = 1) AS minPrice,
              (CASE WHEN EXISTS (
                  SELECT 1 FROM coachavailabilityblocks 
                  WHERE coachID = u.id 
                  AND blockedDate = CURRENT_DATE() 
                  AND startTime <= CURRENT_TIME() 
                  AND endTime >= '23:59:00'
              ) THEN 0 ELSE 1 END) AS isAvailableToday
       FROM users u JOIN coachprofiles cp ON cp.userID = u.id
       LEFT JOIN categories cat ON cat.id = cp.categoryID
       WHERE u.id=? AND u.role='coach'
         AND u.id NOT IN (SELECT blockedID FROM user_blocks WHERE blockerID = ?)
         AND u.id NOT IN (SELECT blockerID FROM user_blocks WHERE blockedID = ?)`,
      [req.params.id, requesterID, requesterID]
    );
    if (!rows.length) return res.status(404).json({ error: 'Coach not found' });
    res.json((await withCoachDistances(db, rows, req.user))[0]);
  } catch (err) { 
    res.status(500).json({ error: err.message }); 
  }
});

router.get('/me/profile', async (req, res) => {
  try {
    const userID = req.user.id;
    const [rows] = await db.query(
      `SELECT cp.*, u.firstName, u.lastName, u.email, u.gender, u.avatarUrl, u.isApproved
       FROM coachprofiles cp 
       JOIN users u ON cp.userID = u.id 
       WHERE cp.userID=?`, 
      [userID]
    );
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

    const cleanInstagram = instagramPage ? instagramPage.trim().replace(/^@+/, '') : null;

    await db.query(
      'INSERT INTO coachprofiles (userID, bio, instagramPage, certificateUrl, invitationCode, advisorID , ville) VALUES (?,?,?,?,?,?)',
      [userID, bio, cleanInstagram, certificateUrl, invitationCode, advisorID || null, req.body.ville || null]
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
    const { 
      userID, bio, instagramPage, certificateUrl, tel, price, ville,
      firstName, lastName, gender, professionalTitle, languages, showGender,
      coachingFormats, gymName, gymAddress, gymImage, serviceArea,
      publicProfile, directMessaging
    } = req.body;

    const [existing] = await db.query('SELECT id FROM coachprofiles WHERE userID=?', [userID]);
    if (!existing.length) {
      return res.status(404).json({ error: 'Coach profile not found' });
    }

    const cleanInstagram = instagramPage !== undefined 
      ? (instagramPage ? instagramPage.trim().replace(/^@+/, '') : '') 
      : null;

    await db.query(
      `UPDATE coachprofiles SET 
        bio=COALESCE(?, bio), 
        instagramPage=COALESCE(?, instagramPage), 
        certificateUrl=COALESCE(?, certificateUrl), 
        tel=COALESCE(?, tel), 
        price=COALESCE(?, price), 
        ville=COALESCE(?, ville),
        professionalTitle=COALESCE(?, professionalTitle),
        languages=COALESCE(?, languages),
        showGender=COALESCE(?, showGender),
        coachingFormats=COALESCE(?, coachingFormats),
        gymName=COALESCE(?, gymName),
        gymAddress=COALESCE(?, gymAddress),
        gymImage=COALESCE(?, gymImage),
        serviceArea=COALESCE(?, serviceArea),
        publicProfile=COALESCE(?, publicProfile),
        directMessaging=COALESCE(?, directMessaging)
       WHERE userID=?`,
      [
        bio ?? null, 
        cleanInstagram, 
        certificateUrl ?? null, 
        tel ?? null, 
        price ?? null, 
        ville ?? null, 
        professionalTitle ?? null, 
        languages ?? null, 
        showGender ?? null, 
        coachingFormats ? JSON.stringify(coachingFormats) : null, 
        gymName ?? null, 
        gymAddress ?? null,
        gymImage ?? null, 
        serviceArea ?? null,
        publicProfile ?? null,
        directMessaging ?? null,
        userID
      ]
    );

    if (firstName || lastName || gender !== undefined) {
      await db.query(
        `UPDATE users SET 
          firstName=COALESCE(?, firstName), 
          lastName=COALESCE(?, lastName), 
          gender=COALESCE(?, gender) 
         WHERE id=?`,
        [firstName, lastName, gender, userID]
      );
    }

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
      `SELECT id, urlImage, caption
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

// PUT /coaches/:id/images/:imageId
router.put('/:id/images/:imageId', async (req, res) => {
  try {
    const { caption } = req.body;
    await db.query(
      'UPDATE coachimages SET caption = ? WHERE id = ? AND coachID = ?', 
      [caption, req.params.imageId, req.params.id]
    );
    res.json({ message: 'Image caption updated' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

export default router;
