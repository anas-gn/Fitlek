-- Shared between the mobile API and Web_admin API. Existing behavior stays active.
CREATE TABLE IF NOT EXISTS app_feature_flags (
  name VARCHAR(100) NOT NULL PRIMARY KEY,
  enabled TINYINT(1) NOT NULL DEFAULT 1,
  updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
INSERT IGNORE INTO app_feature_flags (name, enabled) VALUES ('coachingCompanies', 1);
