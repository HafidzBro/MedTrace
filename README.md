# MedTrace Mobile

MedTrace is a Flutter mobile application for tuberculosis treatment monitoring. It connects patients and doctors through real medication adherence logs, reminders, treatment progress, alerts, maps, and TB education support.

## Current Status

This repository is in active development and is not Play Store ready yet.

Key blockers are tracked in [TODO.md](TODO.md):
- Flutter analyzer currently completes, but reports lint/deprecation cleanup items.
- Debug APK build is verified for the current development baseline.
- Supabase migrations need cleanup because old and timestamped migrations describe conflicting schemas.
- Runtime screens must use Supabase data or explicit loading/empty/error states, not dummy clinical data.

## Main Documents

- [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md): product, architecture, data, and release context.
- [AGENT_CONTEXT.md](AGENT_CONTEXT.md): implementation rules for AI agents/developers.
- [UI_CONTEXT.md](UI_CONTEXT.md): UI/UX direction and `assets/ui` mockup inventory.
- [TODO.md](TODO.md): release roadmap and current blockers.
- [SETUP.md](SETUP.md): local setup notes.

## Development

Use real Supabase configuration from [lib/core/config/app_config.dart](lib/core/config/app_config.dart). Do not add mock clinical data to production code.

```bash
flutter pub get
flutter analyze --no-pub
flutter test
flutter build apk --debug
```

If Flutter commands hang on Windows, see Phase 0 in [TODO.md](TODO.md).
