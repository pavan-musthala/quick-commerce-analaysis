CREATE VIEW master_data AS
SELECT
    o.order_id,
    o.customer_id,
    c.customer_name,
    c.customer_segment,
    c.total_orders,
    c.avg_order_value,
    o.order_date,
    o.order_total,
    o.payment_method,
    o.delivery_status AS order_delivery_status,
    p.product_id,
    p.product_name,
    p.category AS product_category,
    p.brand AS product_brand,
    p.price AS product_price,
    p.mrp AS product_mrp,
    oi.quantity AS order_item_quantity,
    oi.unit_price AS order_item_unit_price,
    f.feedback_id,
    f.rating AS feedback_rating,
    f.feedback_text,
    f.feedback_category,
    f.sentiment AS feedback_sentiment,
    f.feedback_date,
    dp.delivery_partner_id,
    dp.promised_time AS delivery_promised_time,
    dp.actual_time AS delivery_actual_time,
    dp.delivery_time_minutes,
    dp.delivery_status AS delivery_status,
    dp.reasons_if_delayed,
    i.stock_received,
    i.damaged_stock
   
  
FROM
    orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN customer_feedback f ON f.order_id = o.order_id
LEFT JOIN delivery_performance dp ON o.order_id = dp.order_id
LEFT JOIN inventory i ON i.product_id = p.product_id

select * from master_data
