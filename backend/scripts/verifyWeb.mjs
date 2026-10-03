// Local browser verification in an isolated Chrome context, with disposable
// accounts in SIRVYA's existing database. Never reuse a person's login token.
import fs from 'node:fs';
import path from 'node:path';
import { once } from 'node:events';
import {randomBytes} from 'node:crypto';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import assert from 'node:assert/strict';
import db from '../config/db.js';

const root = path.resolve('..');
const stateFile = path.join(root, '.git', 'sirvya-browser-verification.json');
const mode = process.argv[2] || 'inspect';
const args = process.argv.slice(3);
if (!['localhost','127.0.0.1','::1'].includes(process.env.DB_HOST)) throw new Error('Browser fixtures require local MySQL');
const debugPort = Number(process.env.WEB_DEBUG_PORT || 64423);
if(mode==='verify'){
  try{
    const fixture=JSON.parse(fs.readFileSync(stateFile,'utf8'));
    const client=fixture.users.find(u=>u.role==='client'),coach=fixture.users.find(u=>u.role==='coach');
    const [[plan]]=await db.query("SELECT * FROM workout_plans WHERE clientID=? AND coachID=? AND name='QA strength plan'",[client.id,coach.id]);
    assert.equal(plan.status,'assigned');
    const [[session]]=await db.query("SELECT * FROM workout_sessions WHERE workoutPlanID=? AND clientID=? AND status='completed' ORDER BY id DESC LIMIT 1",[plan.id,client.id]);
    const [sets]=await db.query('SELECT * FROM workout_sets WHERE workoutSessionID=? ORDER BY workoutExerciseID',[session.id]);
    const prescription=typeof session.prescription==='string'?JSON.parse(session.prescription):session.prescription;
    const bench=prescription.exercises.find(e=>e.name==='barbell bench press');
    const actual=sets.find(s=>Number(s.workoutExerciseID)===Number(bench.id));
    assert.equal(Number(bench.targetWeight),60);assert.equal(bench.targetReps,10);
    assert.equal(Number(actual.weight),57.5);assert.equal(actual.reps,9);assert.equal(sets.length,3);
    const timed=prescription.exercises.find(e=>e.exerciseType==='timed');
    assert.ok(sets.find(s=>Number(s.workoutExerciseID)===Number(timed.id)).durationSeconds>0);
    const login=await fetch('http://localhost:3000/api/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:client.email,password:fixture.password})});
    assert.equal(login.status,200);const auth=await login.json();
    const statsResponse=await fetch('http://localhost:3000/api/workout/stats?days=90',{headers:{Authorization:`Bearer ${auth.accessToken}`}});
    assert.equal(statsResponse.status,200);const stats=await statsResponse.json();
    assert.equal(stats.workoutCount,1);assert.equal(stats.setCount,3);assert.equal(Number(stats.volume),517.5);assert.equal(stats.currentWeeklyStreak,1);
    const denied=await fetch('http://localhost:3000/api/workout/stats');assert.equal(denied.status,401);
    const proof={workflow:'native Coach builder -> assignment -> Client sets -> recovery -> completion -> Coach review',authentication:'real SIRVYA password login API and restored session; login form not exercised',prescribed:{weight:60,reps:10},performed:{weight:57.5,reps:9},savedSets:sets.length,volumeKg:57.5*9,timedActualSeconds:sets.find(s=>Number(s.workoutExerciseID)===Number(timed.id)).durationSeconds,verifiedAt:new Date().toISOString()};
    proof.statistics={workouts:stats.workoutCount,sets:stats.setCount,volumeKg:stats.volume,weeklyStreak:stats.currentWeeklyStreak};proof.unauthenticatedStatus=denied.status;
    fs.writeFileSync(path.join(root,'docs/verification/workout-browser-audit.json'),JSON.stringify(proof,null,2)+'\n');
    console.log(JSON.stringify(proof,null,2));
  }finally{await db.end();}
  process.exit(0);
}
// Disposal must also work when the verification browser is no longer running.
if(mode==='cleanup'){
  if(fs.existsSync(stateFile)){
    const fixture=JSON.parse(fs.readFileSync(stateFile,'utf8'));
    if(!/^web-verification-\d+$/.test(fixture.prefix))throw new Error('Invalid fixture prefix');
    let removed=0;
    for(const user of fixture.users??[]){
      const [result]=await db.query('DELETE FROM users WHERE id=? AND email LIKE ?',[user.id,`${fixture.prefix}-%@example.invalid`]);removed+=result.affectedRows;
    }
    fs.unlinkSync(stateFile);console.log(`Cleaned ${removed} owned verification accounts.`);
  }
  await db.end();process.exit(0);
}
const version = await (await fetch(`http://localhost:${debugPort}/json/version`)).json();
const socket = new WebSocket(version.webSocketDebuggerUrl);
await once(socket, 'open');
let sequence = 0;
const pending = new Map();
const apiResponses = [];
const browserErrors = [];
socket.addEventListener('message', event => {
  const message = JSON.parse(event.data);
  if (message.id) {
    const task = pending.get(message.id); if (!task) return;
    pending.delete(message.id); clearTimeout(task.timeout);
    message.error ? task.reject(new Error(message.error.message)) : task.resolve(message.result);
  } else if (message.method === 'Runtime.exceptionThrown') {
    browserErrors.push(message.params.exceptionDetails.text);
  } else if (message.method === 'Runtime.consoleAPICalled') {
    const line=message.params.args.map(a=>a.value).filter(v=>typeof v==='string').join(' ');
    if(/FATAL|Failed to initialize|Error|error/.test(line)) browserErrors.push(line.slice(0,500));
  } else if (message.method === 'Network.responseReceived' && message.params.response.url.startsWith('http://localhost:3000/api')) {
    const response = message.params.response; apiResponses.push({path: new URL(response.url).pathname,status:response.status});
  }
});
const call = (method, params={}, sessionId) => new Promise((resolve,reject)=> {
  const id=++sequence;
  const timeout=setTimeout(()=>{pending.delete(id);reject(new Error('CDP timeout: '+method));},20000);
  pending.set(id,{resolve,reject,timeout}); socket.send(JSON.stringify({id,method,params,...(sessionId?{sessionId}:{})}));
});
const delay = ms => new Promise(resolve=>setTimeout(resolve,ms));
let state;
try {
  if (mode === 'setup') {
    if (fs.existsSync(stateFile)) throw new Error('Existing verification fixtures must be cleaned first');
    state = {prefix:`web-verification-${Date.now()}`,password:randomBytes(24).toString('base64url'),users:[]};
    fs.writeFileSync(stateFile,JSON.stringify(state));
    const hash = await bcrypt.hash(state.password,10);
    for (const role of ['client','coach']) {
      const email = `${state.prefix}-${role}@example.invalid`;
      const [result] = await db.query("INSERT INTO users (firstName,lastName,email,passwordHash,role,gender,isApproved) VALUES ('Verification',?,?,?,?,'Other',1)",[role,email,hash,role]);
      state.users.push({id:result.insertId,role,email}); fs.writeFileSync(stateFile,JSON.stringify(state));
      if (role==='coach') await db.query("INSERT INTO coachprofiles (userID,bio,invitationCode) VALUES (?,'Browser verification fixture',?)",[result.insertId,state.prefix]);
    }
    const [client,coach]=state.users;
    await db.query('INSERT INTO coachclients (coachID,clientID) VALUES (?,?)',[coach.id,client.id]);
    const [[exercise]]=await db.query("SELECT id FROM exercises WHERE name='Bench Press' LIMIT 1");
    const token=jwt.sign({id:coach.id,role:coach.role},process.env.JWT_SECRET,{expiresIn:'30m'});
    const response=await fetch('http://localhost:3000/api/workout/plans',{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({clientID:client.id,name:'Browser verification plan',status:'assigned',days:[{name:'Verification day',exercises:[{exerciseID:exercise.id,targetSets:1,targetReps:10,targetWeight:20,restSeconds:15}]}]})});
    if(response.status!==201)throw new Error('Fixture plan creation failed: '+response.status);
    const context=await call('Target.createBrowserContext'); state.contextId=context.browserContextId;
    await call('Browser.setPermission',{permission:{name:'notifications'},setting:'denied',browserContextId:state.contextId});
    state.targetId=(await call('Target.createTarget',{url:'about:blank',browserContextId:state.contextId})).targetId;
    fs.writeFileSync(stateFile,JSON.stringify(state));
  } else state=JSON.parse(fs.readFileSync(stateFile,'utf8'));
  if(mode==='cleanup') {
    if(state.contextId)await call('Target.disposeBrowserContext',{browserContextId:state.contextId});
    const [fixtures]=await db.query('SELECT id FROM users WHERE email LIKE ?',[`${state.prefix}%@example.invalid`]);
    for(const fixture of fixtures)await db.query('DELETE FROM users WHERE id=?',[fixture.id]);
    fs.unlinkSync(stateFile); console.log('Verification browser context and fixture accounts cleaned.');
  } else {
    const {sessionId}=await call('Target.attachToTarget',{targetId:state.targetId,flatten:true});
    const send=(method,params={})=>call(method,params,sessionId);
    // Emulation belongs to the CDP session and is lost on detach. Restore it
    // for every invocation so follow-up actions keep the same phone viewport.
    const viewport=state.viewport??{width:396,height:844};
    await send('Emulation.setDeviceMetricsOverride',{...viewport,deviceScaleFactor:1,mobile:viewport.width<600});
    const evaluate=async expression=>{
      const result=await send('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});
      if(result.exceptionDetails)throw new Error(result.exceptionDetails.exception?.description||'Browser evaluation failed');
      return result.result.value;
    };
    await send('Page.enable'); await send('Network.enable'); await send('Runtime.enable');
    if(mode==='diagnose') console.log(JSON.stringify(await evaluate(`({url:location.href,ready:document.readyState,tags:[...document.body.children].map(e=>e.tagName),text:document.body.innerText.slice(0,500)})`)));
    if(mode==='setup') {
      await send('Emulation.setDeviceMetricsOverride',{width:396,height:844,deviceScaleFactor:1,mobile:true});
      await send('Page.navigate',{url:'http://localhost:8080'}); await delay(10000);
    }
    if(mode==='reload'){await send('Page.reload',{ignoreCache:true});await delay(7000);}
    await evaluate("document.querySelector('flt-semantics-placeholder')?.click()"); await delay(500);
    if(mode==='tap'||mode==='fill'||mode==='fill-at') {
      const coords=mode==='fill-at'?{x:Number(args[0]),y:Number(args[1])}:await evaluate(`(()=>{const wanted=${JSON.stringify(args[0])};const elements=[...document.querySelectorAll('flt-semantics,[role],input,textarea')];const candidates=elements.filter(e=>((e.getAttribute('aria-label')||e.innerText||'').trim()===wanted)&&e.getBoundingClientRect().width>0);candidates.sort((a,b)=>{const x=a.getBoundingClientRect(),y=b.getBoundingClientRect();return x.width*x.height-y.width*y.height});const e=candidates[0];if(!e)throw Error('Control not found: '+wanted);const r=e.getBoundingClientRect();return {x:r.x+r.width/2,y:r.y+r.height/2};})()`);
      await send('Input.dispatchMouseEvent',{type:'mousePressed',button:'left',clickCount:1,...coords});
      await send('Input.dispatchMouseEvent',{type:'mouseReleased',button:'left',clickCount:1,...coords});
      if(mode==='fill'||mode==='fill-at'){
        await send('Input.dispatchKeyEvent',{type:'keyDown',modifiers:2,key:'Control',code:'ControlLeft',windowsVirtualKeyCode:17});
        await send('Input.dispatchKeyEvent',{type:'keyDown',modifiers:2,key:'a',code:'KeyA',windowsVirtualKeyCode:65});
        await send('Input.dispatchKeyEvent',{type:'keyUp',modifiers:2,key:'a',code:'KeyA',windowsVirtualKeyCode:65});
        await send('Input.dispatchKeyEvent',{type:'keyUp',key:'Control',code:'ControlLeft',windowsVirtualKeyCode:17});
        await evaluate("document.activeElement?.select?.()");
        await send('Input.insertText',{text:mode==='fill-at'?args[2]:args[1]});
      }
      await delay(1500);
    }
    if(mode==='click') {
      const x=Number(args[0]),y=Number(args[1]);
      await send('Input.dispatchMouseEvent',{type:'mousePressed',button:'left',clickCount:1,x,y});
      await send('Input.dispatchMouseEvent',{type:'mouseReleased',button:'left',clickCount:1,x,y});await delay(1500);
    }
    if(mode==='type') {await send('Input.insertText',{text:args[0]});await delay(500);}
    if(mode==='login') {
      const user=state.users.find(u=>u.role===args[0]);
      // API authentication + SIRVYA's own stored session, useful for validating
      // restored sessions independently of the login form control test.
      const login=await fetch('http://localhost:3000/api/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:user.email,password:state.password})});
      if(login.status!==200)throw new Error('Fixture login failed');
      const result=await login.json();
      await evaluate(`(()=>{localStorage.setItem('flutter.token',JSON.stringify(${JSON.stringify(result.accessToken)}));localStorage.setItem('flutter.role',JSON.stringify(${JSON.stringify(user.role)}));localStorage.setItem('flutter.userId',JSON.stringify(${user.id}));localStorage.setItem('flutter.firstName',JSON.stringify('Verification'));})()`);
      await send('Page.reload',{ignoreCache:true});await delay(7000);
      await evaluate("document.querySelector('flt-semantics-placeholder')?.click()");await delay(1000);
    }
    if(mode==='scroll') {await send('Input.dispatchMouseEvent',{type:'mouseWheel',x:200,y:400,deltaY:Number(args[0]),deltaX:0});await delay(1000);}
    if(mode==='resize') {state.viewport={width:Number(args[0]),height:Number(args[1])};fs.writeFileSync(stateFile,JSON.stringify(state));await send('Emulation.setDeviceMetricsOverride',{...state.viewport,deviceScaleFactor:1,mobile:state.viewport.width<600});await delay(1000);}
    if(mode==='capture') {
      const directory=path.join(root,'docs','verification');fs.mkdirSync(directory,{recursive:true});
      const screenshot=await send('Page.captureScreenshot',{format:'png'});
      const file=path.join(directory,path.basename(args[0])+'.png');fs.writeFileSync(file,Buffer.from(screenshot.data,'base64'));console.log('Screenshot saved:',file);
    }
    const snapshot=await evaluate(`(()=>[...document.querySelectorAll('flt-semantics,input,textarea')].map(e=>{const r=e.getBoundingClientRect();return {tag:e.tagName,role:e.getAttribute('role'),label:e.getAttribute('aria-label'),text:(e.innerText||'').slice(0,150),x:Math.round(r.x),y:Math.round(r.y),w:Math.round(r.width),h:Math.round(r.height)}}).filter(e=>e.w>0&&e.h>0&&(e.label||e.text||e.tag==='INPUT'||e.tag==='TEXTAREA')).slice(-100))()`);
    console.log(JSON.stringify({mode,controls:snapshot,apiResponses,browserErrors},null,2));
  }
} finally {socket.close();await db.end();}
