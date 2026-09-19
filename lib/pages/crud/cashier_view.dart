import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import 'payment_bottom_sheet.dart';
import 'pos_order_page.dart';

/// Tampilan Kasir & Penjualan (Halaman Utama Kasir Mobile)
///
/// Fitur:
/// 1. Default tampilan langsung ke 'Menunggu Bayar' (fokus kasir pada transaksi aktif).
/// 2. Pencarian cepat berdasarkan Nama Pelanggan / Nomor Meja / Nomor Struk.
/// 3. Tombol besar '+ Transaksi Baru' untuk membuka layar POS mobile.
/// 4. Kartu transaksi menampilkan nama pelanggan/meja dengan jelas.
/// 5. Tombol 'Bayar / Lunasi' untuk pelunasan instan via QRIS/Tunai & Gojek Slide to Pay.
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

  final DateFormat _timeFormat = DateFormat('HH:mm', 'id_ID');
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

  // Default tampilan kasir: 'Semua' (dengan penanda khusus jika ada pesanan tertahan)
  String _statusFilter = 'Semua';
  String _searchQuery = '';

  /// Membuka layar POS mobile untuk melayani transaksi baru
  void _openNewTransactionPOS() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PosOrderPage(allProducts: widget.allProducts),
      ),
    );
  }

  /// Dialog konfirmasi pembatalan pesanan tertahan (Stash)
  Future<void> _confirmCancelStashed(TransactionModel trx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pesanan Tertahan?', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
        content: Text(
          'Yakin ingin membatalkan pesanan ${trx.customerName} (${trx.transactionCode})?\n\nKarena transaksi belum dibayar, stok produk tidak terpengaruh.',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Kembali', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Batalkan Pesanan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.cancelStashedTransaction(trx.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pesanan ${trx.customerName} berhasil dibatalkan.'),
            backgroundColor: AppColors.card,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membatalkan: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _showDetailSheet(TransactionModel trx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trx.customerName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${trx.transactionCode} • ${_dateFormat.format(trx.createdAt)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Status Badge & Metode
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (trx.isPaid ? AppColors.success : AppColors.warning).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: trx.isPaid ? AppColors.success : AppColors.warning),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trx.isPaid ? Icons.check_circle : Icons.hourglass_top_rounded,
                          size: 14,
                          color: trx.isPaid ? AppColors.success : AppColors.warning,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          trx.isPaid ? 'LUNAS' : 'MENUNGGU PEMBAYARAN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: trx.isPaid ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trx.isPaid && trx.paymentMethod != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        trx.paymentMethod!,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 14),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 12),

              const Text(
                'Daftar Menu Pesanan:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),

              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: trx.items.length,
                  separatorBuilder: (context, index) => const Divider(color: AppColors.border, height: 1),
                  itemBuilder: (context, index) {
                    final it = trx.items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(it.productName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                Text(
                                  '${_currency.format(it.sellingPrice)} × ${it.quantity} unit',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _currency.format(it.subtotal),
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Tagihan:', style: TextStyle(color: AppColors.textSecondary)),
                  Text(
                    _currency.format(trx.totalAmount),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.success),
                  ),
                ],
              ),

              if (trx.isPending) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      PaymentBottomSheet.show(
                        context,
                        transactionId: trx.id,
                        transactionCode: trx.transactionCode,
                        totalAmount: trx.totalAmount,
                        totalItems: trx.totalItems,
                        items: trx.items,
                        onSettled: () => setState(() {}),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text(
                      'Bayar Sekarang (QRIS / Tunai)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openNewTransactionPOS,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              icon: const Icon(Icons.point_of_sale_rounded, size: 22),
              label: const Text(
                '+ Transaksi Baru (Buka POS)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: _firestoreService.getTransactionsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }

          final allTransactions = snapshot.data ?? [];

          int pendingCount = 0;
          int paidCount = 0;
          double pendingAmount = 0.0;

          for (final t in allTransactions) {
            if (t.isPaid) {
              paidCount++;
            } else {
              pendingCount++;
              pendingAmount += t.totalAmount;
            }
          }

          // Filter berdasarkan status tab ('Semua', 'Tertahan (Stash)', 'Lunas')
          // dan pencarian nama pelanggan / nomor meja / struk
          final displayList = allTransactions.where((t) {
            // Filter Status
            if (_statusFilter == 'Tertahan (Stash)' && !t.isPending) return false;
            if (_statusFilter == 'Lunas' && !t.isPaid) return false;

            // Filter Pencarian
            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              final matchName = t.customerName.toLowerCase().contains(query);
              final matchCode = t.transactionCode.toLowerCase().contains(query);
              final matchTable = t.tableNumber.toLowerCase().contains(query);
              final matchQueue = t.queueNumber.toLowerCase().contains(query);
              return matchName || matchCode || matchTable || matchQueue;
            }
            return true;
          }).toList();

          return Column(
            children: [
              // Header Kasir Bar: Pencarian & Filter Status (Tombol Baru ada di Bawah)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                color: AppColors.card,
                child: Column(
                  children: [
                    // Pencarian Cepat Nama Pelanggan / Nomor Meja / Struk
                    SizedBox(
                      height: 38,
                      child: TextField(
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Cari Meja / Antrean / Struk...',
                          hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          prefixIcon: const Icon(Icons.search, color: AppColors.accent, size: 18),
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                        ),
                        onChanged: (val) {
                          setState(() => _searchQuery = val.trim());
                        },
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Filter Chip Bar: Semua (Default), Tertahan (Stash), Lunas
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('Semua', '${allTransactions.length}'),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Tertahan (Stash)',
                            '$pendingCount',
                            isAlert: pendingCount > 0,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip('Lunas', '$paidCount'),
                        ],
                      ),
                    ),

                    if (pendingCount > 0) ...[
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () {
                          setState(() => _statusFilter = 'Tertahan (Stash)');
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.pause_circle_outline_rounded, color: AppColors.warning, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$pendingCount Pesanan Tertahan (Stash) • ${_currency.format(pendingAmount)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.warning),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: AppColors.warning, size: 12),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Daftar Transaksi Kasir
              Expanded(
                child: displayList.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 60,
                                color: AppColors.textSecondary.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _statusFilter == 'Menunggu Bayar'
                                    ? 'Tidak ada pesanan menunggu bayar'
                                    : 'Tidak ada transaksi yang cocok',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _statusFilter == 'Tertahan (Stash)'
                                    ? 'Tidak ada pesanan tertahan (Stash)'
                                    : 'Tidak ada transaksi yang cocok',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _statusFilter == 'Tertahan (Stash)'
                                    ? 'Semua pesanan tertahan sudah selesai dilunasi atau dibatalkan.'
                                    : 'Tekan tombol "+ Transaksi Baru" di bawah untuk melayani pelanggan.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                        itemCount: displayList.length,
                        itemBuilder: (context, index) {
                          final trx = displayList[index];
                          final isPaid = trx.isPaid;
                          final itemsSummary = trx.items.map((it) => '${it.productName} ×${it.quantity}').join(', ');

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isPaid ? AppColors.border : AppColors.warning.withValues(alpha: 0.7),
                                width: isPaid ? 1 : 1.5,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _showDetailSheet(trx),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row 1: Tipe Pesanan & Status Badge
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              trx.isTakeAway ? Icons.takeout_dining_rounded : Icons.restaurant_rounded,
                                              size: 18,
                                              color: AppColors.accent,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              trx.displayIdentifier,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            if (trx.isTakeAway) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: AppColors.background,
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: AppColors.border),
                                                ),
                                                child: const Text('Bungkus', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: (isPaid ? AppColors.success : AppColors.warning).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isPaid
                                                ? (trx.paymentMethod != null ? 'LUNAS (${trx.paymentMethod})' : 'LUNAS')
                                                : 'TERTAHAN (STASH)',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isPaid ? AppColors.success : AppColors.warning,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 6),

                                    // Row 2: Nomor Struk & Waktu
                                    Row(
                                      children: [
                                        Text(
                                          trx.transactionCode,
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('•', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                        const SizedBox(width: 8),
                                        Text(
                                          _timeFormat.format(trx.createdAt),
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    // Row 3: Rincian Menu Pesanan
                                    Text(
                                      itemsSummary,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                    ),

                                    const SizedBox(height: 12),
                                    const Divider(color: AppColors.border, height: 1),
                                    const SizedBox(height: 10),

                                    // Row 4: Total Tagihan & Aksi Lunasi / Batal
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Total Tagihan (${trx.totalItems} item)',
                                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                            ),
                                            Text(
                                              _currency.format(trx.totalAmount),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: isPaid ? AppColors.success : AppColors.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),

                                        if (trx.isPending)
                                          Row(
                                            children: [
                                              // Tombol Batal Stash (Tanpa efek ke stok karena belum dipotong)
                                              OutlinedButton(
                                                onPressed: () => _confirmCancelStashed(trx),
                                                style: OutlinedButton.styleFrom(
                                                  side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
                                                  foregroundColor: AppColors.danger,
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  minimumSize: Size.zero,
                                                ),
                                                child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                              ),
                                              const SizedBox(width: 8),
                                              // Tombol Bayar Sekarang (Memotong Stok saat sukses)
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  PaymentBottomSheet.show(
                                                    context,
                                                    transactionId: trx.id,
                                                    transactionCode: trx.transactionCode,
                                                    customerName: trx.customerName,
                                                    orderType: trx.orderType,
                                                    tableNumber: trx.tableNumber,
                                                    queueNumber: trx.queueNumber,
                                                    totalAmount: trx.totalAmount,
                                                    totalItems: trx.totalItems,
                                                    items: trx.items,
                                                    onSettled: () => setState(() {}),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF10B981), // Green Pay
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                icon: const Icon(Icons.payments_outlined, size: 16),
                                                label: const Text(
                                                  'Bayar',
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          )
                                        else
                                          Row(
                                            children: [
                                              const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                                              const SizedBox(width: 4),
                                              Text(
                                                trx.paymentMethod ?? 'Lunas',
                                                style: const TextStyle(
                                                  color: AppColors.success,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
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
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String count, {bool isAlert = false}) {
    final isSelected = _statusFilter == label;

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.3)
                  : (isAlert ? AppColors.warning : AppColors.background),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : (isAlert ? Colors.black : AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
      selectedColor: AppColors.accent,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? AppColors.accent : AppColors.border),
      ),
      onSelected: (val) {
        if (val) {
          setState(() => _statusFilter = label);
        }
      },
    );
  }
}
