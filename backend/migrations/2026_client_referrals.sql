CREATE TABLE IF NOT EXISTS clientreferrals (
 id INT AUTO_INCREMENT PRIMARY KEY,
 inviterCoachID BIGINT UNSIGNED NOT NULL,
 invitedClientID BIGINT UNSIGNED NOT NULL,
 invitationCode VARCHAR(64) NOT NULL,
 createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 UNIQUE KEY uniq_referred_client (invitedClientID),
 KEY idx_clientref_inviter (inviterCoachID),
 FOREIGN KEY (inviterCoachID) REFERENCES users(id) ON DELETE CASCADE,
 FOREIGN KEY (invitedClientID) REFERENCES users(id) ON DELETE CASCADE
);