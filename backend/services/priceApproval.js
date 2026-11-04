import {expireUnapprovedReservations} from './bookingPolicy.js';
import {invalidate} from './realtime.js';
export function sessionClock(now = new Date()) {
  const parts = new Intl.DateTimeFormat('en-CA',{timeZone:'Africa/Casablanca',year:'numeric',month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit',second:'2-digit',hourCycle:'h23'}).formatToParts(now);
  const p=Object.fromEntries(parts.map(x=>[x.type,x.value]));
  return `${p.year}-${p.month}-${p.day} ${p.hour}:${p.minute}:${p.second}`;
}
export function validOffer(price) {
  if (price === null || price === '' || !['number','string'].includes(typeof price)) return false;
  const n=Number(price);return Number.isFinite(n)&&n>=0&&n<=99999999.99&&Math.abs(n*100-Math.round(n*100))<0.00001;
}
export async function expirePriceRequests(db, notify) {
  const now=sessionClock();
  const [rows]=await db.query("SELECT id,clientID,coachID FROM reservations WHERE status='pending' AND pricingStatus IN ('awaiting','proposed') AND TIMESTAMP(reservedDate,reservedTime)<=DATE_ADD(?,INTERVAL 2 HOUR)",[now]);
  for(const row of rows){
    const [result]=await db.query("UPDATE reservations SET status='cancelled',pricingStatus='expired',cancellationReason='Price was not agreed at least two hours before the session' WHERE id=? AND status='pending' AND pricingStatus IN ('awaiting','proposed')",[row.id]);
    if(result.affectedRows)invalidate('reservations');
    if(result.affectedRows)for(const recipientUserID of [row.clientID,row.coachID]){
      try{await notify({recipientUserID,type:'price_expired',title:'Booking request expired',body:'The price was not agreed before the two-hour deadline.',relatedEntityID:row.id,uniqueKey:`price_expired:${row.id}:${recipientUserID}`});}catch(error){console.error('Price expiry notification failed',error.message)}
    }
  }
  await expireUnapprovedReservations(db, notify, now);
}
