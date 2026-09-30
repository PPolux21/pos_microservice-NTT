USE grocery_inventory;
GO
-- Idempotent seed: safe to re-run. Categories guarded by UNIQUE(name), products by UNIQUE(sku).
-- Category ids are resolved by name (never hardcode IDENTITY values).
IF NOT EXISTS (SELECT 1 FROM categories WHERE name='Produce')
  INSERT INTO categories(name,description) VALUES('Produce','Fresh fruits and vegetables');
IF NOT EXISTS (SELECT 1 FROM categories WHERE name='Dairy')
  INSERT INTO categories(name,description) VALUES('Dairy','Milk, yogurt, cheese');
IF NOT EXISTS (SELECT 1 FROM categories WHERE name='Bakery')
  INSERT INTO categories(name,description) VALUES('Bakery','Bread and pastries');
IF NOT EXISTS (SELECT 1 FROM categories WHERE name='Pantry')
  INSERT INTO categories(name,description) VALUES('Pantry','Packaged goods');
GO
DECLARE @produce BIGINT = (SELECT id FROM categories WHERE name='Produce');
DECLARE @dairy BIGINT = (SELECT id FROM categories WHERE name='Dairy');
DECLARE @bakery BIGINT = (SELECT id FROM categories WHERE name='Bakery');
DECLARE @pantry BIGINT = (SELECT id FROM categories WHERE name='Pantry');
IF NOT EXISTS (SELECT 1 FROM products WHERE sku='APL-001')
  INSERT INTO products(sku,name,description,category_id,unit_price,current_stock,reorder_level,status) VALUES('APL-001','Red Apples','1kg bag',@produce,2.99,120,25,'ACTIVE');
IF NOT EXISTS (SELECT 1 FROM products WHERE sku='MLK-001')
  INSERT INTO products(sku,name,description,category_id,unit_price,current_stock,reorder_level,status) VALUES('MLK-001','Whole Milk','1 liter carton',@dairy,1.79,80,20,'ACTIVE');
IF NOT EXISTS (SELECT 1 FROM products WHERE sku='BRD-001')
  INSERT INTO products(sku,name,description,category_id,unit_price,current_stock,reorder_level,status) VALUES('BRD-001','Sourdough Bread','500g loaf',@bakery,3.49,30,10,'ACTIVE');
IF NOT EXISTS (SELECT 1 FROM products WHERE sku='RCE-001')
  INSERT INTO products(sku,name,description,category_id,unit_price,current_stock,reorder_level,status) VALUES('RCE-001','Rice','1kg bag',@pantry,2.29,12,15,'ACTIVE');
GO
