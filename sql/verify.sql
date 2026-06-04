SELECT 'customers' AS tbl, COUNT(*) FROM customers 
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'reviews', COUNT(*) FROM reviews
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'geolocation', COUNT(*) FROM geolocation;


SELECT
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS missing_delivery_date,
    COUNT(*) FILTER (WHERE order_delivered_customer_date > order_estimated_delivery_date) AS late_orders,
    COUNT(*) FILTER (WHERE order_status = 'delivered') AS delivered_count
FROM orders;