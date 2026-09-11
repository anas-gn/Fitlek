ALTER TABLE `users`
  MODIFY `passwordHash` varchar(255) COLLATE utf8mb4_unicode_ci NULL,
  MODIFY `gender` enum('Male','Female','Other') COLLATE utf8mb4_unicode_ci NULL;

ALTER TABLE `users`
  ADD COLUMN `googleId` varchar(255) COLLATE utf8mb4_unicode_ci NULL AFTER `passwordHash`,
  ADD COLUMN `authProvider` enum('local','google') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'local' AFTER `googleId`;

ALTER TABLE `users`
  ADD UNIQUE KEY `idx_users_googleId` (`googleId`);
