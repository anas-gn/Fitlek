import pool from './db.js';

// Idempotently ensures the Coach-to-Coach referral table exists.
// Additive only — never drops or alters existing tables/columns.
// See backend/migrations/2026_coach_referrals.sql for rationale.
export async function ensureReferralSchema() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS coachreferrals (
      id INT AUTO_INCREMENT PRIMARY KEY,
      inviterCoachID BIGINT UNSIGNED NOT NULL,
      invitedCoachID BIGINT UNSIGNED NOT NULL,
      invitationCode VARCHAR(64) NOT NULL,
      pointsAwarded INT NOT NULL DEFAULT 20,
      createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      UNIQUE KEY uniq_invited_coach (invitedCoachID),
      KEY idx_inviter (inviterCoachID),
      CONSTRAINT fk_coachref_inviter FOREIGN KEY (inviterCoachID) REFERENCES users(id) ON DELETE CASCADE,
      CONSTRAINT fk_coachref_invited FOREIGN KEY (invitedCoachID) REFERENCES users(id) ON DELETE CASCADE
    )
  `);
}

// Idempotently adds the Coach profile editor fields to coachprofiles.
// Additive only — never drops data and
// safe to run on every startup. See backend/migrations/2026_coach_profile_fields.sql.
export async function ensureCoachProfileColumns() {
  const [cols] = await pool.query(
    `SELECT COLUMN_NAME FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'coachprofiles'
        AND COLUMN_NAME IN (
          'specialty', 'experience', 'professionalTitle', 'certifications',
          'specialties', 'publicProfile', 'directMessaging'
        )`
  );
  const existing = new Set(cols.map((c) => c.COLUMN_NAME));
  if (!existing.has('specialty')) {
    await pool.query(
      `ALTER TABLE coachprofiles ADD COLUMN specialty VARCHAR(150) NOT NULL DEFAULT '' AFTER bio`
    );
  }
  if (!existing.has('experience')) {
    await pool.query(
      `ALTER TABLE coachprofiles ADD COLUMN experience VARCHAR(200) NOT NULL DEFAULT '' AFTER specialty`
    );
  }
  if (!existing.has('professionalTitle')) {
    await pool.query(
      `ALTER TABLE coachprofiles ADD COLUMN professionalTitle VARCHAR(150) NOT NULL DEFAULT '' AFTER experience`
    );
  }
  if (!existing.has('certifications')) {
    await pool.query(
      `ALTER TABLE coachprofiles ADD COLUMN certifications TEXT NULL AFTER professionalTitle`
    );
  }
  if (!existing.has('specialties')) {
    await pool.query(
      `ALTER TABLE coachprofiles ADD COLUMN specialties TEXT NULL AFTER certifications`
    );
  }
  if (!existing.has('publicProfile')) {
    await pool.query(
      `ALTER TABLE coachprofiles ADD COLUMN publicProfile TINYINT(1) NOT NULL DEFAULT 1 AFTER specialties`
    );
  }
  if (!existing.has('directMessaging')) {
    await pool.query(
      `ALTER TABLE coachprofiles ADD COLUMN directMessaging TINYINT(1) NOT NULL DEFAULT 1 AFTER publicProfile`
    );
  }

  // Price is no longer used in the coach app (subscription later).
  // Column type in this DB is TEXT NOT NULL — make it nullable so profile
  // edits never fail with: Column 'price' cannot be null.
  const [priceCols] = await pool.query(
    `SELECT IS_NULLABLE, DATA_TYPE, COLUMN_TYPE
       FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'coachprofiles'
        AND COLUMN_NAME = 'price'
      LIMIT 1`
  );
  if (priceCols.length && priceCols[0].IS_NULLABLE === 'NO') {
    const dataType = String(priceCols[0].DATA_TYPE || '').toLowerCase();
    if (dataType === 'text' || dataType === 'varchar' || dataType === 'char') {
      await pool.query(`ALTER TABLE coachprofiles MODIFY COLUMN price TEXT NULL`);
    } else {
      await pool.query(
        `ALTER TABLE coachprofiles MODIFY COLUMN price DECIMAL(10,2) NULL DEFAULT NULL`
      );
    }
  }
}

// Durable in-app notifications (messages, reservations, session reminders).
// uniqueKey enforces once-only creation across retries / repeated jobs.
// Additive only — see backend/migrations/2026_notifications.sql.
export async function ensureNotificationSchema() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS notifications (
      id INT AUTO_INCREMENT PRIMARY KEY,
      recipientUserID BIGINT UNSIGNED NOT NULL,
      type VARCHAR(40) NOT NULL,
      title VARCHAR(120) NOT NULL,
      body VARCHAR(255) NOT NULL,
      relatedEntityID BIGINT UNSIGNED NULL,
      actorName VARCHAR(120) NULL,
      actorAvatar TEXT NULL,
      isRead TINYINT(1) NOT NULL DEFAULT 0,
      uniqueKey VARCHAR(160) NOT NULL,
      createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      UNIQUE KEY uniq_notif_key (uniqueKey),
      KEY idx_recipient_read (recipientUserID, isRead),
      KEY idx_recipient_created (recipientUserID, createdAt),
      CONSTRAINT fk_notif_recipient FOREIGN KEY (recipientUserID) REFERENCES users(id) ON DELETE CASCADE
    )
  `);
}
