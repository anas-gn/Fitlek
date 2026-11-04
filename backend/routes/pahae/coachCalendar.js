import {expirePriceRequests,sessionClock} from '../../services/priceApproval.js';
import {createAndSendNotification} from '../../services/pushNotificationService.js';
import { Router } from 'express';
import {presentSessionLocation} from '../../services/sessionLocation.js';
import pool from '../../config/db.js';
import { requireAuth, requireRole } from '../../middleware/auth.js';

const router = Router();

router.get('/reservations', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  try {
    await expirePriceRequests(pool,createAndSendNotification);
    const [rows] = await pool.query(
      `SELECT r.id, r.reservedDate, r.reservedTime, r.status, r.location, r.companyName, r.price, r.packageName,
              CASE WHEN r.pricingStatus = 'fixed' AND r.price IS NULL THEN 'awaiting' ELSE r.pricingStatus END AS pricingStatus,
              r.proposedPrice, r.quoteVersion,
              u.firstName, u.lastName, u.avatarUrl
       FROM reservations r
       JOIN users u ON u.id = r.clientID
       WHERE r.coachID = ?
       ORDER BY r.reservedDate ASC, r.reservedTime ASC`,
      [coachID]
    );
    res.json(rows.map(presentSessionLocation));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.patch('/reservations/:id/accept', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  const { id } = req.params;
  try {
    await expirePriceRequests(pool, createAndSendNotification);
    const [[res_]] = await pool.query(
      `SELECT id, clientID, status, pricingStatus, price FROM reservations WHERE id = ? AND coachID = ?`,
      [id, coachID]
    );
    if (!res_) return res.status(404).json({ message: 'Reservation not found.' });
    if (res_.status !== 'pending') return res.status(409).json({ message: 'This reservation is no longer pending. Refresh to see its current status.' });
    if (res_.pricingStatus !== 'fixed' || res_.price === null) return res.status(409).json({ message: res_.pricingStatus === 'proposed' ? 'Waiting for the client to accept your price offer.' : 'Propose a session price first. The client must accept it to confirm the booking.' });
    const [updated] = await pool.query(`UPDATE reservations SET status = 'confirmed' WHERE id = ? AND coachID = ? AND pricingStatus='fixed' AND price IS NOT NULL AND status='pending' AND TIMESTAMP(reservedDate,reservedTime)>DATE_ADD(?,INTERVAL 1 HOUR)`, [id, coachID,sessionClock()]);
    if (!updated.affectedRows) return res.status(409).json({ message: 'The reservation changed. Refresh and try again.' });
    await createAndSendNotification({recipientUserID: res_.clientID, type:'reservation_confirmed', title:'Session confirmed', body:'Your coach confirmed your booking. Open it to see the session details.', relatedEntityID:id, uniqueKey:`resv_confirmed:${id}`});
    res.json({ message: 'Reservation confirmed.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.patch('/reservations/:id/reject', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  const { id } = req.params;
  const { reason } = req.body;
  if (!reason) return res.status(400).json({ message: 'Rejection reason is required.' });
  try {
    const [[res_]] = await pool.query(
      `SELECT id, clientID FROM reservations WHERE id = ? AND coachID = ? AND status = 'pending'`,
      [id, coachID]
    );
    if (!res_) return res.status(404).json({ message: 'Reservation not found.' });
    await pool.query(
      `UPDATE reservations SET status = 'cancelled', rejectionReason = ?, cancelledBy = 'coach' WHERE id = ?`,
      [reason, id]
    );
    await createAndSendNotification({recipientUserID:res_.clientID,type:'reservation_rejected',title:'Booking declined',body:`Your coach declined the request. Reason: ${reason}`,relatedEntityID:id,uniqueKey:`resv_rejected:${id}`});
    res.json({ message: 'Reservation rejected.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.patch('/reservations/:id/cancel', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  const { id } = req.params;
  const { reason } = req.body;
  if (!reason) return res.status(400).json({ message: 'Cancellation reason is required.' });
  try {
    const [[res_]] = await pool.query(
      `SELECT id, clientID, reservedDate FROM reservations
       WHERE id = ? AND coachID = ? AND status = 'confirmed'`,
      [id, coachID]
    );
    if (!res_) return res.status(404).json({ message: 'Reservation not found.' });
    const diffDays = (new Date(res_.reservedDate) - new Date()) / 86400000;
    if (diffDays <= 3) {
      return res.status(400).json({ message: 'Cancellation only allowed more than 3 days before the session.' });
    }
    await pool.query(
      `UPDATE reservations SET status = 'cancelled', cancellationReason = ?, cancelledBy = 'coach' WHERE id = ?`,
      [reason, id]
    );
    await createAndSendNotification({recipientUserID:res_.clientID,type:'reservation_cancelled',title:'Session cancelled',body:`Your coach cancelled the session. Reason: ${reason}`,relatedEntityID:id,uniqueKey:`resv_cancelled:${id}`});
    res.json({ message: 'Reservation cancelled.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/availability', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  try {
    const [rows] = await pool.query(
      `SELECT id, blockedDate, startTime, endTime, note
       FROM coachavailabilityblocks
       WHERE coachID = ?
       ORDER BY blockedDate ASC, startTime ASC`,
      [coachID]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.post('/availability', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  const { blockedDate, startTime, endTime, note } = req.body;
  if (!blockedDate || !startTime || !endTime) {
    return res.status(400).json({ message: 'blockedDate, startTime and endTime are required.' });
  }
  if (endTime <= startTime) {
    return res.status(400).json({ message: 'endTime must be after startTime.' });
  }
  try {
    const [result] = await pool.query(
      `INSERT INTO coachavailabilityblocks (coachID, blockedDate, startTime, endTime, note)
       VALUES (?, ?, ?, ?, ?)`,
      [coachID, blockedDate, startTime, endTime, note || null]
    );
    res.status(201).json({ id: result.insertId });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.delete('/availability/:id', requireAuth, requireRole('coach'), async (req, res) => {
  const coachID = req.user.id;
  const { id } = req.params;
  try {
    const [result] = await pool.query(
      `DELETE FROM coachavailabilityblocks WHERE id = ? AND coachID = ?`,
      [id, coachID]
    );
    if (result.affectedRows === 0) return res.status(404).json({ message: 'Block not found.' });
    res.json({ message: 'Availability block deleted.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
