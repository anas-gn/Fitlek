DROP DATABASE IF EXISTS fitlekdb;
CREATE DATABASE fitlekdb;
USE fitlekdb;
SET FOREIGN_KEY_CHECKS = 0;
SET NAMES utf8mb4;

CREATE TABLE users (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    firstName           VARCHAR(100)        NOT NULL,
    lastName            VARCHAR(100)        NOT NULL,
    email               VARCHAR(255)        NOT NULL UNIQUE,
    passwordHash        VARCHAR(255)        NOT NULL,
    role                ENUM('client','coach','admin','manager','advisor') NOT NULL DEFAULT 'client',
    gender              ENUM('Male','Female','Other')                      NOT NULL,
    avatarUrl           VARCHAR(500)        NULL,
    isPremium           TINYINT(1)          NOT NULL DEFAULT 0,
    isApproved          TINYINT(1)          NOT NULL DEFAULT 0,
    createdAt           DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt           DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE coachProfiles (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    userID              BIGINT UNSIGNED     NOT NULL UNIQUE,
    bio                 TEXT                NOT NULL,
    instagramPage       VARCHAR(100)        NOT NULL,
    certificateUrl      LONGBLOB            NOT NULL,
    invitationCode      VARCHAR(30)         NOT NULL UNIQUE,
    totalInvitations    INT UNSIGNED        NOT NULL DEFAULT 0,
    earnedPoints        INT UNSIGNED        NOT NULL DEFAULT 0,
    createdAt           DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt           DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_coachProfiles_userID
        FOREIGN KEY (userID) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE advisorProfiles (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    userID              BIGINT UNSIGNED     NOT NULL UNIQUE,
    specialty           VARCHAR(100)        NOT NULL,
    createdAt           DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt           DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_advisorProfiles_userID
        FOREIGN KEY (userID) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE coachClients (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    coachID             BIGINT UNSIGNED     NOT NULL,
    clientID            BIGINT UNSIGNED     NOT NULL,
    createdAt           DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uq_coachClients (coachID, clientID),

    CONSTRAINT fk_coachClients_coachID
        FOREIGN KEY (coachID)  REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_coachClients_clientID
        FOREIGN KEY (clientID) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE reservations (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    clientID            BIGINT UNSIGNED     NOT NULL,
    coachID             BIGINT UNSIGNED     NOT NULL,
    reservedDate        DATE                NOT NULL,
    reservedTime        TIME                NOT NULL,
    status              ENUM('pending','confirmed','cancelled') NOT NULL DEFAULT 'pending',
    rejectionReason     TEXT                NULL,
    cancellationReason  TEXT                NULL,
    cancelledBy         ENUM('coach','manager') NULL,
    createdAt           DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt           DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_reservations_clientID
        FOREIGN KEY (clientID) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_reservations_coachID
        FOREIGN KEY (coachID)  REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE coachAvailabilityBlocks (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    coachID             BIGINT UNSIGNED     NOT NULL,
    blockedDate         DATE                NOT NULL,
    startTime           TIME                NOT NULL,
    endTime             TIME                NOT NULL,
    note                VARCHAR(255)        NULL,
    createdAt           DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_coachAvailabilityBlocks_coachID
        FOREIGN KEY (coachID) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT chk_availabilityTime
        CHECK (endTime > startTime)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE conversations (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    coachID             BIGINT UNSIGNED     NOT NULL,
    clientID            BIGINT UNSIGNED     NOT NULL,
    lastMessageAt       DATETIME            NULL,
    createdAt           DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uq_conversations (coachID, clientID),

    CONSTRAINT fk_conversations_coachID
        FOREIGN KEY (coachID)  REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_conversations_clientID
        FOREIGN KEY (clientID) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE messages (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    conversationID      BIGINT UNSIGNED     NOT NULL,
    senderID            BIGINT UNSIGNED     NOT NULL,
    body                TEXT                NOT NULL,
    isRead              TINYINT(1)          NOT NULL DEFAULT 0,
    createdAt           DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_messages_conversationID
        FOREIGN KEY (conversationID) REFERENCES conversations(id) ON DELETE CASCADE,
    CONSTRAINT fk_messages_senderID
        FOREIGN KEY (senderID) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE invitations (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    coachID             BIGINT UNSIGNED     NOT NULL,
    invitedUserID       BIGINT UNSIGNED     NOT NULL,
    pointsEarned        INT UNSIGNED        NOT NULL DEFAULT 20,
    clickedAt           DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_invitations_coachID
        FOREIGN KEY (coachID)       REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_invitations_invitedUserID
        FOREIGN KEY (invitedUserID) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE bans (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    userID              BIGINT UNSIGNED     NOT NULL,
    bannedBy            BIGINT UNSIGNED     NOT NULL,
    banType             ENUM('temporary','permanent') NOT NULL,
    reason              TEXT                NOT NULL,
    bannedAt            DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expiresAt           DATETIME            NULL,
    isActive            TINYINT(1)          NOT NULL DEFAULT 1,
    liftedAt            DATETIME            NULL,
    liftedBy            BIGINT UNSIGNED     NULL,

    CONSTRAINT fk_bans_userID
        FOREIGN KEY (userID)   REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_bans_bannedBy
        FOREIGN KEY (bannedBy) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_bans_liftedBy
        FOREIGN KEY (liftedBy) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_bansExpiry
        CHECK (banType = 'permanent' OR expiresAt IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE passwordResetTokens (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    userID              BIGINT UNSIGNED     NOT NULL,
    token               VARCHAR(255)        NOT NULL UNIQUE,
    expiresAt           DATETIME            NOT NULL,
    usedAt              DATETIME            NULL,
    createdAt           DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_passwordResetTokens_userID
        FOREIGN KEY (userID) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE authTokens (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    userID              BIGINT UNSIGNED     NOT NULL,
    refreshToken        VARCHAR(512)        NOT NULL UNIQUE,
    deviceInfo          VARCHAR(255)        NULL,
    expiresAt           DATETIME            NOT NULL,
    revokedAt           DATETIME            NULL,
    createdAt           DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_authTokens_userID
        FOREIGN KEY (userID) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE INDEX idx_users_email              ON users(email);
CREATE INDEX idx_users_role               ON users(role);
CREATE INDEX idx_users_isApproved         ON users(isApproved);
CREATE INDEX idx_reservations_clientID    ON reservations(clientID);
CREATE INDEX idx_reservations_coachID     ON reservations(coachID);
CREATE INDEX idx_reservations_date        ON reservations(reservedDate);
CREATE INDEX idx_reservations_status      ON reservations(status);
CREATE INDEX idx_conversations_lastMsg    ON conversations(lastMessageAt DESC);
CREATE INDEX idx_messages_readStatus      ON messages(conversationID, isRead);
CREATE INDEX idx_bans_userActive          ON bans(userID, isActive);
CREATE INDEX idx_coachProfiles_invCode    ON coachProfiles(invitationCode);
CREATE INDEX idx_passwordResetTokens_exp  ON passwordResetTokens(expiresAt);
CREATE INDEX idx_authTokens_exp           ON authTokens(expiresAt);

SET FOREIGN_KEY_CHECKS = 1;