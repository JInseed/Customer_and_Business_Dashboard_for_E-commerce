# Schema 생성
CREATE TABLE campaign_product_subcategory (
    campaign_product_subcategory_id INT NOT NULL AUTO_INCREMENT,
    campaign_id INT,
    subcategory_id INT,
    discount DECIMAL(5,2),
    PRIMARY KEY (campaign_product_subcategory_id)
);

CREATE TABLE supplier (
    supplier_id INT NOT NULL AUTO_INCREMENT,
    supplier_name VARCHAR(255),
    email VARCHAR(255),
    PRIMARY KEY (supplier_id)
);

CREATE TABLE category (
    category_id INT NOT NULL AUTO_INCREMENT,
    category_name VARCHAR(50),
    PRIMARY KEY (category_id)
);

CREATE TABLE subcategory (
    subcategory_id INT NOT NULL AUTO_INCREMENT,
    subcategory_name VARCHAR(50),
    category_id INT,
    PRIMARY KEY (subcategory_id),
    FOREIGN KEY (category_id) REFERENCES category(category_id)
);

CREATE TABLE customer (
    customer_id INT NOT NULL AUTO_INCREMENT,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    email VARCHAR(255),
    country VARCHAR(100),
    PRIMARY KEY (customer_id),
    UNIQUE KEY email (email)
);

CREATE TABLE product (
    product_id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(255),
    price DECIMAL(10,2),
    description TEXT,
    subcategory_id INT,
    PRIMARY KEY (product_id),
    FOREIGN KEY (subcategory_id) REFERENCES subcategory(subcategory_id)
);

CREATE TABLE marketing_campaigns (
    campaign_id INT NOT NULL AUTO_INCREMENT,
    campaign_name VARCHAR(255),
    offer_week INT,
    PRIMARY KEY (campaign_id)
);

CREATE TABLE payment_method (
    payment_method_id INT NOT NULL AUTO_INCREMENT,
    payment_method VARCHAR(50),
    PRIMARY KEY (payment_method_id)
);

CREATE TABLE orders (
    order_id_surrogate INT NOT NULL AUTO_INCREMENT,
    order_id INT,
    customer_id INT,
    order_date DATE,
    campaign_id INT,
    amount INT,
    payment_method_id INT,
    PRIMARY KEY (order_id_surrogate),
    UNIQUE KEY order_id (order_id),
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    FOREIGN KEY (campaign_id) REFERENCES marketing_campaigns(campaign_id),
    FOREIGN KEY (payment_method_id) REFERENCES payment_method(payment_method_id)
);

CREATE TABLE orderitem (
    orderitem_id INT NOT NULL AUTO_INCREMENT,
    order_id INT,
    product_id INT,
    quantity INT,
    supplier_id INT,
    subtotal DECIMAL(10,2),
    discount DECIMAL(5,2),
    PRIMARY KEY (orderitem_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES product(product_id),
    FOREIGN KEY (supplier_id) REFERENCES supplier(supplier_id)
);


CREATE TABLE customer_product_ratings (
    customerproductrating_id INT NOT NULL AUTO_INCREMENT,
    customer_id INT,
    product_id INT,
    ratings DECIMAL(2,1),
    review VARCHAR(255),
    sentiment VARCHAR(10),
    CONSTRAINT customerproductrating_ratings_check CHECK (ratings BETWEEN 1 AND 5),
    PRIMARY KEY (customerproductrating_id),
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    FOREIGN KEY (product_id) REFERENCES product(product_id)
);


CREATE TABLE returns (
    return_id INT NOT NULL AUTO_INCREMENT,
    order_id INT,
    product_id INT,
    return_date DATE,
    reason TEXT,
    amount_refunded DECIMAL(10,2),
    PRIMARY KEY (return_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES product(product_id)
);



