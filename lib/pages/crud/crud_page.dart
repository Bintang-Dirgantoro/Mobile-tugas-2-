import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/menu_presets.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import 'crud_form_page.dart';
import 'time_filter_helper.dart';
import 'adjust_stock_dialog.dart';
import 'cashier_view.dart';
import 'summary_view.dart';
import 'widgets/inventory_history_sheet.dart';

/// Halaman Utama Operasional Bisnis & Kasir UMKM (Sistem Warmindo)
/// 
/// Mengintegrasikan 4 modul utama:
/// 1. Kasir Penjualan (POS Warmindo)
/// 2. Katalog Menu & Stok (Master Produk & Mutasi Stok)
/// 3. Riwayat Transaksi (Aplikasi Perbankan dengan Filter Waktu)
/// 4. Ringkasan Penjualan (Sales Summary berdasarkan Periode Waktu)
class CrudPage extends StatefulWidget {
  const CrudPage({super.key});

  @override
  State<CrudPage> createState() => _CrudPageState();
}

class _CrudPageState extends State<CrudPage> {
  final FirestoreService _firestoreService = FirestoreService();

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Filter untuk Tab Katalog Menu
  String _catalogSearchQuery = '';
  String _catalogSelectedCategory = 'Semua';
  final List<String> _catalogCategories = [
    'Semua',
    'Makanan',
    'Minuman',
    'Pakaian',
    'Jasa',
    'Elektronik',
    'Kerajinan',
    'Lainnya'
  ];

  // State Bersama Filter Waktu (Riwayat & Summary)
  TimeFilterPeriod _sharedPeriod = TimeFilterPeriod.today;
  DateTimeRange? _sharedCustomRange;

  void _onPeriodChanged(TimeFilterPeriod period, DateTimeRange? custom) {
    setState(() {
      _sharedPeriod = period;
      _sharedCustomRange = custom;
    });
  }

  bool _isLoadingPreset = false;
  bool _isResettingDatabase = false;

  // Reset Database Firestore (Membersihkan seluruh data tanpa menyentuh Auth)
  Future<void> _resetFirestore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Reset Database?', style: TextStyle(color: AppColors.danger, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aksi ini akan mengosongkan seluruh data di Cloud Firestore:',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Seluruh riwayat transaksi kasir\n• Seluruh catatan mutasi stok\n• Seluruh master menu & produk',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.success, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Akun login (Firebase Auth) Anda TETAP AMAN dan tidak akan terhapus.',
                      style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Ya, Kosongkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isResettingDatabase = true);
    try {
      await _firestoreService.resetFirestoreDatabase(reseedWithPresets: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Database Firestore berhasil dikosongkan!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengosongkan database: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isResettingDatabase = false);
      }
    }
  }

  // Memuat Template Menu Starter Warmindo secara instan ke Firestore
  Future<void> _loadPresetMenu() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Row(
          children: [
            Icon(Icons.download_rounded, color: AppColors.accent),
            SizedBox(width: 8),
            Text('Muat Template Menu?', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
          ],
        ),
        content: Text(
          'Sistem akan menambahkan ${MenuPresets.items.length} item dari "${MenuPresets.templateName}" ke dalam katalog Firestore beserta log mutasi stok awalnya.\n\nLanjutkan?',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Ya, Muat Menu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoadingPreset = true);
    try {
      await _firestoreService.importPresetMenu(MenuPresets.items);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${MenuPresets.items.length} menu dari "${MenuPresets.templateName}" berhasil dimuat!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat template: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingPreset = false);
      }
    }
  }

  // Dialog Konfirmasi Hapus Produk Master
  Future<void> _confirmDeleteProduct(ProductItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Hapus Master Menu?', style: TextStyle(color: AppColors.danger)),
        content: Text(
          'Yakin ingin menghapus "${item.name}" dari katalog?\nData master menu ini tidak akan bisa dipesan lagi.',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteProduct(item.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Menu "${item.name}" berhasil dihapus'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  // Modal Riwayat Mutasi Stok Keseluruhan
  void _showMovementHistoryModal() {
    InventoryHistorySheet.show(context);
  }

  // Tab 2: Katalog Menu & Stok
  Widget _buildCatalogTab(List<ProductItem> allProducts) {
    final items = allProducts.where((p) {
      final matchQuery = p.name.toLowerCase().contains(_catalogSearchQuery);
      final matchCategory = (_catalogSelectedCategory == 'Semua') || (p.category == _catalogSelectedCategory);
      return matchQuery && matchCategory;
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CrudFormPage()),
          );
        },
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Menu Master', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Bar Pencarian & Kategori Katalog
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.card,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Cari master menu...',
                          hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          prefixIcon: const Icon(Icons.search, color: AppColors.accent),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                        ),
                        onChanged: (val) {
                          setState(() => _catalogSearchQuery = val.toLowerCase().trim());
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _catalogCategories.map((cat) {
                      final isSelected = _catalogSelectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: AppColors.accent.withValues(alpha: 0.3),
                          checkmarkColor: AppColors.accent,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.accent : AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          backgroundColor: AppColors.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: isSelected ? AppColors.accent : AppColors.border),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _catalogSelectedCategory = cat);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Daftar Master Menu
          Expanded(
            child: allProducts.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.restaurant_menu,
                              size: 48,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Katalog Menu Masih Kosong',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Database baru saja dikosongkan. Mulai cepat dengan memuat paket menu starter Warmindo atau tambah manual satu per satu.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _isLoadingPreset
                              ? const CircularProgressIndicator(color: AppColors.accent)
                              : ElevatedButton.icon(
                                  onPressed: _loadPresetMenu,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accent,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.download_rounded, color: Colors.white),
                                  label: Text(
                                    'Muat ${MenuPresets.templateName} (${MenuPresets.items.length} Menu)',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Text(
                              '💡 File template dapat Anda edit langsung di:\nlib/data/menu_presets.dart',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : items.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada menu yang sesuai dengan pencarian/filter',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final p = items[index];
                      final isLowStock = p.stock <= 5;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.accent.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              p.category,
                                              style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (isLowStock ? AppColors.danger : AppColors.success).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isLowStock ? 'Stok Kritis: ${p.stock}' : 'Stok: ${p.stock}',
                                              style: TextStyle(
                                                color: isLowStock ? AppColors.danger : AppColors.success,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                                      tooltip: 'Edit Master Menu',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => CrudFormPage(product: p)),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                                      tooltip: 'Hapus Menu',
                                      onPressed: () => _confirmDeleteProduct(p),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: AppColors.border, height: 1),
                            const SizedBox(height: 10),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Harga Jual', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                    Text(_currency.format(p.sellingPrice), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Modal Beli', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                    Text(_currency.format(p.purchasePrice), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Margin Laba', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                    Text(
                                      '+${_currency.format(p.profitPerUnit)} (${p.marginPercentage.toStringAsFixed(1)}%)',
                                      style: TextStyle(
                                        color: p.profitPerUnit >= 0 ? AppColors.success : AppColors.danger,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => AdjustStockDialog.show(context, p),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.accent),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                icon: const Icon(Icons.tune, size: 16, color: AppColors.accent),
                                label: const Text(
                                  'Atur Stok',
                                  style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Operasional Bisnis UMKM'),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.swap_vert),
              tooltip: 'Riwayat Mutasi Stok',
              onPressed: _showMovementHistoryModal,
            ),
            IconButton(
              icon: _isResettingDatabase
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger),
                    )
                  : const Icon(Icons.restart_alt, color: AppColors.danger),
              tooltip: 'Reset Database',
              onPressed: _isResettingDatabase ? null : _resetFirestore,
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(icon: Icon(Icons.point_of_sale_rounded), text: 'Kasir & Transaksi'),
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Katalog & Stok'),
              Tab(icon: Icon(Icons.analytics_outlined), text: 'Ringkasan Bisnis'),
            ],
          ),
        ),
        body: StreamBuilder<List<ProductItem>>(
          stream: _firestoreService.getProductsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.accent));
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off, color: AppColors.danger, size: 48),
                      const SizedBox(height: 12),
                      const Text('Gagal memuat database Firestore',
                          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              );
            }

            final allProducts = snapshot.data ?? [];

            return TabBarView(
              children: [
                CashierView(
                  allProducts: allProducts,
                  selectedPeriod: _sharedPeriod,
                  customRange: _sharedCustomRange,
                  onPeriodChanged: _onPeriodChanged,
                ),
                _buildCatalogTab(allProducts),
                SummaryView(
                  selectedPeriod: _sharedPeriod,
                  customRange: _sharedCustomRange,
                  onPeriodChanged: _onPeriodChanged,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
