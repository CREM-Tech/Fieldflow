-- FieldFlow Migration 002 — Row Level Security
-- Run AFTER 001. Locks down every table.

-- Helper function: get the current user's role from allowed_users
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS text LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT role FROM public.allowed_users
  WHERE lower(email) = lower(auth.jwt() ->> 'email')
    AND active = true
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.current_user_is_super()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.allowed_users
    WHERE lower(email) = lower(auth.jwt() ->> 'email')
      AND role = 'superintendent'
      AND active = true
  );
$$;

CREATE OR REPLACE FUNCTION public.current_user_is_staff()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.allowed_users
    WHERE lower(email) = lower(auth.jwt() ->> 'email')
      AND role IN ('superintendent','foreman')
      AND active = true
  );
$$;

-- ── Enable RLS on all tables ──────────────────────────────────
ALTER TABLE public.users                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schedule_entries      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schedule_overrides    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.school_sessions       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.requests              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schedule_changes      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_settings          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.allowed_users         ENABLE ROW LEVEL SECURITY;

-- ── users ─────────────────────────────────────────────────────
CREATE POLICY "users_read_own"   ON public.users FOR SELECT USING (id = auth.uid());
CREATE POLICY "users_super_all"  ON public.users FOR ALL    USING (public.current_user_is_super());

-- ── employees — all staff can read, only supers can write ─────
CREATE POLICY "employees_staff_read"  ON public.employees FOR SELECT USING (public.current_user_is_staff());
CREATE POLICY "employees_super_write" ON public.employees FOR ALL    USING (public.current_user_is_super());

-- ── jobs — all staff can read, only supers can write ─────────
CREATE POLICY "jobs_staff_read"  ON public.jobs FOR SELECT USING (public.current_user_is_staff());
CREATE POLICY "jobs_super_write" ON public.jobs FOR ALL    USING (public.current_user_is_super());

-- ── schedule_entries — all staff read, supers + foremen write ─
CREATE POLICY "sched_staff_read"  ON public.schedule_entries FOR SELECT USING (public.current_user_is_staff());
CREATE POLICY "sched_staff_write" ON public.schedule_entries FOR ALL    USING (public.current_user_is_staff());

-- ── schedule_overrides — all staff read/write ────────────────
CREATE POLICY "overrides_staff_read"  ON public.schedule_overrides FOR SELECT USING (public.current_user_is_staff());
CREATE POLICY "overrides_staff_write" ON public.schedule_overrides FOR ALL    USING (public.current_user_is_staff());

-- ── school_sessions — all staff read, supers write ───────────
CREATE POLICY "school_staff_read"  ON public.school_sessions FOR SELECT USING (public.current_user_is_staff());
CREATE POLICY "school_super_write" ON public.school_sessions FOR ALL    USING (public.current_user_is_super());

-- ── requests — staff can read/create, supers can decide ───────
CREATE POLICY "requests_staff_read"   ON public.requests FOR SELECT USING (public.current_user_is_staff());
CREATE POLICY "requests_staff_insert" ON public.requests FOR INSERT WITH CHECK (public.current_user_is_staff());
CREATE POLICY "requests_super_update" ON public.requests FOR UPDATE USING (public.current_user_is_super());

-- ── schedule_changes audit log — all staff read, system writes ─
CREATE POLICY "changes_staff_read"  ON public.schedule_changes FOR SELECT USING (public.current_user_is_staff());
CREATE POLICY "changes_staff_write" ON public.schedule_changes FOR INSERT WITH CHECK (public.current_user_is_staff());

-- ── notification_settings — super only ───────────────────────
CREATE POLICY "notif_super" ON public.notification_settings FOR ALL USING (public.current_user_is_super());

-- ── app_settings — super only ────────────────────────────────
CREATE POLICY "settings_super" ON public.app_settings FOR ALL USING (public.current_user_is_super());

-- ── allowed_users — super only ───────────────────────────────
CREATE POLICY "allowed_super_read"  ON public.allowed_users FOR SELECT USING (public.current_user_is_super());
CREATE POLICY "allowed_super_write" ON public.allowed_users FOR ALL    USING (public.current_user_is_super());
