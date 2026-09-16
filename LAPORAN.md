# LAPORAN PEMBUATAN APLIKASI MOBILE (TUGAS 2)
## "Smart UMKM & Utilitas: Aplikasi Manajemen Bisnis, Finansial, dan Penanggalan Tradisional"

---

### IDENTITAS KELOMPOK (KELOMPOK 03)

| No | Nama Mahasiswa | NIM | Peran / Role | Pembagian Tugas (Jobdesk) |
| :---: | :--- | :---: | :--- | :--- |
| 1 | **Pinto Mande Mantofani** | 124240118 | Ketua Kelompok | • Implementasi Autentikasi & Persistent Session (Firebase Auth)<br>• Error Handling Form Login & Validasi Kredensial |
| 2 | **Bintang Dirgantoro Gien** | 124240088 | Anggota | • Logika Komputasi Finansial & Bisnis UMKM<br>• Algoritma Konversi Kalender Hijriah, Umur, Weton & Saka Bali |
| 3 | **Michael Aldo Tri Cahya** | 124230124 | Anggota | • Arsitektur Database Cloud Firestore CRUD<br>• Desain Antarmuka (UI/UX), Tema Gelap Modern, & Bottom Nav Bar |

---

## 1. PENDAHULUAN & LATAR BELAKANG

### 1.1 Deskripsi Aplikasi
Aplikasi **"Smart UMKM & Utilitas"** adalah aplikasi mobile berbasis framework **Flutter** yang dirancang sebagai instrumen all-in-one bagi pelaku Usaha Mikro, Kecil, dan Menengah (UMKM) serta masyarakat umum. Aplikasi ini mengintegrasikan fungsi pencatatan inventaris berbasis cloud database, kalkulator analisis bisnis/keuangan, sistem pencatat waktu kerja, serta utilitas konversi penanggalan multi-sistem (Masehi, Hijriah, Weton Jawa, dan Saka Bali).

### 1.2 Tema Desain (*Theme System*)
Aplikasi mengusung tema **"Modern Emerald Dark UI"** yang terpusat di dalam `lib/theme/app_colors.dart`:
* **Background Utama**: Dark Charcoal (`#0D0D0F`) yang hemat daya pada layar OLED/AMOLED dan nyaman di mata.
* **Surface / Card**: Sleek Charcoal (`#161618`) dengan pembatas border tipis (`#27272A`).
* **Warna Aksen Utama**: Vivid Violet / Purple (`#8B5CF6`) untuk interaksi tombol dan status aktif.
* **Warna Semantik**: Hijau Sukses (`#4ADE80`), Oranye Peringatan (`#FB923C`), dan Merah Bahaya (`#BE0000`).

---

## 2. PEMENUHAN SPESIFIKASI TUGAS

| No | Kriteria Spesifikasi Tugas | Status | Implementasi pada Aplikasi |
| :---: | :--- | :---: | :--- |
| 1 | **Terkoneksi dengan Database** | ✅ Terpenuhi | Menggunakan **Firebase Cloud Firestore** secara realtime untuk penyimpanan data inventaris produk UMKM. |
| 2 | **Memiliki Tema Konsisten** | ✅ Terpenuhi | Seluruh halaman mengacu pada satu konfigurasi tema terpusat (`ThemeData.dark()` & `AppColors`). |
| 3 | **Login dengan Session** | ✅ Terpenuhi | Autentikasi Firebase Auth dengan token sesi persisten; pengguna tetap login saat aplikasi dibuka kembali hingga menekan logout. |
| 4 | **5 Menu Vertikal di Tengah Layar** | ✅ Terpenuhi | Tab Halaman Utama menyusun 5 menu vertikal di tengah layar (`Center` + `SingleChildScrollView` + `Column`). |
| 5 | **Menu Daftar Anggota** | ✅ Terpenuhi | Halaman `GroupPage` memuat identitas 3 anggota, NIM, avatar, badge peran, dan rincian jobdesk. |
| 6 | **Menu Komputasi Sesuai Tema** | ✅ Terpenuhi | Halaman `ComputationPage` memuat kalkulator Margin Laba, Diskon Promo Bertingkat, dan Pajak UMKM (PPN/PPh). |
| 7 | **Menu CRUD Sesuai Tema** | ✅ Terpenuhi | Halaman `CrudPage` & `CrudFormPage` untuk Create, Read, Update, dan Delete produk toko secara online di Firestore. |
| 8 | **Konversi Hijriah & Umur Detail** | ✅ Terpenuhi | Halaman `DateConversionPage` dengan konversi kalender Hijriah dan kalkulator umur detail (Tahun, Bulan, Hari, Jam, Menit, Detik realtime). |
| 9 | **Konversi Weton & Saka Bali** | ✅ Terpenuhi | Halaman `TraditionalCalendarPage` menghitung pasaran, neptu Jawa, watak, serta tahun Saka, wuku pawukon, dan sasih Bali. |
| 10 | **Bottom Navigation Bar (3 Menu)** | ✅ Terpenuhi | Terdiri dari tab Halaman Utama, Aplikasi Stopwatch presisi milidetik, dan Bantuan & Logout. |
| 11 | **Error Handling & Batasan Data** | ✅ Terpenuhi | Validasi input desimal (`double`), sanitasi koma/titik, batas nominal maksimal, proteksi pembagian nol, dan proteksi tanggal masa depan. |

---

## 3. ARSITEKTUR & STRUKTUR DIREKTORI

Struktur direktori menerapkan pola modular berbasis fitur (*Feature-Based Architecture*) agar kode bersih, terpisah sesuai tugasnya (*Separation of Concerns*), dan mudah dipelihara:

```
lib/
├── firebase_options.dart              # Konfigurasi platform Firebase
├── main.dart                          # Inisialisasi Firebase, date locale, & Auth Gate
├── pages/
│   ├── auth/
│   │   └── login_page.dart            # Tampilan form login, validasi & sesi
│   ├── calendar/
│   │   ├── date_conversion_page.dart  # Konversi Hijriah & Kalkulator Umur
│   │   └── traditional_calendar_page.dart # Kalender Weton Jawa & Saka Bali
│   ├── computation/
│   │   └── computation_page.dart      # Kalkulator finansial (Margin, Diskon, Pajak)
│   ├── crud/
│   │   ├── crud_form_page.dart        # Form tambah & edit produk toko
│   │   └── crud_page.dart             # Realtime stream list produk, search, & filter
│   ├── dashboard/
│   │   └── home_page.dart             # 5 Menu vertikal tengah & BottomNavBar
│   ├── group/
│   │   └── group_page.dart            # Profil identitas anggota kelompok
│   └── tools/
│       ├── help_logout_page.dart      # Panduan penggunaan & tombol logout
│       └── stopwatch_page.dart        # Stopwatch digital presisi milidetik
├── services/
│   ├── auth_services.dart             # Wrapper service Firebase Authentication
│   └── firestore_service.dart         # Service operasi Cloud Firestore CRUD
└── theme/
    └── app_colors.dart                # Palet warna desain terpusat
```

---

## 4. PENJELASAN TEKNIS FITUR & RUMUS MATEMATIKA

### 4.1 Autentikasi & Persistent Session
* **Pondasi**: `FirebaseAuth.instance.authStateChanges()` di dalam `StreamBuilder` pada `main.dart`.
* **Alur Sesi**:
  1. Saat aplikasi pertama kali dibuka, `StreamBuilder` mendengarkan apakah ada token sesi user lokal yang valid.
  2. Jika ada (`snapshot.hasData == true`), aplikasi langsung membuka `HomePage` tanpa menampilkan form login.
  3. Saat user menekan tombol Logout di `HelpAndLogoutPage`, fungsi `signOut()` dipanggil, token sesi dihapus, dan `StreamBuilder` otomatis mengembalikan user ke `LoginPage`.

---

### 4.2 Komputasi Finansial & Bisnis UMKM
Menggunakan tipe data `double` untuk mendukung bilangan berkoma/desimal:

1. **Kalkulator Margin & Markup**:
   * **Laba Bersih** = `Harga Jual - Harga Modal`
   * **Margin Penjualan (%)** = `(Laba Bersih / Harga Jual) * 100`
   * **Markup Modal (%)** = `(Laba Bersih / Harga Modal) * 100`
   * **Proteksi Nol**: Jika Harga Jual $\le 0$ atau Modal $\le 0$, hasil margin/markup diatur ke $0.0\%$ untuk mencegah nilai `Infinity` atau `NaN`.

2. **Kalkulator Diskon Bertingkat (Promo UMKM)**:
   * **Harga Setelah Diskon 1** = `Harga Awal - (Harga Awal * (Diskon 1 / 100))`
   * **Harga Akhir** = `Harga Setelah Diskon 1 - (Harga Setelah Diskon 1 * (Diskon 2 / 100))`
   * **Efektif Diskon (%)** = `((Harga Awal - Harga Akhir) / Harga Awal) * 100`

3. **Kalkulator Pajak UMKM**:
   * Opsi 1: PPh Final UMKM sesuai PP 23/2018 ($0.5\%$ dari omzet bruto).
   * Opsi 2: PPN ($11\%$ sesuai tarif UU HPP).
   * **Pajak Terutang** = `Omzet * Tarif`
   * **Penghasilan Bersih (Net)** = `Omzet - Pajak Terutang`

---

### 4.3 Database Cloud Firestore CRUD
* **Koleksi**: `products`
* **Skema Dokumen**:
  * `name` (`String`): Nama produk/jasa (maks 60 karakter).
  * `category` (`String`): Makanan, Minuman, Pakaian, Jasa, Elektronik, Kerajinan, Lainnya.
  * `purchase_price` (`double`): Harga modal barang.
  * `selling_price` (`double`): Harga jual ke konsumen.
  * `stock` (`int`): Jumlah ketersediaan stok unit.
  * `created_at` (`Timestamp`): Waktu server pencatatan.
  * `user_id` (`String`): ID akun Firebase Auth pemilik data.
* **Mekanisme Realtime**: Menggunakan method `snapshots()` dari Firestore, sehingga saat ada data baru, diedit, atau dihapus, tampilan daftar langsung terupdate tanpa perlu reload halaman.

---

### 4.4 Konversi Penanggalan & Kalkulator Umur

#### A. Konversi Kalender Hijriah
Menggunakan konversi astronomis **Julian Day Number (JDN)** dari penanggalan Gregorian (Masehi):
1. Menghitung nilai JDN dari Tanggal, Bulan, dan Tahun Masehi.
2. Mengonversi JDN ke kalender Hijriah Tabular.
3. Menentukan 12 nama bulan Hijriah: Muharram, Safar, Rabi'ul-Awwal, Rabi'ul-Akhir, Jumadil-Awwal, Jumadil-Akhir, Rajab, Sya'ban, Ramadhan, Syawal, Dzulqa'dah, dan Dzulhijjah.

#### B. Kalkulator Umur Detail Presisi Realtime
* Menerima input tanggal lahir dan jam kelahiran.
* Menghitung selisih dengan `DateTime.now()` yang dipecah secara berurutan: **Tahun, Bulan, Hari, Jam, Menit, dan Detik**.
* **Live Ticker**: Menggunakan `Timer.periodic(Duration(seconds: 1))` sehingga satuan **detik bergerak maju secara realtime di layar**.
* Menghitung total hari hidup dan hitung mundur sisa hari menuju ulang tahun berikutnya.

#### C. Konversi Kalender Weton Jawa
* Menggunakan referensi Epoch (1 Januari 1970 = Kamis Pahing).
* Nilai modulus 5 menentukan pasaran: `Pahing (9)`, `Pon (7)`, `Wage (4)`, `Kliwon (8)`, `Legi (5)`.
* Nilai hari Masehi: `Senin (4)`, `Selasa (3)`, `Rabu (7)`, `Kamis (8)`, `Jumat (6)`, `Sabtu (9)`, `Minggu (5)`.
* **Total Neptu** = `Neptu Hari + Neptu Pasaran`.
* Menghitung watak dan wuku berdasarkan total neptu.

#### D. Konversi Kalender Saka Bali
* Tahun Saka = $\text{Tahun Masehi} - 78$ (disesuaikan dengan Sasih Kadasa/Nyepi).
* Menghitung **Saptawara Bali** (Redite, Soma, Anggara, Buda, Wraspati, Sukra, Saniscara).
* Menghitung **Pancawara Bali** (Umanis, Paing, Pon, Wage, Kliwon).
* Menghitung siklus **Pawukon 210 Hari** yang memetakan ke 30 nama Wuku (Sinta s/d Watugunung).
* Menentukan nama **Sasih Bali** (Kasa s/d Sadha).

---

### 4.5 Fitur Utilitas Pendukung (Bottom Navigation Bar)

1. **Aplikasi Stopwatch**:
   * Menggunakan objek bawaan Dart `Stopwatch` yang dipadukan dengan `Timer.periodic` berkecepatan 30 milidetik.
   * Format tampilan digital: `Menit:Detik.RatusanMilidetik` (`MM:SS.ms`).
   * Tombol Start, Pause, Resume, Reset, dan Catat Putaran (*Lap Time*).
   * Membersihkan alokasi memori pada fungsi `dispose()`.
2. **Menu Bantuan & Sesi Akun**:
   * Menampilkan kartu user login aktif (`email`, status koneksi Firebase).
   * Panduan interaktif bertipe *Accordion/ExpansionTile* untuk setiap menu.
   * Tombol Logout dengan dialog konfirmasi keamanan.

---

## 5. PENANGANAN ERROR & VALIDASI TIPE DATA (*ERROR HANDLING*)

| Skenario Potensi Error | Penanganan / Error Handling pada Kode | Tipe Data yang Digunakan |
| :--- | :--- | :---: |
| **Input koma gaya Indonesia** (`15,5`) | Sanitasi string dengan mengganti koma (`,`) menjadi titik (`.`) sebelum parsing: `text.replaceAll(',', '.')`. | `double` |
| **Angka tidak valid / huruf** | Menggunakan `double.tryParse()` dan `int.tryParse()`. Jika menghasilkan `null`, form menampilkan pesan error tanpa membuat aplikasi crash. | `double?` / `int?` |
| **Batas maksimal angka (*Overflow*)** | Nilai uang dibatasi maksimal **Rp 999.999.999.999** (999 Miliar) dan stok dibatasi maksimal **1.000.000 unit**. | `double` / `int` |
| **Persentase tidak logis** | Diskon dibatasi ketat antara $0\%$ s/d $100\%$. Input di luar rentang akan ditolak. | `double` |
| **Pembagian dengan nol (*Zero Division*)** | Validasi pengecekan pembagi (`price > 0` dan `cost > 0`). Menghindari hasil `Infinity` atau `NaN`. | `double` |
| **Tanggal lahir di masa depan** | Pemilih tanggal dibatasi `lastDate: DateTime.now()`. Sistem menolak tanggal lahir yang lebih besar dari waktu saat ini. | `DateTime` |
| **Harga jual lebih kecil dari modal** | Form mendeteksi potensi rugi dan memunculkan dialog konfirmasi apakah user yakin ingin menjual di bawah modal. | `double` |
| **Koneksi internet bermasalah / Auth error** | Exception ditangkap via `try-catch` spesifik `FirebaseAuthException` (contoh: `invalid-credential`, `network-request-failed`). | `String` / Exception |

---

## 6. PENGUJIAN & ANALISIS KODE (*TESTING*)

### 6.1 Uji Statis (*Static Code Analysis*)
Pemeriksaan dilakukan dengan tool resmi Flutter SDK:
```bash
flutter analyze
```
**Hasil Analisis**:
```
Analyzing mobile_tugas2...
No issues found! (ran in 3.6s)
```
Seluruh file kode dinyatakan **100% bebas dari compile error, dead code, lint violation, maupun deprecated API**.

### 6.2 Matriks Pengujian Fungsional (*Black-Box Testing*)

| Kasus Uji | Tindakan / Input | Hasil yang Diharapkan | Status |
| :--- | :--- | :--- | :---: |
| **Autentikasi** | Masukkan email dan password valid | Berhasil login dan langsung masuk ke dashboard utama | **PASS** |
| **Sesi Login** | Tutup total aplikasi lalu buka kembali | Masuk langsung ke dashboard tanpa meminta login ulang | **PASS** |
| **Logout** | Tekan tombol Logout di menu Bantuan | Sesi dihapus, dialihkan ke halaman LoginPage | **PASS** |
| **Layout 5 Menu** | Buka tab Halaman Utama | 5 menu tersusun vertikal tepat di tengah layar | **PASS** |
| **Komputasi Desimal** | Masukkan harga modal `12500,50` dan jual `18000` | Berhasil dihitung tanpa error, menampilkan laba dan margin | **PASS** |
| **Proteksi Nol** | Masukkan harga jual `0` pada margin | Menampilkan margin $0\%$ tanpa crash `Infinity` | **PASS** |
| **CRUD Tambah** | Simpan produk baru di Firestore | Produk langsung muncul di daftar realtime | **PASS** |
| **CRUD Edit & Hapus** | Ubah harga produk dan hapus salah satu produk | Data terupdate dan terhapus dari cloud database | **PASS** |
| **Konversi Hijriah** | Pilih tanggal Masehi sembarang | Menampilkan tanggal, bulan Hijriah, dan hari yang sesuai | **PASS** |
| **Kalkulator Umur** | Masukkan tanggal lahir | Detik bergerak live setiap detik, menampilkan umur lengkap | **PASS** |
| **Weton Jawa & Bali** | Pilih tanggal hari ini | Menampilkan nama hari, pasaran, neptu, wuku, dan tahun Saka | **PASS** |
| **Stopwatch** | Tekan Mulai, Lap, Jeda, dan Reset | Stopwatch berjalan akurat, mencatat putaran waktu | **PASS** |

---

## 7. KESIMPULAN

Aplikasi **"Smart UMKM & Utilitas"** yang dikembangkan oleh **Kelompok 03** telah berhasil memenuhi **100% seluruh kriteria dan spesifikasi tugas**:
1. Terkoneksi penuh dengan database cloud **Firebase Cloud Firestore** secara realtime.
2. Memiliki **tema gelap terpadu** yang konsisten di seluruh antarmuka.
3. Memiliki sistem **autentikasi dan sesi persisten** menggunakan Firebase Auth.
4. Memiliki **5 menu utama yang tersusun vertikal di tengah layar**.
5. Menyediakan fitur komputasi finansial, CRUD database, konversi kalender Hijriah, kalkulator umur detail, serta kalender Weton Jawa dan Saka Bali.
6. Memiliki **Bottom Navigation Bar 3 tab** (Utama, Stopwatch presisi, dan Bantuan & Logout).
7. Menerapkan **error handling dan validasi tipe data yang ketat**, aman, dan logis.
