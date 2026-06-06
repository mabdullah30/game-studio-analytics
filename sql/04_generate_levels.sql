-- ==============================================================================
-- 04: Level Design & Progression Telemetry
-- Simulates difficulty spikes, failure rates, and boss level mechanics
-- ==============================================================================

-- Generate 50 Game Levels
INSERT INTO dim_levels (
    level_number, level_name, world, difficulty, avg_time_target, is_boss_level
)
SELECT
    n,
    'Level ' || n,
    CASE 
        WHEN n <= 10 THEN 'Forest'
        WHEN n <= 20 THEN 'Desert'
        WHEN n <= 30 THEN 'Ocean'
        WHEN n <= 40 THEN 'Castle'
        ELSE 'Space' 
    END,
    CASE 
        WHEN n % 10 = 0 THEN 'Boss'
        WHEN n % 3 = 0 THEN 'Hard'
        WHEN n % 2 = 0 THEN 'Medium'
        ELSE 'Easy' 
    END,
    (60 + n * 8), -- Difficulty scales time target up
    (n % 10 = 0)
FROM generate_series(1, 50) n;

-- Generate Level Progression Events (Completion vs. Failure)
WITH generated_events AS (
    SELECT
        p.player_id,
        lv.level_id,
        CASE 
            WHEN lv.is_boss_level AND random() < 0.55 THEN 'level_fail' 
            WHEN lv.difficulty = 'Hard' AND random() < 0.35 THEN 'level_fail' 
            ELSE 'level_complete' 
        END AS event_type,
        p.registered_at + (lv.level_number * random() * 14 || ' days')::interval AS event_timestamp,
        floor(random() * 4 + 1)::int AS attempt_number,
        lv.avg_time_target + floor((random() - 0.5) * 120)::int AS time_spent_sec,
        floor(random() * 3 + 1)::int AS stars_earned
    FROM dim_players p
    JOIN dim_levels lv ON lv.level_number <= (floor(random() * 50 + 1))::int
    WHERE p.player_id <= 2000 -- Sample subset of players for level data
)
INSERT INTO fact_level_events (
    player_id, level_id, event_type, event_timestamp, 
    attempt_number, time_spent_sec, stars_earned
)
SELECT * FROM generated_events
WHERE event_timestamp <= '2025-12-31 23:59:59'::timestamp;