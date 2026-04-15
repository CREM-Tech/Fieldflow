# FieldFlow

Workforce scheduling app for electrical contractors.

## Files

- `index.html` — the full app (open this in a browser)
- `001_core_schema.sql` — run first in Supabase SQL Editor
- `002_rls_policies.sql` — run second
- `003_triggers.sql` — run third
- `004_seed_data.sql` — run fourth (seeds all 44 employees + jobs)

## Deploy

Hosted on Railway. Auth via Supabase magic link.
Only emails in the `allowed_users` table can sign in.
