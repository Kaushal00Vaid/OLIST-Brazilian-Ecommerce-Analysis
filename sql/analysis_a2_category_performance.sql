/*
    A2 - Category Performance

    Key findings:
        1. Top 5 Categories capture 39.83% of revenue across 70+ categories
            This means healthy diversification, no dangerous concentration in 
            one category.
            
            For example:-  If health_beauty disappeared tomorrow, Olist loses 9%, 
                            painful but survivable.

        2. health_beauty leads revenue (9.33%) but watches_gifts has highest
            avg item price (199 BRL). Platform has both volume players
            (bed_bath_table) and value players (watches_gifts)
            Different unit economics, different retention strategies needed

            bed_bath_table — 9,272 orders, avg price 93 BRL. High volume, 
            low margin per item. 
            The business problem: needs massive order volume to generate 
            meaningful revenue.

            office_furniture — 1,254 orders, avg price 161 BRL. 
            Low volume, high price. 
            The business problem: small customer base, harder to grow, 
            but each sale is worth more. Risk is that one bad month 
            tanks the category revenue.

        3. items_per_order is low platform-wide (max 1.33 in office_furniture).
            Complimentary purchasing 
            (a desk and a chair, two chairs, a shelf and a cabinet.) 
            drives multi-item orders in furniture,
            not consumables - opposite of offline/wholesale behaviour.
            Suggests significant cross-sell opportunity exists.
*/

-- best performing categories
WITH category_stats AS (
    SELECT
        COALESCE(t.product_category_name_english, p.product_category_name, 'uncategorized') AS category,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(SUM(oi.price)::NUMERIC, 2) AS total_revenue,
        ROUND(AVG(oi.price)::NUMERIC, 2) AS avg_item_price,
        COUNT(oi.order_item_id) AS total_items_sold
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p ON p.product_id = oi.product_id
    LEFT JOIN product_category_name_translation t
        ON p.product_category_name = t.product_category_name
    WHERE o.order_status = 'delivered'
        AND DATE_TRUNC('month', o.order_purchase_timestamp) != '2016-12-01'
    GROUP BY 1
),
total AS (
    SELECT SUM(total_revenue) AS platform_revenue FROM category_stats
)
SELECT 
    c.category,
    c.total_orders,
    c.total_items_sold,
    c.total_revenue,
    c.avg_item_price,
    ROUND((c.total_revenue / t.platform_revenue * 100)::NUMERIC, 2) AS revenue_share_pct
FROM category_stats c
CROSS JOIN total t
ORDER BY c.total_revenue DESC
LIMIT 15;


-- hidden underperforming categories
WITH category_stats AS (
    SELECT
        COALESCE(t.product_category_name_english, p.product_category_name, 'uncategorized') AS category,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(SUM(oi.price)::NUMERIC, 2) AS total_revenue,
        ROUND(AVG(oi.price)::NUMERIC, 2) AS avg_item_price,
        COUNT(oi.order_item_id) AS total_items_sold
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p ON p.product_id = oi.product_id
    LEFT JOIN product_category_name_translation t
        ON p.product_category_name = t.product_category_name
    WHERE o.order_status = 'delivered'
        AND DATE_TRUNC('month', o.order_purchase_timestamp) != '2016-12-01'
    GROUP BY 1
)
SELECT 
    category,
    total_orders,
    total_revenue,
    avg_item_price,
    ROUND((total_items_sold::NUMERIC / total_orders), 2) AS items_per_order
FROM category_stats
WHERE total_orders > 500
ORDER BY items_per_order DESC
LIMIT 10;