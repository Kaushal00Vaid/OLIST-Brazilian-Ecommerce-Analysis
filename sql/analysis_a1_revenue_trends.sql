-- Revenue & order trends over time
-- Monthly GMV, order volume, avg order value.

/*
    Key Findings:
    1. December 2016 excluded -- data collection gap (1 delivered order, 
        no other statuses present). Not a business anomaly.
    
    2. November 2017 spike:
            week of Nov 20 saw 2,915 orders vs prior week avg of ~1050
                -- a 131@ increase. Driven by Black Friday (Nov 24) and 
                    Cyber Monday (Nov 27). Decay back to baseline by mid-December
                    confirmes event-driven, not sustained growth.

    3. Consistent month-on-month growth from Jan 2017 through mid-2018,
        suggesting healthy organic platform growth outside of event spikes.
*/

WITH order_revenue AS (
    SELECT
        o.order_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month,
        SUM(p.payment_value) AS order_value
    FROM orders o
    JOIN payments p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
        AND DATE_TRUNC('month', o.order_purchase_timestamp) != '2016-12-01'
    GROUP BY 1, 2
)
SELECT
    order_month,
    COUNT(order_id) AS total_orders,
    ROUND(SUM(order_value)::NUMERIC, 2) AS total_revenue,
    ROUND(AVG(order_value)::NUMERIC, 2) AS avg_order_value
FROM order_revenue
GROUP BY 1
ORDER BY 1;

/*
-- why is December 2016 has just 1 order ?
SELECT 
    DATE_TRUNC('month', order_purchase_timestamp) AS month,
    order_status,
    COUNT(*) AS orders
FROM orders
WHERE order_purchase_timestamp BETWEEN '2016-10-01' AND '2017-02-01'
GROUP BY 1, 2
ORDER BY 1, 2;

-- why is there a spike in November 2017
SELECT
    DATE_TRUNC('week', order_purchase_timestamp) as week,
    COUNT(DISTINCT order_id) AS orders
FROM orders
WHERE order_purchase_timestamp BETWEEN '2017-10-01' AND '2017-12-31'
    AND order_status = 'delivered'
GROUP BY 1
ORDER BY 1;
*/