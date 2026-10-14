-- ==============================================================================
-- ELIPSE HR PORTAL - MASTER DATABASE SETUP SCRIPT
-- ==============================================================================
-- Run this script in the Supabase SQL Editor (or PostgreSQL 14+)
-- It is completely IDEMPOTENT (safe to run on a brand new or existing database).
-- It creates all tables, columns, indexes, constraints, default rows, RLS policies,
-- realtime publications, and secure RPC stored procedures.
-- ==============================================================================

-- Enable required PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 1. PROFILES TABLE (Core Employee Directory & User Metadata)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    pin TEXT UNIQUE,
    full_name TEXT NOT NULL,
    designation TEXT DEFAULT '',
    department TEXT DEFAULT '',
    joining_date DATE DEFAULT CURRENT_DATE,
    base_salary NUMERIC(12, 2) DEFAULT 0.00,
    hourly_rate NUMERIC(10, 2) DEFAULT 0.00,
    role TEXT DEFAULT 'employee' CHECK (role IN ('admin', 'employee')),
    contact_number TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    email TEXT,
    password TEXT,
    date_of_birth DATE,
    income_tax NUMERIC(10, 2) DEFAULT 0.00,
    is_first_login BOOLEAN DEFAULT false,
    nic_no TEXT,
    emergency_contacts JSONB DEFAULT '[]'::jsonb,
    timeline_periods JSONB DEFAULT '[]'::jsonb,
    warning_text TEXT,
    warning_expiry TIMESTAMPTZ,
    warning_color TEXT,
    warning_active BOOLEAN DEFAULT false,
    bank_name TEXT,
    bank_account_title TEXT,
    bank_account_no TEXT,
    payment_method TEXT DEFAULT 'Bank' CHECK (payment_method IN ('Bank', 'Cash')),
    phone TEXT,
    display_order INTEGER DEFAULT 0,
    allowed_tabs JSONB DEFAULT '[]'::jsonb,
    left_date DATE
);

-- Ensure all columns exist if table was already created
DO $$
BEGIN
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pin TEXT UNIQUE;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS full_name TEXT;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS designation TEXT DEFAULT '';
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS department TEXT DEFAULT '';
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS joining_date DATE DEFAULT CURRENT_DATE;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS base_salary NUMERIC(12, 2) DEFAULT 0.00;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS hourly_rate NUMERIC(10, 2) DEFAULT 0.00;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'employee';
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS contact_number TEXT;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS email TEXT;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS date_of_birth DATE;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS income_tax NUMERIC(10, 2) DEFAULT 0.00;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_first_login BOOLEAN DEFAULT false;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS nic_no TEXT;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS emergency_contacts JSONB DEFAULT '[]'::jsonb;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS timeline_periods JSONB DEFAULT '[]'::jsonb;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS warning_text TEXT;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS warning_expiry TIMESTAMPTZ;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS warning_color TEXT;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS warning_active BOOLEAN DEFAULT false;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS bank_name TEXT;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS bank_account_title TEXT;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS bank_account_no TEXT;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'Bank';
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone TEXT;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS allowed_tabs JSONB DEFAULT '[]'::jsonb;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS left_date DATE;
END $$;

CREATE INDEX IF NOT EXISTS idx_profiles_pin ON public.profiles(pin);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_active ON public.profiles(is_active);

-- ==============================================================================
-- 2. RAW ATTENDANCE LOGS TABLE (Hardware Biometric Punches)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.raw_attendance_logs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_pin TEXT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,
    verify_type INTEGER DEFAULT 0, -- 1: fingerprint, 4: card, 15: face, etc.
    status_type INTEGER DEFAULT 0, -- 0: check-in, 1: check-out
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_pin_timestamp UNIQUE (employee_pin, timestamp)
);

CREATE INDEX IF NOT EXISTS idx_raw_logs_pin_timestamp ON public.raw_attendance_logs(employee_pin, timestamp);
CREATE INDEX IF NOT EXISTS idx_raw_logs_timestamp ON public.raw_attendance_logs(timestamp);

-- ==============================================================================
-- 3. DEVICE SETTINGS TABLE (ZKTeco K40 Config & Backup Settings)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.device_settings (
    id INTEGER PRIMARY KEY DEFAULT 1,
    ip_address TEXT DEFAULT '192.168.88.119',
    port INTEGER DEFAULT 4370,
    sync_interval INTEGER DEFAULT 1,
    last_sync TIMESTAMPTZ,
    status TEXT DEFAULT 'Offline',
    last_connection_state TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    grace_time_mins INTEGER DEFAULT 15,
    monthly_grace_settings JSONB DEFAULT '{}'::jsonb,
    default_shift_start_time TEXT DEFAULT '11:00',
    default_shift_end_time TEXT DEFAULT '20:00',
    default_shift_total_hours NUMERIC DEFAULT 9,
    is_notifications_muted BOOLEAN DEFAULT false,
    auto_backup_enabled BOOLEAN DEFAULT true,
    backup_directory TEXT,
    last_backup_time TIMESTAMPTZ
);

DO $$
BEGIN
    ALTER TABLE public.device_settings ADD COLUMN IF NOT EXISTS ip_address TEXT DEFAULT '192.168.88.119';
    ALTER TABLE public.device_settings ADD COLUMN IF NOT EXISTS port INTEGER DEFAULT 4370;
    ALTER TABLE public.device_settings ADD COLUMN IF NOT EXISTS sync_interval INTEGER DEFAULT 1;
    ALTER TABLE public.device_settings ADD COLUMN IF NOT EXISTS last_sync TIMESTAMPTZ;
    ALTER TABLE public.device_settings ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'Offline';
    ALTER TABLE public.device_settings ADD COLUMN IF NOT EXISTS last_connection_state TEXT;
    ALTER TABLE public.device_settings ADD COLUMN IF NOT EXISTS grace_time_mins INTEGER DEFAULT 15;
    ALTER TABLE public.device_settings ADD COLUMN IF NOT EXISTS monthly_grace_settings JSONB DEFAULT '{}'::jsonb;
    ALTER TABLE public.device_settings ADD COLUMN IF NOT EXISTS default_shift_start_time TEXT DEFAULT '11:00';
    ALTER TABLE public.device_settings ADD COLUMN IF NOT EXISTS default_shift_end_time TEXT DEFAULT '20:00';
    ALTER TABLE public.device_settings ADD COLUMN IF NOT EXISTS default_shift_total_hours NUMERIC DEFAULT 9;
    ALTER TABLE public.device_settings ADD COLUMN IF NOT EXISTS is_notifications_muted BOOLEAN DEFAULT false;
    ALTER TABLE public.device_settings ADD COLUMN IF NOT EXISTS auto_backup_enabled BOOLEAN DEFAULT true;
    ALTER TABLE public.device_settings ADD COLUMN IF NOT EXISTS backup_directory TEXT;
    ALTER TABLE public.device_settings ADD COLUMN IF NOT EXISTS last_backup_time TIMESTAMPTZ;
END $$;

-- Insert singleton default configuration record (id = 1) if not exists
INSERT INTO public.device_settings (id, ip_address, port, sync_interval, status, grace_time_mins, default_shift_start_time, default_shift_end_time, default_shift_total_hours, auto_backup_enabled)
VALUES (1, '192.168.88.119', 4370, 1, 'Online', 20, '11:00', '20:00', 9, true)
ON CONFLICT (id) DO NOTHING;

-- ==============================================================================
-- 4. SHIFT TIMINGS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.shift_timings (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    target_type TEXT DEFAULT 'global_default' CHECK (target_type IN ('employee', 'designation', 'department', 'global_default')),
    target_id TEXT NOT NULL,
    target_name TEXT DEFAULT '',
    start_time TIME NOT NULL DEFAULT '11:00:00',
    end_time TIME NOT NULL DEFAULT '20:00:00',
    grace_mins INTEGER DEFAULT 15,
    days TEXT[] DEFAULT ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
    is_fixed_hours BOOLEAN DEFAULT false,
    total_hours NUMERIC DEFAULT 9,
    saturday_option TEXT DEFAULT 'alternate' CHECK (saturday_option IN ('alternate', 'all_off', 'all_working')),
    allow_regular_overtime BOOLEAN DEFAULT false,
    grace_period_mins INTEGER DEFAULT 15,
    saturday_rule TEXT DEFAULT 'alternate',
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

DO $$
BEGIN
    ALTER TABLE public.shift_timings ADD COLUMN IF NOT EXISTS target_type TEXT DEFAULT 'global_default';
    ALTER TABLE public.shift_timings ADD COLUMN IF NOT EXISTS target_id TEXT;
    ALTER TABLE public.shift_timings ADD COLUMN IF NOT EXISTS target_name TEXT DEFAULT '';
    ALTER TABLE public.shift_timings ADD COLUMN IF NOT EXISTS grace_mins INTEGER DEFAULT 15;
    ALTER TABLE public.shift_timings ADD COLUMN IF NOT EXISTS days TEXT[];
    ALTER TABLE public.shift_timings ADD COLUMN IF NOT EXISTS is_fixed_hours BOOLEAN DEFAULT false;
    ALTER TABLE public.shift_timings ADD COLUMN IF NOT EXISTS total_hours NUMERIC DEFAULT 9;
    ALTER TABLE public.shift_timings ADD COLUMN IF NOT EXISTS saturday_option TEXT DEFAULT 'alternate';
    ALTER TABLE public.shift_timings ADD COLUMN IF NOT EXISTS allow_regular_overtime BOOLEAN DEFAULT false;
    ALTER TABLE public.shift_timings ADD COLUMN IF NOT EXISTS grace_period_mins INTEGER DEFAULT 15;
    ALTER TABLE public.shift_timings ADD COLUMN IF NOT EXISTS saturday_rule TEXT DEFAULT 'alternate';
END $$;

-- ==============================================================================
-- 5. LEAVE REQUESTS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.leave_requests (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    leave_type TEXT CHECK (leave_type IN ('Casual', 'Medical', 'Annual')) NOT NULL,
    status TEXT CHECK (status IN ('Pending', 'Approved', 'Rejected')) DEFAULT 'Pending' NOT NULL,
    reason TEXT,
    requested_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    approved_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_leave_requests_emp ON public.leave_requests(employee_id);
CREATE INDEX IF NOT EXISTS idx_leave_requests_dates ON public.leave_requests(start_date, end_date);

-- ==============================================================================
-- 6. LEAVE BALANCES TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.leave_balances (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL UNIQUE,
    casual_total INTEGER DEFAULT 10,
    casual_used INTEGER DEFAULT 0,
    medical_total INTEGER DEFAULT 10,
    medical_used INTEGER DEFAULT 0,
    annual_total INTEGER DEFAULT 10,
    annual_used INTEGER DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==============================================================================
-- 7. COMPLAINTS TABLE (Helpdesk & Attendance Correction Requests)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.complaints (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT CHECK (status IN ('Open', 'In Progress', 'Resolved', 'Ignored', 'Rejected', 'Approved', 'Closed')) DEFAULT 'Open',
    resolution TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_complaints_emp ON public.complaints(employee_id);

-- ==============================================================================
-- 8. APPROVED ATTENDANCE CORRECTIONS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.approved_attendance_corrections (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id TEXT NOT NULL,
    employee_pin TEXT,
    date DATE NOT NULL,
    check_in TIME,
    check_out TIME,
    status TEXT DEFAULT 'Approved',
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_employee_date_corr UNIQUE (employee_id, date)
);

CREATE INDEX IF NOT EXISTS idx_corr_emp_date ON public.approved_attendance_corrections(employee_id, date);

-- ==============================================================================
-- 9. ANNOUNCEMENTS TABLE (Broadcasts, Schedules & Auto-Disposal)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.announcements (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    target_type TEXT CHECK (target_type IN ('all', 'department', 'designation', 'employee')) DEFAULT 'all',
    target_value TEXT DEFAULT '',
    color TEXT DEFAULT '#ff3b57',
    status TEXT DEFAULT 'Active' CHECK (status IN ('Active', 'Disposed')),
    schedule_from TIMESTAMPTZ,
    dispose_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

DO $$
BEGIN
    ALTER TABLE public.announcements ADD COLUMN IF NOT EXISTS color TEXT DEFAULT '#ff3b57';
    ALTER TABLE public.announcements ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'Active';
    ALTER TABLE public.announcements ADD COLUMN IF NOT EXISTS schedule_from TIMESTAMPTZ;
    ALTER TABLE public.announcements ADD COLUMN IF NOT EXISTS dispose_at TIMESTAMPTZ;
END $$;

-- ==============================================================================
-- 10. NOTIFICATIONS TABLE (Real-Time Toast & Center Alerts)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id TEXT, -- TEXT accommodates UUIDs, 'admin', 'all', or employee PINs
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

DO $$
BEGIN
    ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_user_id_fkey;
    ALTER TABLE public.notifications ALTER COLUMN user_id TYPE TEXT USING user_id::TEXT;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON public.notifications(created_at DESC);

-- ==============================================================================
-- 11. HOLIDAYS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.holidays (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date DATE NOT NULL UNIQUE,
    title TEXT NOT NULL,
    description TEXT,
    color TEXT DEFAULT '#3b82f6',
    created_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

DO $$
BEGIN
    ALTER TABLE public.holidays ADD COLUMN IF NOT EXISTS color TEXT DEFAULT '#3b82f6';
END $$;

-- ==============================================================================
-- 12. EMPLOYEE LOANS / ADVANCE SALARY TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.employee_loans (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    employee_id TEXT NOT NULL,
    employee_pin TEXT,
    employee_name TEXT,
    employee_contact TEXT,
    loan_name TEXT NOT NULL,
    loan_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    monthly_deduction NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    months_duration INTEGER DEFAULT 1,
    total_repaid NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    remaining_balance NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    status TEXT NOT NULL DEFAULT 'Pending',
    notes TEXT,
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    selected_months JSONB DEFAULT '[]'::jsonb,
    skipped_months JSONB DEFAULT '[]'::jsonb,
    months_skipped INTEGER DEFAULT 0,
    loan_tax_mode TEXT DEFAULT 'same',
    loan_tax_amount NUMERIC(12, 2) DEFAULT 0.00,
    deduction_basis TEXT DEFAULT 'net_salary',
    last_payment_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

DO $$
BEGIN
    ALTER TABLE public.employee_loans ADD COLUMN IF NOT EXISTS start_date TIMESTAMPTZ;
    ALTER TABLE public.employee_loans ADD COLUMN IF NOT EXISTS end_date TIMESTAMPTZ;
    ALTER TABLE public.employee_loans ADD COLUMN IF NOT EXISTS selected_months JSONB DEFAULT '[]'::jsonb;
    ALTER TABLE public.employee_loans ADD COLUMN IF NOT EXISTS skipped_months JSONB DEFAULT '[]'::jsonb;
    ALTER TABLE public.employee_loans ADD COLUMN IF NOT EXISTS months_skipped INTEGER DEFAULT 0;
    ALTER TABLE public.employee_loans ADD COLUMN IF NOT EXISTS loan_tax_mode TEXT DEFAULT 'same';
    ALTER TABLE public.employee_loans ADD COLUMN IF NOT EXISTS loan_tax_amount NUMERIC(12, 2) DEFAULT 0.00;
    ALTER TABLE public.employee_loans ADD COLUMN IF NOT EXISTS deduction_basis TEXT DEFAULT 'net_salary';
    ALTER TABLE public.employee_loans ADD COLUMN IF NOT EXISTS last_payment_date TIMESTAMPTZ;
END $$;

CREATE INDEX IF NOT EXISTS idx_loans_emp ON public.employee_loans(employee_id);

-- ==============================================================================
-- 13. TRUSTED DEVICES TABLE (Biometric Hardware & Bank-Grade Security)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.trusted_devices (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    device_id TEXT NOT NULL,
    user_email TEXT NOT NULL,
    auth_type TEXT DEFAULT 'fingerprint',
    device_name TEXT DEFAULT 'Trusted Device',
    icon_name TEXT DEFAULT 'fingerprint.svg',
    icon_path TEXT DEFAULT '/icons/fingerprint.svg',
    is_active BOOLEAN DEFAULT true,
    user_password TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_device_user UNIQUE (device_id, user_email)
);

CREATE INDEX IF NOT EXISTS idx_trusted_dev_id ON public.trusted_devices(device_id);
CREATE INDEX IF NOT EXISTS idx_trusted_dev_email ON public.trusted_devices(user_email);

-- ==============================================================================
-- 14. PURPOSE TRANSFERS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.purpose_transfers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    payee_name TEXT NOT NULL,
    purpose TEXT NOT NULL,
    amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    payment_method TEXT DEFAULT 'Bank' CHECK (payment_method IN ('Bank', 'Cash')),
    bank_name TEXT,
    bank_account_title TEXT,
    bank_account_no TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==============================================================================
-- 15. SALARY DIVISION PLANS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.salary_division_plans (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    month_key TEXT UNIQUE NOT NULL, -- Format: YYYY-MM
    division_count INTEGER NOT NULL DEFAULT 2,
    divisions JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==============================================================================
-- 16. USER PUSH TOKENS TABLE (Firebase Cloud Messaging & Web Push)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.user_push_tokens (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT,
    email TEXT,
    role TEXT DEFAULT 'employee',
    token TEXT UNIQUE NOT NULL,
    subscription_data TEXT,
    device_info TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==============================================================================
-- 17. DEPARTMENTS & DESIGNATIONS TABLES
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.departments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.designations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Populate standard default departments
INSERT INTO public.departments (name)
VALUES ('Administration'), ('Development'), ('Design'), ('Sales'), ('Marketing'), ('Operations'), ('Finance'), ('Human Resources')
ON CONFLICT (name) DO NOTHING;

-- Populate standard default designations
INSERT INTO public.designations (name)
VALUES ('CEO'), ('Director'), ('Manager'), ('HR Manager'), ('Software Engineer'), ('Senior Software Engineer'), ('Frontend Developer'), ('Backend Developer'), ('UI/UX Designer'), ('Graphic Designer'), ('Sales Executive'), ('Accountant')
ON CONFLICT (name) DO NOTHING;

-- ==============================================================================
-- 18. ROW LEVEL SECURITY (RLS) POLICIES & GRANTS
-- ==============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.raw_attendance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shift_timings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.approved_attendance_corrections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.holidays ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_loans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trusted_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purpose_transfers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salary_division_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_push_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.designations ENABLE ROW LEVEL SECURITY;

-- Set up permissive policies (authenticated portal users & service role)
DO $$
DECLARE
    tbl text;
    tables text[] := ARRAY[
        'profiles', 'raw_attendance_logs', 'device_settings', 'shift_timings',
        'leave_requests', 'leave_balances', 'complaints', 'approved_attendance_corrections',
        'announcements', 'notifications', 'holidays', 'employee_loans',
        'trusted_devices', 'purpose_transfers', 'salary_division_plans',
        'user_push_tokens', 'departments', 'designations'
    ];
BEGIN
    FOREACH tbl IN ARRAY tables LOOP
        EXECUTE format('DROP POLICY IF EXISTS "Allow portal access to %I" ON public.%I', tbl, tbl);
        EXECUTE format('CREATE POLICY "Allow portal access to %I" ON public.%I FOR ALL USING (true) WITH CHECK (true)', tbl, tbl);
        EXECUTE format('GRANT ALL ON public.%I TO anon, authenticated, service_role', tbl);
    END LOOP;
END $$;

-- ==============================================================================
-- 19. SUPABASE REALTIME REPLICATION (For Live Push Notifications)
-- ==============================================================================
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.announcements;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.device_settings;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- ==============================================================================
-- 20. STORED PROCEDURES / RPC FUNCTIONS
-- ==============================================================================

-- 1. save_employee_user (Securely creates/updates auth.users and public.profiles)
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
SET search_path = public, extensions, pg_temp
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

-- 2. delete_employee_user
CREATE OR REPLACE FUNCTION public.delete_employee_user(user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  DELETE FROM auth.users WHERE id = user_id;
  DELETE FROM public.profiles WHERE id = user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.save_employee_user TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.delete_employee_user TO anon, authenticated, service_role;

-- ==============================================================================
-- SETUP COMPLETE! ALL 19 TABLES, INDEXES, RLS POLICIES & RPCS ARE READY.
-- ==============================================================================
