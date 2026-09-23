# MedTrace Mobile

Aplikasi mobile untuk ekosistem pemantauan dan pendampingan pengobatan **Tuberkulosis (TBC)**, menghubungkan pasien dan dokter/tenaga medis melalui pencatatan kepatuhan minum obat secara real-time, pengingat otomatis, visualisasi progres pengobatan, peta fasilitas kesehatan, dan asisten edukasi TBC. Dibangun menggunakan **Flutter + Dart + Supabase**.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.19+ (Dart SDK ≥ 3.3.0) |
| State Management | Flutter Riverpod (^2.4.1) |
| Routing & Navigation | GoRouter (^13.0.0) |
| Backend & Database | Supabase (`supabase_flutter` 2.12.4) — Auth, PostgreSQL, Realtime & Storage |
| HTTP & API Client | `http` (^1.1.0) & `dio` (^5.3.1) |
| Local Storage & Cache | `shared_preferences`, `hive`, `flutter_secure_storage` |
| Maps & Location | `google_maps_flutter`, `flutter_map`, `latlong2`, `geolocator`, `geocoding` |
| Notifications | `flutter_local_notifications`, `timezone` |
| UI & Utilities | `flutter_screenutil`, `shimmer`, `lottie`, `cached_network_image`, `intl` |
| Code Generation & Tooling | `build_runner`, `riverpod_generator`, `flutter_lints` |

---

## Project Structure

```
lib/
├── core/                       ← Konfigurasi global, konstanta, & utility error
│   ├── config/                 ← Konfigurasi aplikasi & endpoint Supabase (app_config.dart)
│   ├── constants/              ← Konstanta warna, aset, teks, & endpoint
│   ├── error/                  ← Exception & failure handling
│   └── extensions/             ← Helper extensions (context, date, string)
├── data/                       ← Data layer (model data & komunikasi database)
│   ├── datasources/            ← Remote & local data sources (Supabase client/queries)
│   ├── models/                 ← DTO / Data model (User, Treatment, MedicationLog, Alert)
│   └── repositories/           ← Implementasi repositori penghubung domain & data
├── presentation/               ← Presentation & UI layer
│   ├── pages/                  ← Layar tampilan aplikasi berdasarkan role
│   │   ├── auth/               ← Login, registrasi multi-step pasien & dokter
│   │   ├── doctor/             ← Dashboard dokter, manajemen pasien, analitik, peta & alert
│   │   └── patient/            ← Dashboard pasien, jadwal obat, riwayat kepatuhan, chatbot, pengingat
│   ├── providers/              ← State management (Riverpod providers)
│   ├── router/                 ← Definisi rute GoRouter & auth redirect policy
│   └── widgets/                ← Komponen UI modular & reusable (cards, dialogs, buttons)
├── services/                   ← Integrasi service eksternal (Supabase, Notifikasi, Lokasi)
└── shared/                     ← Tema global, styling, & konstanta bersama
```

---

## Running Locally

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (≥ 3.19.0)
- [Dart SDK](https://dart.dev/get-dart) (≥ 3.3.0)
- Android Studio / VS Code dengan Flutter & Dart extensions
- Android Device fisik (dengan USB Debugging aktif) atau Android Emulator

### Setup

```bash
# 1. Clone repository
git clone https://github.com/HafidzBro/MedTrace_Mobile.git
cd MedTrace_Mobile

# 2. Unduh dependencies
flutter pub get

# 3. (Opsional) Jalankan code generator jika ada perubahan model/provider
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Jalankan aplikasi pada perangkat/emulator yang terhubung
flutter run
```

---

## Configuration & Environment

Konfigurasi koneksi Supabase dan variabel environment diatur terpusat di file [`lib/core/config/app_config.dart`](lib/core/config/app_config.dart):

| Parameter | Keterangan |
|---|---|
| `supabaseUrl` | Endpoint URL Supabase project |
| `supabaseAnonKey` | Anon public API key Supabase |
| `enableLogging` | Flag logging debug (dapat di-override via `--dart-define=ENABLE_LOGGING=true`) |
| `enableAnalytics` | Flag pengumpulan analitik |
| `pageSize` | Standar limit pagination data list |
| `connectionTimeout` | Durasi batas waktu koneksi HTTP |

---

## Available Commands

| Command | Description |
|---|---|
| `flutter pub get` | Mengunduh seluruh package dan dependencies |
| `flutter run` | Menjalankan aplikasi dalam mode Debug |
| `flutter analyze --no-pub` | Menjalankan static analysis linting kode Dart/Flutter |
| `flutter test` | Menjalankan automated unit & widget tests |
| `flutter build apk --debug` | Membangun file installer APK versi Debug |
| `flutter build apk --release` | Membangun file APK production (Release) |
| `flutter pub run build_runner build` | Menghasilkan file generated code (Hive/Riverpod) |

---

## Key Features & User Roles

### 👤 Pasien (Patient)
- **Monitoring Kepatuhan Minum Obat**: Konfirmasi konsumsi obat harian, upload bukti minum obat, dan pemantauan streak kepatuhan.
- **Pengingat Jadwal Obat**: Notifikasi otomatis sesuai jam minum obat pasien.
- **Progress & Riwayat Pengobatan**: Visualisasi fase pengobatan TBC (Fase Intensif & Lanjutan).
- **Asisten Edukasi & Chatbot**: Konsultasi panduan pengobatan dan informasi seputar pencegahan efek samping TBC.
- **Peta Fasilitas Kesehatan**: Menemukan lokasi faskes/puskesmas rujukan terdekat.

### 🩺 Dokter & Tenaga Medis (Doctor)
- **Dashboard Monitoring Terpusat**: Daftar pasien aktif, skor kepatuhan, dan pasien berisiko drop out.
- **Early Warning & Alert System**: Peringatan otomatis jika pasien melewatkan dosis obat berturut-turut.
- **Manajemen & Detail Pasien**: Rekam medis pasien, riwayat kepatuhan, dan penyesuaian regimen obat.
- **Peta Sebaran Pasien**: Pemetaan wilayah pemantauan pasien TBC.
- **Laporan & Analitik**: Statistik kepatuhan kumulatif dan progres kesembuhan.

---

## Architecture & Integration

- **Layered Clean Architecture**: Memisahkan antarmuka (Presentation), manajemen state (Riverpod), abstraksi bisnis (Repositories), dan sumber data (Supabase DataSources).
- **Supabase Backend**: Mengelola otentikasi peran ganda (Pasien & Dokter), Row-Level Security (RLS) PostgreSQL untuk privasi data medis, dan sinkronisasi real-time.
- **Offline-first Capability**: Caching lokal menggunakan Hive dan SharedPreferences untuk memastikan akses data riwayat dan jadwal tetap tersedia saat koneksi internet terbatas.

---

## License

Internal Project — MedTrace Ecosystem.
