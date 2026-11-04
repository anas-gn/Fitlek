import { createNutritionPlanRouter, readNutritionPlan } from './nutritionGoals.js';
import express from 'express';
import { requireAuth, requireRole } from '../middleware/auth.js';

const types = new Set(['breakfast', 'lunch', 'dinner', 'snack']);
const keys = ['calories', 'protein', 'carbs', 'fat'];
function invalid() { const error = new Error('Check the meal details and try again.'); error.status = 400; throw error; }
function text(value, max, required = false) {
  if (typeof value !== 'string' || value.length > max || (required && !value.trim())) invalid();
  return value.trim();
}
export function validDay(value) {
  return typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value)
    && Number.isFinite(Date.parse(value)) && new Date(value).toISOString().slice(0, 10) === value;
}
function number(value, max = 10000) {
  if (typeof value !== 'number' || !Number.isFinite(value) || value < 0 || value > max) invalid();
  return value;
}
export function cleanMeal(value, id) {
  if (!value || !/^[a-zA-Z0-9_-]{1,80}$/.test(id) || !validDay(value.mealDate) || !types.has(value.mealType)) invalid();
  if (typeof value.createdAt !== 'string' || !Number.isFinite(Date.parse(value.createdAt))) invalid();
  if (!Array.isArray(value.ingredients) || !value.ingredients.length || value.ingredients.length > 60) invalid();
  const ingredients = value.ingredients.map(item => {
    if (!item || typeof item !== 'object') invalid();
    const result = { name: text(item.name, 120, true), grams: number(item.grams),
      image_key: text(item.image_key ?? 'generic', 100), image_url: '',
      preparation: text(item.preparation ?? 'unknown', 40), quantity: text(item.quantity ?? '', 100) };
    for (const key of keys) result[key] = number(item[key], key === 'calories' ? 50000 : 10000);
    return result;
  });
  return { id, name: text(value.name, 160, true), notes: text(value.notes ?? '', 2000),
    confidence: ['low', 'medium', 'high', 'manual'].includes(value.confidence) ? value.confidence : 'medium',
    portion: number(value.portion ?? 1, 100), createdAt: new Date(value.createdAt).toISOString(),
    mealDate: value.mealDate, mealType: value.mealType, ingredients };
}
export function cleanGoals(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) invalid();
  return Object.fromEntries(keys.map(key => [key, value[key] == null ? null : number(value[key], key === 'calories' ? 20000 : 2000)]));
}
const decoded = value => typeof value === 'string' ? JSON.parse(value) : value;
export function createNutritionRouter(pool) {
  const router = express.Router();
  router.use(requireAuth, requireRole('client'), (req, res, next) => {
    res.set('Cache-Control', 'no-store');
    if (!Number.isSafeInteger(Number(req.user.id)) || Number(req.user.id) <= 0) return res.status(401).json({ message: 'Invalid session.' });
    next();
  });
  router.use('/plan', createNutritionPlanRouter(pool));
  router.get('/', async (req, res) => {
    if (!validDay(req.query.date)) return res.status(400).json({ message: 'Choose a valid date.' });
    try {
      const [rows] = await pool.execute('SELECT payload FROM client_meals WHERE userID=? AND mealDate=? ORDER BY consumedAt,id', [req.user.id, req.query.date]);
      res.json({ meals: rows.map(row => decoded(row.payload)) });
    } catch { res.status(503).json({ message: 'Could not load your nutrition diary. Try again.' }); }
  });
  router.get('/goals', async (req, res) => {
    try {
      const [rows] = await pool.execute('SELECT goals FROM client_nutrition_goals WHERE userID=?', [req.user.id]);
      res.json(rows.length ? decoded(rows[0].goals) : Object.fromEntries(keys.map(key => [key, null])));
    } catch { res.status(503).json({ message: 'Could not load your targets.' }); }
  });
  router.put('/goals', async (req, res) => {
    try {
      const goals = cleanGoals(req.body);
      const plan = await readNutritionPlan(pool,req.user.id);
      if(plan?.age!=null && plan.age<18 && Object.values(goals).some(value=>value!=null)) return res.status(400).json({message:'For clients under 18, use balanced tracking without numerical nutrition targets.'});
      await pool.execute('INSERT INTO client_nutrition_goals (userID,goals) VALUES (?,?) ON DUPLICATE KEY UPDATE goals=VALUES(goals)', [req.user.id, JSON.stringify(goals)]);
      res.json(goals);
    } catch (error) { res.status(error.status ?? 503).json({ message: error.status ? 'Enter valid daily targets.' : 'Could not save your targets.' }); }
  });
  router.put('/:id', async (req, res) => {
    try {
      const meal = cleanMeal(req.body, req.params.id);
      await pool.execute('INSERT INTO client_meals (userID,id,mealDate,mealType,consumedAt,payload) VALUES (?,?,?,?,?,?) ON DUPLICATE KEY UPDATE mealDate=VALUES(mealDate),mealType=VALUES(mealType),consumedAt=VALUES(consumedAt),payload=VALUES(payload)', [req.user.id, meal.id, meal.mealDate, meal.mealType, meal.createdAt, JSON.stringify(meal)]);
      res.json(meal);
    } catch (error) { res.status(error.status ?? 503).json({ message: error.status ? error.message : 'Could not save this meal. Try again.' }); }
  });
  router.delete('/:id', async (req, res) => {
    try {
      const [result] = await pool.execute('DELETE FROM client_meals WHERE userID=? AND id=?', [req.user.id, req.params.id]);
      if (!result.affectedRows) return res.status(404).json({ message: 'Meal not found.' });
      res.sendStatus(204);
    } catch { res.status(503).json({ message: 'Could not delete this meal.' }); }
  });
  return router;
}
