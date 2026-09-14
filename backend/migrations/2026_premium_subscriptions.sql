CREATE TABLE IF NOT EXISTS premium_subscriptions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  userID BIGINT UNSIGNED NOT NULL,
  provider VARCHAR(32) NOT NULL DEFAULT 'stripe',
  stripeCustomerID VARCHAR(255) NULL,
  stripeSubscriptionID VARCHAR(255) NULL,
  stripePriceID VARCHAR(255) NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'incomplete',
  currentPeriodStart DATETIME NULL,
  currentPeriodEnd DATETIME NULL,
  cancelAtPeriodEnd TINYINT(1) NOT NULL DEFAULT 0,
  createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_premium_stripe_subscription (stripeSubscriptionID),
  KEY idx_premium_user_status (userID, status),
  CONSTRAINT fk_premium_subscription_user
    FOREIGN KEY (userID) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS premium_stripe_events (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  stripeEventID VARCHAR(255) NOT NULL,
  eventType VARCHAR(100) NOT NULL,
  receivedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_premium_stripe_event (stripeEventID)
);
