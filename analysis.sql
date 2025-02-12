-- Advanced Analytics 

-- Seasonal demand trends for each product:
SELECT 
    p.product_id, 
    p.product_name, 
    EXTRACT(MONTH FROM i.date) AS month, 
    SUM(i.stock_received) AS total_stock
FROM inventory i
JOIN products p ON i.product_id = p.product_id
GROUP BY p.product_id, p.product_name, EXTRACT(MONTH FROM i.date)
ORDER BY p.product_id, month;


-- Financial loss from damaged stock:
SELECT 
    p.product_id, 
    p.product_name, 
    SUM(i.damaged_stock * p.price) AS financial_loss
FROM inventory i
JOIN products p ON i.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY financial_loss DESC;



-- Delivery time by time of day:
SELECT 
    EXTRACT(HOUR FROM promised_time) AS hour_of_day, 
    AVG(delivery_time_minutes) AS avg_delivery_time
FROM delivery_performance
GROUP BY EXTRACT(HOUR FROM promised_time)
ORDER BY avg_delivery_time;


-- Delivery partner performance score:
SELECT 
    delivery_partner_id, 
    COUNT(*) AS total_deliveries,
    SUM(CASE WHEN actual_time <= promised_time THEN 1 ELSE 0 END) AS on_time_deliveries,
    ROUND(SUM(CASE WHEN actual_time <= promised_time THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS performance_score
FROM delivery_performance
GROUP BY delivery_partner_id
HAVING COUNT(*) > 50
ORDER BY performance_score DESC;



-- Calculate Customer Lifetime Value (CLV):

SELECT 
    c.customer_id, 
    c.customer_name, 
    ROUND(SUM(o.order_total), 2) AS total_revenue,
    ROUND(AVG(o.order_total), 2) AS avg_order_value,
    COUNT(o.order_id) AS total_orders,
    CASE 
        WHEN COUNT(o.order_id) > 0 AND EXTRACT(DAY FROM AGE(CURRENT_DATE, MIN(o.order_date))) > 0
        THEN ROUND((SUM(o.order_total) / COUNT(o.order_id)) * 
             (1 + (COUNT(o.order_id) / EXTRACT(DAY FROM AGE(CURRENT_DATE, MIN(o.order_date))))), 2)
        ELSE 0
    END AS clv
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY clv DESC;







-- Predict churn (customers with no recent orders and low feedback sentiment):
SELECT 
    c.customer_id, 
    c.customer_name, 
    MAX(o.order_date) AS last_order_date, 
    Round(AVG(f.rating),2) AS avg_feedback_rating
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN customer_feedback f ON c.customer_id = f.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING EXTRACT(DAY FROM AGE(CURRENT_DATE, MAX(o.order_date))) > 90 OR AVG(f.rating) < 3;



-- Advanced ROAS analysis:
SELECT 
    campaign_id, 
    campaign_name, 
    SUM(revenue_generated) AS total_revenue, 
    SUM(spend) AS total_spend, 
    (SUM(revenue_generated) / SUM(spend)) AS roas
FROM marketing_performance
GROUP BY campaign_id, campaign_name
ORDER BY roas DESC;



-- Cost-per-click (CPC) and Cost-per-Acquisition (CPA) by channel:
SELECT 
    channel, 
    SUM(spend) / SUM(clicks) AS cpc, 
    SUM(spend) / SUM(conversions) AS cpa
FROM marketing_performance
GROUP BY channel
ORDER BY cpa ASC;

-- Predict future demand (moving average):

SELECT 
    product_id, 
    round (AVG(stock_received) OVER (PARTITION BY product_id ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW),2)AS predicted_demand
FROM inventory
order by predicted_demand desc;




-- Predict sentiment trends (rolling average):
SELECT 
    EXTRACT(MONTH FROM feedback_date) AS month, 
    AVG(CASE WHEN sentiment = 'Positive' THEN 1 ELSE 0 END) AS positive_trend,
    AVG(CASE WHEN sentiment = 'Negative' THEN 1 ELSE 0 END) AS negative_trend
FROM customer_feedback
GROUP BY EXTRACT(MONTH FROM feedback_date)
ORDER BY month;








