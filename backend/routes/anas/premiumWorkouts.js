import express from 'express';
import db from '../../config/db.js';
import { requirePremiumAccess } from '../../services/premiumAccessService.js';

const router = express.Router();
router.use(requirePremiumAccess);

router.get('/exercises', async (req, res) => {
  try {
    const search = String(req.query.search || '').trim();
    const params = [];
    let query = `SELECT id, name, description, muscleGroup, equipment, exerciseType,
      isBodyweight, imageUrl, videoUrl FROM premium_exercises`;
    if (search) {
      query += ' WHERE name LIKE ? OR muscleGroup LIKE ? OR equipment LIKE ?';
      params.push(`%${search}%`, `%${search}%`, `%${search}%`);
    }
    query += ' ORDER BY name ASC LIMIT 100';
    const [rows] = await db.query(query, params);
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: 'Unable to load exercises.' });
  }
});

router.get('/routines', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT r.id, r.name, r.description, r.createdAt, r.updatedAt,
        COUNT(re.id) AS exerciseCount
       FROM premium_routines r
       LEFT JOIN premium_routine_exercises re ON re.routineID = r.id
       WHERE r.userID = ?
       GROUP BY r.id, r.name, r.description, r.createdAt, r.updatedAt
       ORDER BY r.updatedAt DESC`,
      [req.user.id],
    );
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: 'Unable to load routines.' });
  }
});

router.post('/routines', async (req, res) => {
  const name = String(req.body.name || '').trim();
  if (!name || name.length > 160) return res.status(400).json({ error: 'A valid routine name is required.' });
  try {
    const [result] = await db.query(
      'INSERT INTO premium_routines (userID, name, description) VALUES (?, ?, ?)',
      [req.user.id, name, req.body.description ? String(req.body.description).trim() : null],
    );
    res.status(201).json({ id: result.insertId, name });
  } catch (error) {
    res.status(500).json({ error: 'Unable to create routine.' });
  }
});

router.get('/routines/:routineID', async (req, res) => {
  const routineID = Number(req.params.routineID);
  if (!Number.isInteger(routineID) || routineID <= 0) return res.status(400).json({ error: 'Invalid routine.' });
  try {
    const [rows] = await db.query(
      `SELECT r.id, r.name, r.description, re.id AS routineExerciseID,
        re.sortOrder, re.targetSets, re.targetReps, re.targetDurationSeconds,
        re.restSeconds, re.supersetGroup, e.id AS exerciseID, e.name AS exerciseName,
        e.exerciseType, e.isBodyweight
       FROM premium_routines r
       LEFT JOIN premium_routine_exercises re ON re.routineID = r.id
       LEFT JOIN premium_exercises e ON e.id = re.exerciseID
       WHERE r.id = ? AND r.userID = ?
       ORDER BY re.sortOrder, re.id`,
      [routineID, req.user.id],
    );
    if (!rows.length) return res.status(404).json({ error: 'Routine not found.' });
    res.json({ routine: rows[0], exercises: rows.filter((row) => row.exerciseID != null) });
  } catch (error) {
    res.status(500).json({ error: 'Unable to load routine.' });
  }
});

router.post('/routines/:routineID/exercises', async (req, res) => {
  const routineID = Number(req.params.routineID);
  const exerciseID = Number(req.body.exerciseID);
  const targetSets = Number(req.body.targetSets ?? 3);
  const targetReps = req.body.targetReps == null ? null : Number(req.body.targetReps);
  const targetDurationSeconds = req.body.targetDurationSeconds == null ? null : Number(req.body.targetDurationSeconds);
  if (![routineID, exerciseID, targetSets].every(Number.isInteger) ||
      routineID <= 0 || exerciseID <= 0 || targetSets <= 0 ||
      (targetReps !== null && (!Number.isInteger(targetReps) || targetReps < 0)) ||
      (targetDurationSeconds !== null && (!Number.isInteger(targetDurationSeconds) || targetDurationSeconds < 0))) {
    return res.status(400).json({ error: 'Invalid routine exercise.' });
  }
  try {
    const [owned] = await db.query('SELECT id FROM premium_routines WHERE id = ? AND userID = ?', [routineID, req.user.id]);
    if (!owned.length) return res.status(404).json({ error: 'Routine not found.' });
    const [exercise] = await db.query('SELECT id FROM premium_exercises WHERE id = ?', [exerciseID]);
    if (!exercise.length) return res.status(404).json({ error: 'Exercise not found.' });
    const [order] = await db.query(
      'SELECT COALESCE(MAX(sortOrder), -1) + 1 AS nextOrder FROM premium_routine_exercises WHERE routineID = ?',
      [routineID],
    );
    await db.query(
      `INSERT INTO premium_routine_exercises
        (routineID, exerciseID, sortOrder, targetSets, targetReps, targetDurationSeconds)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [routineID, exerciseID, order[0].nextOrder, targetSets, targetReps, targetDurationSeconds],
    );
    res.status(201).json({ added: true });
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') return res.status(409).json({ error: 'Exercise already exists in this routine.' });
    res.status(500).json({ error: 'Unable to add exercise.' });
  }
});

router.post('/sessions', async (req, res) => {
  const routineID = req.body.routineID == null ? null : Number(req.body.routineID);
  if (routineID !== null && (!Number.isInteger(routineID) || routineID <= 0)) {
    return res.status(400).json({ error: 'Invalid routine.' });
  }
  try {
    if (routineID !== null) {
      const [owned] = await db.query(
        'SELECT id FROM premium_routines WHERE id = ? AND userID = ?',
        [routineID, req.user.id],
      );
      if (!owned.length) return res.status(404).json({ error: 'Routine not found.' });
    }
    const [result] = await db.query(
      'INSERT INTO premium_workout_sessions (userID, routineID) VALUES (?, ?)',
      [req.user.id, routineID],
    );
    res.status(201).json({ id: result.insertId, status: 'active' });
  } catch (error) {
    res.status(500).json({ error: 'Unable to start workout.' });
  }
});

router.post('/sessions/:sessionID/sets', async (req, res) => {
  const sessionID = Number(req.params.sessionID);
  const exerciseID = Number(req.body.exerciseID);
  const setNumber = Number(req.body.setNumber);
  const reps = req.body.reps == null ? null : Number(req.body.reps);
  const durationSeconds = req.body.durationSeconds == null ? null : Number(req.body.durationSeconds);
  const weight = req.body.weight == null ? null : Number(req.body.weight);
  if (![sessionID, exerciseID, setNumber].every(Number.isInteger) ||
      sessionID <= 0 || exerciseID <= 0 || setNumber <= 0 ||
      (reps !== null && (!Number.isInteger(reps) || reps < 0)) ||
      (durationSeconds !== null && (!Number.isInteger(durationSeconds) || durationSeconds < 0)) ||
      (weight !== null && (!Number.isFinite(weight) || weight < 0))) {
    return res.status(400).json({ error: 'Invalid set data.' });
  }
  try {
    const [owned] = await db.query(
      `SELECT s.id FROM premium_workout_sessions s
       JOIN premium_exercises e ON e.id = ? 
       WHERE s.id = ? AND s.userID = ? AND s.status = 'active'`,
      [exerciseID, sessionID, req.user.id],
    );
    if (!owned.length) return res.status(404).json({ error: 'Active workout not found.' });
    await db.query(
      `INSERT INTO premium_workout_sets
        (sessionID, exerciseID, setNumber, weight, reps, durationSeconds)
       VALUES (?, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE weight=VALUES(weight), reps=VALUES(reps),
        durationSeconds=VALUES(durationSeconds)`,
      [sessionID, exerciseID, setNumber, weight, reps, durationSeconds],
    );
    res.status(201).json({ saved: true });
  } catch (error) {
    res.status(500).json({ error: 'Unable to save set.' });
  }
});

router.post('/sessions/:sessionID/finish', async (req, res) => {
  const sessionID = Number(req.params.sessionID);
  if (!Number.isInteger(sessionID) || sessionID <= 0) return res.status(400).json({ error: 'Invalid workout.' });
  try {
    const [result] = await db.query(
      `UPDATE premium_workout_sessions SET status = 'completed', completedAt = NOW()
       WHERE id = ? AND userID = ? AND status = 'active'`,
      [sessionID, req.user.id],
    );
    if (!result.affectedRows) return res.status(404).json({ error: 'Active workout not found.' });
    res.json({ completed: true });
  } catch (error) {
    res.status(500).json({ error: 'Unable to finish workout.' });
  }
});

router.get('/history', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT s.id, s.status, s.startedAt, s.completedAt, r.name AS routineName,
        COUNT(ws.id) AS setCount
       FROM premium_workout_sessions s
       LEFT JOIN premium_routines r ON r.id = s.routineID
       LEFT JOIN premium_workout_sets ws ON ws.sessionID = s.id
       WHERE s.userID = ? GROUP BY s.id ORDER BY s.startedAt DESC LIMIT 50`,
      [req.user.id],
    );
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: 'Unable to load workout history.' });
  }
});

router.get('/body-weight', async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT id, weight, unit, recordedAt FROM premium_body_weights WHERE userID = ? ORDER BY recordedAt DESC LIMIT 100',
      [req.user.id],
    );
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: 'Unable to load body weight.' });
  }
});

router.post('/body-weight', async (req, res) => {
  const weight = Number(req.body.weight);
  const unit = req.body.unit === 'lb' ? 'lb' : 'kg';
  if (!Number.isFinite(weight) || weight <= 0 || weight > 500) {
    return res.status(400).json({ error: 'Enter a valid body weight.' });
  }
  try {
    const [result] = await db.query(
      'INSERT INTO premium_body_weights (userID, weight, unit) VALUES (?, ?, ?)',
      [req.user.id, weight, unit],
    );
    res.status(201).json({ id: result.insertId, weight, unit });
  } catch (error) {
    res.status(500).json({ error: 'Unable to save body weight.' });
  }
});

router.get('/stats', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT
        COUNT(DISTINCT s.id) AS workoutCount,
        COUNT(ws.id) AS setCount,
        COALESCE(SUM(ws.weight * ws.reps), 0) AS totalVolume,
        MAX(ws.weight) AS heaviestSet
       FROM premium_workout_sessions s
       LEFT JOIN premium_workout_sets ws ON ws.sessionID = s.id
       WHERE s.userID = ? AND s.status = 'completed'`,
      [req.user.id],
    );
    res.json(rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Unable to load workout statistics.' });
  }
});

export default router;
