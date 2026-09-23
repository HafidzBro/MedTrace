# MedTrace Mobile

Aplikasi mobile untuk **Sistem Pemantauan dan Pendampingan Pengobatan Tuberkulosis (MedTrace)**, dibangun dengan **Flutter + Dart + Supabase**.

---

## Tech Stack

| Layer            | Technology                                              |
|------------------|---------------------------------------------------------|
| Framework        | Flutter 3.19+ (Dart SDK >= 3.3.0)                       |
| State Management | Flutter Riverpod (^2.4.1)                              |
| Routing          | GoRouter (^13.0.0)                                     |
| Backend & DB     | Supabase (`supabase_flutter` 2.12.4) — Auth, DB, Storage |
| HTTP Client      | `http` (^1.1.0) & `dio` (^5.3.1)                       |
| Environment      | `flutter_dotenv` (^6.0.1)                              |
| Local Storage    | `shared_preferences`, `hive`, `flutter_secure_storage`   |
| Maps & Location  | `google_maps_flutter`, `flutter_map`, `geolocator`      |
| Notifications    | `flutter_local_notifications`, `timezone`              |
| Linting          | `flutter_lints` (^3.0.0)                                |
| Code Generation  | `build_runner` (^2.4.9), `riverpod_generator`          |

---

## Project Structure

```
lib/
├── core/             <- Konfigurasi global, error handling, & tema
│   ├── config/       <- AppConfig (Supabase URL, Anon Key, feature flags)
│   ├── constants/    <- Konstanta warna, aset, teks, & endpoint
│   ├── error/        <- Custom exception & failure handler
│   └── extensions/   <- Helper extensions (context, date, string)
├── data/             <- Data layer (model, datasource, repository)
│   ├── datasources/  <- Supabase remote query & local cache
│   ├── models/       <- Model data DTO (User, Treatment, MedicationLog, Alert)
│   └── repositories/ <- Implementasi repositori penghubung domain & data
├── presentation/     <- UI layer (pages, providers, widgets)
│   ├── pages/        <- Halaman aplikasi berdasarkan role (Doctor & Patient)
│   │   ├── auth/     <- Login & registrasi bertahap pasien
│   │   ├── doctor/   <- Dashboard dokter, rekam medis pasien, analitik, peta
│   │   └── patient/  <- Dashboard pasien, jadwal minum obat, edukasi chatbot
│   ├── providers/    <- State management dengan Riverpod
│   ├── router/       <- Definisi rute GoRouter & auth redirect policy
│   └── widgets/      <- Komponen UI modular & reusable
├── services/         <- External services (Supabase, Notifikasi, Konektivitas)
└── shared/           <- Tema aplikasi & komponen styling bersama
```

---

## Running Locally

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) >= 3.19.0
- [Dart SDK](https://dart.dev/get-dart) >= 3.3.0
- Android Studio / VS Code dengan ekstensi Flutter & Dart
- Perangkat Android fisik (USB Debugging aktif) atau Android Emulator
- Akun dan project aktif di [Supabase](https://supabase.com)

### Setup

```bash
# 1. Clone repository
git clone <URL_REPOSITORY_ANDA>
cd MedTrace

# 2. Unduh dependencies
flutter pub get

# 3. Salin file environment
cp .env.example .env

# 4. Atur kredensial Supabase di file .env
# Buka file .env dan masukkan SUPABASE_URL serta SUPABASE_ANON_KEY Anda

# 5. Jalankan aplikasi
flutter run
```

---

## Environment Variables

Aplikasi membaca konfigurasi runtime melalui file `.env`. Template konfigurasi tersedia di `.env.example`:

| Variable | Default | Description |
|---|---|---|
| `SUPABASE_URL` | *(Wajib diisi)* | URL endpoint proyek Supabase Anda |
| `SUPABASE_ANON_KEY` | *(Wajib diisi)* | Public Anon / Publishable API Key dari Supabase |
| `ENABLE_LOGGING` | `false` | Menampilkan log detail untuk keperluan debugging |
| `ENABLE_ANALYTICS` | `true` | Mengaktifkan pengumpulan analitik aplikasi |

> **Catatan:** File `.env` sudah didaftarkan pada `.gitignore` agar informasi rahasia tidak ter-commit ke remote repository.

---

## Database Setup (Supabase)

Sebelum menjalankan aplikasi, pastikan database Supabase sudah disiapkan:

1. Buat project baru di [Supabase Dashboard](https://supabase.com/dashboard).
2. Buka **Project Settings** > **API**, salin **Project URL** dan **Anon Key** ke file `.env`.
3. Jalankan file SQL migrasi skema ERD MedTrace yang berada di direktori [`supabase/migrations/`](supabase/migrations) secara berurutan pada menu **SQL Editor** di dashboard Supabase:
   - `20240101000000_init_schema.sql`
   - `20240101000001_rls_policies.sql`
   - `20260507000000_security_hardening.sql`
   - `20260527000000_rebuild_medtrace_erd_schema.sql`
   - `20260528000000_allow_patient_tb_case_registration.sql`
   - `20260528001000_add_tb_case_description.sql`
   - `20260528002000_default_patient_therapy.sql`
   - `20260528003000_add_reminders_created_at.sql`
   - `20260528004000_allow_patient_chatbot_conversation_update.sql`
   - `20260603000000_expand_therapy_status_values.sql`
   - `20260603001000_alert_reset_state.sql`

*(Alternatif: Gunakan Supabase CLI dengan perintah `supabase db push` setelah melakukan `supabase link`)*.

---

## Available Scripts

| Command | Description |
|---|---|
| `flutter pub get` | Mengunduh seluruh dependencies |
| `flutter run` | Menjalankan aplikasi dalam mode Debug |
| `flutter analyze --no-pub` | Menjalankan static analysis linting kode |
| `flutter test` | Menjalankan automated unit & widget tests |
| `flutter build apk --debug` | Membangun installer APK versi Debug |
| `flutter build apk --release` | Membangun installer APK versi Production (Release) |
| `dart run build_runner build` | Menghasilkan kode otomatis (Hive/Riverpod) |

---

## Backend Integration

Seluruh integrasi backend dikelola melalui **Supabase**:
- **Otentikasi & Hak Akses**: Mendukung role ganda (*Patient* & *Doctor*) yang dilindungi oleh PostgreSQL *Row-Level Security (RLS)*.
- **Penyimpanan Terpusat**: Pengaturan koneksi terpusat di `AppConfig` yang secara otomatis membaca konfigurasi dari file `.env`.
- **Offline First**: Menggunakan `Hive` dan `SharedPreferences` untuk caching lokal, sehingga data jadwal dan log obat tetap dapat diakses saat koneksi internet terputus.

---

## License

UNLICENSED (internal project).