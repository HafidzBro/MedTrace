# MedTrace - Architecture Documentation

## 📐 Architecture Overview

MedTrace follows **Clean Architecture** principles with three distinct layers:

```
┌─────────────────────────────────────────────┐
│      PRESENTATION LAYER                     │
│  (Pages, Providers, Widgets, Router)        │
└──────────────────┬──────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────┐
│      STATE MANAGEMENT LAYER                 │
│  (Riverpod StateNotifiers, Providers)       │
└──────────────────┬──────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────┐
│      DOMAIN LAYER                           │
│  (Entities, Repository Interfaces)          │
└──────────────────┬──────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────┐
│      DATA LAYER                             │
│  (Repositories, DataSources, Models)        │
└──────────────────┬──────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────┐
│      EXTERNAL (Supabase)                    │
│  (PostgreSQL Database, Auth, Storage)       │
└─────────────────────────────────────────────┘
```

## 🏗️ Layer Responsibilities

### 1. PRESENTATION LAYER
**Location**: `lib/presentation/`

**Responsibilities:**
- Display UI to users
- Handle user interactions
- Navigate between screens
- Trigger business logic via providers

**Key Components:**
- **Pages**: Full screen widgets (LoginPage, TreatmentDetailsPage, etc.)
- **Widgets**: Reusable UI components
- **Providers**: Riverpod state management
- **Router**: GoRouter navigation configuration

**Isolation**: 
- Does NOT contain business logic
- Does NOT directly call APIs
- All data access via providers

**Example Flow**:
```
User taps "Mark Medication Taken"
     ↓
Page calls: ref.read(patientMedicationLogsProvider.notifier).markMedicationTaken()
     ↓
StateNotifier updates state
     ↓
Page rebuilds with new state
```

### 2. STATE MANAGEMENT LAYER
**Location**: `lib/presentation/providers/`

**Responsibilities:**
- Manage application state
- Call repositories for data
- Handle async operations
- Notify listeners of changes

**Pattern Used**: **Riverpod with StateNotifier**

**Key Providers:**
- **Auth Provider**: User authentication state
- **Feature Providers**: Domain-specific state (Treatments, Medications, etc.)
- **Repository Providers**: Dependency injection for repositories
- **Datasource Providers**: Dependency injection for data sources

**Example StateNotifier**:
```dart
class MedicationLogsNotifier extends StateNotifier<MedicationLogsState> {
  final MedicationLogRepository repository;
  
  // Called by presentation layer
  Future<void> markMedicationTaken(String medicationId) async {
    // 1. Call repository
    await repository.createMedicationLog(
      medicationId: medicationId,
      status: 'taken',
      takenAt: DateTime.now(),
    );
    
    // 2. Update local state
    state = state.copyWith(adherencePercentage: 87);
    
    // 3. Page rebuilds automatically
  }
}
```

### 3. DOMAIN LAYER
**Location**: `lib/domain/`

**Responsibilities:**
- Define business entities
- Define repository interfaces
- Implement use cases (future)
- Business logic rules

**Key Components:**
- **Entities**: Pure business objects (User, Treatment, Medication, etc.)
- **Repository Interfaces**: What data operations are available
- **Value Objects**: Immutable value types

**Entity Example**:
```dart
class Treatment extends Equatable {
  final String id;
  final String patientId;
  final String status;
  final double adherencePercentage;
  
  // Computed property
  bool get isCompleted => status == 'completed';
  
  // Value equality
  @override
  List<Object> get props => [id, patientId, status, adherencePercentage];
}
```

**Repository Interface**:
```dart
abstract class TreatmentRepository {
  Future<Treatment> getPatientTreatment(String patientId);
  Future<void> createTreatment(Treatment treatment);
  Future<void> updateTreatment(Treatment treatment);
}
```

### 4. DATA LAYER
**Location**: `lib/data/`

**Responsibilities:**
- Fetch data from remote sources
- Transform data to/from API format
- Implement repository interfaces
- Caching logic (future)

**Key Components:**
- **Models**: JSON-serializable versions of entities
- **Remote Data Source**: API interaction (Supabase)
- **Repositories**: Implementations of domain interfaces

**Data Flow Example**:
```
API Response (JSON)
    ↓
DataSource parses JSON to Model
    ↓
Repository converts Model to Entity
    ↓
StateNotifier receives Entity
    ↓
UI displays Entity
```

**Model Example**:
```dart
class TreatmentModel extends Treatment {
  const TreatmentModel({
    required String id,
    required String patientId,
    // ...
  }) : super(id: id, patientId: patientId);
  
  // JSON serialization
  factory TreatmentModel.fromJson(Map<String, dynamic> json) {
    return TreatmentModel(
      id: json['id'],
      patientId: json['patient_id'],
      // ...
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    // ...
  };
}
```

## 🔄 Data Flow Example: Patient Logs Medication

### 1. Trigger: User taps "Mark Taken"
```dart
// Location: medication_schedule_page.dart
ref.read(patientMedicationLogsProvider(userId).notifier)
    .markMedicationTaken(medication.id);
```

### 2. StateNotifier Processes
```dart
// Location: feature_providers.dart - MedicationLogsNotifier
Future<void> markMedicationTaken(String medicationId) async {
  state = state.copyWith(isLoading: true);
  
  try {
    // Call repository
    await repository.createMedicationLog(
      medicationId: medicationId,
      patientId: patientId,
      status: 'taken',
      takenAt: DateTime.now(),
    );
    
    // Reload all logs
    await loadMedicationLogs();
  } catch (e) {
    state = state.copyWith(error: e.toString());
  }
}
```

### 3. Repository Executes
```dart
// Location: repositories.dart - MedicationLogRepository
@override
Future<void> createMedicationLog({
  required String medicationId,
  required String patientId,
  required String status,
  required DateTime takenAt,
}) {
  return remoteDataSource.createMedicationLog(
    medicationId: medicationId,
    patientId: patientId,
    status: status,
    takenAt: takenAt,
  );
}
```

### 4. DataSource Calls API
```dart
// Location: supabase_remote_datasource.dart
Future<void> createMedicationLog({...}) async {
  await supabaseClient
      .from('medication_logs')
      .insert({
        'medication_id': medicationId,
        'patient_id': patientId,
        'status': status,
        'taken_at': takenAt.toIso8601String(),
      });
}
```

### 5. Database Saves
```sql
-- Supabase PostgreSQL
INSERT INTO medication_logs (medication_id, patient_id, status, taken_at)
VALUES ('med_123', 'patient_456', 'taken', '2024-05-20T14:30:00Z')
RETURNING *;
```

### 6. StateNotifier Reloads & UI Updates
```dart
// StateNotifier automatically recalculates adherence
state = state.copyWith(
  data: updatedLogs,
  adherencePercentage: 87.5, // Recalculated
);

// Page watches provider and rebuilds automatically
final state = ref.watch(patientMedicationLogsProvider(userId));
// UI displays new adherence percentage
```

## 🎯 Design Patterns Used

### 1. Repository Pattern
**Purpose**: Abstract data access logic

```
Presentation → Repository Interface (Domain)
                        ↓
                    Repository Implementation (Data)
                        ↓
                    Remote DataSource
                        ↓
                    External API
```

### 2. Factory Pattern
**Purpose**: Create instances with complex initialization

```dart
final appThemeProvider = Provider((ref) {
  final user = ref.watch(authProvider).user;
  if (user?.isDoctor == true) {
    return AppTheme.doctor();  // Factory method
  }
  return AppTheme.patient();   // Factory method
});
```

### 3. StateNotifier Pattern
**Purpose**: Encapsulate mutable state

```dart
class TreatmentNotifier extends StateNotifier<TreatmentState> {
  // State is immutable
  // Changes trigger rebuilds automatically
  state = state.copyWith(isLoading: true);
}
```

### 4. Dependency Injection (Riverpod)
**Purpose**: Separate concerns and enable testing

```dart
// Instead of: 
// final repo = TreatmentRepository(); // Direct dependency

// Use:
final repository = ref.watch(treatmentRepositoryProvider);
// Can mock in tests
```

### 5. Builder Pattern
**Purpose**: Complex object creation

```dart
// Instead of many constructor parameters:
Treatment treatment = createTreatment(
  id: '123',
  patientId: '456',
  phase: 'intensive',
  // ... 10 more parameters
);

// Use immutable copyWith:
treatment.copyWith(
  phase: 'continuation', // Only change what's needed
);
```

## 🔐 Security & Isolation

### Role-Based Access Control (RBAC)

**Patient View:**
```dart
// Patient can only access own data
SELECT * FROM treatments WHERE patient_id = current_user_id;
```

**Doctor View:**
```dart
// Doctor can access patients' data they manage
SELECT * FROM treatments t
WHERE t.patient_id IN (
  SELECT patient_id FROM doctor_patients 
  WHERE doctor_id = current_user_id
);
```

### RLS Policies
All tables have Row Level Security:
- ✅ Patients can ONLY read/write their own data
- ✅ Doctors can ONLY read/write their patients' data
- ✅ Admin can manage everything

**Example Policy**:
```sql
CREATE POLICY patient_isolation ON treatments
AS RESTRICTIVE USING (
  auth.uid()::uuid = patient_id OR
  auth.uid()::uuid IN (
    SELECT doctor_id FROM doctor_patients 
    WHERE patient_id = treatments.patient_id
  )
);
```

## 📊 State Management Deep Dive

### Provider Types Used

**1. Simple Provider (Read-Only)**
```dart
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
```

**2. StateNotifier Provider (Mutable)**
```dart
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
```

**3. Family Provider (Parameterized)**
```dart
final patientTreatmentProvider = 
  StateNotifierProvider.family<TreatmentNotifier, TreatmentState, String>(
    (ref, patientId) => TreatmentNotifier(patientId: patientId),
  );

// Usage:
ref.watch(patientTreatmentProvider('user_123'));
ref.watch(patientTreatmentProvider('user_456')); // Different state instance
```

**4. FutureProvider (Async)**
```dart
final userProvider = FutureProvider<User>((ref) async {
  return await repository.getUser();
});
```

## 🗄️ Database Schema Design

**Entity-Relationship Diagram:**
```
    Profiles
    /  |  \
   /   |   \
Doctor Doctor Patient
Codes Patients Locations

      Treatments
      /  \
     /    \
Medications Reminders
  |
  ↓
Medication Logs

Chatbot Conversations
  |
  ↓
Chatbot Messages

    Alerts
```

**Key Design Decisions:**
- ✅ Normalized schema (3NF)
- ✅ Surrogate keys (UUID) for all tables
- ✅ Timestamps (created_at, updated_at)
- ✅ Status enums for flexible workflows
- ✅ Spatial indexes for geospatial queries

## 🎨 UI Architecture

### Widget Hierarchy
```
MaterialApp
  ├── GoRouter (Navigation)
  ├── ProviderScope (Riverpod)
  └── ThemeData (Material 3)
      ├── PatientDashboardPage
      │   ├── MedicationSchedulePage
      │   ├── TreatmentDetailsPage
      │   ├── ChatbotPage
      │   ├── RemindersPage
      │   └── TbMapPage
      └── DoctorDashboardPage
          ├── PatientManagementPage
          ├── AlertsPage
          └── (Analytics, Map - future)
```

### Page Structure
```dart
class MyPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch providers for data
    final state = ref.watch(someProvider);
    
    // 2. Access notifiers for actions
    final notifier = ref.read(someProvider.notifier);
    
    // 3. Build UI that responds to state
    return Scaffold(
      body: state.isLoading 
        ? LoadingWidget()
        : state.data != null
          ? DataWidget(state.data)
          : EmptyWidget(),
    );
  }
}
```

## 🚀 Scalability Considerations

### For Growing User Base
- ✅ Indexing strategies for large datasets
- ✅ Pagination support in repositories
- ✅ Caching layer ready (Hive)
- ✅ Async operations throughout

### For New Features
- ✅ Modular repository structure
- ✅ Easy to add new StateNotifiers
- ✅ Extension methods for utilities
- ✅ Consistent error handling

### For Performance
- ✅ Lazy loading of data
- ✅ StateNotifier caching
- ✅ Efficient UI rebuilds (watch specific providers)
- ✅ Spatial indexes for location queries

## 📚 File Organization

```
lib/
├── core/                 # Infrastructure utilities
│   ├── config/          # App configuration
│   ├── constants/       # Constants and enums
│   ├── error/           # Exceptions and failures
│   └── extensions/      # Utility extensions
│
├── data/                # Data access layer
│   ├── datasources/     # API interaction
│   ├── models/          # JSON models
│   └── repositories/    # Repository implementations
│
├── domain/              # Business logic layer
│   └── entities/        # Pure business objects
│
├── presentation/        # UI layer
│   ├── pages/           # Full-screen widgets
│   ├── providers/       # Riverpod state management
│   ├── router/          # Navigation
│   └── widgets/         # Reusable components
│
├── services/            # Utility services
└── shared/              # Shared resources
    └── theme/           # Theme definitions

test/                    # Unit and widget tests
supabase/
├── migrations/          # Database migrations
└── seed/                # Seed data (optional)
```

## 🔄 Dependency Flow

```
Presentation ← Riverpod Providers
                       ↓
                 Repositories
                       ↓
              RemoteDataSource
                       ↓
              SupabaseClient
                       ↓
              Supabase Backend
```

**Benefits:**
- ✅ Easy to test (mock at any level)
- ✅ Easy to change implementation
- ✅ Loose coupling between layers
- ✅ Single responsibility principle

---

**Architecture Pattern**: Clean Architecture with Riverpod  
**State Management**: Riverpod StateNotifier  
**Navigation**: GoRouter  
**Database**: Supabase PostgreSQL with RLS  
**Language**: Dart 3.3.0+  
**Framework**: Flutter 3.19.0+

**Last Updated**: May 2024
