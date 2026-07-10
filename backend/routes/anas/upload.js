import express from 'express';
const router = express.Router();
import cloudinaryPkg from 'cloudinary';
const cloudinary = cloudinaryPkg.v2;
import { CloudinaryStorage } from 'multer-storage-cloudinary';
import multer from 'multer';

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key:    process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

console.log('☁️ Cloudinary cloud_name:', process.env.CLOUDINARY_CLOUD_NAME);

const storage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder:          'fitlek/avatars',
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
    transformation:  [{ width: 400, height: 400, crop: 'fill', gravity: 'face' }],
    public_id:       (req, file) => `avatar_${req.query.userID || Date.now()}`,
    overwrite:       true,
  },
});

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

router.post('/avatar', (req, res) => {
  upload.single('avatar')(req, res, async (err) => {
    if (err) {
      console.error('❌ Multer/Cloudinary error:', err.message);
      return res.status(500).json({ error: err.message });
    }
    try {
      if (!req.file) return res.status(400).json({ error: 'No file uploaded' });
      console.log('✅ Uploaded to Cloudinary:', req.file.path);
      res.json({ url: req.file.path });
    } catch (e) {
      console.error('❌ Handler error:', e.message);
      res.status(500).json({ error: e.message });
    }
  });
});

export default router;