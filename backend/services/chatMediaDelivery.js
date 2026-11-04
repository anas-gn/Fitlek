import path from 'node:path';
import {promises as fs} from 'node:fs';
import {createHash} from 'node:crypto';
export const CHAT_MEDIA_RECEIPTS_SCHEMA = `CREATE TABLE IF NOT EXISTS chat_media_receipts (
 messageID BIGINT UNSIGNED NOT NULL, userID BIGINT UNSIGNED NOT NULL,
 savedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY(messageID,userID), KEY idx_media_user(userID),
 FOREIGN KEY(messageID) REFERENCES messages(id) ON DELETE CASCADE,
 FOREIGN KEY(userID) REFERENCES users(id) ON DELETE CASCADE)`;
export function chatMediaPath(url, root = path.resolve('uploads/chat_media')) {
 const pathname = decodeURIComponent(new URL(url).pathname);
 const match = /^\/uploads\/chat_media\/([A-Za-z0-9_.-]+)$/.exec(pathname);
 if (!match || match[1] === '.' || match[1] === '..') throw new Error('Invalid chat media path');
 const file = path.resolve(root,match[1]);
 if (path.dirname(file) !== path.resolve(root)) throw new Error('Invalid chat media path');
 return file;
}
export async function acknowledgeMedia(pool, userID, messageID, sha256, {root} = {}) {
 const conn = await pool.getConnection();
 try {
  await conn.beginTransaction();
  const [[message]] = await conn.query(`SELECT m.*,c.coachID,c.clientID FROM messages m
    JOIN conversations c ON c.id=m.conversationID WHERE m.id=? AND (c.coachID=? OR c.clientID=?) FOR UPDATE`,[messageID,userID,userID]);
  if (!message || message.deletedAt || !['image','audio'].includes(message.mediaType)) {
   const error = new Error('Media not found');error.status=404;throw error;
  }
  if (!message.mediaExpired) {
   const content = await fs.readFile(chatMediaPath(message.mediaUrl,root));
   if (createHash('sha256').update(content).digest('hex') !== sha256) {
    const error = new Error('Downloaded file does not match');error.status=400;throw error;
   }
  }
  await conn.query('INSERT IGNORE INTO chat_media_receipts (messageID,userID) VALUES (?,?)',[messageID,userID]);
  await conn.commit();
  return {conversationID:message.conversationID};
 } catch(error) {await conn.rollback();throw error;} finally {conn.release();}
}
// Remove media after both participants saved it or explicitly deleted their copy.
// Delete-for-everyone media is purged regardless of delivery. History is retained.
export async function cleanupDeliveredMedia(pool, {root} = {}) {
 const [rows] = await pool.query(`SELECT m.id,m.mediaUrl FROM messages m JOIN conversations c ON c.id=m.conversationID
  WHERE m.mediaType IN ('image','audio') AND m.mediaExpired=0
  AND (m.deletedAt IS NOT NULL OR (
  (EXISTS(SELECT 1 FROM chat_media_receipts r WHERE r.messageID=m.id AND r.userID=c.coachID)
   OR EXISTS(SELECT 1 FROM chat_hidden_messages h WHERE h.messageID=m.id AND h.userID=c.coachID))
  AND (EXISTS(SELECT 1 FROM chat_media_receipts r WHERE r.messageID=m.id AND r.userID=c.clientID)
   OR EXISTS(SELECT 1 FROM chat_hidden_messages h WHERE h.messageID=m.id AND h.userID=c.clientID)))) LIMIT 100`);
 let removed=0;
 for (const row of rows) {
  try {
   const [[shared]] = await pool.query('SELECT COUNT(*) AS total FROM messages WHERE mediaUrl=? AND mediaExpired=0 AND id<>?',[row.mediaUrl,row.id]);
   if (Number(shared.total)>0) continue;
   await fs.unlink(chatMediaPath(row.mediaUrl,root)).catch(error=>{if(error.code!=='ENOENT')throw error;});
   await pool.query('UPDATE messages SET mediaExpired=1 WHERE id=?',[row.id]);
   removed++;
  } catch(error) {console.error('Delivered media cleanup deferred:',error.code || 'invalid media');}
 }
 return removed;
}
