**LAPORAN PEMBUATAN APLIKASI MOBILE**
**TUGAS 3**
**“Smart UMKM & Utilitas: Aplikasi Manajemen Bisnis, Finansial, dan Penanggalan Tradisional”**
***image***

Disusun oleh:

| Michael Aldo Tri Cahya  | 124230124 |
| ----------------------- | --------- |
| Bintang Dirgantoro Gien | 124240088 |
| Pinto Mande Mantofani   | 124240118 |

**FAKULTAS TEKNIK INDUSTRI**
**JURUSAN INFORMATIKA**
**PROGRAM STUDI SISTEM INFORMASI**
**UNIVERSITAS PEMBANGUNAN NASIONAL “VETERAN” YOGYAKARTA**
**2026**

# BAB I PENDAHULUAN

## 1.1 Latar Belakang

Perkembangan teknologi perangkat bergerak memberikan kemudahan dalam mengintegrasikan berbagai kebutuhan pengguna ke dalam satu aplikasi. Salah satu kebutuhan tersebut adalah pengelolaan aktivitas usaha, perhitungan keuangan, pencatatan data, serta penyediaan informasi penanggalan.
Berdasarkan kebutuhan tersebut, dikembangkan aplikasi Smart UMKM & Utilitas sebagai aplikasi mobile yang mengintegrasikan beberapa fungsi pendukung kegiatan usaha dan utilitas umum. Aplikasi ini dikembangkan menggunakan framework Flutter dengan bahasa pemrograman Dart.
Aplikasi menyediakan beberapa fungsi utama, antara lain pengelolaan data produk menggunakan cloud database, kalkulator keuangan dan bisnis UMKM, sistem autentikasi pengguna, konversi penanggalan, kalkulator umur, serta fitur utilitas berupa stopwatch.

## 1.2 Deskripsi Aplikasi

Smart UMKM & Utilitas merupakan aplikasi mobile yang ditujukan untuk membantu pengguna dalam melakukan pengelolaan data produk, perhitungan finansial sederhana, serta berbagai fungsi utilitas.

1. Autentikasi pengguna.
2. Pengelolaan data produk menggunakan Cloud Firestore.
3. Perhitungan margin dan markup.
4. Perhitungan diskon bertingkat.
5. Perhitungan pajak.
6. Konversi kalender Masehi dan Hijriah.
7. Perhitungan umur secara terperinci.
8. Perhitungan Weton Jawa.
9. Konversi kalender Saka Bali.
10. Stopwatch.
11. Halaman informasi anggota kelompok dan bantuan penggunaan aplikasi.

# BAB II ISI

## 2.1 Perancangan Antarmuka

### 2.1.1 Konsep Tema

Aplikasi menggunakan konsep antarmuka Modern Emerald Dark UI dengan dominasi warna gelap dan aksen ungu. Penggunaan tema yang terpusat bertujuan menjaga konsistensi tampilan pada seluruh halaman aplikasi.
Konfigurasi warna utama disimpan pada lib/theme/app_colors.dart.

- Background: Dark Charcoal (#0D0D0F).
- Surface/Card: Sleek Charcoal (#161618).
- Accent: Vivid Violet/Purple (#8B5CF6).
- Success: Hijau (#4ADE80).
- Warning: Orange (#FB923C).
- Danger: Merah (#BE0000).

Pendekatan tersebut memungkinkan perubahan warna aplikasi dilakukan melalui konfigurasi terpusat sehingga konsistensi tampilan dapat dipertahankan.

## 2.2 Pemenuhan Spesifikasi Tugas

| **No.** | **Kriteria**              | **Implementasi**                                                                                                                          |
| ------- | ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| 1       | Koneksi dengan database   | Menggunakan Firebase Cloud Firestore untuk menyimpan data inventaris produk secara daring dan menyediakan pembaruan data secara realtime. |
| 2       | Tema yang konsisten       | Seluruh halaman menggunakan konfigurasi tema terpusat melalui ThemeData.dark() dan AppColors.                                             |
| 3       | Login dengan session      | Sistem autentikasi menggunakan Firebase Authentication dengan dukungan persistent session.                                                |
| 4       | Lima menu vertikal        | Halaman utama menyediakan lima menu yang disusun secara vertikal menggunakan Center, SingleChildScrollView, dan Column.                   |
| 5       | Daftar anggota kelompok   | Halaman GroupPage menampilkan identitas anggota kelompok, NIM, peran, dan pembagian tugas.                                                |
| 6       | Komputasi sesuai tema     | ComputationPage menyediakan perhitungan margin laba, markup, diskon bertingkat, dan pajak.                                                |
| 7       | CRUD sesuai tema          | CrudPage dan CrudFormPage menyediakan fungsi Create, Read, Update, dan Delete untuk data produk.                                          |
| 8       | Konversi Hijriah dan umur | DateConversionPage menyediakan konversi kalender Hijriah dan perhitungan umur secara terperinci.                                          |
| 9       | Weton dan Saka Bali       | TraditionalCalendarPage menyediakan perhitungan Weton Jawa dan kalender Saka Bali.                                                        |
| 10      | Bottom Navigation Bar     | Aplikasi menyediakan tiga navigasi utama, yaitu halaman utama, stopwatch, dan bantuan/logout.                                             |
| 11      | Error handling            | Aplikasi menerapkan validasi input, penanganan pembagian dengan nol, pembatasan data, dan penanganan kesalahan autentikasi.               |

## 2.3 Arsitektur dan Struktur Direktori

Aplikasi menerapkan struktur modular berdasarkan fitur (feature-based architecture). Pendekatan ini digunakan untuk memisahkan fungsi berdasarkan tanggung jawab masing-masing sehingga kode lebih terorganisasi dan mudah dipelihara.
```text
lib/
├── firebase_options.dart
├── main.dart
├── models/
│   ├── product_model.dart             # Model data master produk & stok
│   └── transaction_model.dart         # Model transaksi penjualan & status
├── pages/
│   ├── auth/
│   │   └── login_page.dart
│   ├── calendar/
│   │   ├── date_conversion_page.dart
│   │   └── traditional_calendar_page.dart
│   ├── computation/
│   │   └── computation_page.dart
│   ├── crud/
│   │   ├── cashier_view.dart          # Tab 1: Kasir & Riwayat Transaksi Terpadu
│   │   ├── crud_page.dart             # Halaman Induk Modul Bisnis (3 Tab)
│   │   ├── pos_order_page.dart        # Layar Kasir POS Pembuatan Pesanan Baru
│   │   ├── time_filter_helper.dart    # Helper bar filter rentang waktu
│   │   └── widgets/
│   │       ├── inventory_history_sheet.dart # Modal audit trail mutasi inventaris
│   │       └── receipt_detail_sheet.dart    # Modal struk/nota digital resmi
│   ├── dashboard/
│   │   └── home_page.dart
│   ├── group/
│   │   └── group_page.dart
│   └── tools/
│       ├── help_logout_page.dart
│       └── stopwatch_page.dart
├── services/
│   ├── auth_services.dart
│   └── firestore_service.dart         # Service operasi Cloud Firestore (CRUD & Batch)
└── theme/
    └── app_colors.dart
```

## 2.4 Implementasi Fitur

### 2.4.1 Autentikasi dan Persistent Session

Sistem autentikasi menggunakan Firebase Authentication. Status autentikasi pengguna dipantau melalui FirebaseAuth.instance.authStateChanges() yang digunakan bersama StreamBuilder pada main.dart.

1. Pengguna membuka aplikasi.
2. Sistem memeriksa status autentikasi pengguna.
3. Apabila terdapat sesi autentik yang masih aktif, pengguna diarahkan ke halaman utama.
4. Apabila tidak terdapat sesi aktif, pengguna diarahkan ke halaman login.
5. Pengguna dapat mengakhiri sesi melalui fungsi logout.
6. Setelah logout berhasil, pengguna dikembalikan ke halaman login.

### 2.4.2 Komputasi Finansial dan Bisnis UMKM

Fitur komputasi menggunakan tipe data double untuk mendukung nilai numerik yang memiliki bagian desimal.

#### *A. Margin dan Markup*

Laba Bersih = Harga Jual − Harga Modal
Margin (%) = (Laba Bersih / Harga Jual) × 100
Markup (%) = (Laba Bersih / Harga Modal) × 100
Sistem melakukan validasi terhadap harga jual dan harga modal untuk menghindari pembagian dengan nilai nol.

#### *B. Diskon Bertingkat*

Diskon 1 merupakan input wajib, sedangkan diskon 2 bersifat opsional (hanya dapat dihitung jika diskon 1 telah diisi).
Harga Setelah Diskon 1 = Harga Awal − (Harga Awal × Diskon 1 / 100)
Harga Akhir = Harga Setelah Diskon 1 − (Harga Setelah Diskon 1 × Diskon 2 / 100)
Diskon Efektif (%) = ((Harga Awal − Harga Akhir) / Harga Awal) × 100

#### *C. Perhitungan Pajak*

Aplikasi menyesuaikan perhitungan Pajak Penghasilan (PPh Final 0,5%) dan status PPN berdasarkan klasifikasi bentuk usaha serta batas omzet tahunan : 

1. Orang pribadi (Perorangan)

Jika Omzet <= Rp 500.000000 : PPh terhutang = 0 (Bebas Pajak)
Jika Rp 500.000.000 < Omzet <= Rp 4.800.000.000 : 
DPP = Omzet - Rp 500.000.000
PPh Terutang = DPP x 0,5%

2. PT Perorangan / Koperasi

Jika Omzet <= Rp 4.800.000.000 : PPh Terutang = Omzet x 0,5%

3. CV / PT Biasa & Omzet > Rp 4.800.000.000

Wajib beralih menggunakan skema PPh normal (Tarif Badan 22% dari laba bersih berdasarkan pembukuan)

4. Ketentuan PPN (Pengusaha Kena Pajak)

Pajak Terutang = Omzet × Tarif Pajak
Penghasilan Bersih = Omzet − Pajak Terutang

## 2.5 Database Cloud Firestore

Aplikasi menggunakan Firebase Cloud Firestore sebagai database untuk menyimpan data produk.
Koleksi yang digunakan adalah: products

| **Field**      | **Tipe Data** | **Keterangan**          |
| -------------- | ------------- | ----------------------- |
| name           | String        | Nama produk atau jasa   |
| category       | String        | Kategori produk         |
| purchase_price | double        | Harga modal             |
| selling_price  | double        | Harga jual              |
| stock          | int           | Jumlah stok             |
| created_at     | Timestamp     | Waktu pencatatan        |
| user_id        | String        | Identitas akun pengguna |

Operasi database mencakup Create untuk menambahkan produk, Read untuk menampilkan data produk, Update untuk mengubah data produk, dan Delete untuk menghapus data produk.
Data ditampilkan menggunakan mekanisme snapshots() sehingga perubahan pada database dapat tercermin pada antarmuka aplikasi secara realtime.

### 2.5.1 Arsitektur 3 Tab Terpadu di `CrudPage`
Untuk meningkatkan efisiensi operasional kasir serta menghilangkan pemisahan halaman yang memicu duplikasi data, modul operasional bisnis pada `lib/pages/crud/crud_page.dart` disusun ke dalam **3 Tab Terpadu**:
1. **Tab 1: Kasir & Transaksi (`CashierView`)**: Menggabungkan pemantauan antrean pesanan yang sedang berjalan dengan arsip riwayat transaksi lunas. Dilengkapi bar filter rentang waktu (`Hari Ini`, `Kemarin`, `7 Hari`, `30 Hari`, `Bulan Ini`, dan `Kustom`) serta filter status transaksi (`Semua`, `Tertahan`, `Lunas`). Pesanan yang berstatus `Tertahan` secara cerdas tidak dibatasi oleh filter waktu agar tidak terlewat oleh kasir.
2. **Tab 2: Katalog & Stok**: Pengelolaan master produk UMKM (tambah, edit, hapus) disertai tombol penyesuaian stok kilat (*quick adjust* `+/-`) yang mencatat riwayat mutasi stok secara otomatis.
3. **Tab 3: Ringkasan Bisnis**: Rekapitulasi performa penjualan berkala yang menampilkan total omzet kotor, estimasi laba bersih (omzet dikurangi HPP), total transaksi, dan daftar produk terlaris (*best seller*).

### 2.5.2 Sistem Kasir Antrean Tunggal Harian & Pembeda Kemasan
Pada antarmuka kasir pembuatan pesanan baru (`lib/pages/crud/pos_order_page.dart`):
1. **Antrean Tunggal Otomatis (Tanpa Meja)**: Mengeliminasi konsep nomor meja fisik restoran yang tidak relevan bagi kedai kopi atau gerai UMKM. Sistem secara otomatis membuat **Nomor Antrean Harian** (`#01`, `#02`, `#03`, dst.) yang dihitung berdasarkan urutan transaksi pada hari kalender yang sama.
2. **Pembeda Kemasan Pesanan**: Disediakan tombol seleksi cepat kemasan pesanan:
   - **`Makan di Sini`**: Untuk hidangan santap di tempat (piring/gelas).
   - **`Bungkus`**: Untuk pesanan bawa pulang (*take away*).
3. **Fleksibilitas Alur Antrean**:
   - **Tombol `Tahan`**: Digunakan jika pelanggan menahan pesanan atau menunggu antrean. Pesanan tersimpan ke database dengan status `held` tanpa memotong kuantitas stok barang.
   - **Tombol `Bayar`**: Langsung membuka lembar konfirmasi pembayaran kasir jika transaksi diselesaikan seketika.

### 2.5.3 Format Penomoran Struk Transaksi: `KYN-DDMMYY-XXX`
Setiap transaksi penjualan kasir secara otomatis diberikan kode struk resmi dengan format:
`KYN-DDMMYY-XXX`
- **`KYN`**: Identitas unit usaha kuliner / UMKM.
- **`DDMMYY`**: Tanggal, bulan, dan 2 digit tahun transaksi (contoh: `190926` untuk 19 September 2026).
- **`XXX`**: Nomor increment urutan transaksi pada tanggal tersebut (contoh: `001`, `002`).
- Contoh nomor struk: **`KYN-190926-001`**.

### 2.5.4 Tampilan Grid Menu 3 Kolom Kompak
Antarmuka katalog produk pada layar kasir dirancang menggunakan **`SliverGrid` 3 Kolom** dengan rasio aspek kompak (`childAspectRatio: 0.78`):
- Memuat foto menu dengan gradient placeholder, nama produk ringkas, harga jual, dan indikator ketersediaan stok fisik (*badge* hijau jika stok tersedia, merah jika stok habis).
- Dilengkapi *badge counter* lingkaran di sudut kartu produk yang secara realtime menampilkan kuantitas item yang telah dipilih ke dalam keranjang.

### 2.5.5 Mekanisme Pelunasan 'Slide to Pay' & Pemotongan Stok Atomik
Untuk mencegah ketidaksengajaan pembayaran ganda (*accidental double submission*):
1. Kasir memilih metode pembayaran: **Tunai** (dengan perhitungan uang kembali instan) atau **QRIS** (dengan kode QR interaktif).
2. Konfirmasi pelunasan dilakukan dengan menggeser slider **`Slide to Pay`** dari kiri ke ujung kanan.
3. Saat digeser, sistem menjalankan **Firestore Transaction** atomik (`lib/services/firestore_service.dart`):
   - Kuantitas stok produk di server dikurangi tepat sesuai jumlah pembelian.
   - Log mutasi keluar secara otomatis dicatat ke riwayat dengan kode `KASIR-OUT`.
   - Transaksi dibatalkan (*rollback*) jika kuantitas stok di server tidak mencukupi.
4. Menampilkan struk belanja digital resmi (`ReceiptDetailSheet`) setelah pembayaran sukses dengan opsi cetak / bagikan nota.

### 2.5.6 Reset Database Murni (0 Data) & Template Starter Menu Tunggal
1. **Reset Database Murni (0 Data)**:
   - Disediakan melalui tombol khusus di Tab Katalog dengan dialog peringatan konfirmasi ganda.
   - Menggunakan mekanisme **Firestore WriteBatch** untuk menghapus seluruh dokumen pada koleksi `products`, `transactions`, dan `inventory_logs` hingga bersih (0 data).
   - **Aman**: Operasi hanya membersihkan dokumen bisnis di Cloud Firestore tanpa menghapus akun pengguna di Firebase Authentication, sehingga kasir tidak ter-logout dari aplikasi.
   - **Murni**: Setelah di-reset, basis data tetap berada dalam keadaan kosong (0 data) tanpa auto-load data awal secara diam-diam.
2. **Tombol Tunggal Template Starter Menu**:
   - Tombol *“Muat Template Menu UMKM”* **hanya muncul satu kali secara eksklusif ketika database dalam keadaan kosong (`empty state`)**.
   - Ketika ditekan, sistem mengunggah 12 produk starter UMKM lengkap dengan HPP, harga jual, kategori, dan stok awal. Setelah termuat, tombol tersebut otomatis menghilang dari antarmuka.

### 2.5.7 Standarisasi Copywriting & Interaksi UX
Seluruh label tombol dan status antarmuka telah distandarisasi untuk menghilangkan keraguan pengguna:
- Menghilangkan tanda garing ganda dan istilah ambigu: status transaksi distandarisasi menggunakan kata pasti **`Tertahan`** (menggantikan kata campuran *held/tertahan/stash*).
- Tombol aksi menggunakan kata kerja tegas: **`Tahan`**, **`Bayar`**, **`Batal`**, dan **`Slide to Pay`**.

### 2.5.8 Skema Data Cloud Firestore Terintegrasi
Data operasional disimpan dalam 3 koleksi Cloud Firestore terintegrasi:

```text
firestore_root/
├── products/ {productId}
│   ├── name: String
│   ├── category: String
│   ├── costPrice: num (HPP)
│   ├── sellingPrice: num (Harga Jual)
│   ├── stock: int
│   ├── imageUrl: String?
│   └── updatedAt: Timestamp
│
├── transactions/ {transactionId}
│   ├── receiptNumber: String ("KYN-190926-001")
│   ├── queueNumber: int (1, 2, ...)
│   ├── orderType: String ("dine_in" / "take_away")
│   ├── items: Array<Map> [{id, name, price, qty, costPrice}]
│   ├── totalAmount: num
│   ├── paymentMethod: String ("cash" / "qris")
│   ├── status: String ("completed" / "held")
│   ├── createdAt: Timestamp
│   └── cashierName: String
│
└── inventory_logs/ {logId}
    ├── productId: String
    ├── productName: String
    ├── changeQty: int (+/-)
    ├── finalStock: int
    ├── reason: String ("KASIR-OUT", "RESTOCK", "MANUAL")
    └── timestamp: Timestamp
```

## 2.6 Konversi Penanggalan dan Kalkulator Umur

### 2.6.1 Konversi Kalender Hijriah

Konversi kalender dilakukan melalui perhitungan Julian Day Number (JDN) untuk mengubah input tanggal Masehi menjadi tanggal Hijriah. Proses konversi meliputi: 

1. Mengambil tanggal Masehi dari pengguna.
2. Menghitung nilai JDN berdasarkan tanggal masehi.
3. Mengonversikan JDN ke dalam sistem kalender hijriah tabular.
4. Menentukan hasil akhir berupa tanggal, bulan, dan tahun hijriah.

Nama bulan yang digunakan mencakup 12 bulan Hijriah, yaitu Muharram, Safar, Rabi'ul-Awwal, Rabi'ul-Akhir, Jumadil-Awwal, Jumadil-Akhir, Rajab, Sya'ban, Ramadhan, Syawal, Dzulqa'dah, dan Dzulhijjah. 

### 2.6.2 Kalkulator Umur

Kalkulator umur menerima tanggal lahir dan waktu kelahiran pengguna. Sistem kemudian menghitung selisih antara waktu kelahiran dengan waktu saat ini.
Hasil perhitungan ditampilkan dalam satuan tahun, bulan, hari, jam, menit, dan detik.
Perubahan nilai detik diperbarui secara berkala menggunakan Timer.periodic(Duration(seconds: 1)).
Sistem juga menyediakan informasi jumlah hari yang telah dijalani serta perhitungan menuju ulang tahun berikutnya.

## 2.7 Kalender Tradisional

Modul kalender tradisional pada `lib/pages/calendar/traditional_calendar_page.dart` menyediakan integrasi penanggalan adat Weton Jawa dan Kalender Saka Bali dengan antarmuka kalender bulanan interaktif.

### 2.7.1 Tata Letak Interaktif & Eliminasi Redundansi Tombol
Antarmuka kalender dirancang secara ergonomis dengan susunan tata letak:
1. **Bagian Atas (Kartu Hasil Rincian)**: Menampilkan hasil konversi komprehensif dari tanggal yang sedang dipilih (Banner Weton/Saka, Total Neptu, Wuku, Analisis Watak, dan Penanda Hari Suci). Ketika pengguna mengetuk tanggal mana pun pada kalender bawah, kartu di bagian atas langsung diperbarui secara realtime.
2. **Bagian Bawah (Grid Kalender Bulanan Penuh)**: Menampilkan kalender 1 bulan penuh (7 kolom: Min s/d Sab) dengan angka Masehi dan nama pasaran Jawa di setiap sel tanggal.
3. **Pemusatan Kontrol Navigasi (Bebas Redundansi)**: Seluruh tombol kontrol tanggal dipusatkan secara tunggal pada baris header card kalender bulanan (tombol panah bulan `<` dan `>`, judul bulan yang dapat ditekan untuk melompat bebas, serta 1 tombol tunggal **`Hari Ini`**). Redundansi tombol pada AppBar dan baris pemisah telah dibersihkan sehingga antarmuka tetap bersih dan intuitif.

### 2.7.2 Weton Jawa & Validasi Anchor Historis
Sistem melakukan perhitungan hari dan pasaran Jawa berdasarkan siklus Saptawara (7 hari) dan Pancawara (5 pasaran):
- **Nilai Neptu Hari (Saptawara)**: Minggu (5), Senin (4), Selasa (3), Rabu (7), Kamis (8), Jumat (6), Sabtu (9).
- **Nilai Neptu Pasaran (Pancawara)**: Legi (5), Pahing (9), Pon (7), Wage (4), Kliwon (8).
- **Total Neptu**: $\text{Total Neptu} = \text{Neptu Hari} + \text{Neptu Pasaran}$.
- **Formula Matematis & Koreksi Epoch**:
  - Acuan Epoch: 1 Januari 1970 secara astronomis adalah **Kamis Wage** (Index 3).
  - Formula: $\text{Index Pasaran} = [(\text{diffDays} + 3) \pmod 5 + 5] \pmod 5$.
  - **Validasi Anchor Historis**: Teruji tepat pada hari Proklamasi Kemerdekaan RI **17 Agustus 1945 (Jumat Legi)** dan **1 Januari 2024 (Senin Pahing)**.
- **Klasifikasi Watak (*Lakuning*)**: Berdasarkan rujukan Kitab Primbon Betaljemur Adakammakna, sistem menjabarkan karakter bawaan berdasarkan neptu (contoh: Neptu 13 = *Lakuning Lintang* yang mandiri dan berjiwa wirausaha; Neptu 14 = *Lakuning Mbulan* yang bijaksana dan pengayom).

### 2.7.3 Kalender Saka Bali, Pawukon & Deteksi Hari Suci
Modul penanggalan Saka Bali menyediakan informasi wewaran lengkap:
- **Tahun Saka**: Dihitung dari formula Masehi $- 78$ tahun (disesuaikan dengan pergantian Sasih Kadasa / Hari Raya Nyepi).
- **Wuku Pawukon (Siklus 210 Hari)**: Menggunakan formula $[(\text{diffDays} + 32) \pmod{210}] / 7$ yang mencakup 30 wuku dari Sinta hingga Watugunung.
- **Unsur Wewaran**: Saptawara Bali (Redite s/d Saniscara), Pancawara Bali (Umanis s/d Kliwon), Triwara (Pasah, Beteng, Kajeng), serta 12 Sasih Bali.
- **Deteksi Otomatis Hari Suci & Rerainan Bali**: Sistem secara otomatis mendeteksi dan menampilkan lencana bintang pada hari perayaan sakral:
  - **Hari Raya Galungan**: Buda (Rabu) Kliwon Dungulan.
  - **Hari Raya Kuningan**: Saniscara (Sabtu) Kliwon Kuningan.
  - **Kajeng Kliwon**: Pertemuan Triwara Kajeng dan Pancawara Kliwon (setiap 15 hari).
  - **Hari Saraswati** (Saniscara Umanis Watugunung), **Pagerwesi** (Buda Kliwon Sinta), dan **Tumpek** (Sabtu Kliwon).
  - Pada grid kalender bulanan, setiap tanggal yang bertepatan dengan hari rerainan suci ditandai dengan dot indikator khusus berwarna emas.

## 2.8 Fitur Utilitas

### 2.8.1 Stopwatch

Stopwatch menggunakan objek Stopwatch bawaan Dart yang dikombinasikan dengan Timer.periodic.
Fitur yang tersedia meliputi Start, Pause, Resume, Reset, dan Lap Time.
Tampilan waktu menggunakan format MM\:SS.ms.
Objek dan timer yang digunakan juga dihentikan atau dibersihkan melalui fungsi dispose() ketika halaman tidak lagi digunakan.

### 2.8.2 Bantuan dan Logout

Halaman bantuan menyediakan informasi mengenai penggunaan fitur aplikasi serta informasi akun yang sedang aktif.
Komponen bantuan menggunakan pola ExpansionTile sehingga pengguna dapat membuka informasi berdasarkan menu yang ingin diketahui.
Fungsi logout menyediakan mekanisme konfirmasi sebelum sesi pengguna diakhiri.

## 2.9 Error Handling dan Validasi

| **Kondisi**                     | **Penanganan**                                                        |
| ------------------------------- | --------------------------------------------------------------------- |
| Input desimal menggunakan koma  | Koma dikonversi menjadi titik sebelum proses parsing.                 |
| Input bukan angka               | Menggunakan double.tryParse() atau int.tryParse().                    |
| Nominal melebihi batas          | Sistem membatasi nilai berdasarkan batas yang telah ditentukan.       |
| Persentase diskon tidak valid   | Nilai dibatasi pada rentang 0%–100%.                                  |
| Pembagian dengan nol            | Sistem melakukan pengecekan nilai pembagi sebelum perhitungan.        |
| Tanggal lahir di masa depan     | Pemilihan tanggal dibatasi sampai tanggal saat ini.                   |
| Harga jual di bawah harga modal | Sistem memberikan peringatan dan meminta konfirmasi pengguna.         |
| Kesalahan autentikasi           | Exception Firebase Authentication ditangani menggunakan try-catch.    |
| Gangguan jaringan               | Sistem menangani kesalahan autentikasi yang berkaitan dengan koneksi. |

## 2.10 Pengujian Sistem (Black-Box Testing)

Pengujian fungsionalitas sistem dilakukan menggunakan metode *Black-Box Testing* untuk memverifikasi kesesuaian operasional aplikasi:

| **Kasus Pengujian** | **Input/Tindakan** | **Hasil yang Diharapkan** | **Status** |
| :--- | :--- | :--- | :---: |
| Autentikasi | Memasukkan kredensial valid | Pengguna berhasil masuk ke halaman utama; sesi login tersimpan persisten | PASS |
| Logout | Menekan tombol logout | Sesi diakhiri dan pengguna diarahkan ke halaman login | PASS |
| Menu Utama | Membuka halaman utama | 5 menu utama ditampilkan secara vertikal | PASS |
| Komputasi Desimal | Memasukkan nilai harga & diskon | Perhitungan margin, markup, dan pajak dilakukan dengan benar | PASS |
| Proteksi Pembagian Nol | Memasukkan nilai pembagi 0 | Sistem mencegah hasil Infinity atau NaN | PASS |
| POS Transaksi Baru | Menekan `+ Transaksi Baru` | Layar kasir terbuka, nomor antrean `#01` terisi otomatis | PASS |
| Pemilihan Menu Kasir | Memilih menu dari grid 3 kolom | Badge kuantitas bertambah dan subtotal belanja terhitung otomatis | PASS |
| Tahan Pesanan | Memilih kemasan 'Bungkus' lalu tekan 'Tahan' | Pesanan masuk antrean tertahan; stok fisik produk tetap utuh | PASS |
| Pelunasan Slide to Pay | Menggeser slider ke kanan | Transaksi lunas, stok terpotong atomik, struk `KYN-DDMMYY-XXX` terbit | PASS |
| Filter Kasir | Memilih filter 'Hari Ini' & 'Lunas' | Hanya menampilkan riwayat transaksi sah pada hari bersangkutan | PASS |
| CRUD Produk | Menambah & mengedit produk | Data tersimpan ke Firestore dan ter-update realtime pada katalog | PASS |
| Quick Adjust Stok | Menekan tombol `+/-` stok | Stok berubah seketika dan riwayat mutasi otomatis tercatat | PASS |
| Reset Database | Konfirmasi reset database | Seluruh produk, transaksi, dan mutasi terhapus (0 data); akun login aman | PASS |
| Template Starter | Klik tombol template saat data kosong | 12 menu starter terunggah; tombol template otomatis hilang | PASS |
| Konversi Hijriah | Memilih tanggal Masehi | Informasi penanggalan Hijriah ditampilkan akurat | PASS |
| Kalkulator Umur | Memasukkan tanggal lahir | Umur detail ditampilkan dengan detik yang berdetak realtime | PASS |
| Weton dan Bali | Memilih tanggal | Hari pasaran, neptu, dan penanggalan Saka Bali ditampilkan tepat | PASS |
| Stopwatch | Start, pause, lap, reset | Stopwatch menjalankan fungsi pengukur waktu presisi milidetik | PASS |

# BAB III PENUTUP

## 3.1 Kesimpulan

Berdasarkan proses perancangan, implementasi, dan pengujian yang telah dilakukan, aplikasi Smart UMKM & Utilitas berhasil mengintegrasikan beberapa fungsi dalam satu aplikasi mobile berbasis Flutter.
Fitur yang berhasil diimplementasikan meliputi autentikasi pengguna menggunakan Firebase Authentication, pengelolaan data produk menggunakan Cloud Firestore, komputasi finansial dan bisnis UMKM, konversi kalender, kalkulator umur, kalender tradisional, stopwatch, serta halaman bantuan dan logout.
Aplikasi juga menerapkan struktur kode modular berdasarkan fitur, konfigurasi tema terpusat, serta mekanisme validasi dan error handling untuk menangani berbagai kondisi input yang tidak valid.
Berdasarkan hasil pengujian yang tercantum dalam laporan, fungsi-fungsi utama aplikasi dapat berjalan sesuai dengan skenario pengujian yang telah ditentukan. Dengan demikian, aplikasi dapat digunakan sebagai implementasi tugas pengembangan aplikasi mobile dengan integrasi database cloud, autentikasi, komputasi, dan fitur utilitas dalam satu sistem.
