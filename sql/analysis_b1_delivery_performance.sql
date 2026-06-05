/*
    B1 - Delivery Performance

    Key Findings:
        1. AL (Alagoas) has worst late rate (23.93%) but RR (Roraima) has worst avg delivery time (29.4 days)
            Late rate and delivery speed measure different failures - promise accuracy vs absolute speed
        
        2. Amazon / northern states (RR, AP, AM, PA) have worst delivery times - geographic isolation, poor
            road infrastructure, river-dependent logistics. SP delivers in 8.8 days vs RR's 29.4 days
            Thats 3.3x gap on the same platform.

        3. AP and AM have lowest late rates (4.48%, 4.14%) but worst delivery times. Olist sets artificially
            generous estimates in remote states - managing the metric, not the problem.
            avg_days_vs_estimate of -19 days confirms this.

        4. Northeast states (MA, AL, CE, SE, BA) cluster in the worst late rate tier - distinct failure mode 
            from the north. Likely carrier reliability, not just geography.

*/


WITH delivery_stats AS (
    SELECT
        c.customer_state AS state,
        COUNT(*) AS total_delivered,
        COUNT(*) FILTER (
            WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
        ) AS late_orders,
        ROUND(AVG(
            EXTRACT(EPOCH FROM (
                o.order_delivered_customer_date - o.order_estimated_delivery_date
            )) / 86400
        )::NUMERIC, 2) AS avg_days_vs_estimate,
        ROUND(AVG(
            EXTRACT(EPOCH FROM (
                o.order_delivered_customer_date - o.order_purchase_timestamp
            )) / 86400
        )::NUMERIC, 2) AS avg_actual_delivery_days
    
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        AND DATE_TRUNC('month', o.order_purchase_timestamp) != '2016-12-01'
    GROUP BY 1
)
SELECT 
    state,
    total_delivered,
    late_orders,
    ROUND((late_orders::NUMERIC / total_delivered * 100), 2) AS late_rate_pct,
    avg_days_vs_estimate,
    avg_actual_delivery_days
FROM delivery_stats
ORDER BY late_rate_pct DESC;


WITH delivery_detail AS (
    SELECT
        c.customer_state AS state,
        EXTRACT(EPOCH FROM (
            o.order_delivered_customer_date - o.order_purchase_timestamp
        )) / 86400 AS actual_days,
        CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 1 ELSE 0
        END AS is_late
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        AND DATE_TRUNC('month', o.order_purchase_timestamp) != '2016-12-01'
)
SELECT
    state,
    COUNT(*) AS total_orders, 
    ROUND(AVG(actual_days)::NUMERIC, 1) AS avg_delivery_days,
    COUNT(*) FILTER (WHERE actual_days <= 7) AS within_7d,
    COUNT(*) FILTER (WHERE actual_days BETWEEN 8 AND 14) AS within_8_14d,
    COUNT(*) FILTER (WHERE actual_days BETWEEN 15 AND 21) AS within_15_21d,
    COUNT(*) FILTER (WHERE actual_days > 21) AS over_21d,
    ROUND(SUM(is_late)::NUMERIC / COUNT(*) * 100, 2) AS late_rate_pct
FROM delivery_detail
GROUP BY 1
ORDER BY avg_delivery_days DESC;


-- verifying the geography claim
SELECT
    c.customer_state,
    ROUND(AVG(geo.geolocation_lat)::NUMERIC, 4) AS avg_lat,
    ROUND(AVG(geo.geolocation_lng)::NUMERIC, 4) AS avg_lng,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (
            o.order_delivered_customer_date - o.order_purchase_timestamp
        )) / 86400
    )::NUMERIC, 1) AS avg_delivery_days
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN geolocation geo ON c.customer_zip_code_prefix = geo.geolocation_zip_code_prefix
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY 1
ORDER BY avg_delivery_days DESC;