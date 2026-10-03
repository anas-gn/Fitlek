import {opendir,stat,unlink} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const directory=fileURLToPath(new URL('../storage/workout/',import.meta.url));

// Account/session cascades may leave a file behind. Remove only our UUID files
// absent from MySQL, after a full day's grace for in-flight uploads.
export async function pruneWorkoutMedia(db){
  let entries;try{entries=await opendir(directory);}catch(error){if(error.code==='ENOENT')return 0;throw error;}
  let scanned=0,removed=0;
  for await(const entry of entries){
    if(++scanned>10000||removed>=200)break;
    if(!entry.isFile()||!/^\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\.(webp|mp4)$/.test(entry.name))continue;
    const filename=path.resolve(directory,entry.name);
    if(path.dirname(filename)!==path.resolve(directory))continue;
    const info=await stat(filename).catch(()=>null);if(!info||Date.now()-info.mtimeMs<86400000)continue;
    const [existing]=await db.query('SELECT id FROM workout_media WHERE filename=?',[entry.name]);
    if(!existing.length){await unlink(filename);removed++;}
  }return removed;
}
export function startWorkoutMediaCleanup(db,ready){
  let busy=false;
  const prune=async()=>{if(busy)return;busy=true;try{await ready;await pruneWorkoutMedia(db);}catch(error){console.error('Workout media cleanup unavailable:',error.code||error.message);}finally{busy=false;}};
  prune();const timer=setInterval(prune,3600000);timer.unref();return ()=>clearInterval(timer);
}
