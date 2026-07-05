const express = require('express');
const router = express.Router();
const db = require('../../config/db');

// GET /reservations
router.get('/', async (req, res) => {
  try {
    const { userID, role, status, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;
    let sql = `SELECT r.*,
               CONCAT(c.firstName,' ',c.lastName)  AS clientName, c.avatarUrl  AS clientAvatar,
               CONCAT(co.firstName,' ',co.lastName) AS coachName,  co.avatarUrl AS coachAvatar
               FROM reservations r
               JOIN users c  ON c.id  = r.clientID
               JOIN users co ON co.id = r.coachID
               WHERE 1=1`;
    const params = [];
    if (role === 'client') { sql += ' AND r.clientID=?'; params.push(userID); }
    if (role === 'coach')  { sql += ' AND r.coachID=?';  params.push(userID); }
    if (status) { sql += ' AND r.status=?'; params.push(status); }
    sql += ' ORDER BY r.reservedDate DESC, r.reservedTime DESC LIMIT ? OFFSET ?';
    params.push(Number(limit), Number(offset));
    const [rows] = await db.query(sql, params);
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// GET /reservations/advisor/:advisorID
// Toutes les réservations des coaches appartenant à cet advisor
router.get('/advisor/:advisorID', async (req, res) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    let sql = `SELECT r.*,
               CONCAT(c.firstName,' ',c.lastName)   AS clientName,  c.avatarUrl  AS clientAvatar,
               CONCAT(co.firstName,' ',co.lastName)  AS coachName,   co.avatarUrl AS coachAvatar
               FROM reservations r
               JOIN users c   ON c.id  = r.clientID
               JOIN users co  ON co.id = r.coachID
               JOIN coachProfiles cp ON cp.userID = r.coachID
               WHERE cp.advisorID = ?`;
    const params = [req.params.advisorID];

    if (status) { sql += ' AND r.status=?'; params.push(status); }
    sql += ' ORDER BY r.reservedDate DESC, r.reservedTime DESC LIMIT ? OFFSET ?';
    params.push(Number(limit), Number(offset));

    const [rows] = await db.query(sql, params);
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// GET /reservations/:id
router.get('/:id', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT r.*,
              CONCAT(c.firstName,' ',c.lastName)  AS clientName,
              CONCAT(co.firstName,' ',co.lastName) AS coachName
       FROM reservations r
       JOIN users c  ON c.id  = r.clientID
       JOIN users co ON co.id = r.coachID
       WHERE r.id=?`, [req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Not found' });
    res.json(rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// POST /reservations
// Auto-remplit location & companyName depuis le profil advisor du coach
router.post('/', async (req, res) => {
  try {
    const { clientID, coachID, reservedDate, reservedTime, userID } = req.body;
    const cID = clientID ?? userID;
    if (!cID || !coachID || !reservedDate || !reservedTime)
      return res.status(400).json({ error: 'Missing required fields' });

    // Vérifier que le coach existe et est approuvé
    const [coach] = await db.query(
      'SELECT id FROM users WHERE id=? AND role="coach" AND isApproved=1', [coachID]
    );
    if (!coach.length) return res.status(404).json({ error: 'Coach not found or not approved' });

    // Vérifier conflit de créneau
    const [conflict] = await db.query(
      `SELECT id FROM reservations
       WHERE coachID=? AND reservedDate=? AND reservedTime=?
         AND status IN ('pending','confirmed')`,
      [coachID, reservedDate, reservedTime]
    );
    if (conflict.length) return res.status(409).json({ error: 'Time slot already booked' });

    // Vérifier créneau bloqué par le coach
    const [blocks] = await db.query(
      `SELECT id FROM coachAvailabilityBlocks
       WHERE coachID=? AND blockedDate=? AND startTime <= ? AND endTime > ?`,
      [coachID, reservedDate, reservedTime, reservedTime]
    );
    if (blocks.length) return res.status(409).json({ error: 'Coach not available at this time' });

    // Auto-remplissage lieu & salle depuis l'advisor du coach
    let autoLocation = null;
    let autoCompanyName = null;

    const [advisorInfo] = await db.query(
      `SELECT ap.location, ap.companyName
       FROM coachProfiles cp
       JOIN advisorProfiles ap ON ap.userID = cp.advisorID
       WHERE cp.userID = ?`,
      [coachID]
    );
    if (advisorInfo.length) {
      autoLocation    = advisorInfo[0].location    || null;
      autoCompanyName = advisorInfo[0].companyName || null;
    }

    const [result] = await db.query(
      `INSERT INTO reservations (clientID, coachID, reservedDate, reservedTime, location, companyName)
       VALUES (?,?,?,?,?,?)`,
      [cID, coachID, reservedDate, reservedTime, autoLocation, autoCompanyName]
    );

    res.status(201).json({
      message: 'Reservation created',
      reservationID: result.insertId,
      location: autoLocation,
      companyName: autoCompanyName,
    });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// PATCH /reservations/:id/confirm
router.patch('/:id/confirm', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM reservations WHERE id=?', [req.params.id]);
    if (!rows.length) return res.status(404).json({ error: 'Not found' });
    if (rows[0].status !== 'pending') return res.status(400).json({ error: 'Only pending reservations can be confirmed' });
    await db.query('UPDATE reservations SET status="confirmed" WHERE id=?', [req.params.id]);
    res.json({ message: 'Reservation confirmed' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// PATCH /reservations/:id/cancel
router.patch('/:id/cancel', async (req, res) => {
  try {
    const { cancellationReason, cancelledBy } = req.body;
    const [rows] = await db.query('SELECT * FROM reservations WHERE id=?', [req.params.id]);
    if (!rows.length) return res.status(404).json({ error: 'Not found' });
    if (rows[0].status === 'cancelled') return res.status(400).json({ error: 'Already cancelled' });
    await db.query(
      'UPDATE reservations SET status="cancelled", cancellationReason=?, cancelledBy=? WHERE id=?',
      [cancellationReason || null, cancelledBy || null, req.params.id]
    );
    res.json({ message: 'Reservation cancelled' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// PATCH /reservations/:id/reject
router.patch('/:id/reject', async (req, res) => {
  try {
    const { rejectionReason } = req.body;
    const [rows] = await db.query('SELECT * FROM reservations WHERE id=?', [req.params.id]);
    if (!rows.length) return res.status(404).json({ error: 'Not found' });
    if (rows[0].status !== 'pending') return res.status(400).json({ error: 'Only pending reservations can be rejected' });
    await db.query(
      'UPDATE reservations SET status="cancelled", rejectionReason=? WHERE id=?',
      [rejectionReason || null, req.params.id]
    );
    res.json({ message: 'Reservation rejected' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// PATCH /reservations/:id/price
router.patch('/:id/price', async (req, res) => {
  try {
    const { price } = req.body;
    if (price === undefined || isNaN(price) || price < 0)
      return res.status(400).json({ error: 'Prix invalide' });
    const [rows] = await db.query('SELECT id FROM reservations WHERE id=?', [req.params.id]);
    if (!rows.length) return res.status(404).json({ error: 'Réservation introuvable' });
    await db.query('UPDATE reservations SET price=? WHERE id=?', [price, req.params.id]);
    res.json({ message: 'Prix mis à jour', price });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

module.exports = router;