CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(100) NOT NULL,
    brand VARCHAR(100),
    price DECIMAL(10, 2) NOT NULL,
    mrp DECIMAL(10, 2) NOT NULL,
    margin_percentage DECIMAL(5, 2),
    shelf_life_days INT,
    min_stock_level INT,
    max_stock_level INT
);

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(15),
    address VARCHAR(100),
    area VARCHAR(100),
    pincode VARCHAR(100),
    registration_date DATE,
    customer_segment VARCHAR(100),
    total_orders INT,
    avg_order_value INT
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    promised_delivery_time TIMESTAMP NOT NULL,
    actual_delivery_time TIMESTAMP,
    delivery_status VARCHAR(50),
    order_total DECIMAL(10, 2) NOT NULL,
    payment_method VARCHAR(50),
    delivery_partner_id INT,
    store_id INT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE customer_feedback (
    feedback_id INT PRIMARY KEY,
    order_id INT NOT NULL,
    customer_id INT NOT NULL,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    feedback_text TEXT,
    feedback_category VARCHAR(100),
    sentiment VARCHAR(50),
    feedback_date DATE,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE delivery_performance (
    order_id INT NOT NULL,
    delivery_partner_id INT NOT NULL,
    promised_time TIMESTAMP NOT NULL,
    actual_time TIMESTAMP,
    delivery_time_minutes INT,
    distance_km DECIMAL(5, 2),
    delivery_status VARCHAR(50),
    reasons_if_delayed TEXT,
    PRIMARY KEY (order_id, delivery_partner_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE inventory (
    product_id INT NOT NULL,
    date DATE NOT NULL,
    stock_received INT,
    damaged_stock INT,
    PRIMARY KEY (product_id, date),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE marketing_performance (
    campaign_id INT PRIMARY KEY,
    campaign_name VARCHAR(255) NOT NULL,
    date DATE NOT NULL,
    target_audience VARCHAR(255),
    channel VARCHAR(100) NOT NULL,
    impressions INT,
    clicks INT,
    conversions INT,
    spend DECIMAL(10, 2),
    revenue_generated DECIMAL(10, 2),
    roas DECIMAL(5, 2)
);

CREATE TABLE rating_icon (
    rating TEXT,
    emoji TEXT,
    star TEXT
);
