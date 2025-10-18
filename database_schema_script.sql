-- Database Schema Visualization Script
-- Run this script in your Supabase SQL editor to see the table structures and relationships

-- 1. First, let's see the structure of all 5 tables
SELECT 'SHOPS TABLE STRUCTURE' as table_info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'shops' 
ORDER BY ordinal_position;

SELECT 'BRANCHES TABLE STRUCTURE' as table_info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'branches' 
ORDER BY ordinal_position;

SELECT 'SHOP_CATEGORIES TABLE STRUCTURE' as table_info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'shop_categories' 
ORDER BY ordinal_position;

SELECT 'PRODUCTS TABLE STRUCTURE' as table_info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'products' 
ORDER BY ordinal_position;

SELECT 'PRICES TABLE STRUCTURE' as table_info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'prices' 
ORDER BY ordinal_position;

-- 2. Let's see the foreign key relationships
SELECT 'FOREIGN KEY RELATIONSHIPS' as table_info;
SELECT 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name IN ('shops', 'branches', 'shop_categories', 'products', 'prices')
ORDER BY tc.table_name;

-- 3. Let's see some sample data from each table to understand the relationships
SELECT 'SAMPLE SHOPS DATA' as table_info;
SELECT * FROM shops LIMIT 3;

SELECT 'SAMPLE BRANCHES DATA' as table_info;
SELECT * FROM branches LIMIT 5;

SELECT 'SAMPLE SHOP_CATEGORIES DATA' as table_info;
SELECT * FROM shop_categories LIMIT 5;

SELECT 'SAMPLE PRODUCTS DATA' as table_info;
SELECT * FROM products LIMIT 5;

SELECT 'SAMPLE PRICES DATA' as table_info;
SELECT * FROM prices LIMIT 5;

-- 4. Let's see how the tables are connected with a sample query
SELECT 'SAMPLE RELATIONSHIP QUERY' as table_info;
SELECT 
    s.shopName,
    b.branchName,
    sc.categoryName,
    p.productName,
    pr.price
FROM shops s
LEFT JOIN branches b ON s.id = b.shop_id
LEFT JOIN shop_categories sc ON s.id = sc.shop_id
LEFT JOIN products p ON sc.id = p.category_id
LEFT JOIN prices pr ON p.id = pr.product_id
LIMIT 10;
