SELECT 
	utm_source,
    utm_campaign,
    http_referer,
    COUNT(website_session_id) AS sessions
FROM website_sessions
WHERE created_at < '2012-04-12'
GROUP BY utm_source, utm_campaign, http_referer
ORDER BY sessions DESC;

SELECT
	COUNT(website_session_id) AS sessions,
    COUNT(order_id) AS orders,
    COUNT(order_id) / COUNT(website_session_id) AS session_to_order_conv_rate
FROM website_sessions
LEFT JOIN orders USING (website_session_id)
WHERE website_sessions.created_at < '2012-04-14' 
	AND utm_source = 'gsearch' 
    AND utm_campaign = 'nonbrand';

SELECT
	MIN(DATE(created_at)) AS week_start_date,
    COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE created_at BETWEEN '2012-04-15' AND '2012-05-12'
	AND utm_source = 'gsearch' 
    AND utm_campaign = 'nonbrand'
GROUP BY WEEK(created_at);

SELECT
	device_type,
	COUNT(website_session_id) AS sessions,
    COUNT(order_id) AS orders,
    COUNT(order_id) / COUNT(website_session_id) AS session_to_order_conv_rate
FROM website_sessions
LEFT JOIN orders USING (website_session_id)
WHERE website_sessions.created_at < '2012-05-11' 
	AND utm_source = 'gsearch' 
    AND utm_campaign = 'nonbrand'
    AND device_type = 'mobile'
UNION
SELECT
	device_type,
    COUNT(website_session_id) AS sessions,
    COUNT(order_id) AS orders,
    COUNT(order_id) / COUNT(website_session_id) AS session_to_order_conv_rate
FROM website_sessions
LEFT JOIN orders USING (website_session_id)
WHERE website_sessions.created_at < '2012-05-11' 
	AND utm_source = 'gsearch' 
    AND utm_campaign = 'nonbrand'
    AND device_type = 'desktop';
    
SELECT
	MIN(DATE(created_at)) AS week_start_date,
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS dtop_sessions,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mob_sessions
FROM website_sessions
WHERE created_at BETWEEN '2012-04-15' AND'2012-06-09'
	AND utm_source = 'gsearch' 
    AND utm_campaign = 'nonbrand'
GROUP BY WEEK(created_at);

    
    
    
    
    