IF DB_ID('grocery_inventory') IS NULL CREATE DATABASE grocery_inventory;
GO
USE grocery_inventory;
GO
-- Idempotent: safe to re-run on every `docker compose up` (volume persists).
IF OBJECT_ID('dbo.categories', 'U') IS NULL
CREATE TABLE categories (id BIGINT IDENTITY PRIMARY KEY, name NVARCHAR(120) NOT NULL, description NVARCHAR(500), CONSTRAINT uk_categories_name UNIQUE(name));
IF OBJECT_ID('dbo.products', 'U') IS NULL
CREATE TABLE products (id BIGINT IDENTITY PRIMARY KEY, sku NVARCHAR(64) NOT NULL, name NVARCHAR(180) NOT NULL, description NVARCHAR(1000), category_id BIGINT NOT NULL, unit_price DECIMAL(12,2) NOT NULL, current_stock INT NOT NULL CONSTRAINT ck_products_stock CHECK(current_stock>=0), reorder_level INT NOT NULL CONSTRAINT ck_products_reorder CHECK(reorder_level>=0), status NVARCHAR(30) NOT NULL CONSTRAINT ck_products_status CHECK(status IN ('ACTIVE','INACTIVE','DISCONTINUED')), CONSTRAINT uk_products_sku UNIQUE(sku), CONSTRAINT fk_products_categories FOREIGN KEY(category_id) REFERENCES categories(id));
IF OBJECT_ID('dbo.inventory_movements', 'U') IS NULL
CREATE TABLE inventory_movements (id BIGINT IDENTITY PRIMARY KEY, product_id BIGINT NOT NULL, movement_type NVARCHAR(30) NOT NULL CONSTRAINT ck_movements_type CHECK(movement_type IN ('REPLENISHMENT','ADJUSTMENT_IN','ADJUSTMENT_OUT','SALE')), quantity INT NOT NULL CONSTRAINT ck_movements_qty CHECK(quantity>0), movement_date DATETIMEOFFSET NOT NULL, created_by NVARCHAR(100) NOT NULL, CONSTRAINT fk_movements_products FOREIGN KEY(product_id) REFERENCES products(id));
IF OBJECT_ID('dbo.sales', 'U') IS NULL
CREATE TABLE sales (id BIGINT IDENTITY PRIMARY KEY, sale_date DATETIMEOFFSET NOT NULL, total_amount DECIMAL(12,2) NOT NULL);
IF OBJECT_ID('dbo.sale_details', 'U') IS NULL
CREATE TABLE sale_details (id BIGINT IDENTITY PRIMARY KEY, sale_id BIGINT NOT NULL, product_id BIGINT NOT NULL, quantity INT NOT NULL CONSTRAINT ck_detail_qty CHECK(quantity>0), unit_price DECIMAL(12,2) NOT NULL, subtotal DECIMAL(12,2) NOT NULL, CONSTRAINT fk_details_sales FOREIGN KEY(sale_id) REFERENCES sales(id), CONSTRAINT fk_details_products FOREIGN KEY(product_id) REFERENCES products(id));
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='ix_products_category' AND object_id=OBJECT_ID('dbo.products')) CREATE INDEX ix_products_category ON products(category_id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='ix_movements_product_date' AND object_id=OBJECT_ID('dbo.inventory_movements')) CREATE INDEX ix_movements_product_date ON inventory_movements(product_id, movement_date DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='ix_sales_date' AND object_id=OBJECT_ID('dbo.sales')) CREATE INDEX ix_sales_date ON sales(sale_date);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='ix_sale_details_sale' AND object_id=OBJECT_ID('dbo.sale_details')) CREATE INDEX ix_sale_details_sale ON sale_details(sale_id);
-- Converge pre-existing volumes created by the older script (no CHECK on status/type):
-- WITH NOCHECK avoids full-table scan failures on legacy rows; new writes are still validated.
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='ck_products_status')
  ALTER TABLE products WITH NOCHECK ADD CONSTRAINT ck_products_status CHECK(status IN ('ACTIVE','INACTIVE','DISCONTINUED'));
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='ck_movements_type')
  ALTER TABLE inventory_movements WITH NOCHECK ADD CONSTRAINT ck_movements_type CHECK(movement_type IN ('REPLENISHMENT','ADJUSTMENT_IN','ADJUSTMENT_OUT','SALE'));
GO
