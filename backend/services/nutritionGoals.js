import express from 'express';

export const goalTypes = ['balanced', 'lose', 'gain', 'maintain'];
const macros = ['calories', 'protein', 'carbs', 'fat'];
const parse = value => typeof value === 'string' ? JSON.parse(value) : value;
function fail(message) { const error = new Error(message); error.status = 400; throw error; }
function numeric(value, min, max, label) {
  if (value == null || value === '') return null;
  if (typeof value !== 'number' || !Number.isFinite(value) || value < min || value > max) fail(`Enter a valid ${label}.`);
  return value;
}
export function cleanNutritionPlan(input) {
  if (!input || typeof input !== 'object' || Array.isArray(input)) fail('Choose your nutrition goal.');
  if (!goalTypes.includes(input.goalType)) fail('Choose a valid goal.');
  const age = numeric(input.age, 13, 100, 'age');
  if (age != null && !Number.isInteger(age)) fail('Enter your age in whole years.');
  const height = numeric(input.height, 1, 300, 'height');
  const currentWeight = numeric(input.currentWeight, 1, 500, 'current weight');
  let targetWeight = numeric(input.targetWeight, 25, 500, 'target weight');
  if (['lose', 'gain'].includes(input.goalType)) {
    if (!age || age < 18 || !height || !currentWeight || !targetWeight) fail('Adult weight goals need age, height, current weight and target weight. Choose balanced tracking otherwise.');
    if (targetWeight / (height / 100) ** 2 < 18.5) fail('This target is below the adult weight range supported by this planner. Review it with a qualified health professional.');
    if ((input.goalType === 'lose' && targetWeight >= currentWeight) || (input.goalType === 'gain' && targetWeight <= currentWeight)) fail('Choose a target weight in the direction of your goal.');
  } else { targetWeight = null; }
  const timeZone = typeof input.timeZone === 'string' ? input.timeZone : 'Africa/Casablanca';
  try { new Intl.DateTimeFormat('en', { timeZone }).format(); } catch { fail('Choose a valid time zone.'); }
  const minute = (value, fallback) => {
    if (value == null) return fallback;
    if (!Number.isInteger(value) || value < 0 || value > 1439) fail('Choose valid reminder times.');
    return value;
  };
  const targets = {};
  for (const key of macros) targets[key] = numeric(input.targets?.[key], 0, key === 'calories' ? 20000 : 2000, `${key} target`);
  if (age != null && age < 18 && Object.values(targets).some(value => value != null)) fail('For clients under 18, use balanced meal tracking without numerical nutrition targets.');
  const reminders = input.reminders ?? {};
  for (const key of ['enabled','calorieAlerts','monthly','yearly','weekly','mealIdeas']) if (reminders[key] != null && typeof reminders[key] !== 'boolean') fail('Check your reminder preferences.');
  return {
    goalType: input.goalType, age, height, currentWeight, targetWeight,
    activity: ['low','light','moderate','high'].includes(input.activity) ? input.activity : 'light',
    formulaSex: ['male','female'].includes(input.formulaSex) ? input.formulaSex : null,
    estimateEligible: input.estimateEligible === true,
    diet: ['balanced','vegetarian','vegan','halal'].includes(input.diet) ? input.diet : 'balanced',
    timeZone, targets,
    reminders: { enabled: reminders.enabled === true, calorieAlerts: age >= 18 && reminders.calorieAlerts === true,
      monthly: reminders.monthly !== false, yearly: reminders.yearly !== false, weekly: reminders.weekly !== false,
      mealIdeas: age >= 18 && reminders.mealIdeas === true,
      breakfast: minute(reminders.breakfast, 540), lunch: minute(reminders.lunch, 840), dinner: minute(reminders.dinner, 1200),
      quietStart: minute(reminders.quietStart, 1320), quietEnd: minute(reminders.quietEnd, 480) },
  };
}

// Optional maintenance estimate only. Never chooses a weight-loss deficit or a gain target.
export function maintenanceEstimate(plan) {
  if (!plan.estimateEligible || !plan.age || plan.age < 18 || plan.age > 80 || !plan.height || !plan.currentWeight || !['male','female'].includes(plan.formulaSex)) return null;
  const resting = 10 * plan.currentWeight + 6.25 * plan.height - 5 * plan.age + (plan.formulaSex === 'male' ? 5 : -161);
  const value = resting * ({ low:1.2, light:1.375, moderate:1.55, high:1.725 }[plan.activity] ?? 1.375);
  // Outside this product range, offer manual targets instead of clipping an estimate.
  return value >= 1500 && value <= 4500 ? Math.round(value / 50) * 50 : null;
}

export async function readNutritionPlan(db, userID, lock = false) {
  const [rows] = await db.query("SELECT plan,status,revision,DATE_FORMAT(startedAt,'%Y-%m-%dT%H:%i:%s.000Z') AS startedAt FROM client_nutrition_plans WHERE userID=?" + (lock ? ' FOR UPDATE' : ''), [userID]);
  if (!rows.length) return null;
  return { ...parse(rows[0].plan), status: rows[0].status, revision: rows[0].revision, startedAt: rows[0].startedAt };
}

export async function saveNutritionPlan(db, userID, input) {
  const plan = cleanNutritionPlan(input);
  const old = await readNutritionPlan(db, userID, true);
  const restart = !old || input.restart === true || old.goalType !== plan.goalType || old.targetWeight !== plan.targetWeight;
  const status = ['active','paused','achieved'].includes(input.status) ? input.status : restart ? 'active' : old?.status ?? 'active';
  const revision = old ? old.revision + (restart ? 1 : 0) : 1;
  if (old && !restart) plan.currentWeight = old.currentWeight;
  await db.query(`INSERT INTO client_nutrition_plans (userID,plan,status,revision,startedAt) VALUES (?,?,?,?,UTC_TIMESTAMP())
    ON DUPLICATE KEY UPDATE plan=VALUES(plan),status=VALUES(status),revision=VALUES(revision),startedAt=IF(?,UTC_TIMESTAMP(),startedAt)`, [userID, JSON.stringify(plan), status, revision, restart]);
  await db.query('INSERT INTO client_nutrition_goals (userID,goals) VALUES (?,?) ON DUPLICATE KEY UPDATE goals=VALUES(goals)', [userID, JSON.stringify(plan.targets)]);
  return readNutritionPlan(db, userID);
}

export function weightGoalProgress(plan, weights, now = new Date()) {
  const seen = new Set();
  const distinct = weights.filter(row => {
    const day = String(row.day).slice(0,10);
    if (seen.has(day) || !Number.isFinite(Number(row.weight)) || Number(row.weight) <= 0 || now-new Date(day+'T00:00:00Z')>30*86400000) return false;
    seen.add(day); return true;
  }).slice(0,3);
  const latest = weights.find(row => Number.isFinite(Number(row.weight)) && Number(row.weight)>0);
  const current = latest ? Number(latest.weight) : plan.currentWeight;
  const average = distinct.length ? distinct.reduce((sum,row) => sum + Number(row.weight),0) / distinct.length : null;
  const baseline = plan.currentWeight, target = plan.targetWeight;
  const weightGoal = ['lose','gain'].includes(plan.goalType) && baseline && target && baseline !== target;
  const percent = weightGoal && current ? Math.max(0, Math.min(100, ((current-baseline)/(target-baseline))*100)) : null;
  const recent = distinct.length >= 2 && now - new Date(String(distinct[0].day).slice(0,10) + 'T00:00:00Z') < 30*86400000;
  const reached = Boolean(weightGoal && recent && (plan.goalType === 'lose' ? average <= target : average >= target));
  return { currentWeight: current ?? null, averageWeight: average, baselineWeight: baseline, targetWeight: target, percent, reached, measurements: distinct.length };
}

export async function planProgress(db, userID, plan, now = new Date()) {
  const [rows] = await db.query("SELECT weight,DATE_FORMAT(recordedAt,'%Y-%m-%d') AS day FROM weighthistory WHERE clientID=? AND createdAt>=? ORDER BY createdAt DESC,id DESC LIMIT 30", [userID, plan.startedAt.slice(0,19).replace('T',' ')]);
  return weightGoalProgress(plan, rows, now);
}

export async function nutritionSummary(db, userID, from, to) {
  const [rows] = await db.query('SELECT mealDate,payload FROM client_meals WHERE userID=? AND mealDate>=? AND mealDate<?', [userID, from, to]);
  const days = new Set();
  const totals = Object.fromEntries(macros.map(key => [key,0]));
  for (const row of rows) {
    const meal = parse(row.payload); days.add(String(meal.mealDate));
    for (const ingredient of meal.ingredients ?? []) for (const key of macros) totals[key] += Number(ingredient[key]) || 0;
  }
  const [weights] = await db.query('SELECT weight FROM weighthistory WHERE clientID=? AND recordedAt>=? AND recordedAt<? ORDER BY recordedAt,id', [userID,from,to]);
  return { from, to, loggedDays: days.size, meals: rows.length, totals, dailyAverages: Object.fromEntries(macros.map(key => [key, days.size ? totals[key]/days.size : 0])),
    weight: { checkIns:weights.length, first:weights.length?Number(weights[0].weight):null, latest:weights.length?Number(weights.at(-1).weight):null, change:weights.length>1?Number(weights.at(-1).weight)-Number(weights[0].weight):null } };
}

export function createNutritionPlanRouter(pool) {
  const router = express.Router();
  router.get('/', async (req,res) => {
    try {
      const plan = await readNutritionPlan(pool,req.user.id);
      if (!plan) {
        const [[user]] = await pool.query('SELECT height FROM users WHERE id=?',[req.user.id]);
        const [[weight]] = await pool.query('SELECT weight FROM weighthistory WHERE clientID=? ORDER BY createdAt DESC,id DESC LIMIT 1',[req.user.id]);
        const [[targets]] = await pool.query('SELECT goals FROM client_nutrition_goals WHERE userID=?',[req.user.id]);
        return res.json({plan:null,defaults:{height:user?.height==null?null:Number(user.height),currentWeight:weight?.weight==null?null:Number(weight.weight),targets:targets?parse(targets.goals):{}}});
      }
      const [[goal]] = await pool.query('SELECT goals FROM client_nutrition_goals WHERE userID=?',[req.user.id]);
      plan.targets = goal ? parse(goal.goals) : plan.targets;
      const progress = await planProgress(pool,req.user.id,plan);
      res.json({plan,progress,maintenanceEstimate:maintenanceEstimate({...plan,currentWeight:progress.currentWeight})});
    } catch { res.status(503).json({message:'Could not load your goal. Try again.'}); }
  });
  router.put('/', async (req,res) => {
    let tx;
    try {
      cleanNutritionPlan(req.body);
      tx = await pool.getConnection(); await tx.beginTransaction();
      const plan = await saveNutritionPlan(tx,req.user.id,req.body);
      await tx.commit(); res.json({plan});
    } catch(error) { if(tx) await tx.rollback(); res.status(error.status ?? 503).json({message:error.status ? error.message : 'Could not save your goal. Your previous plan is unchanged.'}); }
    finally { tx?.release(); }
  });
  router.get('/summary', async (req,res) => {
    const from = req.query.from, to = req.query.to;
    const valid = value => typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value) && Number.isFinite(Date.parse(value)) && new Date(value).toISOString().slice(0,10) === value;
    if(!valid(from) || !valid(to) || from>=to || new Date(to)-new Date(from)>367*86400000) return res.status(400).json({message:'Choose a valid review period of up to one year.'});
    try { res.json(await nutritionSummary(pool,req.user.id,from,to)); }
    catch {res.status(503).json({message:'Could not load your progress review.'});}
  });
  return router;
}
