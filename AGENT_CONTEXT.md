# MedTrace Mobile - Agent Context

Panduan kerja untuk AI agent atau developer yang mengerjakan repo MedTrace.

Read order:
1. `PROJECT_CONTEXT.md`
2. `UI_CONTEXT.md`
3. `TODO.md`
4. Relevant source files

Last reviewed: 2026-05-24

## 1. Mission

Bangun MedTrace sebagai aplikasi kesehatan TB yang aman, jelas, dan layak dirilis ke Google Play Store. Prioritasnya bukan hanya fitur terlihat selesai, tetapi fitur benar-benar memakai data Supabase, aman secara role/RLS, dan dapat diverifikasi lewat analyze/build/test.

## 2. Non-Negotiable Rules

- Jangan gunakan mock/dummy/hardcoded runtime data untuk pasien, dokter, alert, adherence, lokasi, reminder, atau grafik.
- Jika data belum tersedia, tampilkan loading, empty state, error state, retry, atau CTA untuk membuat data.
- Jangan call Supabase langsung dari widget/page.
- Gunakan alur Page -> Provider/Notifier -> Repository -> DataSource -> Supabase.
- Jangan commit service role key, API key pribadi, atau credential produksi.
- Jangan menganggap fitur selesai sampai ada verifikasi minimal: analyze/build atau alasan eksplisit kenapa belum bisa.
- Jangan mengubah schema tanpa memperbarui migration, model, repository, RLS, dan TODO.

## 3. Current Technical Reality

Repo sudah memiliki banyak struktur inti:
- Supabase config and initialization.
- Auth provider.
- Domain entities and models.
- Repositories and remote datasource.
- Patient and doctor pages.
- Feature providers for treatment, logs, reminders, chatbot, doctor patients, alerts, and locations.
- Services for notification, cache, connectivity, offline queue, PDF.
- UI reference assets under `assets/ui`.

Known risks:
- `flutter analyze` previously hung for more than 5 minutes because Dart analyzer processes were stuck. Current baseline completes in seconds.
- `flutter build apk --debug` previously timed out; current baseline builds successfully after Android/Gradle/dependency fixes.
- Supabase REST endpoint responds HTTP 200 for `profiles`, but auth/RLS/RPC/realtime still need real account testing.
- Migration folder contains conflicting old migrations (`001_init.sql`, `002_registration.sql`) and newer timestamped migrations.
- Chatbot has Groq primary and OpenAI fallback in code; documentation must not claim only OpenAI.
- Some docs were over-optimistic and marked features complete before verification.
- Android currently needs compatibility flags `android.builtInKotlin=false` and `android.newDsl=false` until all plugins support AGP 9 built-in Kotlin cleanly.

## 4. Working With Data

Data source policy:
- Production UI reads from Supabase via repositories.
- Offline data must be cached from real Supabase responses or queued user actions.
- Tests may use controlled test doubles only for behavior isolation; feature acceptance and RLS/security checks must use real Supabase development accounts.
- Empty states are acceptable and preferred over fake content.

When implementing a screen:
1. Identify the authenticated user and role.
2. Find the provider/repository that owns the data.
3. Add repository methods if the data is missing.
4. Add RLS-compatible query patterns.
5. Render loading, error, empty, and data states.
6. Add refresh/retry behavior where useful.

## 5. Supabase Guidelines

Use `AppConfig` for URL and anon key during development. For release, move environment values to `--dart-define` or CI/CD secrets.

Required Supabase checks:
- Anon key can reach REST API.
- Patient can read/update only own data.
- Doctor can read only assigned patients.
- Patient cannot query other patients.
- Patient cannot access doctor pages or doctor data.
- Doctor code validation works.
- `complete_patient_registration` RPC works with active code.
- Realtime streams emit expected rows under RLS.
- Adherence update and alert creation do not violate RLS.

Migration rule:
- Use one canonical schema path.
- Do not apply both old `001/002` migrations and timestamped migrations to the same production database until conflicts are resolved.
- Any table rename or relationship change must be reflected in models and queries.

## 6. Implementation Patterns

Provider pattern:

```dart
final myRepositoryProvider = Provider<MyRepository>((ref) {
  final dataSource = ref.watch(remoteDataSourceProvider);
  return MyRepository(remoteDataSource: dataSource);
});
```

State pattern:

```dart
class MyState {
  final bool isLoading;
  final List<MyModel> items;
  final String? error;

  const MyState({
    this.isLoading = false,
    this.items = const [],
    this.error,
  });

  MyState copyWith({
    bool? isLoading,
    List<MyModel>? items,
    String? error,
  }) {
    return MyState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      error: error,
    );
  }
}
```

Page rule:
- Use `ref.watch` in build for state.
- Use `ref.read` in callbacks.
- Do not parse database JSON in UI.
- Do not compute clinical truth in UI if repository/database should own it.

## 7. UI Rules

Use `UI_CONTEXT.md` and mockups in `assets/ui` as visual reference.

Key assets:
- `assets/ui/begin`: splash, login, register.
- `assets/ui/doctor`: dashboard, patient list, patient detail, update status, reminder monitoring, alert center, map.
- `assets/ui/patient`: registration steps, home, progress, adherence, reminder, chatbot, profile, success.
- `assets/ui/app/App_Logo.svg`: logo reference.

Implementation requirements:
- Preserve MedTrace visual identity.
- Keep doctor and patient information architecture distinct.
- Add consistent bottom navigation.
- Use real values from Supabase.
- Use responsive constraints; avoid text overflow.
- Add accessibility labels for critical actions.
- Add medical disclaimer wherever AI health guidance appears.

## 8. Store Readiness Rules

Before Play Store release candidate:
- No analyzer errors.
- Release AAB builds.
- App icon and splash are generated.
- Android package id is final, not `com.example`.
- Versioning is intentional.
- Privacy policy exists.
- Account deletion flow is available or clearly documented.
- Permission rationale exists for location and notifications.
- No debug banner, debug logs, or test credentials exposed.
- Crash reporting/performance monitoring decision is made.
- Screenshots come from implemented app.

## 9. Git Workflow

Use small, focused commits:

```text
docs: align MedTrace context with Play Store readiness
fix: remove runtime sample data from doctor dashboard
feat: wire patient profile to Supabase
test: add auth provider state tests
```

Before commit:
- Review `git status --short`.
- Stage specific files only.
- Do not revert user changes unless explicitly requested.

## 10. Verification Commands

```bash
flutter pub get
flutter analyze --no-pub
flutter test
flutter build apk --debug
flutter build appbundle --release
```

Windows analyzer recovery:

```powershell
Get-Process dart,dartvm -ErrorAction SilentlyContinue | Stop-Process
Remove-Item -Recurse -Force .dart_tool
flutter pub get
flutter analyze --no-pub
```

## 11. Current Priorities

Follow `TODO.md`. Highest priorities:
1. Clean Supabase migration history.
2. Verify real doctor/patient auth and RLS.
3. Remove or replace any runtime placeholder/fallback data found during feature work.
4. Align UI implementation with `assets/ui`.
5. Reduce analyzer lint/warning backlog.
6. Finish Play Store readiness checklist.
