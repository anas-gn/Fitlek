// Repair older/partially migrated SIRVYA databases without replacing accounts.
export async function ensureGoogleAuthSchema(db) {
  const [columns] = await db.query(`
    SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLLATION_NAME
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users'
      AND COLUMN_NAME IN ('passwordHash', 'gender', 'googleId', 'authProvider')
  `);
  const existing = new Map(columns.map(column => [column.COLUMN_NAME, column]));

  // Google does not supply a local password or gender. Preserve each column's
  // existing type/collation and values; only relax nullability.
  for (const name of ['passwordHash', 'gender']) {
    const column = existing.get(name);
    if (!column) throw new Error(`Google auth schema requires users.${name}`);
    if (column.IS_NULLABLE === 'NO') {
      const collation = column.COLLATION_NAME ? ` COLLATE ${column.COLLATION_NAME}` : '';
      await db.query(`ALTER TABLE users MODIFY COLUMN \`${name}\` ${column.COLUMN_TYPE}${collation} NULL`);
    }
  }
  if (!existing.has('googleId')) {
    await db.query('ALTER TABLE users ADD COLUMN googleId VARCHAR(255) COLLATE utf8mb4_unicode_ci NULL AFTER passwordHash');
  }
  const provider = existing.get('authProvider');
  if (!provider) {
    await db.query("ALTER TABLE users ADD COLUMN authProvider ENUM('local','google','both') NOT NULL DEFAULT 'local' AFTER googleId");
  } else if (provider.COLUMN_TYPE.startsWith('enum(') && !provider.COLUMN_TYPE.includes("'both'")) {
    // Append rather than replace to retain any provider values already in use.
    const expandedType = provider.COLUMN_TYPE.slice(0, -1) + ",'both')";
    await db.query(`ALTER TABLE users MODIFY COLUMN authProvider ${expandedType} NOT NULL DEFAULT 'local'`);
  }

  const [indexes] = await db.query('SHOW INDEX FROM users');
  const groups = new Map();
  for (const index of indexes) {
    if (!groups.has(index.Key_name)) groups.set(index.Key_name, []);
    groups.get(index.Key_name).push(index);
  }
  const hasUniqueGoogleId = [...groups.values()].some(group =>
    group.length === 1 && group[0].Column_name === 'googleId' && group[0].Non_unique === 0);
  if (!hasUniqueGoogleId) {
    await db.query('ALTER TABLE users ADD UNIQUE KEY idx_users_googleId (googleId)');
  }
}
