import {sessionClock} from './priceApproval.js';

export async function sendDueSessionReminders(db, notify) {
  const clock = sessionClock();
  const [rows] = await db.query(`SELECT id,coachID,clientID,reservedTime FROM reservations
    WHERE status='confirmed' AND TIMESTAMP(reservedDate,reservedTime)>?
    AND TIMESTAMP(reservedDate,reservedTime)<=DATE_ADD(?,INTERVAL 60 MINUTE)`, [clock,clock]);
  for (const row of rows) {
    for (const recipientUserID of [row.coachID,row.clientID]) {
      await notify({recipientUserID,type:'upcoming_session',title:'Your session starts soon',
        body:`Your session starts at ${String(row.reservedTime).slice(0,5)}. Open the booking to check the location.`,
        relatedEntityID:row.id,uniqueKey:`session-reminder:${row.id}:60m:${Number(recipientUserID)===Number(row.coachID)?'coach':'client'}:${recipientUserID}`});
    }
  }
  const [quotes] = await db.query(`SELECT id,coachID,clientID,pricingStatus FROM reservations
    WHERE status='pending' AND pricingStatus IN ('awaiting','proposed')
    AND TIMESTAMP(reservedDate,reservedTime)>DATE_ADD(?,INTERVAL 2 HOUR)
    AND TIMESTAMP(reservedDate,reservedTime)<=DATE_ADD(?,INTERVAL 3 HOUR)`,[clock,clock]);
  for (const row of quotes) {
    const proposing = row.pricingStatus === 'awaiting';
    const recipientUserID = proposing ? row.coachID : row.clientID;
    await notify({recipientUserID,type:'price_reminder',title:proposing?'Session price still needed':'Your price offer needs a response',
      body:proposing?'Propose a price soon. This request expires two hours before the session unless the client accepts.':'Accept or decline your coach’s offer soon. It expires two hours before the session.',
      relatedEntityID:row.id,uniqueKey:`price_reminder:${row.id}:${row.pricingStatus}:${recipientUserID}`});
  }
}
