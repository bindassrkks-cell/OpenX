CREATE TABLE IF NOT EXISTS orders (
  id TEXT PRIMARY KEY,
  customer_name TEXT,
  customer_phone TEXT,
  shipping_address TEXT,
  total_amount NUMERIC NOT NULL,
  payment_method TEXT,
  payment_status TEXT DEFAULT 'PENDING',
  utr_number TEXT,
  screenshot_url TEXT,
  status TEXT DEFAULT 'PLACED',
  items JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
ALTER TABLE orders REPLICA IDENTITY FULL;
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
