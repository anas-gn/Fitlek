-- Coach-to-Coach referral tracking.
--
-- Why this table is necessary:
-- The existing `invitations` table models Coach-to-CLIENT relationships
-- (coachID + invitedUserID/client, accept/decline lifecycle). It has no way to
-- durably prove that a newly registered COACH has already produced a referral
-- reward, so reusing it would both mix the two concepts and allow duplicate
-- rewards. This dedicated table records one row per referred coach and enforces
-- once-only rewards via UNIQUE(invitedCoachID).
--
-- It does NOT drop or alter any existing table/column. The +20 points / +1
-- invitation are still applied to the existing coachprofiles.earnedPoints /
-- coachprofiles.totalInvitations columns so Dashboard/Profile/Invitations stay
-- in sync (source of truth unchanged).

-- NOTE: users.id is BIGINT UNSIGNED, so all FK columns referencing it must
-- also be BIGINT UNSIGNED (MySQL requires exact type + signedness match).
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
);
