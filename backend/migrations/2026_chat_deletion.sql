-- Run the ALTER only if deletedAt is absent. Startup performs this check automatically.
-- ALTER TABLE messages ADD COLUMN deletedAt DATETIME NULL;
CREATE TABLE IF NOT EXISTS chat_hidden_messages (
 messageID BIGINT UNSIGNED NOT NULL,userID BIGINT UNSIGNED NOT NULL,
 PRIMARY KEY(messageID,userID),
 FOREIGN KEY(messageID) REFERENCES messages(id) ON DELETE CASCADE,
 FOREIGN KEY(userID) REFERENCES users(id) ON DELETE CASCADE);
