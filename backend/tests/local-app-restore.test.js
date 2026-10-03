import test from 'node:test';
import assert from 'node:assert/strict';
import {parseValues, parseDump, adaptLegacyRow, mergeLocalData} from '../scripts/restoreLocalAppData.mjs';

test('legacy dump parser retains escaped content and accepts UTF-16 without evaluating SQL', () => {
  assert.deepEqual(parseValues("(1,'coach; (test), \\'quoted\\'',NULL,2.5),(2,'line\\nnext',0,-1)"),
    [[1,"coach; (test), 'quoted'",null,2.5],[2,'line\nnext',0,-1]]);
  const dump = "CREATE TABLE `users` (\n `id` int,\n `email` varchar(100)\n) ENGINE=InnoDB;\nINSERT INTO `users` VALUES (1,'fixture@example.invalid');\n" +
    "CREATE TABLE `authtokens` (\n `id` int\n) ENGINE=InnoDB;\nINSERT INTO `authtokens` VALUES (2);\n";
  const parsed = parseDump(Buffer.from('\uFEFF'+dump, 'utf16le'));
  assert.deepEqual(parsed.get('users').rows,[{id:1,email:'fixture@example.invalid'}]);
  assert.equal(parsed.has('authtokens'),false);
});

test('legacy dump parser rejects SQL expressions, malformed rows and unsafe integers', () => {
  for (const input of ["(1,NOW())", "(1,'unterminated)", '(9007199254740993)', '(1,)', '(1); DROP TABLE users;']) {
    assert.throws(() => parseValues(input));
  }
  const dump="CREATE TABLE `users` (\n `id` int,\n `email` text\n) ENGINE=InnoDB;\nINSERT INTO `users` VALUES (1);\n";
  assert.throws(() => parseDump(Buffer.from(dump)), /column mismatch/);
});

test('legacy profiles retain price meaning and accounts never restore device tokens', () => {
  assert.equal(adaptLegacyRow('coachprofiles',{price:'120 MAD'}).price,120);
  assert.equal(adaptLegacyRow('coachprofiles',{price:'120,50 dh'}).price,120.5);
  assert.equal(adaptLegacyRow('coachprofiles',{price:null}).price,null);
  assert.throws(() => adaptLegacyRow('coachprofiles',{price:'120 USD'}));
  const original={id:1,authProvider:'email',fcmToken:'old-fixture-token'};
  assert.deepEqual(adaptLegacyRow('users',original),{authProvider:'local',fcmToken:null});
  assert.equal(original.fcmToken,'old-fixture-token');
  assert.equal(adaptLegacyRow('coachclients',{createdAt:'2025-01-01'}).assignedAt,'2025-01-01');
});

test('local MySQL merge preserves accounts, remaps relationships and rolls back invalid imports',
  {skip:process.env.APP_TEST_MYSQL !== '1'}, async () => {
    const {default:db} = await import('../config/db.js');
    assert.ok(['localhost','127.0.0.1','::1'].includes(process.env.DB_HOST));
    const prefix=`restore-test-${Date.now()}-${process.pid}`;
    const clientEmail=`${prefix}-client@example.invalid`;
    const coachEmail=`${prefix}-coach@example.invalid`;
    let clientID;
    let connection;
    try {
      const [result]=await db.query("INSERT INTO users (firstName,lastName,email,passwordHash,role,gender,isApproved) VALUES ('Restore','Fixture',?,'existing-fixture-hash','client','Other',1)",[clientEmail]);
      clientID=result.insertId;
      connection=await db.getConnection();
      const rows = values => ({rows:values});
      const tables=new Map([
        ['users',rows([
          {id:1,email:clientEmail,role:'client',passwordHash:'replacement-must-not-be-used'},
          {id:2,firstName:'Restore',lastName:'Fixture',email:coachEmail,role:'coach',gender:'Other',isApproved:1,authProvider:'email',passwordHash:'fixture-hash',fcmToken:'old-fixture-device'},
        ])],
        ['coachprofiles',rows([{id:1,userID:2,bio:'Fixture',invitationCode:prefix,price:'120 MAD'}])],
        ['coachclients',rows([{id:1,coachID:2,clientID:1,createdAt:'2025-01-02 12:00:00'}])],
        ['conversations',rows([{id:1,coachID:2,clientID:1,createdAt:'2025-01-02 12:00:00',lastMessageAt:null}])],
        ['messages',rows([{id:1,conversationID:1,senderID:2,body:'Fixture',isRead:0,createdAt:'2025-01-03 12:00:00'}])],
      ]);
      await connection.beginTransaction();
      const merged=await mergeLocalData(connection,tables);
      assert.equal(merged.reused.users,1);
      assert.equal(merged.inserted.users.length,1);
      const coachID=merged.inserted.users[0];
      const [[client]]=await connection.query('SELECT passwordHash FROM users WHERE id=?',[clientID]);
      assert.equal(client.passwordHash,'existing-fixture-hash');
      const [[coach]]=await connection.query('SELECT authProvider,fcmToken FROM users WHERE id=?',[coachID]);
      assert.equal(coach.authProvider,'local');assert.equal(coach.fcmToken,null);
      const [[link]]=await connection.query('SELECT coachID,clientID FROM coachclients WHERE id=?',[merged.inserted.coachclients[0]]);
      assert.equal(Number(link.coachID),coachID);assert.equal(Number(link.clientID),clientID);
      const [[message]]=await connection.query('SELECT senderID,conversationID FROM messages WHERE id=?',[merged.inserted.messages[0]]);
      assert.equal(Number(message.senderID),coachID);assert.equal(Number(message.conversationID),merged.inserted.conversations[0]);
      const [[conversation]]=await connection.query("SELECT DATE_FORMAT(lastMessageAt,'%Y-%m-%d %H:%i:%s') AS latest FROM conversations WHERE id=?",[message.conversationID]);
      assert.equal(conversation.latest,'2025-01-03 12:00:00');
      await connection.rollback();
      const [[missing]]=await connection.query('SELECT COUNT(*) AS total FROM users WHERE email=?',[coachEmail]);
      assert.equal(missing.total,0);
      tables.get('coachprofiles').rows[0].userID=999999;
      await connection.beginTransaction();
      await assert.rejects(mergeLocalData(connection,tables), /Unresolved backup relationship/);
      await connection.rollback();
      const [[unchanged]]=await connection.query('SELECT COUNT(*) AS total FROM users WHERE email=?',[coachEmail]);
      assert.equal(unchanged.total,0);
    } finally {
      if(connection){await connection.rollback();connection.release();}
      if(clientID)await db.query('DELETE FROM users WHERE id=? AND email=?',[clientID,clientEmail]);
      await db.end();
    }
  });
