-- ==============================================================================
-- FIX EMPLOYEE CREATION: PGCYRTO & SAVE_EMPLOYEE_USER FUNCTION
-- ==============================================================================
-- Run this in your Supabase SQL Editor:
-- https://rbqjanevxnmllpvsssth.supabase.co
-- ==============================================================================

-- 1. Ensure pgcrypto extension is installed in extensions schema
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- 2. Make sure public.profiles has all necessary columns
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS password TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS allowed_tabs JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS extra_data JSONB DEFAULT '{}'::jsonb;

-- 3. Update save_employee_user with schema-safe pgcrypto resolution
CREATE OR REPLACE FUNCTION public.save_employee_user(
  id_val uuid DEFAULT NULL,
  email_val text DEFAULT NULL,
  password_val text DEFAULT NULL,
  pin_val text DEFAULT NULL,
  name_val text DEFAULT NULL,
  designation_val text DEFAULT NULL,
  department_val text DEFAULT NULL,
  salary_val numeric DEFAULT NULL,
  hourly_val numeric DEFAULT NULL,
  dob_val text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, auth, pg_temp
AS $$
DECLARE
  target_user_id uuid := id_val;
  encrypted_pw text;
  col_name text;
BEGIN
  IF email_val IS NULL OR email_val = '' THEN
    RAISE EXCEPTION 'Email address is required.';
  END IF;
  IF pin_val IS NULL OR pin_val = '' THEN
    RAISE EXCEPTION 'Employee PIN is required.';
  END IF;
  IF name_val IS NULL OR name_val = '' THEN
    RAISE EXCEPTION 'Employee name is required.';
  END IF;

  IF target_user_id IS NULL THEN
    -- ============ CREATE NEW USER ============
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = email_val) THEN
      RAISE EXCEPTION 'An account with this email already exists.';
    END IF;

    IF EXISTS (SELECT 1 FROM public.profiles WHERE pin = pin_val) THEN
      RAISE EXCEPTION 'An employee with ZKTeco PIN % already exists.', pin_val;
    END IF;

    target_user_id := gen_random_uuid();
    
    -- Safe password hashing using extensions schema with fallback
    BEGIN
      encrypted_pw := extensions.crypt(COALESCE(password_val, 'Default@12345'), extensions.gen_salt('bf'));
    EXCEPTION WHEN OTHERS THEN
      encrypted_pw := crypt(COALESCE(password_val, 'Default@12345'), gen_salt('bf'));
    END;

    INSERT INTO auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    )
    VALUES (
      '00000000-0000-0000-0000-000000000000', target_user_id, 'authenticated', 'authenticated',
      email_val, encrypted_pw, now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      jsonb_build_object('role', 'employee'),
      now(), now()
    );

    -- Avoid GoTrue scan null crashes
    FOR col_name IN
      SELECT column_name FROM information_schema.columns
      WHERE table_schema = 'auth' AND table_name = 'users'
        AND data_type IN ('character varying', 'text') AND column_name != 'phone'
    LOOP
      EXECUTE format('UPDATE auth.users SET %I = '''' WHERE id = $1 AND %I IS NULL', col_name, col_name) USING target_user_id;
    END LOOP;

    INSERT INTO auth.identities (
      id, user_id, provider, provider_id, identity_data, last_sign_in_at, created_at, updated_at
    )
    VALUES (
      target_user_id, target_user_id, 'email', target_user_id::text,
      jsonb_build_object('sub', target_user_id::text, 'email', email_val, 'email_verified', true),
      now(), now(), now()
    );

  ELSE
    -- ============ UPDATE EXISTING USER ============
    IF EXISTS (SELECT 1 FROM public.profiles WHERE pin = pin_val AND id != target_user_id) THEN
      RAISE EXCEPTION 'ZKTeco PIN % is already assigned to another employee.', pin_val;
    END IF;

    UPDATE auth.users
    SET email = email_val, updated_at = now()
    WHERE id = target_user_id;

    IF password_val IS NOT NULL AND password_val != '' THEN
      BEGIN
        encrypted_pw := extensions.crypt(password_val, extensions.gen_salt('bf'));
      EXCEPTION WHEN OTHERS THEN
        encrypted_pw := crypt(password_val, gen_salt('bf'));
      END;
      
      UPDATE auth.users
      SET encrypted_password = encrypted_pw, updated_at = now()
      WHERE id = target_user_id;
    END IF;

    UPDATE auth.identities
    SET identity_data = jsonb_build_object('sub', target_user_id::text, 'email', email_val, 'email_verified', true),
        updated_at = now()
    WHERE user_id = target_user_id;
  END IF;

  -- Upsert into public.profiles
  INSERT INTO public.profiles (
    id, pin, full_name, designation, department, base_salary, hourly_rate, email, password, role, is_active, joining_date, date_of_birth
  )
  VALUES (
    target_user_id, pin_val, name_val, designation_val, department_val, salary_val, hourly_val, email_val, password_val, 'employee', true, now()::date,
    CASE WHEN dob_val IS NOT NULL AND dob_val != '' THEN dob_val::date ELSE NULL END
  )
  ON CONFLICT (id) DO UPDATE
  SET
    pin = pin_val,
    full_name = name_val,
    designation = designation_val,
    department = department_val,
    base_salary = salary_val,
    hourly_rate = hourly_val,
    email = email_val,
    password = COALESCE(NULLIF(password_val, ''), public.profiles.password),
    date_of_birth = CASE WHEN dob_val IS NOT NULL AND dob_val != '' THEN dob_val::date ELSE public.profiles.date_of_birth END;

  RETURN target_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.save_employee_user TO anon, authenticated, service_role;
