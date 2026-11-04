import test from 'node:test';
import assert from 'node:assert/strict';
import express from 'express';
import jwt from 'jsonwebtoken';
process.env.JWT_SECRET = 'nutrition-test-secret';
const { createNutritionRouter, cleanMeal, cleanGoals, validDay } = await import('../services/nutritionDiary.js');
const meal = (overrides = {}) => ({ name: 'Chicken tagine', mealDate: '2026-10-16', mealType: 'lunch', createdAt: '2026-10-16T12:00:00Z', ingredients: [{ name: 'Grilled chicken', grams: 150, calories: 250, protein: 35, carbs: 0, fat: 8 }], ...overrides });
test('validates calendar days, bounded nutrition and strips all photos/unknown fields', () => {
  assert.equal(validDay('2026-02-30'), false);
  assert.equal(validDay('2026-10-16'), true);
  const clean = cleanMeal(meal({ userID: 9, photoData: 'secret', photoPath: 'private', extra: true }), 'scan_1');
  assert.equal(clean.photoData, undefined); assert.equal(clean.photoPath, undefined); assert.equal(clean.userID, undefined);
  assert.equal(cleanMeal(meal({ notes: 'a'.repeat(2000) }), 'scan_2').notes.length, 2000);
  for (const change of [{ mealDate: '2026-02-30' }, { mealType: 'bad' }, { ingredients: [] }, { ingredients: [{name:'Food',grams:1,calories:-1,protein:0,carbs:0,fat:0}] }]) assert.throws(() => cleanMeal(meal(change), 'scan_1'));
  assert.throws(() => cleanMeal(meal(), '../evil'));
  assert.throws(() => cleanGoals({ calories: Infinity }));
  assert.deepEqual(cleanGoals({ protein: 100 }), { calories: null, protein: 100, carbs: null, fat: null });
});
test('authenticated clients have isolated, idempotent diaries, editable dates, goals and deletion', async t => {
  const records = new Map(), goals = new Map();
  const pool = { async query(sql,args) { return this.execute(sql,args); }, async execute(sql, args) {
    if(sql.startsWith('SELECT plan,status')) return [[]];
    if (sql.startsWith('INSERT INTO client_meals')) { records.set(`${args[0]}:${args[1]}`, { user: args[0], date: args[2], payload: args[5] }); return [{}]; }
    if (sql.startsWith('SELECT payload')) return [[...records.values()].filter(row => row.user === args[0] && row.date === args[1]).map(row => ({payload: row.payload}))];
    if (sql.startsWith('DELETE FROM')) return [{ affectedRows: Number(records.delete(`${args[0]}:${args[1]}`)) }];
    if (sql.startsWith('INSERT INTO client_nutrition_goals')) { goals.set(args[0], args[1]); return [{}]; }
    if (sql.startsWith('SELECT goals')) return [goals.has(args[0]) ? [{goals: goals.get(args[0])}] : []];
    throw new Error('Unexpected SQL');
  } };
  const app = express(); app.use(express.json()); app.use('/diary', createNutritionRouter(pool));
  const server = app.listen(0, '127.0.0.1'); await new Promise(resolve => server.once('listening', resolve));
  t.after(() => server.close());
  const base = `http://127.0.0.1:${server.address().port}/diary`;
  const call = async (path, method = 'GET', body, id = 7, role = 'client') => fetch(base + path, { method, headers: {'Content-Type':'application/json', ...(id ? { Authorization: `Bearer ${jwt.sign({id,role}, process.env.JWT_SECRET)}` } : {})}, ...(body ? {body: JSON.stringify(body)} : {}) });
  assert.equal((await call('?date=2026-10-16','GET',null,0)).status, 401);
  assert.equal((await call('?date=2026-10-16','GET',null,7,'coach')).status, 403);
  assert.equal((await call('?date=2026-02-30')).status,400);
  for(let n=0;n<2;n++) assert.equal((await call('/same','PUT',meal({userID:8,photoData:'not stored'}))).status,200);
  assert.equal(records.size,1);
  assert.equal((await (await call('?date=2026-10-16')).json()).meals.length,1);
  assert.equal((await (await call('?date=2026-10-16&userID=7','GET',null,8)).json()).meals.length,0);
  assert.equal((await call('/same','DELETE',null,8)).status,404);
  await call('/same','PUT',meal({mealDate:'2026-10-15',mealType:'dinner'}));
  assert.equal((await (await call('?date=2026-10-16')).json()).meals.length,0);
  assert.equal((await (await call('?date=2026-10-15')).json()).meals[0].mealType,'dinner');
  assert.equal((await call('/goals','PUT',{calories:2200,protein:130})).status,200);
  assert.equal((await (await call('/goals')).json()).protein,130);
  assert.equal((await (await call('/goals','GET',null,8)).json()).calories,null);
  assert.equal((await call('/same','DELETE')).status,204);
  assert.equal(records.size,0);
});
