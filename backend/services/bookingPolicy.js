import {invalidate} from './realtime.js';

export const COACH_APPROVAL_EXPIRY_REASON = 'Coach did not approve at least one hour before the session';

export async function requireBookingLeadTime(db, sessions, now) {
  for (const session of sessions) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(session.reservedDate ?? '') ||
        !/^(?:[01]\d|2[0-3]):[0-5]\d(?::[0-5]\d)?$/.test(session.reservedTime ?? '')) {
      throw new Error('Choose a valid session date and time.');
    }
    const [[row]] = await db.query(
      'SELECT TIMESTAMP(?,?) > DATE_ADD(?, INTERVAL 1 HOUR) AS canBook',
      [session.reservedDate, session.reservedTime, now]);
    if (Number(row?.canBook) !== 1) throw new Error('Book sessions more than one hour before their start time.');
  }
}

export async function expireUnapprovedReservations(db, notify, now) {
  const [rows] = await db.query(
    "SELECT id,clientID,coachID FROM reservations WHERE status='pending' AND pricingStatus='fixed' AND TIMESTAMP(reservedDate,reservedTime)<=DATE_ADD(?,INTERVAL 1 HOUR)", [now]);
  for (const row of rows) {
    const [result] = await db.query(
      "UPDATE reservations SET status='cancelled',pricingStatus='expired',cancellationReason=? WHERE id=? AND status='pending' AND pricingStatus='fixed' AND TIMESTAMP(reservedDate,reservedTime)<=DATE_ADD(?,INTERVAL 1 HOUR)",
      [COACH_APPROVAL_EXPIRY_REASON, row.id, now]);
    if (!result.affectedRows) continue;
    invalidate('reservations');
    for (const recipientUserID of [row.clientID, row.coachID]) {
      try {
        await notify({recipientUserID, type:'reservation_expired', title:'Booking request expired',
          body:'The coach did not approve this booking before the one-hour deadline.', relatedEntityID:row.id,
          uniqueKey:`reservation_expired:${row.id}:${recipientUserID}`});
      } catch (error) { console.error('Booking expiry notification failed', error.code ?? 'notification_error'); }
    }
  }
}
