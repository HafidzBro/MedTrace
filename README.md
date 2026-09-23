# MedTrace Mobile

MedTrace is a Flutter mobile application for tuberculosis treatment monitoring. It connects patients and doctors through real medication adherence logs, reminders, treatment progress, alerts, maps, and TB education support.

## Current Status

This repository is in active development.
- Flutter analyzer reports lint/deprecation items.
- Debug APK build is verified.
- Supabase migrations need cleanup because old and timestamped migrations describe conflicting schemas.
- Runtime screens must use Supabase data or explicit loading/empty/error states, not dummy clinical data.

## Development

Use real Supabase configuration from [lib/core/config/app_config.dart](lib/core/config/app_config.dart). Do not add mock clinical data to production code.

```bash
flutter pub get
flutter analyze --no-pub
flutter test
flutter build apk --debug
```
