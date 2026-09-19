import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';

/// Tampilan Kasir / Transaksi Penjualan (POS Warmindo)
class CashierView extends StatefulWidget {
  final List<ProductItem> allProducts;

  const CashierView({
    super.key,
    required this.allProducts,
  });

  @override
  State<CashierView> createState() => _CashierViewState();
}

class _CashierViewState extends State<CashierView> {
  final FirestoreService _firestoreService = FirestoreService();

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  final List<String> _categories = [
    'Semua',
    'Makanan',
    'Minuman',
    'Pakaian',
    'Jasa',
    'Elektronik',
    'Kerajinan',
    'Lainnya'
  ];

  // Keranjang transaksi (key: productId, value: quantity)
  final Map<String, int> _cart = {};
  bool _isCheckingOut = false;

  void _showCheckoutSheet() {
    final cartProducts = widget.allProducts
        .where((p) => _cart.containsKey(p.id) && _cart[p.id]! > 0)
        .toList();

    if (cartProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang belanja masih kosong!'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            double totalAmount = 0.0;
            int totalQty = 0;

            final List<TransactionItem> itemsToSubmit = [];
            for (final p in cartProducts) {
              final qty = _cart[p.id] ?? 0;
              final subtotal = p.sellingPrice * qty;
              totalAmount += subtotal;
              totalQty += qty;

              itemsToSubmit.add(
                TransactionItem(
                  productId: p.id,
                  productName: p.name,
                  quantity: qty,
                  purchasePrice: p.purchasePrice,
                  sellingPrice: p.sellingPrice,
                  subtotal: subtotal,
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shopping_cart_checkout, color: AppColors.accent),
                          SizedBox(width: 8),
                          Text(
                            'Konfirmasi Penjualan',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 12),

                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: cartProducts.length,
                      separatorBuilder: (context, index) => const Divider(color: AppColors.border, height: 1),
                      itemBuilder: (context, index) {
                        final p = cartProducts[index];
                        final qty = _cart[p.id] ?? 0;
                        final subtotal = p.sellingPrice * qty;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                    ),
                                    Text(
                                      '${_currency.format(p.sellingPrice)} × $qty unit',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _currency.format(subtotal),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Belanja ($totalQty item):',
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      Text(
                        _currency.format(totalAmount),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.success),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _isCheckingOut
                        ? null
                        : () async {
                            setSheetState(() => _isCheckingOut = true);
                            setState(() => _isCheckingOut = true);

                            try {
                              final trxCode = await _firestoreService.createSaleTransaction(itemsToSubmit);

                              if (!mounted || !sheetContext.mounted) return;
                              Navigator.pop(sheetContext);

                              setState(() {
                                _cart.clear();
                              });

                              if (!mounted) return;
                              showDialog(
                                context: context,
                                builder: (dialogCtx) => AlertDialog(
                                  backgroundColor: AppColors.card,
                                  title: const Row(
                                    children: [
                                      Icon(Icons.check_circle, color: AppColors.success, size: 28),
                                      SizedBox(width: 10),
                                      Text('Transaksi Berhasil!', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Nomor Struk: $trxCode', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Text('Total Pembayaran: ${_currency.format(totalAmount)}'),
                                      Text('Jumlah Item: $totalQty unit'),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Stok produk otomatis berkurang dan tercatat pada riwayat mutasi inventaris.',
                                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(dialogCtx),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                                      child: const Text('Tutup', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              if (sheetContext.mounted) {
                                setSheetState(() => _isCheckingOut = false);
                              }
                              setState(() => _isCheckingOut = false);

                              if (!mounted) return;
                              showDialog(
                                context: context,
                                builder: (dialogCtx) => AlertDialog(
                                  backgroundColor: AppColors.card,
                                  title: const Row(
                                    children: [
                                      Icon(Icons.error_outline, color: AppColors.danger, size: 26),
                                      SizedBox(width: 8),
                                      Text('Transaksi Gagal', style: TextStyle(color: AppColors.danger)),
                                    ],
                                  ),
                                  content: Text(
                                    e.toString().replaceAll('Exception: ', ''),
                                    style: const TextStyle(color: AppColors.textPrimary),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogCtx),
                                      child: const Text('Mengerti', style: TextStyle(color: AppColors.accent)),
                                    ),
                                  ],
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setState(() => _isCheckingOut = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isCheckingOut
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Bayar & Simpan Transaksi',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.allProducts.where((p) {
      final matchQuery = p.name.toLowerCase().contains(_searchQuery);
      final matchCategory = (_selectedCategory == 'Semua') || (p.category == _selectedCategory);
      return matchQuery && matchCategory;
    }).toList();

    int totalCartQty = 0;
    double totalCartPrice = 0.0;
    _cart.forEach((id, qty) {
      final match = widget.allProducts.where((p) => p.id == id).firstOrNull;
      if (match != null && qty > 0) {
        totalCartQty += qty;
        totalCartPrice += (match.sellingPrice * qty);
      }
    });

    return Stack(
      children: [
        Column(
          children: [
            // Search & Category Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.card,
              child: Column(
                children: [
                  TextField(
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Cari menu pesanan...',
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
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
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
                                setState(() => _selectedCategory = cat);
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

            // List Menu
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text('Tidak ada menu ditemukan', style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, totalCartQty > 0 ? 96 : 16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final p = items[index];
                        final qty = _cart[p.id] ?? 0;
                        final isOutOfStock = p.stock <= 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: qty > 0 ? AppColors.accent : AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.fastfood_outlined, color: AppColors.accent),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _currency.format(p.sellingPrice),
                                      style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: (isOutOfStock ? AppColors.danger : AppColors.accent).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isOutOfStock ? 'Stok Habis' : 'Stok: ${p.stock}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: isOutOfStock ? AppColors.danger : AppColors.accent,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(p.category, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              if (qty > 0)
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove, size: 18, color: AppColors.danger),
                                        onPressed: () {
                                          setState(() {
                                            if (qty > 1) {
                                              _cart[p.id] = qty - 1;
                                            } else {
                                              _cart.remove(p.id);
                                            }
                                          });
                                        },
                                      ),
                                      Text(
                                        '$qty',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 18, color: AppColors.success),
                                        onPressed: () {
                                          if (qty >= p.stock) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Stok "${p.name}" hanya tersedia ${p.stock} unit!'),
                                                backgroundColor: AppColors.warning,
                                              ),
                                            );
                                            return;
                                          }
                                          setState(() {
                                            _cart[p.id] = qty + 1;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ElevatedButton.icon(
                                  onPressed: isOutOfStock
                                      ? null
                                      : () {
                                          setState(() {
                                            _cart[p.id] = 1;
                                          });
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.add_shopping_cart, size: 16),
                                  label: const Text('Pesan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),

        // Floating Cart Summary Bar
        if (totalCartQty > 0)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accent, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.25),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$totalCartQty Menu Dipilih',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        _currency.format(totalCartPrice),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.success),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _showCheckoutSheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
