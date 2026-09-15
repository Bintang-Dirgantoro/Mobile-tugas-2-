import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import 'crud_form_page.dart';

/// Halaman Daftar Produk UMKM (Cloud Firestore CRUD)
/// 
/// Fitur:
/// 1. Create: Tambah produk melalui FloatingActionButton -> CrudFormPage.
/// 2. Read: Realtime stream data dari Firestore dengan indikator loading & empty state.
/// 3. Update: Edit data produk yang sudah ada.
/// 4. Delete: Hapus produk dengan konfirmasi dialog agar tidak terhapus tidak sengaja.
/// 5. Pencarian & Filter: Pencarian nama produk & filter kategori.
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

  String _searchQuery = '';
  String _selectedFilterCategory = 'Semua';

  final List<String> _filterCategories = [
    'Semua',
    'Makanan',
    'Minuman',
    'Pakaian',
    'Jasa',
    'Elektronik',
    'Kerajinan',
    'Lainnya'
  ];

  Future<void> _confirmDelete(ProductItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Hapus Produk?', style: TextStyle(color: AppColors.danger)),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${item.name}" dari database?',
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
            content: Text('Produk "${item.name}" berhasil dihapus'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Produk UMKM (CRUD)'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CrudFormPage()),
          );
        },
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Produk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Bar Pencarian & Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.card,
            child: Column(
              children: [
                TextField(
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Cari produk berdasarkan nama...',
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
                    setState(() => _searchQuery = val.toLowerCase().trim());
                  },
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterCategories.map((cat) {
                      final isSelected = _selectedFilterCategory == cat;
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
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedFilterCategory = cat);
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

          // Daftar Produk Realtime dari Cloud Firestore
          Expanded(
            child: StreamBuilder<List<ProductItem>>(
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
                          Text('${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }

                final allItems = snapshot.data ?? [];

                // Terapkan Filter & Pencarian
                final items = allItems.where((item) {
                  final matchQuery = item.name.toLowerCase().contains(_searchQuery);
                  final matchCategory = (_selectedFilterCategory == 'Semua') ||
                      (item.category == _selectedFilterCategory);
                  return matchQuery && matchCategory;
                }).toList();

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        const Text('Belum ada produk ditemukan',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                        const SizedBox(height: 4),
                        const Text('Klik tombol Tambah Produk di bawah',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildProductCard(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductItem item) {
    final isLowStock = item.stock <= 5;

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
          // Header card: Nama & Kategori
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
                            item.category,
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
                            isLowStock ? 'Stok Kritis: ${item.stock}' : 'Stok: ${item.stock}',
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
              // Menu aksi edit & hapus
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                    tooltip: 'Edit Produk',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CrudFormPage(product: item),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                    tooltip: 'Hapus Produk',
                    onPressed: () => _confirmDelete(item),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),

          // Detail Harga & Margin Keuntungan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Harga Jual', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  Text(
                    _currency.format(item.sellingPrice),
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Modal / Beli', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  Text(
                    _currency.format(item.purchasePrice),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Margin / Unit', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  Text(
                    '+${_currency.format(item.profitPerUnit)} (${item.marginPercentage.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      color: item.profitPerUnit >= 0 ? AppColors.success : AppColors.danger,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
