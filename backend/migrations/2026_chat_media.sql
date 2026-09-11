ALTER TABLE messages
MODIFY COLUMN `body` text COLLATE utf8mb4_unicode_ci,
ADD COLUMN `mediaUrl` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL AFTER `body`,
ADD COLUMN `mediaType` enum('text','image','audio') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'text' AFTER `mediaUrl`,
ADD COLUMN `mediaExpired` tinyint(1) NOT NULL DEFAULT '0' AFTER `mediaType`;
