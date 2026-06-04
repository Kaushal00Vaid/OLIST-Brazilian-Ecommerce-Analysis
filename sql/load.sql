\COPY product_category_name_translation FROM '/data/product_category_name_translation.csv' CSV HEADER;
\COPY customers FROM '/data/olist_customers_dataset.csv' CSV HEADER;
\COPY sellers FROM '/data/olist_sellers_dataset.csv' CSV HEADER;
\COPY products FROM '/data/olist_products_dataset.csv' CSV HEADER;
\COPY orders FROM '/data/olist_orders_dataset.csv' CSV HEADER;
\COPY order_items FROM '/data/olist_order_items_dataset.csv' CSV HEADER;
\COPY payments FROM '/data/olist_order_payments_dataset.csv' CSV HEADER;
COPY reviews (review_id, order_id, review_score, review_comment_title, review_comment_message, review_creation_date, review_answer_timestamp)
FROM '/data/olist_order_reviews_dataset.csv' CSV HEADER;
\COPY geolocation FROM '/data/olist_geolocation_dataset.csv' CSV HEADER;