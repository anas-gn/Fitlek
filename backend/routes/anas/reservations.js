import {priceApprovalRouter} from './priceApproval.js';
import {expirePriceRequests,sessionClock} from '../../services/priceApproval.js';
import {resolveSessionLocation,presentSessionLocation} from '../../services/sessionLocation.js';
import {requireBookingLeadTime} from '../../services/bookingPolicy.js';
import express from 'express';
const router = express.Router();
import db from '../../config/db.js';
import { createAndSendNotification } from '../../services/pushNotificationService.js';
router.use(priceApprovalRouter(db,createAndSendNotification));
// GET /reservations
router.get('/', async (req, res) => {
  try {
    await expirePriceRequests(db,createAndSendNotification);
    const { userID, role, status, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;
    let sql = `SELECT r.*, cr.rating AS reviewRating, cr.comment AS reviewComment,
               CONCAT(c.firstName,' ',c.lastName)  AS clientName, c.avatarUrl  AS clientAvatar,
               CONCAT(co.firstName,' ',co.lastName) AS coachName,  co.avatarUrl AS coachAvatar
               FROM reservations r
               JOIN users c  ON c.id  = r.clientID
               JOIN users co ON co.id = r.coachID
               LEFT JOIN coachreviews cr ON cr.coachID=r.coachID AND cr.clientID=r.clientID
               WHERE 1=1`;
    const params = [];
    if (role === 'client') { sql += ' AND r.clientID=?'; params.push(userID); }
    if (role === 'coach')  { sql += ' AND r.coachID=?';  params.push(userID); }
    if (status) { sql += ' AND r.status=?'; params.push(status); }
    sql += ' ORDER BY r.reservedDate DESC, r.reservedTime DESC LIMIT ? OFFSET ?';
    params.push(Number(limit), Number(offset));
    const [rows] = await db.query(sql, params);
    res.json(rows.map(presentSessionLocation));
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// GET /reservations/advisor/:advisorID
// Toutes les réservations des coaches appartenant à cet advisor
router.get('/advisor/:advisorID', async (req, res) => {
  try {
    await expirePriceRequests(db,createAndSendNotification);
    const { status, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    let sql = `SELECT r.*, cr.rating AS reviewRating, cr.comment AS reviewComment,
               CONCAT(c.firstName,' ',c.lastName)   AS clientName,  c.avatarUrl  AS clientAvatar,
               CONCAT(co.firstName,' ',co.lastName)  AS coachName,   co.avatarUrl AS coachAvatar
               FROM reservations r
               JOIN users c   ON c.id  = r.clientID
               JOIN users co  ON co.id = r.coachID
               JOIN coachprofiles cp ON cp.userID = r.coachID
               LEFT JOIN coachreviews cr ON cr.coachID=r.coachID AND cr.clientID=r.clientID
               WHERE cp.advisorID = ?`;
    const params = [req.params.advisorID];

    if (status) { sql += ' AND r.status=?'; params.push(status); }
    sql += ' ORDER BY r.reservedDate DESC, r.reservedTime DESC LIMIT ? OFFSET ?';
    params.push(Number(limit), Number(offset));

    const [rows] = await db.query(sql, params);
    res.json(rows.map(presentSessionLocation));
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// GET /reservations/:id
router.get('/:id', async (req, res) => {
  try {
    await expirePriceRequests(db,createAndSendNotification);
    const [rows] = await db.query(
      `SELECT r.*, cr.rating AS reviewRating, cr.comment AS reviewComment,
              CONCAT(c.firstName,' ',c.lastName)  AS clientName,
              CONCAT(co.firstName,' ',co.lastName) AS coachName
       FROM reservations r
       JOIN users c  ON c.id  = r.clientID
       JOIN users co ON co.id = r.coachID
       LEFT JOIN coachreviews cr ON cr.coachID=r.coachID AND cr.clientID=r.clientID
       WHERE r.id=?`, [req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Not found' });
    res.json(presentSessionLocation(rows[0]));
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// POST /reservations
// Auto-remplit location & companyName depuis le profil advisor du coach
router.post('/', async (req, res) => {
  try {
    const { clientID, coachID, reservedDate, reservedTime, userID, packageID, sessions } = req.body;
    const cID = clientID ?? userID;
    if (!cID || !coachID)
      return res.status(400).json({ error: 'Missing required fields' });

    const sessionList = Array.isArray(sessions) && sessions.length > 0
      ? sessions
      : (reservedDate && reservedTime ? [{ reservedDate, reservedTime }] : []);

    if (sessionList.length === 0) {
      return res.status(400).json({ error: 'At least one session date and time is required' });
    }
    try { await requireBookingLeadTime(db,sessionList,sessionClock()); }
    catch(error) { return res.status(400).json({error:error.message}); }
    await expirePriceRequests(db,createAndSendNotification);

    // Vérifier que le coach existe et est approuvé
    const [coach] = await db.query(
      'SELECT id FROM users WHERE id=? AND role="coach" AND isApproved=1', [coachID]
    );
    if (!coach.length) return res.status(404).json({ error: 'Coach not found or not approved' });

    // Vérifier conflit de créneau et blocages pour chaque session
    for (const s of sessionList) {
      const sDate = s.reservedDate;
      const sTime = s.reservedTime.length === 5 ? `${s.reservedTime}:00` : s.reservedTime;
      s.reservedTime = sTime;

      const [conflict] = await db.query(
        `SELECT id FROM reservations
         WHERE coachID=? AND reservedDate=? AND reservedTime=?
           AND status IN ('pending','confirmed')`,
        [coachID, sDate, sTime]
      );
      if (conflict.length) {
        return res.status(409).json({ error: `Time slot already booked for ${sDate} at ${sTime.substring(0, 5)}` });
      }

      const [blocks] = await db.query(
        `SELECT id FROM coachavailabilityblocks
         WHERE coachID=? AND blockedDate=? AND startTime <= ? AND endTime > ?`,
        [coachID, sDate, sTime, sTime]
      );
      if (blocks.length) {
        return res.status(409).json({ error: `Coach not available on ${sDate} at ${sTime.substring(0, 5)}` });
      }
    }

    const [[gym]] = await db.query('SELECT gymName,gymAddress FROM coachprofiles WHERE userID=?', [coachID]);
    let autoLocation;
    const autoCompanyName = null;
    try { autoLocation = resolveSessionLocation(req.body.location, gym); }
    catch(error) { return res.status(400).json({error:error.message}); }

    // Resolve package info if provided
    let resolvedPackageID = null;
    let resolvedPackageName = null;
    let resolvedPrice = null;

    if (packageID) {
      const [pkgRows] = await db.query(
        'SELECT id, name, price, sessions, isPriceOnRequest FROM coach_packages WHERE id = ? AND coachID = ? AND isActive = 1',
        [packageID, coachID]
      );
      if (pkgRows.length) {
        resolvedPackageID   = pkgRows[0].id;
        resolvedPackageName = pkgRows[0].name;
        if (!Number(pkgRows[0].isPriceOnRequest) && pkgRows[0].price !== null && pkgRows[0].price !== undefined) {
          const totalPkgPrice = Number(pkgRows[0].price);
          const totalSessions = sessionList.length > 0 ? sessionList.length : (Number(pkgRows[0].sessions) || 1);
          resolvedPrice = Number((totalPkgPrice / totalSessions).toFixed(2));
        } else {
          resolvedPrice = null;
        }
      }
    } else if (req.body.price !== undefined && req.body.price !== null) {
      const entered = Number(req.body.price);
      if (!Number.isFinite(entered) || entered < 0) return res.status(400).json({error:'Invalid price'});
      resolvedPrice = entered > 0 ? entered : null;
    }

    if (resolvedPrice === null) {
      for (const s of sessionList) {
        const [[limit]]=await db.query('SELECT TIMESTAMP(?,?)<=DATE_ADD(?,INTERVAL 2 HOUR) AS tooLate',[s.reservedDate,s.reservedTime,sessionClock()]);
        if(limit.tooLate)return res.status(400).json({error:'Price-on-request bookings must be made more than two hours before the session.'});
      }
    }
    try { await requireBookingLeadTime(db,sessionList,sessionClock()); }
    catch(error) { return res.status(400).json({error:error.message}); }
    const createdIDs = [];
    for (const s of sessionList) {
      const [result] = await db.query(
        `INSERT INTO reservations (clientID, coachID, reservedDate, reservedTime, location, companyName, packageID, packageName, price, pricingStatus)
         VALUES (?,?,?,?,?,?,?,?,?,?)`,
        // Legacy schema requires a numeric price. pricingStatus, not the placeholder,
        // determines whether a price has been agreed; acceptance replaces price later.
        [cID, coachID, s.reservedDate, s.reservedTime, autoLocation, autoCompanyName, resolvedPackageID, resolvedPackageName, resolvedPrice ?? 0, resolvedPrice === null ? 'awaiting' : 'fixed']
      );
      createdIDs.push(result.insertId);
    }

    // Notify the coach of the new reservation(s)
    try {
      const [[client]] = await db.query(
        'SELECT firstName, lastName, avatarUrl FROM users WHERE id=?',
        [cID]
      );
      const clientName = client ? `${client.firstName} ${client.lastName}`.trim() : 'A client';
      const packageNote = resolvedPackageName ? ` (${resolvedPackageName})` : '';
      const sessionCountText = sessionList.length > 1 ? `${sessionList.length} sessions` : 'a session';
      await createAndSendNotification({
        recipientUserID: coachID,
        type: 'new_reservation',
        title: 'New Reservation Request 📅',
        body: `${clientName} requested ${sessionCountText}${packageNote}.`,
        relatedEntityID: createdIDs[0],
        actorName: clientName,
        actorAvatar: client?.avatarUrl ?? null,
        uniqueKey: `reservation:${createdIDs[0]}:coach:${coachID}`
      });
    } catch (notifyErr) {
      console.error('new_reservation notification failed:', notifyErr.message);
    }

    res.status(201).json({
      message: 'Reservation created',
      reservationID: createdIDs[0],
      reservationIDs: createdIDs,
      location: autoLocation,
      companyName: autoCompanyName,
      packageID: resolvedPackageID,
      packageName: resolvedPackageName,
      price: resolvedPrice,
      pricingStatus: resolvedPrice === null ? 'awaiting' : 'fixed',
    });
  } catch (err) { res.status(500).json({ error: err.message }); }
});


// PATCH /reservations/:id/confirm
router.patch('/:id/confirm', async (req, res) => {
  try {
    await expirePriceRequests(db,createAndSendNotification);
    const [rows] = await db.query('SELECT * FROM reservations WHERE id=?', [req.params.id]);
    if (!rows.length) return res.status(404).json({ error: 'Not found' });
    if (Number(rows[0].coachID)!==Number(req.user.id)||req.user.role!=='coach')return res.status(403).json({error:'Access denied'});
    if (rows[0].status !== 'pending' || rows[0].pricingStatus !== 'fixed') return res.status(400).json({ error: 'Client must accept the proposed price first' });
    const [updated] = await db.query('UPDATE reservations SET status="confirmed" WHERE id=? AND status="pending" AND pricingStatus="fixed" AND TIMESTAMP(reservedDate,reservedTime)>DATE_ADD(?,INTERVAL 1 HOUR)', [req.params.id,sessionClock()]);
    if (!updated.affectedRows) return res.status(409).json({error:'This request expired or changed. Refresh the session.'});
    
    // Notify the client that their reservation was confirmed
    try {
      const resv = rows[0];
      const [[coach]] = await db.query('SELECT firstName, lastName, avatarUrl FROM users WHERE id=?', [resv.coachID]);
      const coachName = coach ? `${coach.firstName} ${coach.lastName}`.trim() : 'Your coach';
      await createAndSendNotification({
        recipientUserID: resv.clientID,
        type: 'reservation_confirmed',
        title: 'Reservation Confirmed ✅',
        body: `${coachName} confirmed your booking.`,
        relatedEntityID: resv.id,
        actorName: coachName,
        actorAvatar: coach?.avatarUrl ?? null,
        uniqueKey: `resv_confirmed:${resv.id}`
      });
    } catch (err) {
      console.error('reservation_confirmed notification error:', err.message);
    }

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
    if (Number(rows[0].clientID)!==Number(req.user.id) && Number(rows[0].coachID)!==Number(req.user.id)) return res.status(403).json({error:'Access denied'});
    await db.query(
      'UPDATE reservations SET status="cancelled", cancellationReason=?, cancelledBy=? WHERE id=?',
      [cancellationReason || null, req.user.role === 'coach' ? 'coach' : null, req.params.id]
    );
    await createAndSendNotification({recipientUserID:Number(rows[0].clientID)===Number(req.user.id)?rows[0].coachID:rows[0].clientID,type:'reservation_cancelled',title:'Session cancelled',body:cancellationReason ? `The session was cancelled. Reason: ${cancellationReason}` : 'The session was cancelled. Open the booking for details.',relatedEntityID:req.params.id,uniqueKey:`resv_cancelled:${req.params.id}`});
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
    if (Number(rows[0].coachID) !== Number(req.user.id)) return res.status(403).json({error:'Access denied'});
    await db.query(
      'UPDATE reservations SET status="cancelled", rejectionReason=? WHERE id=?',
      [rejectionReason || null, req.params.id]
    );

    // Notify the client of rejection
    try {
      const resv = rows[0];
      const [[coach]] = await db.query('SELECT firstName, lastName, avatarUrl FROM users WHERE id=?', [resv.coachID]);
      const coachName = coach ? `${coach.firstName} ${coach.lastName}`.trim() : 'Your coach';
      await createAndSendNotification({
        recipientUserID: resv.clientID,
        type: 'reservation_rejected',
        title: 'Reservation Declined ❌',
        body: `${coachName} declined your booking request.`,
        relatedEntityID: resv.id,
        actorName: coachName,
        actorAvatar: coach?.avatarUrl ?? null,
        uniqueKey: `resv_rejected:${resv.id}`
      });
    } catch (err) {
      console.error('reservation_rejected notification error:', err.message);
    }

    res.json({ message: 'Reservation rejected' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

export default router;
