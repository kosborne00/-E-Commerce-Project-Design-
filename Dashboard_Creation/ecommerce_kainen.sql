CREATE SCHEMA `kainen_ecommerce`;
USE kainen_ecommerce;

CREATE TABLE Category (
    CategoryID        INT PRIMARY KEY AUTO_INCREMENT,
    CategoryName      VARCHAR(100) NOT NULL UNIQUE,
    Description       TEXT,
    ParentCategoryID  INT REFERENCES Category(CategoryID)
                                   ON DELETE SET NULL
);

-- USER TABLES (supertype + subtypes)
CREATE TABLE User (
    UserID        INT PRIMARY KEY AUTO_INCREMENT,
    Email         VARCHAR(255) NOT NULL UNIQUE,
    PasswordHash  VARCHAR(255) NOT NULL,
    FirstName     VARCHAR(100) NOT NULL,
    LastName      VARCHAR(100) NOT NULL,
    Phone         VARCHAR(20),
    CreatedAt     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UserType      VARCHAR(10)  NOT NULL CHECK (UserType IN ('Customer','Seller'))
);

CREATE TABLE Customer (
    UserID					INT PRIMARY KEY REFERENCES User(UserID) ON DELETE CASCADE,
    LoyaltyPoints			INT NOT NULL DEFAULT 0,
    PreferredPaymentMethod  VARCHAR(50)
);

CREATE TABLE Seller (
    UserID         INT PRIMARY KEY REFERENCES User(UserID) ON DELETE CASCADE,
    BusinessName   VARCHAR(255) NOT NULL UNIQUE,
    BusinessEmail  VARCHAR(255) UNIQUE,
    SellerRating   DECIMAL(2,1) CHECK (SellerRating BETWEEN 0 AND 5),
    JoinedAt       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ADDRESS
CREATE TABLE Address (
    AddressID   INT PRIMARY KEY AUTO_INCREMENT,
    UserID      INT NOT NULL REFERENCES User(UserID) ON DELETE CASCADE,
    StreetLine1 VARCHAR(255) NOT NULL,
    StreetLine2 VARCHAR(255),
    City        VARCHAR(100) NOT NULL,
    State       VARCHAR(100) NOT NULL,
    ZipCode     VARCHAR(20)  NOT NULL,
    Country     VARCHAR(100) NOT NULL DEFAULT 'USA',
    IsDefault   TINYINT(1) NOT NULL DEFAULT 0
);

-- PRODUCT & INVENTORY
CREATE TABLE Product (
    ProductID    INT PRIMARY KEY AUTO_INCREMENT,
    SellerID     INT NOT NULL REFERENCES Seller(UserID) ON DELETE RESTRICT,
    CategoryID   INT NOT NULL REFERENCES Category(CategoryID) ON DELETE RESTRICT,
    ProductName  VARCHAR(255)	NOT NULL,
    Description  TEXT,
    Price        DECIMAL(10,2)  NOT NULL CHECK (Price >= 0),
    CreatedAt    DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    IsActive     TINYINT(1) NOT NULL DEFAULT 1
);

-- Inventory is 1-to-1 with Product it is separated to isolate writes
CREATE TABLE Inventory (
    InventoryID     INT PRIMARY KEY AUTO_INCREMENT,
    ProductID       INT NOT NULL UNIQUE
                             REFERENCES Product(ProductID)
                             ON DELETE CASCADE,
    QuantityInStock INT NOT NULL DEFAULT 0 CHECK (QuantityInStock >= 0),
    ReorderLevel    INT NOT NULL DEFAULT 10,
    LastUpdated     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ORDERS
CREATE TABLE `Order` (
    OrderID           INT PRIMARY KEY AUTO_INCREMENT,
    CustomerID        INT NOT NULL REFERENCES Customer(UserID)
                                    ON DELETE RESTRICT,
    ShippingAddressID INT NOT NULL REFERENCES Address(AddressID)
                                    ON DELETE RESTRICT,
    OrderDate         DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Status            VARCHAR(20)   NOT NULL DEFAULT 'Pending'
                                    CHECK (Status IN ('Pending','Shipped',
                                                      'Delivered','Cancelled')),
    TotalAmount       DECIMAL(10,2) NOT NULL CHECK (TotalAmount >= 0),
    PaymentMethod     VARCHAR(50)   NOT NULL
);

CREATE TABLE Order_Item (
    OrderItemID          INT PRIMARY KEY AUTO_INCREMENT,
    OrderID              INT NOT NULL REFERENCES `Order`(OrderID)
                                       ON DELETE CASCADE,
    ProductID            INT NOT NULL REFERENCES Product(ProductID)
                                       ON DELETE RESTRICT,
    Quantity             INT NOT NULL CHECK (Quantity >= 1),
    UnitPriceAtPurchase  DECIMAL(10,2) NOT NULL CHECK (UnitPriceAtPurchase >= 0),
    -- a product appears once per order
    UNIQUE (OrderID, ProductID)
);

-- REVIEWS
CREATE TABLE Review (
    ReviewID    INT PRIMARY KEY AUTO_INCREMENT,
    CustomerID  INT NOT NULL REFERENCES Customer(UserID)
                         ON DELETE CASCADE,
    ProductID   INT NOT NULL REFERENCES Product(ProductID)
                         ON DELETE CASCADE,
    Rating      INT NOT NULL CHECK (Rating BETWEEN 1 AND 5),
    Comment     TEXT,
    ReviewDate  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- one review per customer per product
    UNIQUE (CustomerID, ProductID)
);
-- SAMPLE DATA Disclaimer: Sample data was created with the help of AI.
-- Categories
INSERT INTO Category (CategoryName, Description, ParentCategoryID) VALUES
  ('Electronics',     'Electronic devices and accessories',  NULL),
  ('Clothing',        'Apparel and fashion',                 NULL),
  ('Home & Garden',   'Home goods and outdoor',              NULL),
  ('Smartphones',     'Mobile phones and accessories',       1),
  ('Laptops',         'Portable computers',                  1),
  ('Audio',           'Headphones, speakers, and earbuds',   1),
  ('Men''s Clothing', 'Clothing for men',                    2),
  ('Women''s Clothing','Clothing for women',                 2),
  ('Kitchen',         'Kitchen appliances and tools',        3),
  ('Outdoor',         'Outdoor and garden equipment',        3);

-- Users (5 customers, 3 sellers)
INSERT INTO User (Email, PasswordHash, FirstName, LastName, Phone, CreatedAt, UserType) VALUES
  ('alice@email.com',   'hash_alice',   'Alice',   'Johnson',  '206-555-0101', '2023-01-15 10:00:00', 'Customer'),
  ('bob@email.com',     'hash_bob',     'Bob',     'Martinez', '206-555-0102', '2023-02-20 11:30:00', 'Customer'),
  ('carol@email.com',   'hash_carol',   'Carol',   'Williams', '425-555-0103', '2023-03-05 09:15:00', 'Customer'),
  ('dave@email.com',    'hash_dave',    'Dave',    'Brown',    '253-555-0104', '2023-04-10 14:00:00', 'Customer'),
  ('eve@email.com',     'hash_eve',     'Eve',     'Davis',    '360-555-0105', '2023-05-22 16:45:00', 'Customer'),
  ('techcorp@biz.com',  'hash_techcorp','Sam',     'Tech',     '800-555-0201', '2022-11-01 08:00:00', 'Seller'),
  ('fashionco@biz.com', 'hash_fashion', 'Maria',   'Style',    '800-555-0202', '2022-12-15 08:00:00', 'Seller'),
  ('homeshop@biz.com',  'hash_home',    'James',   'Home',     '800-555-0203', '2023-01-05 08:00:00', 'Seller');

INSERT INTO Customer (UserID, LoyaltyPoints, PreferredPaymentMethod) VALUES
  (1, 1250, 'Credit Card'),
  (2, 430,  'PayPal'),
  (3, 2100, 'Credit Card'),
  (4, 80,   'Debit Card'),
  (5, 0,    NULL);

INSERT INTO Seller (UserID, BusinessName, BusinessEmail, SellerRating, JoinedAt) VALUES
  (6, 'TechCorp Electronics', 'sales@techcorp.com',  4.7, '2022-11-01 08:00:00'),
  (7, 'FashionCo Apparel',    'orders@fashionco.com', 4.3, '2022-12-15 08:00:00'),
  (8, 'HomeShop Goods',       'shop@homeshop.com',    4.5, '2023-01-05 08:00:00');

-- Addresses
INSERT INTO Address (UserID, StreetLine1, StreetLine2, City, State, ZipCode, Country, IsDefault) VALUES
  (1, '123 Pine St',    NULL,       'Seattle',   'WA', '98101', 'USA', 1),
  (2, '456 Oak Ave',    'Apt 2B',   'Bellevue',  'WA', '98004', 'USA', 1),
  (3, '789 Maple Dr',   NULL,       'Redmond',   'WA', '98052', 'USA', 1),
  (3, '100 Cedar Blvd', 'Suite 5',  'Kirkland',  'WA', '98033', 'USA', 0),
  (4, '321 Elm St',     NULL,       'Renton',    'WA', '98055', 'USA', 1),
  (5, '654 Birch Ln',   NULL,       'Tacoma',    'WA', '98401', 'USA', 1);

-- Products (10 active, 2 inactive/discontinued)
INSERT INTO Product (SellerID, CategoryID, ProductName, Description, Price, CreatedAt, IsActive) VALUES
  (6, 4,  'ProPhone 15',        'Flagship smartphone, 256GB',          899.99, '2023-06-01', 1),
  (6, 5,  'UltraBook Pro',      '14" laptop, 16GB RAM, 512GB SSD',     1299.99,'2023-06-01', 1),
  (6, 6,  'SoundWave ANC',      'Active noise-cancelling headphones',   149.99, '2023-07-01', 1),
  (6, 4,  'ProPhone 14',        'Previous-gen smartphone, 128GB',       549.99, '2022-09-01', 0),  -- discontinued
  (6, 6,  'BudPods Wireless',   'True wireless earbuds',                79.99,  '2023-08-01', 1),
  (7, 7,  'Classic Oxford Shirt','Men''s cotton oxford, slim fit',       59.99,  '2023-03-01', 1),
  (7, 8,  'Summer Linen Dress', 'Women''s A-line linen dress',          89.99,  '2023-04-01', 1),
  (7, 7,  'Chino Pants',        'Men''s stretch chino, multiple colors', 69.99,  '2023-04-15', 1),
  (7, 8,  'Cashmere Sweater',   'Women''s cashmere pullover',           129.99, '2023-09-01', 1),
  (8, 9,  'Chef''s Knife Set',  '8-piece professional knife block',     189.99, '2023-05-01', 1),
  (8, 9,  'Instant Pot Ultra',  '8-quart multi-use pressure cooker',    129.99, '2023-05-15', 1),
  (8, 10, 'Garden Tool Kit',    '10-piece stainless steel garden set',   49.99,  '2023-06-15', 1),
  (6, 5,  'StreamTab 10',       '10" tablet, 64GB',                     399.99, '2023-10-01', 0); -- discontinued

-- Inventory (stock levels for all active products)
INSERT INTO Inventory (ProductID, QuantityInStock, ReorderLevel, LastUpdated) VALUES
  (1,  45,  10, CURRENT_TIMESTAMP),
  (2,  22,   5, CURRENT_TIMESTAMP),
  (3,  80,  20, CURRENT_TIMESTAMP),
  (4,   3,   5, CURRENT_TIMESTAMP),   -- discontinued but remaining stock
  (5, 150,  30, CURRENT_TIMESTAMP),
  (6,  60,  15, CURRENT_TIMESTAMP),
  (7,  38,  10, CURRENT_TIMESTAMP),
  (8,  75,  20, CURRENT_TIMESTAMP),
  (9,  20,  10, CURRENT_TIMESTAMP),
  (10, 15,   5, CURRENT_TIMESTAMP),
  (11, 30,  10, CURRENT_TIMESTAMP),
  (12, 55,  15, CURRENT_TIMESTAMP),
  (13,  0,   5, CURRENT_TIMESTAMP);  -- discontinued, zero stock

-- Orders spread across several months
INSERT INTO `Order` (CustomerID, ShippingAddressID, OrderDate, Status, TotalAmount, PaymentMethod) VALUES
  (1, 1, '2025-01-10 14:22:00', 'Delivered',  1049.98, 'Credit Card'),  -- O1: phone+earbuds
  (2, 2, '2025-01-18 09:05:00', 'Delivered',   189.99, 'PayPal'),        -- O2: knife set
  (3, 3, '2025-02-03 16:40:00', 'Delivered',  1299.99, 'Credit Card'),   -- O3: laptop
  (1, 1, '2025-02-14 11:00:00', 'Delivered',   149.99, 'Credit Card'),   -- O4: headphones
  (4, 5, '2025-03-07 13:30:00', 'Delivered',   129.99, 'Debit Card'),    -- O5: Instant Pot
  (3, 4, '2025-03-22 10:15:00', 'Delivered',   219.98, 'Credit Card'),   -- O6: shirt+chino
  (2, 2, '2025-04-05 08:50:00', 'Delivered',    89.99, 'PayPal'),        -- O7: linen dress
  (1, 1, '2025-04-19 17:00:00', 'Delivered',   899.99, 'Credit Card'),   -- O8: ProPhone 15
  (3, 3, '2025-05-01 12:20:00', 'Delivered',   259.97, 'Credit Card'),   -- O9: sweater+earbuds+tool
  (4, 5, '2025-05-14 09:00:00', 'Delivered',    49.99, 'Debit Card'),    -- O10: garden kit
  (2, 2, '2025-06-02 14:10:00', 'Delivered',   149.99, 'PayPal'),        -- O11: headphones
  (1, 1, '2025-06-20 11:45:00', 'Delivered',   129.99, 'Credit Card'),   -- O12: cashmere sweater
  (3, 3, '2025-07-08 10:30:00', 'Delivered',  1299.99, 'Credit Card'),   -- O13: laptop (gift)
  (5, 6, '2025-01-25 15:00:00', 'Delivered',   189.98, 'Credit Card'),   -- O14: shirt+chino  <-- last order for Eve
  (2, 2, '2025-07-30 12:00:00', 'Delivered',   399.98, 'PayPal'),        -- O15: knife+tool
  (4, 5, '2025-02-28 10:00:00', 'Delivered',    79.99, 'Debit Card'),    -- O16: earbuds  <-- last for Dave
  (1, 1, '2025-08-15 09:30:00', 'Shipped',     129.99, 'Credit Card'),   -- O17: Instant Pot
  (3, 3, '2025-08-22 14:00:00', 'Pending',      59.99, 'Credit Card');   -- O18: oxford shirt

-- Order Items
INSERT INTO Order_Item (OrderID, ProductID, Quantity, UnitPriceAtPurchase) VALUES
  (1,  1,  1, 899.99),
  (1,  5,  2,  75.00),   -- sale price at time
  (2,  10, 1, 189.99),
  (3,  2,  1,1299.99),
  (4,  3,  1, 149.99),
  (5,  11, 1, 129.99),
  (6,  6,  1,  59.99),
  (6,  8,  2,  79.99),
  (7,  7,  1,  89.99),
  (8,  1,  1, 899.99),
  (9,  9,  1, 129.99),
  (9,  5,  1,  79.99),
  (9,  12, 1,  49.99),
  (10, 12, 1,  49.99),
  (11, 3,  1, 149.99),
  (12, 9,  1, 129.99),
  (13, 2,  1,1299.99),
  (14, 6,  1,  59.99),
  (14, 8,  2,  64.99),
  (15, 10, 1, 189.99),
  (15, 12, 1, 209.99),
  (16, 5,  1,  79.99),
  (17, 11, 1, 129.99),
  (18, 6,  1,  59.99);

-- Reviews
INSERT INTO Review (CustomerID, ProductID, Rating, Comment, ReviewDate) VALUES
  (1, 1,  5, 'Best phone I''ve ever owned. Fast and great camera.',   '2025-01-20'),
  (1, 5,  4, 'Good earbuds for the price, comfortable fit.',          '2025-01-20'),
  (2, 10, 5, 'Knives are incredibly sharp. Worth every penny.',       '2025-01-25'),
  (3, 2,  5, 'Blazing fast laptop. Battery life is impressive.',      '2025-02-15'),
  (1, 3,  4, 'Great noise cancellation. Comfortable for long use.',   '2025-02-22'),
  (4, 11, 5, 'Cooks everything perfectly. Easy to clean.',            '2025-03-15'),
  (3, 6,  4, 'Well-made shirt. Fits true to size.',                   '2025-03-30'),
  (3, 8,  3, 'Decent chinos but the color faded after one wash.',     '2025-03-30'),
  (2, 7,  5, 'Beautiful dress! Great quality linen.',                 '2025-04-12'),
  (3, 9,  5, 'Incredibly soft cashmere. Worth the price.',            '2025-05-10'),
  (2, 3,  5, 'Amazing headphones. Best purchase this year.',          '2025-06-10'),
  (1, 9,  4, 'Very cozy sweater. Sizing runs slightly large.',        '2025-06-28'),
  (4, 12, 4, 'Solid garden tools. Good quality for the price.',       '2025-05-20');
