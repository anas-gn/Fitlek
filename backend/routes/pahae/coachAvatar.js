import express from 'express';
const router = express.Router();
import multer from 'multer';
 import sharp from 'sharp';
import path from 'path';
import fs from 'fs';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const storage = multer.memoryStorage();
const upload = multer({
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

router.post('/avatar', requireAuth, requireRole('coach'), (req, res) => {
  upload.single('avatar')(req, res, async (err) => {
    if (err) {
      console.error('Multer error:', err.message);
      return res.status(500).json({ ok: false, error: err.message });
    }
    try {
      if (!req.file) return res.status(400).json({ ok: false, error: 'No file uploaded' });
      
      const uploadDir = path.join(process.cwd(), 'uploads', 'avatars');
      if (!fs.existsSync(uploadDir)) {
        fs.mkdirSync(uploadDir, { recursive: true });
      }

      const filename = `avatar_${req.query.userID || req.user?.id || req.user?._id || Date.now()}.webp`;
      const filepath = path.join(uploadDir, filename);
      
      await sharp(req.file.buffer)
        .resize(400, 400, { fit: 'cover', position: 'attention' })
        .webp({ quality: 80 })
        .toFile(filepath);

      const url = `${req.protocol}://${req.get('host')}/uploads/avatars/${filename}`;
      console.log('✅ Uploaded local avatar:', url);
      res.json({ ok: true, url });
    } catch (e) {
      console.error('Handler error:', e.message);
      res.status(500).json({ ok: false, error: e.message });
    }
  });
});

export default router;