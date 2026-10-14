-- ==============================================================================
-- ELIPSE HR PORTAL - ADMIN USER SEED & AUTH SETUP (BULLETPROOF VERSION)
-- ==============================================================================
-- Run this script in the Supabase SQL Editor:
-- https://rbqjanevxnmllpvsssth.supabase.co
-- ==============================================================================

-- 1. Ensure pgcrypto extension exists (Supabase puts this in 'extensions' schema)
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- 2. Make sure search_path includes both public and extensions
SET search_path TO public, extensions, auth;

-- 3. Ensure required columns exist on public.profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS password TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS allowed_tabs JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS extra_data JSONB DEFAULT '{}'::jsonb;

-- 4. Seed and confirm Admin User
DO $$
DECLARE
  admin_uid UUID;
  admin_email TEXT := 'elipsestudiohr@gmail.com';
  admin_pass TEXT := '695683';
  admin_pin TEXT := '9999';
  hashed_pw TEXT;
  col_name TEXT;
BEGIN
  -- Safe hashing: handles both 'extensions' and 'public' schemas
  BEGIN
    hashed_pw := extensions.crypt(admin_pass, extensions.gen_salt('bf'));
  EXCEPTION WHEN OTHERS THEN
    hashed_pw := public.crypt(admin_pass, public.gen_salt('bf'));
  END;

  -- Check if user already exists in auth.users
  IF EXISTS (SELECT 1 FROM auth.users WHERE email = admin_email) THEN
    SELECT id INTO admin_uid FROM auth.users WHERE email = admin_email;
    
    UPDATE auth.users
    SET encrypted_password = hashed_pw,
        email_confirmed_at = COALESCE(email_confirmed_at, now()),
        raw_user_meta_data = jsonb_build_object('role', 'admin'),
        raw_app_meta_data = '{"provider":"email","providers":["email"]}'::jsonb,
        updated_at = now()
    WHERE id = admin_uid;
  ELSE
    admin_uid := gen_random_uuid();
    
    INSERT INTO auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    )
    VALUES (
      '00000000-0000-0000-0000-000000000000', admin_uid, 'authenticated', 'authenticated',
      admin_email, hashed_pw, now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      jsonb_build_object('role', 'admin'),
      now(), now()
    );

    FOR col_name IN
      SELECT column_name FROM information_schema.columns
      WHERE table_schema = 'auth' AND table_name = 'users'
        AND data_type IN ('character varying', 'text') AND column_name != 'phone'
    LOOP
      EXECUTE format('UPDATE auth.users SET %I = '''' WHERE id = $1 AND %I IS NULL', col_name, col_name) USING admin_uid;
    END LOOP;
  END IF;

  -- Ensure identity exists in auth.identities
  INSERT INTO auth.identities (
    id, user_id, provider, provider_id, identity_data, last_sign_in_at, created_at, updated_at
  )
  VALUES (
    admin_uid, admin_uid, 'email', admin_uid::text,
    jsonb_build_object('sub', admin_uid::text, 'email', admin_email, 'email_verified', true),
    now(), now(), now()
  )
  ON CONFLICT (provider, provider_id) DO UPDATE
  SET identity_data = jsonb_build_object('sub', admin_uid::text, 'email', admin_email, 'email_verified', true),
      updated_at = now();

  -- Upsert into public.profiles
  INSERT INTO public.profiles (
    id, pin, full_name, designation, department, base_salary, hourly_rate, email, password, role, is_active, joining_date
  )
  VALUES (
    admin_uid, admin_pin, 'HR Administrator', 'Administrator', 'Administration', 0, 0, admin_email, admin_pass, 'admin', true, now()::date
  )
  ON CONFLICT (id) DO UPDATE
  SET
    role = 'admin',
    password = admin_pass,
    pin = admin_pin,
    full_name = 'HR Administrator',
    designation = 'Administrator',
    department = 'Administration',
    is_active = true;

END $$;
