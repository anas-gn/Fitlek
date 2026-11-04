import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import express from 'express';

test('booking succeeds on NOT NULL price schema and coach offer still requires client acceptance', async()=>{
  const sourceUrl=new URL('../routes/anas/reservations.js',import.meta.url);
  let source=await fs.readFile(sourceUrl,'utf8');
  const row={id:1,clientID:8,coachID:7,status:'pending',quoteVersion:0,deadlinePassed:0};
  let selectedPackage=null;const notices=[];
  const query=async(sql,args=[])=>{
    if(sql.includes(' AS canBook'))return [[{canBook:1}]];
    if(sql.includes(' AS tooLate'))return [[{tooLate:0}]];
    if(sql.includes('SELECT *,TIMESTAMP'))return [[{...row}]];
    if(sql.startsWith('SELECT * FROM reservations WHERE id=?'))return [[{...row}]];
    if(sql.includes('SELECT id FROM users'))return [[{id:7}]];
    if(sql.includes('SELECT gymName'))return [[{}]];
    if(sql.includes('FROM coach_packages'))return [[selectedPackage].filter(Boolean)];
    if(sql.includes('SELECT firstName'))return [[{firstName:'Test',lastName:'Client'}]];
    if(sql.includes('INSERT INTO reservations')){
      assert.notEqual(args[8],null,"Column 'price' cannot be null");
      row.price=args[8];row.pricingStatus=args[9];row.status='pending';return [{insertId:1}];
    }
    if(sql.includes("SET pricingStatus='proposed'")){row.pricingStatus='proposed';row.proposedPrice=args[0];row.quoteVersion++;}
    if(sql.includes("SET price=proposedPrice")){row.price=row.proposedPrice;row.pricingStatus='accepted';row.status='confirmed';}
    return sql.trim().startsWith('SELECT')?[[]]:[{affectedRows:1}];
  };
  const tx={query,beginTransaction:async()=>{},commit:async()=>{},rollback:async()=>{},release:()=>{}};
  globalThis.bookingPriceTestDb={query,getConnection:async()=>tx};
  globalThis.bookingPriceTestNotify=async(n)=>notices.push(n);
  source=source.replace("import db from '../../config/db.js';",'const db=globalThis.bookingPriceTestDb;')
    .replace("import { createAndSendNotification } from '../../services/pushNotificationService.js';",'const createAndSendNotification=globalThis.bookingPriceTestNotify;')
    .replace(/from '([^']+)'/g,(match,path)=>`from '${path==='express'?new URL('../node_modules/express/index.js',import.meta.url).href:new URL(path,sourceUrl).href}'`);
  const {default:router}=await import('data:text/javascript;base64,'+Buffer.from(source).toString('base64'));
  const app=express();app.use(express.json());app.use((req,res,next)=>{req.user={id:Number(req.get('actor')||8),role:req.get('role')||'client'};next()});app.use(router);
  const server=app.listen(0,'127.0.0.1');await new Promise(r=>server.once('listening',r));
  const base=`http://127.0.0.1:${server.address().port}`;
  const call=(path,body,method='POST',actor=8,role='client')=>fetch(base+path,{method,headers:{'content-type':'application/json',actor:String(actor),role},body:JSON.stringify(body)});
  const booking={clientID:8,coachID:7,reservedDate:'2099-01-01',reservedTime:'20:00',location:'defined'};
  try{
    for(const price of [undefined,null,0]){
      const response=await call('/',{...booking,price});assert.equal(response.status,201,await response.clone().text());
      const result=await response.json();assert.equal(result.price,null);assert.equal(result.pricingStatus,'awaiting');assert.equal(row.price,0);assert.equal(row.pricingStatus,'awaiting');
    }
    assert.equal((await call('/1/confirm',{},'PATCH',7,'coach')).status,400);
    assert.equal((await call('/1/price',{price:250},'PATCH',7,'coach')).status,200);
    assert.equal(row.status,'pending');assert.equal(row.price,0);assert.equal(row.pricingStatus,'proposed');
    assert.equal((await call('/1/price/accept',{quoteVersion:row.quoteVersion},'PATCH')).status,200);
    assert.equal(row.price,250);assert.equal(row.status,'confirmed');assert.equal(row.pricingStatus,'accepted');
    selectedPackage={id:2,name:'Custom sessions',price:0,sessions:1,isPriceOnRequest:1};
    assert.equal((await call('/',{...booking,packageID:2})).status,201);assert.equal(row.pricingStatus,'awaiting');
    selectedPackage={...selectedPackage,price:300,isPriceOnRequest:0};
    assert.equal((await call('/',{...booking,packageID:2})).status,201);assert.equal(row.price,300);assert.equal(row.pricingStatus,'fixed');
    assert.ok(notices.some(n=>n.type==='price_proposed'));assert.ok(notices.some(n=>n.type==='price_accepted'));
  }finally{await new Promise(r=>server.close(r));delete globalThis.bookingPriceTestDb;delete globalThis.bookingPriceTestNotify;}
});
