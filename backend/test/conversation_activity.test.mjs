import test from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import jwt from 'jsonwebtoken';
import {initSocket} from '../config/socket.js';
import {emitMessage} from '../services/realtime.js';

const sleep = ms => new Promise(resolve => setTimeout(resolve,ms));
async function until(predicate) {
  const end=Date.now()+1500;
  while(Date.now()<end) { const value=predicate(); if(value) return value; await sleep(5); }
  throw new Error('Timed out waiting for websocket event');
}
test('authenticated live messages and ephemeral typing/audio are private, expire and clear on disconnect', async t => {
  process.env.JWT_SECRET='local-realtime-test-secret';
  const db={query:async (_,args)=>[[[7,9].includes(Number(args[1])) && String(args[0])==='1' ? {id:1}:null]]};
  const server=http.createServer();
  const io=initSocket(server,db,{ttlMs:250});
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  const peers=[];
  t.after(async()=>{for(const p of peers) p.ws.close(); await new Promise(resolve=>io.close(resolve));});
  async function peer(id,role='client') {
    const events=[],acks=new Map(); let sequence=0;
    const token=jwt.sign({id,role},process.env.JWT_SECRET,{expiresIn:'5m'});
    const ws=new WebSocket(`ws://127.0.0.1:${server.address().port}/socket.io/?EIO=4&transport=websocket`);
    const ready=new Promise((resolve,reject)=> {
      ws.addEventListener('error',reject,{once:true});
      ws.addEventListener('message',event=>{
        const packet=String(event.data);
        if(packet.startsWith('0')) ws.send('40'+JSON.stringify({token}));
        else if(packet==='2') ws.send('3');
        else if(packet.startsWith('40')) resolve();
        else if(packet.startsWith('44')) { ws.close(); reject(new Error('Unauthorized')); }
        else if(packet.startsWith('42')) { const [type,data]=JSON.parse(packet.slice(2)); events.push({type,...data}); }
        else if(packet.startsWith('43')) {
          const match=packet.match(/^43(\d+)(.*)$/);
          acks.get(Number(match[1]))?.(JSON.parse(match[2])[0]);
        }
      });
    });
    const result={ws,events,send:(type,data)=>ws.send('42'+JSON.stringify([type,data])),
      join:room=>new Promise(resolve=>{const n=++sequence;acks.set(n,resolve);ws.send('42'+n+JSON.stringify(['join_room',{conversationId:room}]));})};
    peers.push(result); await ready; return result;
  }
  const client=await peer(7),coach=await peer(9,'coach'),outsider=await peer(11);
  assert.equal((await client.join('1')).ok,true);
  assert.equal((await coach.join('1')).ok,true);
  assert.equal((await outsider.join('1')).ok,false);
  await assert.rejects(peer(12,'manager'),/Unauthorized/);
  outsider.send('conversation_activity',{conversationID:1,activity:'typing',userID:9});
  await sleep(25); assert.equal(client.events.length,0);
  coach.send('conversation_activity',{conversationID:1,activity:'typing',userID:11,body:'must never appear'});
  const typing=await until(()=>client.events.find(e=>e.activity==='typing'));
  assert.equal(typing.userID,9); assert.equal(typing.conversationID,1);
  assert.equal(typing.body,undefined); assert.equal(outsider.events.length,0);
  coach.send('conversation_activity',{conversationID:1,activity:'typing'});
  await sleep(20); assert.equal(client.events.filter(e=>e.activity==='typing').length,1);
  coach.send('conversation_activity',{conversationID:1,activity:'recording'});
  await until(()=>client.events.find(e=>e.activity==='recording'));
  await until(()=>client.events.find(e=>e.activity==='idle'));

  client.events.length=0;
  const secondDevice=await peer(9,'coach'); await secondDevice.join('1');
  coach.send('conversation_activity',{conversationID:1,activity:'recording'});
  await until(()=>client.events.find(e=>e.activity==='recording'));
  secondDevice.send('conversation_activity',{conversationID:1,activity:'typing'});
  await sleep(10); client.events.length=0; coach.ws.close();
  await until(()=>client.events.find(e=>e.activity==='typing'));
  secondDevice.send('leave_room',{conversationId:'1'});
  await until(()=>client.events.find(e=>e.activity==='idle'));
  emitMessage({id:99,conversationID:1,senderID:9,body:'A live message'}, {coachID:9,clientID:7});
  assert.equal((await until(()=>client.events.find(e=>e.type==='new_message'))).body,'A live message');
  assert.equal(outsider.events.length,0);
});
