export const CHAT_HIDDEN_SCHEMA = `CREATE TABLE IF NOT EXISTS chat_hidden_messages (
 messageID BIGINT UNSIGNED NOT NULL,userID BIGINT UNSIGNED NOT NULL,
 PRIMARY KEY(messageID,userID),
 FOREIGN KEY(messageID) REFERENCES messages(id) ON DELETE CASCADE,
 FOREIGN KEY(userID) REFERENCES users(id) ON DELETE CASCADE)`;
export async function ensureChatDeletionSchema(db) {
 const [columns]=await db.query("SHOW COLUMNS FROM messages LIKE 'deletedAt'");
 if(!columns.length) await db.query('ALTER TABLE messages ADD COLUMN deletedAt DATETIME NULL');
 await db.query(CHAT_HIDDEN_SCHEMA);
}
export function validateDeletionRows(rows, ids, userID, scope) {
 if(rows.length!==ids.length) throw Object.assign(new Error('Some messages are unavailable.'),{status:404});
 if(scope==='everyone' && rows.some(m=>Number(m.senderID)!==Number(userID)||m.deletedAt||!Number(m.canDelete))) {
  throw Object.assign(new Error('Only your own messages sent less than 30 minutes ago can be deleted for everyone. Use Delete for me instead.'),{status:409});
 }
}
export async function deleteChatMessages(db,userID,conversationID,ids,scope) {
 const conn=await db.getConnection();
 try {
  await conn.beginTransaction();
  const [[conversation]]=await conn.query('SELECT id,coachID,clientID FROM conversations WHERE id=? AND (coachID=? OR clientID=?) FOR UPDATE',[conversationID,userID,userID]);
  if(!conversation) throw Object.assign(new Error('Access denied.'),{status:403});
  const [rows]=await conn.query(`SELECT id,senderID,deletedAt,(createdAt>DATE_SUB(NOW(),INTERVAL 30 MINUTE)) AS canDelete FROM messages WHERE conversationID=? AND id IN (?) FOR UPDATE`,[conversationID,ids]);
  validateDeletionRows(rows,ids,userID,scope);
  if(scope==='everyone') {
   await conn.query("UPDATE messages SET deletedAt=NOW(),body='This message was deleted' WHERE conversationID=? AND id IN (?)",[conversationID,ids]);
  } else {
   await conn.query('INSERT IGNORE INTO chat_hidden_messages (messageID,userID) VALUES ?',[ids.map(id=>[id,userID])]);
  }
  await conn.commit();return conversation;
 } catch(error){await conn.rollback();throw error;} finally{conn.release();}
}
