import test from 'node:test';
import assert from 'node:assert/strict';
import {once} from 'node:events';
import {unlink} from 'node:fs/promises';
import path from 'node:path';
import express from 'express';
import jwt from 'jsonwebtoken';
import sharp from 'sharp';
import dotenv from 'dotenv';
dotenv.config({path:new URL('../.env',import.meta.url),quiet:true});

test('private chat attachments preserve uploads, participant reads and account revocation',
  {skip:process.env.APP_TEST_MYSQL!=='1'},async t=>{
  assert.ok(['localhost','127.0.0.1','::1'].includes(process.env.DB_HOST));
  assert.match(process.env.DB_NAME,/^sirvya_ci_\d+$/);
  const {default:db}=await import('../config/db.js');
  const {ensureAppCompatibilitySchema}=await import('../config/appCompatibilitySchema.js');
  const {requireAuth}=await import('../middleware/auth.js');
  const {default:upload}=await import('../routes/anas/upload.js');
  const {default:messages}=await import('../routes/anas/messages.js');
  const {createChatMediaRouter,signedChatMedia,chatFilename}=await import('../services/chatMedia.js');
  const prefix=`chat-audit-${Date.now()}-${process.pid}`,users=[],files=[],conversations=[];
  let server,origin,uploadURL,messageID;
  const previousOrigin=process.env.PUBLIC_API_ORIGIN;
  try{
    await ensureAppCompatibilitySchema(db);
    for(const role of ['coach','client','coach','client']){
      const [row]=await db.query("INSERT INTO users(firstName,lastName,email,passwordHash,role,gender) VALUES('Media','Audit',?,'no-login-fixture',?,'Other')",[`${prefix}-${users.length}@example.invalid`,role]);
      users.push({id:row.insertId,role,tokenVersion:0});
    }
    const [coach,client,otherCoach,otherClient]=users;
    for(const [a,b] of [[coach,client],[otherCoach,otherClient]]){
      const [row]=await db.query('INSERT INTO conversations(coachID,clientID) VALUES(?,?)',[a.id,b.id]);conversations.push(row.insertId);
    }
    const app=express();app.use(express.json());
    app.use('/uploads/chat_media',createChatMediaRouter(db,path.join(process.cwd(),'uploads','chat_media')));
    app.use('/uploads',express.static(path.join(process.cwd(),'uploads')));
    app.use('/api/upload',requireAuth,upload);app.use('/api/messages',requireAuth,messages);
    app.get('/api/check',requireAuth,(_req,res)=>res.json({authenticated:true}));
    server=app.listen(0,'127.0.0.1');await once(server,'listening');origin=`http://127.0.0.1:${server.address().port}`;
    process.env.PUBLIC_API_ORIGIN=origin;
    const auth=user=>({Authorization:`Bearer ${jwt.sign(user,process.env.JWT_SECRET,{expiresIn:'5m'})}`});
    const request=async(user,route,method='GET',body)=>fetch(origin+route,{method,headers:{...auth(user),'Content-Type':'application/json'},...(body===undefined?{}:{body:JSON.stringify(body)})});
    await t.test('image upload returns a private working preview and rejects its bare public URL',async()=>{
      const image=await sharp({create:{width:2,height:2,channels:3,background:'#ffffff'}}).png().toBuffer();
      const form=new FormData();form.set('image',new Blob([image],{type:'image/png'}),'fixture.png');
      const response=await fetch(origin+'/api/upload/chat-image',{method:'POST',headers:auth(client),body:form});
      assert.equal(response.status,200);uploadURL=(await response.json()).url;files.push(chatFilename(uploadURL));
      const signed=await fetch(uploadURL);assert.equal(signed.status,200);assert.match(signed.headers.get('Content-Type'),/image\/webp/);
      assert.equal(signed.headers.get('X-Content-Type-Options'),'nosniff');assert.match(signed.headers.get('Cache-Control'),/no-store/);
      assert.equal((await fetch(uploadURL.split('?')[0])).status,401);
    });
    await t.test('sending strips transient tickets and both conversation participants receive working media',async()=>{
      const response=await request(client,`/api/messages/${conversations[0]}`,'POST',{senderID:client.id,body:'Private image',mediaUrl:uploadURL,mediaType:'image'});
      assert.equal(response.status,201);messageID=(await response.json()).id;
      const [[saved]]=await db.query('SELECT mediaUrl FROM messages WHERE id=?',[messageID]);assert.ok(!saved.mediaUrl.includes('?'));
      for(const user of [client,coach]){
        const response=await request(user,`/api/messages/${conversations[0]}`);assert.equal(response.status,200);
        const media=(await response.json()).find(message=>message.id===messageID).mediaUrl;
        assert.equal((await fetch(media)).status,200);
      }
    });
    await t.test('a valid audio file keeps a private playable-range download',async()=>{
      const wav=Buffer.alloc(364);wav.write('RIFF',0);wav.writeUInt32LE(356,4);wav.write('WAVEfmt ',8);
      wav.writeUInt32LE(16,16);wav.writeUInt16LE(1,20);wav.writeUInt16LE(1,22);wav.writeUInt32LE(8000,24);
      wav.writeUInt32LE(16000,28);wav.writeUInt16LE(2,32);wav.writeUInt16LE(16,34);wav.write('data',36);wav.writeUInt32LE(320,40);
      const form=new FormData();form.set('audio',new Blob([wav],{type:'audio/wav'}),'fixture.wav');
      const response=await fetch(origin+'/api/upload/chat-audio',{method:'POST',headers:auth(coach),body:form});
      assert.equal(response.status,200);const url=(await response.json()).url;files.push(chatFilename(url));
      const audio=await fetch(url,{headers:{Range:'bytes=0-43'}});assert.equal(audio.status,206);
      assert.match(audio.headers.get('Content-Type'),/audio\/wav/);assert.equal((await audio.arrayBuffer()).byteLength,44);
    });
    await t.test('unrelated accounts cannot attach a guessed file or read it with a different capability',async()=>{
      const response=await request(otherClient,`/api/messages/${conversations[1]}`,'POST',{senderID:otherClient.id,body:'Guessed attachment',mediaUrl:uploadURL,mediaType:'image'});
      assert.equal(response.status,403);
      assert.equal((await request(otherClient,`/api/messages/${conversations[0]}`)).status,404);
      const wrongUser=signedChatMedia({user:otherClient},uploadURL);assert.equal((await fetch(wrongUser)).status,403);
      const ticket=new URL(uploadURL).searchParams.get('ticket');
      assert.equal((await fetch(origin+'/api/check',{headers:{Authorization:`Bearer ${ticket}`}})).status,401,'media capabilities cannot authenticate API calls');
    });
    await t.test('legacy attachments remain private and readable to their original participants',async()=>{
      await db.query('DELETE FROM chat_uploads WHERE filename=?',[files[0]]);
      const response=await request(coach,`/api/messages/${conversations[0]}`);
      const media=(await response.json())[0].mediaUrl;assert.equal((await fetch(media)).status,200);
    });
    await t.test('password/session revocation invalidates issued media capabilities',async()=>{
      await db.query('UPDATE users SET tokenVersion=tokenVersion+1 WHERE id=?',[client.id]);
      assert.equal((await fetch(uploadURL)).status,401);
    });
    await t.test('audio uploads reject executable filename extensions without storing a file',async()=>{
      const form=new FormData();form.set('audio',new Blob(['<script>bad()</script>'],{type:'audio/mp4'}),'payload.html');
      const response=await fetch(origin+'/api/upload/chat-audio',{method:'POST',headers:auth(coach),body:form});
      assert.equal(response.status,400);
    });
  }finally{
    if(server)await new Promise(resolve=>server.close(resolve));
    for(const id of conversations){await db.query('DELETE FROM messages WHERE conversationID=?',[id]);await db.query('DELETE FROM conversations WHERE id=?',[id]);}
    for(const user of users)await db.query('DELETE FROM users WHERE id=?',[user.id]);
    for(const file of files)await unlink(path.join(process.cwd(),'uploads','chat_media',file)).catch(()=>{});
    if(previousOrigin===undefined)delete process.env.PUBLIC_API_ORIGIN;else process.env.PUBLIC_API_ORIGIN=previousOrigin;
    await db.end();
  }
});
