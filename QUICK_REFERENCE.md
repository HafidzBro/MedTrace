# MedTrace - Quick Reference Guide

## 🚀 Quick Start Commands

```bash
# Clone and setup
git clone https://github.com/your-org/medtrace.git
cd medtrace
flutter clean
flutter pub get

# Run on emulator
flutter run -d emulator-5554

# Run on physical device
flutter run

# Run with verbose logging
flutter run -v

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

## 🔐 Environment Configuration

### Before First Run
Create `.env` file in project root:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_JWT_SECRET=your-jwt-secret
OPENAI_API_KEY=sk-your-key-here
```

### Load in main.dart:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(const MedTraceApp());
}
```

## 📱 Test Credentials

### Patient Account
```
Email: patient@test.com
Password: Test123!@#
Doctor Code: (ask doctor to generate)
```

### Doctor Account
```
Email: doctor@test.com
Password: Test123!@#
No code needed - selects Doctor role
```

## 🎯 Common Code Snippets

### Watch a Provider
```dart
final state = ref.watch(myProvider);
```

### Watch Multiple Providers
```dart
final state1 = ref.watch(provider1);
final state2 = ref.watch(provider2);
```

### Watch Only Part of State
```dart
// Only rebuilds when data changes, not isLoading
final data = ref.watch(myProvider.select((s) => s.data));
```

### Call a Provider Method
```dart
// Mark medication as taken
ref.read(patientMedicationLogsProvider.notifier)
    .markMedicationTaken(medicationId);

// Refresh provider (reload data)
ref.refresh(myProvider);
```

### Navigate to Page
```dart
// Import GoRouter
import 'package:go_router/go_router.dart';

// Navigate
context.go('/patient/medications');

// Navigate with parameters
context.go('/patient/treatment', extra: {'id': '123'});

// Navigate and replace history
context.replace('/patient/dashboard');

// Pop
context.pop();
```

### Show Snackbar
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Text('Medication marked as taken'),
    duration: const Duration(seconds: 2),
    backgroundColor: Colors.green,
  ),
);
```

### Show Dialog
```dart
showDialog<String>(
  context: context,
  builder: (BuildContext context) => AlertDialog(
    title: const Text('Confirm'),
    content: const Text('Are you sure?'),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, 'OK'),
        child: const Text('OK'),
      ),
    ],
  ),
);
```

### Async Loading UI
```dart
final state = ref.watch(myProvider);

if (state.isLoading) {
  return const CircularProgressIndicator();
}

if (state.error != null) {
  return Text('Error: ${state.error}');
}

if (state.data == null || state.data!.isEmpty) {
  return const Text('No data available');
}

return MyListWidget(state.data!);
```

### API Call in StateNotifier
```dart
class MyNotifier extends StateNotifier<MyState> {
  final MyRepository _repository;
  
  MyNotifier(this._repository) : super(const MyState());
  
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.getData();
      state = state.copyWith(data: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }
}
```

### Create New StateNotifier Provider
```dart
class MyState {
  final List<MyData> data;
  final bool isLoading;
  final String? error;
  
  const MyState({
    this.data = const [],
    this.isLoading = false,
    this.error,
  });
  
  MyState copyWith({
    List<MyData>? data,
    bool? isLoading,
    String? error,
  }) => MyState(
    data: data ?? this.data,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
  );
}

class MyNotifier extends StateNotifier<MyState> {
  MyNotifier() : super(const MyState());
  
  Future<void> loadData() async {
    // Implementation
  }
}

final myProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier();
});
```

### Supabase Query
```dart
// Get data
final response = await supabaseClient
  .from('treatments')
  .select()
  .eq('patient_id', patientId)
  .single();

// Insert data
final response = await supabaseClient
  .from('medication_logs')
  .insert({
    'medication_id': medicationId,
    'patient_id': patientId,
    'status': 'taken',
    'taken_at': DateTime.now().toIso8601String(),
  });

// Update data
final response = await supabaseClient
  .from('treatments')
  .update({'status': 'completed'})
  .eq('id', treatmentId);

// Delete data
await supabaseClient
  .from('reminders')
  .delete()
  .eq('id', reminderId);

// Count rows
final count = await supabaseClient
  .from('patients')
  .select()
  .count(CountOption.exact);
```

### Error Handling
```dart
try {
  await someAsyncOperation();
} on SocketException catch (e) {
  print('Network error: $e');
} on FormatException catch (e) {
  print('Format error: $e');
} catch (e) {
  print('Unknown error: $e');
}
```

### DateTime Operations
```dart
// Current date
final now = DateTime.now();

// Create specific date
final specific = DateTime(2024, 5, 20, 14, 30);

// Add days
final tomorrow = now.add(const Duration(days: 1));

// Subtract days
final yesterday = now.subtract(const Duration(days: 1));

// Format to string
final formatted = DateFormat('MMM d, yyyy - h:mm a').format(now);

// Parse from string
final parsed = DateFormat('yyyy-MM-dd').parse('2024-05-20');

// Compare dates (same day)
bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && 
         a.month == b.month && 
         a.day == b.day;
}

// Time until event
final duration = scheduledTime.difference(now);
final hoursLeft = duration.inHours;
```

### Color & Theme
```dart
// Get theme colors
final theme = Theme.of(context);
final primary = theme.primaryColor;
final surface = theme.scaffoldBackgroundColor;

// Patient theme colors
const patientPrimary = Color(0xFF0F766E); // Teal
const patientSecondary = Color(0xFF14B8A6);

// Doctor theme colors
const doctorPrimary = Color(0xFF134E4A); // Dark Teal
const doctorSecondary = Color(0xFF0F766E);

// Use in widgets
Container(
  color: theme.colorScheme.primary,
  child: const Text('Hello'),
)
```

## 🧪 Testing Commands

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/models/medication_test.dart

# Run tests with coverage
flutter test --coverage

# Run tests in watch mode
flutter test --watch

# Generate coverage report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 🐛 Debugging

```bash
# Run with verbose logging
flutter run -v

# Inspect logs from device
flutter logs

# Attach debugger to running app
flutter attach

# Debug on physical device
flutter run -d <device-id> --debug

# List connected devices
flutter devices

# Hot reload (fast: keep app state)
Press 'r'

# Hot restart (restart: lose app state)
Press 'R'

# Quit
Press 'q'
```

## 📦 Dependency Management

```bash
# Check for outdated packages
flutter pub outdated

# Upgrade dependencies
flutter pub upgrade

# Get specific version
flutter pub add package_name:^1.0.0

# Remove package
flutter pub remove package_name

# Analyze dependencies
flutter pub deps

# Resolve conflicts
flutter pub get
```

## 🔍 Code Analysis

```bash
# Analyze all code
flutter analyze

# Format code
dart format lib/ -i

# Format and check (no changes)
dart format lib/ --output=none

# Check specific file
dart format lib/main.dart -i

# Ignore warnings
dart analyze --no-warnings
```

## 📱 Device Management

```bash
# List devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Uninstall app from device
flutter uninstall

# Clear app data
adb shell pm clear com.example.medtrace

# View device logs
adb logcat | grep flutter

# Take screenshot
adb shell screencap /sdcard/screenshot.png
adb pull /sdcard/screenshot.png
```

## 🎯 Performance Tips

```bash
# Build in release mode (faster)
flutter run --release

# Profile performance
flutter run -v --profile

# Check app size
flutter build apk --analyze-size

# Generate flame graph
flutter run --profile --preserve-frames
```

## 🔧 Common Issues & Fixes

### Issue: Flutter not found
```bash
# Add Flutter to PATH
export PATH="$PATH:/path/to/flutter/bin"

# Verify
flutter --version
```

### Issue: Gradle issues
```bash
# Clean gradle cache
./gradlew clean

# Rebuild gradle
flutter clean && flutter pub get
```

### Issue: Pod issues (iOS)
```bash
# Clean pods
cd ios && rm -rf Pods Podfile.lock && cd ..

# Reinstall
flutter clean && flutter pub get
```

### Issue: Dartfmt/format issues
```bash
# Format all files
dart format lib/ -i

# Format specific file
dart format lib/main.dart -i
```

### Issue: Hot reload not working
```bash
# Use hot restart instead
# Press 'R'

# Or run with flag
flutter run --enable-software-keyboard
```

## 🚨 Emergency Commands

```bash
# Complete clean rebuild
flutter clean
flutter pub get
flutter run

# Reset Supabase local state
# Delete .supabase directory

# Kill all Flutter processes
pkill -f flutter

# Restart device
adb reboot

# Reset iOS simulator
xcrun simctl erase all
```

## 🔐 Git Workflow Quick Commands

```bash
# Create feature branch
git checkout -b feature/my-feature

# Check status
git status

# Add changes
git add .
git add lib/specific_file.dart

# Commit
git commit -m "feat: add new feature"

# Push
git push origin feature/my-feature

# Create pull request
# Via GitHub UI

# Pull latest
git pull origin main

# Merge locally
git merge feature/my-feature

# Delete branch
git branch -d feature/my-feature
git push origin --delete feature/my-feature
```

## 📚 Documentation Links

- **Flutter Docs**: https://flutter.dev/docs
- **Dart Docs**: https://dart.dev/guides
- **Riverpod Docs**: https://riverpod.dev
- **GoRouter Docs**: https://pub.dev/packages/go_router
- **Supabase Docs**: https://supabase.com/docs
- **Material 3**: https://m3.material.io

## 🎓 Learning Resources

- Flutter Codelabs: https://flutter.dev/codelabs
- Dart by Example: https://dart.dev/samples
- Riverpod Examples: https://riverpod.dev/docs/getting_started
- Clean Architecture: https://resocoder.com/clean-architecture
- Effective Dart: https://dart.dev/guides/language/effective-dart

## 💡 Pro Tips

### Use const everywhere possible
```dart
const MyWidget();  // Not 'MyWidget()'
const []; // instead of []
const {}; // instead of {}
```

### Use extensions for repeated code
```dart
extension DateTimeX on DateTime {
  bool get isToday => isSameDay(this, DateTime.now());
  
  bool get isTomorrow => 
    isSameDay(this, DateTime.now().add(const Duration(days: 1)));
}

// Usage
if (date.isToday) { }
```

### Use freezed for immutable classes
```dart
// Instead of manual copyWith()
@freezed
class MyModel with _$MyModel {
  const factory MyModel({
    required String id,
    required String name,
  }) = _MyModel;
}

// Auto-generates: copyWith(), ==, hashCode, toString()
```

### Listen to provider changes
```dart
ref.listen(myProvider, (previous, next) {
  if (previous?.data != next.data) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data updated!')),
    );
  }
});
```

### Use select for granular updates
```dart
// ❌ Rebuilds on ANY state change
final state = ref.watch(myProvider);

// ✅ Only rebuilds when isLoading changes
final isLoading = ref.watch(myProvider.select((s) => s.isLoading));
```

---

**Last Updated**: May 2024
**Quick Reference Version**: 1.0
