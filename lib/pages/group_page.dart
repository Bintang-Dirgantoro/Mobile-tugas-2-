import 'package:flutter/material.dart';

import 'package:mobile_tugas2/theme/app_colors.dart';

class GroupPage extends StatelessWidget {
  const GroupPage({super.key});

  // ===== HELPER 1: satu item jobdesk (ikon + judul + keterangan) =====
  Widget _jobdeskItem(
    IconData icon,
    Color color,
    String title,
    String subtitle,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===== HELPER 2: satu kartu anggota lengkap =====
  Widget _memberCard({
    required String initial,
    required String name,
    required String nim,
    required String role,
    required Color badgeColor,
    required List<Widget> jobdesks,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Avatar lingkaran dengan inisial
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.accent.withValues(alpha: 0.15),
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Kolom info: nama, NIM, badge role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nim,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    role,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Divider vertikal tipis
          Container(width: 1, height: 56, color: AppColors.border),

          const SizedBox(width: 12),

          // Area jobdesk (1 atau 2 item)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: jobdesks,
          ),

          const SizedBox(width: 4),

          // Chevron di ujung kanan
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {},
        ),
        title: const Text('Data Kelompok'),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // ===== HEADER GRUP =====
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accent),
              ),
              child: const Icon(Icons.group, color: AppColors.accent, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Kelompok 03',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '3 Anggota',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aplikasi Mobile',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            // ===== KARTU ANGGOTA =====
            _memberCard(
              initial: 'P',
              name: 'Pinto Mande Mantofani',
              nim: '124240118',
              role: 'Ketua Kelompok',
              badgeColor: AppColors.accent,
              jobdesks: [
                _jobdeskItem(
                  Icons.lock_outline,
                  AppColors.accent,
                  'Authentication',
                  'Login & Register',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _memberCard(
              initial: 'B',
              name: 'Bintang',
              nim: '124240XXX',
              role: 'Anggota',
              badgeColor: AppColors.textSecondary,
              jobdesks: [
                _jobdeskItem(
                  Icons.calculate_outlined,
                  AppColors.success,
                  'Calculator',
                  'Operasi Matematika',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _memberCard(
              initial: 'M',
              name: 'Michael Aldo Tri Cahya',
              nim: '124230124',
              role: 'Anggota',
              badgeColor: AppColors.textSecondary,
              jobdesks: [
                _jobdeskItem(
                  Icons.palette_outlined,
                  AppColors.warning,
                  'UI Design',
                  'Tampilan Aplikasi',
                ),
                const SizedBox(height: 10),
                _jobdeskItem(
                  Icons.percent,
                  AppColors.danger,
                  'Ganjil Genap',
                  'Fitur Cek Bilangan',
                ),
              ],
            ),
            const SizedBox(height: 32),
            // ===== GESTURE BAR (indikator navigasi mobile) =====
            Container(
              width: 120,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
