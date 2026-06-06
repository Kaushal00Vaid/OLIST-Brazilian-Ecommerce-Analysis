/*
    C1 - review_score analysis

    Key Findings:
        1. Positive Skewed Distribution of reviews in platform - 
            59.22% score 5, but 9.76% score 1.
            Score 1 is 3x more common than score 2, suggesting dissatisfied
            customers express maximum displeasure rather than moderate ratings.

        2. Late delivery is the dominant satisfaction driver:
            - On time avg score: 4.294 | pct score 1-or-2: 9.23%
            - Late avg score: 2.566 | pct score 1-or-2: 54.03%
            A late delivery makes a bad review (score 1-or-2) 5.85x more likely.
        
        3. Customer tolerance cliff is at 4-7 days past estimate:
            - 1-3 days late: avg 3.72 (customers still forgiving)
            - 4-7 days late: avg 2.29 (cliff — tolerance breaks here)
            - 8-14 days late: avg 1.74 (angry, no further degradation)
            - 14+ days late:  avg 1.71 (essentially same as 8-14)
        
        4. threshold recommendation: Olist's intervention threshold should 
            be 4 days, not 7, not 14. If a delivery is going to 
            cross 4 days past estimate, proactive customer communication 
            or compensation should trigger automatically.
            Beyond 8 days, marginal damage plateaus — the customer has decided.
*/


-- overall score distrbution - percentage
SELECT
    review_score,
    COUNT(*) AS total_reviews,
    ROUND(COUNT(*)::NUMERIC /SUM(COUNT(*)) OVER () * 100, 2) AS pct_of_total
FROM reviews r
JOIN orders o ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
    AND DATE_TRUNC('month', o.order_purchase_timestamp) != '2016-12-01'
GROUP BY 1
ORDER BY 1;

-- score dist split by on-time vs late
WITH delivery_flag AS (
    SELECT
        o.order_id,
        r.review_score,
        CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 'late'
            ELSE 'on_time'
        END AS delivery_status
    FROM orders o
    JOIN reviews r ON r.order_id = o.order_id
    WHERE o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        AND DATE_TRUNC('month', o.order_purchase_timestamp) != '2016-12-01'
)
SELECT
    delivery_status,
    review_score,
    COUNT(*) AS total,
    ROUND(COUNT(*)::Numeric / SUM(COUNT(*)) OVER (
        PARTITION BY delivery_status
    ) * 100, 2) AS pct_within_status
FROM delivery_flag
GROUP BY 1, 2
ORDER BY 1, 2;

-- quantifying the damage
WITH delivery_flag AS (
    SELECT
        o.order_id,
        r.review_score,
        CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 'late'
            ELSE 'on_time'
        END AS delivery_status,
        ROUND(
            EXTRACT(EPOCH FROM (
                o.order_delivered_customer_date - o.order_estimated_delivery_date
            )) / 86400
        ) AS days_late
    FROM orders o
    JOIN reviews r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        AND DATE_TRUNC('month', o.order_purchase_timestamp) != '2016-12-01'
)
SELECT
    delivery_status,
    COUNT(*) AS total_orders,
    ROUND(AVG(review_score)::NUMERIC, 3) AS avg_review_score,
    ROUND(AVG(CASE WHEN review_score <= 2
        THEN 1.0 ELSE 0.0 END)::NUMERIC * 100, 2) AS pct_score_1_or_2,
    ROUND(AVG(CASE WHEN review_score = 5
        THEN 1.0 ELSE 0.0 END)::NUMERIC * 100, 2) AS pct_score_5
FROM delivery_flag
GROUP BY 1
ORDER BY 1;

-- how score degrade as delay increases
WITH delivery_flag AS (
    SELECT r.review_score,
        ROUND(
            EXTRACT(EPOCH FROM (
                o.order_delivered_customer_date - o.order_estimated_delivery_date
            )) / 86400
        ) AS days_late
    FROM orders o
    JOIN reviews r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        AND o.order_delivered_customer_date > o.order_estimated_delivery_date
        AND DATE_TRUNC('month', o.order_purchase_timestamp) != '2016-12-01'
)
SELECT
    CASE
        WHEN days_late BETWEEN 1 AND 3 THEN '1-3 days late'
        WHEN days_late BETWEEN 4 AND 7 THEN '4-7 days late'
        WHEN days_late BETWEEN 8 AND 14 THEN '8-14 days late'
        WHEN days_late > 14 THEN '14+ days late'
    END AS delay_bucket,
    COUNT(*) AS total_orders,
    ROUND(AVG(review_score)::NUMERIC, 3) AS avg_review_score,
    ROUND(AVG(CASE WHEN review_score <= 2
        THEN 1.0 ELSE 0.0 END)::NUMERIC * 100, 2) AS pct_score_1_or_2
FROM delivery_flag
WHERE days_late > 0
GROUP BY 1
ORDER BY MIN(days_late);