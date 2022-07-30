ALTER TABLE competition ADD INDEX `created_at_idx` (`created_at`);
ALTER TABLE player ADD INDEX `created_at_idx` (`created_at`);
ALTER TABLE player_score DROP INDEX `ranking_idx`, ADD INDEX `ranking_idx` (`competition_id`, `score` DESC, `row_num`);
