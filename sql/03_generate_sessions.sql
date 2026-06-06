-- ==============================================================================
-- 03: Session & Transaction Telemetry
-- Simulates engagement patterns based on player monetization segments
-- ==============================================================================

-- Generate Play Sessions
INSERT INTO fact_sessions (
    player_id, session_start, session_end, session_duration, 
    levels_played, device_type, country, session_date, hour_of_day
)
SELECT
    p.player_id,
    session_ts,
    session_ts + (floor(random() * 1800 + 60) || ' seconds')::interval,
    floor(random() * 1800 + 60)::int, -- Duration: 1 to 30 mins
    floor(random() * 8 + 1)::int,
    p.device_type,
    p.country,
    session_ts::date,
    EXTRACT(hour FROM session_ts)::int
FROM dim_players p
CROSS JOIN LATERAL (
    SELECT p.registered_at + (random() * 730 || ' days')::interval AS session_ts
    FROM generate_series(1, 
        CASE p.player_segment
            WHEN 'Whale' THEN 150   -- Highly engaged
            WHEN 'Dolphin' THEN 80
            WHEN 'Minnow' THEN 30
            ELSE 10                 -- Free players churn fast
        END
    ) s
) sessions
WHERE session_ts <= '2025-12-31 23:59:59'::timestamp;

-- Generate Transactions (Exclusive to non-free players)
WITH generated_tx AS (
    SELECT
        p.player_id,
        p.registered_at + (random() * 730 || ' days')::interval AS transaction_date,
        (ARRAY['Gem Pack 100', 'Gem Pack 500', 'Gem Pack 1200', 'Speed Booster', 'Extra Lives x5', 'Battle Pass', 'Hero Skin - Dragon', 'Hero Skin - Galaxy', 'Starter Pack', 'VIP Bundle'])[ceil(random()*10)::int] AS item_name,
        (ARRAY['Gems', 'Gems', 'Gems', 'Booster', 'Booster', 'Battle Pass', 'Skin', 'Skin', 'Bundle', 'Bundle'])[ceil(random()*10)::int] AS item_category,
        
        -- Price scaling based on player segment
        CASE p.player_segment
            WHEN 'Whale' THEN ROUND((random() * 90 + 10)::numeric, 2)
            WHEN 'Dolphin' THEN ROUND((random() * 20 + 2)::numeric, 2)
            ELSE ROUND((random() * 5 + 0.99)::numeric, 2)
        END AS price_usd,
        
        'USD' AS currency,
        CASE WHEN p.device_type = 'iOS' THEN 'AppStore' ELSE 'PlayStore' END AS store,
        (random() < 0.7) AS is_first_purchase
    FROM dim_players p
    CROSS JOIN generate_series(1, 
        CASE p.player_segment
            WHEN 'Whale' THEN 50
            WHEN 'Dolphin' THEN 16
            WHEN 'Minnow' THEN 4
            ELSE 0
        END
    )
    WHERE p.player_segment != 'Free'
)
INSERT INTO fact_transactions (
    player_id, transaction_date, item_name, item_category, 
    price_usd, currency, store, is_first_purchase
)
SELECT * FROM generated_tx
WHERE transaction_date <= '2025-12-31 23:59:59'::timestamp;