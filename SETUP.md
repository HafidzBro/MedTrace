# MedTrace - Setup and Installation Guide

## 🚀 Quick Start (5 Minutes)

This guide will help you get MedTrace running on your machine.

## ✅ Prerequisites

### Required
- **Flutter SDK** (3.19.0 or higher)
  - Download from: https://flutter.dev/docs/get-started/install
  - Run `flutter --version` to verify

- **Dart SDK** (included with Flutter, 3.3.0+)
  - Verify with: `dart --version`

- **Supabase Account** (Free tier available)
  - Sign up at: https://supabase.com
  - Create a new project

- **Git**
  - For version control and cloning

### Optional
- **Android Studio** (for Android development)
- **Xcode** (for iOS development on Mac)
- **VS Code or Android Studio** (IDE)

## 📥 Installation Steps

### Step 1: Clone the Repository

```bash
git clone https://github.com/yourusername/medtrace.git
cd medtrace
```

### Step 2: Get Flutter Packages

```bash
flutter pub get
```

This will download all dependencies listed in `pubspec.yaml` (50+ packages).

### Step 3: Setup Supabase

#### Create Supabase Project
1. Go to https://supabase.com and sign in
2. Click "New Project"
3. Fill in project details:
   - Name: `medtrace`
   - Password: Create a secure password
   - Region: Choose closest to your location
4. Wait for project to initialize (2-3 minutes)

#### Get Supabase Credentials
1. Go to Project Settings → API
2. Copy:
   - **Project URL** → `SUPABASE_URL`
   - **anon public** key → `SUPABASE_ANON_KEY`
3. Keep these safe!

#### Run Database Migrations
```bash
# Navigate to supabase directory
cd supabase

# Push migrations to your database
supabase db push

cd ..
```

This will create all 12 tables with proper RLS policies.

### Step 4: Configure App Settings

Update `lib/core/config/app_config.dart`:

```dart
class AppConfig {
  // Supabase Configuration
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  // Other settings
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  // ... rest of config
}
```

### Step 5: Run the App

#### On Android Emulator
```bash
# Start Android emulator first, then:
flutter run
```

#### On iOS Simulator (Mac only)
```bash
flutter run -d "iPhone 15"
```

#### On Physical Device
```bash
# Connect device via USB, then:
flutter run
```

#### On Web (Chrome)
```bash
flutter run -d chrome
```

## 🔐 Supabase Setup Details

### Database Management

The database comes pre-configured with:

**12 Tables:**
- `profiles` - User data
- `doctor_codes` - Patient registration codes
- `doctor_patients` - Doctor-patient relationships
- `treatments` - TB treatment records
- `medications` - Medication prescriptions
- `medication_logs` - Adherence tracking
- `reminders` - Appointment reminders
- `patient_locations` - Geospatial data
- `chatbot_conversations` - Chat history
- `chatbot_messages` - Chat messages
- `alerts` - Doctor alerts
- `notifications` - Push notifications

**Security:**
- ✅ Row-Level Security (RLS) enabled on all tables
- ✅ 40+ RLS policies for role-based access
- ✅ Automated timestamp triggers

### User Roles

The system supports two roles:

**Patient Role:**
- Register via doctor code
- Access own treatment data
- Cannot see other patients' data

**Doctor Role:**
- Created by admin (via database)
- Generate patient codes
- View patient data
- Create alerts

### Creating Test Users

#### Create Patient (via App)
1. Open app
2. Tap "Register as Patient"
3. Enter personal info
4. Create password
5. Enter doctor code (see below)
6. Submit

#### Create Doctor Code
```sql
-- Run in Supabase SQL Editor

INSERT INTO public.doctor_codes (code, doctor_id, expires_at, max_uses, current_uses)
VALUES ('ABC123', 'DOCTOR_UUID', NOW() + INTERVAL '30 days', 1, 0);
```

#### Create Doctor (Admin Only)
```sql
-- 1. First create auth user in Supabase Auth
-- Copy the user UUID

-- 2. Then create profile
INSERT INTO public.profiles (id, email, full_name, role, is_doctor)
VALUES ('DOCTOR_UUID', 'doctor@example.com', 'Dr. John Doe', 'doctor', true);
```

## 🧪 Testing the App

### Test Login Flow
1. **Doctor Code:** `ABC123` (use one you created)
2. **Patient Email:** Patient@example.com
3. **Patient Password:** Test@1234
4. **Doctor Email:** doctor@example.com
5. **Doctor Password:** Doctor@1234

### Key Features to Test

#### Patient Features
- ✅ Login/Registration
- ✅ View Treatment Progress
- ✅ Log Medications
- ✅ Create Reminders
- ✅ View Map
- ✅ Message AI Assistant

#### Doctor Features
- ✅ Login
- ✅ View Patient List
- ✅ Monitor Adherence
- ✅ Generate Patient Codes
- ✅ View Alerts
- ✅ Manage patients

## 🛠️ Development Tools

### Flutter Commands

```bash
# Clean build
flutter clean

# Get latest packages
flutter pub get

# Run with verbose logging
flutter run -v

# Build APK (Android)
flutter build apk

# Build AAB (Android - for Play Store)
flutter build appbundle

# Build iOS
flutter build ios

# Format code
dart format .

# Analyze code
flutter analyze

# Run tests
flutter test
```

### Useful VS Code Extensions
- Flutter
- Dart
- Pubspec Assist
- Supabase
- Material Icon Theme

## 📱 Device Configuration

### Android Permissions
Location: `android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### iOS Permissions
Location: `ios/Runner/Info.plist`

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>MedTrace needs access to your location to map TB distribution</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>MedTrace needs access to your location</string>
```

## 🐛 Troubleshooting

### "Flutter command not found"
```bash
# Add Flutter to PATH
export PATH="$PATH:YOUR_FLUTTER_PATH/bin"

# Verify
flutter --version
```

### "Unable to connect to Supabase"
1. Check `AppConfig` credentials
2. Verify internet connection
3. Check Supabase project status in dashboard
4. Ensure project URL is correct (with https://)

### "Gradle error on Android"
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### "Pod error on iOS"
```bash
# Clean pod cache
cd ios
rm -rf Pods
rm Podfile.lock
cd ..
flutter run
```

### "Package version conflicts"
```bash
# Update pubspec.lock
flutter pub upgrade
```

## 📊 Build Sizes

- **Debug APK**: ~150 MB
- **Release APK**: ~45-50 MB
- **iOS**: ~120 MB (after optimization)

## 🔗 Useful Resources

- **Flutter Docs**: https://flutter.dev/docs
- **Supabase Docs**: https://supabase.com/docs
- **Riverpod Documentation**: https://riverpod.dev
- **GoRouter Documentation**: https://go-router.dev

## 📝 Common Tasks

### Adding a New Package
```bash
flutter pub add package_name
```

### Removing a Package
```bash
flutter pub remove package_name
```

### Updating All Packages
```bash
flutter pub upgrade
```

### Getting Package Info
```bash
flutter pub outdated
```

## 🚀 Next Steps After Setup

1. ✅ Verify app runs without errors
2. ✅ Test login with test credentials
3. ✅ Explore patient features
4. ✅ Explore doctor features
5. ✅ Check data in Supabase dashboard
6. ✅ Review app logs in VS Code terminal

## 💡 Tips

1. **Hot Reload**: Press `r` in terminal to reload app (doesn't restart)
2. **Hot Restart**: Press `R` in terminal to fully restart app
3. **Dart DevTools**: Run `flutter pub global activate devtools` then `devtools`
4. **Debug Logs**: Use `print()` or `Logger.log()` to debug

## 📞 Support

If you encounter issues:
1. Check PROJECT_STATUS.md for known issues
2. Review console output for error messages
3. Check Supabase project logs
4. Verify all credentials are correct
5. Ensure all permissions are granted on device

---

**Setup Time**: ~15-20 minutes  
**Last Updated**: May 2024  
**Status**: Ready to Deploy
