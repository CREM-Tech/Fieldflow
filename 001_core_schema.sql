-- FieldFlow Migration 001 — Core Schema
-- Run this first. Creates all tables.
-- Paste into Supabase SQL Editor → Run

-- ── Extensions ───────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── users ────────────────────────────────────────────────────
-- Extends Supabase auth.users. One row per person who can log in.
CREATE TABLE public.users (
  id         uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email      text NOT NULL UNIQUE,
  name       text NOT NULL,
  role       text NOT NULL CHECK (role IN ('superintendent','foreman','hr','finance')),
  active     boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ── employees ─────────────────────────────────────────────────
-- Every crew member. Not all employees can log in — only those in users table.
CREATE TABLE public.employees (
  id           uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  last_name    text NOT NULL,
  first_name   text NOT NULL,
  role_code    text NOT NULL DEFAULT '',   -- GF, FM, JN, MH, 1A, 2B, etc.
  badge        text,                       -- AWS, etc.
  -- Certifications (boolean held or not)
  cert_wa      boolean NOT NULL DEFAULT false,  -- WA License
  cert_or      boolean NOT NULL DEFAULT false,  -- OR License
  cert_aerial  boolean NOT NULL DEFAULT false,  -- Aerial Lift
  cert_forklift boolean NOT NULL DEFAULT false, -- Forklift
  cert_hazwoper boolean NOT NULL DEFAULT false, -- HAZWOPER
  cert_osha10  boolean NOT NULL DEFAULT false,  -- OSHA 10
  cert_osha30  boolean NOT NULL DEFAULT false,  -- OSHA 30
  -- Cert expiry dates (null = no expiry set)
  cert_wa_exp      date,
  cert_or_exp      date,
  cert_aerial_exp  date,
  cert_forklift_exp date,
  cert_hazwoper_exp date,
  cert_osha10_exp  date,
  cert_osha30_exp  date,
  active       boolean NOT NULL DEFAULT true,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX employees_name_idx ON public.employees (last_name, first_name);

-- ── jobs ──────────────────────────────────────────────────────
CREATE TABLE public.jobs (
  id           uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name         text NOT NULL UNIQUE,       -- e.g. 'PDX247 BMS'
  number       text NOT NULL DEFAULT '',   -- project number
  location     text NOT NULL DEFAULT 'Portland, OR',
  status       text NOT NULL DEFAULT 'active'
                 CHECK (status IN ('active','inactive','pending')),
  lead_name    text,                       -- GF/FM name
  lead_email   text,                       -- for email notifications
  notes        text,
  color        text NOT NULL DEFAULT '#3B82F6',  -- hex color for UI
  ot_hrs       numeric(4,1) NOT NULL DEFAULT 0,  -- weekly OT hours per person
  finance_job_id text,                     -- stub for FinanceFlow
  created_at   timestamptz NOT NULL DEFAULT now()
);

-- ── schedule_entries ──────────────────────────────────────────
-- ONE ROW per employee per day. This is the base schedule.
CREATE TABLE public.schedule_entries (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_id uuid NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  entry_date  date NOT NULL,
  entry_type  text NOT NULL DEFAULT 'job'
                CHECK (entry_type IN ('job','school','vacation','holiday','conflict','unassigned','off')),
  job_id      uuid REFERENCES public.jobs(id) ON DELETE SET NULL,
  note        text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (employee_id, entry_date)
);

CREATE INDEX schedule_entries_date_idx     ON public.schedule_entries (entry_date);
CREATE INDEX schedule_entries_employee_idx ON public.schedule_entries (employee_id);
CREATE INDEX schedule_entries_job_idx      ON public.schedule_entries (job_id);

-- ── schedule_overrides ────────────────────────────────────────
-- Single-day overrides — wins over schedule_entries when both exist.
-- Used by the "click a cell to change one day" feature.
CREATE TABLE public.schedule_overrides (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_id uuid NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  entry_date  date NOT NULL,
  entry_type  text NOT NULL DEFAULT 'job'
                CHECK (entry_type IN ('job','school','vacation','holiday','off','unassigned')),
  job_id      uuid REFERENCES public.jobs(id) ON DELETE SET NULL,
  note        text,
  changed_by  uuid REFERENCES public.users(id) ON DELETE SET NULL,
  changed_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (employee_id, entry_date)   -- one override per employee per day max
);

CREATE INDEX schedule_overrides_date_idx     ON public.schedule_overrides (entry_date);
CREATE INDEX schedule_overrides_employee_idx ON public.schedule_overrides (employee_id);

-- ── school_sessions ───────────────────────────────────────────
CREATE TABLE public.school_sessions (
  id         uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  class_code text NOT NULL,    -- e.g. '2D', '4A'
  start_date date NOT NULL,
  end_date   date NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (end_date >= start_date)
);

-- ── requests ──────────────────────────────────────────────────
CREATE TABLE public.requests (
  id           uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  title        text NOT NULL,
  submitted_by uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  status       text NOT NULL DEFAULT 'pending'
                 CHECK (status IN ('pending','approved','denied')),
  decided_by   uuid REFERENCES public.users(id) ON DELETE SET NULL,
  decided_at   timestamptz,
  notes        text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  -- Prevent self-approval
  CHECK (decided_by IS NULL OR decided_by != submitted_by)
);

-- ── schedule_changes (audit log) ──────────────────────────────
CREATE TABLE public.schedule_changes (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_id uuid REFERENCES public.employees(id) ON DELETE SET NULL,
  entry_date  date,
  from_job_id uuid REFERENCES public.jobs(id) ON DELETE SET NULL,
  to_job_id   uuid REFERENCES public.jobs(id) ON DELETE SET NULL,
  scope       text CHECK (scope IN ('day','week','future')),
  changed_by  uuid REFERENCES public.users(id) ON DELETE SET NULL,
  changed_at  timestamptz NOT NULL DEFAULT now(),
  note        text
);

-- ── notification_settings ─────────────────────────────────────
CREATE TABLE public.notification_settings (
  key        text PRIMARY KEY,
  enabled    boolean NOT NULL DEFAULT true,
  updated_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO public.notification_settings (key, enabled) VALUES
  ('move',     true),
  ('request',  true),
  ('approved', true),
  ('cert',     true),
  ('school',   true),
  ('digest',   false);

-- ── app_settings ─────────────────────────────────────────────
CREATE TABLE public.app_settings (
  key   text PRIMARY KEY,
  value text
);

INSERT INTO public.app_settings (key, value) VALUES
  ('hr_name',  NULL),
  ('hr_email', NULL);

-- ── allowed_users (auth allowlist) ───────────────────────────
-- Controls who can sign in. Email must be in this table.
CREATE TABLE public.allowed_users (
  id         uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  email      text NOT NULL UNIQUE,
  name       text NOT NULL,
  role       text NOT NULL CHECK (role IN ('superintendent','foreman','hr','finance')),
  active     boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX allowed_users_email_idx ON public.allowed_users (lower(email));

-- ── Seed your first superintendent ───────────────────────────
-- IMPORTANT: Replace with your real email before running
INSERT INTO public.allowed_users (email, name, role) VALUES
  ('your@email.com', 'Your Name', 'superintendent');
