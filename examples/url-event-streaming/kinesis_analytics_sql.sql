-- Kinesis Analytics SQL for Real-time URL Event Processing
-- This SQL processes incoming URL events and performs real-time analytics

-- Create a stream for windowed aggregations
CREATE OR REPLACE STREAM "DESTINATION_SQL_STREAM" (
    event_id VARCHAR(64),
    timestamp TIMESTAMP,
    url VARCHAR(2048),
    user_id VARCHAR(128),
    session_id VARCHAR(128),
    user_agent VARCHAR(1024),
    ip_address VARCHAR(45),
    referrer VARCHAR(2048),
    page_title VARCHAR(500),
    event_type VARCHAR(50),
    processing_time TIMESTAMP
);

-- Insert processed events with enrichments
CREATE OR REPLACE PUMP "STREAM_PUMP" AS INSERT INTO "DESTINATION_SQL_STREAM"
SELECT STREAM 
    event_id,
    timestamp,
    url,
    user_id,
    session_id,
    user_agent,
    ip_address,
    referrer,
    CASE 
        WHEN url LIKE '%/product%' THEN 'Product Page'
        WHEN url LIKE '%/category%' THEN 'Category Page'
        WHEN url LIKE '%/checkout%' THEN 'Checkout Page'
        WHEN url LIKE '%/search%' THEN 'Search Page'
        WHEN url = '/' OR url = '' THEN 'Homepage'
        ELSE 'Other Page'
    END as page_title,
    CASE 
        WHEN url LIKE '%/checkout%' OR url LIKE '%/cart%' THEN 'conversion'
        WHEN url LIKE '%/product%' THEN 'browse'
        WHEN url LIKE '%/search%' THEN 'search'
        ELSE 'page_view'
    END as event_type,
    CURRENT_TIMESTAMP as processing_time
FROM "SOURCE_SQL_STREAM_001"
WHERE timestamp IS NOT NULL 
    AND event_id IS NOT NULL;

-- Create a stream for real-time session analytics
CREATE OR REPLACE STREAM "SESSION_ANALYTICS_STREAM" (
    session_id VARCHAR(128),
    user_id VARCHAR(128),
    session_start TIMESTAMP,
    session_end TIMESTAMP,
    page_views INTEGER,
    unique_pages INTEGER,
    session_duration_seconds INTEGER,
    bounce_flag INTEGER,
    conversion_flag INTEGER,
    window_timestamp TIMESTAMP
);

-- Pump for session analytics (5-minute tumbling window)
CREATE OR REPLACE PUMP "SESSION_PUMP" AS INSERT INTO "SESSION_ANALYTICS_STREAM"
SELECT STREAM
    session_id,
    user_id,
    MIN(timestamp) as session_start,
    MAX(timestamp) as session_end,
    COUNT(*) as page_views,
    COUNT(DISTINCT url) as unique_pages,
    EXTRACT(EPOCH FROM (MAX(timestamp) - MIN(timestamp))) as session_duration_seconds,
    CASE WHEN COUNT(*) = 1 THEN 1 ELSE 0 END as bounce_flag,
    CASE WHEN MAX(CASE WHEN url LIKE '%/checkout%' OR url LIKE '%/purchase%' THEN 1 ELSE 0 END) = 1 THEN 1 ELSE 0 END as conversion_flag,
    ROWTIME_TO_TIMESTAMP(ROWTIME) as window_timestamp
FROM "SOURCE_SQL_STREAM_001"
WHERE session_id IS NOT NULL 
    AND session_id != ''
GROUP BY 
    session_id,
    user_id,
    RANGE_INTERVAL '5' MINUTE;

-- Create a stream for real-time page analytics
CREATE OR REPLACE STREAM "PAGE_ANALYTICS_STREAM" (
    url VARCHAR(2048),
    page_views INTEGER,
    unique_users INTEGER,
    unique_sessions INTEGER,
    avg_session_duration DOUBLE,
    bounce_rate DOUBLE,
    window_timestamp TIMESTAMP
);

-- Pump for page analytics (1-minute tumbling window)
CREATE OR REPLACE PUMP "PAGE_PUMP" AS INSERT INTO "PAGE_ANALYTICS_STREAM"
SELECT STREAM
    url,
    COUNT(*) as page_views,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT session_id) as unique_sessions,
    AVG(EXTRACT(EPOCH FROM (timestamp - LAG(timestamp) OVER (PARTITION BY session_id ORDER BY timestamp)))) as avg_session_duration,
    CAST(COUNT(CASE WHEN ROW_NUMBER() OVER (PARTITION BY session_id ORDER BY timestamp) = 1 
                    AND COUNT(*) OVER (PARTITION BY session_id) = 1 THEN 1 END) AS DOUBLE) / 
    CAST(COUNT(DISTINCT session_id) AS DOUBLE) as bounce_rate,
    ROWTIME_TO_TIMESTAMP(ROWTIME) as window_timestamp
FROM "SOURCE_SQL_STREAM_001"
WHERE url IS NOT NULL 
    AND url != ''
GROUP BY 
    url,
    RANGE_INTERVAL '1' MINUTE;

-- Create a stream for real-time traffic source analytics
CREATE OR REPLACE STREAM "TRAFFIC_SOURCE_STREAM" (
    referrer_domain VARCHAR(500),
    traffic_count INTEGER,
    unique_users INTEGER,
    conversion_count INTEGER,
    conversion_rate DOUBLE,
    window_timestamp TIMESTAMP
);

-- Pump for traffic source analytics (5-minute tumbling window)
CREATE OR REPLACE PUMP "TRAFFIC_SOURCE_PUMP" AS INSERT INTO "TRAFFIC_SOURCE_STREAM"
SELECT STREAM
    CASE 
        WHEN referrer IS NULL OR referrer = '' THEN 'Direct'
        WHEN referrer LIKE '%google.%' THEN 'Google'
        WHEN referrer LIKE '%facebook.%' THEN 'Facebook'
        WHEN referrer LIKE '%twitter.%' THEN 'Twitter'
        WHEN referrer LIKE '%linkedin.%' THEN 'LinkedIn'
        WHEN referrer LIKE '%youtube.%' THEN 'YouTube'
        ELSE 'Other'
    END as referrer_domain,
    COUNT(*) as traffic_count,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(CASE WHEN url LIKE '%/checkout%' OR url LIKE '%/purchase%' THEN 1 END) as conversion_count,
    CAST(COUNT(CASE WHEN url LIKE '%/checkout%' OR url LIKE '%/purchase%' THEN 1 END) AS DOUBLE) / 
    CAST(COUNT(*) AS DOUBLE) as conversion_rate,
    ROWTIME_TO_TIMESTAMP(ROWTIME) as window_timestamp
FROM "SOURCE_SQL_STREAM_001"
GROUP BY 
    CASE 
        WHEN referrer IS NULL OR referrer = '' THEN 'Direct'
        WHEN referrer LIKE '%google.%' THEN 'Google'
        WHEN referrer LIKE '%facebook.%' THEN 'Facebook'
        WHEN referrer LIKE '%twitter.%' THEN 'Twitter'
        WHEN referrer LIKE '%linkedin.%' THEN 'LinkedIn'
        WHEN referrer LIKE '%youtube.%' THEN 'YouTube'
        ELSE 'Other'
    END,
    RANGE_INTERVAL '5' MINUTE;

-- Create a stream for anomaly detection
CREATE OR REPLACE STREAM "ANOMALY_DETECTION_STREAM" (
    metric_name VARCHAR(100),
    metric_value DOUBLE,
    threshold_value DOUBLE,
    anomaly_score DOUBLE,
    is_anomaly INTEGER,
    window_timestamp TIMESTAMP
);

-- Pump for anomaly detection (1-minute tumbling window)
CREATE OR REPLACE PUMP "ANOMALY_PUMP" AS INSERT INTO "ANOMALY_DETECTION_STREAM"
SELECT STREAM
    'page_views_per_minute' as metric_name,
    CAST(COUNT(*) AS DOUBLE) as metric_value,
    100.0 as threshold_value,
    CASE 
        WHEN COUNT(*) > 100 THEN CAST(COUNT(*) AS DOUBLE) / 100.0
        ELSE 0.0
    END as anomaly_score,
    CASE WHEN COUNT(*) > 100 THEN 1 ELSE 0 END as is_anomaly,
    ROWTIME_TO_TIMESTAMP(ROWTIME) as window_timestamp
FROM "SOURCE_SQL_STREAM_001"
GROUP BY RANGE_INTERVAL '1' MINUTE

UNION ALL

SELECT STREAM
    'unique_users_per_minute' as metric_name,
    CAST(COUNT(DISTINCT user_id) AS DOUBLE) as metric_value,
    50.0 as threshold_value,
    CASE 
        WHEN COUNT(DISTINCT user_id) > 50 THEN CAST(COUNT(DISTINCT user_id) AS DOUBLE) / 50.0
        ELSE 0.0
    END as anomaly_score,
    CASE WHEN COUNT(DISTINCT user_id) > 50 THEN 1 ELSE 0 END as is_anomaly,
    ROWTIME_TO_TIMESTAMP(ROWTIME) as window_timestamp
FROM "SOURCE_SQL_STREAM_001"
GROUP BY RANGE_INTERVAL '1' MINUTE;

-- Create a stream for real-time user behavior analytics
CREATE OR REPLACE STREAM "USER_BEHAVIOR_STREAM" (
    user_id VARCHAR(128),
    session_count INTEGER,
    total_page_views INTEGER,
    unique_pages_visited INTEGER,
    avg_session_duration DOUBLE,
    last_activity TIMESTAMP,
    user_segment VARCHAR(50),
    window_timestamp TIMESTAMP
);

-- Pump for user behavior analytics (10-minute tumbling window)
CREATE OR REPLACE PUMP "USER_BEHAVIOR_PUMP" AS INSERT INTO "USER_BEHAVIOR_STREAM"
SELECT STREAM
    user_id,
    COUNT(DISTINCT session_id) as session_count,
    COUNT(*) as total_page_views,
    COUNT(DISTINCT url) as unique_pages_visited,
    AVG(EXTRACT(EPOCH FROM (MAX(timestamp) - MIN(timestamp)))) as avg_session_duration,
    MAX(timestamp) as last_activity,
    CASE 
        WHEN COUNT(*) > 20 THEN 'High Activity'
        WHEN COUNT(*) > 5 THEN 'Medium Activity'
        ELSE 'Low Activity'
    END as user_segment,
    ROWTIME_TO_TIMESTAMP(ROWTIME) as window_timestamp
FROM "SOURCE_SQL_STREAM_001"
WHERE user_id IS NOT NULL 
    AND user_id != ''
GROUP BY 
    user_id,
    RANGE_INTERVAL '10' MINUTE;
