from sqlalchemy import create_engine
import pandas as pd

engine = create_engine("postgresql://postgres:olist123@localhost:5432/olist")

# A1
a1 = pd.read_sql("""
    WITH order_revenue AS (
        SELECT o.order_id,
            DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month,
            SUM(p.payment_value) AS order_value
        FROM orders o JOIN payments p ON o.order_id = p.order_id
        WHERE o.order_status = 'delivered'
          AND DATE_TRUNC('month', o.order_purchase_timestamp) != '2016-12-01'
        GROUP BY 1, 2
    )
    SELECT order_month, COUNT(order_id) AS total_orders,
           ROUND(SUM(order_value)::NUMERIC, 2) AS total_revenue,
           ROUND(AVG(order_value)::NUMERIC, 2) AS avg_order_value
    FROM order_revenue GROUP BY 1 ORDER BY 1
""", engine)
a1 = a1[a1['order_month'] < '2018-08-01']
a1.to_csv("dashboard/data/a1_revenue.csv", index=False)

# A2
a2 = pd.read_sql("""
    WITH category_stats AS (
        SELECT COALESCE(t.product_category_name_english,
                        p.product_category_name, 'uncategorized') AS category,
               ROUND(SUM(oi.price)::NUMERIC, 2) AS total_revenue,
               COUNT(DISTINCT o.order_id) AS total_orders,
               ROUND(AVG(oi.price)::NUMERIC, 2) AS avg_item_price
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        JOIN products p ON oi.product_id = p.product_id
        LEFT JOIN product_category_name_translation t
               ON p.product_category_name = t.product_category_name
        WHERE o.order_status = 'delivered'
          AND DATE_TRUNC('month', o.order_purchase_timestamp) != '2016-12-01'
        GROUP BY 1
    ), total AS (SELECT SUM(total_revenue) AS platform_revenue FROM category_stats)
    SELECT c.category, c.total_revenue, c.total_orders, c.avg_item_price,
           ROUND((c.total_revenue/t.platform_revenue*100)::NUMERIC,2) AS revenue_share_pct
    FROM category_stats c CROSS JOIN total t
    ORDER BY c.total_revenue DESC LIMIT 15
""", engine)
a2.to_csv('dashboard/data/a2_categories.csv', index=False)

# B1
b1 = pd.read_sql("""
    SELECT c.customer_state AS state,
           COUNT(*) AS total_delivered,
           ROUND(AVG(EXTRACT(EPOCH FROM (
               o.order_delivered_customer_date - o.order_purchase_timestamp
           ))/86400)::NUMERIC,1) AS avg_delivery_days,
           ROUND(COUNT(*) FILTER (
               WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
           )::NUMERIC / COUNT(*) * 100, 2) AS late_rate_pct
    FROM orders o JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND DATE_TRUNC('month', o.order_purchase_timestamp) != '2016-12-01'
    GROUP BY 1 ORDER BY avg_delivery_days DESC
""", engine)
b1.to_csv('dashboard/data/b1_delivery.csv', index=False)

# B2
b2 = pd.read_sql("""
    SELECT oi.seller_id, s.seller_state,
           COUNT(DISTINCT oi.order_id) AS total_orders,
           ROUND(SUM(oi.price)::NUMERIC,2) AS total_revenue,
           ROUND(AVG(r.review_score)::NUMERIC,2) AS avg_review_score,
           ROUND(COUNT(DISTINCT oi.order_id) FILTER (
               WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
           )::NUMERIC / COUNT(DISTINCT oi.order_id) * 100, 2) AS late_rate_pct
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN sellers s ON oi.seller_id = s.seller_id
    LEFT JOIN reviews r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND DATE_TRUNC('month', o.order_purchase_timestamp) != '2016-12-01'
    GROUP BY 1, 2
    HAVING COUNT(DISTINCT oi.order_id) >= 50
""", engine)
b2.to_csv('dashboard/data/b2_sellers.csv', index=False)

# c1
c1 = pd.read_sql("""
    WITH delivery_flag AS (
        SELECT r.review_score,
               ROUND(EXTRACT(EPOCH FROM (
                   o.order_delivered_customer_date - o.order_estimated_delivery_date
               ))/86400) AS days_late
        FROM orders o JOIN reviews r ON o.order_id = r.order_id
        WHERE o.order_status = 'delivered'
          AND o.order_delivered_customer_date IS NOT NULL
          AND o.order_estimated_delivery_date IS NOT NULL
          AND o.order_delivered_customer_date > o.order_estimated_delivery_date
          AND DATE_TRUNC('month', o.order_purchase_timestamp) != '2016-12-01'
    )
    SELECT CASE
               WHEN days_late BETWEEN 1 AND 3  THEN '1-3 days'
               WHEN days_late BETWEEN 4 AND 7  THEN '4-7 days'
               WHEN days_late BETWEEN 8 AND 14 THEN '8-14 days'
               WHEN days_late > 14             THEN '14+ days'
           END AS delay_bucket,
           ROUND(AVG(review_score)::NUMERIC,3) AS avg_review_score,
           ROUND(AVG(CASE WHEN review_score <= 2 THEN 1.0 ELSE 0.0 END)::NUMERIC*100,2) AS pct_bad_review
    FROM delivery_flag WHERE days_late > 0
    GROUP BY 1 ORDER BY MIN(days_late)
""", engine)
c1.to_csv('dashboard/data/c1_delay_buckets.csv', index=False)

