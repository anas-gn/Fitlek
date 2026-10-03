// Merge a local legacy SIRVYA backup without executing its SQL or replacing data.
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';

export const RESTORE_TABLES = [
  'users', 'advisorprofiles', 'coachprofiles', 'managerprofiles', 'coachclients',
  'coachavailabilityblocks', 'coachreviews', 'imageadvisor', 'conversations',
  'messages', 'reservations', 'invitations', 'weighthistory', 'user_blocks', 'bans',
];

// mysqldump emits each data INSERT on one line, using escaped string literals.
// Only literals are accepted: functions, subqueries and arbitrary SQL are rejected.
export function parseValues(text) {
  let position = 0;
  const rows = [];
  const spaces = () => {while (/\s/.test(text[position] ?? '') && position < text.length) position++;};
  const expect = character => {
    spaces();
    if (text[position++] !== character) throw new Error('Invalid backup tuple syntax');
  };
  while (position < text.length) {
    spaces();
    if (position === text.length) break;
    expect('(');
    const row = [];
    while (true) {
      spaces();
      let value;
      if (text[position] === "'") {
        position++;
        value = '';
        let closed = false;
        while (position < text.length) {
          const character = text[position++];
          if (character === '\\') {
            if (position === text.length) throw new Error('Incomplete backup escape');
            const escaped = text[position++];
            const escapes = {'0':'\0', n:'\n', r:'\r', t:'\t', b:'\b', Z:'\x1a'};
            value += escapes[escaped] ?? escaped;
          } else if (character === "'") {
            if (text[position] === "'") {value += "'"; position++;}
            else {closed = true; break;}
          } else value += character;
        }
        if (!closed) throw new Error('Unterminated backup string');
      } else {
        const start = position;
        while (position < text.length && ![',', ')'].includes(text[position])) position++;
        const literal = text.slice(start, position).trim();
        if (/^NULL$/i.test(literal)) value = null;
        else if (/^-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?$/.test(literal)) {
          value = Number(literal);
          if (!Number.isFinite(value) || (/^-?\d+$/.test(literal) && !Number.isSafeInteger(value))) {
            throw new Error('Unsafe backup numeric literal');
          }
        } else throw new Error('Unsupported backup literal');
      }
      row.push(value);
      spaces();
      if (text[position] === ')') {position++; break;}
      expect(',');
    }
    rows.push(row);
    spaces();
    if (position === text.length) break;
    expect(',');
  }
  return rows;
}

export function parseDump(bytes) {
  const encoding = bytes[0] === 0xff && bytes[1] === 0xfe ? 'utf16le' : 'utf8';
  const sql = bytes.toString(encoding).replace(/^\uFEFF/, '');
  const tables = new Map();
  for (const match of sql.matchAll(/CREATE TABLE `([a-zA-Z0-9_]+)`\s*\(([\s\S]*?)\) ENGINE=/g)) {
    if (!RESTORE_TABLES.includes(match[1])) continue;
    tables.set(match[1], {columns:[...match[2].matchAll(/^\s*`([^`]+)`/gm)].map(c => c[1]), rows:[]});
  }
  for (const match of sql.matchAll(/^INSERT INTO `([a-zA-Z0-9_]+)` VALUES (.*);\s*$/gm)) {
    const table = tables.get(match[1]);
    if (!table) continue;
    for (const values of parseValues(match[2])) {
      if (values.length !== table.columns.length) throw new Error(`Backup column mismatch: ${match[1]}`);
      table.rows.push(Object.fromEntries(table.columns.map((column, i) => [column, values[i]])));
    }
  }
  if (!tables.get('users')?.rows.length) throw new Error('Backup contains no SIRVYA users');
  return tables;
}

const naturalKeys = {
  users:['email'], advisorprofiles:['userID'], coachprofiles:['userID'],
  managerprofiles:['userId'], coachclients:['coachID','clientID'],
  conversations:['clientID','coachID'], user_blocks:['blockerID','blockedID'],
};

export function adaptLegacyRow(name, original) {
  const row = {...original};
  delete row.id;
  if (name === 'users') {
    row.fcmToken = null;
    if (row.authProvider === 'email') row.authProvider = 'local';
  }
  if (name === 'coachprofiles' && typeof row.price === 'string') {
    const amount = row.price.trim().match(/^(\d+(?:[.,]\d{1,2})?)\s*(?:MAD|DHS?|DIRHAMS?)?$/i);
    if (!amount) throw new Error('Unsupported legacy coach price format');
    row.price = Number(amount[1].replace(',', '.'));
  }
  if (name === 'coachclients' && row.createdAt !== undefined) row.assignedAt = row.createdAt;
  if (name === 'bans' && row.bannedAt !== undefined) row.createdAt = row.bannedAt;
  return row;
}

export async function mergeLocalData(connection, tables) {
  const [columns] = await connection.query(`SELECT TABLE_NAME,COLUMN_NAME FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA=DATABASE() ORDER BY TABLE_NAME,ORDINAL_POSITION`);
  const target = new Map();
  for (const column of columns) {
    if (!target.has(column.TABLE_NAME)) target.set(column.TABLE_NAME, new Set());
    target.get(column.TABLE_NAME).add(column.COLUMN_NAME);
  }
  const [foreignKeys] = await connection.query(`SELECT TABLE_NAME,COLUMN_NAME,REFERENCED_TABLE_NAME
    FROM information_schema.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA=DATABASE() AND REFERENCED_TABLE_NAME IS NOT NULL`);
  const mapped = new Map();
  const inserted = {};
  const reused = {};
  for (const name of RESTORE_TABLES) {
    const source = tables.get(name);
    if (!source?.rows.length) continue;
    if (!target.has(name)) throw new Error(`Missing target table: ${name}`);
    const mappings = new Map();
    mapped.set(name, mappings);
    inserted[name] = [];
    reused[name] = 0;
    for (const original of source.rows) {
      const row = adaptLegacyRow(name, original);
      for (const fk of foreignKeys.filter(f => f.TABLE_NAME === name)) {
        if (row[fk.COLUMN_NAME] == null) continue;
        const referenced = mapped.get(fk.REFERENCED_TABLE_NAME)?.get(Number(row[fk.COLUMN_NAME]));
        if (referenced === undefined) throw new Error(`Unresolved backup relationship: ${name}.${fk.COLUMN_NAME}`);
        row[fk.COLUMN_NAME] = referenced;
      }
      if (name === 'conversations') {
        row.user1ID = row.clientID;
        row.user2ID = row.coachID;
        if (row.lastMessageAt == null) {
          row.lastMessageAt = tables.get('messages')?.rows
            .filter(message => Number(message.conversationID) === Number(original.id))
            .map(message => message.createdAt).filter(Boolean).sort().at(-1) ?? row.createdAt;
        }
      }
      const key = naturalKeys[name];
      if (key) {
        const [existing] = await connection.query(
          `SELECT * FROM ?? WHERE ${key.map(column => `\`${column}\` <=> ?`).join(' AND ')} LIMIT 2`,
          [name, ...key.map(column => row[column])]);
        if (existing.length > 1) throw new Error(`Ambiguous existing identity: ${name}`);
        if (existing.length) {
          if (name === 'users' && existing[0].role !== row.role) throw new Error('Existing account role differs from backup');
          mappings.set(Number(original.id), Number(existing[0].id));
          reused[name]++;
          continue;
        }
      }
      const fields = Object.keys(row).filter(column => target.get(name).has(column));
      let result;
      try {
        [result] = await connection.query(
          `INSERT INTO ?? (${fields.map(column => `\`${column}\``).join(',')}) VALUES (${fields.map(() => '?').join(',')})`,
          [name, ...fields.map(column => row[column])]);
      } catch (error) {
        const column = String(error.sqlMessage ?? '').match(/(?:for column|Column) '([a-zA-Z0-9_]+)'/)?.[1];
        throw new Error(`Restore failed at ${name}${column ? '.'+column : ''}: ${error.code ?? 'database error'}`);
      }
      mappings.set(Number(original.id), result.insertId);
      inserted[name].push(result.insertId);
    }
  }
  return {inserted, reused};
}

async function main() {
  const root = fileURLToPath(new URL('../../', import.meta.url));
  const backup = path.join(root, 'workout_tmp/local-backups/sirvya_backup.sql');
  const manifest = path.join(root, 'workout_tmp/local-backups/app-restore-manifest.json');
  const bytes = fs.readFileSync(backup);
  const digest = createHash('sha256').update(bytes).digest('hex');
  const tables = parseDump(bytes);
  const counts = Object.fromEntries([...tables].map(([name, table]) => [name, table.rows.length]));
  const {default: db} = await import('../config/db.js');
  let connection;
  try {
    if (!['localhost','127.0.0.1','::1'].includes(process.env.DB_HOST)) throw new Error('Restore requires local MySQL');
    await db.query('SELECT 1');
    if (!process.argv.includes('--apply')) {
      console.log(JSON.stringify({mode:'preview',sourceRows:counts,excluded:'tokens, OTPs, resets, notifications, deleted accounts and configuration; no SQL executed'}));
      return;
    }
    connection = await db.getConnection();
    if (fs.existsSync(manifest)) {
      const prior = JSON.parse(fs.readFileSync(manifest, 'utf8'));
      if (prior.backupHash !== digest) throw new Error('Existing restore belongs to another backup');
      for (const [name, ids] of Object.entries(prior.inserted)) {
        if (!RESTORE_TABLES.includes(name)) throw new Error('Invalid restore manifest');
        if (!ids.length) continue;
        const [[count]] = await connection.query('SELECT COUNT(*) AS total FROM ?? WHERE id IN (?)', [name, ids]);
        if (Number(count.total) !== ids.length) throw new Error('Prior restore is incomplete; inspect before rerunning');
      }
      console.log(JSON.stringify({mode:'already-restored',inserted:Object.fromEntries(Object.entries(prior.inserted).map(([name, ids]) => [name,ids.length]))}));
      return;
    }
    await connection.beginTransaction();
    const result = await mergeLocalData(connection, tables);
    // Write the non-sensitive ID manifest before commit; a failed commit removes it.
    fs.writeFileSync(manifest, JSON.stringify({backupHash:digest,...result}, null, 2)+'\n', {flag:'wx'});
    try {await connection.commit();}
    catch (error) {fs.unlinkSync(manifest); throw error;}
    console.log(JSON.stringify({mode:'restored',inserted:Object.fromEntries(Object.entries(result.inserted).map(([name, ids]) => [name,ids.length])),reused:result.reused}));
  } catch (error) {
    if (connection) await connection.rollback();
    // Database errors can contain personal values; print only their code.
    console.error(error.code ? `Restore failed: ${error.code}` : error.message);
    process.exitCode = 1;
  } finally {connection?.release(); await db.end();}
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) await main();
