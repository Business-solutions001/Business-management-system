-- ==========================================
-- RBAC & MULTI-LOCATION SCHEMA UPDATE
-- ==========================================

-- 1. Create Locations (Branches/Warehouses)
CREATE TABLE IF NOT EXISTS locations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT UNIQUE NOT NULL,
  type TEXT NOT NULL DEFAULT 'BRANCH', -- 'BRANCH', 'WAREHOUSE', 'HQ'
  address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert Default 'HQ' Location
INSERT INTO locations (name, type, address) 
VALUES ('Headquarters', 'HQ', 'System Default')
ON CONFLICT (name) DO NOTHING;

-- Retrieve the ID of 'Headquarters' for migration default mapping
DO $$
DECLARE
  hq_id UUID;
BEGIN
  SELECT id INTO hq_id FROM locations WHERE name = 'Headquarters' LIMIT 1;

  -- 2. Update Users Table (Add role logic & Location linkage)
  -- Supabase doesn't easily let you alter ENUMs without recreates, but we're storing them as TEXT 'USER', 'ADMIN', 'MANAGER'.
  -- Let's stick with TEXT roles ('ADMIN', 'ACCOUNTS', 'EMPLOYEE') going forward.
  -- Create location_id column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='location_id') THEN
    ALTER TABLE users ADD COLUMN location_id UUID REFERENCES locations(id);
    UPDATE users SET location_id = hq_id WHERE location_id IS NULL;
  END IF;

  -- Migrate existing user roles to new equivalents if needed
  UPDATE users SET role = 'ADMIN' WHERE role = 'USER' OR role = 'MANAGER'; -- Defaulting existing users back to Admin so you don't lose access!

  -- 3. Update Sales Table
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='sales' AND column_name='location_id') THEN
    ALTER TABLE sales ADD COLUMN location_id UUID REFERENCES locations(id);
    UPDATE sales SET location_id = hq_id WHERE location_id IS NULL;
    ALTER TABLE sales ALTER COLUMN location_id SET NOT NULL;
  END IF;

  -- 4. Update Purchases Table (For completeness, though transactions atomic usually tie through items/movements)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='purchases' AND column_name='location_id') THEN
    ALTER TABLE purchases ADD COLUMN location_id UUID REFERENCES locations(id);
    UPDATE purchases SET location_id = hq_id WHERE location_id IS NULL;
    ALTER TABLE purchases ALTER COLUMN location_id SET NOT NULL;
  END IF;

  -- 5. Update Stock Movements Table (Critical for location-specific stock keeping)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='stock_movements' AND column_name='location_id') THEN
    ALTER TABLE stock_movements ADD COLUMN location_id UUID REFERENCES locations(id);
    UPDATE stock_movements SET location_id = hq_id WHERE location_id IS NULL;
    ALTER TABLE stock_movements ALTER COLUMN location_id SET NOT NULL;
  END IF;

  -- 6. Update Delivery Orders
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='delivery_orders' AND column_name='location_id') THEN
    ALTER TABLE delivery_orders ADD COLUMN location_id UUID REFERENCES locations(id);
    UPDATE delivery_orders SET location_id = hq_id WHERE location_id IS NULL;
    ALTER TABLE delivery_orders ALTER COLUMN location_id SET NOT NULL;
  END IF;

  -- 7. Update Returns
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='returns' AND column_name='location_id') THEN
    ALTER TABLE returns ADD COLUMN location_id UUID REFERENCES locations(id);
    UPDATE returns SET location_id = hq_id WHERE location_id IS NULL;
    ALTER TABLE returns ALTER COLUMN location_id SET NOT NULL;
  END IF;

END $$;

-- 8. Turn off RLS globally for the new table for development if needed
ALTER TABLE locations DISABLE ROW LEVEL SECURITY;
