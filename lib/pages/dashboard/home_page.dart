import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../group/group_page.dart';
import '../computation/computation_page.dart';
import '../crud/crud_page.dart';
import '../calendar/date_conversion_page.dart';
import '../calendar/traditional_calendar_page.dart';
import '../tools/stopwatch_page.dart';
import '../tools/help_logout_page.dart';

/// Halaman Utama Aplikasi Mobile Tugas Kelompok
/// 
/// Struktur:
/// 1. Bottom Navigation Bar terdiri dari 3 tab:
///    - Tab 0: Halaman Utama (Main Dashboard)
///    - Tab 1: Aplikasi Stopwatch
///    - Tab 2: Bantuan & Logout
/// 2. Pada Tab 0 (Halaman Utama), terdapat 5 MENU VERTIKAL yang terletak TEPAT DI TENGAH LAYAR:
///    - Menu 1: Daftar Anggota Kelompok
///    - Menu 2: Komputasi Finansial & Bisnis UMKM
///    - Menu 3: Kelola Produk & Inventaris UMKM (Cloud Firestore CRUD)
///    - Menu 4: Konversi Kalender Hijriah & Kalkulator Umur Presisi (Tahun, Bulan, Hari, Jam, Menit, Detik)
///    - Menu 5: Konversi Kalender Tradisional (Weton Jawa & Saka Bali)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _buildMainDashboard(context),
          const StopwatchPage(),
          const HelpAndLogoutPage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          backgroundColor: AppColors.card,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() => _currentTabIndex = index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Halaman Utama',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.timer_outlined),
              activeIcon: Icon(Icons.timer),
              label: 'Stopwatch',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.help_outline),
              activeIcon: Icon(Icons.help),
              label: 'Bantuan & Akun',
            ),
          ],
        ),
      ),
    );
  }

  /// Tampilan Tab Halaman Utama dengan 5 Menu di Tengah Layar Secara Vertikal
  Widget _buildMainDashboard(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart UMKM & Utilitas'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          // Center & SingleChildScrollView menjamin 5 menu tersusun vertikal tepat di tengah layar
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Mini
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.storefront, color: AppColors.accent, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Menu Utama Aplikasi',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Pilih layanan komputasi & utilitas di bawah',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // 5 MENU VERTIKAL DI TENGAH LAYAR
                // ==========================================

                // MENU 1: DAFTAR ANGGOTA
                _buildVerticalMenuCard(
                  context: context,
                  icon: Icons.groups_outlined,
                  accentColor: AppColors.accent,
                  title: '1. Daftar Anggota',
                  subtitle: 'Data profil 3 anggota kelompok & peran',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const GroupPage()),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // MENU 2: KOMPUTASI SESUAI TEMA
                _buildVerticalMenuCard(
                  context: context,
                  icon: Icons.calculate_outlined,
                  accentColor: AppColors.success,
                  title: '2. Komputasi Finansial UMKM',
                  subtitle: 'Kalkulator laba, margin, diskon & pajak',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ComputationPage()),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // MENU 3: OPERASIONAL BISNIS & KASIR UMKM (WARMINDO SYSTEM)
                _buildVerticalMenuCard(
                  context: context,
                  icon: Icons.store_mall_directory_outlined,
                  accentColor: const Color(0xFF38BDF8), // Sky blue
                  title: '3. Operasional Bisnis & Kasir UMKM',
                  subtitle: 'Kasir POS, master menu, mutasi stok & riwayat penjualan',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CrudPage()),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // MENU 4: KONVERSI HIJRIAH & KALKULATOR UMUR PRESISI
                _buildVerticalMenuCard(
                  context: context,
                  icon: Icons.calendar_month_outlined,
                  accentColor: AppColors.warning,
                  title: '4. Kalender Hijriah & Umur Presisi',
                  subtitle: 'Konversi Hijriah & umur detail hingga detik',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DateConversionPage()),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // MENU 5: KONVERSI WETON & SAKA BALI
                _buildVerticalMenuCard(
                  context: context,
                  icon: Icons.temple_hindu_outlined,
                  accentColor: const Color(0xFFF43F5E), // Rose red
                  title: '5. Kalender Weton & Saka Bali',
                  subtitle: 'Pasaran Jawa, neptu, wuku & kalender Bali',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TraditionalCalendarPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Card Menu Vertikal yang Interaktif dan Rapi
  Widget _buildVerticalMenuCard({
    required BuildContext context,
    required IconData icon,
    required Color accentColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withValues(alpha: 0.4)),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}
