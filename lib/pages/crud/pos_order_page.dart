import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import 'payment_bottom_sheet.dart';

/// Halaman POS Mobile Kasir (Split Vertikal: Atas = Menu, Bawah = Pesanan)
///
/// Fitur:
/// 1. Input Nama Pelanggan / Nomor Meja untuk memudahkan pencarian saat bayar.
/// 2. Setengah Atas Layar: Menu pilihan dengan tombol + dan - yang BESAR.
///    (Mengetuk kartu tidak menambah item, hanya tombol + dan - yang mengubah qty).
/// 3. Setengah Bawah Layar: Pesanan terpilih langsung terlihat secara real-time.
/// 4. Opsi Simpan (Bayar Nanti) dan Tombol Hijau Besar Bayar dengan Gojek Slide.
class PosOrderPage extends StatefulWidget {
  final List<ProductItem> allProducts;

  const PosOrderPage({
    super.key,
    required this.allProducts,
  });

  @override
  State<PosOrderPage> createState() => _PosOrderPageState();
}

class _PosOrderPageState extends State<PosOrderPage> {
  final FirestoreService _firestoreService = FirestoreService();

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Tipe Pesanan: 'DINE_IN' atau 'TAKE_AWAY'
  String _orderType = 'DINE_IN';
  String _selectedTable = 'Meja 1';
  final TextEditingController _customTableController = TextEditingController();
  final List<String> _tableOptions = ['Meja 1', 'Meja 2', 'Meja 3', 'Meja 4', 'Meja 5', 'Meja 6', 'Lesehan'];
  String _queueNumber = '01';

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

  // Keranjang pesanan aktif (key: productId, value: quantity)
  final Map<String, int> _cart = {};
  bool _isSavingPending = false;

  @override
  void initState() {
    super.initState();
    _loadQueueNumber();
  }

  Future<void> _loadQueueNumber() async {
    final next = await _firestoreService.getNextQueueNumber();
    if (mounted) {
      setState(() => _queueNumber = next);
    }
  }

  @override
  void dispose() {
    _customTableController.dispose();
    super.dispose();
  }

  int get _totalItems => _cart.values.fold(0, (sum, q) => sum + q);

  double get _totalAmount {
    double total = 0.0;
    _cart.forEach((id, qty) {
      final match = widget.allProducts.where((p) => p.id == id).firstOrNull;
      if (match != null && qty > 0) {
        total += (match.sellingPrice * qty);
      }
    });
    return total;
  }

  List<TransactionItem> _buildTransactionItems() {
    final List<TransactionItem> items = [];
    _cart.forEach((id, qty) {
      final p = widget.allProducts.where((prod) => prod.id == id).firstOrNull;
      if (p != null && qty > 0) {
        items.add(
          TransactionItem(
            productId: p.id,
            productName: p.name,
            quantity: qty,
            purchasePrice: p.purchasePrice,
            sellingPrice: p.sellingPrice,
            subtotal: p.sellingPrice * qty,
          ),
        );
      }
    });
    return items;
  }

  String get _resolvedCustomerName {
    if (_orderType == 'DINE_IN') {
      final custom = _customTableController.text.trim();
      final table = custom.isNotEmpty ? custom : _selectedTable;
      return '[Dine In] $table';
    } else {
      return '[Take Away] Antrean #$_queueNumber';
    }
  }

  void _addItem(ProductItem product) {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stok "${product.name}" habis!'),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    final currentQty = _cart[product.id] ?? 0;
    if (currentQty >= product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stok "${product.name}" hanya tersisa ${product.stock} unit!'),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _cart[product.id] = currentQty + 1;
    });
  }

  void _removeItem(ProductItem product) {
    final currentQty = _cart[product.id] ?? 0;
    HapticFeedback.lightImpact();
    if (currentQty <= 1) {
      setState(() {
        _cart.remove(product.id);
      });
    } else {
      setState(() {
        _cart[product.id] = currentQty - 1;
      });
    }
  }

  void _clearCart() {
    if (_cart.isEmpty) return;
    setState(() => _cart.clear());
    HapticFeedback.mediumImpact();
  }

  String get _currentTableValue {
    final custom = _customTableController.text.trim();
    return custom.isNotEmpty ? custom : _selectedTable;
  }

  /// Tahan pesanan ke antrean kasir (Stash) - Stok TIDAK dipotong
  Future<void> _stashOrder() async {
    final items = _buildTransactionItems();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 menu pesanan!'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isSavingPending = true);

    try {
      final customer = _resolvedCustomerName;
      final table = _orderType == 'DINE_IN' ? _currentTableValue : '';
      final queue = _orderType == 'TAKE_AWAY' ? _queueNumber : '';

      final res = await _firestoreService.createSaleTransaction(
        items,
        customerName: customer,
        orderType: _orderType,
        tableNumber: table,
        queueNumber: queue,
        status: 'MENUNGGU_PEMBAYARAN', // Stash / Tertahan (stok TIDAK dipotong)
      );

      if (!mounted) return;
      Navigator.pop(context); // Kembali ke kasir

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pesanan ${res.code} ($customer) ditahan (Stash)! Stok belum dipotong.'),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingPending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menahan pesanan: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  /// Langsung bayar pesanan aktif (LUNAS - Stok langsung dipotong atomik)
  void _checkoutOrder() {
    final items = _buildTransactionItems();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 menu pesanan!'), backgroundColor: AppColors.warning),
      );
      return;
    }

    final customer = _resolvedCustomerName;
    final table = _orderType == 'DINE_IN' ? _currentTableValue : '';
    final queue = _orderType == 'TAKE_AWAY' ? _queueNumber : '';

    PaymentBottomSheet.show(
      context,
      customerName: customer,
      orderType: _orderType,
      tableNumber: table,
      queueNumber: queue,
      totalAmount: _totalAmount,
      totalItems: _totalItems,
      items: items,
      onSettled: () {
        if (mounted) {
          Navigator.pop(context); // Kembali ke kasir setelah lunas
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.allProducts.where((p) {
      final matchQuery = p.name.toLowerCase().contains(_searchQuery);
      final matchCategory = (_selectedCategory == 'Semua') || (p.category == _selectedCategory);
      return matchQuery && matchCategory;
    }).toList();

    final cartProducts = widget.allProducts
        .where((p) => _cart.containsKey(p.id) && _cart[p.id]! > 0)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi Baru (Kasir POS)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          if (_cart.isNotEmpty)
            TextButton(
              onPressed: _clearCart,
              child: const Text('Reset', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Column(
        children: [
          // 1. Pemilihan Tipe Pesanan: Dine In vs Take Away
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            color: AppColors.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toggle Tipe Pesanan
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _orderType = 'DINE_IN');
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _orderType == 'DINE_IN'
                                ? AppColors.accent.withValues(alpha: 0.15)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _orderType == 'DINE_IN' ? AppColors.accent : AppColors.border,
                              width: _orderType == 'DINE_IN' ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restaurant_rounded,
                                size: 18,
                                color: _orderType == 'DINE_IN' ? AppColors.accent : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Dine In (Makan di Sini)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _orderType == 'DINE_IN' ? FontWeight.bold : FontWeight.normal,
                                  color: _orderType == 'DINE_IN' ? AppColors.accent : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _orderType = 'TAKE_AWAY');
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _orderType == 'TAKE_AWAY'
                                ? AppColors.accent.withValues(alpha: 0.15)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _orderType == 'TAKE_AWAY' ? AppColors.accent : AppColors.border,
                              width: _orderType == 'TAKE_AWAY' ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.takeout_dining_rounded,
                                size: 18,
                                color: _orderType == 'TAKE_AWAY' ? AppColors.accent : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Take Away (Bungkus)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _orderType == 'TAKE_AWAY' ? FontWeight.bold : FontWeight.normal,
                                  color: _orderType == 'TAKE_AWAY' ? AppColors.accent : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Detail Identifikasi sesuai Tipe Pesanan
                if (_orderType == 'DINE_IN') ...[
                  // Chip Pilihan Meja Cepat
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _tableOptions.map((t) {
                        final isSel = _selectedTable == t && _customTableController.text.isEmpty;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(t),
                            selected: isSel,
                            selectedColor: AppColors.accent.withValues(alpha: 0.25),
                            labelStyle: TextStyle(
                              color: isSel ? AppColors.accent : AppColors.textSecondary,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              fontSize: 11,
                            ),
                            backgroundColor: AppColors.background,
                            side: BorderSide(color: isSel ? AppColors.accent : AppColors.border),
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _selectedTable = t;
                                  _customTableController.clear();
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ] else ...[
                  // Lencana Nomor Antrean Take Away
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.confirmation_number_outlined, size: 16, color: AppColors.accent),
                            const SizedBox(width: 8),
                            Text(
                              'Nomor Antrean: Antrean #$_queueNumber',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Otomatis', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // 2. SETENGAH ATAS: Menu Pilihan (Katalog Produk)
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar & Filter Kategori
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                  color: AppColors.card,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 36,
                        child: TextField(
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Cari menu...',
                            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            prefixIcon: const Icon(Icons.search, color: AppColors.accent, size: 18),
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                          ),
                          onChanged: (val) {
                            setState(() => _searchQuery = val.toLowerCase().trim());
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categories.map((cat) {
                            final isSelected = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: FilterChip(
                                label: Text(cat),
                                selected: isSelected,
                                selectedColor: AppColors.accent.withValues(alpha: 0.25),
                                checkmarkColor: AppColors.accent,
                                labelStyle: TextStyle(
                                  color: isSelected ? AppColors.accent : AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                backgroundColor: AppColors.background,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
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

                // List Menu Produk dengan Tombol + dan - BESAR
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text('Menu tidak ditemukan', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final p = filtered[index];
                            final inCartQty = _cart[p.id] ?? 0;
                            final isOutOfStock = p.stock <= 0;

                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                if (isOutOfStock) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Stok "${p.name}" habis!'),
                                      backgroundColor: AppColors.danger,
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                  return;
                                }
                                if (inCartQty == 0) {
                                  _addItem(p);
                                } else {
                                  // Sudah terpilih, klik lagi TIDAK menambah item (penambahan hanya lewat tombol +/- di bawah)
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('"${p.name}" sudah dipilih. Ubah jumlah via tombol [+] / [-] di panel bawah.'),
                                      backgroundColor: AppColors.card,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(milliseconds: 1500),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: inCartQty > 0 ? AppColors.accent : AppColors.border,
                                    width: inCartQty > 0 ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Icon Kategori
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(_getCategoryIcon(p.category), color: AppColors.accent, size: 20),
                                    ),
                                    const SizedBox(width: 10),

                                    // Detail Produk (Nama, Harga, Sisa Stok)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Text(
                                                _currency.format(p.sellingPrice),
                                                style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                isOutOfStock ? 'Habis' : 'Stok: ${p.stock}',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: isOutOfStock ? AppColors.danger : AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Indikator Select (Hanya Select, tidak ada tombol +/- di bagian atas)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: inCartQty > 0
                                            ? AppColors.accent.withValues(alpha: 0.15)
                                            : (isOutOfStock ? AppColors.background : AppColors.card),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: inCartQty > 0
                                              ? AppColors.accent
                                              : (isOutOfStock ? AppColors.border : AppColors.accent.withValues(alpha: 0.5)),
                                          width: inCartQty > 0 ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (inCartQty > 0) ...[
                                            const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 16),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Terpilih',
                                              style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ] else ...[
                                            Text(
                                              isOutOfStock ? 'Habis' : 'Pilih',
                                              style: TextStyle(
                                                color: isOutOfStock ? AppColors.textSecondary : AppColors.accent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // Divider Pemisah Setengah Atas dan Setengah Bawah
          Container(
            height: 6,
            color: AppColors.background,
          ),

          // 3. SETENGAH BAWAH: Pesanan Terpilih (Tiket Pesanan Aktif)
          Expanded(
            flex: 5,
            child: Container(
              color: AppColors.card,
              child: Column(
                children: [
                  // Header Panel Bawah
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      border: Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long, color: AppColors.accent, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Pesanan Terpilih ($_totalItems Item)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        if (_cart.isNotEmpty)
                          InkWell(
                            onTap: _clearCart,
                            child: const Text('Hapus Semua', style: TextStyle(color: AppColors.danger, fontSize: 11)),
                          ),
                      ],
                    ),
                  ),

                  // List Pesanan Terpilih
                  Expanded(
                    child: cartProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_cart_outlined, size: 38, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                                const SizedBox(height: 6),
                                const Text(
                                  'Belum ada menu yang dipilih.',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'Pilih menu di atas, lalu sesuaikan jumlah dengan tombol [+] dan [-] di sini.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: cartProducts.length,
                            separatorBuilder: (context, index) => const Divider(color: AppColors.border, height: 1),
                            itemBuilder: (context, index) {
                              final p = cartProducts[index];
                              final qty = _cart[p.id] ?? 0;
                              final subtotal = p.sellingPrice * qty;

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                child: Row(
                                  children: [
                                    // Nama Item & Harga Satuan
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_currency.format(p.sellingPrice)} × $qty',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Stepper Qty (+ dan - BESAR Khusus Layar HP)
                                    Row(
                                      children: [
                                        // Tombol Minus Gede
                                        InkWell(
                                          onTap: () => _removeItem(p),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
                                              borderRadius: BorderRadius.circular(8),
                                              color: AppColors.danger.withValues(alpha: 0.1),
                                            ),
                                            child: Icon(
                                              qty == 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
                                              size: 22,
                                              color: AppColors.danger,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          constraints: const BoxConstraints(minWidth: 40),
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: Text(
                                            '$qty',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                                          ),
                                        ),
                                        // Tombol Plus Gede
                                        InkWell(
                                          onTap: () => _addItem(p),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
                                              borderRadius: BorderRadius.circular(8),
                                              color: AppColors.success.withValues(alpha: 0.12),
                                            ),
                                            child: const Icon(Icons.add_rounded, size: 22, color: AppColors.success),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(width: 12),

                                    // Subtotal
                                    Text(
                                      _currency.format(subtotal),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // Footer Aksi Kasir: Total & Tombol Simpan / Bayar
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    decoration: const BoxDecoration(
                      color: AppColors.card,
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Tagihan:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text(
                              _currency.format(_totalAmount),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.success),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            // Tombol Tahan (Stash) - Tanpa Potong Stok
                            Expanded(
                              flex: 2,
                              child: OutlinedButton.icon(
                                onPressed: (_cart.isEmpty || _isSavingPending) ? null : _stashOrder,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.warning),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: _isSavingPending
                                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.warning))
                                    : const Icon(Icons.pause_circle_outline_rounded, color: AppColors.warning, size: 18),
                                label: const Text(
                                  'Tahan (Stash)',
                                  style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Tombol Utama Besar Hijau Bayar Langsung
                            Expanded(
                              flex: 3,
                              child: ElevatedButton.icon(
                                onPressed: _cart.isEmpty ? null : _checkoutOrder,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981), // Green POS
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 2,
                                ),
                                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                                label: Text(
                                  'Bayar Langsung • ${_currency.format(_totalAmount)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'makanan':
        return Icons.restaurant_rounded;
      case 'minuman':
        return Icons.local_cafe_rounded;
      case 'pakaian':
        return Icons.checkroom_rounded;
      case 'elektronik':
        return Icons.devices_rounded;
      default:
        return Icons.fastfood_rounded;
    }
  }
}
