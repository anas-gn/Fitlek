export async function ensureAuthSecuritySchema(db) {
  const [columns] = await db.query("SHOW COLUMNS FROM users LIKE 'tokenVersion'");
  if (!columns.length) await db.query('ALTER TABLE users ADD COLUMN tokenVersion INT UNSIGNED NOT NULL DEFAULT 0');
  await db.query(`CREATE TABLE IF NOT EXISTS password_reset_challenges (
    id CHAR(36) PRIMARY KEY, userID BIGINT UNSIGNED NOT NULL, email VARCHAR(255) NOT NULL,
    codeHash CHAR(64) NOT NULL, expiresAt DATETIME NOT NULL,
    attempts INT NOT NULL DEFAULT 0, verifiedAt DATETIME NULL,
    capabilityHash CHAR(64) NULL, capabilityExpiresAt DATETIME NULL,
    consumedAt DATETIME NULL, createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_reset_email (email, createdAt), INDEX idx_reset_user (userID),
    FOREIGN KEY (userID) REFERENCES users(id) ON DELETE CASCADE
  ) ENGINE=InnoDB`);
}
