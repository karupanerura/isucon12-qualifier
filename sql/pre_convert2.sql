ALTER TABLE competition DROP COLUMN tenant_id;
ALTER TABLE player DROP COLUMN tenant_id;
ALTER TABLE player_score ADD COLUMN `row_num` bigint NOT NULL AFTER `score`, DROP PRIMARY KEY, ADD PRIMARY KEY (`player_id`, `competition_id`), DROP INDEX `ranking_idx`, ADD INDEX `ranking_idx` (`competition_id`, `score`, `row_num`), DROP COLUMN tenant_id;
