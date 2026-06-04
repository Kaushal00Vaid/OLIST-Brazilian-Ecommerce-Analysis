CREATE TABLE customers (
    customer_id               VARCHAR(50) PRIMARY KEY,
    customer_unique_id        VARCHAR(50) NOT NULL,
    customer_zip_code_prefix  INTEGER,
    customer_city             VARCHAR(100),
    customer_state            VARCHAR(2)
);

CREATE TABLE orders (
    order_id                         VARCHAR(50) PRIMARY KEY,
    customer_id                      VARCHAR(50) REFERENCES customers(customer_id),
    order_status                     VARCHAR(20),
    order_purchase_timestamp         TIMESTAMP,
    order_approved_at                TIMESTAMP,
    order_delivered_carrier_date     TIMESTAMP,
    order_delivered_customer_date    TIMESTAMP,
    order_estimated_delivery_date    TIMESTAMP
);

CREATE TABLE product_category_name_translation (
    product_category_name         VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

CREATE TABLE products (
    product_id                 VARCHAR(50) PRIMARY KEY,
    product_category_name      VARCHAR(100) REFERENCES product_category_name_translation(product_category_name)
    product_name_length        SMALLINT,
    product_description_length INTEGER,
    product_photos_qty         SMALLINT,
    product_weight_g           NUMERIC(8, 2),
    product_length_cm          NUMERIC(6, 2),
    product_height_cm          NUMERIC(6, 2),
    product_width_cm           NUMERIC(6, 2)
);

CREATE TABLE sellers (
    seller_id               VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix  INTEGER,
    seller_city             VARCHAR(100),
    seller_state            CHAR(2)
);

CREATE TABLE order_items (
    order_id               VARCHAR(50) REFERENCES orders(order_id),
    order_item_id          SMALLINT,
    product_id             VARCHAR(50) REFERENCES products(product_id),
    seller_id              VARCHAR(50) REFERENCES sellers(seller_id),
    shipping_limit_date    TIMESTAMP
    price                  NUMERIC(10, 2),
    freight_value          NUMERIC(10, 2),

    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE payments (
    order_id VARCHAR(50) REFERENCES orders(order_id),
    payment_sequential SMALLINT,
    payment_type VARCHAR(20),
    payment_installments SMALLINT,
    payment_value NUMERIC(10, 2),

    PRIMARY KEY (order_id, payment_sequential)
);

CREATE TABLE reviews (
    review_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50) REFERENCES orders(order_id),
    review_sccore SMALLINT CHECK (review_score BETWEEN 1 AND 5),
    review_comment_title TEXT,
    review_comment_message TEXT, 
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

CREATE TABLE geolocation (
    geolocation_zip_code_prefix INTEGER,
    geolocation_lat NUMERIC(10, 6),
    geolocation_lng NUMERIC(10, 6),
    geolocation_city VARCHAR(100),
    geolocation_state CHAR(2)
);