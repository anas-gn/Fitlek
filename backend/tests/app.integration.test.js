import test from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import express from 'express';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcrypt';
import dotenv from 'dotenv';
dotenv.config({path: new URL('../.env', import.meta.url), quiet: true});

test('SIRVYA existing app HTTP / MySQL flows', {skip: process.env.APP_TEST_MYSQL !== '1'}, async t => {
  assert.ok(['localhost', '127.0.0.1', '::1'].includes(process.env.DB_HOST), 'App fixtures require local MySQL');
  const {default: db} = await import('../config/db.js');
  const {ensureAppCompatibilitySchema} = await import('../config/appCompatibilitySchema.js');
  const {ensureGoogleAuthSchema} = await import('../config/googleAuthSchema.js');
  const {default: admin, initFirebase} = await import('../config/firebase.js');
  const {requireAuth} = await import('../middleware/auth.js');
  const prefix = `app-test-${Date.now()}-${process.pid}`;
  const users = [];
  let server;
  initFirebase();
  const messaging = admin.messaging();
  const originalSend = messaging.send;
  const pushes = [];
  // Provider delivery is simulated only in this test process, never the API.
  messaging.send = async message => { pushes.push(message); return 'fixture-message'; };
  try {
    await ensureGoogleAuthSchema(db);
    await ensureAppCompatibilitySchema(db);
    await ensureAppCompatibilitySchema(db);
    const hash = await bcrypt.hash('AppFixturePassword123', 10);
    for (const role of ['client', 'coach', 'client', 'coach', 'manager']) {
      const [inserted] = await db.query(`INSERT INTO users (firstName,lastName,email,passwordHash,role,gender,isApproved)
        VALUES ('App','Fixture',?,?,?,'Other',1)`, [`${prefix}-${users.length}@example.invalid`, hash, role]);
      users.push({id: inserted.insertId, role});
      if (role === 'coach') {
        await db.query("INSERT INTO coachprofiles (userID,bio,invitationCode) VALUES (?,'Fixture',?)", [inserted.insertId, `${prefix}-${users.length}`]);
      }
    }
    const [client, coach, otherClient, otherCoach, manager] = users;
    await db.query('INSERT INTO coachclients (coachID,clientID) VALUES (?,?)', [coach.id, client.id]);
    const app = express(); app.use(express.json());
    const protectedRoutes = [
      ['clients','anas/client'], ['coaches','anas/coach'], ['advisors','anas/advisorProfiles'],
      ['reservations','anas/reservations'], ['availability','anas/coachAvailability'],
      ['conversations','anas/conversations'], ['messages','anas/messages'], ['invitations','anas/invitations'],
      ['weight-history','anas/weightHistory'], ['reviews','anas/reviews'], ['ugc','anas/ugc'],
      ['categories','anas/categories'], ['favorites','anas/favorites'],
      ['premium','anas/premium'], ['premium/workouts','anas/premiumWorkouts'], ['coach/premium','anas/premiumCoach'],
    ];
    const standaloneRoutes = [
      ['auth','anas/auth'], ['coach/dashboard','pahae/coachDashboard'], ['coach/profile','pahae/coachProfile'],
      ['coach/profile/edit','pahae/coachEditProfile'], ['coach/calendar','pahae/coachCalendar'],
      ['coach/clients','pahae/coachClients'], ['coach/conversations','pahae/coachConversations'],
      ['coach/chat','pahae/coachChat'], ['coach/invitations','pahae/coachInvitations'],
      ['coach/invite','pahae/coachInviteClients'], ['coach/notifications','pahae/coachNotifications'],
      ['manager/dashboard','pahae/managerDashboard'], ['manager/profile','pahae/managerProfile'],
      ['manager/clients','pahae/managerClients'], ['manager/coaches','pahae/managerCoaches'],
    ];
    for (const [path, file] of protectedRoutes) {
      const {default: router} = await import(`../routes/${file}.js`); app.use('/api/' + path, requireAuth, router);
    }
    for (const [path, file] of standaloneRoutes) {
      const {default: router} = await import(`../routes/${file}.js`); app.use('/api/' + path, router);
    }
    server = app.listen(0, '127.0.0.1'); await once(server, 'listening');
    const request = async (user, path, method='GET', body) => {
      const token = user ? jwt.sign(user, process.env.JWT_SECRET, {expiresIn: '5m'}) : null;
      const response = await fetch(`http://127.0.0.1:${server.address().port}/api${path}`, {
        method, headers: {'Content-Type': 'application/json', ...(token ? {Authorization: `Bearer ${token}`} : {})},
        ...(body === undefined ? {} : {body: JSON.stringify(body)}),
      });
      return {status: response.status, body: await response.json()};
    };
    const expect = async (user, path, status=200, method='GET', body) => {
      const result = await request(user, path, method, body);
      assert.equal(result.status, status, `${method} ${path}: ${JSON.stringify(result.body)}`);
      return result.body;
    };
    await t.test('main Client, Coach and Manager screen reads', async () => {
      for (const path of [`/clients/me?userID=${client.id}`, '/coaches', `/coaches/${coach.id}`, '/advisors',
        `/reservations?userID=${client.id}&role=client`, `/availability/${coach.id}?date=2035-01-01`,
        `/conversations?userID=${client.id}&role=client`, `/conversations/unread-total?userID=${client.id}`,
        `/weight-history/me?clientID=${client.id}`, `/weight-history/me/stats?clientID=${client.id}`,
        `/weight-history/me/chart?clientID=${client.id}`, `/reviews/coach/${coach.id}`, '/ugc/blocked',
        '/premium/status', '/premium/workouts/routines', '/premium/workouts/history', '/premium/workouts/exercises',
        '/premium/workouts/stats', '/premium/workouts/body-weight','/categories','/favorites']) await expect(client, path);
      for (const path of ['/coach/dashboard','/coach/profile','/coach/clients', `/coach/clients/${client.id}`,
        '/coach/conversations','/coach/calendar/reservations','/coach/calendar/availability','/coach/invitations',
        '/coach/invite','/coach/invite/referrals','/coach/notifications','/coach/notifications/unread-count',
        `/coach/premium/clients/${client.id}/history`]) await expect(coach, path);
      for (const path of ['/manager/dashboard','/manager/profile','/manager/clients','/manager/coaches']) await expect(manager,path);
    });
    await t.test('password login, refresh and logout', async () => {
      const loggedIn = await expect(null, '/auth/login', 200, 'POST', {email: `${prefix}-0@example.invalid`, password: 'AppFixturePassword123'});
      assert.equal(loggedIn.user.id, client.id);
      const refreshed = await expect(null, '/auth/refresh', 200, 'POST', {refreshToken: loggedIn.refreshToken});
      assert.equal(jwt.verify(refreshed.accessToken, process.env.JWT_SECRET).id, client.id);
      await expect(null, '/auth/logout', 200, 'POST', {refreshToken: loggedIn.refreshToken});
      await expect(null, '/auth/refresh', 401, 'POST', {refreshToken: loggedIn.refreshToken});
    });
    await t.test('coach profile edit and linked client ownership', async () => {
      await expect(coach, '/coach/profile/edit', 200, 'PUT', {firstName:'App',lastName:'Fixture',gender:'Other',bio:'Verified fixture',tel:'0000000000',ville:'Test city',certifications:['Fixture']});
      const profile = await expect(coach,'/coach/profile');
      assert.equal(profile.bio, 'Verified fixture'); assert.equal(profile.ville,'Test city');
      await expect(otherCoach, `/coach/clients/${client.id}`, 403);
      await expect(client,'/coach/profile',403);
      await expect(null,'/coach/dashboard',401);
      await expect(null,'/premium/status',401);
    });
    await t.test('availability, reservation conflicts, accept, cancel and reject', async () => {
      const blocked = await expect(coach,'/coach/calendar/availability',201,'POST',{blockedDate:'2035-01-01',startTime:'10:00',endTime:'11:00',note:'Fixture'});
      const reserve = {clientID:client.id,coachID:coach.id,reservedDate:'2035-01-01',reservedTime:'10:30'};
      await expect(client,'/reservations',409,'POST',reserve);
      await expect(coach,`/coach/calendar/availability/${blocked.id}`,200,'DELETE');
      const created = await expect(client,'/reservations',201,'POST',reserve);
      await expect(client,'/reservations',409,'POST',reserve);
      await expect(otherCoach,`/coach/calendar/reservations/${created.reservationID}/accept`,404,'PATCH',{});
      await expect(coach,`/coach/calendar/reservations/${created.reservationID}/accept`,200,'PATCH',{});
      assert.equal((await expect(client,`/reservations/${created.reservationID}`)).status,'confirmed');
      const upcoming = await expect(client,`/reservations?clientID=${client.id}&status=confirmed&upcoming=true`);
      assert.equal(upcoming.length,1); assert.ok(upcoming[0].sessionStart.startsWith('2035-01-01T10:30'));
      assert.equal((await expect(otherClient,`/reservations?clientID=${client.id}&status=confirmed&upcoming=true`)).length,0);
      await expect(coach,`/coach/calendar/reservations/${created.reservationID}/cancel`,200,'PATCH',{reason:'Fixture cleanup'});
      const next = await expect(client,'/reservations',201,'POST',{...reserve,reservedTime:'12:00'});
      await expect(coach,`/coach/calendar/reservations/${next.reservationID}/reject`,200,'PATCH',{reason:'Fixture'});
      // Legacy recurring blocks must also remain effective after migration.
      await db.query("INSERT INTO coachavailabilityblocks (coachID,dayOfWeek,startTime,endTime,isRecurring) VALUES (?,'Monday','14:00','15:00',1)",[coach.id]);
      await expect(client,'/reservations',409,'POST',{...reserve,reservedTime:'14:30'});
    });
    await t.test('Client and Coach messages, media, unread state and in-app notifications', async () => {
      const conv = await expect(coach,`/coach/clients/${client.id}/conversation`,201,'POST',{});
      const reused = await expect(client,'/conversations/find-or-create',200,'POST',{clientID:client.id,coachID:coach.id});
      assert.equal(reused.conversationID,conv.conversationID);
      await expect(client,`/messages/${conv.conversationID}`,201,'POST',{senderID:client.id,body:'Fixture message'});
      assert.equal((await expect(coach,'/coach/conversations'))[0].unreadCount,1);
      assert.equal((await expect(coach,`/coach/chat/${conv.conversationID}`))[0].body,'Fixture message');
      await expect(otherCoach,`/coach/chat/${conv.conversationID}`,403);
      await expect(otherClient,`/messages/${conv.conversationID}`,404);
      await expect(otherClient,`/messages/${conv.conversationID}`,404,'POST',{senderID:client.id,body:'Impersonation fixture'});
      await expect(client,`/messages/${conv.conversationID}`,403,'POST',{senderID:coach.id,body:'Impersonation fixture'});
      await expect(otherClient,`/conversations?userID=${client.id}&role=client`,403);
      await expect(client,`/conversations?userID=${client.id}&role=coach`,403);
      await expect(otherClient,'/conversations/find-or-create',403,'POST',{clientID:client.id,coachID:coach.id});
      await expect(coach,`/coach/chat/${conv.conversationID}`,201,'POST',{mediaUrl:'https://example.invalid/fixture.png',mediaType:'image'});
      const messages = await expect(client,`/messages/${conv.conversationID}?readerID=${client.id}`);
      assert.equal(messages.length,2); assert.equal(messages[1].mediaType,'image');
      assert.equal((await expect(client,`/conversations/unread-total?userID=${client.id}`)).totalUnread,0);
      const notifications = await expect(coach,'/coach/notifications');
      assert.ok(notifications.some(n=>n.type==='new_message'));
      const notification = notifications.find(n=>n.type==='new_message');
      await expect(otherCoach,`/coach/notifications/${notification.id}/read`,404,'PATCH',{});
      await expect(coach,`/coach/notifications/${notification.id}/read`,200,'PATCH',{});
      await expect(coach,'/coach/notifications/read-all',200,'PATCH',{});
      assert.equal((await expect(coach,'/coach/notifications/unread-count')).count,0);
    });
    await t.test('client invitation links accounts and creates only one conversation', async () => {
      const invite = await expect(otherClient,'/invitations/send',201,'POST',{senderID:otherClient.id,coachID:coach.id});
      await expect(coach,`/coach/invitations/${invite.id}/accept`,200,'PATCH',{});
      await expect(coach,`/coach/invitations/${invite.id}/accept`,404,'PATCH',{});
      assert.ok((await expect(coach,'/coach/clients')).some(u=>u.id===otherClient.id));
      const conv = await expect(coach,`/coach/clients/${otherClient.id}/conversation`,200,'POST',{});
      assert.equal(conv.created,false);
    });
    await t.test('body weight, reviews, blocking and existing Premium reads', async () => {
      const entry = await expect(client,'/weight-history',201,'POST',{clientID:client.id,weight:75,note:'Fixture'});
      assert.equal((await expect(client,`/weight-history/me?clientID=${client.id}`)).length,1);
      await expect(otherClient,`/weight-history/${entry.id}`,404,'PUT',{weight:1});
      await expect(otherClient,`/weight-history/${entry.id}`,404,'DELETE');
      await expect(otherClient,`/weight-history/me?clientID=${client.id}`,403);
      await expect(otherCoach,`/weight-history/me?clientID=${client.id}`,403);
      await expect(client,`/weight-history/${entry.id}`,200,'PUT',{weight:74,note:'Fixture'});
      await expect(client,`/weight-history/${entry.id}`,200,'DELETE');
      await expect(client,'/ugc/block',200,'POST',{blockedID:otherCoach.id});
      assert.ok((await expect(client,'/ugc/blocked')).some(u=>u.id===otherCoach.id));
      await expect(client,`/coaches/${otherCoach.id}`,404);
      await expect(client,'/ugc/unblock',200,'POST',{blockedID:otherCoach.id});
      assert.equal((await expect(client,'/ugc/blocked')).length,0);
      assert.equal((await expect(client,'/favorites/toggle',200,'POST',{coachID:coach.id})).favorited,true);
      assert.deepEqual(await expect(client,'/favorites'),[coach.id]);
      assert.deepEqual(await expect(otherClient,`/favorites?clientID=${client.id}`),[]);
      assert.equal((await expect(client,'/favorites/toggle',200,'POST',{coachID:coach.id})).favorited,false);
    });
    await t.test('push integration uses the existing initialized Firebase app', async () => {
      await db.query('UPDATE users SET fcmToken=? WHERE id=?',['app-fixture-not-a-real-fcm-token',coach.id]);
      const {sendPushNotification} = await import('../services/pushNotificationService.js');
      const result = await sendPushNotification({recipientUserID:coach.id,title:'Fixture',body:'Fixture',data:{id:123}});
      assert.equal(result.success,true); assert.equal(pushes.length,1); assert.equal(pushes[0].data.id,'123');
    });
  } finally {
    messaging.send = originalSend;
    if (server) await new Promise(resolve=>server.close(resolve));
    const [fixtures] = await db.query('SELECT id FROM users WHERE email LIKE ?',[`${prefix}%@example.invalid`]);
    for (const fixture of fixtures) await db.query('DELETE FROM users WHERE id=?',[fixture.id]);
    await db.end();
  }
});
