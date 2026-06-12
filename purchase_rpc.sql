-- ============================================================
-- ERP Sales Module - Purchase Entry & Weighted Average Updates
-- Run this in the Supabase SQL Editor at:
-- https://supabase.com/dashboard/project/wjfdmxxhjxplcftsuxic/sql
-- ============================================================

-- 1. Create Suppliers Table
CREATE TABLE IF NOT EXISTS suppliers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  mobile TEXT,
  address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create Supplier Ledger Table
CREATE TABLE IF NOT EXISTS supplier_ledger (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  supplier_id UUID NOT NULL REFERENCES suppliers(id),
  type TEXT NOT NULL, -- 'CREDIT' (We owe them) / 'DEBIT' (We paid them)
  amount NUMERIC(12,2) NOT NULL,
  reference_id UUID, -- purchase_id or payment_id
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Modify Products Table
ALTER TABLE products 
  ADD COLUMN IF NOT EXISTS stock_qty INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS avg_price NUMERIC(12,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_purchase_price NUMERIC(12,2) DEFAULT 0;

-- 4. Modify Purchases Table (Supplier reference, detailed amounts)
ALTER TABLE purchases DROP COLUMN IF EXISTS supplier;
ALTER TABLE purchases ADD COLUMN IF NOT EXISTS supplier_id UUID REFERENCES suppliers(id);
ALTER TABLE purchases ADD COLUMN IF NOT EXISTS invoice_no TEXT;
ALTER TABLE purchases ADD COLUMN IF NOT EXISTS purchase_date TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE purchases ADD COLUMN IF NOT EXISTS subtotal NUMERIC(12,2) DEFAULT 0;
ALTER TABLE purchases ADD COLUMN IF NOT EXISTS discount NUMERIC(12,2) DEFAULT 0;
ALTER TABLE purchases ADD COLUMN IF NOT EXISTS transport_cost NUMERIC(12,2) DEFAULT 0;
ALTER TABLE purchases ADD COLUMN IF NOT EXISTS paid NUMERIC(12,2) DEFAULT 0;
ALTER TABLE purchases ADD COLUMN IF NOT EXISTS due NUMERIC(12,2) DEFAULT 0;

-- Drop foreign key on stock_movements reference if it causes issues, but it's a UUID so it should be fine.
-- Let's make sure the return type of the RPC works.
DROP FUNCTION IF EXISTS process_purchase_transaction;

-- 5. Create RPC for Atomic Purchase Transaction
CREATE OR REPLACE FUNCTION process_purchase_transaction(
  p_supplier_id UUID,
  p_invoice_no TEXT,
  p_purchase_date TIMESTAMPTZ,
  p_subtotal NUMERIC,
  p_discount NUMERIC,
  p_transport_cost NUMERIC,
  p_total NUMERIC,
  p_paid NUMERIC,
  p_due NUMERIC,
  p_location_id UUID,
  p_items JSONB -- Array of items: [{product_id, quantity, price, total}]
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_purchase_id UUID;
  v_item JSONB;
  v_product_id UUID;
  v_qty INTEGER;
  v_price NUMERIC;
  v_item_total NUMERIC;
  v_existing_stock_qty INTEGER;
  v_existing_avg_price NUMERIC;
  v_new_avg_price NUMERIC;
  v_existing_stock_value NUMERIC;
  v_new_stock_value NUMERIC;
BEGIN
  -- Insert Purchase
  INSERT INTO purchases (
    supplier_id, invoice_no, purchase_date, subtotal, discount, transport_cost, total, paid, due, location_id
  ) VALUES (
    p_supplier_id, p_invoice_no, p_purchase_date, p_subtotal, p_discount, p_transport_cost, p_total, p_paid, p_due, p_location_id
  ) RETURNING id INTO v_purchase_id;

  -- Supplier Ledger (Add CREDIT for the purchase total)
  IF p_supplier_id IS NOT NULL THEN
    INSERT INTO supplier_ledger (supplier_id, type, amount, reference_id)
    VALUES (p_supplier_id, 'CREDIT', p_total, v_purchase_id);

    -- If there's an immediate payment, register a DEBIT
    IF p_paid > 0 THEN
      INSERT INTO supplier_ledger (supplier_id, type, amount, reference_id)
      VALUES (p_supplier_id, 'DEBIT', p_paid, v_purchase_id);
    END IF;
  END IF;

  -- Process Items
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    v_product_id := (v_item->>'product_id')::UUID;
    v_qty := (v_item->>'quantity')::INTEGER;
    v_price := (v_item->>'price')::NUMERIC;
    v_item_total := (v_item->>'total')::NUMERIC;

    -- Insert Purchase Item
    INSERT INTO purchase_items (purchase_id, product_id, quantity, price, total)
    VALUES (v_purchase_id, v_product_id, v_qty, v_price, v_item_total);

    -- Insert Stock Movement
    INSERT INTO stock_movements (product_id, type, quantity, reference, location_id)
    VALUES (v_product_id, 'IN_PURCHASE', v_qty, v_purchase_id, p_location_id);

    -- Fetch existing product metrics for weighted average calculation
    SELECT COALESCE(stock_qty, 0), COALESCE(avg_price, 0)
    INTO v_existing_stock_qty, v_existing_avg_price
    FROM products
    WHERE id = v_product_id;

    -- Calculate weighted average
    v_existing_stock_value := v_existing_stock_qty * v_existing_avg_price;
    v_new_stock_value := v_price * v_qty;

    IF (v_existing_stock_qty + v_qty) > 0 THEN
      v_new_avg_price := (v_existing_stock_value + v_new_stock_value) / (v_existing_stock_qty + v_qty);
    ELSE
      v_new_avg_price := v_price;
    END IF;

    -- Update Product
    UPDATE products
    SET 
      stock_qty = stock_qty + v_qty,
      avg_price = v_new_avg_price,
      last_purchase_price = v_price
    WHERE id = v_product_id;
  END LOOP;

  RETURN jsonb_build_object('success', true, 'purchase_id', v_purchase_id);
EXCEPTION WHEN OTHERS THEN
  -- The transaction will implicitly rollback here.
  -- Raise an error to inform the caller
  RAISE EXCEPTION 'Transaction failed: %', SQLERRM;
END;
$$;

-- Seed Sample Supplier
INSERT INTO suppliers (name, mobile, address) VALUES
  ('Global Traders Inc.', '01988112233', 'Sylhet, Bangladesh')
ON CONFLICT DO NOTHING;
