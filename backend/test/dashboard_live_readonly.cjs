// Run on the VPS with the dashboard route source supplied on stdin.
const fs = require('fs');
const mysql = require('mysql2/promise');
const dotenv = require('dotenv');
(async () => {
  const env = dotenv.parse(fs.readFileSync('.env'));
  const db = await mysql.createConnection({host: env.DB_HOST, user: env.DB_USER,
    password: env.DB_PASSWORD, database: env.DB_NAME, port: Number(env.DB_PORT || 3306)});
  await db.query('SET SESSION TRANSACTION READ ONLY');
  await db.beginTransaction();
  globalThis.dashboardDb = db;
  try {
    let source = fs.readFileSync(0, 'utf8');
    source = source.replace("import { Router } from 'express';",
      'const Router=()=>({get:(path,...handlers)=>{globalThis.dashboardHandler=handlers.at(-1);}});')
      .replace("import pool from '../../config/db.js';", 'const pool=globalThis.dashboardDb;')
      .replace("import { requireAuth, requireRole } from '../../middleware/auth.js';",
        'const requireAuth=()=>{}; const requireRole=()=>()=>{};');
    await import('data:text/javascript;base64,' + Buffer.from(source).toString('base64'));
    const [coaches] = await db.query("SELECT id FROM users WHERE role='coach' ORDER BY id LIMIT 10");
    for (const period of ['today', 'week', 'month']) {
      for (const coach of [...coaches, {id: 0}]) {
        let status = 200, body;
        const res = {status(code) {status=code; return this;}, json(value) {body=value;}};
        await globalThis.dashboardHandler({user: {id: coach.id}, query: {period}}, res);
        if (status !== 200) throw Error(body.message);
        if (!Number.isFinite(body.confirmedValue) || body.totalClients < body.periodClients) throw Error('Invalid totals');
        const filter = period === 'today' ? 'reservedDate=CURDATE()'
          : period === 'week' ? 'YEARWEEK(reservedDate,1)=YEARWEEK(CURDATE(),1)'
          : 'MONTH(reservedDate)=MONTH(CURDATE()) AND YEAR(reservedDate)=YEAR(CURDATE())';
        const [[expected]] = await db.query(`SELECT COUNT(*) count,
          COALESCE(SUM(CASE WHEN status='confirmed' AND pricingStatus IN ('fixed','accepted') THEN price ELSE 0 END),0) amount
          FROM reservations WHERE coachID=? AND ${filter}`, [coach.id]);
        if (body.totalReservations !== Number(expected.count) || body.confirmedValue !== Number(expected.amount)) throw Error('Dashboard mismatch');
      }
      console.log(JSON.stringify({period, result: 'PASS', coachesChecked: coaches.length + 1}));
    }
    // Exercise the route's actual aggregate SQL against read-only fixture rows.
    const originalQuery = db.query.bind(db);
    globalThis.dashboardDb.query = async (sql, args) => {
      if (!sql.includes('AS confirmedValue')) return originalQuery(sql, args);
      const fixtures = `(SELECT 0 AS coachID, CURDATE() AS reservedDate, 'confirmed' AS status, 'fixed' AS pricingStatus, 100 AS price
        UNION ALL SELECT 0,CURDATE(),'confirmed','accepted',250.75
        UNION ALL SELECT 0,CURDATE(),'confirmed','awaiting',999
        UNION ALL SELECT 0,CURDATE(),'pending','proposed',999
        UNION ALL SELECT 0,CURDATE(),'cancelled','fixed',999) r`;
      return originalQuery(sql.replace('reservations r', fixtures), args);
    };
    let fixtureResult;
    await globalThis.dashboardHandler({user: {id: 0}, query: {period: 'today'}},
      {status() {throw Error('Fixture route failed');}, json(body) {fixtureResult=body;}});
    if (fixtureResult.confirmedValue !== 350.75 || fixtureResult.totalReservations !== 5
      || fixtureResult.confirmedReservations !== 3 || fixtureResult.pendingReservations !== 1) throw Error('Pricing fixture mismatch');
    console.log(JSON.stringify({check: 'fixed, accepted, awaiting, proposed and cancelled prices', result: 'PASS'}));
  } finally {await db.rollback(); await db.end();}
})().catch(error => {console.error(error.message); process.exitCode=1;});
