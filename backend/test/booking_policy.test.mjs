import test from 'node:test';
import assert from 'node:assert/strict';
import {requireBookingLeadTime,expireUnapprovedReservations,COACH_APPROVAL_EXPIRY_REASON} from '../services/bookingPolicy.js';

const wallTime = value => Date.parse(value.replace(' ', 'T') + 'Z');
test('one-hour booking boundary is strict and applies to every package session', async () => {
  const db={query:async(sql,[date,time,now])=>[[{canBook:wallTime(`${date} ${time}`)>wallTime(now)+3600000?1:0}]]};
  const now='2026-10-12 19:00:00';
  const session=time=>({reservedDate:'2026-10-12',reservedTime:time});
  await assert.rejects(requireBookingLeadTime(db,[session('19:59:00')],now),/more than one hour/);
  await assert.rejects(requireBookingLeadTime(db,[session('20:00:00')],now),/more than one hour/);
  await requireBookingLeadTime(db,[session('20:00:01')],now);
  await assert.rejects(requireBookingLeadTime(db,[session('21:00:00'),session('20:00:00')],now),/more than one hour/);
  await assert.rejects(requireBookingLeadTime(db,[session('25:00:00')],now),/valid session/);
  await assert.rejects(requireBookingLeadTime(db,[{reservedDate:'bad'}],now),/valid session/);
});

test('expiry notifies both participants once and never cancels a concurrently confirmed booking', async () => {
  let expired=false; const notifications=[]; const statements=[];
  const db={query:async(sql,args)=>{
    statements.push(sql);
    if(sql.startsWith('SELECT'))return [[{id:4,clientID:8,coachID:7}]];
    assert.equal(args[0],COACH_APPROVAL_EXPIRY_REASON);
    const changed=!expired;expired=true;return [{affectedRows:changed?1:0}];
  }};
  await expireUnapprovedReservations(db,n=>notifications.push(n),'2026-10-12 19:00:00');
  await expireUnapprovedReservations(db,n=>notifications.push(n),'2026-10-12 19:00:00');
  assert.deepEqual(notifications.map(n=>n.recipientUserID),[8,7]);
  assert.ok(notifications.every(n=>n.type==='reservation_expired'&&n.relatedEntityID===4));
  assert.ok(statements.every(sql=>sql.includes("status='pending'")&&sql.includes("pricingStatus='fixed'")&&sql.includes('INTERVAL 1 HOUR')));
  const concurrent={query:async(sql)=>sql.startsWith('SELECT')?[[{id:9,clientID:8,coachID:7}]]:[{affectedRows:0}]};
  await expireUnapprovedReservations(concurrent,()=>assert.fail('confirmed bookings must not expire'),'2026-10-12 19:00:00');
});
