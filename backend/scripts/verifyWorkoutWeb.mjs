// Isolated browser smoke test of the full built app. All API traffic is answered
// with synthetic fixtures in this browser context; no database writes occur.
import fs from 'node:fs';
import {once} from 'node:events';
const fixture=JSON.parse(fs.readFileSync(new URL('../../test/fixtures/workout-product-parity.json',import.meta.url),'utf8'));
const version=await (await fetch('http://127.0.0.1:64423/json/version')).json();
const socket=new WebSocket(version.webSocketDebuggerUrl);await once(socket,'open');
let seq=0;const pending=new Map(),requests=[],errors=[],consoleMessages=[],failedResources=[],resources=new Map();
const call=(method,params={},sessionId)=>new Promise((resolve,reject)=>{
  const id=++seq;pending.set(id,{resolve,reject});socket.send(JSON.stringify({id,method,params,...(sessionId?{sessionId}:{})}));
});
socket.addEventListener('message',async event=>{
  const m=JSON.parse(event.data);
  if(m.id){const task=pending.get(m.id);if(!task)return;pending.delete(m.id);m.error?task.reject(Error(m.error.message)):task.resolve(m.result);return;}
  if(m.method==='Runtime.exceptionThrown')errors.push(m.params.exceptionDetails.exception?.description??m.params.exceptionDetails.text);
  if(m.method==='Runtime.consoleAPICalled')consoleMessages.push(m.params.args.map(a=>a.value??a.description??'').join(' '));
  if(m.method==='Network.loadingFailed')failedResources.push({error:m.params.errorText,type:m.params.type});
  if(m.method==='Network.requestWillBeSent'){const u=new URL(m.params.request.url);resources.set(m.params.requestId,{url:u.origin+u.pathname,done:false});}
  if(m.method==='Network.loadingFinished'&&resources.has(m.params.requestId))resources.get(m.params.requestId).done=true;
  if(m.method!=='Fetch.requestPaused')return;
  const {requestId,request}=m.params,url=new URL(request.url);requests.push({path:url.pathname,method:request.method});
  let data=[];
  if(url.pathname.includes('/clients/me'))data={id:42,firstName:'Workout',lastName:'Fixture',role:'client',email:'qa@example.invalid',ville:'Test'};
  if(url.pathname.endsWith('/unread-total'))data={total:0};
  if(url.pathname.endsWith('/notifications/count'))data={count:0};
  if(url.pathname.endsWith('/weight-history/me/stats'))data={currentWeight:79.5,startWeight:80,maxWeight:80,minWeight:79.5,totalEntries:2,totalLoss:.5};
  if(url.pathname.includes('/workout/')){
    data={data:[]};
    if(url.pathname.endsWith('/plans'))data={data:[fixture.plan]};
    if(url.pathname.endsWith('/stats'))data=fixture.stats;
    if(url.pathname.endsWith('/history'))data={data:fixture.history,total:1};
    if(url.pathname.endsWith('/schedule'))data=fixture.schedule;
    if(url.pathname.endsWith('/exercises'))data={
      data:fixture.plan.days[0].exercises.map(e=>({...e,id:e.exerciseID,instructions:[]})),
      total:2,chosenCount:2,hasMore:false,effectiveEquipment:null,
      filters:{bodyPart:['back','chest'],equipment:['barbell'],muscleGroup:['pectorals','upper back'],secondaryMuscle:['triceps','shoulders','biceps','forearms'],exerciseType:['reps']}
    };
    if(url.pathname.endsWith('/sessions/active'))data={session:null};
    if(url.pathname.endsWith('/preferences'))data={unit:'kg',view:'cards',viewVersion:2,bodyweightCheckIn:true,defaultRestSeconds:90,
      automaticRest:true,effort:'rir',timeZone:'UTC',reminderTime:'18:00',equipmentProfiles:[]};
  }
  await call('Fetch.fulfillRequest',{requestId,responseCode:200,responseHeaders:[
    {name:'Content-Type',value:'application/json'},{name:'Access-Control-Allow-Origin',value:'http://localhost:8080'},
    {name:'Access-Control-Allow-Headers',value:'*'},{name:'Access-Control-Allow-Methods',value:'GET,POST,PUT,DELETE,OPTIONS'}
  ],body:Buffer.from(JSON.stringify(data)).toString('base64')},m.sessionId);
});
const context=await call('Target.createBrowserContext');
try {
  const target=await call('Target.createTarget',{url:'about:blank',browserContextId:context.browserContextId});
  const {sessionId}=await call('Target.attachToTarget',{targetId:target.targetId,flatten:true});
  const send=(method,params={})=>call(method,params,sessionId);
  const evaluate=async expression=>{
    const r=await send('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});
    if(r.exceptionDetails)throw Error(r.exceptionDetails.exception?.description);return r.result.value;
  };
  await send('Runtime.enable');await send('Page.enable');await send('Network.enable');
  await send('Fetch.enable',{patterns:[{urlPattern:'http://localhost:3000/api/*'}]});
  await send('Emulation.setDeviceMetricsOverride',{width:396,height:844,deviceScaleFactor:1,mobile:true});
  await send('Page.addScriptToEvaluateOnNewDocument',{source:`for(const [key,value] of Object.entries({token:'qa-fixture-only',role:'client',userId:42,firstName:'Workout',app_theme_mode:'light',sirvya_language:'en'}))localStorage.setItem('flutter.'+key,JSON.stringify(value));`});
  await send('Page.navigate',{url:'http://localhost:8080/'});
  for(let waited=0;waited<120&&!requests.some(r=>r.path.endsWith('/clients/me'));waited+=5){
    await new Promise(resolve=>setTimeout(resolve,5000));
    await evaluate(`document.querySelector('flt-semantics-placeholder')?.click();document.querySelector('video')?.click();`);
    await send('Input.dispatchMouseEvent',{type:'mousePressed',x:198,y:400,button:'left',clickCount:1});
    await send('Input.dispatchMouseEvent',{type:'mouseReleased',x:198,y:400,button:'left',clickCount:1});
    if(waited%20===0)console.log(`Browser startup: ${waited+5}s, ${requests.length} fixture API requests`);
  }
  await evaluate(`document.querySelector('flt-semantics-placeholder')?.click()`);
  await send('Input.dispatchMouseEvent',{type:'mousePressed',x:198,y:400,button:'left',clickCount:1});
  await send('Input.dispatchMouseEvent',{type:'mouseReleased',x:198,y:400,button:'left',clickCount:1});
  await new Promise(resolve=>setTimeout(resolve,3000));
  await send('Input.dispatchMouseEvent',{type:'mousePressed',x:198,y:797,button:'left',clickCount:1});
  await send('Input.dispatchMouseEvent',{type:'mouseReleased',x:198,y:797,button:'left',clickCount:1});
  await new Promise(resolve=>setTimeout(resolve,2000));
  const shot=await send('Page.captureScreenshot',{format:'png',captureBeyondViewport:false});
  fs.writeFileSync(new URL('../../docs/verification/parity/sirvya-full-web-smoke.png',import.meta.url),Buffer.from(shot.data,'base64'));
  const state=await evaluate(`({views:document.querySelectorAll('flutter-view').length,text:document.body.innerText.slice(0,2000),labels:[...document.querySelectorAll('[aria-label]')].map(e=>e.getAttribute('aria-label')).slice(0,100)})`);
  const tabChecks=[];
  for(const [name,x,content] of [['Plan',118,'Monday Full body'],['Stats',276,'Progress & history'],['Exercises',355,'Barbell Bench Press']]){
    await send('Input.dispatchMouseEvent',{type:'mousePressed',x,y:805,button:'left',clickCount:1});
    await send('Input.dispatchMouseEvent',{type:'mouseReleased',x,y:805,button:'left',clickCount:1});
    await new Promise(resolve=>setTimeout(resolve,1500));
    const text=await evaluate(`[document.body.innerText,...[...document.querySelectorAll('[aria-label]')].map(e=>e.getAttribute('aria-label'))].join(' ')`);
    tabChecks.push({name,hasTitle:text.includes(name),hasContent:text.includes(content),noLoadError:!text.includes('Unable to load Workout'),hostNavigationAbsent:!text.includes('Explore')&&!text.includes('Profile'),text:text.slice(0,2000)});
  }
  await send('Input.dispatchMouseEvent',{type:'mousePressed',x:40,y:805,button:'left',clickCount:1});
  await send('Input.dispatchMouseEvent',{type:'mouseReleased',x:40,y:805,button:'left',clickCount:1});
  await new Promise(resolve=>setTimeout(resolve,500));
  await send('Input.dispatchMouseEvent',{type:'mousePressed',x:28,y:38,button:'left',clickCount:1});
  await send('Input.dispatchMouseEvent',{type:'mouseReleased',x:28,y:38,button:'left',clickCount:1});
  await new Promise(resolve=>setTimeout(resolve,500));
  const returnedToSirvya=await evaluate(`document.body.innerText.includes('Explore')&&!document.body.innerText.includes('Back to SIRVYA')`);
  const report={builtApp:true,fixtureOnly:true,state,tabChecks,returnedToSirvya,requests,errors,consoleMessages,failedResources,resources:[...resources.values()]};
  fs.writeFileSync(new URL('../../workout_tmp/recovery-web-smoke.json',import.meta.url),JSON.stringify(report,null,2)+'\n');
  console.log(JSON.stringify(report));
  if(state.views<1||errors.length||!requests.some(r=>r.path.endsWith('/workout/plans'))||
    !state.text.includes('Back to SIRVYA')||state.text.includes('Explore')||state.text.includes('Profile')||
    tabChecks.some(t=>!t.hasTitle||!t.hasContent||!t.noLoadError||!t.hostNavigationAbsent)||!returnedToSirvya)process.exitCode=1;
}finally{await call('Target.disposeBrowserContext',{browserContextId:context.browserContextId});socket.close();}
