-- ==============================================================================
-- 01: Core Star Schema Generation
-- Simulates standard mobile gaming telemetry (Firebase/GameAnalytics)
-- ==============================================================================

CREATE DATABASE game_studio_db;

-- 1. PLAYERS (Dimension Table)
CREATE TABLE dim_players (
    player_id SERIAL PRIMARY KEY,
    username VARCHAR(50),
    country VARCHAR(50),
    device_type VARCHAR(20), -- iOS / Android / Tablet
    os_version VARCHAR(20),
    acquisition_source VARCHAR(30), -- Organic / Facebook / Google / TikTok
    registered_at TIMESTAMP,
    player_segment VARCHAR(20), -- Whale / Dolphin / Minnow / Free
    age_group VARCHAR(15), -- 13-17 / 18-24 / 25-34 / 35+
    is_active BOOLEAN DEFAULT TRUE
);

-- 2. SESSIONS (Fact Table: One row per play session)
CREATE TABLE fact_sessions (
    session_id SERIAL PRIMARY KEY,
    player_id INTEGER REFERENCES dim_players (player_id),
    session_start TIMESTAMP,
    session_end TIMESTAMP,
    session_duration INTEGER, -- Stored in seconds
    levels_played INTEGER,
    device_type VARCHAR(20),
    country VARCHAR(50),
    session_date DATE,
    hour_of_day INTEGER -- 0-23
);

-- 3. TRANSACTIONS (Fact Table: One row per purchase)
CREATE TABLE fact_transactions (
    transaction_id SERIAL PRIMARY KEY,
    player_id INTEGER REFERENCES dim_players (player_id),
    transaction_date TIMESTAMP,
    item_name VARCHAR(80),
    item_category VARCHAR(30), -- Gems / Booster / Skin / Battle Pass
    price_usd DECIMAL(8,2),
    currency VARCHAR(5),
    store VARCHAR(20), -- AppStore / PlayStore
    is_first_purchase BOOLEAN
);

-- 4. LEVEL EVENTS (Fact Table: One row per level attempt)
CREATE TABLE fact_level_events (
    event_id SERIAL PRIMARY KEY,
    player_id INTEGER REFERENCES dim_players (player_id),
    level_id INTEGER,
    event_type VARCHAR(20), -- level_start / level_complete / level_fail
    event_timestamp TIMESTAMP,
    attempt_number INTEGER,
    time_spent_sec INTEGER,
    stars_earned INTEGER -- 0-3
);

-- 5. LEVELS (Dimension Table)
CREATE TABLE dim_levels (
    level_id SERIAL PRIMARY KEY,
    level_number INTEGER,
    level_name VARCHAR(50),
    world VARCHAR(30), -- Forest / Desert / Ocean / Castle
    difficulty VARCHAR(15), -- Easy / Medium / Hard / Boss
    avg_time_target INTEGER, -- Target seconds for completion
    is_boss_level BOOLEAN
);

-- 6. CUSTOM EVENTS (Fact Table: Flexible game events log)
CREATE TABLE fact_events (
    event_id SERIAL PRIMARY KEY,
    player_id INTEGER REFERENCES dim_players (player_id),
    event_name VARCHAR(50), -- tutorial_complete / ad_watched / crash
    event_value TEXT,
    event_timestamp TIMESTAMP,
    session_id INTEGER,
    platform VARCHAR(15)
);

-- 7. DATE DIMENSION (Standardized time intelligence)
CREATE TABLE dim_date AS
SELECT
    d::date AS date_key,
    EXTRACT(year FROM d)::int AS year,
    EXTRACT(month FROM d)::int AS month,
    TO_CHAR(d, 'Mon YYYY') AS month_name,
    EXTRACT(week FROM d)::int AS week_number,
    EXTRACT(dow FROM d)::int AS day_of_week,
    TO_CHAR(d, 'Day') AS day_name,
    CASE WHEN EXTRACT(dow FROM d) IN (0,6) THEN 'Weekend' ELSE 'Weekday' END AS day_type
FROM generate_series(
    '2024-01-01'::date,
    '2025-12-31'::date,
    '1 day'::interval
) d;