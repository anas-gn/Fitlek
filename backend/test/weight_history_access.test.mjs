import test from 'node:test';
import assert from 'node:assert/strict';
import express from 'express';
import {createWeightHistoryRouter} from '../services/weightHistoryRoutes.js';
test('goal weigh-ins are client-owned for reading, creating, editing and deleting',async t=>{
  const rows=[{id:1,clientID:7,weight:80},{id:2,clientID:8,weight:90}];
  const db={async query(sql,a){
    if(sql.startsWith('SELECT id, clientID'))return [rows.filter(row=>row.clientID===Number(a[0]))];
    if(sql.startsWith('INSERT INTO')){rows.push({id:3,clientID:a[0],weight:a[1]});return [{insertId:3}];}
    if(sql.startsWith('UPDATE')){const row=rows.find(row=>row.id===Number(a[2])&&row.clientID===Number(a[3]));if(row)row.weight=a[0];return [{affectedRows:row?1:0}];}
    if(sql.startsWith('DELETE')){const index=rows.findIndex(row=>row.id===Number(a[0])&&row.clientID===Number(a[1]));if(index>=0)rows.splice(index,1);return [{affectedRows:index>=0?1:0}];}
    throw Error('Unexpected query');
  }};
  const app=express();app.use(express.json());app.use((req,res,next)=>{if(req.headers['x-user'])req.user={id:Number(req.headers['x-user']),role:req.headers['x-role']??'client'};next();});app.use('/weights',createWeightHistoryRouter(db));
  const server=app.listen(0,'127.0.0.1');await new Promise(resolve=>server.once('listening',resolve));t.after(()=>server.close());
  const call=(path,method='GET',body,role='client',user='7')=>fetch(`http://127.0.0.1:${server.address().port}/weights${path}`,{method,headers:{'Content-Type':'application/json',...(user?{'x-user':user,'x-role':role}:{})},...(body?{body:JSON.stringify(body)}:{})});
  assert.equal((await call('/me?clientID=7','GET',null,'client','')).status,401);assert.equal((await call('/me?clientID=7','GET',null,'coach')).status,403);
  assert.equal((await call('/me?clientID=8')).status,403);assert.equal((await(await call('/me?clientID=7')).json()).length,1);
  assert.equal((await call('/','POST',{clientID:8,weight:50})).status,403);assert.equal((await call('/','POST',{clientID:7,weight:-1})).status,400);
  assert.equal((await call('/2','PUT',{weight:50})).status,404);assert.equal((await call('/2','DELETE')).status,404);assert.equal(rows.find(row=>row.id===2).weight,90);
  assert.equal((await call('/1','PUT',{weight:79})).status,200);assert.equal((await call('/1','DELETE')).status,200);
});
