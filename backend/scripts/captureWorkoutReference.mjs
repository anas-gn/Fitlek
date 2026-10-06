import fs from 'node:fs';
import {once} from 'node:events';
const fixture=JSON.parse(fs.readFileSync(new URL('../../test/fixtures/workout-product-parity.json',import.meta.url),'utf8'));
const version=await (await fetch('http://127.0.0.1:64423/json/version')).json();
const socket=new WebSocket(version.webSocketDebuggerUrl);await once(socket,'open');
let seq=0;const pending=new Map();
socket.addEventListener('message',event=>{const m=JSON.parse(event.data);if(!m.id)return;const task=pending.get(m.id);if(!task)return;pending.delete(m.id);m.error?task.reject(Error(m.error.message)):task.resolve(m.result);});
const call=(method,params={},sessionId)=>new Promise((resolve,reject)=>{const id=++seq;pending.set(id,{resolve,reject});socket.send(JSON.stringify({id,method,params,...(sessionId?{sessionId}:{})}));});
const context=await call('Target.createBrowserContext');
try{
  const target=await call('Target.createTarget',{url:'about:blank',browserContextId:context.browserContextId});
  const {sessionId}=await call('Target.attachToTarget',{targetId:target.targetId,flatten:true});
  const send=(method,params)=>call(method,params,sessionId);
  await send('Page.enable');await send('Runtime.enable');
  const evaluate=async expression=>{const r=await send('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});if(r.exceptionDetails)throw Error(r.exceptionDetails.exception?.description);return r.result.value;};
  await send('Page.addScriptToEvaluateOnNewDocument',{source:`const RealDate=Date;globalThis.Date=class extends RealDate{constructor(...args){super(...(args.length?args:[${new Date(fixture.now).getTime()}]));}static now(){return ${new Date(fixture.now).getTime()};}};localStorage.setItem('gym_guest','1');localStorage.setItem('gym_state_v1',${JSON.stringify(JSON.stringify(fixture.reference))});`});
  await send('Page.navigate',{url:'http://127.0.0.1:8091/#/home'});
  await new Promise(r=>setTimeout(r,2500));
  fs.mkdirSync(new URL('../../docs/verification/parity/',import.meta.url),{recursive:true});
  for(const width of [396,1100]){
    await send('Emulation.setDeviceMetricsOverride',{width,height:844,deviceScaleFactor:1,mobile:width<600});
    const pages=[['home','home'],['plan','plan'],['stats','stats'],['active','workout'],['editor','plan/r/r1'],['picker','plan/r/r1'],['configuration','plan/r/r1'],['summary','workout'],['library','library'],['history','history'],['custom','library'],['checkin','home'],['day-override','home'],['day-assignment','plan'],['calendar','home']];
    for(const [page,route] of pages.filter(([page])=>!process.env.WORKOUT_CAPTURE_PAGES||process.env.WORKOUT_CAPTURE_PAGES.split(',').includes(page))){
      await evaluate(`(async()=>{const {useStore}=await import('/src/store/useStore.js');useStore.getState().replaceState({...${JSON.stringify(fixture.reference)},active:${['active','summary'].includes(page)?JSON.stringify(fixture.referenceActive):'null'}});location.hash='/${route}';})()`);
      await new Promise(r=>setTimeout(r,500));
      if(page==='picker')await evaluate(`(async()=>{const {exercisePicker}=await import('/src/sheets.jsx');exercisePicker(()=>{});})()`);
      if(page==='configuration')await evaluate(`(async()=>{const {exConfigSheet}=await import('/src/sheets.jsx');const {EXIDX}=await import('/src/lib/exercises.js');exConfigSheet(EXIDX['0025'],${JSON.stringify(fixture.reference.routines[0].ex[0])},()=>{},()=>{},${JSON.stringify(fixture.reference.routines[0])});})()`);
      if(page==='summary')await evaluate(`(async()=>{const {useStore}=await import('/src/store/useStore.js');const {finishWorkout}=await import('/src/sheets.jsx');useStore.getState().update(s=>{s.active.start=Date.now()-1800000;s.active.entries[0].sets[0].done=true;});finishWorkout();})()`);
      if(page==='summary'){
        await new Promise(r=>setTimeout(r,100));
        await evaluate(`Array.from(document.querySelectorAll('button')).find(b=>b.textContent==='Finish workout').click()`);
      }
      if(page==='custom')await evaluate(`(async()=>{const {customExSheet}=await import('/src/sheets.jsx');customExSheet(null,()=>{},'Indoor cycling');})()`);
      if(page==='checkin')await evaluate(`(async()=>{const {bwSheet}=await import('/src/sheets.jsx');bwSheet({required:true});})()`);
      if(page==='day-override')await evaluate(`(async()=>{const {dayOverrideSheet}=await import('/src/sheets.jsx');dayOverrideSheet('2026-10-04');})()`);
      if(page==='day-assignment')await evaluate(`(async()=>{const {dayAssignSheet}=await import('/src/sheets.jsx');dayAssignSheet(1);})()`);
      if(page==='calendar')await evaluate(`(async()=>{const {calendarSheet}=await import('/src/sheets.jsx');calendarSheet('2026-10-04');})()`);
      await new Promise(r=>setTimeout(r,300));
      const shot=await send('Page.captureScreenshot',{format:'png',captureBeyondViewport:false});
      fs.writeFileSync(new URL(`../../docs/verification/parity/opengym-${page}-${width}.png`,import.meta.url),Buffer.from(shot.data,'base64'));
      const text=await evaluate('document.body.innerText.slice(0,160)');
      console.log(`${page} ${width}: ${text.replaceAll('\n',' · ')}`);
      await evaluate(`(async()=>{const {useUI}=await import('/src/store/useUI.js');useUI.setState({sheets:[]});window.scrollTo(0,0);})()`);
    }
  }
}finally{await call('Target.disposeBrowserContext',{browserContextId:context.browserContextId});socket.close();}
