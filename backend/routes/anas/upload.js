import express from 'express';
const router = express.Router();
import multer from 'multer';
import sharp from 'sharp';
import path from 'path';
import fs from 'fs';
import db from '../../config/db.js';

const storage = multer.memoryStorage();
const uploadImage = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const isImage = file.mimetype.startsWith('image/')
                 || file.mimetype === 'application/octet-stream'
                 || file.mimetype === '';
    if (isImage) cb(null, true);
    else cb(new Error('Only image files allowed'), false);
  },
});

const uploadAudio = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB limit for audio
  fileFilter: (req, file, cb) => {
    const isAudio = file.mimetype.startsWith('audio/')
                 || file.mimetype.startsWith('video/mp4') // Sometimes m4a is sent as video/mp4
                 || file.mimetype === 'application/octet-stream'
                 || file.mimetype === '';
    if (isAudio) cb(null, true);
    else cb(new Error('Only audio files allowed'), false);
  },
});

router.post('/avatar', (req, res) => {
  uploadImage.single('avatar')(req, res, async (err) => {
    if (err) {
      console.error('❌ Multer error:', err.message);
      return res.status(500).json({ error: err.message });
    }
    try {
      if (!req.file) return res.status(400).json({ error: 'No file uploaded' });
      
      const uploadDir = path.join(process.cwd(), 'uploads', 'avatars');
      if (!fs.existsSync(uploadDir)) {
        fs.mkdirSync(uploadDir, { recursive: true });
      }

      const filename = `avatar_${req.user.id}_${Date.now()}_${Math.round(Math.random()*1e9)}.webp`;
      const filepath = path.join(uploadDir, filename);
      
      await sharp(req.file.buffer)
        .rotate()
        .resize(400, 400, { fit: 'cover', position: 'attention' })
        .webp({ quality: 80 })
        .toFile(filepath);

      const url = `${req.protocol}://${req.get('host')}/uploads/avatars/${filename}`;
      console.log('✅ Uploaded local avatar:', url);
      res.json({ url });
    } catch (e) {
      console.error('❌ Handler error:', e.message);
      res.status(500).json({ error: e.message });
    }
  });
});

router.post('/certification', (req, res) => {
  uploadImage.single('certificate')(req, res, async (err) => {
    if (err) {
      console.error('❌ Multer error:', err.message);
      return res.status(500).json({ error: err.message });
    }
    try {
      if (!req.file) return res.status(400).json({ error: 'No file uploaded' });
      
      const uploadDir = path.join(process.cwd(), 'uploads', 'certifications');
      if (!fs.existsSync(uploadDir)) {
        fs.mkdirSync(uploadDir, { recursive: true });
      }

      const filename = `cert_${Date.now()}_${Math.round(Math.random() * 1e9)}.webp`;
      const filepath = path.join(uploadDir, filename);

      await sharp(req.file.buffer)
        .resize({ width: 1200, withoutEnlargement: true })
        .webp({ quality: 80 })
        .toFile(filepath);

      const url = `${req.protocol}://${req.get('host')}/uploads/certifications/${filename}`;
      console.log('✅ Uploaded local certification:', url);
      
      return res.json({ url });
    } catch (error) {
      console.error('❌ Error processing certification:', error);
      res.status(500).json({ error: 'Error processing image' });
    }
  });
});

router.post('/coach-gallery', (req, res) => {
  uploadImage.single('image')(req, res, async (err) => {
    if (err) {
      console.error('❌ Multer error:', err.message);
      return res.status(500).json({ error: err.message });
    }
    try {
      if (!req.file) return res.status(400).json({ error: 'No file uploaded' });
      const coachID = req.body.coachID;
      if (!coachID) return res.status(400).json({ error: 'coachID required' });

      // Check if max 5 images reached
      const [existing] = await db.query('SELECT COUNT(*) as count FROM coachimages WHERE coachID = ?', [coachID]);
      if (existing[0].count >= 5) {
        return res.status(400).json({ error: 'Maximum 5 images allowed for the gallery' });
      }
      
      const uploadDir = path.join(process.cwd(), 'uploads', 'coach_gallery');
      if (!fs.existsSync(uploadDir)) {
        fs.mkdirSync(uploadDir, { recursive: true });
      }

      const filename = `gallery_${coachID}_${Date.now()}.webp`;
      const filepath = path.join(uploadDir, filename);
      
      await sharp(req.file.buffer)
        .rotate()
        .resize(1000, 1000, { fit: 'inside', withoutEnlargement: true })
        .webp({ quality: 85 })
        .toFile(filepath);

      const url = `${req.protocol}://${req.get('host')}/uploads/coach_gallery/${filename}`;
      
      const [result] = await db.query('INSERT INTO coachimages (coachID, urlImage) VALUES (?, ?)', [coachID, url]);

      console.log('✅ Uploaded local coach gallery image:', url);
      res.json({ id: result.insertId, urlImage: url });
    } catch (e) {
      console.error('❌ Handler error:', e.message);
      res.status(500).json({ error: e.message });
    }
  });
});

router.post('/chat-image', (req, res) => {
  uploadImage.single('image')(req, res, async (err) => {
    if (err) {
      console.error('❌ Multer error:', err.message);
      return res.status(500).json({ error: err.message });
    }
    try {
      if (!req.file) return res.status(400).json({ error: 'No file uploaded' });

      const uploadDir = path.join(process.cwd(), 'uploads', 'chat_media');
      if (!fs.existsSync(uploadDir)) {
        fs.mkdirSync(uploadDir, { recursive: true });
      }

      const filename = `chat_img_${Date.now()}_${Math.floor(Math.random() * 1000)}.webp`;
      const filepath = path.join(uploadDir, filename);

      await sharp(req.file.buffer)
        .resize(1000, 1000, { fit: 'inside', withoutEnlargement: true })
        .webp({ quality: 75 })
        .toFile(filepath);

      const url = `${req.protocol}://${req.get('host')}/uploads/chat_media/${filename}`;
      console.log('✅ Uploaded chat image:', url);
      res.json({ url });
    } catch (e) {
      console.error('❌ Handler error:', e.message);
      res.status(500).json({ error: e.message });
    }
  });
});

router.post('/chat-audio', (req, res) => {
  uploadAudio.single('audio')(req, res, async (err) => {
    if (err) {
      console.error('❌ Multer error:', err.message);
      return res.status(500).json({ error: err.message });
    }
    try {
      if (!req.file) return res.status(400).json({ error: 'No file uploaded' });

      const uploadDir = path.join(process.cwd(), 'uploads', 'chat_media');
      if (!fs.existsSync(uploadDir)) {
        fs.mkdirSync(uploadDir, { recursive: true });
      }

      // Keep original extension or assume m4a from Flutter
      let ext = req.file.originalname.split('.').pop();
      if (!ext || ext === req.file.originalname) {
        ext = 'm4a'; // Default extension for AAC
      }
      
      const filename = `chat_aud_${Date.now()}_${Math.floor(Math.random() * 1000)}.${ext}`;
      const filepath = path.join(uploadDir, filename);

      fs.writeFileSync(filepath, req.file.buffer);

      const url = `${req.protocol}://${req.get('host')}/uploads/chat_media/${filename}`;
      console.log('✅ Uploaded chat audio:', url);
      res.json({ url });
    } catch (e) {
      console.error('❌ Handler error:', e.message);
      res.status(500).json({ error: e.message });
    }
  });
});
router.post('/package-image', (req, res) => {
  uploadImage.single('file')(req, res, async (err) => {
    if (err) {
      console.error('❌ Multer error:', err.message);
      return res.status(500).json({ error: err.message });
    }
    try {
      if (!req.file) return res.status(400).json({ error: 'No file uploaded' });
      
      const uploadDir = path.join(process.cwd(), 'uploads', 'packages');
      if (!fs.existsSync(uploadDir)) {
        fs.mkdirSync(uploadDir, { recursive: true });
      }

      const filename = `pkg_${Date.now()}_${Math.round(Math.random() * 1e9)}.webp`;
      const filepath = path.join(uploadDir, filename);

      await sharp(req.file.buffer)
        .resize({ width: 1200, withoutEnlargement: true })
        .webp({ quality: 80 })
        .toFile(filepath);

      const url = `${req.protocol}://${req.get('host')}/uploads/packages/${filename}`;
      console.log('✅ Uploaded package image:', url);
      
      return res.json({ fileUrl: url });
    } catch (error) {
      console.error('❌ Error processing package image:', error);
      res.status(500).json({ error: 'Error processing image' });
    }
  });
});
router.post('/gym-image', (req, res) => {
  uploadImage.single('file')(req, res, async (err) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    try {
      if (!req.file) return res.status(400).json({ error: 'No file uploaded' });
      
      const uploadDir = path.join(process.cwd(), 'uploads', 'gyms');
      if (!fs.existsSync(uploadDir)) {
        fs.mkdirSync(uploadDir, { recursive: true });
      }

      const filename = `gym_${Date.now()}_${Math.round(Math.random() * 1e9)}.webp`;
      const filepath = path.join(uploadDir, filename);

      await sharp(req.file.buffer)
        .resize({ width: 1200, withoutEnlargement: true })
        .webp({ quality: 80 })
        .toFile(filepath);

      const url = `${req.protocol}://${req.get('host')}/uploads/gyms/${filename}`;
      return res.json({ fileUrl: url });
    } catch (error) {
      res.status(500).json({ error: 'Error processing image' });
    }
  });
});

export default router;
