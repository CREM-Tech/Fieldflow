-- FieldFlow Migration 004 — Seed Data
-- Run AFTER 003. Inserts all 44 employees, 7 jobs, and school sessions
-- to match the prototype exactly.

-- ── Jobs ─────────────────────────────────────────────────────
INSERT INTO public.jobs (name, number, location, status, lead_name, lead_email, notes, color, ot_hrs) VALUES
  ('PDX247 BMS',  'PDX247',  'Portland, OR', 'active', 'Porter, Billy',   'bporter@crem.com',   'BMS install — Level 3 & 4',        '#3B82F6', 0),
  ('PDX246 SEC',  'PDX246',  'Portland, OR', 'active', 'Olveda, Tanner',  'tolveda@crem.com',   'Security system rough-in',          '#8B5CF6', 0),
  ('PDX247 SEC',  'PDX247B', 'Portland, OR', 'active', 'Frison, Brad',    'bfrison@crem.com',   'Security panels — west wing',       '#EC4899', 0),
  ('CAMPUS WIDE', 'CW-01',   'Portland, OR', 'active', 'Marsolek, Tyler', 'tmarsolek@crem.com', 'Campus-wide conduit run',           '#F59E0B', 0),
  ('Live Work',   'LW-OPS',  'Various',      'active', 'Munson, Mike',    'mmunson@crem.com',   'On-call live work / outages',       '#EF4444', 0),
  ('WTB',         'WTB-01',  'Portland, OR', 'active', 'Isley, Mike',     'misley@crem.com',    'Warehouse to building feeder',      '#10B981', 0),
  ('SERVICE',     'SVC-01',  'Various',      'active', 'Clugston, Cody',  'cclugston@crem.com', 'Service calls',                    '#6B7280', 0)
ON CONFLICT (name) DO NOTHING;

-- ── Employees ─────────────────────────────────────────────────
-- All 44 crew members from the roster
-- Fields: last_name, first_name, role_code, badge, cert_wa, cert_or, cert_aerial, cert_forklift, cert_hazwoper, cert_osha10, cert_osha30
INSERT INTO public.employees (last_name, first_name, role_code, badge, cert_wa, cert_or, cert_aerial, cert_forklift, cert_hazwoper, cert_osha10, cert_osha30) VALUES
  ('Berry',      'Vanessa',   '',    '',    false, false, false, false, false, false, false),
  ('Boden',      'Charlie',   'JN',  'AWS', true,  false, false, false, false, true,  false),
  ('Boles',      'James',     'FM',  '',    true,  false, true,  true,  true,  true,  true),
  ('Braught',    'Isaiah',    'JN',  'AWS', true,  false, false, false, false, true,  false),
  ('Brundridge', 'Guinevere', 'JN',  '',    true,  false, false, false, false, false, false),
  ('Budan',      'Ryan',      'JN',  '',    true,  false, false, false, false, false, false),
  ('Campuzano',  'Eric',      '1E',  '',    false, false, false, false, false, false, false),
  ('Chirhart',   'Phillip',   'JN',  'AWS', true,  false, false, false, false, false, false),
  ('Clark',      'Collin',    'MH',  '',    false, false, false, false, false, false, false),
  ('Clugston',   'Cody',      'JN',  'AWS', true,  false, true,  false, false, false, false),
  ('Cole',       'Kolten',    '1C',  'AWS', false, false, false, false, false, false, false),
  ('Cramer',     'Mason',     'FM',  'AWS', true,  false, false, false, false, true,  false),
  ('Davis',      'Jayden',    '1A',  'AWS', false, false, false, false, false, false, false),
  ('Dik',        'Stefhan',   'JN',  '',    true,  false, false, false, false, false, false),
  ('Fellows',    'Shay',      '4B',  'AWS', false, false, false, false, false, false, false),
  ('Fielding',   'Joshua',    'MH',  '',    false, false, false, false, false, false, false),
  ('Frison',     'Brad',      'FM',  'AWS', true,  false, false, true,  false, true,  false),
  ('Grossruck',  'Michael',   'JN',  '',    true,  false, false, false, false, false, false),
  ('Gunderson',  'Hunter',    '4B',  'AWS', false, false, false, false, false, false, false),
  ('Isley',      'Mike',      'FM',  '',    true,  false, false, false, false, false, false),
  ('Kegel',      'Alex',      '2D',  'AWS', false, false, false, false, false, false, false),
  ('Lambert',    'Kevin',     'GF',  '',    true,  false, false, false, false, false, false),
  ('Marsolek',   'Tyler',     'GF',  'AWS', true,  false, false, false, false, false, false),
  ('Mellotte',   'Colby',     '2B',  'AWS', false, false, false, false, false, false, false),
  ('Mercado',    'Fabian',    'MH',  '',    false, false, false, false, false, false, false),
  ('Miller',     'Easton',    '1',   '',    false, false, false, false, false, false, false),
  ('Montelongo', 'Miguel',    'MH',  '',    false, false, false, false, false, false, false),
  ('Munson',     'Mike',      'GF',  'AWS', true,  true,  false, false, true,  false, false),
  ('Olveda',     'Tanner',    'FM',  'AWS', true,  false, true,  false, false, true,  false),
  ('Ortega',     'Miguel',    '5B',  'AWS', true,  false, false, false, false, false, false),
  ('Pierce',     'Ernest',    '2A',  '',    true,  false, false, false, false, false, false),
  ('Porter',     'Billy',     'FM',  'AWS', true,  true,  false, false, false, true,  true),
  ('Purser',     'Tim',       'FM',  'AWS', true,  false, false, false, false, true,  false),
  ('Reynolds',   'Brendan',   '5A',  '',    true,  false, false, false, false, false, false),
  ('Robins',     'Jason',     '4A',  '',    false, false, false, false, false, false, false),
  ('Rodgers',    'Shawn',     'JN',  'var', true,  false, false, false, false, false, false),
  ('Schroder',   'Hailey',    '',    '',    false, false, false, false, false, false, false),
  ('Sholotyuk',  'Alexsei',   '2E',  'AWS', true,  false, false, false, false, false, false),
  ('Siharath',   'Vayourinh', 'GF',  'AWS', true,  true,  false, false, false, true,  true),
  ('Sorbel',     'Chayce',    'GF',  'AWS', true,  true,  true,  true,  true,  true,  true),
  ('Tikka',      'Alan',      'JN',  '',    true,  false, false, false, false, false, false),
  ('Walker',     'Rodger',    '5A',  'AWS', true,  false, false, false, false, false, false),
  ('Weaver',     'Corey',     'JN',  'AWS', true,  false, false, false, false, false, false),
  ('Neal',       'James',     'JN',  '',    false, false, false, false, false, false, false)
ON CONFLICT DO NOTHING;

-- ── School sessions ───────────────────────────────────────────
-- Triggers will auto-fill schedule_entries for matching apprentices
INSERT INTO public.school_sessions (class_code, start_date, end_date) VALUES
  ('2D', '2026-04-13', '2026-04-17'),
  ('4A', '2026-04-13', '2026-04-17'),
  ('2E', '2026-04-20', '2026-04-24'),
  ('4B', '2026-04-20', '2026-04-24'),
  ('1E', '2026-04-27', '2026-05-01'),
  ('1C', '2026-05-18', '2026-05-22'),
  ('5A', '2026-02-02', '2026-02-06'),
  ('2B', '2026-02-09', '2026-02-13'),
  ('1A', '2026-03-16', '2026-03-20'),
  ('2A', '2026-02-02', '2026-02-06')
ON CONFLICT DO NOTHING;

-- ── Verification query ────────────────────────────────────────
-- Run this after the seed to confirm everything loaded correctly:
SELECT
  (SELECT count(*) FROM public.employees)             AS employees,
  (SELECT count(*) FROM public.jobs)                  AS jobs,
  (SELECT count(*) FROM public.school_sessions)       AS school_sessions,
  (SELECT count(*) FROM public.schedule_entries)      AS schedule_entries_auto_filled,
  (SELECT count(*) FROM public.allowed_users)         AS allowed_users;
