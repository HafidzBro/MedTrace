# MedTrace Supabase Migrations

Canonical development migration order:

1. `20240101000000_init_schema.sql`
2. `20240101000001_rls_policies.sql`
3. `20260507000000_security_hardening.sql`
4. `20260527000000_rebuild_medtrace_erd_schema.sql`

`20260527000000_rebuild_medtrace_erd_schema.sql` is intentionally destructive
for application tables in `public`. It drops the older app schema
(`treatments`, `medications`, `doctor_patients`, legacy profile/patient shapes,
and related policies/functions) and recreates the schema from the current ERD.
It does not drop or modify Supabase Auth tables such as `auth.users`.

Development seed data is kept in `supabase/seed.sql`. Before running it, create
or reuse two Supabase Auth users and edit the doctor/patient emails at the top
of the seed file if needed. The seed links app rows to existing `auth.users`
records and fills every current ERD table with a small doctor/patient scenario.

Do not copy legacy migrations back into this directory without reconciling the
schema with the Flutter app and RLS policies first. Supabase CLI applies every
SQL file in this folder in sorted order, so conflicting schema histories can
break a fresh database before development starts.

The old `001_init.sql` and `002_registration.sql` files are archived under
`supabase/legacy_migrations/` because they use a different patient model
(`patients.profile_id`, an `admin` role, PostGIS location columns, and different
medication-log relationships) than the current application code.
