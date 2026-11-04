import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,writeFile,access,rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {acknowledgeMedia,cleanupDeliveredMedia,chatMediaPath} from '../services/chatMediaDelivery.js';
async function fixture(fn){const root=await mkdtemp(path.join(tmpdir(),'sirvya-media-test-'));try {await fn(root);}finally{await rm(root,{recursive:true,force:true});}}
function connection(message){const calls=[];return {calls,beginTransaction:async()=>{},commit:async()=>calls.push('commit'),rollback:async()=>calls.push('rollback'),release:()=>{},query:async(sql,params)=>{calls.push({sql,params});return sql.includes('FOR UPDATE')?[[message].filter(Boolean)]:[{}];}};}
test('unrelated account cannot acknowledge or access a file',async()=>{
 const conn=connection(null);await assert.rejects(acknowledgeMedia({getConnection:async()=>conn},99,1,'hash'),e=>e.status===404);
 assert.equal(conn.calls.filter(c=>c.sql?.includes('INSERT')).length,0);
 assert.deepEqual(conn.calls[0].params,[1,99,99]);
});
test('ack requires exact saved bytes and never deletes media by itself',async()=>fixture(async(root)=>{
 await writeFile(path.join(root,'a.jpg'),'payload');
 const message={mediaType:'image',mediaExpired:0,mediaUrl:'https://server/uploads/chat_media/a.jpg'};
 const bad=connection(message);await assert.rejects(acknowledgeMedia({getConnection:async()=>bad},12,1,'0'.repeat(64),{root}),e=>e.status===400);
 assert.equal(bad.calls.filter(c=>c.sql?.includes('INSERT')).length,0);
 const good=connection(message);await acknowledgeMedia({getConnection:async()=>good},12,1,createHash('sha256').update('payload').digest('hex'),{root});
 assert.deepEqual(good.calls.find(c=>c.sql?.includes('INSERT')).params,[1,12]);await access(path.join(root,'a.jpg'));
}));
test('cleanup requires both participant receipts and preserves text history',async()=>fixture(async(root)=>{
 await writeFile(path.join(root,'a.jpg'),'payload');const queries=[];
 const db={query:async(sql,params)=>{queries.push({sql,params});if(sql.includes('SELECT m.id'))return [[{id:1,mediaUrl:'https://server/uploads/chat_media/a.jpg'}]];if(sql.includes('COUNT'))return [[{total:0}]];return [{}];}};
 assert.equal(await cleanupDeliveredMedia(db,{root}),1);await assert.rejects(access(path.join(root,'a.jpg')));
 assert.match(queries[0].sql,/r.userID=c.coachID/);assert.match(queries[0].sql,/r.userID=c.clientID/);
 assert.equal(queries.at(-1).sql,'UPDATE messages SET mediaExpired=1 WHERE id=?');
}));
test('cleanup retains files referenced by another unprocessed message',async()=>fixture(async(root)=>{
 await writeFile(path.join(root,'a.jpg'),'payload');
 const db={query:async(sql)=>sql.includes('SELECT m.id')?[[{id:1,mediaUrl:'https://server/uploads/chat_media/a.jpg'}]]:[[{total:1}]]};
 assert.equal(await cleanupDeliveredMedia(db,{root}),0);await access(path.join(root,'a.jpg'));
}));
test('cleanup rejects paths outside chat uploads',()=>{
 for(const url of ['https://server/uploads/avatar.png','https://server/uploads/chat_media/%2E%2E','https://server/uploads/chat_media/%2E%2E%2Fsecret'])assert.throws(()=>chatMediaPath(url));
});
