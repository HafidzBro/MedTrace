# MedTrace Documentation Index

Use these documents as the current source of truth:

| Document | Purpose |
|---|---|
| [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) | Product scope, architecture, Supabase status, release quality bar |
| [AGENT_CONTEXT.md](AGENT_CONTEXT.md) | Rules for agents/developers working in this repo |
| [UI_CONTEXT.md](UI_CONTEXT.md) | UI/UX direction and mockup inventory from `assets/ui` |
| [TODO.md](TODO.md) | Current roadmap, blockers, and Play Store checklist |
| [SETUP.md](SETUP.md) | Local setup and troubleshooting |

## Important Notes

- Do not rely on missing legacy docs such as `FEATURES.md`, `ARCHITECTURE.md`, `DEVELOPMENT.md`, `QUICK_REFERENCE.md`, or `PROJECT_STATUS.md`; they are not present in this repository.
- Do not use test credentials or fake clinical data in production flows.
- UI mockups in `assets/ui` are visual references only. Runtime values must come from Supabase, authenticated state, local cache of real data, or loading/empty/error states.
- Supabase REST connectivity has been verified for the development endpoint, but auth, RLS, RPC, realtime, and migrations still need real account testing.

## Verification Baseline

Current baseline is recorded in [TODO.md](TODO.md) Phase 0. Re-run these after changes:

```bash
flutter pub get
flutter analyze --no-pub
flutter test
flutter build apk --debug
```
