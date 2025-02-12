--1. Customer Cohort Retention
--Question: Calculate monthly retention rates for customer cohorts


WITH first_orders AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM orders
    GROUP BY customer_id
),
monthly_activity AS (
    SELECT
        fo.cohort_month,
        DATE_TRUNC('month', o.order_date) AS activity_month,
        COUNT(DISTINCT o.customer_id) AS active_customers
    FROM orders o
    JOIN first_orders fo 
        ON o.customer_id = fo.customer_id
    GROUP BY 1,2
)
SELECT
    cohort_month,
    activity_month,
    EXTRACT(MONTH FROM activity_month) - EXTRACT(MONTH FROM cohort_month) AS month_number,
    active_customers,
    FIRST_VALUE(active_customers) OVER (PARTITION BY cohort_month ORDER BY activity_month) AS cohort_size,
    ROUND(active_customers::NUMERIC / FIRST_VALUE(active_customers) OVER 
          (PARTITION BY cohort_month ORDER BY activity_month) * 100, 1) AS retention_rate
FROM monthly_activity;



-- 2. Delivery Performance Analytics
--Question: Calculate on-time delivery percentage for each delivery partner

SELECT 
    dp.delivery_partner_id,
    COUNT(*) AS total_orders,
    ROUND(AVG(CASE WHEN actual_time <= promised_time THEN 1 ELSE 0 END)*100,1) AS on_time_percentage,
    ROUND(AVG(EXTRACT(EPOCH FROM (actual_time - promised_time))/60),2) AS avg_delay_minutes
FROM delivery_performance dp
WHERE actual_time IS NOT NULL
GROUP BY dp.delivery_partner_id
HAVING COUNT(*) > 50
ORDER BY on_time_percentage DESC;


--4. Revenue Growth Analysis
--Question: Show month-over-month revenue growth percentage

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', order_date) AS month,
        SUM(order_total) AS revenue
    FROM orders
    GROUP BY 1
)
SELECT
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS prev_month_revenue,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY month)) / 
          LAG(revenue) OVER (ORDER BY month) * 100, 1) AS growth_pct
FROM monthly_revenue;


-- 5. Inventory Stock Alerts
--Question: Find products needing immediate restock

SELECT 
    p.product_id,
    p.product_name,
    COALESCE(SUM(i.stock_received - i.damaged_stock), 0) AS current_stock,
    p.min_stock_level,
    p.max_stock_level
FROM products p
LEFT JOIN inventory i 
    ON p.product_id = i.product_id
    AND i.date BETWEEN CURRENT_DATE - INTERVAL '7 days' AND CURRENT_DATE
GROUP BY p.product_id
HAVING COALESCE(SUM(i.stock_received - i.damaged_stock),0) < p.min_stock_level;

--6. Customer Lifetime Value
--Question: Calculate CLTV for customer segments


WITH customer_stats AS (
    SELECT
        c.customer_segment,
        o.customer_id,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(o.order_total) AS total_revenue
    FROM orders o
    JOIN customers c 
        ON o.customer_id = c.customer_id
    GROUP BY 1,2
)
SELECT
    customer_segment,
    AVG(total_orders) AS avg_orders,
    AVG(total_revenue) AS avg_revenue,
    ROUND(AVG(total_revenue) * 0.25 / (1 - 0.85), 2) AS cltv -- Assuming 25% margin and 15% discount rate
FROM customer_stats
GROUP BY customer_segment;

--7. Marketing Campaign ROAS
--Question: Identify campaigns with ROAS above platform average

WITH campaign_performance AS (
    SELECT
        campaign_id,
        spend,
        revenue_generated,
        revenue_generated / NULLIF(spend,0) AS roas
    FROM marketing_performance
)
SELECT 
    campaign_id,
    roas
FROM campaign_performance
WHERE roas > (SELECT AVG(roas) FROM campaign_performance);

--8. Product Return Analysis
--Question: Find products with high return rates due to quality issues

SELECT
    p.product_id,
    p.product_name,
    COUNT(DISTINCT cf.feedback_id) AS total_returns,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(COUNT(DISTINCT cf.feedback_id)*100.0 / COUNT(DISTINCT oi.order_id),1) AS return_rate
FROM customer_feedback cf
JOIN order_items oi 
    ON cf.order_id = oi.order_id
JOIN products p 
    ON oi.product_id = p.product_id
WHERE cf.feedback_category = 'Product Quality'
GROUP BY 1,2
HAVING COUNT(DISTINCT oi.order_id) > 100
ORDER BY return_rate DESC
LIMIT 10;


--9. Shelf Life Monitoring
--Question: Identify products approaching expiration

SELECT
    p.product_id,
    p.product_name,
    i.date AS stock_date,
    (i.date + p.shelf_life_days) AS expiry_date,
    (CURRENT_DATE - (i.date + p.shelf_life_days)) AS days_past_expiry
FROM inventory i
JOIN products p 
    ON i.product_id = p.product_id
WHERE CURRENT_DATE BETWEEN i.date + p.shelf_life_days - 3 AND i.date + p.shelf_life_days;


--10. Customer Value Segmentation
--Question: Segment customers by RFM analysis

WITH rfm AS (
    SELECT
        o.customer_id,
        MAX(o.order_date) AS last_order_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(o.order_total) AS monetary_value
    FROM orders o
    GROUP BY o.customer_id
)
SELECT
    customer_id,
    NTILE(5) OVER (ORDER BY last_order_date DESC) AS recency_score,
    NTILE(5) OVER (ORDER BY frequency) AS frequency_score,
    NTILE(5) OVER (ORDER BY monetary_value) AS monetary_score,
    CASE
        WHEN (NTILE(5) OVER (ORDER BY monetary_value) + NTILE(5) OVER (ORDER BY frequency)) >= 9 
             THEN 'High Value'
        ELSE 'Regular'
    END AS customer_segment
FROM rfm;


--11. Cross-Selling Analysis
--Question: Find frequently bought together product pairs

SELECT 
    a.product_id AS product1,
    b.product_id AS product2,
    COUNT(DISTINCT a.order_id) AS pair_count
FROM order_items a
JOIN order_items b 
    ON a.order_id = b.order_id
    AND a.product_id < b.product_id
GROUP BY 1,2
HAVING COUNT(DISTINCT a.order_id) > 50
ORDER BY pair_count DESC
LIMIT 10;

--13. Price Optimization
--Question: Find products with pricing 25% above/below category average

WITH category_pricing AS (
    SELECT
        category,
        AVG(price) AS avg_price,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price) AS p75_price,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price) AS p25_price
    FROM products
    GROUP BY category
)
SELECT
    p.product_id,
    p.product_name,
    p.price,
    cp.avg_price,
    CASE
        WHEN p.price > cp.p75_price THEN 'Premium Priced'
        WHEN p.price < cp.p25_price THEN 'Discount Priced'
        ELSE 'Average Priced'
    END AS price_positioning
FROM products p
JOIN category_pricing cp 
    ON p.category = cp.category;


--14. Delivery Distance Analysis
--Question: Optimize delivery zones based on distance-performance

SELECT
    c.area,
    AVG(dp.distance_km) AS avg_distance,
    AVG(EXTRACT(EPOCH FROM (dp.actual_time - dp.promised_time))/60) AS avg_delay,
    COUNT(*) AS total_orders
FROM delivery_performance dp
JOIN orders o 
    ON dp.order_id = o.order_id
JOIN customers c 
    ON o.customer_id = c.customer_id
GROUP BY c.area
HAVING COUNT(*) > 100
ORDER BY avg_delay DESC;

--15. Customer Feedback Sentiment
--Question: Analyze negative feedback trends

SELECT
    feedback_category,
    sentiment,
    DATE_TRUNC('week', feedback_date) AS week,
    COUNT(*) AS feedback_count,
    ROUND(AVG(rating),2) AS avg_rating
FROM customer_feedback
WHERE sentiment = 'negative'
GROUP BY 1,2,3
ORDER BY week DESC, feedback_count DESC;


--16. Promotional Effectiveness
--Question: Measure impact of price discounts on sales velocity


SELECT
    p.product_id,
    p.product_name,
    AVG(CASE WHEN oi.unit_price < p.mrp * 0.9 THEN oi.quantity ELSE 0 END) AS discounted_sales,
    AVG(CASE WHEN oi.unit_price >= p.mrp * 0.9 THEN oi.quantity ELSE 0 END) AS regular_sales,
    (AVG(CASE WHEN oi.unit_price < p.mrp * 0.9 THEN oi.quantity ELSE 0 END) -
     AVG(CASE WHEN oi.unit_price >= p.mrp * 0.9 THEN oi.quantity ELSE 0 END)) AS lift
FROM order_items oi
JOIN products p 
    ON oi.product_id = p.product_id
GROUP BY 1,2
HAVING COUNT(DISTINCT oi.order_id) > 50;


--17. Customer Acquisition Cost
--Question: Calculate CAC per marketing channel

SELECT
    channel,
    SUM(spend) AS total_spend,
    COUNT(DISTINCT c.customer_id) AS acquired_customers,
    ROUND(SUM(spend) / COUNT(DISTINCT c.customer_id),2) AS cac
FROM marketing_performance mp
JOIN customers c 
    ON c.registration_date BETWEEN mp.date - INTERVAL '7 days' AND mp.date + INTERVAL '7 days'
GROUP BY channel
HAVING COUNT(DISTINCT c.customer_id) > 0;



--18. Inventory Turnover
--Question: Calculate inventory turnover ratio

WITH product_sales AS (
    SELECT
        oi.product_id,
        SUM(oi.quantity) AS total_sold
    FROM order_items oi
    WHERE oi.order_id IN (SELECT order_id FROM orders WHERE order_date >= CURRENT_DATE - INTERVAL '30 days')
    GROUP BY 1
),
inventory_levels AS (
    SELECT
        product_id,
        AVG(stock_received - damaged_stock) AS avg_stock
    FROM inventory
    WHERE date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 1
)
SELECT
    p.product_id,
    p.product_name,
    COALESCE(ps.total_sold,0) AS units_sold,
    COALESCE(il.avg_stock,0) AS avg_inventory,
    ROUND(COALESCE(ps.total_sold / NULLIF(il.avg_stock,0),0),1) AS turnover_ratio
FROM products p
LEFT JOIN product_sales ps 
    ON p.product_id = ps.product_id
LEFT JOIN inventory_levels il 
    ON p.product_id = il.product_id;


--19. Customer Support Analysis
--Question: Identify common feedback patterns

SELECT
    feedback_category,
    sentiment,
    COUNT(*) AS feedback_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_total
FROM customer_feedback
WHERE feedback_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY 1,2
ORDER BY feedback_count DESC;

--20. Payment Method Trends
--Question: Analyze payment method adoption over time


SELECT
    DATE_TRUNC('month', order_date) AS month,
    payment_method,
    COUNT(DISTINCT order_id) AS order_count,
    ROUND(100.0 * COUNT(DISTINCT order_id) / SUM(COUNT(DISTINCT order_id)) OVER 
          (PARTITION BY DATE_TRUNC('month', order_date)), 1) AS pct_total
FROM orders
GROUP BY 1,2
ORDER BY month DESC, order_count DESC;



--21. Customer Geography Analysis
--Question: Optimize delivery centers based on customer density

SELECT
    c.pincode,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    ROUND(AVG(dp.distance_km),1) AS avg_distance
FROM orders o
JOIN customers c 
    ON o.customer_id = c.customer_id
JOIN delivery_performance dp 
    ON o.order_id = dp.order_id
GROUP BY c.pincode
HAVING COUNT(DISTINCT o.order_id) > 100
ORDER BY total_orders DESC;

--14. Find Customers Who Have Given Negative Feedback
--Question: Which customers have rated below 3 stars?

SELECT f.customer_id, c.customer_name, f.rating, f.feedback_text
FROM customer_feedback f
JOIN customers c ON f.customer_id = c.customer_id
WHERE f.rating < 3;










