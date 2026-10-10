import test from 'node:test';
import assert from 'node:assert/strict';
import {once} from 'node:events';
import express from 'express';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcrypt';
import dotenv from 'dotenv';
dotenv.config({path: new URL('../.env',import.meta.url),quiet:true});

test('Reset proof, session revocation and legacy ownership regressions', {skip:process.env.APP_TEST_MYSQL!=='1'}, async t=>{
  assert.ok(['localhost','127.0.0.1','::1'].includes(process.env.DB_HOST),'Fixtures require local MySQL');
  const {default:db}=await import('../config/db.js');
  const {ensureGoogleAuthSchema}=await import('../config/googleAuthSchema.js');
  const {ensureAppCompatibilitySchema}=await import('../config/appCompatibilitySchema.js');
  const {createPasswordResetRouter}=await import('../routes/anas/passwordReset.js');
  const {requireAuth}=await import('../middleware/auth.js');
  const prefix=`security-${Date.now()}-${process.pid}`;
  const users=[], deliveries=[];
  let server;
  try {
    await ensureGoogleAuthSchema(db); await ensureAppCompatibilitySchema(db);
    const hash=await bcrypt.hash('OriginalPassword123',10);
    for(const role of ['client','coach','client','coach','advisor','manager','admin']){
      const email=`${prefix}-${users.length}@example.invalid`;
      const [row]=await db.query("INSERT INTO users(firstName,lastName,email,passwordHash,role,gender,isApproved) VALUES('Security','Fixture',?,?,?,'Other',1)",[email,hash,role]);
      users.push({id:row.insertId,role,email});
      if(role==='coach')await db.query('INSERT INTO coachprofiles(userID,bio,invitationCode) VALUES(?,?,?)',[row.insertId,'Fixture',`${prefix}-${users.length}`]);
    }
    const [client,coach,otherClient,otherCoach,advisor,manager,admin]=users;
    await db.query('INSERT INTO coachclients(coachID,clientID) VALUES(?,?)',[coach.id,client.id]);
    const app=express(); app.use(express.json());
    app.use('/reset',createPasswordResetRouter(db,{sendCode:async data=>deliveries.push(data)}));
    // Verify the actual auth mount retires legacy endpoints, not just the factory.
    const {default:auth}=await import('../routes/anas/auth.js'); app.use('/auth',auth);
    for(const [route,file] of [['clients','client'],['coaches','coach'],['advisors','advisorProfiles'],['links','coachClients'],['bans','bans'],['invitations','invitations'],['upload','upload']]){
      const {default:router}=await import(`../routes/anas/${file}.js`);app.use('/'+route,requireAuth,router);
    }
    server=app.listen(0,'127.0.0.1');await once(server,'listening');
    const call=async(path,{user,body,method='POST',token}={})=>{
      const response=await fetch(`http://127.0.0.1:${server.address().port}${path}`,{method,headers:{'Content-Type':'application/json',...(user||token?{Authorization:`Bearer ${token??jwt.sign({id:user.id,role:user.role,tokenVersion:user.tokenVersion??0},process.env.JWT_SECRET,{expiresIn:'5m'})}`}:{})},...(body?{body:JSON.stringify(body)}:{})});
      return {status:response.status,body:await response.json()};
    };
    const expect=async(path,options,status)=>{const r=await call(path,options);assert.equal(r.status,status,`${path}: ${JSON.stringify(r.body)}`);return r.body;};
    const challenge=async(user)=>{
      const body=await expect('/reset/send-forgot-otp',{body:{email:user.email}},200);
      assert.equal(body._devToken,undefined);assert.equal(body.otp,undefined);assert.equal(body.resetToken,undefined);
      return deliveries.at(-1).otp;
    };
    await t.test('database timeouts and pool failures preserve authentication with HTTP 503',async()=>{
      const original=db.query;
      try{
        for(const code of ['ETIMEDOUT','PROTOCOL_CONNECTION_LOST','POOL_CLOSED']){
          db.query=async()=>{throw Object.assign(new Error('Private database details'),{code});};
          const response=await expect('/clients/me',{user:client,method:'GET'},503);
          assert.equal(JSON.stringify(response).includes('Private database details'),false);
          await expect('/clients/me',{token:'invalid',method:'GET'},401);
        }
      }finally{db.query=original;}
      await expect('/clients/me',{user:client,method:'GET'},200);
    });
    await t.test('all roles are blocked from forging links and impersonating profile owners',async()=>{
      for(const user of users){
        await expect('/links',{user,body:{coachID:otherCoach.id,clientID:otherClient.id}},410);
        if(user.id!==otherClient.id){
          await expect(`/clients/me?userID=${otherClient.id}`,{user,method:'GET'},403);
          await expect('/clients/me',{user,method:'PUT',body:{userID:otherClient.id,firstName:'Forged'}},403);
          await expect(`/upload/avatar?userID=${otherClient.id}`,{user,body:{}},403);
        }
        if(user.id!==otherCoach.id)await expect('/coaches/me/profile',{user,method:'PUT',body:{userID:otherCoach.id,bio:'Forged'}},403);
        if(user.id!==advisor.id)await expect('/advisors/me',{user,method:'PUT',body:{userID:advisor.id,specialty:'Forged'}},403);
      }
      for(const user of [client,coach,otherClient,otherCoach,advisor])await expect('/bans',{user,body:{userID:otherClient.id,bannedBy:manager.id,banType:'permanent',reason:'Forged'}},403);
      await expect('/bans',{user:manager,body:{userID:otherClient.id,bannedBy:admin.id,banType:'permanent',reason:'Forged'}},403);
      await expect(`/clients/${client.id}`,{user:coach,method:'GET'},200);
      await expect(`/clients/${client.id}`,{user:otherCoach,method:'GET'},403);
      await expect(`/clients/${client.id}`,{user:otherClient,method:'GET'},403);
      const [[n]]=await db.query('SELECT COUNT(*) AS n FROM coachclients WHERE coachID=? AND clientID=?',[otherCoach.id,otherClient.id]);assert.equal(n.n,0);
    });
    await t.test('invitation consent cannot be forged or accepted by another actor',async()=>{
      await expect('/invitations/send',{user:client,body:{senderID:otherClient.id,coachID:otherCoach.id}},403);
      const [insert]=await db.query("INSERT INTO invitations(coachID,invitedUserID,status,pointsEarned) VALUES(?,?,'pending',0)",[otherCoach.id,otherClient.id]);
      await expect(`/invitations/${insert.insertId}/accept`,{user:client,method:'PATCH',body:{}},403);
      await expect(`/invitations/${insert.insertId}/accept`,{user:coach,method:'PATCH',body:{}},404);
      await expect(`/invitations/${insert.insertId}/accept`,{user:otherCoach,method:'PATCH',body:{}},200);
      await expect(`/invitations/${insert.insertId}/accept`,{user:otherCoach,method:'PATCH',body:{}},404);
    });
    await t.test('legacy link reset endpoints are retired at actual auth mount',async()=>{
      await expect('/auth/forgot-password',{body:{email:client.email}},410);
      await expect('/auth/reset-password',{body:{token:'historically-disclosed',newPassword:'HackedPassword123'}},410);
      await expect('/auth/reset-password-otp',{body:{email:client.email,newPassword:'HackedPassword123'}},400);
    });
    await t.test('wrong, missing, expired and cross-account proof fail; concurrent reset has one winner',async()=>{
      const code=await challenge(client);
      await expect('/reset/verify-forgot-otp',{body:{email:client.email,otp:code==='100000'?'100001':'100000'}},400);
      const verified=await expect('/reset/verify-forgot-otp',{body:{email:client.email,otp:code}},200);
      await expect('/reset/verify-forgot-otp',{body:{email:client.email,otp:code}},400);
      await expect('/reset/reset-password-otp',{body:{email:client.email,otp:code,newPassword:'HackedPassword123'}},400);
      await expect('/reset/reset-password-otp',{body:{email:otherClient.email,resetToken:verified.resetToken,newPassword:'HackedPassword123'}},400);
      await expect('/reset/reset-password-otp',{body:{email:client.email,resetToken:'f'.repeat(64),newPassword:'HackedPassword123'}},400);
      await expect('/reset/reset-password-otp',{body:{email:client.email,resetToken:verified.resetToken,newPassword:'short'}},400);
      await db.query('UPDATE password_reset_challenges SET capabilityExpiresAt=DATE_SUB(NOW(),INTERVAL 1 SECOND) WHERE email=?',[client.email]);
      await expect('/reset/reset-password-otp',{body:{email:client.email,resetToken:verified.resetToken,newPassword:'HackedPassword123'}},400);
      await db.query('UPDATE password_reset_challenges SET capabilityExpiresAt=DATE_ADD(NOW(),INTERVAL 1 MINUTE) WHERE email=?',[client.email]);
      await db.query('INSERT INTO authtokens(userID,refreshToken,expiresAt) VALUES(?,?,DATE_ADD(NOW(),INTERVAL 1 DAY))',[client.id,`${prefix}-refresh`]);
      const attempts=await Promise.all([1,2].map(()=>call('/reset/reset-password-otp',{body:{email:client.email,resetToken:verified.resetToken,newPassword:'ChangedPassword123'}})));
      assert.deepEqual(attempts.map(r=>r.status).sort(),[200,400]);
      await expect('/reset/reset-password-otp',{body:{email:client.email,resetToken:verified.resetToken,newPassword:'HackedPassword123'}},400);
      await expect('/clients/me',{user:client,method:'GET'},401);
      const login=await expect('/auth/login',{body:{email:client.email,password:'ChangedPassword123'}},200);
      await expect('/clients/me',{token:login.accessToken,method:'GET'},200);
      await expect('/auth/refresh',{body:{refreshToken:`${prefix}-refresh`}},401);
    });
    await t.test('verification attempts, cooldown and OTP expiry are enforced',async()=>{
      const code=await challenge(coach);
      await expect('/reset/send-forgot-otp',{body:{email:coach.email}},200);
      assert.equal(deliveries.filter(d=>d.to===coach.email).length,1);
      for(let i=0;i<5;i++)await expect('/reset/verify-forgot-otp',{body:{email:coach.email,otp:code==='100000'?'100001':'100000'}},400);
      await expect('/reset/verify-forgot-otp',{body:{email:coach.email,otp:code}},400);
      const otherCode=await challenge(advisor);
      await db.query('UPDATE password_reset_challenges SET expiresAt=DATE_SUB(NOW(),INTERVAL 1 SECOND) WHERE email=?',[advisor.email]);
      await expect('/reset/verify-forgot-otp',{body:{email:advisor.email,otp:otherCode}},400);
      const existing=await expect('/reset/send-forgot-otp',{body:{email:otherCoach.email}},200);
      const unknown=await expect('/reset/send-forgot-otp',{body:{email:`${prefix}-missing@example.invalid`}},200);
      assert.deepEqual(existing,unknown);
    });
  } finally {
    if(server)await new Promise(resolve=>server.close(resolve));
    const [rows]=await db.query('SELECT id FROM users WHERE email LIKE ?',[`${prefix}%@example.invalid`]);
    for(const row of rows)await db.query('DELETE FROM users WHERE id=?',[row.id]);
    await db.end();
  }
});
