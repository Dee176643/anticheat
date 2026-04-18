CREATE TABLE IF NOT EXISTS `ac_players` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `license_id` VARCHAR(96) NULL,
  `fivem_id` VARCHAR(96) NULL,
  `discord_id` VARCHAR(96) NULL,
  `steam_id` VARCHAR(96) NULL,
  `first_seen_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_seen_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `notes` TEXT NULL,
  `current_risk_score` INT NOT NULL DEFAULT 0,
  `is_banned` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ac_players_license` (`license_id`),
  UNIQUE KEY `uq_ac_players_fivem` (`fivem_id`),
  UNIQUE KEY `uq_ac_players_discord` (`discord_id`),
  UNIQUE KEY `uq_ac_players_steam` (`steam_id`)
);

CREATE TABLE IF NOT EXISTS `ac_sessions` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `player_id` INT NOT NULL,
  `joined_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `left_at` TIMESTAMP NULL DEFAULT NULL,
  `ip_hash` VARCHAR(64) NULL,
  `build_version` VARCHAR(64) NULL,
  `server_id` VARCHAR(64) NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ac_sessions_player` (`player_id`),
  CONSTRAINT `fk_ac_sessions_player`
    FOREIGN KEY (`player_id`) REFERENCES `ac_players` (`id`)
    ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `ac_detections` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `player_id` INT NOT NULL,
  `session_id` INT NOT NULL,
  `type` VARCHAR(64) NOT NULL,
  `severity` VARCHAR(16) NOT NULL,
  `score_delta` INT NOT NULL DEFAULT 0,
  `confidence` VARCHAR(16) NOT NULL,
  `details_json` LONGTEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ac_detections_player` (`player_id`),
  KEY `idx_ac_detections_session` (`session_id`),
  CONSTRAINT `fk_ac_detections_player`
    FOREIGN KEY (`player_id`) REFERENCES `ac_players` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_ac_detections_session`
    FOREIGN KEY (`session_id`) REFERENCES `ac_sessions` (`id`)
    ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `ac_evidence` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `detection_id` INT NOT NULL,
  `kind` VARCHAR(32) NOT NULL,
  `payload_json` LONGTEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ac_evidence_detection` (`detection_id`),
  CONSTRAINT `fk_ac_evidence_detection`
    FOREIGN KEY (`detection_id`) REFERENCES `ac_detections` (`id`)
    ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `ac_bans` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `player_id` INT NOT NULL,
  `reason` VARCHAR(255) NOT NULL,
  `issued_by` VARCHAR(64) NOT NULL,
  `issued_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` TIMESTAMP NULL DEFAULT NULL,
  `evidence_summary` TEXT NULL,
  `active` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `idx_ac_bans_player` (`player_id`),
  KEY `idx_ac_bans_active` (`active`),
  CONSTRAINT `fk_ac_bans_player`
    FOREIGN KEY (`player_id`) REFERENCES `ac_players` (`id`)
    ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `ac_admin_actions` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `admin_id` VARCHAR(96) NOT NULL,
  `action_type` VARCHAR(64) NOT NULL,
  `target_player_id` INT NULL,
  `details_json` LONGTEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ac_admin_actions_target` (`target_player_id`),
  CONSTRAINT `fk_ac_admin_actions_target`
    FOREIGN KEY (`target_player_id`) REFERENCES `ac_players` (`id`)
    ON DELETE SET NULL
);
