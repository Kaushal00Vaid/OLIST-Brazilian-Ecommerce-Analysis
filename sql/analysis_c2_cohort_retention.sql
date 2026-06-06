/*
  C2 - Cohort Retention Analysis

  Key findings:
    1. Month-1 retention is near-zero across all cohorts - ranges from
        0.18% to 0.72%. Olist retains fewer than 1 in 100 customers 
        in the month after their first purchase.

    2. Slight improvement in m1 retention across cohorts - early 2017 
        cohorts show ~0.28%, mid-2017 cohorts reach ~0.70%. Directionally
        positive but operationally insignificant at these levels.

    3. No retention curve - scores dont decay gradually, they drop 
        immediately and stay flat. There is no "loyal segment" that 
        emerges over time.

    4. Business model implication: Olist's growth through 2017-2018 
        was entirely acquisition-driven. This is sustainable while 
        the addressable market is expanding, but creates fragility - 
        any slowdown in new customer acquisition has no retention 
        buffer to compensate. Building repeat purchase incentives 
        (loyalty programs, re-engagement campaigns) is the logical 
        next investment.
*/



-- finding each real customer's cohort month
/*
        cohort_month     | cohort_size
    ---------------------+-------------
    2016-09-01 00:00:00 |           1
    2016-10-01 00:00:00 |         262
    2017-01-01 00:00:00 |         718
    2017-02-01 00:00:00 |        1628
    2017-03-01 00:00:00 |        2503
    2017-04-01 00:00:00 |        2256
    2017-05-01 00:00:00 |        3451
    2017-06-01 00:00:00 |        3037
    2017-07-01 00:00:00 |        3752
    2017-08-01 00:00:00 |        4057
    (10 rows)

    - Looks natural and fine
*/
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
        AND DATE_TRUNC('month', o.order_purchase_timestamp) != '2016-12-01'
),
cohort_base AS (
    SELECT
        customer_unique_id,
        MIN(order_month) AS cohort_month
    FROM customer_orders
    GROUP BY 1
)
SELECT
    cohort_month,
    COUNT(DISTINCT customer_unique_id) AS cohort_size
FROM cohort_base
GROUP BY 1
ORDER BY 1
LIMIT 10;

-- full cohort retention matrix
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
      AND DATE_TRUNC('month', o.order_purchase_timestamp) != '2016-12-01'
),
cohort_base AS (
    SELECT
        customer_unique_id,
        MIN(order_month) AS cohort_month
    FROM customer_orders
    GROUP BY 1
),
cohort_activity AS (
    SELECT
        cb.customer_unique_id,
        cb.cohort_month,
        co.order_month,
        EXTRACT(YEAR FROM AGE(co.order_month, cb.cohort_month)) * 12 +
        EXTRACT(MONTH FROM AGE(co.order_month, cb.cohort_month))
            AS months_since_first
    FROM cohort_base cb
    JOIN customer_orders co ON cb.customer_unique_id = co.customer_unique_id
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(DISTINCT customer_unique_id) AS cohort_size
    FROM cohort_base
    GROUP BY 1
)
SELECT
    ca.cohort_month,
    cs.cohort_size,
    ca.months_since_first                               AS month_number,
    COUNT(DISTINCT ca.customer_unique_id)               AS active_customers,
    ROUND(
        COUNT(DISTINCT ca.customer_unique_id)::NUMERIC
        / cs.cohort_size * 100
    , 2)                                                AS retention_pct
FROM cohort_activity ca
JOIN cohort_sizes cs ON ca.cohort_month = cs.cohort_month
GROUP BY 1, 2, 3
ORDER BY 1, 3;

-- full cohort retention matrix in readable format
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL
        AND DATE_TRUNC('month', o.order_purchase_timestamp) != '2016-12-01'
),
cohort_base AS (
    SELECT
        customer_unique_id,
        MIN(order_month) AS cohort_month
    FROM customer_orders
    GROUP BY 1
),
cohort_activity AS (
    SELECT
        cb.customer_unique_id,
        cb.cohort_month,
        EXTRACT(YEAR FROM AGE(co.order_month, cb.cohort_month)) * 12 +
            EXTRACT(MONTH FROM AGE(co.order_month, cb.cohort_month)) AS months_since_first
    FROM cohort_base cb
    JOIN customer_orders co ON co.customer_unique_id = cb.customer_unique_id
),
cohort_sizes AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_unique_id) AS cohort_size
    FROM cohort_base
    GROUP BY 1    
),
retention AS (
    SELECT
        ca.cohort_month,
        cs.cohort_size,
        ca.months_since_first,
        ROUND(
            COUNT(DISTINCT ca.customer_unique_id)::NUMERIC
            / cs.cohort_size * 100
        , 2) AS retention_pct
    FROM cohort_activity as ca
    JOIN cohort_sizes cs ON ca.cohort_month  = cs.cohort_month
    GROUP BY 1, 2, 3
)
SELECT
    cohort_month,
    cohort_size,
    MAX(retention_pct) FILTER (WHERE months_since_first = 0)  AS m0,
    MAX(retention_pct) FILTER (WHERE months_since_first = 1)  AS m1,
    MAX(retention_pct) FILTER (WHERE months_since_first = 2)  AS m2,
    MAX(retention_pct) FILTER (WHERE months_since_first = 3)  AS m3,
    MAX(retention_pct) FILTER (WHERE months_since_first = 4)  AS m4,
    MAX(retention_pct) FILTER (WHERE months_since_first = 5)  AS m5,
    MAX(retention_pct) FILTER (WHERE months_since_first = 6)  AS m6
FROM retention
GROUP BY 1, 2
ORDER BY 1;