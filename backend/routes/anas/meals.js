import express from 'express';
import multer from 'multer';
import sharp from 'sharp';
import { requireAuth, requireRole } from '../../middleware/auth.js';
import pool from '../../config/db.js';
import { createNutritionRouter } from '../../services/nutritionDiary.js';
import { readMealAllowance, reserveMealScan, refundMealScan, MealQuotaError } from '../../services/mealQuota.js';
import { analyzeMeal, MealError } from '../../services/mealAnalysis.js';
import { decorateMeal, publicIngredientCatalog } from '../../services/ingredientCatalog.js';
import { fileURLToPath } from 'node:url';

const router = express.Router();
router.use('/diary', createNutritionRouter(pool));
router.use('/ingredients', express.static(fileURLToPath(new URL('../../public/ingredients', import.meta.url)), {
  maxAge: '7d', immutable: false, dotfiles: 'deny', index: false,
}));
router.get('/catalog', (req, res) => {
  res.set('Cache-Control', 'public, max-age=3600');
  res.json(publicIngredientCatalog());
});
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 6 * 1024 * 1024, files: 1, fields: 2, fieldSize: 2000 } });
// Short burst/concurrency protection only; daily quota is persisted in MySQL.
const usage = new Map();
let active = 0;
const cleanup = setInterval(() => {
  const now = Date.now();
  for (const [key, entry] of usage) if (entry.expires <= now) usage.delete(key);
}, 60000);
cleanup.unref();

router.get('/allowance', requireAuth, requireRole('client'), async (req, res) => {
  res.set('Cache-Control', 'no-store');
  try { res.json(await readMealAllowance(pool, req.user.id)); }
  catch { res.status(503).json({ message: 'Meal scanner is temporarily unavailable. Please try again later.' }); }
});

function quotaResponse(res, allowance) {
  const error = new MealQuotaError(allowance);
  res.set('Cache-Control', 'no-store');
  res.set('Retry-After', String(Math.max(1, Math.ceil((Date.parse(allowance.resetsAt) - Date.now()) / 1000))));
  return res.status(429).json({ code: error.code, message: error.message, allowance });
}

router.post('/analyze', requireAuth, requireRole('client'), async (req, res, next) => {
  try {
    const allowance = await readMealAllowance(pool, req.user.id);
    if (!allowance.remaining) return quotaResponse(res, allowance);
    next();
  } catch { res.status(503).json({ message: 'Meal scanner is temporarily unavailable. Please try again later.' }); }
}, (req, res, next) => {
  const id = req.user?.id ?? req.user?.userID;
  if (!id) return res.status(401).json({ message: 'Invalid session.' });
  const key = String(id);
  const now = Date.now();
  let entry = usage.get(key);
  if (!entry || entry.expires <= now) entry = { count: 0, expires: now + 86400000, last: 0 };
  if (now - entry.last < 10000 || active >= 8) {
    res.set('Retry-After', '60');
    return res.status(429).json({ message: 'Scan limit reached. Please wait and try again later.' });
  }
  entry.count++; entry.last = now; usage.set(key, entry);
  active++;
  let released = false;
  const release = () => { if (!released) { released = true; active--; } };
  res.once('finish', release); res.once('close', release);
  next();
}, (req, res) => upload.single('photo')(req, res, async error => {
  if (error) return res.status(error.code === 'LIMIT_FILE_SIZE' ? 413 : 400).json({ message: 'Choose one photo under 6 MB.' });
  let allowance;
  try {
    if (!req.file) throw new MealError(400, 'A meal photo is required.');
    const portion = Number(req.body.portion ?? 1);
    const notes = req.body.notes ?? '';
    if (!Number.isFinite(portion) || portion < 0.1 || portion > 3 || typeof notes !== 'string' || notes.length > 600) throw new MealError(400, 'Invalid portion or meal notes.');
    let jpeg;
    try {
      jpeg = await sharp(req.file.buffer, { limitInputPixels: 40000000, animated: false })
        .rotate().resize(1280, 1280, { fit: 'inside', withoutEnlargement: true }).jpeg({ quality: 80 }).toBuffer();
    } catch { throw new MealError(400, 'This photo cannot be read. Choose a JPEG, PNG or HEIC photo.'); }
    allowance = await reserveMealScan(pool, req.user.id);
    const meal = await analyzeMeal(jpeg, { portion, notes });
    res.set('Cache-Control', 'no-store');
    res.json({ ...decorateMeal(meal), portion, allowance });
  } catch (error) {
    // Only refund known pre-processing rejections. A timeout or unrecognized
    // meal can still incur Azure cost, so it must not bypass the daily cap.
    const refundable = error instanceof MealError && [429, 503].includes(error.status);
    if (allowance && refundable) {
      try { await refundMealScan(pool, req.user.id, allowance.day); }
      catch { console.error('Meal scan quota refund failed'); }
    }
    if (error instanceof MealQuotaError) {
      return quotaResponse(res, error.allowance);
    }
    const message = error instanceof MealError ? error.message : 'Meal analysis failed. Please try again.';
    res.status(error instanceof MealError ? error.status : 500).json({ message: message + (allowance && !refundable ? ' This attempt counted toward your daily scan allowance.' : '') });
  }
}));
export default router;
