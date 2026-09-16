-- ============================================================
-- Migration: Categories & Favorites
-- Run on: sirvya database (MySQL 8+)
-- ============================================================

-- 1. Categories table
CREATE TABLE IF NOT EXISTS `categories` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `icon` varchar(100) NOT NULL DEFAULT 'fitness_center',
  `sortOrder` int NOT NULL DEFAULT 0,
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_category_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Seed default categories
INSERT IGNORE INTO `categories` (`name`, `icon`, `sortOrder`) VALUES
  ('Musculation', 'fitness_center', 1),
  ('Perte de poids', 'monitor_weight', 2),
  ('Yoga', 'self_improvement', 3),
  ('CrossFit', 'sports_gymnastics', 4),
  ('Boxe', 'sports_mma', 5),
  ('Nutrition', 'restaurant', 6),
  ('Pilates', 'accessibility_new', 7),
  ('Cardio', 'directions_run', 8),
  ('Stretching', 'straighten', 9),
  ('Functional Training', 'sports_kabaddi', 10);

-- 3. Add categoryID to coachprofiles
ALTER TABLE `coachprofiles`
  ADD COLUMN `categoryID` int unsigned DEFAULT NULL AFTER `ville`,
  ADD CONSTRAINT `fk_coachprofiles_categoryID`
    FOREIGN KEY (`categoryID`) REFERENCES `categories` (`id`)
    ON DELETE SET NULL;

-- 4. Coach favorites table
CREATE TABLE IF NOT EXISTS `coach_favorites` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `clientID` bigint unsigned NOT NULL,
  `coachID` bigint unsigned NOT NULL,
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_coach_favorite` (`clientID`, `coachID`),
  KEY `idx_favorites_client` (`clientID`),
  KEY `idx_favorites_coach` (`coachID`),
  CONSTRAINT `fk_favorites_clientID` FOREIGN KEY (`clientID`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_favorites_coachID` FOREIGN KEY (`coachID`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Try to auto-assign categories to existing coaches based on specialty text
UPDATE `coachprofiles` cp
  SET cp.categoryID = (SELECT c.id FROM `categories` c WHERE c.name = 'Musculation' LIMIT 1)
  WHERE LOWER(cp.specialty) LIKE '%muscul%'
    OR LOWER(cp.specialty) LIKE '%hypertrophy%'
    OR LOWER(cp.specialty) LIKE '%bodybuilding%'
    OR LOWER(cp.specialty) LIKE '%strength%';

UPDATE `coachprofiles` cp
  SET cp.categoryID = (SELECT c.id FROM `categories` c WHERE c.name = 'Yoga' LIMIT 1)
  WHERE LOWER(cp.specialty) LIKE '%yoga%'
    OR LOWER(cp.specialty) LIKE '%pilates%';

UPDATE `coachprofiles` cp
  SET cp.categoryID = (SELECT c.id FROM `categories` c WHERE c.name = 'Perte de poids' LIMIT 1)
  WHERE LOWER(cp.specialty) LIKE '%weight loss%'
    OR LOWER(cp.specialty) LIKE '%perte%'
    OR LOWER(cp.specialty) LIKE '%nutrition%';

UPDATE `coachprofiles` cp
  SET cp.categoryID = (SELECT c.id FROM `categories` c WHERE c.name = 'CrossFit' LIMIT 1)
  WHERE LOWER(cp.specialty) LIKE '%crossfit%';

UPDATE `coachprofiles` cp
  SET cp.categoryID = (SELECT c.id FROM `categories` c WHERE c.name = 'Boxe' LIMIT 1)
  WHERE LOWER(cp.specialty) LIKE '%box%'
    OR LOWER(cp.specialty) LIKE '%mma%';
