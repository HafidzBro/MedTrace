# MedTrace Supabase Migrations

Canonical development migration order:

1. `20240101000000_init_schema.sql`
2. `20240101000001_rls_policies.sql`
3. `20260507000000_security_hardening.sql`

Do not copy legacy migrations back into this directory without reconciling the
schema with the Flutter app and RLS policies first. Supabase CLI applies every
SQL file in this folder in sorted order, so conflicting schema histories can
break a fresh database before development starts.

The old `001_init.sql` and `002_registration.sql` files are archived under
`supabase/legacy_migrations/` because they use a different patient model
(`patients.profile_id`, an `admin` role, PostGIS location columns, and different
medication-log relationships) than the current application code.
