const ready = new WeakMap();
export function ensureRealtimeJournal(db) {
  if (!ready.has(db)) {
    ready.set(db,db.query(`CREATE TABLE IF NOT EXISTS app_live_events (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
      domain VARCHAR(40) NOT NULL,
      createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      INDEX(createdAt)
    )`).catch(error => { ready.delete(db); throw error; }));
  }
  return ready.get(db);
}
export async function recordLiveChange(db, domain) {
  await ensureRealtimeJournal(db);
  await db.query('INSERT INTO app_live_events (domain) VALUES (?)',[domain]);
}
// Shared by app and admin processes; the journal never stores private information.
export function adminLiveWrites(db) {
  return (req,res,next) => {
    if (['POST','PUT','PATCH','DELETE'].includes(req.method)) {
      res.on('finish',() => {
        if (res.statusCode>=200 && res.statusCode<300 && !req.originalUrl.includes('/auth/')) {
          recordLiveChange(db,'all').catch(error => console.error('Admin live update failed:',error.message));
        }
      });
    }
    next();
  };
}
