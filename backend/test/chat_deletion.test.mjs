import test from 'node:test';
import assert from 'node:assert/strict';
import {deleteChatMessages,validateDeletionRows} from '../services/chatDeletion.js';
test('everyone rejects received, expired, missing and already deleted messages',()=>{
 for(const row of [{id:1,senderID:3,canDelete:1},{id:1,senderID:2,canDelete:0},{id:1,senderID:2,canDelete:1,deletedAt:'now'}]) {
  assert.throws(()=>validateDeletionRows([row],[1],2,'everyone'),e=>e.status===409);
 }
 assert.throws(()=>validateDeletionRows([],[1],2,'me'),e=>e.status===404);
});
test('me accepts old or received messages; everyone accepts fresh own messages',()=>{
 assert.doesNotThrow(()=>validateDeletionRows([{id:1,senderID:3,canDelete:0}],[1],2,'me'));
 assert.doesNotThrow(()=>validateDeletionRows([{id:1,senderID:2,canDelete:1}],[1],2,'everyone'));
});
function pool(rows,member=true) {
 const calls=[];const conn={beginTransaction:async()=>calls.push('begin'),commit:async()=>calls.push('commit'),rollback:async()=>calls.push('rollback'),release:()=>calls.push('release'),query:async(sql,args)=>{
  calls.push({sql,args});
  if(sql.startsWith('SELECT id,coachID'))return [[member?{id:10,coachID:2,clientID:3}:undefined]];
  if(sql.startsWith('SELECT id,senderID'))return [rows];
  return [{}];
 }};return {calls,getConnection:async()=>conn};
}
test('bulk everyone is atomic and uses database time and authenticated ownership',async()=>{
 const db=pool([{id:1,senderID:2,canDelete:1},{id:2,senderID:2,canDelete:0}]);
 await assert.rejects(deleteChatMessages(db,2,10,[1,2],'everyone'));
 assert.ok(db.calls.includes('rollback'));assert.ok(!db.calls.includes('commit'));
 assert.ok(!db.calls.some(c=>c.sql?.startsWith('UPDATE')));
 const select=db.calls.find(c=>c.sql?.startsWith('SELECT id,senderID'));
 assert.match(select.sql,/createdAt>DATE_SUB\(NOW\(\),INTERVAL 30 MINUTE\)/);
});
test('everyone clears content to tombstone; me only hides for authenticated user',async()=>{
 const db=pool([{id:1,senderID:2,canDelete:1}]);await deleteChatMessages(db,2,10,[1],'everyone');
 assert.match(db.calls.find(c=>c.sql?.startsWith('UPDATE')).sql,/body='This message was deleted'/);
 const me=pool([{id:1,senderID:3,canDelete:0}]);await deleteChatMessages(me,2,10,[1],'me');
 assert.deepEqual(me.calls.find(c=>c.sql?.startsWith('INSERT')).args,[[[1,2]]]);
 assert.ok(!me.calls.some(c=>c.sql?.startsWith('UPDATE')));
});
test('unrelated account cannot delete any message',async()=>{
 const db=pool([],false);await assert.rejects(deleteChatMessages(db,8,10,[1],'me'),e=>e.status===403);
 assert.deepEqual(db.calls[1].args,[10,8,8]);assert.ok(db.calls.includes('rollback'));
});
