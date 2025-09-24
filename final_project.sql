-- E-commerce Store Database Management System
-- Created by: Database System
-- Date: 2025-09-25

-- Database
CREATE DATABASE IF NOT EXISTS ecommerce_store;
USE ecommerce_store;

-- 1. Users Table (Customers and Administrators)
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone_number VARCHAR(20),
    date_of_birth DATE,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,
    user_type ENUM('customer', 'admin', 'vendor') DEFAULT 'customer',
    CONSTRAINT chk_valid_email CHECK (email LIKE '%@%.%')
);

-- 2. Addresses Table (Customer Addresses)
CREATE TABLE addresses (
    address_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    address_type ENUM('billing', 'shipping') DEFAULT 'shipping',
    street_address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_address (user_id, address_type)
);

-- 3. Categories Table (Product Categories Hierarchy)
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) UNIQUE NOT NULL,
    parent_category_id INT NULL,
    category_description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_category_id) REFERENCES categories(category_id) ON DELETE SET NULL,
    INDEX idx_parent_category (parent_category_id)
);

-- 4. Products Table
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    product_description TEXT,
    category_id INT NOT NULL,
    sku VARCHAR(50) UNIQUE NOT NULL,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    compare_at_price DECIMAL(10,2) CHECK (compare_at_price >= 0),
    cost_price DECIMAL(10,2) CHECK (cost_price >= 0),
    quantity_in_stock INT NOT NULL DEFAULT 0 CHECK (quantity_in_stock >= 0),
    weight DECIMAL(8,2) CHECK (weight >= 0),
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE RESTRICT,
    INDEX idx_category (category_id),
    INDEX idx_sku (sku),
    INDEX idx_price (price)
);

-- 5. Product Images Table (One-to-Many relationship with Products)
CREATE TABLE product_images (
    image_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    alt_text VARCHAR(200),
    is_primary BOOLEAN DEFAULT FALSE,
    display_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    UNIQUE KEY unique_primary_image (product_id, is_primary),
    INDEX idx_product_images (product_id, display_order)
);

-- 6. Orders Table
CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    order_status ENUM('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded') DEFAULT 'pending',
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2) NOT NULL CHECK (total_amount >= 0),
    tax_amount DECIMAL(10,2) DEFAULT 0 CHECK (tax_amount >= 0),
    shipping_amount DECIMAL(10,2) DEFAULT 0 CHECK (shipping_amount >= 0),
    discount_amount DECIMAL(10,2) DEFAULT 0 CHECK (discount_amount >= 0),
    final_amount DECIMAL(10,2) NOT NULL CHECK (final_amount >= 0),
    shipping_address_id INT NOT NULL,
    billing_address_id INT NOT NULL,
    payment_method ENUM('credit_card', 'debit_card', 'paypal', 'stripe', 'cod') NOT NULL,
    payment_status ENUM('pending', 'completed', 'failed', 'refunded') DEFAULT 'pending',
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE RESTRICT,
    FOREIGN KEY (shipping_address_id) REFERENCES addresses(address_id),
    FOREIGN KEY (billing_address_id) REFERENCES addresses(address_id),
    INDEX idx_user_orders (user_id),
    INDEX idx_order_status (order_status),
    INDEX idx_order_date (order_date)
);

-- 7. Order Items Table (Many-to-Many relationship between Orders and Products)
CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    total_price DECIMAL(10,2) NOT NULL CHECK (total_price >= 0),
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT,
    UNIQUE KEY unique_order_product (order_id, product_id),
    INDEX idx_order_items (order_id)
);

-- 8. Inventory Transactions Table (Track stock movements)
CREATE TABLE inventory_transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    transaction_type ENUM('purchase', 'sale', 'return', 'adjustment', 'damage') NOT NULL,
    quantity_change INT NOT NULL,
    previous_quantity INT NOT NULL,
    new_quantity INT NOT NULL,
    reference_id INT NULL, -- Links to order_id or purchase_order_id
    notes TEXT,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by INT NOT NULL, -- User who performed the transaction
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(user_id),
    INDEX idx_product_transactions (product_id, transaction_date)
);

-- 9. Reviews Table (Customer reviews for products)
CREATE TABLE reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    user_id INT NOT NULL,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(200),
    review_text TEXT,
    is_approved BOOLEAN DEFAULT FALSE,
    helpful_votes INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_product_review (user_id, product_id),
    INDEX idx_product_reviews (product_id, rating),
    INDEX idx_user_reviews (user_id)
);

-- 10. Shopping Cart Table
CREATE TABLE shopping_cart (
    cart_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
    added_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_product_cart (user_id, product_id),
    INDEX idx_user_cart (user_id)
);

-- 11. Wishlist Table
CREATE TABLE wishlist (
    wishlist_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    added_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_product_wishlist (user_id, product_id),
    INDEX idx_user_wishlist (user_id)
);

-- 12. Coupons/Discounts Table
CREATE TABLE coupons (
    coupon_id INT AUTO_INCREMENT PRIMARY KEY,
    coupon_code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    discount_type ENUM('percentage', 'fixed_amount') DEFAULT 'percentage',
    discount_value DECIMAL(10,2) NOT NULL CHECK (discount_value >= 0),
    minimum_order_amount DECIMAL(10,2) DEFAULT 0 CHECK (minimum_order_amount >= 0),
    maximum_discount_amount DECIMAL(10,2) CHECK (maximum_discount_amount >= 0),
    usage_limit INT DEFAULT NULL,
    used_count INT DEFAULT 0 CHECK (used_count >= 0),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (end_date >= start_date),
    INDEX idx_coupon_code (coupon_code),
    INDEX idx_coupon_dates (start_date, end_date)
);

-- 13. Order Coupons Table (Many-to-Many relationship between Orders and Coupons)
CREATE TABLE order_coupons (
    order_coupon_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    coupon_id INT NOT NULL,
    discount_amount DECIMAL(10,2) NOT NULL CHECK (discount_amount >= 0),
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (coupon_id) REFERENCES coupons(coupon_id) ON DELETE RESTRICT,
    UNIQUE KEY unique_order_coupon (order_id, coupon_id)
);

-- 14. Shipping Methods Table
CREATE TABLE shipping_methods (
    method_id INT AUTO_INCREMENT PRIMARY KEY,
    method_name VARCHAR(100) NOT NULL,
    description TEXT,
    cost DECIMAL(10,2) NOT NULL CHECK (cost >= 0),
    estimated_days VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 15. Order Shipping Table (One-to-One relationship with Orders)
CREATE TABLE order_shipping (
    order_shipping_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT UNIQUE NOT NULL,
    shipping_method_id INT NOT NULL,
    tracking_number VARCHAR(100),
    shipped_date TIMESTAMP NULL,
    estimated_delivery DATE,
    actual_delivery_date TIMESTAMP NULL,
    carrier_name VARCHAR(100),
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (shipping_method_id) REFERENCES shipping_methods(method_id) ON DELETE RESTRICT,
    INDEX idx_tracking (tracking_number)
);

-- Data for Demonstration
INSERT INTO users (username, email, password_hash, first_name, last_name, phone_number, user_type) VALUES
('admin', 'admin@estore.com', 'hashed_password_123', 'System', 'Administrator', '+1234567890', 'admin'),
('john_doe', 'john.doe@email.com', 'hashed_password_456', 'John', 'Doe', '+1234567891', 'customer'),
('jane_smith', 'jane.smith@email.com', 'hashed_password_789', 'Jane', 'Smith', '+1234567892', 'customer');

INSERT INTO categories (category_name, parent_category_id, category_description) VALUES
('Electronics', NULL, 'All electronic devices and accessories'),
('Computers', 1, 'Computers, laptops, and related equipment'),
('Smartphones', 1, 'Mobile phones and smartphones'),
('Clothing', NULL, 'Fashion and apparel'),
('Books', NULL, 'Books and educational materials');

INSERT INTO products (product_name, product_description, category_id, sku, price, compare_at_price, quantity_in_stock) VALUES
('iPhone 15 Pro', 'Latest Apple smartphone with advanced features', 3, 'IP15PRO-256', 999.99, 1099.99, 50),
('MacBook Air M2', 'Apple laptop with M2 chip', 2, 'MBA-M2-13', 1199.99, 1299.99, 25),
('Samsung Galaxy S24', 'Latest Samsung flagship smartphone', 3, 'SGS24-256', 899.99, 999.99, 40),
('Wireless Headphones', 'High-quality wireless headphones', 1, 'WH-1000XM4', 299.99, 349.99, 100);

INSERT INTO addresses (user_id, address_type, street_address, city, state, country, postal_code, is_default) VALUES
(2, 'shipping', '123 Main St', 'New York', 'NY', 'USA', '10001', TRUE),
(2, 'billing', '123 Main St', 'New York', 'NY', 'USA', '10001', TRUE),
(3, 'shipping', '456 Oak Ave', 'Los Angeles', 'CA', 'USA', '90210', TRUE);

INSERT INTO coupons (coupon_code, description, discount_type, discount_value, minimum_order_amount, usage_limit, start_date, end_date) VALUES
('WELCOME10', 'Welcome discount for new customers', 'percentage', 10.00, 50.00, 1000, '2024-01-01', '2024-12-31'),
('FREESHIP', 'Free shipping on orders above $100', 'fixed_amount', 15.00, 100.00, NULL, '2024-01-01', '2024-12-31');

INSERT INTO shipping_methods (method_name, description, cost, estimated_days) VALUES
('Standard Shipping', 'Regular shipping method', 5.99, '3-5 business days'),
('Express Shipping', 'Fast shipping method', 12.99, '1-2 business days'),
('Overnight Shipping', 'Next day delivery', 24.99, 'Next business day');

-- Views for Common Queries
CREATE VIEW product_catalog AS
SELECT 
    p.product_id,
    p.product_name,
    p.product_description,
    c.category_name,
    p.sku,
    p.price,
    p.compare_at_price,
    p.quantity_in_stock,
    pi.image_url as primary_image,
    AVG(r.rating) as average_rating,
    COUNT(r.review_id) as review_count
FROM products p
LEFT JOIN categories c ON p.category_id = c.category_id
LEFT JOIN product_images pi ON p.product_id = pi.product_id AND pi.is_primary = TRUE
LEFT JOIN reviews r ON p.product_id = r.product_id AND r.is_approved = TRUE
WHERE p.is_active = TRUE
GROUP BY p.product_id;

CREATE VIEW customer_order_summary AS
SELECT 
    u.user_id,
    u.username,
    u.email,
    u.first_name,
    u.last_name,
    COUNT(o.order_id) as total_orders,
    SUM(o.final_amount) as total_spent,
    MAX(o.order_date) as last_order_date
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
WHERE u.user_type = 'customer'
GROUP BY u.user_id;

--  Stored Procedures
DELIMITER //

CREATE PROCEDURE CreateNewOrder(
    IN p_user_id INT,
    IN p_shipping_address_id INT,
    IN p_billing_address_id INT,
    IN p_payment_method VARCHAR(20),
    OUT p_order_id INT
)
BEGIN
    DECLARE v_order_number VARCHAR(50);
    DECLARE v_total_amount DECIMAL(10,2);
    DECLARE v_final_amount DECIMAL(10,2);
    
    -- unique order number
    SET v_order_number = CONCAT('ORD-', DATE_FORMAT(NOW(), '%Y%m%d-'), LPAD(FLOOR(RAND() * 10000), 4, '0'));
    
    -- totals from cart (simplified)
    SELECT SUM(p.price * sc.quantity) INTO v_total_amount
    FROM shopping_cart sc
    JOIN products p ON sc.product_id = p.product_id
    WHERE sc.user_id = p_user_id;
    
    SET v_final_amount = v_total_amount;
    
    -- order
    INSERT INTO orders (user_id, order_number, total_amount, final_amount, 
                       shipping_address_id, billing_address_id, payment_method)
    VALUES (p_user_id, v_order_number, v_total_amount, v_final_amount,
            p_shipping_address_id, p_billing_address_id, p_payment_method);
    
    SET p_order_id = LAST_INSERT_ID();
END //

CREATE PROCEDURE GetProductInventoryHistory(
    IN p_product_id INT,
    IN p_days_back INT
)
BEGIN
    SELECT 
        transaction_type,
        quantity_change,
        previous_quantity,
        new_quantity,
        transaction_date,
        notes
    FROM inventory_transactions
    WHERE product_id = p_product_id
    AND transaction_date >= DATE_SUB(NOW(), INTERVAL p_days_back DAY)
    ORDER BY transaction_date DESC;
END //

DELIMITER ;

-- Triggers for Data Integrity
DELIMITER //

CREATE TRIGGER update_product_quantity
AFTER INSERT ON inventory_transactions
FOR EACH ROW
BEGIN
    UPDATE products 
    SET quantity_in_stock = NEW.new_quantity,
        updated_at = NOW()
    WHERE product_id = NEW.product_id;
END //

CREATE TRIGGER prevent_zero_price
BEFORE UPDATE ON products
FOR EACH ROW
BEGIN
    IF NEW.price <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product price must be greater than 0';
    END IF;
END //

DELIMITER ;

-- Indexes for Performance Optimization
CREATE INDEX idx_orders_user_date ON orders(user_id, order_date);
CREATE INDEX idx_products_price_stock ON products(price, quantity_in_stock);
CREATE INDEX idx_reviews_product_rating ON reviews(product_id, rating, is_approved);
CREATE INDEX idx_order_items_product ON order_items(product_id);
CREATE INDEX idx_inventory_product_date ON inventory_transactions(product_id, transaction_date);