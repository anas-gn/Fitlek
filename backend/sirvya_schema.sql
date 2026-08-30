-- SIRVYA MASTER DATABASE SCHEMA DUMP
-- Compatible with MySQL 5.7+ / MySQL 8.0+ / MariaDB / phpMyAdmin / Aiven / Railway / PlanetScale

SET FOREIGN_KEY_CHECKS = 0;

-- --------------------------------------------------------
-- Table structure for `users`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `firstName` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `lastName` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phoneNumber` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `passwordHash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `role` enum('client','coach','admin','manager','advisor') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'client',
  `gender` enum('Male','Female','Other') COLLATE utf8mb4_unicode_ci NOT NULL,
  `height` decimal(5,2) DEFAULT NULL,
  `avatarUrl` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `isPremium` tinyint(1) NOT NULL DEFAULT '0',
  `isApproved` tinyint(1) NOT NULL DEFAULT '0',
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `termsAccepted` tinyint(1) NOT NULL DEFAULT '0',
  `termsAcceptedAt` timestamp NULL DEFAULT NULL,
  `googleId` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `uniq_users_phone` (`phoneNumber`),
  KEY `idx_users_email` (`email`),
  KEY `idx_users_role` (`role`),
  KEY `idx_users_isApproved` (`isApproved`)
) ENGINE=InnoDB AUTO_INCREMENT=84 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table structure for `advisorprofiles`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `advisorprofiles`;
CREATE TABLE `advisorprofiles` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `userID` bigint unsigned NOT NULL,
  `bio` text COLLATE utf8mb4_unicode_ci,
  `specialty` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pricing` decimal(10,2) DEFAULT NULL,
  `location` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `companyName` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `descriptionCompany` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `isVerified` tinyint(1) NOT NULL DEFAULT '0',
  `invitationCode` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `userID` (`userID`),
  UNIQUE KEY `invitationCode` (`invitationCode`),
  KEY `idx_advisorProfiles_userID` (`userID`),
  KEY `idx_advisorProfiles_company` (`companyName`),
  CONSTRAINT `fk_advisorProfiles_userID` FOREIGN KEY (`userID`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table structure for `authtokens`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `authtokens`;
CREATE TABLE `authtokens` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `userID` bigint unsigned NOT NULL,
  `refreshToken` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `deviceInfo` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `expiresAt` datetime NOT NULL,
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `revokedAt` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `refreshToken` (`refreshToken`),
  KEY `fk_authTokens_userID` (`userID`),
  KEY `idx_authTokens_exp` (`expiresAt`),
  CONSTRAINT `fk_authTokens_userID` FOREIGN KEY (`userID`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table structure for `bans`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `bans`;
CREATE TABLE `bans` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `userID` bigint unsigned NOT NULL,
  `bannedBy` bigint unsigned NOT NULL,
  `banType` enum('temporary','permanent') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'temporary',
  `reason` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `expiresAt` datetime DEFAULT NULL,
  `isActive` tinyint(1) NOT NULL DEFAULT '1',
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_bans_userID` (`userID`),
  KEY `fk_bans_bannedBy` (`bannedBy`),
  KEY `idx_bans_active` (`userID`,`isActive`),
  CONSTRAINT `fk_bans_bannedBy` FOREIGN KEY (`bannedBy`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_bans_userID` FOREIGN KEY (`userID`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table structure for `coachavailabilityblocks`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `coachavailabilityblocks`;
CREATE TABLE `coachavailabilityblocks` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `coachID` bigint unsigned NOT NULL,
  `dayOfWeek` enum('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday') COLLATE utf8mb4_unicode_ci NOT NULL,
  `startTime` time NOT NULL,
  `endTime` time NOT NULL,
  `isRecurring` tinyint(1) NOT NULL DEFAULT '1',
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_cab_coach` (`coachID`),
  KEY `idx_cab_day_time` (`coachID`,`dayOfWeek`,`startTime`,`endTime`),
  CONSTRAINT `fk_cab_coach` FOREIGN KEY (`coachID`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table structure for `coachclients`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `coachclients`;
CREATE TABLE `coachclients` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `coachID` bigint unsigned NOT NULL,
  `clientID` bigint unsigned NOT NULL,
  `assignedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `notes` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_coach_client` (`coachID`,`clientID`),
  KEY `idx_coachClients_coachID` (`coachID`),
  KEY `idx_coachClients_clientID` (`clientID`),
  CONSTRAINT `fk_coachClients_clientID` FOREIGN KEY (`clientID`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_coachClients_coachID` FOREIGN KEY (`coachID`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table structure for `coachprofiles`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `coachprofiles`;
CREATE TABLE `coachprofiles` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `userID` bigint unsigned NOT NULL,
  `bio` text COLLATE utf8mb4_unicode_ci,
  `specialty` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pricing` decimal(10,2) DEFAULT NULL,
  `location` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `instagramPage` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `certificateUrl` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `invitationCode` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `advisorID` bigint unsigned DEFAULT NULL,
  `earnedPoints` int unsigned NOT NULL DEFAULT '0',
  `totalInvitations` int unsigned NOT NULL DEFAULT '0',
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `userID` (`userID`),
  UNIQUE KEY `invitationCode` (`invitationCode`),
  KEY `idx_coachProfiles_userID` (`userID`),
  KEY `idx_coachProfiles_specialty` (`specialty`),
  KEY `fk_coachprofiles_advisorID` (`advisorID`),
  CONSTRAINT `fk_coachprofiles_advisorID` FOREIGN KEY (`advisorID`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_coachProfiles_userID` FOREIGN KEY (`userID`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=47 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table structure for `coachreferrals`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `coachreferrals`;
CREATE TABLE `coachreferrals` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `inviterCoachID` bigint unsigned NOT NULL,
  `invitedCoachID` bigint unsigned NOT NULL,
  `invitationCode` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `pointsAwarded` int unsigned NOT NULL DEFAULT '40',
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_invitedCoachID` (`invitedCoachID`),
  KEY `idx_inviter` (`inviterCoachID`),
  CONSTRAINT `fk_coachref_invited` FOREIGN KEY (`invitedCoachID`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_coachref_inviter` FOREIGN KEY (`inviterCoachID`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table structure for `coachreviews`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `coachreviews`;
CREATE TABLE `coachreviews` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `coachID` bigint unsigned NOT NULL,
  `clientID` bigint unsigned NOT NULL,
  `rating` tinyint unsigned NOT NULL,
  `comment` text COLLATE utf8mb4_unicode_ci,
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_coach_client_review` (`coachID`,`clientID`),
  KEY `idx_coachReviews_coachID` (`coachID`),
  KEY `idx_coachReviews_clientID` (`clientID`),
  CONSTRAINT `fk_coachReviews_clientID` FOREIGN KEY (`clientID`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_coachReviews_coachID` FOREIGN KEY (`coachID`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table structure for `conversations`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `conversations`;
CREATE TABLE `conversations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user1ID` bigint unsigned NOT NULL,
  `user2ID` bigint unsigned NOT NULL,
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_conversation_pair` (`user1ID`,`user2ID`),
  KEY `fk_conversations_user2ID` (`user2ID`),
  CONSTRAINT `fk_conversations_user1ID` FOREIGN KEY (`user1ID`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_conversations_user2ID` FOREIGN KEY (`user2ID`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table structure for `gymreviews`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `gymreviews`;
CREATE TABLE `gymreviews` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `advisorID` bigint unsigned NOT NULL,
  `clientID` bigint unsigned NOT NULL,
  `rating` tinyint unsigned NOT NULL,
  `comment` text,
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_gymReview` (`advisorID`,`clientID`),
  KEY `idx_gymReviews_advisorID` (`advisorID`),
  KEY `idx_gymReviews_clientID` (`clientID`),
  CONSTRAINT `fk_gymReviews_advisorID` FOREIGN KEY (`advisorID`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_gymReviews_clientID` FOREIGN KEY (`clientID`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

-- --------------------------------------------------------
-- Table structure for `imageadvisor`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `imageadvisor`;
CREATE TABLE `imageadvisor` (
  `id` int NOT NULL AUTO_INCREMENT,
  `idAdvisor` int NOT NULL,
  `UrlImage` varchar(600) COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for `invitations`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `invitations`;
CREATE TABLE `invitations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `coachID` bigint unsigned NOT NULL,
  `invitedUserID` bigint unsigned NOT NULL,
  `pointsEarned` int unsigned NOT NULL DEFAULT '0',
  `status` enum('pending','accepted','refused') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `clickedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `respondedAt` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_invitations_coachID` (`coachID`),
  KEY `fk_invitations_invitedUserID` (`invitedUserID`),
  CONSTRAINT `fk_invitations_coachID` FOREIGN KEY (`coachID`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_invitations_invitedUserID` FOREIGN KEY (`invitedUserID`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table structure for `managerprofiles`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `managerprofiles`;
CREATE TABLE `managerprofiles` (
  `id` int NOT NULL AUTO_INCREMENT,
  `userId` int NOT NULL,
  `ville` varchar(200) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8;

-- --------------------------------------------------------
-- Table structure for `messages`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `messages`;
CREATE TABLE `messages` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `conversationID` bigint unsigned NOT NULL,
  `senderID` bigint unsigned NOT NULL,
  `body` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `isRead` tinyint(1) NOT NULL DEFAULT '0',
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_messages_senderID` (`senderID`),
  KEY `idx_messages_readStatus` (`conversationID`,`isRead`),
  CONSTRAINT `fk_messages_conversationID` FOREIGN KEY (`conversationID`) REFERENCES `conversations` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_messages_senderID` FOREIGN KEY (`senderID`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table structure for `notifications`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `notifications`;
CREATE TABLE `notifications` (
  `id` int NOT NULL AUTO_INCREMENT,
  `recipientUserID` bigint unsigned NOT NULL,
  `type` varchar(40) NOT NULL,
  `title` varchar(120) NOT NULL,
  `body` varchar(255) NOT NULL,
  `relatedEntityID` bigint unsigned DEFAULT NULL,
  `actorName` varchar(120) DEFAULT NULL,
  `actorAvatar` text,
  `isRead` tinyint(1) NOT NULL DEFAULT '0',
  `uniqueKey` varchar(160) NOT NULL,
  `createdAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_notif_key` (`uniqueKey`),
  KEY `idx_recipient_read` (`recipientUserID`,`isRead`),
  KEY `idx_recipient_created` (`recipientUserID`,`createdAt`),
  CONSTRAINT `fk_notif_recipient` FOREIGN KEY (`recipientUserID`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8;

-- --------------------------------------------------------
-- Table structure for `otp_verifications`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `otp_verifications`;
CREATE TABLE `otp_verifications` (
  `id` int NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL,
  `otp` varchar(10) NOT NULL,
  `type` varchar(50) NOT NULL DEFAULT 'signup',
  `expiresAt` timestamp NOT NULL,
  `isVerified` tinyint(1) NOT NULL DEFAULT '0',
  `createdAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_email_type` (`email`,`type`),
  KEY `idx_expires` (`expiresAt`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;

-- --------------------------------------------------------
-- Table structure for `passwordresettokens`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `passwordresettokens`;
CREATE TABLE `passwordresettokens` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `userID` bigint unsigned NOT NULL,
  `token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expiresAt` datetime NOT NULL,
  `usedAt` datetime DEFAULT NULL,
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `token` (`token`),
  KEY `fk_passwordResetTokens_userID` (`userID`),
  KEY `idx_passwordResetTokens_exp` (`expiresAt`),
  CONSTRAINT `fk_passwordResetTokens_userID` FOREIGN KEY (`userID`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table structure for `reservations`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `reservations`;
CREATE TABLE `reservations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `clientID` bigint unsigned NOT NULL,
  `coachID` bigint unsigned NOT NULL,
  `reservedDate` date NOT NULL,
  `reservedTime` time NOT NULL,
  `status` enum('pending','confirmed','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `rejectionReason` text COLLATE utf8mb4_unicode_ci,
  `cancellationReason` text COLLATE utf8mb4_unicode_ci,
  `cancelledBy` enum('coach','manager') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `location` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `price` decimal(10,2) NOT NULL DEFAULT '0.00',
  `companyName` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_reservations_clientID` (`clientID`),
  KEY `idx_reservations_coachID` (`coachID`),
  KEY `idx_reservations_date` (`reservedDate`),
  KEY `idx_reservations_status` (`status`),
  CONSTRAINT `fk_reservations_clientID` FOREIGN KEY (`clientID`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_reservations_coachID` FOREIGN KEY (`coachID`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=48 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table structure for `weighthistory`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `weighthistory`;
CREATE TABLE `weighthistory` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `clientID` bigint unsigned NOT NULL,
  `weight` decimal(5,2) NOT NULL,
  `recordedAt` date NOT NULL,
  `note` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_weightHistory_clientID` (`clientID`),
  KEY `idx_weightHistory_date` (`clientID`,`recordedAt`),
  CONSTRAINT `fk_weightHistory_clientID` FOREIGN KEY (`clientID`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=40 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
