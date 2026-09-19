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

  // Tipe Kemasan: 'DINE_IN' (Makan di Sini) atau 'TAKE_AWAY' (Bungkus)
  String _orderType = 'DINE_IN';
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

  String get _packagingLabel => _orderType == 'DINE_IN' ? 'Makan di Sini' : 'Bungkus';
  String get _resolvedCustomerName => 'Antrean #$_queueNumber ($_packagingLabel)';

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

  /// Tahan pesanan ke antrean kasir (Tertahan) - Stok TIDAK dipotong
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

      final res = await _firestoreService.createSaleTransaction(
        items,
        customerName: customer,
        orderType: _orderType,
        tableNumber: '',
        queueNumber: _queueNumber,
        status: 'MENUNGGU_PEMBAYARAN',
      );

      if (!mounted) return;
      Navigator.pop(context); // Kembali ke kasir

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pesanan ${res.code} ($customer) berhasil ditahan.'),
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

    PaymentBottomSheet.show(
      context,
      customerName: customer,
      orderType: _orderType,
      tableNumber: '',
      queueNumber: _queueNumber,
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
        title: const Text('Kasir POS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
          // 1. Header Nomor Antrean & Pilihan Kemasan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.card,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Info Antrean Hari Ini
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.confirmation_number_rounded,
                        color: AppColors.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nomor Antrean',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Antrean #$_queueNumber',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Pilihan Kemasan Cepat: Makan di Sini vs Bungkus
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    children: [
                      _buildPackagingChip(
                        title: 'Makan di Sini',
                        icon: Icons.restaurant_rounded,
                        isSelected: _orderType == 'DINE_IN',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _orderType = 'DINE_IN');
                        },
                      ),
                      const SizedBox(width: 4),
                      _buildPackagingChip(
                        title: 'Bungkus',
                        icon: Icons.takeout_dining_rounded,
                        isSelected: _orderType == 'TAKE_AWAY',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _orderType = 'TAKE_AWAY');
                        },
                      ),
                    ],
                  ),
                ),
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

                // Grid Menu Produk (Kotak-Kotak Modern)
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text('Menu tidak ditemukan', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6,
                            childAspectRatio: 0.92,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final p = filtered[index];
                            final inCartQty = _cart[p.id] ?? 0;
                            final isOutOfStock = p.stock <= 0;
                            final isSelected = inCartQty > 0;

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
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
                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('"${p.name}" sudah dipilih ($inCartQty). Ubah jumlah di bawah.'),
                                        backgroundColor: AppColors.card,
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(milliseconds: 1200),
                                      ),
                                    );
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.accent.withValues(alpha: 0.12)
                                        : AppColors.card,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.accent
                                          : (isOutOfStock ? AppColors.border.withValues(alpha: 0.4) : AppColors.border),
                                      width: isSelected ? 1.8 : 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Baris 1: Ikon Kategori & Badge Stok
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            width: 26,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppColors.accent
                                                  : AppColors.accent.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Icon(
                                              _getCategoryIcon(p.category),
                                              color: isSelected ? Colors.white : AppColors.accent,
                                              size: 14,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: (isOutOfStock
                                                      ? AppColors.danger
                                                      : (isSelected ? AppColors.accent : AppColors.background))
                                                  .withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isOutOfStock ? 'Habis' : (isSelected ? '×$inCartQty' : '${p.stock}'),
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: isOutOfStock
                                                    ? AppColors.danger
                                                    : (isSelected ? AppColors.accent : AppColors.textSecondary),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Baris 2: Nama Menu (2 Baris Rapi)
                                      Text(
                                        p.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          height: 1.2,
                                          color: isOutOfStock ? AppColors.textSecondary : AppColors.textPrimary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      // Baris 3: Harga & Status Centang
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _currency.format(p.sellingPrice),
                                              style: TextStyle(
                                                color: isOutOfStock ? AppColors.textSecondary : AppColors.success,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10.5,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 14)
                                          else
                                            Icon(
                                              Icons.add_circle_outline_rounded,
                                              color: isOutOfStock ? AppColors.border : AppColors.accent.withValues(alpha: 0.6),
                                              size: 14,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
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
                                  'Tahan',
                                  style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 13),
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
                                  'Bayar • ${_currency.format(_totalAmount)}',
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

  Widget _buildPackagingChip({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
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
