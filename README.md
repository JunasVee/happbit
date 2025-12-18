# happbit

HappBit adalah partner digital untuk membangun rutinitas yang lebih sehat dan hidup yang lebih bahagia. Kami percaya kebiasaan kecil yang konsisten adalah kunci menuju kesejahteraan.
Oleh karena itu, Happbit dirancang sebagai pelacak harian all-in-one yang simpel untuk memantau tiga pilar utama kesehatan Anda: mencatat pola makan, memonitor aktivitas olahraga, dan menganalisis kualitas tidur. 

# Tim Pengembang:
Kelompok 4:
- Jonathan Abimanyu Trisno (5026231030)
- Yokanan Prawira Nugroho(5026231032)
- Gabriel Hadi Melvanto Sihaloho (5026231189)
- Jonathan Berlianto (5026231193)
- Arjuna Veetaraq (5026231227)
- Achmad Andi M H (5026231207)
- Muhammad Fikri Khalilullah (5026231198

# Fitur Utama
* **Smart Dashboard**: Ringkasan aktivitas harian dengan status penyelesaian real-time.
* **Interactive Analytics**: Grafik batang mingguan interaktif untuk memantau performa aktivitas secara mendetail.
* **Consistency Heatmap**: Visualisasi intensitas kebiasaan jangka panjang dalam format kalender (ala GitHub).
* **Smart Recommendation**: Saran cerdas berbasis AI-Lite untuk memprioritaskan *habit* yang tertinggal.
* **Gamification**: Animasi *confetti* sebagai apresiasi visual setiap kali pengguna mencapai target harian.
* **Explore & Search**: Akses artikel kesehatan dan tips produktivitas secara instan.

## 📂 Struktur Proyek
Aplikasi ini dibangun menggunakan **Flutter** dengan integrasi **Supabase** sebagai *Backend-as-a-Service*:
```text
happbit/
├── assets/              # Gambar, ikon, dan file konfigurasi .env
├── documentation/       # Laporan, diagram sistem, dan folder release APK
├── lib/
│   ├── services/        # Logika Supabase, Auth, dan manajemen data
│   ├── pages/           # UI Pages (Home, Analytics, Search, Auth)
│   ├── widgets/         # Komponen UI yang dapat digunakan kembali
│   └── main.dart        # Entry point utama aplikasi
└── pubspec.yaml         # Dependensi proyek (fl_chart, heatmap, confetti, dll)
```

# Cara Instalasi (Pengguna / Penguji)
Untuk mencoba aplikasi HappBit secara langsung di perangkat Android tanpa harus melakukan kompilasi kode di laptop:

1. Buka direktori documentation/release/ dalam repository ini.

2. Unduh file app-release.apk.

3. Pindahkan file APK tersebut ke perangkat Android Anda.

4. Instal file tersebut (Berikan izin "Install from Unknown Sources" atau "Instal dari sumber tidak dikenal" jika diminta).

5. Pastikan perangkat terhubung ke internet agar fitur Supabase berfungsi.

# Panduan Developer (Menjalankan dari Source Code)
1. Prasyarat
Instal Flutter SDK versi terbaru.

Memiliki akun Supabase dan proyek yang sudah dikonfigurasi.

2. Langkah Menjalankan
  a. Clone Repository:

git clone [https://github.com/username/happbit.git](https://github.com/username/happbit.git)
  b. Instal Dependensi:

flutter pub get
  c. Setup Environment: Buat file .env di folder root dan masukkan kredensial Supabase Anda (pastikan file .env sudah terdaftar di pubspec.yaml bagian assets):

SUPABASE_URL=[https://your-project-url.supabase.co](https://your-project-url.supabase.co)
SUPABASE_ANON_KEY=your-anon-key
  d. Jalankan Aplikasi:

flutter run

3. Cara Build APK (Rilis)
Jika Anda ingin melakukan build ulang file APK:

flutter build apk --split-per-abi
File hasil build akan berada di build/app/outputs/flutter-apk/.

## Laporan

[Laporan Final Project](https://docs.google.com/document/d/1TMlDd_gPIDpqzK57M5hv6BFlD-pfENoO2-HI0oNzCdg/edit?usp=sharing)
