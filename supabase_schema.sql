-- ============================================================
-- ERP Sales Module - Supabase SQL Schema
-- Run this in the Supabase SQL Editor at:
-- https://supabase.com/dashboard/project/wjfdmxxhjxplcftsuxic/sql
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------
-- USERS
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email      TEXT UNIQUE NOT NULL,
  password   TEXT NOT NULL,
  name       TEXT NOT NULL,
  role       TEXT NOT NULL DEFAULT 'USER', -- 'ADMIN' | 'MANAGER' | 'USER'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------
-- CUSTOMERS
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS customers (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name       TEXT NOT NULL,
  mobile     TEXT,
  address    TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------
-- PRODUCTS
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS products (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code       TEXT UNIQUE NOT NULL,
  name       TEXT NOT NULL,
  category   TEXT,
  unit       TEXT DEFAULT 'PCS',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------
-- PURCHASES
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS purchases (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  supplier   TEXT,
  total      NUMERIC(12,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS purchase_items (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  purchase_id UUID NOT NULL REFERENCES purchases(id) ON DELETE CASCADE,
  product_id  UUID NOT NULL REFERENCES products(id),
  quantity    INTEGER NOT NULL,
  price       NUMERIC(12,2) NOT NULL,
  total       NUMERIC(12,2) NOT NULL
);

-- -----------------------------------------------
-- SALES
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS sales (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sale_type      TEXT NOT NULL DEFAULT 'RETAIL', -- 'RETAIL' | 'WHOLESALE' | 'PREMIUM'
  customer_id    UUID REFERENCES customers(id),
  subtotal       NUMERIC(12,2) NOT NULL DEFAULT 0,
  vat            NUMERIC(12,2) DEFAULT 0,
  discount_pct   NUMERIC(5,2) DEFAULT 0,
  discount_amt   NUMERIC(12,2) DEFAULT 0,
  transport_cost NUMERIC(12,2) DEFAULT 0,
  total_amount   NUMERIC(12,2) NOT NULL DEFAULT 0,
  paid_amount    NUMERIC(12,2) DEFAULT 0,
  due_amount     NUMERIC(12,2) DEFAULT 0,
  cash_return    NUMERIC(12,2) DEFAULT 0,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  updated_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sale_items (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sale_id    UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id),
  quantity   INTEGER NOT NULL,
  rate       NUMERIC(12,2) NOT NULL,
  total      NUMERIC(12,2) NOT NULL
);

-- -----------------------------------------------
-- STOCK MOVEMENTS
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS stock_movements (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID NOT NULL REFERENCES products(id),
  type       TEXT NOT NULL, -- 'IN_PURCHASE' | 'IN_RETURN_GOOD' | 'OUT_SALE' | 'OUT_INVOICE'
  quantity   INTEGER NOT NULL,
  reference  UUID,          -- sale_id or purchase_id or return_id
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------
-- RETURNS
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS returns (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID REFERENCES customers(id),
  total       NUMERIC(12,2) DEFAULT 0,
  type        TEXT NOT NULL, -- 'GOOD_RETURN' | 'BAD_RETURN'
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS return_items (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  return_id  UUID NOT NULL REFERENCES returns(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id),
  quantity   INTEGER NOT NULL,
  price      NUMERIC(12,2) NOT NULL
);

-- -----------------------------------------------
-- DAMAGE REPORTS (Bad Returns)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS damage_reports (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID NOT NULL REFERENCES products(id),
  quantity   INTEGER NOT NULL,
  reason     TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------
-- DELIVERY ORDERS
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS delivery_orders (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID NOT NULL REFERENCES customers(id),
  status      TEXT NOT NULL DEFAULT 'PENDING', -- 'PENDING' | 'INVOICED' | 'CANCELLED'
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS delivery_order_items (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  delivery_order_id UUID NOT NULL REFERENCES delivery_orders(id) ON DELETE CASCADE,
  product_id        UUID NOT NULL REFERENCES products(id),
  quantity          INTEGER NOT NULL,
  rate              NUMERIC(12,2) NOT NULL
);

-- -----------------------------------------------
-- INVOICES
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS invoices (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  delivery_order_id UUID UNIQUE REFERENCES delivery_orders(id),
  customer_id       UUID NOT NULL REFERENCES customers(id),
  total             NUMERIC(12,2) NOT NULL DEFAULT 0,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------
-- PAYMENTS
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS payments (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id    UUID REFERENCES customers(id),
  amount         NUMERIC(12,2) NOT NULL,
  payment_method TEXT NOT NULL DEFAULT 'CASH', -- 'CASH' | 'BANK' | 'CREDIT_NOTE' | 'DEBIT_NOTE'
  reference      TEXT,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------
-- CUSTOMER LEDGER
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS customer_ledger (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID NOT NULL REFERENCES customers(id),
  type        TEXT NOT NULL, -- 'DEBIT' | 'CREDIT'
  amount      NUMERIC(12,2) NOT NULL,
  description TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------
-- PETTY CASH
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS petty_cash_transactions (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  amount      NUMERIC(12,2) NOT NULL,
  description TEXT NOT NULL,
  type        TEXT NOT NULL, -- 'IN' | 'OUT'
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------
-- SEED DATA - Sample Products & Customers
-- -----------------------------------------------
INSERT INTO customers (name, mobile, address) VALUES
  ('John Doe', '01711223344', 'Dhaka, Bangladesh'),
  ('ACME Corp', '01855667788', 'Chittagong, Bangladesh'),
  ('Walk-in Customer', NULL, NULL)
ON CONFLICT DO NOTHING;

INSERT INTO products (code, name, category, unit) VALUES
  ('PRD-001', 'Laptop Pro 15"', 'Electronics', 'PCS'),
  ('PRD-002', 'Wireless Mouse', 'Accessories', 'PCS'),
  ('PRD-003', 'Mechanical Keyboard', 'Accessories', 'PCS'),
  ('PRD-004', 'USB-C Hub 7-in-1', 'Accessories', 'PCS'),
  ('PRD-005', 'Monitor 24" FHD', 'Electronics', 'PCS')
ON CONFLICT DO NOTHING;

-- -----------------------------------------------
-- Disable RLS for development (enable per-table for production)
-- -----------------------------------------------
ALTER TABLE users                  DISABLE ROW LEVEL SECURITY;
ALTER TABLE customers              DISABLE ROW LEVEL SECURITY;
ALTER TABLE products               DISABLE ROW LEVEL SECURITY;
ALTER TABLE purchases              DISABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_items         DISABLE ROW LEVEL SECURITY;
ALTER TABLE sales                  DISABLE ROW LEVEL SECURITY;
ALTER TABLE sale_items             DISABLE ROW LEVEL SECURITY;
ALTER TABLE stock_movements        DISABLE ROW LEVEL SECURITY;
ALTER TABLE returns                DISABLE ROW LEVEL SECURITY;
ALTER TABLE return_items           DISABLE ROW LEVEL SECURITY;
ALTER TABLE damage_reports         DISABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_orders        DISABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_order_items   DISABLE ROW LEVEL SECURITY;
ALTER TABLE invoices               DISABLE ROW LEVEL SECURITY;
ALTER TABLE payments               DISABLE ROW LEVEL SECURITY;
ALTER TABLE customer_ledger        DISABLE ROW LEVEL SECURITY;
ALTER TABLE petty_cash_transactions DISABLE ROW LEVEL SECURITY;
