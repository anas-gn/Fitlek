-- Durable in-app notifications for Coaches (and, structurally, any user).
--
-- Why this table is necessary:
-- The project has no notification table. Chat messages and reservations are
-- their own records and must not be overloaded as notifications. This dedicated
-- table stores one row per delivered notification with a durable `uniqueKey`
-- that guarantees once-only creation across retries, lost responses, backend
-- restarts, and repeated reminder passes (there is no cron/socket in this
-- project, so upcoming-session reminders are generated on-demand when the coach
-- fetches notifications, guarded by uniqueKey).
--
-- Additive only. Does not drop or alter any existing table/column.
--
-- Example unique keys:
--   message:<messageID>:coach:<coachID>
--   reservation:<reservationID>:coach:<coachID>
--   session-reminder:<reservationID>:60m:coach:<coachID>

-- NOTE: users.id is BIGINT UNSIGNED, so recipientUserID (FK) must also be
-- BIGINT UNSIGNED (MySQL requires exact type + signedness match).
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
);
