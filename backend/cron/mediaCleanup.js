import cron from 'node-cron';
import db from '../config/db.js';
import {cleanupDeliveredMedia} from '../services/chatMediaDelivery.js';
let running=false;
cron.schedule('*/5 * * * *',async()=>{
 if(running)return;running=true;
 try {const removed=await cleanupDeliveredMedia(db);if(removed)console.log(`Removed ${removed} safely delivered chat files`);}
 catch(error){console.error('Chat media cleanup deferred:',error.code || 'database unavailable');}
 finally{running=false;}
});
export const startMediaCleanupJob=()=>console.log('Acknowledged chat media cleanup scheduled');
