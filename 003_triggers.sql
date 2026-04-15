-- FieldFlow Migration 003 — Triggers
-- Run AFTER 002.

-- ── Trigger 1: Auto-fill school weeks ────────────────────────
-- When a school_session is inserted, automatically create schedule_entries
-- (type='school') for every matching apprentice for Mon-Fri of that session.
-- "Matching" = role_code matches the class_code (e.g. class '2D' → role '2D').

CREATE OR REPLACE FUNCTION public.auto_fill_school_session()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  emp     RECORD;
  d       date;
BEGIN
  -- Find employees whose role_code matches this school session class code
  FOR emp IN
    SELECT id FROM public.employees
    WHERE role_code = NEW.class_code AND active = true
  LOOP
    -- Fill Mon-Fri for the session date range
    d := NEW.start_date;
    WHILE d <= NEW.end_date LOOP
      -- Skip weekends
      IF EXTRACT(DOW FROM d) BETWEEN 1 AND 5 THEN
        INSERT INTO public.schedule_entries
          (employee_id, entry_date, entry_type, job_id, note)
        VALUES
          (emp.id, d, 'school', NULL, 'Auto-filled: ' || NEW.class_code)
        ON CONFLICT (employee_id, entry_date)
        DO UPDATE SET entry_type = 'school', job_id = NULL,
                      note = 'Auto-filled: ' || NEW.class_code;
      END IF;
      d := d + INTERVAL '1 day';
    END LOOP;
  END LOOP;

  RETURN NEW;
END;
$$;

CREATE TRIGGER auto_fill_school
  AFTER INSERT ON public.school_sessions
  FOR EACH ROW EXECUTE FUNCTION public.auto_fill_school_session();

-- ── Trigger 2: Auto-fill school for new employee ─────────────
-- When a new employee is added, fill any existing school sessions
-- that match their role_code.

CREATE OR REPLACE FUNCTION public.auto_fill_new_employee_school()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  sess RECORD;
  d    date;
BEGIN
  FOR sess IN
    SELECT * FROM public.school_sessions
    WHERE class_code = NEW.role_code
  LOOP
    d := sess.start_date;
    WHILE d <= sess.end_date LOOP
      IF EXTRACT(DOW FROM d) BETWEEN 1 AND 5 THEN
        INSERT INTO public.schedule_entries
          (employee_id, entry_date, entry_type, job_id, note)
        VALUES
          (NEW.id, d, 'school', NULL, 'Auto-filled: ' || sess.class_code)
        ON CONFLICT (employee_id, entry_date) DO NOTHING;
      END IF;
      d := d + INTERVAL '1 day';
    END LOOP;
  END LOOP;

  RETURN NEW;
END;
$$;

CREATE TRIGGER auto_fill_new_employee_school
  AFTER INSERT ON public.employees
  FOR EACH ROW EXECUTE FUNCTION public.auto_fill_new_employee_school();

-- ── Trigger 3: Log schedule changes ──────────────────────────
-- Writes an audit row to schedule_changes whenever a schedule_override is inserted.

CREATE OR REPLACE FUNCTION public.log_schedule_override()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.schedule_changes
    (employee_id, entry_date, to_job_id, scope, changed_by, note)
  VALUES
    (NEW.employee_id, NEW.entry_date, NEW.job_id, 'day', NEW.changed_by,
     'Single-day override via schedule grid');
  RETURN NEW;
END;
$$;

CREATE TRIGGER log_override
  AFTER INSERT OR UPDATE ON public.schedule_overrides
  FOR EACH ROW EXECUTE FUNCTION public.log_schedule_override();

-- ── Trigger 4: Conflict detection ────────────────────────────
-- When a schedule_entry is inserted/updated to type='job',
-- check if the employee has a school entry that same day.
-- If so, mark the entry as 'conflict' instead and raise a notice.

CREATE OR REPLACE FUNCTION public.detect_school_conflict()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  has_school boolean;
BEGIN
  -- Only check job entries
  IF NEW.entry_type != 'job' THEN RETURN NEW; END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.schedule_entries
    WHERE employee_id = NEW.employee_id
      AND entry_date  = NEW.entry_date
      AND entry_type  = 'school'
      AND id          != NEW.id
  ) INTO has_school;

  IF has_school THEN
    NEW.entry_type := 'conflict';
    RAISE NOTICE 'School conflict detected for employee % on %', NEW.employee_id, NEW.entry_date;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER detect_conflict
  BEFORE INSERT OR UPDATE ON public.schedule_entries
  FOR EACH ROW EXECUTE FUNCTION public.detect_school_conflict();
