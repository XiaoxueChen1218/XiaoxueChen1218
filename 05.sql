SELECT 
	pageview_url,
    COUNT(DISTINCT website_session_id) AS sessions
FROM website_pageviews
WHERE created_at < '2012-06-09'
GROUP BY pageview_url
ORDER BY sessions DESC;

-- STEP 1: find the first pageview for each session
-- STEP 2: find the url the customer saw on that first pageview
DROP TABLE IF EXISTS first_landing_sessions;
CREATE TEMPORARY TABLE first_landing_sessions
SELECT 
	website_session_id,
    MIN(website_pageview_id) AS website_pageview_id
FROM website_pageviews
GROUP BY website_session_id;

SELECT
	pageview_url AS landing_page,
    COUNT(DISTINCT first_landing_sessions.website_session_id) 
		AS sessions_hitting_this_landing_page
FROM first_landing_sessions
LEFT JOIN website_pageviews
	USING (website_pageview_id)
WHERE created_at < '2012-06-09'
GROUP BY pageview_url
ORDER BY sessions_hitting_this_landing_page DESC;

-- STEP1: 确定访问id和cookie的对应关系
DROP TEMPORARY TABLE IF EXISTS first_pageviews;
CREATE TEMPORARY TABLE first_pageviews
SELECT
    website_session_id,
    MIN(website_pageview_id) AS related_pageview_id
FROM website_pageviews
WHERE created_at < '2012-06-14' AND pageview_url = '/home'
GROUP BY website_session_id;
-- STEP2: 筛选出bounce = 1的cookie对应的session_id
DROP TEMPORARY TABLE IF EXISTS bounce_session;
CREATE TEMPORARY TABLE bounce_session
SELECT
	first_pageviews.website_session_id,
    COUNT(website_pageviews.website_pageview_id) AS bounce_time
FROM first_pageviews
LEFT JOIN website_pageviews
	USING (website_session_id)
GROUP BY first_pageviews.website_session_id
HAVING bounce_time = 1;
-- STEP3: count全部的session和bounce = 1的session
SELECT
	COUNT(first_pageviews.website_session_id) AS sessions,
    COUNT(bounce_session.website_session_id) AS bounced_sesions,
    COUNT(bounce_session.website_session_id) / COUNT(first_pageviews.website_session_id) AS bounce_rate
FROM first_pageviews
LEFT JOIN bounce_session 
	USING (website_session_id);

-- STEP1: find the first instance of /lander-1 to set analysis timeframe
SELECT 
	MIN(website_pageviews.created_at) AS first_created_at,
    MIN(website_pageview_id) AS first_pageview_id
FROM website_pageviews
LEFT JOIN website_sessions
	USING (website_session_id)
WHERE utm_source = 'gsearch' AND utm_campaign = 'nonbrand' 
	AND pageview_url = '/lander-1';

-- STEP2: repeat the landingpage_performance code
DROP TEMPORARY TABLE IF EXISTS first_pageviews_version2;
CREATE TEMPORARY TABLE IF NOT EXISTS first_pageviews_version2
SELECT
    website_session_id,
    MIN(website_pageview_id) AS related_pageview_id,
    COUNT(website_pageviews.website_pageview_id) AS bounce_time,
    website_sessions.created_at AS date
FROM website_pageviews
JOIN website_sessions
	USING (website_session_id)
WHERE website_pageviews.created_at BETWEEN '2012-06-01' AND '2012-08-31'
    AND utm_source = 'gsearch' 
    AND utm_campaign = 'nonbrand'
GROUP BY website_session_id;
-- ----------------------------------------------------------------------
DROP TABLE IF EXISTS bounce_session_version2;
CREATE TABLE IF NOT EXISTS bounce_session_version2
SELECT
	website_pageviews.pageview_url AS landing_page,
	first_pageviews_version2.website_session_id AS website_session_id,
    date
FROM first_pageviews_version2
LEFT JOIN website_pageviews
	ON first_pageviews_version2.related_pageview_id = website_pageviews.website_pageview_id
WHERE bounce_time = 1;
-- ----------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS total_sessions_in_two_landing_page;
CREATE TEMPORARY TABLE IF NOT EXISTS total_sessions_in_two_landing_page
SELECT
	pageview_url AS landing_page,
	first_pageviews_version2.website_session_id AS website_session_id,
    date
FROM first_pageviews_version2
LEFT JOIN website_pageviews
	ON first_pageviews_version2.related_pageview_id = website_pageviews.website_pageview_id
WHERE pageview_url IN ('/lander-1', '/home');
-- ----------------------------------------------------------------
SELECT
	MIN(DATE(total_sessions_in_two_landing_page.date)) AS week_start_date,
    COUNT(bounce_session_version2.website_session_id)/COUNT(total_sessions_in_two_landing_page.website_session_id) 
		AS bounce_rate,
	COUNT(CASE WHEN total_sessions_in_two_landing_page.landing_page = '/home' 
				THEN website_session_id ELSE NULL END) AS home_sessions,
	COUNT(CASE WHEN total_sessions_in_two_landing_page.landing_page = '/lander-1'
				THEN website_session_id ELSE NULL END) AS lander_sessions
FROM total_sessions_in_two_landing_page
RIGHT JOIN bounce_session_version2
	USING (website_session_id)
GROUP BY WEEK(total_sessions_in_two_landing_page.date)
ORDER BY WEEK(total_sessions_in_two_landing_page.date);

DROP TEMPORARY TABLE IF EXISTS session_level_made_it;
CREATE TEMPORARY TABLE session_level_made_it
SELECT
	website_session_id,
    MAX(products_page) AS to_products,
    MAX(mrfuzzy_page) AS to_mrfuzzy,
    MAX(cart_page) AS to_cart,
    MAX(shipping_page) AS to_shipping,
    MAX(billing_page) AS to_billing,
    MAX(thankyou_page) AS to_thankyou
FROM(
	SELECT 
		website_pageviews.website_session_id,
		pageview_url,
		CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
		CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
		CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
		CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
		CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
		CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
	FROM website_pageviews
	LEFT JOIN website_sessions
		USING (website_session_id)
	WHERE utm_source = 'gsearch' 
		AND utm_campaign = 'nonbrand'
		AND website_pageviews.created_at > '2012-08-05' AND website_pageviews.created_at < '2012-09-05' 
		AND pageview_url IN ('/lander-1', '/products', '/the-original-mr-fuzzy', '/cart', '/shipping', '/billing', '/thank-you-for-your-order')
	ORDER BY website_pageviews.website_session_id
) AS pageview_level
GROUP BY website_session_id;

SELECT
	COUNT(DISTINCT website_session_id) AS sessions,
	COUNT(DISTINCT CASE WHEN to_products = 1 THEN website_session_id ELSE NULL END) / 
		COUNT(DISTINCT website_session_id) AS rate_to_products,
	COUNT(DISTINCT CASE WHEN to_mrfuzzy = 1 THEN website_session_id ELSE NULL END) / 
		COUNT(DISTINCT CASE WHEN to_products = 1 THEN website_session_id ELSE NULL END) AS rate_to_mrfuzzy,
	COUNT(DISTINCT CASE WHEN to_cart = 1 THEN website_session_id ELSE NULL END) / 
		COUNT(DISTINCT CASE WHEN to_mrfuzzy = 1 THEN website_session_id ELSE NULL END) AS rate_to_cart,
	COUNT(DISTINCT CASE WHEN to_shipping = 1 THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN to_cart = 1 THEN website_session_id ELSE NULL END) AS rate_to_shipping,
	COUNT(DISTINCT CASE WHEN to_billing = 1 THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN to_shipping = 1 THEN website_session_id ELSE NULL END) AS rate_to_billing,
	COUNT(DISTINCT CASE WHEN to_thankyou = 1 THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN to_billing = 1 THEN website_session_id ELSE NULL END) AS rate_to_thankyou
FROM session_level_made_it;

-- 确定使用/billing-2开始的时间
SELECT
	website_pageviews.created_at
FROM website_pageviews
LEFT JOIN website_sessions
	USING (website_session_id)
WHERE pageview_url = '/billing-2'
ORDER BY website_pageviews.created_at;
-- 2012-09-10
-- 分别计算/billing和/billing-2的click-through-rate
SELECT
	pageview_url AS billing_version_seen,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT order_id) / COUNT(DISTINCT website_session_id) AS billing_to_order_rt
FROM(
	SELECT 
		website_pageviews.website_session_id,
		pageview_url,
		order_id
	FROM website_pageviews
	LEFT JOIN orders
		USING (website_session_id)
	WHERE website_pageviews.created_at BETWEEN '2012-09-10' AND '2012-11-10'
        AND pageview_url IN ('/billing', '/billing-2')
	ORDER BY website_pageviews.website_session_id
) AS pageview_levels
GROUP BY pageview_url;




