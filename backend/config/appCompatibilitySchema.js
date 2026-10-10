import { readFile } from 'node:fs/promises';

// Bring older SIRVYA schemas up to the fields already used by native screens.
// Retain legacy columns/IDs and existing data; do not recreate tables.
export async function ensureAppCompatibilitySchema(db) {
  const [weightNotes]=await db.query("SELECT DATA_TYPE,CHARACTER_MAXIMUM_LENGTH FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='weighthistory' AND COLUMN_NAME='note'");
  if(weightNotes.some(v=>v.DATA_TYPE==='varchar'&&Number(v.CHARACTER_MAXIMUM_LENGTH)<2000))await db.query('ALTER TABLE weighthistory MODIFY note VARCHAR(2000) NULL');
  const columnsFor = async table => {
    const [columns] = await db.query('SHOW COLUMNS FROM ??', [table]);
    return new Map(columns.map(column => [column.Field, column]));
  };
  const addMissing = async (table, columns, name, definition) => {
    if (columns.has(name)) return false;
    await db.query(`ALTER TABLE \`${table}\` ADD COLUMN \`${name}\` ${definition}`);
    return true;
  };

  const profiles = await columnsFor('coachprofiles');
  if (await addMissing('coachprofiles', profiles, 'tel', 'VARCHAR(40) NULL')) {
    await db.query('UPDATE coachprofiles cp JOIN users u ON u.id=cp.userID SET cp.tel=u.phoneNumber');
  }
  if (await addMissing('coachprofiles', profiles, 'price', 'DECIMAL(10,2) NOT NULL DEFAULT 0') && profiles.has('pricing')) {
    await db.query('UPDATE coachprofiles SET price=COALESCE(pricing,0)');
  }
  if (await addMissing('coachprofiles', profiles, 'ville', 'VARCHAR(255) NULL') && profiles.has('location')) {
    await db.query('UPDATE coachprofiles SET ville=location');
  }
  const advisors = await columnsFor('advisorprofiles');
  if (await addMissing('advisorprofiles', advisors, 'ville', 'VARCHAR(255) NULL') && advisors.has('location')) {
    await db.query('UPDATE advisorprofiles SET ville=location');
  }

  const conversations = await columnsFor('conversations');
  const addedClient = await addMissing('conversations', conversations, 'clientID', 'BIGINT UNSIGNED NULL');
  const addedCoach = await addMissing('conversations', conversations, 'coachID', 'BIGINT UNSIGNED NULL');
  if ((addedClient || addedCoach) && conversations.has('user1ID') && conversations.has('user2ID')) {
    await db.query(`UPDATE conversations cv
      JOIN users u1 ON u1.id=cv.user1ID JOIN users u2 ON u2.id=cv.user2ID
      SET cv.clientID=CASE WHEN u1.role='client' THEN u1.id ELSE u2.id END,
          cv.coachID=CASE WHEN u1.role='coach' THEN u1.id ELSE u2.id END
      WHERE (u1.role='client' AND u2.role='coach') OR (u1.role='coach' AND u2.role='client')`);
  }
  for (const name of ['user1ID', 'user2ID']) {
    if (conversations.get(name)?.Null === 'NO') {
      await db.query(`ALTER TABLE conversations MODIFY COLUMN \`${name}\` BIGINT UNSIGNED NULL`);
    }
  }
  if (await addMissing('conversations', conversations, 'lastMessageAt', 'DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP')) {
    await db.query(`UPDATE conversations cv SET lastMessageAt=COALESCE(
      (SELECT MAX(m.createdAt) FROM messages m WHERE m.conversationID=cv.id),cv.createdAt)`);
  }
  const [constraints] = await db.query(`SELECT CONSTRAINT_NAME FROM information_schema.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='conversations'`);
  const names = new Set(constraints.map(c => c.CONSTRAINT_NAME));
  if (!names.has('uq_sirvya_conversation_roles')) {
    await db.query('ALTER TABLE conversations ADD UNIQUE KEY uq_sirvya_conversation_roles (clientID,coachID)');
  }
  for (const [column, name] of [['clientID','fk_sirvya_conversation_client'], ['coachID','fk_sirvya_conversation_coach']]) {
    if (!names.has(name)) {
      await db.query(`ALTER TABLE conversations ADD CONSTRAINT ${name} FOREIGN KEY (${column}) REFERENCES users(id) ON DELETE CASCADE`);
    }
  }

  const messages = await columnsFor('messages');
  await addMissing('messages', messages, 'mediaUrl', 'TEXT NULL');
  await addMissing('messages', messages, 'mediaType', "ENUM('text','image','audio') NOT NULL DEFAULT 'text'");
  await addMissing('messages', messages, 'mediaExpired', 'TINYINT(1) NOT NULL DEFAULT 0');
  if (messages.get('body')?.Null === 'NO') await db.query('ALTER TABLE messages MODIFY COLUMN body TEXT NULL');

  const blocks = await columnsFor('coachavailabilityblocks');
  await addMissing('coachavailabilityblocks', blocks, 'blockedDate', 'DATE NULL');
  await addMissing('coachavailabilityblocks', blocks, 'note', 'TEXT NULL');
  if (blocks.get('dayOfWeek')?.Null === 'NO') {
    await db.query(`ALTER TABLE coachavailabilityblocks MODIFY COLUMN dayOfWeek ${blocks.get('dayOfWeek').Type} NULL`);
  }

  // Reuse the latest main branch's category/favorite definitions and seeds.
  // Its raw ALTER is not repeatable, so apply that part only when missing.
  const migration = await readFile(new URL('../migrations/2026_categories_favorites.sql', import.meta.url), 'utf8');
  const statements = migration.replace(/^--.*$/gm, '').split(';').map(sql=>sql.trim()).filter(Boolean);
  for (const sql of statements) {
    if (/^(CREATE TABLE|INSERT IGNORE)/i.test(sql)) await db.query(sql);
  }
  if (await addMissing('coachprofiles', profiles, 'categoryID', 'INT UNSIGNED NULL')) {
    await db.query('ALTER TABLE coachprofiles ADD CONSTRAINT fk_coachprofiles_categoryID FOREIGN KEY (categoryID) REFERENCES categories(id) ON DELETE SET NULL');
    for (const sql of statements) if (/^UPDATE/i.test(sql)) await db.query(sql);
  }
}
