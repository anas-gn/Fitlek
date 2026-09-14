import express from 'express';
import db from '../../config/db.js';
import { requireAuth } from '../../middleware/auth.js';

const router = express.Router();

router.get('/status', requireAuth, async (req, res) => {
  try {
    // Always grant premium access for free version
    res.json({ hasAccess: true, subscription: null });
  } catch (error) {
    res.status(500).json({ error: 'Unable to load Premium status.' });
  }
});

export default router;
