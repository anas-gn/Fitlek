-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Hôte : 127.0.0.1:3308
-- Généré le : mer. 10 juin 2026 à 15:32
-- Version du serveur : 10.4.32-MariaDB
-- Version de PHP : 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `fitlekdb`
--

-- --------------------------------------------------------

--
-- Structure de la table `advisorprofiles`
--

CREATE TABLE `advisorprofiles` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `userID` bigint(20) UNSIGNED NOT NULL,
  `specialty` varchar(100) NOT NULL,
  `createdAt` datetime NOT NULL DEFAULT current_timestamp(),
  `updatedAt` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `authtokens`
--

CREATE TABLE `authtokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `userID` bigint(20) UNSIGNED NOT NULL,
  `refreshToken` varchar(512) NOT NULL,
  `deviceInfo` varchar(255) DEFAULT NULL,
  `expiresAt` datetime NOT NULL,
  `revokedAt` datetime DEFAULT NULL,
  `createdAt` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `bans`
--

CREATE TABLE `bans` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `userID` bigint(20) UNSIGNED NOT NULL,
  `bannedBy` bigint(20) UNSIGNED NOT NULL,
  `banType` enum('temporary','permanent') NOT NULL,
  `reason` text NOT NULL,
  `bannedAt` datetime NOT NULL DEFAULT current_timestamp(),
  `expiresAt` datetime DEFAULT NULL,
  `isActive` tinyint(1) NOT NULL DEFAULT 1,
  `liftedAt` datetime DEFAULT NULL,
  `liftedBy` bigint(20) UNSIGNED DEFAULT NULL
) ;

-- --------------------------------------------------------

--
-- Structure de la table `coachavailabilityblocks`
--

CREATE TABLE `coachavailabilityblocks` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `coachID` bigint(20) UNSIGNED NOT NULL,
  `blockedDate` date NOT NULL,
  `startTime` time NOT NULL,
  `endTime` time NOT NULL,
  `note` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL DEFAULT current_timestamp()
) ;

-- --------------------------------------------------------

--
-- Structure de la table `coachclients`
--

CREATE TABLE `coachclients` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `coachID` bigint(20) UNSIGNED NOT NULL,
  `clientID` bigint(20) UNSIGNED NOT NULL,
  `createdAt` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `coachprofiles`
--

CREATE TABLE `coachprofiles` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `userID` bigint(20) UNSIGNED NOT NULL,
  `advisorID` bigint(20) UNSIGNED DEFAULT NULL,
  `bio` text NOT NULL,
  `instagramPage` varchar(100) NOT NULL,
  `certificateUrl` varchar(500) NOT NULL,
  `invitationCode` varchar(30) NOT NULL,
  `totalInvitations` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `earnedPoints` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `createdAt` datetime NOT NULL DEFAULT current_timestamp(),
  `updatedAt` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `coachreviews`
--

CREATE TABLE `coachreviews` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `coachID` bigint(20) UNSIGNED NOT NULL,
  `clientID` bigint(20) UNSIGNED NOT NULL,
  `rating` tinyint(3) UNSIGNED NOT NULL,
  `comment` text DEFAULT NULL,
  `createdAt` datetime NOT NULL DEFAULT current_timestamp(),
  `updatedAt` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ;

-- --------------------------------------------------------

--
-- Structure de la table `conversations`
--

CREATE TABLE `conversations` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `coachID` bigint(20) UNSIGNED NOT NULL,
  `clientID` bigint(20) UNSIGNED NOT NULL,
  `lastMessageAt` datetime DEFAULT NULL,
  `createdAt` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `gymreviews`
--

CREATE TABLE `gymreviews` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `advisorID` bigint(20) UNSIGNED NOT NULL,
  `clientID` bigint(20) UNSIGNED NOT NULL,
  `rating` tinyint(3) UNSIGNED NOT NULL,
  `comment` text DEFAULT NULL,
  `createdAt` datetime NOT NULL DEFAULT current_timestamp(),
  `updatedAt` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ;

-- --------------------------------------------------------

--
-- Structure de la table `invitations`
--

CREATE TABLE `invitations` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `coachID` bigint(20) UNSIGNED NOT NULL,
  `invitedUserID` bigint(20) UNSIGNED NOT NULL,
  `pointsEarned` int(10) UNSIGNED NOT NULL DEFAULT 20,
  `clickedAt` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `messages`
--

CREATE TABLE `messages` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `conversationID` bigint(20) UNSIGNED NOT NULL,
  `senderID` bigint(20) UNSIGNED NOT NULL,
  `body` text NOT NULL,
  `isRead` tinyint(1) NOT NULL DEFAULT 0,
  `createdAt` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `passwordresettokens`
--

CREATE TABLE `passwordresettokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `userID` bigint(20) UNSIGNED NOT NULL,
  `token` varchar(255) NOT NULL,
  `expiresAt` datetime NOT NULL,
  `usedAt` datetime DEFAULT NULL,
  `createdAt` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `reservations`
--

CREATE TABLE `reservations` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `clientID` bigint(20) UNSIGNED NOT NULL,
  `coachID` bigint(20) UNSIGNED NOT NULL,
  `reservedDate` date NOT NULL,
  `reservedTime` time NOT NULL,
  `status` enum('pending','confirmed','cancelled') NOT NULL DEFAULT 'pending',
  `rejectionReason` text DEFAULT NULL,
  `cancellationReason` text DEFAULT NULL,
  `cancelledBy` enum('coach','manager') DEFAULT NULL,
  `createdAt` datetime NOT NULL DEFAULT current_timestamp(),
  `updatedAt` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `location` varchar(255) DEFAULT NULL,
  `price` decimal(10,2) NOT NULL DEFAULT 0.00,
  `companyName` varchar(150) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `firstName` varchar(100) NOT NULL,
  `lastName` varchar(100) NOT NULL,
  `email` varchar(255) NOT NULL,
  `passwordHash` varchar(255) NOT NULL,
  `role` enum('client','coach','admin','manager','advisor') NOT NULL DEFAULT 'client',
  `gender` enum('Male','Female','Other') NOT NULL,
  `avatarUrl` varchar(500) DEFAULT NULL,
  `isPremium` tinyint(1) NOT NULL DEFAULT 0,
  `isApproved` tinyint(1) NOT NULL DEFAULT 0,
  `createdAt` datetime NOT NULL DEFAULT current_timestamp(),
  `updatedAt` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `weighthistory`
--

CREATE TABLE `weighthistory` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `clientID` bigint(20) UNSIGNED NOT NULL,
  `weight` decimal(5,2) NOT NULL,
  `recordedAt` date NOT NULL,
  `note` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `advisorprofiles`
--
ALTER TABLE `advisorprofiles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `userID` (`userID`);

--
-- Index pour la table `authtokens`
--
ALTER TABLE `authtokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `refreshToken` (`refreshToken`),
  ADD KEY `fk_authTokens_userID` (`userID`),
  ADD KEY `idx_authTokens_exp` (`expiresAt`);

--
-- Index pour la table `bans`
--
ALTER TABLE `bans`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_bans_bannedBy` (`bannedBy`),
  ADD KEY `fk_bans_liftedBy` (`liftedBy`),
  ADD KEY `idx_bans_userActive` (`userID`,`isActive`);

--
-- Index pour la table `coachavailabilityblocks`
--
ALTER TABLE `coachavailabilityblocks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_coachAvailabilityBlocks_coachID` (`coachID`);

--
-- Index pour la table `coachclients`
--
ALTER TABLE `coachclients`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_coachClients` (`coachID`,`clientID`),
  ADD KEY `fk_coachClients_clientID` (`clientID`);

--
-- Index pour la table `coachprofiles`
--
ALTER TABLE `coachprofiles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `userID` (`userID`),
  ADD UNIQUE KEY `invitationCode` (`invitationCode`),
  ADD KEY `idx_coachProfiles_advisorID` (`advisorID`),
  ADD KEY `idx_coachProfiles_invCode` (`invitationCode`);

--
-- Index pour la table `coachreviews`
--
ALTER TABLE `coachreviews`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_coachReview` (`coachID`,`clientID`),
  ADD KEY `idx_coachReviews_coachID` (`coachID`),
  ADD KEY `idx_coachReviews_clientID` (`clientID`);

--
-- Index pour la table `conversations`
--
ALTER TABLE `conversations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_conversations` (`coachID`,`clientID`),
  ADD KEY `fk_conversations_clientID` (`clientID`),
  ADD KEY `idx_conversations_lastMsg` (`lastMessageAt`);

--
-- Index pour la table `gymreviews`
--
ALTER TABLE `gymreviews`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_gymReview` (`advisorID`,`clientID`),
  ADD KEY `idx_gymReviews_advisorID` (`advisorID`),
  ADD KEY `idx_gymReviews_clientID` (`clientID`);

--
-- Index pour la table `invitations`
--
ALTER TABLE `invitations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_invitations_coachID` (`coachID`),
  ADD KEY `fk_invitations_invitedUserID` (`invitedUserID`);

--
-- Index pour la table `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_messages_senderID` (`senderID`),
  ADD KEY `idx_messages_readStatus` (`conversationID`,`isRead`);

--
-- Index pour la table `passwordresettokens`
--
ALTER TABLE `passwordresettokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `token` (`token`),
  ADD KEY `fk_passwordResetTokens_userID` (`userID`),
  ADD KEY `idx_passwordResetTokens_exp` (`expiresAt`);

--
-- Index pour la table `reservations`
--
ALTER TABLE `reservations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_reservations_clientID` (`clientID`),
  ADD KEY `idx_reservations_coachID` (`coachID`),
  ADD KEY `idx_reservations_date` (`reservedDate`),
  ADD KEY `idx_reservations_status` (`status`);

--
-- Index pour la table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `idx_users_email` (`email`),
  ADD KEY `idx_users_role` (`role`),
  ADD KEY `idx_users_isApproved` (`isApproved`);

--
-- Index pour la table `weighthistory`
--
ALTER TABLE `weighthistory`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_weightHistory_clientID` (`clientID`),
  ADD KEY `idx_weightHistory_date` (`clientID`,`recordedAt`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `advisorprofiles`
--
ALTER TABLE `advisorprofiles`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `authtokens`
--
ALTER TABLE `authtokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `bans`
--
ALTER TABLE `bans`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `coachavailabilityblocks`
--
ALTER TABLE `coachavailabilityblocks`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `coachclients`
--
ALTER TABLE `coachclients`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `coachprofiles`
--
ALTER TABLE `coachprofiles`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `coachreviews`
--
ALTER TABLE `coachreviews`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `conversations`
--
ALTER TABLE `conversations`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `gymreviews`
--
ALTER TABLE `gymreviews`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `invitations`
--
ALTER TABLE `invitations`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `messages`
--
ALTER TABLE `messages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `passwordresettokens`
--
ALTER TABLE `passwordresettokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `reservations`
--
ALTER TABLE `reservations`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `weighthistory`
--
ALTER TABLE `weighthistory`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `advisorprofiles`
--
ALTER TABLE `advisorprofiles`
  ADD CONSTRAINT `fk_advisorProfiles_userID` FOREIGN KEY (`userID`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `authtokens`
--
ALTER TABLE `authtokens`
  ADD CONSTRAINT `fk_authTokens_userID` FOREIGN KEY (`userID`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `bans`
--
ALTER TABLE `bans`
  ADD CONSTRAINT `fk_bans_bannedBy` FOREIGN KEY (`bannedBy`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_bans_liftedBy` FOREIGN KEY (`liftedBy`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_bans_userID` FOREIGN KEY (`userID`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `coachavailabilityblocks`
--
ALTER TABLE `coachavailabilityblocks`
  ADD CONSTRAINT `fk_coachAvailabilityBlocks_coachID` FOREIGN KEY (`coachID`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `coachclients`
--
ALTER TABLE `coachclients`
  ADD CONSTRAINT `fk_coachClients_clientID` FOREIGN KEY (`clientID`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_coachClients_coachID` FOREIGN KEY (`coachID`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `coachprofiles`
--
ALTER TABLE `coachprofiles`
  ADD CONSTRAINT `fk_coachProfiles_advisorID` FOREIGN KEY (`advisorID`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_coachProfiles_userID` FOREIGN KEY (`userID`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `coachreviews`
--
ALTER TABLE `coachreviews`
  ADD CONSTRAINT `fk_coachReviews_clientID` FOREIGN KEY (`clientID`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_coachReviews_coachID` FOREIGN KEY (`coachID`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `conversations`
--
ALTER TABLE `conversations`
  ADD CONSTRAINT `fk_conversations_clientID` FOREIGN KEY (`clientID`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_conversations_coachID` FOREIGN KEY (`coachID`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `gymreviews`
--
ALTER TABLE `gymreviews`
  ADD CONSTRAINT `fk_gymReviews_advisorID` FOREIGN KEY (`advisorID`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_gymReviews_clientID` FOREIGN KEY (`clientID`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `invitations`
--
ALTER TABLE `invitations`
  ADD CONSTRAINT `fk_invitations_coachID` FOREIGN KEY (`coachID`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_invitations_invitedUserID` FOREIGN KEY (`invitedUserID`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `messages`
--
ALTER TABLE `messages`
  ADD CONSTRAINT `fk_messages_conversationID` FOREIGN KEY (`conversationID`) REFERENCES `conversations` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_messages_senderID` FOREIGN KEY (`senderID`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `passwordresettokens`
--
ALTER TABLE `passwordresettokens`
  ADD CONSTRAINT `fk_passwordResetTokens_userID` FOREIGN KEY (`userID`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `reservations`
--
ALTER TABLE `reservations`
  ADD CONSTRAINT `fk_reservations_clientID` FOREIGN KEY (`clientID`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_reservations_coachID` FOREIGN KEY (`coachID`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `weighthistory`
--
ALTER TABLE `weighthistory`
  ADD CONSTRAINT `fk_weightHistory_clientID` FOREIGN KEY (`clientID`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
