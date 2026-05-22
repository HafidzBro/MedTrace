# MedTrace Mobile - Agent Context

Panduan operasional untuk AI agent yang bekerja pada project ini. Baca PROJECT_CONTEXT.md untuk arsitektur dan TODO.md untuk task list.

---

## 1. Project Identity

MedTrace adalah aplikasi mobile production-ready untuk monitoring pengobatan Tuberkulosis (TB). Aplikasi ini harus siap untuk Google Play Store dan Apple App Store submission.

Tujuan utama:
- Track penyebaran TB secara geografis
- Sentralisasi data pasien
- Monitor adherence pengobatan
- Cegah treatment dropout
- Edukasi kesehatan publik via AI chatbot

---

## 2. Role System

Hanya ada DUA role dengan strict separation:

DOCTOR:
- Dibuat hanya oleh admin via database (tidak bisa self-register)
- Memiliki akses ke data semua pasien yang terhubung
- Dapat generate registration code untuk pasien baru
- Menerima alert untuk non-adherence dan high-risk patients

PATIENT:
- Tidak bisa register tanpa doctor_code
- Hanya bisa akses data sendiri
- Tidak bisa melihat data pasien lain
- Tidak bisa akses fitur doctor

Tidak ada overlap. Tidak ada role lain.

---

## 3. Technical Stack

- Language: Dart 3.3+ / Flutter 3.19+
- State Management: Riverpod (StateNotifier pattern, family providers)
- Navigation: GoRouter with role-based redirect
- Backend: Supabase (PostgreSQL + Auth + RLS + Realtime)
- Architecture: Clean Architecture (domain, data, presentation)
- Map: OpenStreetMap via flutter_map (no API key required)
- AI: OpenAI Chat Completions API
- Notifications: flutter_local_notifications

---

## 4. File Locations

| Concern | Path |
|---------|------|
| Entry point | lib/main.dart |
| Config | lib/core/config/app_config.dart |
| Constants | lib/core/constants/app_constants.dart |
| Exceptions | lib/core/error/exceptions.dart |
| Failures | lib/core/error/failures.dart |
| Extensions | lib/core/extensions/extensions.dart |
| Entities | lib/domain/entities/entities.dart |
| Models | lib/data/models/models.dart |
| Repositories | lib/data/repositories/repositories.dart |
| Remote DataSource | lib/data/datasources/remote/ |
| Auth + DI providers | lib/presentation/providers/app_providers.dart |
| Feature providers | lib/presentation/providers/feature_providers.dart |
| Router | lib/presentation/router/app_router.dart |
| Patient pages | lib/presentation/pages/patient/ |
| Doctor pages | lib/presentation/pages/doctor/ |
| Auth pages | lib/presentation/pages/auth/ |
| Theme | lib/shared/theme/app_theme.dart |
| Services | lib/services/ |
| DB migrations | supabase/migrations/ |

---

## 5. Implementation Patterns

### Membuat Entity Baru

```dart
class MyEntity extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;

  const MyEntity({required this.id, required this.name, required this.createdAt});

  MyEntity copyWith({String? id, String? name, DateTime? createdAt}) => MyEntity(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  List<Object?> get props => [id, name, createdAt];
}
```

### Membuat Model (extends Entity)

```dart
class MyModel extends MyEntity {
  const MyModel({required super.id, required super.name, required super.createdAt});

  factory MyModel.fromJson(Map<String, dynamic> json) => MyModel(
    id: json['id'] as String,
    name: json['name'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'created_at': createdAt.toIso8601String(),
  };
}
```

### Membuat StateNotifier Provider

```dart
class MyFeatureState {
  final List<MyEntity> data;
  final bool isLoading;
  final String? error;
  const MyFeatureState({this.data = const [], this.isLoading = false, this.error});
  MyFeatureState copyWith({List<MyEntity>? data, bool? isLoading, String? error}) =>
    MyFeatureState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
}

class MyFeatureNotifier extends StateNotifier<MyFeatureState> {
  final MyRepository _repository;
  MyFeatureNotifier(this._repository) : super(const MyFeatureState());

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

final myFeatureProvider = StateNotifierProvider.family<MyFeatureNotifier, MyFeatureState, String>(
  (ref, userId) {
    final repo = ref.watch(myRepositoryProvider);
    return MyFeatureNotifier(repo)..loadData(userId);
  },
);
```

### Membuat Page

```dart
class MyPage extends ConsumerWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authProvider).user!.id;
    final state = ref.watch(myFeatureProvider(userId));

    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.error != null) return Center(child: Text(state.error!));

    return Scaffold(
      appBar: AppBar(title: const Text('My Page')),
      body: ListView.builder(
        itemCount: state.data.length,
        itemBuilder: (context, index) => ListTile(title: Text(state.data[index].name)),
      ),
    );
  }
}
```

### Menambah Route

Di lib/presentation/router/app_router.dart:
```dart
// 1. Tambah constant di AppRoutes
static const String myPage = '/patient/my-page';

// 2. Tambah GoRoute di routes list
GoRoute(
  path: AppRoutes.myPage,
  name: 'my_page',
  builder: (context, state) => const MyPage(),
),
```

### Menambah Tabel Database

```sql
CREATE TABLE IF NOT EXISTS public.my_table (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.my_table ENABLE ROW LEVEL SECURITY;

CREATE POLICY my_table_patient_select ON public.my_table
  FOR SELECT USING (auth.uid() = patient_id);

CREATE POLICY my_table_patient_insert ON public.my_table
  FOR INSERT WITH CHECK (auth.uid() = patient_id);
```

---

## 6. Supabase Access Pattern

```dart
// READ (list)
final response = await supabaseClient
    .from('table_name')
    .select()
    .eq('patient_id', patientId)
    .order('created_at', ascending: false);

// READ (single)
final response = await supabaseClient
    .from('table_name')
    .select()
    .eq('id', id)
    .single();

// CREATE
await supabaseClient.from('table_name').insert({
  'column': value,
  'patient_id': patientId,
});

// UPDATE
await supabaseClient.from('table_name')
    .update({'column': newValue, 'updated_at': DateTime.now().toIso8601String()})
    .eq('id', id);

// DELETE
await supabaseClient.from('table_name').delete().eq('id', id);

// COUNT
final count = await supabaseClient
    .from('table_name')
    .select()
    .eq('patient_id', patientId)
    .count(CountOption.exact);
```

---

## 7. Rules and Constraints

1. Jangan hardcode Supabase credentials. Gunakan AppConfig.
2. Jangan akses Supabase langsung dari Page. Selalu lewat Provider -> Repository -> DataSource.
3. Semua state mutable harus di StateNotifier. Page hanya watch/read.
4. Entity tidak boleh punya dependency ke framework. Pure Dart + Equatable only.
5. Model harus extend Entity. Tambah fromJson/toJson.
6. Error handling: throw custom Exception di datasource, catch di notifier, set error state.
7. File naming: snake_case. Class naming: PascalCase. Variable naming: camelCase.
8. Imports: relative imports untuk project files, package imports untuk dependencies.
9. Gunakan const constructors di mana pun memungkinkan.
10. Jangan tinggalkan print statements atau debug logs di production code.
11. Handle semua edge cases: empty data, network failure, invalid input, timeout.
12. DateTime dari Supabase selalu UTC. Convert ke local timezone saat display.

---

## 8. Treatment Logic

Phase:
- intensive: bulan 0-2 (obat harian, monitoring ketat)
- continuation: bulan 3-6 (obat berkala, monitoring berkurang)

Status:
- ongoing: treatment aktif
- completed: treatment selesai dengan adherence >= 80%
- defaulted: pasien berhenti treatment (missed > threshold)

Adherence calculation:
- adherence_percentage = (total_taken / total_scheduled) * 100
- Update setiap kali medication_log dibuat
- Alert jika < 60%
- Alert jika missed 2+ hari berturut-turut

---

## 9. AI Chatbot Specification

System prompt:
```
You are a tuberculosis (TBC) health assistant for the MedTrace application.
Your role is to provide accurate, clear, and supportive health information.

Guidelines:
1. Explain concepts in simple, easy-to-understand language
2. Base medical information on WHO TB guidelines
3. Be empathetic, calm, and helpful
4. Do NOT provide diagnoses or prescribe medications
5. For serious concerns, advise users to consult their healthcare provider
6. Emphasize the importance of treatment adherence
7. Provide educational content about TB transmission and prevention

You are a support tool, not a replacement for professional medical advice.
```

Implementation:
- Use OpenAI Chat Completions API
- Send last 10 messages as context
- Save all messages to chatbot_messages table
- Handle rate limits and errors gracefully
- Show typing indicator during API call

---

## 10. Git Workflow

### Commit Rules

Lakukan git commit untuk setiap fitur atau perubahan yang selesai. Setiap commit harus atomic (satu concern per commit).

Format commit message:
```
<type>: <description>

<optional body>
```

Types:
- feat: fitur baru
- fix: bug fix
- refactor: refactoring tanpa perubahan behavior
- docs: perubahan dokumentasi
- style: formatting, missing semicolons (bukan CSS)
- test: menambah atau memperbaiki tests
- chore: maintenance tasks (dependencies, config)

Contoh:
```
feat: implement doctor alerts provider with Supabase integration

- Create DoctorAlertsNotifier with load, markResolved methods
- Wire alerts_page.dart to use real provider data
- Add severity filtering logic
```

### Commit Frequency

- Commit setelah setiap fitur/sub-fitur selesai dan berfungsi
- Commit setelah bug fix yang verified
- Commit setelah refactoring yang tidak break existing functionality
- Jangan commit code yang tidak compile atau memiliki known errors

### Push Rules

- Push ke remote hanya saat semua perubahan sudah di-commit dan verified
- Sebelum push, pastikan:
  1. flutter analyze tidak ada error
  2. flutter build apk --debug berhasil
  3. Tidak ada conflict dengan remote branch
- Jika ada conflict, resolve terlebih dahulu sebelum push
- Gunakan `git push -u origin <branch>` untuk branch baru
- Jangan force push ke main/master

### Branch Strategy

```
main              <- production-ready code
feature/<name>    <- fitur baru
bugfix/<name>     <- bug fixes
```

### Workflow Per Task

1. Pastikan di branch yang benar
2. Implement perubahan
3. Verify: flutter analyze + build
4. Stage files: git add <specific files> (hindari git add .)
5. Commit dengan message yang descriptive
6. Jika semua task dalam satu session selesai dan aman: push

---

## 11. Quality Checklist

Sebelum menganggap sebuah fitur selesai:

- [ ] Code compiles tanpa error (flutter analyze clean)
- [ ] UI renders tanpa crash
- [ ] Loading state ditampilkan saat fetch data
- [ ] Error state ditampilkan dengan pesan yang jelas
- [ ] Empty state ditampilkan saat data kosong
- [ ] Semua button/action berfungsi
- [ ] Navigation berfungsi (forward dan back)
- [ ] Data persist ke database dengan benar
- [ ] RLS policy tidak block akses yang legitimate
- [ ] Tidak ada hardcoded values (gunakan constants)
- [ ] Tidak ada print/debugPrint di production path

---

## 12. Current Priority

Urutan pengerjaan (lihat TODO.md untuk detail):

1. Wire doctor providers ke backend (replace dummy data)
2. Fix compilation errors dan verify build
3. OpenAI chatbot integration
4. Notification system (flutter_local_notifications)
5. Supabase Realtime subscriptions
6. Adherence calculation automation
7. Offline support (Hive caching)
8. Testing
9. Store deployment preparation

---

## 13. Commands Reference

```bash
flutter pub get              # Install dependencies
flutter analyze              # Static analysis
flutter test                 # Run tests
flutter build apk --debug    # Debug APK
flutter build apk --release  # Release APK
flutter run                  # Run on device
flutter clean                # Clean build cache
dart format lib/             # Format code
```
