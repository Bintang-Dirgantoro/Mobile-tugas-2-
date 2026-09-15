import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_services.dart';
import '../theme/app_colors.dart';
import 'login_page.dart';

/// Halaman Bantuan Penggunaan & Logout (Bottom Nav Tab 3)
/// 
/// Fitur:
/// 1. Informasi status sesi login saat ini (Email user, UID, status sesi).
/// 2. Panduan interaktif cara penggunaan seluruh menu aplikasi.
/// 3. Tombol Logout dengan dialog konfirmasi untuk membersihkan sesi Firebase Auth.
class HelpAndLogoutPage extends StatelessWidget {
  const HelpAndLogoutPage({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Konfirmasi Logout', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari sesi aplikasi ini?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final authService = AuthService();
      await authService.logout();

      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bantuan & Sesi Akun'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card Info Sesi Login
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                    child: const Icon(Icons.person, color: AppColors.accent, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sesi Pengguna Aktif',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'Pengguna Tamu',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Sesi Login Terhubung (Firebase)',
                              style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Panduan Penggunaan
            const Text(
              'Panduan Penggunaan Fitur Aplikasi',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            _buildHelpAccordion(
              icon: Icons.groups_outlined,
              title: '1. Menu Daftar Anggota',
              description:
                  'Menampilkan data identitas 3 anggota kelompok (Ketua & Anggota), Nomor Induk Mahasiswa (NIM), dan rincian pembagian peran (jobdesk) masing-masing.',
            ),
            _buildHelpAccordion(
              icon: Icons.calculate_outlined,
              title: '2. Menu Komputasi Finansial UMKM',
              description:
                  'Menghitung analisis keuangan usaha mikro:\n'
                  '• Tab Margin & Laba: Menghitung laba bersih, % margin penjualan, dan markup harga modal.\n'
                  '• Tab Diskon: Menghitung diskon promo bertingkat (contoh: 50% + 20%) secara akurat.\n'
                  '• Tab Pajak UMKM: Menghitung PPh Final 0.5% (PP 23) atau PPN 11%.',
            ),
            _buildHelpAccordion(
              icon: Icons.storage_outlined,
              title: '3. Menu CRUD Produk UMKM',
              description:
                  'Fitur pengelolaan data inventaris toko yang terhubung langsung ke Cloud Firestore:\n'
                  '• Tambah: Menambah produk dengan input nama, kategori, harga modal, harga jual, dan stok.\n'
                  '• Lihat: Menampilkan daftar produk secara realtime dengan fitur pencarian dan filter kategori.\n'
                  '• Edit: Memperbarui informasi produk dan stok barang.\n'
                  '• Hapus: Menghapus data produk dengan konfirmasi keamanan.',
            ),
            _buildHelpAccordion(
              icon: Icons.calendar_month_outlined,
              title: '4. Menu Kalender Hijriah & Umur',
              description:
                  '• Kalender Hijriah: Mengonversi tanggal Masehi ke kalender Hijriah (Tahun, Nama Bulan, dan Hari).\n'
                  '• Kalkulator Umur: Menghitung selisih usia secara presisi hingga satuan detik yang bergerak realtime, total hari hidup, dan hitung mundur ulang tahun berikutnya.',
            ),
            _buildHelpAccordion(
              icon: Icons.temple_hindu_outlined,
              title: '5. Menu Weton & Saka Bali',
              description:
                  '• Weton Jawa: Menghitung kombinasi 7 hari Masehi dan 5 pasaran Jawa (Legi, Pahing, Pon, Wage, Kliwon), jumlah total neptu, serta tafsir karakter/watak.\n'
                  '• Saka Bali: Menghitung tahun penanggalan Saka Bali, Saptawara, Pancawara, 30 Wuku Pawukon, dan Sasih Bali.',
            ),
            _buildHelpAccordion(
              icon: Icons.timer_outlined,
              title: '6. Navigasi Bawah: Stopwatch',
              description:
                  'Aplikasi pencatat waktu digital presisi milidetik. Mendukung fungsi Mulai, Jeda, Lanjut, Reset, serta pencatatan putaran (Lap Time).',
            ),
            const SizedBox(height: 24),

            // Tombol Logout
            ElevatedButton.icon(
              onPressed: () => _handleLogout(context),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'Keluar dari Aplikasi (Logout)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpAccordion({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: AppColors.accent),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        iconColor: AppColors.accent,
        collapsedIconColor: AppColors.textSecondary,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            description,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}
