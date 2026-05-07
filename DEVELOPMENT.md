# MedTrace - Development Guide

## 👨‍💻 Developer Quick Reference

### First Time Contributor Checklist
- [ ] Read ARCHITECTURE.md to understand structure
- [ ] Read SETUP.md to set up local environment
- [ ] Run `flutter pub get` in project root
- [ ] Create a test user in Supabase
- [ ] Run app on emulator/device
- [ ] Explore patient and doctor flows
- [ ] Review existing provider patterns in `lib/presentation/providers/`

## 📝 Coding Standards

### Naming Conventions
```dart
// Classes: PascalCase
class MedicationSchedulePage { }
class MedicationLogsNotifier { }

// Variables: camelCase
final userId = ref.watch(authProvider).user?.id;
final medicationList = state.data ?? [];

// Constants: camelCase with 'k' prefix (or UPPER_CASE)
const kMinimumAdherence = 0.8;
const MEDICATION_TABLE = 'medications';

// Private members: _prefix
void _privateMethod() { }
final _privateVariable = 42;

// Booleans: is/has prefix
bool isLoading = false;
bool hasError = false;

// Dart linter: Enable 'always_put_overrides_in_respective_sections'
```

### File Organization
```dart
// 1. Imports (organized by type)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:medtrace/core/config/app_config.dart';
import 'package:medtrace/data/repositories/medication_repository.dart';
import 'package:medtrace/domain/entities/medication.dart';
import 'package:medtrace/presentation/widgets/custom_button.dart';

// 2. Constants
const _kPaddingHorizontal = 16.0;
const _kBorderRadius = 12.0;

// 3. Main class
class MyPage extends ConsumerWidget {
  // 3a. Constants (page-specific)
  static const routeName = '/my-page';
  
  // 3b. Constructor
  const MyPage({Key? key}) : super(key: key);
  
  // 3c. Build method
  @override
  Widget build(BuildContext context, WidgetRef ref) { }
  
  // 3d. Private helper methods
  void _privateHelper() { }
}
```

### StateNotifier Pattern

**DO:**
```dart
class TreatmentNotifier extends StateNotifier<TreatmentState> {
  final TreatmentRepository _repository;
  
  TreatmentNotifier(this._repository) 
    : super(const TreatmentState());
  
  Future<void> loadTreatment(String patientId) async {
    state = state.copyWith(isLoading: true);
    try {
      final treatment = await _repository.getTreatment(patientId);
      state = state.copyWith(
        data: treatment,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}
```

**DON'T:**
```dart
// ❌ Don't mutate state directly
state.data!.phase = 'continuation'; // WRONG

// ❌ Don't call API in build method
Future<void> apiCall() async { } // WRONG - not in StateNotifier

// ❌ Don't ignore errors
try {
  await api.call();
} catch (e) {
  // WRONG - errors silently ignored
}
```

### Widget Pattern

**DO:**
```dart
class MedicationCard extends ConsumerWidget {
  final Medication medication;
  
  const MedicationCard({required this.medication, Key? key}) 
    : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch providers needed
    final user = ref.watch(authProvider).user;
    
    // Read notifiers for actions
    final logs = ref.read(medicationLogsProvider.notifier);
    
    return Card(
      child: ListTile(
        title: Text(medication.name),
        onTap: () async {
          await logs.markMedicationTaken(medication.id);
        },
      ),
    );
  }
}
```

**DON'T:**
```dart
// ❌ Don't pass functions as callbacks
class MyWidget extends Widget {
  final Function onTap; // WRONG - not testable
}

// ❌ Don't create notifiers in build
final notifier = ref.read(...); // WRONG - recreated every build

// ❌ Don't do side effects in build
void build(...) {
  api.call(); // WRONG - called multiple times
}
```

## 🔧 Common Tasks

### Add a New Feature Page

**Step 1: Create the page widget**
```dart
// lib/presentation/pages/patient/my_feature_page.dart
class MyFeaturePage extends ConsumerWidget {
  static const routeName = '/my-feature';
  const MyFeaturePage({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Implement UI
    return Scaffold(
      appBar: AppBar(title: const Text('My Feature')),
      body: const Center(child: Text('Coming soon')),
    );
  }
}
```

**Step 2: Add route to router**
```dart
// lib/presentation/router/app_router.dart
class AppRoutes {
  static const myFeature = '/my-feature';
}

// In GoRouter.routes:
GoRoute(
  path: AppRoutes.myFeature,
  builder: (context, state) => const MyFeaturePage(),
),
```

**Step 3: Add navigation from dashboard**
```dart
// lib/presentation/pages/patient/patient_dashboard_page.dart
GridTile(
  icon: Icons.star,
  label: 'My Feature',
  onTap: () => context.go(AppRoutes.myFeature),
),
```

### Add a New State Provider

**Step 1: Define state class**
```dart
// lib/presentation/providers/feature_providers.dart
class MyFeatureState {
  final List<MyData> data;
  final bool isLoading;
  final String? error;
  
  const MyFeatureState({
    this.data = const [],
    this.isLoading = false,
    this.error,
  });
  
  MyFeatureState copyWith({
    List<MyData>? data,
    bool? isLoading,
    String? error,
  }) {
    return MyFeatureState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
```

**Step 2: Create StateNotifier**
```dart
class MyFeatureNotifier extends StateNotifier<MyFeatureState> {
  final MyRepository _repository;
  
  MyFeatureNotifier(this._repository) : super(const MyFeatureState());
  
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _repository.getData();
      state = state.copyWith(data: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}
```

**Step 3: Create provider**
```dart
final myFeatureProvider = 
  StateNotifierProvider<MyFeatureNotifier, MyFeatureState>((ref) {
    final repository = ref.watch(myRepositoryProvider);
    return MyFeatureNotifier(repository);
  });
```

**Step 4: Use in widget**
```dart
class MyPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myFeatureProvider);
    
    return state.isLoading
      ? const CircularProgressIndicator()
      : ListView.builder(
          itemCount: state.data.length,
          itemBuilder: (context, index) {
            return Text(state.data[index].name);
          },
        );
  }
}
```

### Add a New Database Table

**Step 1: Create migration**
```sql
-- supabase/migrations/20240520_create_my_table.sql
CREATE TABLE my_table (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES profiles(id),
  name TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(patient_id, name)
);

-- RLS Policy
ALTER TABLE my_table ENABLE ROW LEVEL SECURITY;

CREATE POLICY my_table_patient_access ON my_table
  AS PERMISSIVE FOR SELECT
  USING (auth.uid() = patient_id);
```

**Step 2: Create entity**
```dart
// lib/domain/entities/my_entity.dart
class MyEntity extends Equatable {
  final String id;
  final String patientId;
  final String name;
  
  const MyEntity({
    required this.id,
    required this.patientId,
    required this.name,
  });
  
  @override
  List<Object> get props => [id, patientId, name];
}
```

**Step 3: Create model**
```dart
// lib/data/models/my_model.dart
class MyModel extends MyEntity {
  const MyModel({
    required String id,
    required String patientId,
    required String name,
  }) : super(id: id, patientId: patientId, name: name);
  
  factory MyModel.fromJson(Map<String, dynamic> json) {
    return MyModel(
      id: json['id'],
      patientId: json['patient_id'],
      name: json['name'],
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patient_id,
    'name': name,
  };
}
```

**Step 4: Update repository**
```dart
// lib/data/repositories/my_repository.dart
abstract class MyRepository {
  Future<List<MyEntity>> getAll(String patientId);
  Future<void> create(MyEntity entity);
}

class MyRepositoryImpl implements MyRepository {
  final SupabaseRemoteDataSource _dataSource;
  
  @override
  Future<List<MyEntity>> getAll(String patientId) async {
    final models = await _dataSource.getAll(patientId);
    return models.map((m) => m as MyEntity).toList();
  }
}
```

## 🧪 Testing Patterns

### Setup Test File
```dart
// test/presentation/providers/my_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('MyProvider', () {
    test('loads data successfully', () async {
      final mockRepository = MockMyRepository();
      
      when(mockRepository.getData())
        .thenAnswer((_) async => [MyData(id: '1', name: 'Test')]);
      
      final container = ProviderContainer(
        overrides: [
          myRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      
      expect(
        container.read(myProvider),
        isA<MyState>(),
      );
    });
  });
}
```

### Widget Testing
```dart
// test/presentation/pages/my_page_test.dart
void main() {
  testWidgets('MyPage renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: MyPage()),
      ),
    );
    
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });
}
```

## 🐛 Debugging Tips

### Enable Debug Logging
```dart
// In main.dart
void main() {
  // Enable Riverpod logs
  ProviderContainer.enableLogging = true;
  
  runApp(const MyApp());
}
```

### Log Provider Changes
```dart
// Watch changes to a provider
ref.listen(myProvider, (previous, next) {
  debugPrint('Previous: $previous');
  debugPrint('Next: $next');
});
```

### Inspect Supabase Data
```dart
// In any provider or page
final supabase = ref.watch(supabaseClientProvider);
final response = await supabase
  .from('my_table')
  .select()
  .limit(10);
debugPrint('Response: $response');
```

### DevTools Flutter Extension
```bash
# Install DevTools
flutter pub global activate devtools

# Run DevTools
devtools

# Connect to running app
# Then use Riverpod tab to inspect providers
```

## 📚 Best Practices

### ✅ Do:
- ✅ Use const constructors whenever possible
- ✅ Use immutable data structures
- ✅ Handle all error cases
- ✅ Use try-catch in async operations
- ✅ Watch only the providers you need
- ✅ Use copyWith for state updates
- ✅ Document complex logic with comments
- ✅ Extract constants to named variables
- ✅ Use meaningful variable names
- ✅ Test before submitting PR

### ❌ Don't:
- ❌ Use mutable state
- ❌ Ignore exceptions
- ❌ Watch providers unnecessarily (causes rebuilds)
- ❌ Inline magic numbers
- ❌ Use single-letter variable names
- ❌ Mix business logic with UI
- ❌ Call APIs directly from widgets
- ❌ Create new notifiers in build
- ❌ Use null! unless absolutely certain
- ❌ Leave TODO comments in production code

## 🔄 Git Workflow

### Branch Naming
```bash
# Features
git checkout -b feature/add-chatbot-api

# Bug fixes
git checkout -b bugfix/fix-medication-adherence

# Documentation
git checkout -b docs/update-architecture
```

### Commit Message Format
```
feat: Add chatbot API integration
      
- Implement OpenAI message sending
- Add system prompt for TB education
- Handle API errors gracefully

Closes #42
```

### Before Pushing
```bash
# Format code
dartfmt -w lib/

# Run tests
flutter test

# Check for errors
flutter analyze

# Build to verify
flutter build apk --debug
```

## 🚀 Performance Tips

### Optimize Rebuilds
```dart
// ❌ Rebuilds on every state change
final state = ref.watch(provider);

// ✅ Rebuilds only when data changes
final data = ref.watch(provider.select((s) => s.data));

// ✅ Rebuilds only when loading flag changes
final isLoading = ref.watch(provider.select((s) => s.isLoading));
```

### Use Lazy Providers
```dart
// Lazy providers don't load until accessed
final expensiveProvider = FutureProvider.autoDispose<T>((ref) async {
  return await expensiveOperation();
});
```

### Pagination (Future)
```dart
// Load data in chunks instead of all at once
Future<List<Item>> getItems(int page) {
  return repository.getItems(
    offset: page * 20,
    limit: 20,
  );
}
```

## 📞 Getting Help

### Common Questions

**Q: How do I watch multiple providers?**
```dart
final state1 = ref.watch(provider1);
final state2 = ref.watch(provider2);
// Both are now available
```

**Q: How do I refresh a provider?**
```dart
// Invalidate provider to reload
ref.refresh(myProvider);

// Or for family providers
ref.refresh(myFamilyProvider(id));
```

**Q: How do I pass data between pages?**
```dart
// Use GoRouter state
context.go('/page', extra: {'id': '123'});

// Access in next page
final params = GoRouterState.of(context).extra as Map;
final id = params['id'];
```

**Q: How do I test API calls?**
```dart
// Mock the repository
final mockRepo = MockRepository();
when(mockRepo.getUser()).thenAnswer((_) async => User(...));

// Override in test
ProviderContainer(
  overrides: [repositoryProvider.overrideWithValue(mockRepo)],
);
```

## 📋 Code Review Checklist

Before submitting PR:
- [ ] Code follows naming conventions
- [ ] No console.log or debug prints left
- [ ] Error handling implemented
- [ ] Loading states shown
- [ ] Empty states handled
- [ ] Tests written or updated
- [ ] No unnecessary rebuilds
- [ ] No hardcoded strings (use constants)
- [ ] Provider pattern followed
- [ ] Documentation updated

---

**Happy coding! 🚀**

For questions, refer to ARCHITECTURE.md or create an issue on GitHub.
