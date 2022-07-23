DROP TABLE IF EXISTS competition;
DROP TABLE IF EXISTS player;
DROP TABLE IF EXISTS player_score;

CREATE TABLE `competition` (
  `id` bigint NOT NULL,
  `tenant_id` bigint NOT NULL,
  `title` text NOT NULL,
  `finished_at` bigint DEFAULT NULL,
  `created_at` bigint NOT NULL,
  `updated_at` bigint NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `player` (
  `id` bigint NOT NULL,
  `tenant_id` bigint NOT NULL,
  `display_name` text NOT NULL,
  `is_disqualified` tinyint(1) NOT NULL,
  `created_at` bigint NOT NULL,
  `updated_at` bigint NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `player_score` (
  `tenant_id` bigint NOT NULL,
  `player_id` bigint NOT NULL,
  `competition_id` bigint NOT NULL,
  `score` bigint NOT NULL,
  `created_at` bigint NOT NULL,
  `updated_at` bigint NOT NULL,
  PRIMARY KEY (`tenant_id`, `player_id`, `competition_id`),
  INDEX `ranking_idx` (`tenant_id`, `competition_id`, `score`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
