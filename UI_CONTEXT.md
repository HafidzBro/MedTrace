# MedTrace Mobile - UI/UX Context

Dokumen ini adalah sumber arahan visual MedTrace. Mockup referensi berada di `assets/ui` dan harus dipakai sebagai standar layout, komposisi, warna, hierarchy, dan interaction pattern.

Last reviewed: 2026-05-24

## 1. Product Feel

MedTrace harus terasa seperti aplikasi kesehatan modern: bersih, profesional, aman, humanis, dan mudah dibaca oleh pasien maupun tenaga kesehatan. UI tidak boleh terasa seperti demo. Semua angka, nama, jadwal, status, lokasi, dan alert di runtime harus berasal dari Supabase atau state nyata.

Jika data belum ada:
- tampilkan loading state,
- empty state,
- error state,
- retry action,
- atau CTA untuk membuat/melengkapi data.

Jangan mengisi layar dengan dummy data.

## 2. Mockup Reference Inventory

Gunakan asset berikut sebagai referensi utama.

### App

| File | Purpose |
|---|---|
| `assets/ui/app/App_Logo.svg` | Logo and brand mark |

### Begin/Auth

| File | Size | Purpose |
|---|---:|---|
| `assets/ui/begin/Splash Screen.png` | 360x645 | Splash branding |
| `assets/ui/begin/Register Screen.png` | 360x645 | Welcome/register entry |
| `assets/ui/begin/Login Screen.png` | 360x645 | Login screen |

### Doctor

| File | Size | Purpose |
|---|---:|---|
| `assets/ui/doctor/Doctor-Healthcare Worker Dashboard.png` | 422x976 | Doctor dashboard |
| `assets/ui/doctor/Doctor-Patient Management List.png` | 414x1375 | Patient directory |
| `assets/ui/doctor/Doctor-Patient Detail Profile.png` | 394x1903 | Patient detail |
| `assets/ui/doctor/Doctor-Update Therapy Status.png` | 454x910 | Update status modal/bottom sheet |
| `assets/ui/doctor/Doctor-Reminder Monitoring.png` | 414x1786 | Adherence/reminder monitoring |
| `assets/ui/doctor/Doctor-Alert Center.png` | 414x1199 | Alert center |
| `assets/ui/doctor/Doctor-TB Case Distribution Map.png` | 414x895 | TB map |

### Patient

| File | Size | Purpose |
|---|---:|---|
| `assets/ui/patient/Patient Registration - Step 1_ Identity.png` | 394x1216 | Registration identity |
| `assets/ui/patient/Patient Registration - Step 2_ Medical.png` | 394x989 | Registration medical/location |
| `assets/ui/patient/Patient Registration - Step 3_ Treatment.png` | 394x1103 | Registration treatment setup |
| `assets/ui/patient/Registration Confirmation Success.png` | 414x884 | Success confirmation |
| `assets/ui/patient/Patient Home & Summary.png` | 414x917 | Patient home |
| `assets/ui/patient/Patient My Therapy Progress.png` | 414x1562 | Therapy progress |
| `assets/ui/patient/Patient Adherence History.png` | 414x941 | Adherence history |
| `assets/ui/patient/Patient Medication Reminder.png` | 414x901 | Reminder alert |
| `assets/ui/patient/Patient Chat Conversation.png` | 414x893 | Chatbot conversation |
| `assets/ui/patient/Patient Profile.png` | 394x1251 | Patient profile/settings |

## 3. Visual Identity

Brand:
- Name: MedTrace.
- Tone: calm, trusted, medical, supportive.
- Logo: medical cross and lung mark, based on `App_Logo.svg`.

Color tokens:

| Token | Hex | Usage |
|---|---|---|
| Deep Teal | `#00565A` | Primary actions, active nav, brand emphasis |
| Teal | `#0D6F73` | Icons, progress, selected state |
| Mint | `#6DEFD6` | Positive accent |
| Mint Soft | `#E9FFFA` | Active nav background, success tint |
| Navy | `#00436B` | Secondary brand/splash support |
| Background | `#F7F9F9` | Page background |
| Surface | `#FFFFFF` | Cards and sheets |
| Border | `#DDE3E3` | Dividers and inputs |
| Text | `#1E2224` | Primary text |
| Text Muted | `#6F777A` | Metadata/caption |
| Danger | `#C5161D` | Critical risk, missed dose, destructive state |
| Danger Soft | `#FFDAD7` | Critical alert background |
| Warning Soft | `#FFE8D8` | Medium risk |
| Neutral Soft | `#E6EAEA` | Pending/disabled/neutral status |

Rules:
- Red is reserved for clinical risk, missed doses, errors, destructive actions.
- Teal and mint carry normal/positive progress.
- Backgrounds stay light.
- Avoid decorative gradients except splash if matching mockup.

## 4. Typography

Use Roboto by default unless a custom font is added intentionally.

Hierarchy:

| Element | Size | Weight |
|---|---:|---|
| Brand/app title | 18-22 | 700 |
| Page title | 24-32 | 700 |
| Section title | 18-24 | 600-700 |
| Card title | 16-20 | 600 |
| Body | 14-16 | 400 |
| Caption/metadata | 12-13 | 400-500 |
| KPI number | 32-40 | 700 |

Rules:
- Do not use tiny text for medicine, risk, dose, or alert content.
- Avoid viewport-scaled font sizes.
- Text must not overflow buttons/cards.

## 5. Layout System

Primary target:
- Mobile portrait.
- Reference widths: 360, 394, 414, 422 px.
- Content should scale to larger Android phones and tablets without overflow.

Common structure:

```text
Top app bar/header
Scrollable content
Bottom navigation or sticky CTA
```

Spacing:

| Element | Value |
|---|---:|
| Page horizontal padding | 20-28 |
| Section gap | 24-32 |
| Card gap | 14-18 |
| Card padding | 16-24 |
| Card radius | 12-18 |
| Button height | 48-56 |

## 6. Components

Required reusable components:
- `MedTraceHeader`
- `MedTraceBottomNavigation`
- `AppCard`
- `StatusChip`
- `KpiCard`
- `PatientListCard`
- `AlertCard`
- `MedicationCard`
- `TherapyProgressCard`
- `PrimaryButton`
- `SecondaryButton`
- `EmptyState`
- `ErrorRetryState`
- `LoadingSkeleton`

Component behavior:
- Every list page has loading, empty, error, and populated state.
- Every destructive/high-risk action asks for confirmation or notes where appropriate.
- Every API action disables duplicate taps while in progress.
- Pull-to-refresh is expected on data-heavy lists.

## 7. Navigation

Doctor bottom navigation:
1. Dashboard
2. Patients
3. Map
4. Alerts

Patient bottom navigation:
1. Home
2. Progress
3. Reminders
4. Chatbot

Rules:
- Active item uses mint soft background and deep teal icon/text.
- Inactive item uses muted gray.
- Detail pages may hide bottom nav if a sticky CTA is more important.

## 8. Doctor Screens

### Healthcare Worker Dashboard

Data source:
- `profiles`, `doctor_patients`, `treatments`, `alerts`, `medication_logs`.

UI:
- Greeting uses authenticated doctor full name.
- KPI grid: total patients, active treatments, at risk/default risk, recovered/completed.
- Priority follow-ups list comes from real alerts/adherence thresholds.
- CTA to patient directory.

Do not hardcode doctor name, patient counts, or risk counts.

### Patient Directory

Data source:
- assigned patients from `doctor_patients`,
- patient profiles,
- current treatments,
- adherence summary.

UI:
- Search by real name, patient identifier/email/phone if available.
- Filters: all, stable/good, warning, critical.
- Cards show name, status, days on therapy, adherence, last log.

### Patient Detail

Data source:
- `profiles`, `patients`, `treatments`, `medications`, `medication_logs`, `reminders`, `alerts`.

UI:
- Identity summary.
- Diagnosis and therapy status.
- Current phase.
- Medication schedule.
- Adherence/history timeline.
- Sticky `Update Status` action.

### Update Therapy Status

UI:
- Bottom sheet or modal.
- Shows current status.
- Status options: ongoing/on treatment, at risk, completed/recovered, defaulted.
- Notes are required for clinical status changes.
- Save updates Supabase and refreshes detail/dashboard/alerts.

### Reminder/Adherence Monitoring

Data source:
- medication logs, reminders, treatments, alerts.

UI:
- Overall adherence.
- Missed doses today.
- Action required section.
- At-risk patient list.
- Quick filters.

### Alert Center

Data source:
- `alerts`.

UI:
- Severity filters.
- High priority card for critical alerts.
- Alert cards with patient, time, description, and action.
- Resolve/mark action writes to Supabase.

### TB Case Distribution Map

Data source:
- `patient_locations`, `treatments`, `doctor_patients`.

UI:
- Fullscreen map feel.
- Status filters.
- Marker colors by status/adherence.
- Summary bottom sheet.

Location privacy:
- Show only patients assigned to authenticated doctor.
- Do not expose precise location without consent rules.

## 9. Patient Screens

### Splash, Register Entry, Login

Use logo and layout from `assets/ui/begin`.

Login:
- Email/password.
- Real Supabase Auth.
- Error messages for invalid credentials.
- No test credentials shown in UI.

### Registration Step 1: Identity

Fields:
- Full name.
- Email.
- Password.
- Gender.
- Date of birth.
- Phone number.
- Optional national identity field only if privacy/legal handling is defined.

### Registration Step 2: Medical and Location

Fields:
- Diagnosis date.
- TB case category if schema supports it.
- Region/district/address.
- Location permission and map set action.

### Registration Step 3: Treatment Setup

Fields/actions:
- Doctor code.
- Initial status.
- Intake frequency/day schedule if supported by schema.
- Complete registration via Supabase Auth and `complete_patient_registration` RPC.

### Success Confirmation

Use for:
- Dose logged.
- Registration completed.
- Reminder saved if appropriate.

Content must be personalized from current user/session, not mock names.

### Patient Home

Data source:
- current treatment,
- today medication logs,
- reminders,
- adherence summary.

UI:
- Greeting with patient full name.
- Therapy progress.
- Today's medication card.
- Weekly adherence.
- Shortcut to chatbot.

### Therapy Progress

Data source:
- treatment, medication logs, doctor notes if available.

UI:
- Current status.
- Phase explanation.
- Journey/timeline.
- Doctor notes if present.

### Adherence History

Data source:
- `medication_logs`.

UI:
- Weekly summary.
- Daily status chips: pending, taken, missed, skipped.
- Date range and adherence percentage.

### Medication Reminder

Data source:
- `reminders`, `medications`, local notification payload.

UI:
- Fullscreen reminder style.
- Confirm intake action writes to medication log.
- Close/snooze only if behavior is defined.

### Chat Conversation

Data source:
- `chatbot_conversations`, `chatbot_messages`.

UI:
- Header with assistant identity.
- Persistent disclaimer: educational support, not medical advice.
- Chat bubbles.
- Input bar.
- Send button disabled while sending.

Safety:
- Do not diagnose.
- Do not prescribe.
- For urgent symptoms, advise contacting healthcare provider/emergency service.

### Profile

Data source:
- `profiles`, `patients`, assigned doctor/facility if available.

UI:
- Profile card.
- Contact/address.
- Treatment account.
- Notification settings.
- Sign out.
- Account deletion entry point for store compliance.

## 10. Data Binding Rules

Every mockup field must map to one of:
- Supabase table column,
- computed value from real Supabase records,
- authenticated session,
- local notification setting,
- local cache derived from Supabase,
- empty/error/loading copy.

Examples:
- Greeting name: `profiles.full_name`.
- Adherence: computed from `medication_logs` or `treatments.adherence_percentage`.
- Doctor code: `doctor_codes.code`.
- Patient list: `doctor_patients` joined with `profiles`.
- Map markers: `patient_locations`.
- Chat history: `chatbot_messages`.

## 11. Quality of Life Requirements

Add these as UI implementation progresses:
- Pull-to-refresh on dashboard, patient list, alerts, history.
- Search and filter persistence during session.
- Retry buttons on network errors.
- Offline banner.
- Disabled state for in-flight actions.
- Haptic feedback for confirm dose, save, resolve alert.
- Clear permission rationale for location and notifications.
- Timezone-safe display for medication and reminder times.
- Accessibility labels for icon-only buttons.
- Large tap targets, minimum 44x44.

## 12. Do and Don't

Do:
- Follow the mockups closely.
- Use real data.
- Keep hierarchy clear.
- Make risk states obvious.
- Keep patient experience calm and supportive.

Don't:
- Use dummy data in runtime.
- Hide important risk information behind too many taps.
- Make chatbot look like a doctor replacement.
- Use red for normal decoration.
- Leave empty screens blank.
- Ship screenshots that do not match the implemented app.
