-- Coach professional profile editor fields.
-- Additive, idempotent-friendly migration. These columns feed the redesigned
-- Coach Profile screen. Run once; the app also ensures them at startup via
-- ensureCoachProfileColumns() in backend/config/ensureSchema.js.
--
-- Note: `ADD COLUMN IF NOT EXISTS` is supported by MariaDB and MySQL 8.0.29+.
-- On older MySQL, rely on the startup ensurer (information_schema check) instead.

ALTER TABLE coachprofiles
  ADD COLUMN IF NOT EXISTS specialty  VARCHAR(150) NOT NULL DEFAULT '' AFTER bio,
  ADD COLUMN IF NOT EXISTS experience VARCHAR(200) NOT NULL DEFAULT '' AFTER specialty,
  ADD COLUMN IF NOT EXISTS professionalTitle VARCHAR(150) NOT NULL DEFAULT '' AFTER experience,
  ADD COLUMN IF NOT EXISTS certifications TEXT NULL AFTER professionalTitle,
  ADD COLUMN IF NOT EXISTS specialties TEXT NULL AFTER certifications,
  ADD COLUMN IF NOT EXISTS publicProfile TINYINT(1) NOT NULL DEFAULT 1 AFTER specialties,
  ADD COLUMN IF NOT EXISTS directMessaging TINYINT(1) NOT NULL DEFAULT 1 AFTER publicProfile;
