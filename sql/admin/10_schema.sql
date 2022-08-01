USE `isuports`;

DROP TABLE IF EXISTS `tenant`;
DROP TABLE IF EXISTS `id_generator`;
DROP TABLE IF EXISTS `visit_history`;
DROP TABLE IF EXISTS `billing_reports`;

CREATE TABLE `tenant` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `display_name` VARCHAR(255) NOT NULL,
  `created_at` BIGINT NOT NULL,
  `updated_at` BIGINT NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4;

CREATE TABLE `billing_reports` (
  tenant_id           BIGINT NOT NULL,
  competition_id      BIGINT NOT NULL,
  competition_title   TEXT NOT NULL,
  player_count        BIGINT NOT NULL,
  visitor_count       BIGINT NOT NULL,
  billing_player_yen  BIGINT NOT NULL,
  billing_visitor_yen BIGINT NOT NULL,
  billing_yen         BIGINT NOT NULL,
  created_at          BIGINT NOT NULL,
  PRIMARY KEY (`tenant_id`, `competition_id`),
  INDEX `billing_idx` (`tenant_id`, `billing_yen`)
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4;