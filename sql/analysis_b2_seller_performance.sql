/*
  B2 — Seller Performance Ranking

    Methodology note: NTILE quartile ranking alone is insufficient for 
    identifying problem sellers — review scores are compressed (3.5–5.0 range),
    so relative ranking mislabels good sellers as bad. Applied absolute 
    thresholds: late_rate > 10% AND avg_review_score < 4.0.

    Key findings:
        1. 21 high-revenue sellers (revenue_quartile = 1) meet both problem 
            thresholds. Combined they represent significant GMV while actively 
            degrading platform reputation.

        2. Top revenue risk: seller 4a3ca9 (SP) — 1,772 orders, 199k revenue,
            3.83 score, 11% late rate. Highest revenue among problem sellers.

        3. Worst customer experience: seller 2eb7024 (SP) — 2.81 avg review 
            score, 13.9% late rate. Likely generating repeat complaints.

        4. Worst late rate: seller 712e6ed (SC) — 22.08% late rate. Nearly 
            1 in 4 orders arrives late.

        5. SP dominates problem seller list (18/21) due to base rate — most 
            sellers are SP-based. Southern sellers shipping to northeastern 
            customers explains the overlap with B1 findings.

    Recommendation: Olist should implement a seller scorecard with 
    automated warnings at late_rate > 10% or review_score < 4.0, 
    and suspension review at late_rate > 15% or review_score < 3.5.
*/

-- core seller metrics
WITH seller_metrics AS (
    SELECT oi.seller_id,
        s.seller_state,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        ROUND(SUM(oi.price)::NUMERIC, 2) AS total_revenue,
        ROUND(AVG(oi.price)::NUMERIC, 2) AS avg_item_price,
        COUNT(DISTINCT oi.order_id) FILTER (
            WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
        ) AS late_orders,
        ROUND(AVG(r.review_score)::NUMERIC, 2) AS avg_review_score
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    JOIN sellers s ON oi.seller_id = s.seller_id
    LEFT JOIN reviews r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND DATE_TRUNC('month', o.order_purchase_timestamp) != '2016-12-01'
    GROUP BY 1, 2
)
SELECT
    seller_id,
    seller_state,
    total_orders,
    total_revenue,
    avg_item_price,
    late_orders,
    ROUND(late_orders::NUMERIC / total_orders * 100, 2) AS late_rate_pct,
    avg_review_score
FROM seller_metrics
WHERE total_orders >= 50
ORDER BY total_revenue DESC
LIMIT 20;

-- percentile ranking
WITH seller_metrics AS (
    SELECT
        oi.seller_id,
        s.seller_state,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        ROUND(SUM(oi.price)::NUMERIC, 2) AS total_revenue,
        ROUND(AVG(r.review_score)::NUMERIC, 2) AS avg_review_score,
        ROUND(
            COUNT(DISTINCT oi.order_id) FILTER (
                WHERE o.order_status = 'delivered'
                    AND o.order_delivered_customer_date > o.order_estimated_delivery_date
            )::NUMERIC / COUNT(DISTINCT oi.order_id) * 100
        , 2) AS late_rate_pct
    
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN sellers s ON oi.seller_id = s.seller_id
    LEFT JOIN reviews r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND DATE_TRUNC('month', o.order_purchase_timestamp) != '2016-12-01'
    GROUP BY 1, 2
    HAVING COUNT(DISTINCT oi.order_id) >= 50
),
ranked AS (
    SELECT
        seller_id,
        seller_state,
        total_orders,
        total_revenue,
        avg_review_score,
        late_rate_pct,
        /*
            NTILE(4) splits sellers into quartiles. Quartile 1 = best, quartile 4 = worst
        */
        NTILE(4) OVER (ORDER BY total_revenue DESC) AS revenue_quartile,
        NTILE(4) OVER (ORDER BY late_rate_pct DESC) AS late_quartile,
        NTILE(4) OVER (ORDER BY avg_review_score ASC) AS review_quartile
    FROM seller_metrics
)
SELECT
    seller_id,
    seller_state,
    total_orders,
    total_revenue,
    avg_review_score,
    late_rate_pct,
    revenue_quartile,
    late_quartile,
    review_quartile,
    /*
        problem_score = late_quartile + review_quartile. 
        Max score is 8 - worst possible on both dimensions.
        A high-revenue seller with problem_score 8 is the most dangerous seller: 
            making money for the platform while actively destroying customer trust.
        find sellers where revenue_quartile = 1 (top earners) AND problem_score >= 6
    */
    (late_quartile + review_quartile) AS problem_score
FROM ranked
ORDER BY problem_score DESC, total_revenue DESC
LIMIT 20;

-- getting only those problem sellers -- top earners with problem_score >= 6
WITH seller_metrics AS (
    SELECT
        oi.seller_id,
        s.seller_state,
        COUNT(DISTINCT oi.order_id)                         AS total_orders,
        ROUND(SUM(oi.price)::NUMERIC, 2)                    AS total_revenue,
        ROUND(AVG(r.review_score)::NUMERIC, 2)              AS avg_review_score,
        ROUND(
            COUNT(DISTINCT oi.order_id) FILTER (
                WHERE o.order_delivered_customer_date
                    > o.order_estimated_delivery_date
            )::NUMERIC / COUNT(DISTINCT oi.order_id) * 100
        , 2)                                                AS late_rate_pct
    FROM order_items oi
    JOIN orders o  ON oi.order_id  = o.order_id
    JOIN sellers s ON oi.seller_id = s.seller_id
    LEFT JOIN reviews r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND DATE_TRUNC('month', o.order_purchase_timestamp) != '2016-12-01'
    GROUP BY 1, 2
    HAVING COUNT(DISTINCT oi.order_id) >= 50
),
ranked AS (
    SELECT *,
        NTILE(4) OVER (ORDER BY total_revenue DESC)     AS revenue_quartile,
        NTILE(4) OVER (ORDER BY late_rate_pct DESC)     AS late_quartile,
        NTILE(4) OVER (ORDER BY avg_review_score ASC)   AS review_quartile
    FROM seller_metrics
)
SELECT
    seller_id,
    seller_state,
    total_orders,
    total_revenue,
    avg_review_score,
    late_rate_pct,
    (late_quartile + review_quartile) AS problem_score
FROM ranked
WHERE revenue_quartile = 1
--   AND (late_quartile + review_quartile) >= 6
    AND late_rate_pct > 10
    AND avg_review_score < 4.0
ORDER BY problem_score DESC, total_revenue DESC;