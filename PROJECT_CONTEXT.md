# MedTrace Mobile - Project Context

## 1. Overview

MedTrace adalah aplikasi mobile Flutter untuk monitoring dan manajemen pengobatan Tuberkulosis (TB). Aplikasi ini menghubungkan pasien TB dengan dokter melalui sistem tracking adherence obat, lokasi geografis, chatbot AI, dan alert system.

- Platform: Android (minSdk 21) + iOS (11.0+)
- Tech Stack: Flutter 3.19+ / Dart 3.3+ / Supabase / Riverpod / GoRouter
- Target: Production-ready, store submission

---

## 2. Architecture

Clean Architecture dengan strict layer separation:

```
Presentation Layer (Pages, Providers, Widgets, Router)
        |
        v
State Management Layer (Riverpod StateNotifiers)
        |
        v
Domain Layer (Entities, Repository Interfaces)
        |
        v
Data Layer (Repositories, DataSources, Models)
        |
        v
External (Supabase PostgreSQL + Auth + Storage)
```

### Layer Responsibilities

PRESENTATION (lib/presentation/):
- Display UI, handle user interactions, trigger business logic via providers
- Pages: full screen widgets (ConsumerWidget)
- Providers: Riverpod state management
- Router: GoRouter navigation with role-based redirect
- TIDAK BOLEH contain business logic atau call API langsung

STATE MANAGEMENT (lib/presentation/providers/):
- Manage application state via StateNotifier
- Call repositories for data
- Handle async operations
- Notify listeners of changes

DOMAIN (lib/domain/):
- Pure business objects (entities)
- Repository interfaces (abstract classes)
- Tidak ada dependency ke framework

DATA (lib/data/):
- JSON-serializable models (extend entities)
- Remote data source (Supabase API calls)
- Repository implementations
- Error handling dan data transformation

---

## 3. Directory Structure

```
lib/
  core/
    config/          app_config.dart (Supabase URL/key, OpenAI key, timeouts, feature flags)
    constants/       app_constants.dart (roles, status, severity, map, notification constants)
    error/           exceptions.dart (12 custom exception types), failures.dart
    extensions/      extensions.dart (40+ utility extensions on core Dart types)
  data/
    datasources/
      remote/        supabase_remote_datasource.dart (50+ methods)
    models/          models.dart (13 data models with fromJson/toJson)
    repositories/    repositories.dart (10 repository implementations)
  domain/
    entities/        entities.dart (11 entities: User, DoctorCode, DoctorPatient, Treatment, Medication, MedicationLog, Reminder, PatientLocation, ChatbotConversation, ChatbotMessage, Alert, Notification)
  presentation/
    pages/
      auth/          login_page.dart, patient_registration_page.dart
      patient/       patient_dashboard_page.dart, treatment_details_page.dart, medication_schedule_page.dart, chatbot_page.dart, tb_map_page.dart, reminders_page.dart
      doctor/        doctor_dashboard_page.dart, patient_management_page.dart, alerts_page.dart
    providers/
      app_providers.dart       (auth, theme, router, repository/datasource DI)
      feature_providers.dart   (5 StateNotifiers: Treatment, MedicationLogs, Reminders, Locations, Chatbot)
    router/          app_router.dart (GoRouter with role-based redirect)
  services/
    supabase_service.dart
    notification_service.dart
  shared/
    theme/           app_theme.dart (Material 3, patient=teal, doctor=dark teal)
  main.dart

supabase/
  migrations/
    20240101000000_init_schema.sql      (12 tables, indexes, triggers)
    20240101000001_rls_policies.sql     (40+ RLS policies)
    20260507000000_security_hardening.sql

test/
assets/
  images/
  icons/
  animations/
```

---

## 4. State Management

### Provider Types

Simple Provider (read-only DI):
```dart
final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);
```

StateNotifierProvider (mutable state):
```dart
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
```

Family Provider (parameterized by userId):
```dart
final patientTreatmentProvider = StateNotifierProvider.family<TreatmentNotifier, TreatmentState, String>(
  (ref, patientId) => TreatmentNotifier(patientId: patientId),
);
```

### State Pattern

Setiap feature state memiliki:
- `data` (nullable atau list)
- `isLoading` (bool)
- `error` (String?)
- `copyWith()` method

### Key Rules

- `ref.watch()` di build method untuk reactive rebuild
- `ref.read()` di callbacks/event handlers untuk one-time access
- `ref.watch(provider.select((s) => s.field))` untuk granular rebuild
- `ref.refresh(provider)` untuk force reload
- Family provider: setiap unique parameter = instance baru, gunakan String ID

---

## 5. Database Schema

12 tabel PostgreSQL dengan RLS:

| Tabel | Deskripsi | Key Columns |
|-------|-----------|-------------|
| profiles | User data | id, email, role, full_name, is_active |
| patients | Patient medical metadata | id, doctor_id, emergency_contact, latitude, longitude |
| doctor_codes | Registration codes | doctor_id, code (6-char), expires_at, max_uses, current_uses |
| doctor_patients | Doctor-patient relationship | doctor_id, patient_id, linked_at |
| treatments | TB treatment plans | patient_id, doctor_id, phase, status, adherence_percentage |
| medications | Prescribed medications | treatment_id, name, dosage, unit, frequency |
| medication_logs | Daily adherence logs | medication_id, patient_id, status (taken/missed/skipped), taken_at |
| reminders | Scheduled reminders | patient_id, title, reminder_type, scheduled_date, is_sent |
| patient_locations | GPS tracking history | patient_id, latitude, longitude, accuracy, recorded_at |
| chatbot_conversations | AI chat sessions | patient_id, title |
| chatbot_messages | Individual messages | conversation_id, role (user/assistant), message |
| alerts | Doctor alerts | doctor_id, patient_id, alert_type, severity, is_read, action_taken |

### Database Conventions

- Tabel: snake_case plural
- Kolom: snake_case
- Primary key: UUID gen_random_uuid()
- Timestamps: created_at + updated_at (auto-trigger)
- Foreign keys: <entity>_id referencing profiles(id) atau parent table
- Enums: TEXT with CHECK constraint
- Spatial: cube + earthdistance extensions

### RLS Policies

- Patient: hanya bisa read/write data sendiri
- Doctor: hanya bisa access data pasien yang terhubung
- Semua unauthorized access di-block

---

## 6. Routing

GoRouter dengan role-based redirect:

| Route | Page | Role |
|-------|------|------|
| /login | LoginPage | public |
| /patient-register | PatientRegistrationPage | public |
| /patient-dashboard | PatientDashboardPage | patient |
| /patient/treatment | TreatmentDetailsPage | patient |
| /patient/medications | MedicationSchedulePage | patient |
| /patient/chatbot | ChatbotPage | patient |
| /patient/map | TbMapPage | patient |
| /patient/reminders | RemindersPage | patient |
| /doctor-dashboard | DoctorDashboardPage | doctor |
| /doctor/patients | PatientManagementPage | doctor |
| /doctor/alerts | AlertsPage | doctor |

Redirect logic:
- Unauthenticated -> /login
- Authenticated doctor accessing /patient/* -> /doctor-dashboard
- Authenticated patient accessing /doctor/* -> /patient-dashboard

---

## 7. Features

### Patient Features

AUTHENTICATION:
- Login email/password via Supabase Auth
- Register dengan doctor code (3-step wizard)
- Password reset via email
- Session persistence

DASHBOARD:
- Personalized greeting
- Quick stats: adherence %, pending medications
- Feature grid navigation (6 items)

TREATMENT DETAILS:
- Phase indicator (intensive 0-2 bulan / continuation 3-6 bulan)
- Progress bar, status, doctor assigned, notes
- Adherence visualization

MEDICATION SCHEDULE:
- Date navigator (prev/current/next day)
- Color-coded adherence (green >=80%, yellow 60-80%, red <60%)
- Mark taken/missed per medication
- Auto-logging ke database

TB MAP:
- OpenStreetMap via flutter_map (no API key)
- Current location marker (blue)
- Location history markers (orange)
- GPS accuracy indicator
- Location recording ke database

AI CHATBOT:
- Conversation interface with message bubbles
- Help topics (empty state)
- Chat history saved to database
- System prompt: WHO-based TB health educator
- OpenAI API integration (pending)

REMINDERS:
- Upcoming dan history sections
- Create reminder dialog (title, type, date, time)
- Types: medication, appointment, checkup, custom
- Local notification scheduling (pending)

### Doctor Features

DASHBOARD:
- Patient count, open alerts, average adherence
- Feature grid navigation (4 items)

PATIENT MANAGEMENT:
- Search bar (realtime filter by name/email)
- Filter chips: all, good (>=80%), warning (60-80%), critical (<60%)
- Patient cards with adherence display
- Generate doctor code dialog (6-char, 30-day validity)

ALERTS:
- Severity filtering: all, critical, high, medium, low
- Alert cards with severity icon, timestamp, unread indicator
- Alert detail bottom sheet
- Mark resolved action
- Alert types: missed_medication, adherence_drop, critical_delay, appointment_missed, side_effects_reported, location_risk

---

## 8. Design System

### Patient Theme
- Primary: #0F766E (Teal)
- Secondary: #14B8A6
- Background: #F0FDFA
- Accent: #EAB308
- UI: simple, guided, clear actions, minimal data overload

### Doctor Theme
- Primary: #134E4A (Dark Teal)
- Secondary: #0F766E
- Background: #ECFEFF
- Alert: red (critical), yellow (warning), green (stable)
- UI: data-rich dashboards, analytical cards, dense structured info

### Material 3
- Rounded cards, soft shadows, clean spacing
- High readability, modern medical UI
- flutter_screenutil untuk responsive sizing

---

## 9. Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| supabase_flutter | ^1.10.7 | Backend (auth, DB, storage, realtime) |
| flutter_riverpod | ^2.4.1 | State management |
| go_router | ^13.0.0 | Navigation |
| flutter_map | ^6.1.0 | OpenStreetMap |
| geolocator | ^10.1.0 | GPS location |
| flutter_local_notifications | ^16.3.0 | Local notifications |
| hive / hive_flutter | ^2.2.3 | Local storage/cache |
| dio | ^5.3.1 | HTTP client |
| flutter_screenutil | ^5.9.0 | Responsive UI |
| equatable | ^2.0.5 | Value equality |
| shared_preferences | ^2.2.2 | Simple key-value storage |
| cached_network_image | ^3.3.0 | Image caching |
| image_picker | ^1.0.4 | Camera/gallery |
| pdf / printing | ^3.10.4 | PDF generation |
| flutter_secure_storage | ^9.0.0 | Secure credential storage |
| connectivity_plus | ^5.0.0 | Network state detection |
| shimmer | ^3.0.0 | Loading skeleton |
| lottie | ^2.6.0 | Animations |
| intl | ^0.19.0 | Date/number formatting |
| logger | ^2.0.0 | Structured logging |

Dev dependencies: flutter_lints, riverpod_generator, build_runner, hive_generator, flutter_launcher_icons, flutter_native_splash

---

## 10. Coding Standards

### Naming

- Files: snake_case (medication_schedule_page.dart)
- Classes: PascalCase (MedicationSchedulePage)
- Variables/methods: camelCase (medicationList, loadData)
- Constants: camelCase atau UPPER_CASE (kMinimumAdherence, MEDICATION_TABLE)
- Private: _prefix (_privateMethod)
- Booleans: is/has prefix (isLoading, hasError)

### Entity Pattern

```dart
class MyEntity extends Equatable {
  final String id;
  const MyEntity({required this.id});
  MyEntity copyWith({String? id}) => MyEntity(id: id ?? this.id);
  @override
  List<Object?> get props => [id];
}
```

### Model Pattern (extends Entity)

```dart
class MyModel extends MyEntity {
  const MyModel({required super.id});
  factory MyModel.fromJson(Map<String, dynamic> json) => MyModel(id: json['id']);
  Map<String, dynamic> toJson() => {'id': id};
}
```

### StateNotifier Pattern

```dart
class MyNotifier extends StateNotifier<MyState> {
  final MyRepository _repository;
  MyNotifier(this._repository) : super(const MyState());

  Future<void> loadData(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.getData(userId);
      state = state.copyWith(data: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
```

### Page Pattern

```dart
class MyPage extends ConsumerWidget {
  const MyPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authProvider).user!.id;
    final state = ref.watch(myProvider(userId));
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.error != null) return Center(child: Text(state.error!));
    return Scaffold(...);
  }
}
```

### Rules

- Gunakan const constructors di mana pun memungkinkan
- Immutable data structures, copyWith untuk update
- Handle semua error cases (try-catch di async operations)
- Watch hanya providers yang dibutuhkan (hindari unnecessary rebuild)
- Jangan mix business logic dengan UI
- Jangan call API langsung dari widget
- Jangan gunakan null! kecuali benar-benar yakin
- Jangan tinggalkan TODO comments di production code

---

## 11. Supabase Access Pattern

```dart
// READ
final response = await supabaseClient
    .from('table_name')
    .select()
    .eq('patient_id', patientId)
    .order('created_at', ascending: false);

// CREATE
await supabaseClient.from('table_name').insert({'column': value});

// UPDATE
await supabaseClient.from('table_name').update({'column': newValue}).eq('id', id);

// DELETE
await supabaseClient.from('table_name').delete().eq('id', id);
```

---

## 12. Testing

```bash
flutter analyze          # Static analysis
flutter test             # Unit/widget tests
flutter test --coverage  # With coverage
flutter build apk --debug   # Debug build verification
flutter build apk --release # Release build
```

### Test Pattern

```dart
void main() {
  group('MyNotifier', () {
    test('loads data successfully', () async {
      final mockRepo = MockMyRepository();
      when(mockRepo.getData()).thenAnswer((_) async => [MyData(id: '1')]);
      final container = ProviderContainer(
        overrides: [myRepositoryProvider.overrideWithValue(mockRepo)],
      );
      // assertions
    });
  });
}
```

---

## 13. Performance

- Lazy loading: FutureProvider.autoDispose
- Granular rebuild: ref.watch(provider.select((s) => s.field))
- Pagination: offset/limit di repository queries
- Caching: Hive untuk offline data
- Efficient queries: indexed columns, spatial indexes
- Minimal rebuilds: watch specific providers, not entire state

---

## 14. Common Issues

| Issue | Solution |
|-------|----------|
| GoRouter redirect loop | Cek path condition sebelum redirect |
| Supabase query returns empty | Cek RLS policy mengizinkan akses |
| Family provider creates new instance | Gunakan String ID, bukan object |
| DateTime dari Supabase UTC | Convert ke local saat display |
| Hot reload not working | Gunakan hot restart (R) |
| Gradle issues | flutter clean && flutter pub get |
| Pod issues (iOS) | cd ios && rm -rf Pods Podfile.lock && cd .. && flutter pub get |

---

## 15. Project Statistics

- Lines of code: 12,000+
- Source files: 31
- Completion: ~70% toward MVP
- Database tables: 12
- RLS policies: 40+
- Entities: 11
- Repositories: 10
- Providers: 15+
- Pages: 11
