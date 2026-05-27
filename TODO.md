# MedTrace Mobile - TODO and Release Roadmap

This TODO is the operational source of truth. A task is only `Done` when it is implemented, verified, and not dependent on mock runtime data.

Last reviewed: 2026-05-24

## Current Assessment

| Area | Status | Notes |
|---|---|---|
| Flutter project structure | In progress | App has core folders, pages, providers, services |
| UI references | Ready for implementation | 20 PNG mockups plus logo under `assets/ui` scanned and documented |
| Supabase endpoint | Development-ready baseline | REST `profiles` check returned HTTP 200 `[]` with publishable anon key on 2026-05-24 |
| Supabase schema | Canonicalized locally | Active migrations are timestamped only; legacy `001/002` archived outside active Supabase folder |
| Runtime data policy | Enforced for current scan | No hardcoded clinical runtime data found in `lib` or `test`; keep scanning per feature |
| Analyzer/build | Baseline recovered | Analyzer finishes; debug APK builds successfully |
| Testing | Baseline recovered | `flutter test` passes after Supabase v2 timer handling |
| Play Store readiness | Not ready | Signing, privacy, permissions, account deletion, release build still required |

Estimated readiness:
- MVP feature code: cannot be honestly scored until analyzer/build and real Supabase flows pass.
- Play Store: not ready.

## Definition of Done

For every feature:
- [ ] Uses real Supabase data or real authenticated/local state.
- [ ] Has loading state.
- [ ] Has empty state.
- [ ] Has error state and retry where appropriate.
- [ ] Handles offline or poor network where relevant.
- [ ] Does not expose data across roles.
- [ ] Has no hardcoded patient/doctor clinical data.
- [ ] Is reachable through role-safe navigation.
- [ ] Passes analyzer/build verification or has a documented blocker.

## Phase 0 - Tooling and Truth Baseline

### 0.0 Diagnosis Snapshot - 2026-05-24

Main issues found:

- Flutter/Dart commands were hanging because stale Dart processes and Flutter SDK cache lock files were left behind.
- `dart pub get` initially failed under sandboxed network access and Dart telemetry could not write to `%APPDATA%`.
- Running commands with `DART_SUPPRESS_ANALYTICS=true` and `FLUTTER_SUPPRESS_ANALYTICS=true` plus approved network/user-cache access recovered pub/test/analyze.
- Analyzer now completes quickly, but reports lint/info items. No analyzer error-level compile issue is currently reported.
- Debug APK build originally timed out after 5 minutes and left Gradle/Java processes running; those were stopped.
- Debug APK build now succeeds and outputs `build/app/outputs/flutter-apk/app-debug.apk`.
- Android package mismatch was found and fixed: `applicationId/namespace = com.medtrace.app`, and `MainActivity.kt` has been moved to `android/app/src/main/kotlin/com/medtrace/app/MainActivity.kt`.
- Gradle/Android was aligned with the local Flutter SDK baseline:
  - Gradle wrapper `9.1.0`
  - Android Gradle Plugin `9.0.1`
  - Kotlin Gradle Plugin `2.3.20`
  - Java 17 compatibility
- Temporary Android compatibility flags remain required because several plugins still apply Kotlin Gradle Plugin under AGP 9:
  - `android.builtInKotlin=false`
  - `android.newDsl=false`
- Kotlin incremental compilation is disabled because Windows cross-drive cache paths caused Kotlin cache failures between `C:\Users\LENOVO\AppData\Local\Pub\Cache` and `D:\Git\Flutter\medtrace_mobile`.
- Core library desugaring is enabled for `flutter_local_notifications`.
- All Android subprojects are forced to compile SDK 36 to satisfy AndroidX AAR metadata.
- Dependency upgrades were required to compile with current Android tooling:
  - `supabase_flutter 2.12.4`
  - `flutter_local_notifications 21.0.0`
  - `timezone 0.11.0`
  - `connectivity_plus 7.1.1`
  - `package_info_plus 10.1.0`
  - `device_info_plus 13.1.0`
  - `shared_preferences 2.5.5`
  - `flutter_secure_storage 10.3.0`
  - `google_maps_flutter 2.17.0`
  - `sign_in_with_apple 8.0.0`
- Migration conflict is confirmed: old `001_init.sql`/`002_registration.sql` use `patients.profile_id`, `admin` role, PostGIS, and different medication log relations, while current app code expects the timestamped schema.
- Documentation conflict was confirmed: old docs referenced missing files and fake/test credentials. `README.md`, `README_DOCUMENTATION.md`, and `SETUP.md` were rewritten to align with current context.
- Runtime hardcoded clinical sample names were not found in `lib` or `test` by search. Chatbot fallback remains generic educational text and is tracked for safety review in Phase 5.3.
- Supabase REST baseline check on 2026-05-24 returned HTTP 200 and body `[]` for `/rest/v1/profiles?select=id,role&limit=1`, confirming the endpoint and publishable anon key respond.

Current verified commands on 2026-05-24:

```powershell
flutter pub get
flutter analyze --no-pub
flutter test
flutter build apk --debug
```

Results:
- `flutter test`: pass.
- `flutter build apk --debug`: pass.
- `flutter analyze --no-pub`: completes quickly, with lint/info/warning backlog only.

### 0.1 Recover analyzer

- [x] Stop stale Dart/Dart VM analyzer processes on Windows.
- [x] Delete `.dart_tool` if analyzer remains stuck.
- [x] Run `flutter pub get`.
- [x] Run `flutter analyze --no-pub`.
- [x] Document actual analyzer errors in this TODO.
- [x] Fix analyzer errors before marking any feature production-ready.
- [ ] Reduce analyzer lint/info backlog to zero or agree on a stricter staged lint policy.
- [x] Complete `flutter build apk --debug` successfully.

Analyzer result on 2026-05-24:
- `flutter analyze --no-pub` completes in seconds.
- 0 analyzer errors found.
- Lint/info/warning items remain, mostly `deprecated_member_use`, `prefer_const_constructors`, `use_super_parameters`, `curly_braces_in_flow_control_structures`, and PDF/theme deprecations.

Suggested recovery:

```powershell
Get-Process dart,dartvm -ErrorAction SilentlyContinue | Stop-Process
Remove-Item -Recurse -Force .dart_tool
flutter pub get
flutter analyze --no-pub
```

### 0.2 Repository audit

- [x] Run `git status --short` and identify user changes.
- [ ] Confirm all important docs are tracked in git before commit (`UI_CONTEXT.md` is currently untracked).
- [x] Confirm `assets/ui` should remain reference-only or be included in app assets.
- [x] Remove stale documentation references to missing files such as `FEATURES.md`, `ARCHITECTURE.md`, `PROJECT_STATUS.md` if they are not present.
- [x] Clean mojibake/encoding artifacts in docs where needed.
- [x] Replace fake Supabase test values in widget test with `AppConfig` development values.
- [x] Fix Android package mismatch for `MainActivity`.
- [x] Move `MainActivity.kt` file path from `com/example/medtrace` to `com/medtrace/app`.
- [x] Verify APK build after the Android package move.
- [x] Scan `lib` and `test` for obvious runtime mock/dummy clinical data.
- [x] Remove placeholder default Groq key from runtime config.

Current working tree notes:
- `PROJECT_CONTEXT.md`, `AGENT_CONTEXT.md`, `UI_CONTEXT.md`, `TODO.md`, `README.md`, `README_DOCUMENTATION.md`, and `SETUP.md` have been intentionally updated.
- `assets/ui/` is currently untracked and should be added if these mockups are part of the project source of truth.
- `UI_CONTEXT.md` is currently untracked and should be added with the docs.
- `macos/Flutter/GeneratedPluginRegistrant.swift` and `windows/flutter/generated_plugins.cmake` changed because `flutter pub get` regenerated plugin registrants after dependency upgrades.
- `build/app/outputs/flutter-apk/app-debug.apk` exists as a generated build artifact and should not be committed.

### 0.3 Phase 0 Completion Criteria

- [x] Tooling commands no longer hang.
- [x] Supabase endpoint and anon key respond from the development machine.
- [x] Debug APK build succeeds.
- [x] Baseline widget test passes.
- [x] Android package id and `MainActivity` package path are aligned.
- [x] No obvious hardcoded clinical runtime data found by source scan.
- [x] Known blockers moved to later phases instead of hidden in Phase 0.

Phase 0 status:
- Done for development baseline.
- Not a release approval. Release readiness still depends on Phase 1 through Phase 8.

## Phase 1 - Supabase and Data Foundation

### 1.1 Supabase connection

- [x] Confirm Supabase REST endpoint responds with anon key.
- [x] Add real-database integration test for anon Supabase profile endpoint.
- [ ] Provide real dev doctor credentials via `MEDTRACE_DOCTOR_EMAIL` and `MEDTRACE_DOCTOR_PASSWORD`, then run Phase 1 integration tests.
- [ ] Provide real dev patient credentials via `MEDTRACE_PATIENT_EMAIL` and `MEDTRACE_PATIENT_PASSWORD`, then run Phase 1 integration tests.
- [ ] Confirm Supabase Auth login works with a real doctor account.
- [ ] Confirm Supabase Auth login works with a real patient account.
- [ ] Confirm patient registration works with a real active doctor code.
- [x] Supabase email confirmation flow shows verification guidance after sign-up without an active session.
- [x] Pending patient registration metadata is stored securely and completed after verified login.
- [x] Confirm `complete_patient_registration` RPC exists in the actual Supabase project.
- [ ] Confirm Realtime is enabled for required tables.
- [ ] Confirm storage buckets if avatars/documents will be used.

### 1.2 Migration cleanup

Release blocker.

- [x] Decide canonical migration set.
- [x] Move legacy `001_init.sql` and `002_registration.sql` out of active `supabase/migrations`.
- [x] Add migration README documenting canonical order.
- [x] Add migration audit test to prevent legacy migration files from returning to the active folder.
- [x] Resolve local migration folder conflicts between `001_init.sql`/`002_registration.sql` and timestamped migrations.
- [x] Ensure active migration files and current code agree on patient foreign keys:
  - current code expects `treatments.patient_id` as profile UUID,
  - active migrations use profile UUIDs for `patients.id`, `doctor_patients.patient_id`, `treatments.patient_id`, medication logs, reminders, locations, chatbot records, and alerts,
  - old migrations using a separate `patients.id/profile_id` shape are archived under `supabase/legacy_migrations/`.
- [x] Ensure active migrations only define roles `doctor` and `patient` unless admin tooling is intentionally added.
- [ ] Verify the actual Supabase database has no legacy `admin` profile role.
- [ ] Add missing migration for any fields required by mockups:
  - national identity, if legally required,
  - TB category,
  - facility,
  - doctor notes,
  - notification preferences,
  - account deletion request.
- [ ] Apply migrations to a clean dev Supabase project.
- [ ] Export schema or document exact migration order.

Canonical active migration order:
1. `20240101000000_init_schema.sql`
2. `20240101000001_rls_policies.sql`
3. `20260507000000_security_hardening.sql`

Legacy migrations are preserved under `supabase/legacy_migrations/` for reference only.

Run Phase 1 real database checks:

```powershell
$env:MEDTRACE_DOCTOR_EMAIL='real-doctor-dev@example.com'
$env:MEDTRACE_DOCTOR_PASSWORD='real doctor password'
$env:MEDTRACE_PATIENT_EMAIL='real-patient-dev@example.com'
$env:MEDTRACE_PATIENT_PASSWORD='real patient password'
flutter test test/supabase_phase1_integration_test.dart
```

Do not commit these credentials. The test file does not create fake clinical data.

### 1.3 RLS verification

- [x] Add real-database integration test placeholder for patient RLS with no mock clinical data.
- [ ] Patient can read own `profiles` row.
- [ ] Patient can update own allowed profile fields.
- [ ] Patient cannot read another patient profile.
- [ ] Patient can read own treatment, medication, logs, reminders, locations, chatbot records.
- [ ] Patient cannot read doctor-only alert queues except allowed notifications if designed.
- [ ] Doctor can read assigned patients only.
- [ ] Doctor can generate doctor codes.
- [ ] Doctor can update treatment status for assigned patients.
- [ ] Doctor cannot access unassigned patients.
- [ ] Anonymous user can only validate active doctor codes if that behavior is intended.

## Phase 2 - Remove Runtime Mock Data

### 2.1 Code search and replacement

- [x] Search for hardcoded clinical names, patient IDs, counts, adherence percentages, and map markers.
- [x] Replace runtime placeholder data with provider-backed data.
- [x] Keep mock/fake data only inside tests.
- [x] Ensure chatbot fallback is generic education only, not patient-specific fake advice.
- [x] Add empty states for dashboards with no data.
- [x] Add runtime no-mock-data audit test to prevent obvious clinical fixtures from returning.
- [x] Treat missing treatment/adherence data as unknown/empty state instead of fake `0%` critical data.
- [x] Remove hardcoded doctor map center when no patient location data exists.

### 2.2 Documentation alignment

- [x] Update `PROJECT_CONTEXT.md` with no-mock runtime policy.
- [x] Update `AGENT_CONTEXT.md` with agent implementation rules.
- [x] Update `UI_CONTEXT.md` to use mockups as visual reference only.
- [x] Update this TODO with release-oriented tasks.

## Phase 3 - Auth and Role Flows

### 3.1 Login

- [ ] Login with real doctor account.
- [ ] Login with real patient account.
- [x] Display useful error for invalid credentials.
- [x] Persist session across app restart through Supabase `currentUser` auth-state recovery on provider initialization.
- [x] Logout clears auth state and redirects to login.
- [x] Add Phase 3 real Supabase auth-flow tests with credential-gated doctor/patient checks.

### 3.2 Patient registration

- [x] Step 1 identity writes expected data.
- [x] Step 2 medical/location data is persisted or explicitly queued for later completion.
- [x] Step 3 doctor code validates against Supabase.
- [ ] RPC creates profile, patient record, and doctor-patient relationship atomically.
- [ ] Doctor code usage increments safely.
- [x] Expired/overused/invalid code shows clear error.
- [ ] Run full registration against a real active dev doctor code and disposable real dev patient email.

### 3.3 Route protection

- [x] Unauthenticated users cannot access patient or doctor routes.
- [x] Patient cannot access doctor routes.
- [x] Doctor cannot access patient-only routes except assigned patient detail if route is designed that way.
- [x] Unknown routes fall back safely.
- [x] Add redirect policy tests so `/patient-register` is not mistaken for an authenticated patient route.

## Phase 4 - UI Implementation Against Mockups

### 4.1 Begin/Auth

- [x] Splash screen matches `assets/ui/begin/Splash Screen.png`.
- [x] Register/welcome screen matches reference.
- [x] Login screen matches reference and uses real Supabase Auth.
- [ ] App icon and splash assets are generated from final logo.

### 4.2 Patient screens

UI-first pass status:
- Patient mockup implementation is now prioritized before Supabase binding by owner request.
- Patient home, therapy progress, adherence history, medication reminder/dose success, chat conversation, and profile/settings have been rebuilt against `assets/ui/patient` visual references with temporary UI-state content.
- Provider/Supabase binding, loading/empty/error data states, and real clinical values remain tracked under the quality requirements below.

- [x] Registration Step 1 UI.
- [x] Registration Step 2 UI.
- [x] Registration Step 3 UI.
- [x] Registration success routes directly to patient dashboard when Supabase email verification is disabled.
- [x] Registration Step 3 status selector and temporary scheduled-day reminder preference UI.
- [x] Dose success screen.
- [x] Patient home summary.
- [x] Therapy progress.
- [x] Adherence history.
- [x] Medication reminder screen.
- [x] Chat conversation with disclaimer.
- [x] Patient profile/settings.

Quality requirements:
- [ ] All screens bind to real providers.
- [ ] All screens handle loading/empty/error states.
- [ ] Bottom navigation matches reference.
- [ ] Text does not overflow on 360 px width.

### 4.3 Doctor screens

- [ ] Healthcare worker dashboard.
- [ ] Patient management list.
- [ ] Patient detail profile.
- [ ] Update therapy status bottom sheet.
- [ ] Reminder/adherence monitoring.
- [ ] Alert center.
- [ ] TB case distribution map.

Quality requirements:
- [ ] Dashboard KPIs come from real queries.
- [ ] Patient list is assigned-patient only.
- [ ] Alert actions persist to Supabase.
- [ ] Map only shows assigned patients.
- [ ] Status update requires notes and refreshes data.

## Phase 5 - Core Feature Completion

### 5.1 Medication and adherence

- [ ] Create or load medication schedule from Supabase.
- [ ] Mark dose taken/missed/skipped.
- [ ] Prevent duplicate logs for same medication/date/time unless schema allows it.
- [ ] Compute adherence consistently in one place.
- [ ] Sync `treatments.adherence_percentage` or use database view.
- [ ] Generate doctor alert on adherence below threshold.
- [ ] Generate alert on 2+ consecutive missed doses.

### 5.2 Reminders and notifications

- [ ] Reminder CRUD persists to Supabase.
- [ ] Local notification scheduling works on Android 13+ permission flow.
- [ ] Notification tap routes to relevant screen.
- [ ] Cancel/reschedule notification on update/delete.
- [ ] Handle timezone correctly.
- [ ] Add background notification response handling if needed.

### 5.3 Chatbot

- [ ] Confirm selected provider strategy: Groq primary, OpenAI fallback, or OpenAI only.
- [ ] Move API keys to `--dart-define`/secrets.
- [ ] Persist user and assistant messages to Supabase.
- [ ] Show typing state.
- [ ] Handle provider/network/rate-limit errors gracefully.
- [ ] Display medical disclaimer persistently.
- [ ] Add safety prompt in Bahasa Indonesia and English if multilingual support is planned.

### 5.4 Location and map

- [ ] Add clear permission rationale.
- [ ] Record patient location only after consent.
- [ ] Show patient location history to patient.
- [ ] Show assigned patient markers to doctor.
- [ ] Add marker clustering or filtering for performance.
- [ ] Avoid overly precise display if privacy policy does not justify it.

### 5.5 Offline support

- [ ] Cache real Supabase data.
- [ ] Queue dose/reminder/profile actions offline.
- [ ] Sync queue on reconnect.
- [ ] Show offline banner.
- [ ] Resolve conflicts deterministically.

### 5.6 PDF reports

- [ ] Generate treatment summary PDF from real patient/treatment/log data.
- [ ] Generate adherence report.
- [ ] Allow doctor to share/download assigned patient report.
- [ ] Ensure patient privacy in file names and share flows.

## Phase 6 - Quality of Life

- [ ] Pull-to-refresh on dashboard, patient list, alerts, adherence history, reminders.
- [ ] Retry buttons on network errors.
- [ ] Shimmer/skeleton on list-heavy screens.
- [ ] Haptic feedback on important confirmations.
- [ ] Search/filter state is preserved during current session.
- [ ] Form validation messages are clear.
- [ ] Date/time formatting uses local timezone.
- [ ] Accessibility labels for icon buttons.
- [ ] Minimum tap target size 44x44.
- [ ] Tablet layout does not break.
- [ ] Dark mode decision documented.
- [ ] Bahasa Indonesia and English localization decision documented.

## Phase 7 - Testing

### 7.1 Unit tests

- [ ] Entities: equality, copyWith, computed properties.
- [ ] Models: fromJson/toJson including nulls and invalid values.
- [ ] Repositories with controlled test doubles only when they do not introduce fake clinical runtime data.
- [ ] StateNotifiers: loading/success/error transitions.
- [ ] Services: notification scheduling payloads, offline queue behavior.

### 7.2 Widget tests

- [ ] Login validation.
- [ ] Registration wizard validation.
- [ ] Patient home loading/empty/error/data states.
- [ ] Medication mark taken/missed flow.
- [ ] Reminder create/update/delete dialogs.
- [ ] Doctor patient list filters.
- [ ] Alert resolution UI.

### 7.3 Integration tests

- [ ] Use real Supabase dev database/accounts for feature verification; do not rely on mock clinical data for pass/fail.
- [ ] Doctor login -> dashboard -> patients -> detail -> update status.
- [ ] Patient registration with code -> dashboard.
- [ ] Patient medication log -> adherence update -> doctor alert.
- [ ] Reminder create -> notification scheduled.
- [ ] Chatbot send/receive -> messages persisted.
- [ ] RLS negative access checks with real accounts.

## Phase 8 - Play Store Preparation

### 8.1 Android release config

- [ ] Finalize package/application id.
- [ ] Configure app label.
- [ ] Create signing keystore.
- [ ] Configure signing in Gradle.
- [ ] Build signed AAB.
- [ ] Enable obfuscation and split debug info.
- [ ] Review minSdk/targetSdk.
- [ ] Remove debug logs and dev-only UI.

### 8.2 Assets and listing

- [ ] Final app icon.
- [ ] Final splash screen.
- [ ] Feature graphic.
- [ ] Phone screenshots from implemented app.
- [ ] Short description.
- [ ] Full description.
- [ ] App category and tags.

### 8.3 Policy and compliance

- [ ] Privacy policy URL.
- [ ] Terms of service URL.
- [ ] Account deletion flow or request mechanism.
- [ ] Data safety form.
- [ ] Location permission disclosure.
- [ ] Notification permission disclosure.
- [ ] Medical/health disclaimer.
- [ ] AI assistant disclaimer.
- [ ] Contact/support email.

### 8.4 Production operations

- [ ] Separate dev/staging/prod Supabase configuration.
- [ ] Database backup strategy.
- [ ] Error/crash reporting decision.
- [ ] Basic analytics decision.
- [ ] Logging policy.
- [ ] Release checklist documented.

## Phase 9 - Post-MVP

- [ ] Push notifications through FCM.
- [ ] WhatsApp contact integration for doctor outreach.
- [ ] Treatment document upload.
- [ ] Lab result tracking.
- [ ] AI adherence insights.
- [ ] Risk prediction.
- [ ] CSV export.
- [ ] Multi-language support.
- [ ] Dark mode.
- [ ] Telemedicine/video call.
- [ ] Admin web console for doctor account creation.
