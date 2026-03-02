ALTER TABLE IF EXISTS product_stock RENAME TO supplier_branch_stock;
ALTER INDEX IF EXISTS product_stock_pkey RENAME TO supplier_branch_stock_pkey;

