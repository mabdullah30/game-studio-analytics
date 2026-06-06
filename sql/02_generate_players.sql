-- ==============================================================================
-- 02: Player Base Generation
-- Generates 5,000 synthetic players with realistic demographic distributions
-- ==============================================================================

INSERT INTO dim_players (
    username, country, device_type, os_version, 
    acquisition_source, registered_at, player_segment, age_group
)
SELECT
    'player_' || generate_series,
    
    -- Country distribution (Weighted towards UK/US/PK)
    (ARRAY['United Kingdom', 'United States', 'Pakistan', 'UAE', 'Germany', 'India', 'Canada', 'Australia'])[ceil(random()*8)::int],
    
    -- Device allocation: 60% Android, 35% iOS, 5% Tablet
    CASE 
        WHEN random() < 0.60 THEN 'Android' 
        WHEN random() < 0.95 THEN 'iOS' 
        ELSE 'Tablet' 
    END,
    
    -- OS Version
    (ARRAY['Android 13', 'Android 14', 'iOS 16', 'iOS 17'])[ceil(random()*4)::int],
    
    -- Acquisition Source
    (ARRAY['Organic', 'Facebook Ads', 'Google UAC', 'TikTok Ads', 'Referral', 'App Store Search'])[ceil(random()*6)::int],
    
    -- Registration spread evenly over the 2-year period (2024-2025)
    '2024-01-01 00:00:00'::timestamp + (random() * 730 || ' days')::interval,
    
    -- Monetization Segments: 2% Whale, 8% Dolphin, 20% Minnow, 70% Free
    CASE 
        WHEN random() < 0.02 THEN 'Whale' 
        WHEN random() < 0.10 THEN 'Dolphin' 
        WHEN random() < 0.30 THEN 'Minnow' 
        ELSE 'Free' 
    END,
    
    -- Age group
    (ARRAY['13-17', '18-24', '25-34', '35+'])[ceil(random()*4)::int]
FROM generate_series(1, 5000);