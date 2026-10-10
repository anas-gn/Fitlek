// Full built Flutter UI -> actual HTTP routes -> disposable local MySQL.
// Run with the explicit provider-fixture preload; no external delivery is tested.
import express from 'express';
import cors from 'cors';
import assert from 'node:assert/strict';
import bcrypt from 'bcrypt';
import {once} from 'node:events';
import {mkdir,writeFile,readFile,readdir} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import db from '../config/db.js';
import {ensureGoogleAuthSchema} from '../config/googleAuthSchema.js';
import {ensureAppCompatibilitySchema} from '../config/appCompatibilitySchema.js';
import {ensureWorkoutSchema} from '../config/workoutSchema.js';
import {createWorkoutRouter} from '../routes/anas/workout.js';
import {requireAuth} from '../middleware/auth.js';
import {createAndSendNotification} from '../services/pushNotificationService.js';

if(!['localhost','127.0.0.1','::1'].includes(process.env.DB_HOST)||!/^sirvya_ci_\d+$/.test(process.env.DB_NAME??''))throw new Error('Journey requires a disposable local CI schema');
const root=fileURLToPath(new URL('../../',import.meta.url));
const prefix=`journey-${Date.now()}-${process.pid}`,users=[],checks=[],apiErrors=[],exceptions=[];
const api=express();api.use(cors({origin:'http://localhost:8082'}));api.use(express.json({limit:'10mb'}));
const web=express();web.use(express.static(path.join(root,'build','web')));
let apiServer,webServer,socket,contextId,send,browserCall,currentSession,fileInput,stage='setup';
const reportFile=path.join(root,'docs','verification','workout-live-journey.json');
const shots=path.join(root,'docs','verification','journey');
const files=path.join(root,'workout_tmp',prefix);
const record=(name)=>{checks.push(name);console.log(`Passed: ${name}`);};
const pause=ms=>new Promise(resolve=>setTimeout(resolve,ms));
let evaluate;
const clickPoint=async(x,y)=>{
  await send('Input.dispatchMouseEvent',{type:'mousePressed',x,y,button:'left',clickCount:1});
  await send('Input.dispatchMouseEvent',{type:'mouseReleased',x,y,button:'left',clickCount:1});
};
const labels=()=>evaluate(`[document.body.innerText,...[...document.querySelectorAll('[aria-label],[role=button]')].map(e=>e.getAttribute('aria-label')||e.innerText)].filter(Boolean)`);
const waitFor=async(fn,name,seconds=30)=>{
  for(let i=0;i<seconds;i++){if(await fn())return;await pause(1000);}
  throw new Error(`Timeout: ${name}`);
};
const click=async(label,contains=false)=>{
  let point;
  for(let attempt=0;attempt<6;attempt++){
    point=await evaluate(`(()=>{const label=${JSON.stringify(label)};const matches=[...document.querySelectorAll('[aria-label],[role=button],button')].filter(e=>{const text=(e.getAttribute('aria-label')||e.innerText||'').replace(/\\s+/g,' ').trim();return ${contains?'text.includes(label)':'text===label'};}).map(e=>{const r=e.getBoundingClientRect();return {x:r.x+r.width/2,y:r.y+r.height/2,w:r.width,h:r.height};}).filter(r=>r.w>0&&r.h>0&&r.y>0&&r.y<844);return matches.sort((a,b)=>a.w*a.h-b.w*b.h)[0]??null;})()`);
    if(point)break;
    await send('Input.dispatchMouseEvent',{type:'mouseWheel',x:198,y:600,deltaX:0,deltaY:300});await pause(400);
  }
  if(!point)throw new Error(`Cannot click ${label}; labels: ${JSON.stringify(await labels())}`);
  await clickPoint(point.x,point.y);await pause(800);
};
const capture=async name=>{const shot=await send('Page.captureScreenshot',{format:'png'});await writeFile(path.join(shots,name+'.png'),Buffer.from(shot.data,'base64'));};
try{
  await mkdir(shots,{recursive:true});
  await mkdir(files,{recursive:true});
  await ensureGoogleAuthSchema(db);await ensureAppCompatibilitySchema(db);await ensureWorkoutSchema(db);
  const password='JourneyFixturePassword123',hash=await bcrypt.hash(password,10);
  for(const role of ['client','coach','coach']){
    const email=`${prefix}-${users.length}@example.invalid`;
    const [r]=await db.query("INSERT INTO users(firstName,lastName,email,passwordHash,role,gender,isApproved,termsAccepted) VALUES('Journey','Fixture',?,?,?,'Other',1,1)",[email,hash,role]);users.push({id:r.insertId,role,email});
    if(role==='coach')await db.query('INSERT INTO coachprofiles(userID,bio,invitationCode) VALUES(?,?,?)',[r.insertId,'Journey fixture',`${prefix}-${users.length}`]);
  }
  const [client,coach,unlinked]=users;await db.query('INSERT INTO coachclients(coachID,clientID) VALUES(?,?)',[coach.id,client.id]);
  const {default:auth}=await import('../routes/anas/auth.js');api.use('/api/auth',auth);
  api.use('/api/workout',createWorkoutRouter(db,{notify:createAndSendNotification}));
  for(const [route,file] of [['clients','client'],['coaches','coach'],['advisors','advisorProfiles'],['reservations','reservations'],['availability','coachAvailability'],['conversations','conversations'],['categories','categories'],['favorites','favorites'],['premium','premium'],['weight-history','weightHistory'],['reviews','reviews']]){
    const {default:router}=await import(`../routes/anas/${file}.js`);api.use('/api/'+route,requireAuth,router);
  }
  for(const [route,file] of [['coach/profile','coachProfile'],['coach/dashboard','coachDashboard'],['coach/clients','coachClients'],['coach/calendar','coachCalendar'],['coach/notifications','coachNotifications'],['coach/conversations','coachConversations'],['coach/invitations','coachInvitations']]){
    const {default:router}=await import(`../routes/pahae/${file}.js`);api.use('/api/'+route,router);
  }
  const {default:version}=await import('../routes/anas/appVersion.js');api.use('/api/app-version',version);
  const {default:notifications}=await import('../routes/anas/notifications.js');api.use('/api/notifications',notifications);
  apiServer=api.listen(3201,'127.0.0.1');webServer=web.listen(8082,'127.0.0.1');await Promise.all([once(apiServer,'listening'),once(webServer,'listening')]);
  const request=async(user,url,method='GET',body)=>{
    const r=await fetch('http://localhost:3201/api'+url,{method,headers:{'Content-Type':'application/json',...(user?.token?{Authorization:'Bearer '+user.token}:{})},...(body?{body:JSON.stringify(body)}:{})});
    const data=await r.json();assert.equal(r.status>=200&&r.status<300,true,`${url}: ${r.status} ${JSON.stringify(data)}`);return data;
  };
  for(const user of users)user.token=(await request(null,'/auth/login','POST',{email:user.email,password})).accessToken;
  record('Real password login for Client and Coaches');
  const library=await request(coach,'/workout/exercises?search=bench&equipment=barbell');const exercise=library.data.find(e=>e.name.toLowerCase()==='barbell bench press');assert.ok(exercise);
  await request(coach,'/workout/plans','POST',{clientID:client.id,name:'Journey Plan',status:'assigned',days:[{name:'Journey Routine',dayOfWeek:new Date().getDay()||7,exercises:[{exerciseID:exercise.id,targetSets:2,targetReps:10,targetWeight:40,restSeconds:0}]}]});
  await request(client,'/workout/preferences','PUT',{view:'cards',unit:'kg',automaticRest:false,bodyweightCheckIn:true});
  record('Coach assignment persists in MySQL and is visible to Client');
  const versionInfo=await (await fetch(`http://127.0.0.1:${process.env.WEB_DEBUG_PORT||64425}/json/version`)).json();
  socket=new WebSocket(versionInfo.webSocketDebuggerUrl);await once(socket,'open');
  let sequence=0;const pending=new Map();
  const call=(method,params={},sessionId)=>new Promise((resolve,reject)=>{
    const id=++sequence;const timeout=setTimeout(()=>{pending.delete(id);reject(new Error(`CDP timeout: ${method}`));},30000);pending.set(id,{resolve,reject,timeout});socket.send(JSON.stringify({id,method,params,...(sessionId?{sessionId}:{})}));
  });
  browserCall=call;
  socket.addEventListener('message',event=>{
    const m=JSON.parse(event.data);if(m.id){const t=pending.get(m.id);if(t){clearTimeout(t.timeout);pending.delete(m.id);m.error?t.reject(new Error(m.error.message)):t.resolve(m.result);}return;}
    if(m.method==='Runtime.exceptionThrown')exceptions.push(m.params.exceptionDetails.text);
    if(m.method==='Page.fileChooserOpened')fileInput=m.params.backendNodeId;
    if(m.method==='Network.responseReceived'&&m.params.response.url.includes('localhost:3201/api/')&&m.params.response.status>=400)apiErrors.push({url:new URL(m.params.response.url).pathname,status:m.params.response.status});
  });
  const context=await call('Target.createBrowserContext');contextId=context.browserContextId;
  const target=await call('Target.createTarget',{url:'about:blank',browserContextId:contextId});const attached=await call('Target.attachToTarget',{targetId:target.targetId,flatten:true});currentSession=attached.sessionId;
  send=(method,params={})=>call(method,params,currentSession);
  await call('Browser.setDownloadBehavior',{behavior:'allow',downloadPath:files,browserContextId:contextId});
  await send('Page.setInterceptFileChooserDialog',{enabled:true});
  evaluate=async expression=>{const r=await send('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});if(r.exceptionDetails)throw new Error(r.exceptionDetails.text);return r.result.value;};
  await send('Runtime.enable');await send('Network.enable');await send('Page.enable');await send('Emulation.setDeviceMetricsOverride',{width:396,height:844,deviceScaleFactor:1,mobile:true});
  const open=async user=>{
    stage=user.role+' startup';
    const values={token:user.token,role:user.role,userId:user.id,firstName:'Journey',app_theme_mode:'light',sirvya_language:'en'};
    await send('Page.addScriptToEvaluateOnNewDocument',{source:`localStorage.clear();for(const [k,v] of Object.entries(${JSON.stringify(values)}))localStorage.setItem('flutter.'+k,JSON.stringify(v));`});
    await send('Page.navigate',{url:'http://localhost:8082/'});
    for(let i=0;i<180;i++){
      await evaluate(`document.querySelector('flt-semantics-placeholder')?.click();document.querySelector('video')?.click();`);
      const text=(await labels()).join(' ');if(user.role==='client'?text.includes('Workout'):text.includes('Dashboard'))return;
      if(i%15===0)console.log(`Waiting for ${user.role} startup (${i}s)`);
      if(i>5 && !text.includes('Home'))await clickPoint(198,400);await pause(1000);
    }
    const finalText=(await labels()).join(' ');
    if(user.role==='client'?finalText.includes('Workout'):finalText.includes('Dashboard'))return;
    throw new Error('Startup did not reach host navigation');
  };
  await open(client);stage='client Workout entry';await click('Workout');
  await waitFor(async()=> (await labels()).join(' ').includes('Journey Routine'),'assigned routine');await capture('client-home');record('Built app enters Workout with actual assigned routine');
  stage='start';await click('Start');await waitFor(async()=>(await labels()).join(' ').includes('Start without weighing in'),'weight check-in');await click('Start without weighing in');
  await waitFor(async()=>(await labels()).join(' ').includes('Complete set'),'active set');record('Actual UI start and optional weight check-in');
  stage='offline set';await capture('client-active');
  await send('Network.emulateNetworkConditions',{offline:true,latency:0,downloadThroughput:-1,uploadThroughput:-1});
  await click('Complete set');
  await waitFor(async()=>(await labels()).join(' ').includes('1 sets waiting to sync'),'offline set saved locally');
  await capture('client-offline');
  await send('Network.emulateNetworkConditions',{offline:false,latency:0,downloadThroughput:-1,uploadThroughput:-1});
  await click('Sync now');
  await waitFor(async()=>!(await labels()).join(' ').includes('waiting to sync'),'outbox synced');
  record('Real browser offline set queues locally and reconnect sync persists it');
  stage='online set';await click('Complete set');
  await waitFor(async()=>{const text=(await labels()).join(' ');return text.includes('Save weight')||text.includes('Continue workout');},'working-weight or completion prompt');
  if((await labels()).join(' ').includes('Save weight')){await capture('client-working-weight');await click('Save weight');record('Working-weight confirmation persists');}
  await waitFor(async()=>(await labels()).join(' ').includes('Continue workout'),'completion prompt');await click('Finish workout');
  await waitFor(async()=>(await labels()).join(' ').includes('Workout complete!'),'completion summary');await capture('client-summary');record('UI set logging and completion persist successfully');await click('Nice!');
  const history=await request(client,'/workout/history');assert.equal(history.data.length,1);const session=await request(client,`/workout/sessions/${history.data[0].id}`);assert.equal(session.status,'completed');assert.equal(session.sets.length,2);assert.equal(Number(session.sets[0].weight),40);assert.equal(Number(session.sets[0].reps),10);
  const stats=await request(client,'/workout/stats');assert.equal(stats.workoutCount,1);assert.equal(Number(stats.volume),800);record('Real persisted history and statistics match both logged sets');
  stage='stats';await click('Stats');await waitFor(async()=>(await labels()).join(' ').includes('Progress & history'),'Stats screen');await capture('client-stats');
  stage='backup export';await click('History');await click('Transfer workout history');
  await waitFor(async()=>(await labels()).join(' ').includes('Export workout backup'),'transfer screen');
  await click('Export workout backup');
  await waitFor(async()=>(await readdir(files)).includes('sirvya-workout-backup.json'),'real backup download');
  const backupPath=path.join(files,'sirvya-workout-backup.json');
  const backup=JSON.parse(await readFile(backupPath,'utf8'));assert.equal(backup.format,'sirvya-workout-backup');assert.equal(backup.history.sessions.length,1);
  const chooseFile=async filename=>{
    await send('Input.dispatchMouseEvent',{type:'mouseWheel',x:198,y:400,deltaX:0,deltaY:-3000});await pause(400);
    fileInput=null;await click('Choose history file');
    await waitFor(async()=>!!fileInput,'native browser file chooser');
    await send('DOM.setFileInputFiles',{files:[filename],backendNodeId:fileInput});
  };
  stage='backup restore';await chooseFile(backupPath);
  await waitFor(async()=>(await labels()).join(' ').includes('Workout backup preview'),'real backup preview');
  await capture('client-backup-preview');await click('Restore backup');
  await waitFor(async()=>(await labels()).join(' ').includes('Restore workout backup?'),'backup confirmation');await click('Restore backup');
  await waitFor(async()=>(await labels()).join(' ').includes('Workout backup restored'),'same-account restore');
  assert.equal((await request(client,'/workout/history')).data.length,1);
  record('Browser downloads, previews and restores its backup without duplicating history');
  stage='large Health file';
  const healthPath=path.join(files,'export.xml');
  const unrelated='<Record type="HKQuantityTypeIdentifierStepCount" unit="count" value="1" startDate="2026-10-01 10:00:00 +0000"/>\n';
  const xml='<HealthData>\n'+unrelated.repeat(100000)+'<Record type="HKQuantityTypeIdentifierBodyMass" unit="lb" value="170" startDate="2026-10-01 10:00:00 +0000"/>\n</HealthData>';
  assert.ok(Buffer.byteLength(xml)>8*1024*1024);await writeFile(healthPath,xml);
  await chooseFile(healthPath);await waitFor(async()=>(await labels()).join(' ').includes('1 measurements ready to import'),'streamed Health preview');
  await capture('client-health-preview');await click('Import measurements');
  await waitFor(async()=>(await labels()).join(' ').includes('1 measurements imported'),'measurement import');
  const [weights]=await db.query('SELECT weight FROM weighthistory WHERE clientID=?',[client.id]);assert.equal(weights.length,1);assert.equal(Number(weights[0].weight),77.11);
  await chooseFile(healthPath);await waitFor(async()=>(await labels()).join(' ').includes('1 measurements ready to import'),'repeated Health preview');await click('Import measurements');
  await waitFor(async()=>(await labels()).join(' ').includes('1 duplicate measurements skipped'),'duplicate measurement handling');
  record('Real browser streams an 8+ MiB Apple Health file, imports bodyweight and skips repeat duplicates');
  await click('Back');
  await waitFor(async()=>(await labels()).join(' ').includes('1 workouts'),'return to History');await click('Back');
  await waitFor(async()=>(await labels()).join(' ').includes('Progress & history'),'return to Stats');
  stage='host return';await click('Home');await click('Back to SIRVYA');record('Workout returns to SIRVYA');
  await open(coach);stage='coach Workout';await click('Workout');await waitFor(async()=>(await labels()).join(' ').includes('Journey Plan'),'Coach assignment view');await capture('coach-plans');await click('History');await waitFor(async()=>(await labels()).join(' ').includes('1 workouts'),'Coach history');await capture('coach-history');await clickPoint(180,140);
  await waitFor(async()=>(await labels()).join(' ').includes('Journey Routine'),'Coach workout detail');await capture('coach-detail');
  const review=await request(coach,`/workout/sessions/${session.id}`);assert.equal(Number(review.sets[0].weight),40);record('Coach UI reviews the Client completed workout');
  const denied=await fetch(`http://localhost:3201/api/workout/sessions/${session.id}`,{headers:{Authorization:'Bearer '+unlinked.token}});assert.equal(denied.status,403);record('Unlinked Coach cannot read that workout');
  assert.deepEqual(exceptions,[]);assert.deepEqual(apiErrors,[]);
  await writeFile(reportFile,JSON.stringify({verifiedAt:new Date().toISOString(),passed:true,fixtureOnly:false,disposableAccounts:true,realLocalMySQL:true,checks,apiErrors,exceptions,nativeDevices:false,externalProviders:false},null,2));
  await call('Target.disposeBrowserContext',{browserContextId:contextId});contextId=null;
}catch(error){
  if(send)try{await capture('failure');await writeFile(path.join(root,'workout_tmp','journey-failure-labels.json'),JSON.stringify(await labels(),null,2));}catch{}
  await writeFile(reportFile,JSON.stringify({verifiedAt:new Date().toISOString(),passed:false,stage,error:error.message,checks,apiErrors,exceptions},null,2));
  throw error;
}finally{
  if(contextId&&browserCall)try{await browserCall('Target.disposeBrowserContext',{browserContextId:contextId});}catch{}
  socket?.close();
  if(apiServer)await new Promise(resolve=>apiServer.close(resolve));if(webServer)await new Promise(resolve=>webServer.close(resolve));
  const [fixtures]=await db.query('SELECT id FROM users WHERE email LIKE ?',[`${prefix}%@example.invalid`]);for(const u of fixtures)await db.query('DELETE FROM users WHERE id=?',[u.id]);await db.end();
}
