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
