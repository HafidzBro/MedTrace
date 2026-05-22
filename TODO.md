# MedTrace Mobile - TODO

## Completion Summary

| Category | Status |
|----------|--------|
| Core Infrastructure | Complete |
| Database Schema + RLS | Complete |
| Domain Layer (Entities) | Complete |
| Data Layer (Models, Repos, DataSource) | Complete |
| Auth System | Complete |
| Patient UI (6 pages) | Complete |
| Doctor UI (3 pages + detail) | Complete |
| State Management (all providers) | Complete |
| OpenAI Chatbot | Complete |
| Notifications | Complete |
| Realtime (medication_logs + alerts + treatments) | Complete |
| Reminders CRUD | Complete |
| Adherence Calculation + Auto-alerts | Complete |
| Offline Support | Not started |
| Testing | Not started |
| Store Deployment | Not started |

Overall: approximately 85% complete toward MVP.

---

## Phase 1: Critical (MVP Blockers)

### 1.1 Wire Doctor Providers to Backend

File: lib/presentation/providers/feature_providers.dart

- [x] Create DoctorPatientsNotifier (state: list of patients with adherence)
- [x] Create DoctorAlertsNotifier (state: list of alerts with severity)
- [x] Wire patient_management_page.dart to DoctorPatientsNotifier (uses real provider)
- [x] Wire alerts_page.dart to DoctorAlertsNotifier (uses real provider)
- [x] Implement generate doctor code via DoctorCodeRepository
- [x] Implement mark alert as resolved via AlertRepository
- [x] Implement patient detail view from doctor perspective

### 1.2 Build Verification

- [ ] Run flutter analyze and fix all warnings/errors
- [ ] Run flutter build apk --debug to verify compilation
- [ ] Test auth flow end-to-end (login, dashboard, logout)
- [ ] Test patient registration with doctor code
- [ ] Verify all route navigation functions correctly
- [ ] Verify role-based redirect works (patient cannot access doctor routes)

### 1.3 Chatbot OpenAI Integration

File: lib/presentation/pages/patient/chatbot_page.dart

- [x] Add HTTP call to OpenAI Chat Completions API (uses http package)
- [x] Implement _sendMessage() with system prompt
- [x] Send conversation history as context (last 20 messages)
- [x] Save assistant response to database via ChatbotRepository
- [x] Handle error states: network error, invalid key (fallback message if no API key)
- [x] Add typing indicator while waiting for response
- [x] Store OpenAI API key via environment variable (AppConfig.openaiApiKey)

---

## Phase 2: High Priority (Core Experience)

### 2.1 Notification System

Files: lib/services/notification_service.dart

- [x] Complete flutter_local_notifications setup (Android channel, iOS permissions)
- [x] Request notification permissions (Android + iOS)
- [x] Implement scheduleReminderNotification(id, title, body, when)
- [x] Implement cancel(id) for removing scheduled notifications
- [x] Handle notification tap: navigate to relevant page via GoRouter
- [x] Cancel notification when reminder is deleted
- [ ] Background notification handling (onDidReceiveNotificationResponse)

### 2.2 Reminder Full CRUD

File: lib/presentation/providers/feature_providers.dart (RemindersNotifier)

- [x] Implement createReminder() -> insert to Supabase + schedule notification
- [x] Implement updateReminder() -> update in Supabase + reschedule notification
- [x] Implement deleteReminder() -> delete from Supabase + cancel notification
- [x] Mark reminder as completed after scheduled time passes
- [x] Show overdue reminders with visual indicator

### 2.3 Supabase Realtime Subscriptions

- [x] Subscribe to medication_logs table changes (MedicationLogsNotifier._subscribeRealtime)
- [x] Subscribe to alerts table changes (DoctorAlertsNotifier._subscribeRealtime)
- [x] Subscribe to treatments table changes (TreatmentNotifier._subscribeRealtime)
- [ ] Handle reconnection gracefully (auto-resubscribe on network restore)
- [x] Dispose subscriptions on logout/page dispose

### 2.4 Adherence Calculation

- [x] Implement adherence calculation: (taken_count / total_logs) * 100
- [x] Auto-update treatments.adherence_percentage when medication_log is created
- [x] Generate alert to doctor if adherence drops below 60%
- [x] Generate alert if patient misses medication for 2+ consecutive days
- [ ] Display adherence trend (last 7 days, last 30 days)

---

## Phase 3: Polish and Enhancement

### 3.1 Offline Support

- [ ] Setup Hive boxes for cache (treatments, medications, medication_logs)
- [ ] Implement offline-first pattern in repositories (read cache, then fetch remote)
- [ ] Queue offline actions (mark taken/missed) in local storage
- [ ] Sync queued actions when connection restored
- [ ] Show offline indicator in AppBar
- [ ] Use connectivity_plus to detect network state changes

### 3.2 Doctor Analytics Dashboard

- [ ] Create analytics_page.dart in lib/presentation/pages/doctor/
- [ ] Add route /doctor/analytics to app_router.dart
- [ ] Patient adherence trends (line chart, last 30 days)
- [ ] Treatment completion rates (pie chart)
- [ ] Alert frequency by severity (bar chart)
- [ ] Add fl_chart package for charting

### 3.3 Doctor Geographic Map

- [ ] Create doctor_map_page.dart in lib/presentation/pages/doctor/
- [ ] Add route /doctor/map to app_router.dart
- [ ] Display all patient locations on map
- [ ] Cluster markers for performance (when zoom < threshold)
- [ ] Filter markers by adherence level (color-coded)
- [ ] Tap marker to show patient info card

### 3.4 PDF Report Generation

- [ ] Generate treatment summary PDF (patient info, medications, adherence)
- [ ] Generate adherence report PDF (daily log table, statistics)
- [ ] Share/download functionality via printing package
- [ ] Doctor can generate report for any patient

### 3.5 UI/UX Polish

- [ ] Add shimmer loading states on all list pages
- [ ] Add Lottie animations for empty states and success feedback
- [ ] Implement pull-to-refresh on all data list pages
- [ ] Add proper error retry buttons with clear messaging
- [ ] Responsive layout adjustments for tablet screens
- [ ] Add haptic feedback on critical actions

---

## Phase 4: Testing

### 4.1 Unit Tests

- [ ] Test all entities (equality, copyWith, computed properties)
- [ ] Test all models (fromJson, toJson, edge cases)
- [ ] Test repositories with mocked datasource
- [ ] Test StateNotifiers (state transitions, error handling)
- [ ] Test extensions (date, string, number utilities)

### 4.2 Widget Tests

- [ ] Test login page form validation (empty fields, invalid email)
- [ ] Test registration wizard steps (doctor code validation)
- [ ] Test dashboard navigation (all grid items navigate correctly)
- [ ] Test medication mark taken/missed flow
- [ ] Test reminder create dialog (form validation, date/time picker)

### 4.3 Integration Tests

- [ ] Auth flow: register with code, login, see dashboard, logout
- [ ] Patient medication flow: view schedule, mark taken, verify adherence update
- [ ] Doctor patient management: view list, filter, generate code
- [ ] Chatbot conversation: send message, receive response, persist history

---

## Phase 5: Deployment

### 5.1 App Branding

- [ ] Design app icon (all required resolutions)
- [ ] Design splash screen
- [ ] Configure flutter_launcher_icons in pubspec.yaml
- [ ] Configure flutter_native_splash in pubspec.yaml
- [ ] Run icon and splash generation commands

### 5.2 Build Configuration

- [ ] Create Android signing keystore
- [ ] Configure signing in android/app/build.gradle.kts
- [ ] Setup iOS provisioning profiles and certificates
- [ ] Configure ProGuard/R8 rules for release
- [ ] Setup environment configs (dev/staging/prod Supabase URLs)
- [ ] Enable Dart obfuscation for release builds
- [ ] Remove all debug logs and print statements

### 5.3 Store Submission

- [ ] Prepare Play Store listing (title, description, screenshots, feature graphic)
- [ ] Prepare App Store listing (title, description, screenshots, preview)
- [ ] Write privacy policy
- [ ] Write terms of service
- [ ] Declare permissions in store listings (location, notifications)
- [ ] Build signed release APK/AAB
- [ ] Build signed release IPA
- [ ] Submit for review

---

## Phase 6: Post-MVP (Advanced Features)

- [ ] Multi-language support (Bahasa Indonesia, English)
- [ ] Dark mode toggle
- [ ] Accessibility (screen reader labels, high contrast mode)
- [ ] AI adherence insights and predictions
- [ ] Treatment document upload (X-ray images, lab results)
- [ ] Video call integration (doctor-patient telemedicine)
- [ ] Data export (CSV format)
- [ ] Account deletion flow (GDPR/privacy compliance)
- [ ] Rate limiting and abuse prevention
- [ ] Performance monitoring (Sentry or Firebase Crashlytics)
- [ ] WhatsApp contact integration for doctor to reach non-adherent patients

---

## Infrastructure Completed (Reference)

The following are already implemented and should not be re-done:

Core: AppConfig, AppConstants, 12 custom exception types, failure classes, 40+ extensions, Material 3 theme system

Database: 12 tables with relationships, 25+ performance indexes, 40+ RLS policies, timestamp triggers, spatial extensions (cube + earthdistance)

Domain: 11 entities with Equatable, copyWith, computed properties

Data: 13 models with JSON serialization, 50+ Supabase methods in remote datasource, 10 repository classes

Presentation: Auth provider (login/register/logout), doctor code provider, theme provider (role-based), 7 feature StateNotifiers (Treatment, MedicationLogs, Reminders, Locations, ChatbotConversations, ChatbotMessages, DoctorPatients, DoctorAlerts), 10 repository providers, GoRouter with role-based redirect, 11 pages (auth: 2, patient: 6, doctor: 3)

Services: Supabase initialization, notification service (fully implemented with scheduling and cancellation)

Realtime: Supabase stream subscriptions for medication_logs and alerts tables

AI: OpenAI Chat Completions API integration (gpt-4o-mini, with fallback)

Statistics: 12,000+ lines of code, 31 files
