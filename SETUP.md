# MedTrace - Setup Guide

This guide is intentionally conservative. MedTrace must be developed against real Supabase data and must not use fake clinical runtime data.

## Prerequisites

- Flutter SDK 3.19 or newer.
- Dart SDK included with Flutter.
- Android Studio or Android command-line tools.
- A Supabase project for development.
- Git.

## Install Dependencies

```bash
flutter pub get
```

If Flutter commands hang on Windows, see `TODO.md` Phase 0. The known recovery path is:

```powershell
Get-Process dart,dartvm -ErrorAction SilentlyContinue | Stop-Process
Remove-Item -Recurse -Force .dart_tool
flutter pub get
flutter analyze --no-pub
```

If pub access is blocked by the sandbox or network policy, rerun with network access enabled.

## Supabase Configuration

Current development values live in:

```text
lib/core/config/app_config.dart
```

Before Play Store release, move environment-specific values to `--dart-define` or CI/CD secrets. Never commit service role keys.

## Database Setup

Do not blindly apply all migration files to production. The migration folder currently contains conflicting schema histories:

- `supabase/migrations/20240101000000_init_schema.sql`
- `supabase/migrations/20240101000001_rls_policies.sql`
- `supabase/migrations/20260507000000_security_hardening.sql`
- `supabase/migrations/001_init.sql`
- `supabase/migrations/002_registration.sql`

The old `001_init.sql` and `002_registration.sql` use a different patient schema than the current application code. Resolve Phase 1.2 in `TODO.md` before treating the database as production-ready.

## Required Real Test Accounts

Create real development accounts in Supabase:

- One doctor user with `profiles.role = 'doctor'`.
- One patient user registered through a valid `doctor_codes.code`.

Do not document or ship shared fake credentials. Store any local-only credentials outside the repository.

Run Phase 1 real database tests with environment variables:

```powershell
$env:MEDTRACE_DOCTOR_EMAIL='real-doctor-dev@example.com'
$env:MEDTRACE_DOCTOR_PASSWORD='real doctor password'
$env:MEDTRACE_PATIENT_EMAIL='real-patient-dev@example.com'
$env:MEDTRACE_PATIENT_PASSWORD='real patient password'
flutter test test/supabase_phase1_integration_test.dart
```

Without those variables, only the anonymous Supabase connectivity check runs.

## Verification Commands

```bash
flutter analyze --no-pub
flutter test
flutter build apk --debug
```

Current Phase 0 baseline:
- Supabase REST endpoint responds with the development publishable anon key.
- `flutter test` passes.
- `flutter build apk --debug` succeeds.
- `flutter analyze --no-pub` completes quickly, with lint/warning cleanup still pending.

Current known status is tracked in `TODO.md`.

## Android Notes

Permissions declared in `android/app/src/main/AndroidManifest.xml` include:

- Internet.
- Coarse/fine location.
- Notifications.
- Exact alarms.

Play Store submission requires clear in-app rationale and Play Console disclosure for location and notifications.

## Troubleshooting

### Flutter or Dart hangs

- Stop stale Dart/Dart VM processes.
- Remove `.dart_tool`.
- Check stale lock files under the Flutter SDK cache.
- Disable analytics for command sessions if telemetry file access fails:

```powershell
$env:DART_SUPPRESS_ANALYTICS='true'
$env:FLUTTER_SUPPRESS_ANALYTICS='true'
```

### Unable to connect to Supabase

- Check `AppConfig.supabaseUrl`.
- Check `AppConfig.supabaseAnonKey`.
- Confirm the Supabase project is not paused.
- Verify RLS policies for the current role.

### Android build timeout

- Check Gradle/Java processes left from previous builds.
- Stop Gradle daemons with `android\gradlew.bat --stop` when a previous build was interrupted.
- Ensure network access for Gradle dependency resolution.
- Re-run with more time after dependencies are cached.
- Current Android baseline requires the compatibility flags documented in `android/gradle.properties`.

## Next Steps

Follow [TODO.md](TODO.md), starting with Phase 1 after the Phase 0 baseline has been re-verified.
