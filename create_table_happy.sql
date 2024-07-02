CREATE TABLE users1 (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE orders1 (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    total_price DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user1
        FOREIGN KEY(user_id) 
        REFERENCES users1(id)
);


CREATE TABLE order_items1 (
    id SERIAL PRIMARY KEY,
    order_id INTEGER,
    product_name VARCHAR(100),
    price DECIMAL(10, 2),
    quantity INTEGER,
    CONSTRAINT fk_order1
        FOREIGN KEY(order_id) 
        REFERENCES orders1(id)
);


INSERT INTO users1 (name, email, created_at)
SELECT 
    md5(random()::text) AS name, 
    md5(random()::text) || '@example.com' AS email, 
    NOW() - (random() * interval '365 days') AS created_at
FROM generate_series(1, 1000000);

WITH max_user_id AS (
    SELECT MAX(id) AS max_id FROM users1
)

INSERT INTO orders1 (user_id, total_price, created_at)
SELECT 
    (RANDOM() * (SELECT max_id FROM max_user_id))::INTEGER + 1 AS user_id, 
    (RANDOM() * 1000)::NUMERIC(10, 2) AS total_price, 
    NOW() - (random() * interval '365 days') AS created_at
FROM generate_series(1, 1000000);


DO
$$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN (SELECT id FROM orders1) LOOP
        INSERT INTO order_items1 (order_id, product_name, price, quantity)
        SELECT 
            rec.id AS order_id, 
            md5(random()::text) AS product_name, 
            (RANDOM() * 100)::NUMERIC(10, 2) AS price, 
            (RANDOM() * 10 + 1)::INTEGER AS quantity
        FROM generate_series(1, 10);  
    END LOOP;
END
$$;


