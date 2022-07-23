-- competition
CREATE TABLE `competition_new` (
  `id` bigint NOT NULL,
  `tenant_id` bigint NOT NULL,
  `title` text NOT NULL,
  `finished_at` bigint DEFAULT NULL,
  `created_at` bigint NOT NULL,
  `updated_at` bigint NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
INSERT INTO competition_new (id, tenant_id, title, finished_at, created_at, updated_at) SELECT CONV(id,16,10) AS id, tenant_id, title, finished_at, created_at, updated_at FROM competition;
RENAME TABLE competition TO competition_old, competition_new TO competition;
DROP TABLE competition_old;

-- player
CREATE TABLE `player_new` (
  `id` bigint NOT NULL,
  `tenant_id` bigint NOT NULL,
  `display_name` text NOT NULL,
  `is_disqualified` tinyint(1) NOT NULL,
  `created_at` bigint NOT NULL,
  `updated_at` bigint NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
INSERT INTO player_new (id, tenant_id, display_name, is_disqualified, created_at, updated_at) SELECT CONV(id,16,10) AS id, tenant_id, display_name, is_disqualified, created_at, updated_at FROM player;
RENAME TABLE player TO player_old, player_new TO player;
DROP TABLE player_old;

--- player_score

CREATE TABLE `player_score_new` (
  `tenant_id` bigint NOT NULL,
  `player_id` bigint NOT NULL,
  `competition_id` bigint NOT NULL,
  `score` bigint NOT NULL,
  `created_at` bigint NOT NULL,
  `updated_at` bigint NOT NULL,
  PRIMARY KEY (`tenant_id`, `player_id`, `competition_id`)
  INDEX `ranking_idx` (`tenant_id`, `competition_id`, `score`);
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
INSERT INTO player_score_new (tenant_id, competition_id, player_id, score, created_at, updated_at) SELECT tenant_id, CONV(competition_id,16,10) AS competition_id, CONV(player_id,16,10) AS player_id, score, created_at, updated_at FROM (SELECT id, tenant_id, competition_id, player_id, score, created_at, updated_at, ROW_NUMBER() OVER (PARTITION BY tenant_id, competition_id, player_id ORDER BY row_num DESC) AS `rank` FROM player_score) a WHERE a.rank = 1;
RENAME TABLE player_score TO player_score_old, player_score_new TO player_score;
DROP TABLE player_score_old;