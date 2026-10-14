-- =========================================================================
-- COMPANY PROFILE & WHITE-LABEL BRANDING SCHEMA
-- Allows dynamic customization of company name, app title, logo, contact info,
-- and currency symbol across Web, Windows (.exe), and Android (.apk).
-- =========================================================================

-- 1. Create company_settings table
CREATE TABLE IF NOT EXISTS public.company_settings (
  id INT PRIMARY KEY DEFAULT 1,
  company_name TEXT NOT NULL DEFAULT 'ELIPSE HR',
  app_title TEXT NOT NULL DEFAULT 'Elipse HR Portal',
  company_tagline TEXT DEFAULT 'Secure Attendance & HR Management Portal',
  company_logo_url TEXT DEFAULT '/icons/logo.png',
  company_email TEXT DEFAULT 'elipsestudiohr@gmail.com',
  company_phone TEXT DEFAULT '',
  company_address TEXT DEFAULT '',
  company_website TEXT DEFAULT '',
  currency_symbol TEXT DEFAULT 'Rs',
  fiscal_year_start TEXT DEFAULT '01-01',
  office_working_days INT DEFAULT 6,
  extra_data JSONB DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ensure default row exists
INSERT INTO public.company_settings (
  id, company_name, app_title, company_tagline, company_logo_url, 
  company_email, company_phone, company_address, company_website, currency_symbol, office_working_days
) VALUES (
  1, 'ELIPSE HR', 'Elipse HR Portal', 'Secure Attendance & HR Management Portal', '/icons/logo.png',
  'elipsestudiohr@gmail.com', '', '', '', 'Rs', 6
) ON CONFLICT (id) DO NOTHING;

-- 2. Add fallback columns to device_settings if not present
ALTER TABLE public.device_settings ADD COLUMN IF NOT EXISTS company_name TEXT DEFAULT 'ELIPSE HR';
ALTER TABLE public.device_settings ADD COLUMN IF NOT EXISTS company_logo_url TEXT DEFAULT '/icons/logo.png';
ALTER TABLE public.device_settings ADD COLUMN IF NOT EXISTS company_profile JSONB DEFAULT '{}'::jsonb;

-- 3. Enable Row Level Security (RLS) and grant open access for company branding
ALTER TABLE public.company_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all users to view company settings" ON public.company_settings;
CREATE POLICY "Allow all users to view company settings"
  ON public.company_settings FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Allow all users to update company settings" ON public.company_settings;
CREATE POLICY "Allow all users to update company settings"
  ON public.company_settings FOR ALL
  USING (true)
  WITH CHECK (true);

-- Grant privileges
GRANT ALL ON TABLE public.company_settings TO anon, authenticated, service_role;

-- 4. Enable Supabase Realtime publication
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
      AND schemaname = 'public' 
      AND tablename = 'company_settings'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.company_settings;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    NULL;
END $$;
