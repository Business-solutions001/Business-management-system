-- ==========================================
-- USER MANAGEMENT & ACTIVITY SCHEMA UPDATE
-- ==========================================

-- 1. Modify the `users` table to track status safely
DO $$
BEGIN
  -- Add a status column if it doesn't exist
  -- 'ACTIVE', 'BLOCKED', 'DELETED'
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='status') THEN
    ALTER TABLE users ADD COLUMN status TEXT NOT NULL DEFAULT 'ACTIVE';
  END IF;

  -- Backwards compatibility: ensure all existing users are 'ACTIVE'
  UPDATE users SET status = 'ACTIVE' WHERE status IS NULL;
END $$;


-- 2. Create an Activity History Table for tracking everything securely
CREATE TABLE IF NOT EXISTS user_activity_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  action TEXT NOT NULL,       -- Example: 'LOGIN', 'CREATED_SALE', 'RESET_PASSWORD'
  description TEXT NOT NULL,  -- Example: 'User John logged into the HQ branch'
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Disable RLS for local dev (match existing setup)
ALTER TABLE user_activity_history DISABLE ROW LEVEL SECURITY;
