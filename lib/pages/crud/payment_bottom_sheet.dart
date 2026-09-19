import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import 'slide_to_pay_button.dart';

/// Bottom Sheet Konfirmasi Pelunasan Transaksi Kasir
/// Mendukung pilihan metode bayar (Tunai & QRIS) serta slider Gojek (Slide to Pay)
class PaymentBottomSheet extends StatefulWidget {
  final String? transactionId;
  final String? transactionCode;
  final String customerName;
  final String orderType;
  final String tableNumber;
  final String queueNumber;
  final double totalAmount;
  final int totalItems;
  final List<TransactionItem> items;
  final VoidCallback? onSettled;

  const PaymentBottomSheet({
    super.key,
    this.transactionId,
    this.transactionCode,
    this.customerName = 'Pelanggan (Anonymous)',
    this.orderType = 'DINE_IN',
    this.tableNumber = '',
    this.queueNumber = '',
    required this.totalAmount,
    required this.totalItems,
    required this.items,
    this.onSettled,
  });

  /// Helper statis untuk menampilkan bottom sheet
  static Future<void> show(
    BuildContext context, {
    String? transactionId,
    String? transactionCode,
    String customerName = 'Pelanggan (Anonymous)',
    String orderType = 'DINE_IN',
    String tableNumber = '',
    String queueNumber = '',
    required double totalAmount,
    required int totalItems,
    required List<TransactionItem> items,
    VoidCallback? onSettled,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => PaymentBottomSheet(
        transactionId: transactionId,
        transactionCode: transactionCode,
        customerName: customerName,
        orderType: orderType,
        tableNumber: tableNumber,
        queueNumber: queueNumber,
        totalAmount: totalAmount,
        totalItems: totalItems,
        items: items,
        onSettled: onSettled,
      ),
    );
  }

  @override
  State<PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<PaymentBottomSheet> {
  final FirestoreService _firestoreService = FirestoreService();

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String _paymentMethod = 'Tunai'; // 'Tunai' atau 'QRIS'
  double _cashReceived = 0.0;
  final TextEditingController _cashController = TextEditingController();
  String? _recordedCode;

  @override
  void initState() {
    super.initState();
    // Default uang tunai = uang pas
    _cashReceived = widget.totalAmount;
    _cashController.text = widget.totalAmount.toInt().toString();
    _recordedCode = widget.transactionCode;
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  double get _changeAmount => (_cashReceived - widget.totalAmount).clamp(0.0, double.infinity);

  Future<void> _handleSettle() async {
    try {
      if (widget.transactionId != null) {
        // Melunasi transaksi yang sudah ada di antrean
        await _firestoreService.settleTransaction(
          transactionId: widget.transactionId!,
          paymentMethod: _paymentMethod,
        );
      } else {
        // Menyimpan transaksi baru langsung berstatus LUNAS
        final res = await _firestoreService.createSaleTransaction(
          widget.items,
          customerName: widget.customerName,
          orderType: widget.orderType,
          tableNumber: widget.tableNumber,
          queueNumber: widget.queueNumber,
          status: 'LUNAS',
          paymentMethod: _paymentMethod,
        );
        _recordedCode = res.code;
      }

      if (!mounted) return;
      Navigator.pop(context); // Tutup bottom sheet pelunasan

      widget.onSettled?.call();

      // Tampilkan Dialog Bukti Pelunasan LUNAS
      _showSuccessReceiptDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pelunasan gagal: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
      rethrow;
    }
  }

  void _showSuccessReceiptDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 42),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.success),
              ),
              child: const Text(
                'LUNAS',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _currency.format(widget.totalAmount),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_recordedCode ?? widget.transactionCode ?? '#TRX-000'} • ${_paymentMethod.toUpperCase()}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.border),
            const SizedBox(height: 8),
            if (_paymentMethod == 'Tunai' && _changeAmount > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Uang Diterima:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  Text(_currency.format(_cashReceived), style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kembalian:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  Text(
                    _currency.format(_changeAmount),
                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text(
              '${widget.totalItems} item belanja telah berhasil diselesaikan.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pelunasan Transaksi Kasir',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Nomor Struk: ${widget.transactionCode}',
                      style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 14),

            // Rincian Tagihan
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Tagihan (${widget.totalItems} item):',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      Text(
                        _currency.format(widget.totalAmount),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Status Transaksi:',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'MENUNGGU PEMBAYARAN',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Pilihan Metode Pembayaran (QRIS & Tunai)
            const Text(
              'Pilih Metode Pembayaran:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      setState(() {
                        _paymentMethod = 'Tunai';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: _paymentMethod == 'Tunai'
                            ? AppColors.accent.withValues(alpha: 0.15)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _paymentMethod == 'Tunai' ? AppColors.accent : AppColors.border,
                          width: _paymentMethod == 'Tunai' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.payments_outlined,
                            color: _paymentMethod == 'Tunai' ? AppColors.accent : AppColors.textSecondary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tunai (Cash)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _paymentMethod == 'Tunai' ? AppColors.accent : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      setState(() {
                        _paymentMethod = 'QRIS';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: _paymentMethod == 'QRIS'
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _paymentMethod == 'QRIS' ? const Color(0xFF10B981) : AppColors.border,
                          width: _paymentMethod == 'QRIS' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            color: _paymentMethod == 'QRIS' ? const Color(0xFF10B981) : AppColors.textSecondary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'QRIS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _paymentMethod == 'QRIS' ? const Color(0xFF10B981) : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Detail Panel Berdasarkan Metode Pembayaran
            if (_paymentMethod == 'Tunai') ...[
              // Kalkulator Uang Tunai
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kalkulator Uang Diterima:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('Uang Pas'),
                          backgroundColor: _cashReceived == widget.totalAmount
                              ? AppColors.accent.withValues(alpha: 0.25)
                              : AppColors.card,
                          labelStyle: TextStyle(
                            color: _cashReceived == widget.totalAmount ? AppColors.accent : AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          onPressed: () {
                            setState(() {
                              _cashReceived = widget.totalAmount;
                              _cashController.text = widget.totalAmount.toInt().toString();
                            });
                          },
                        ),
                        ...[20000, 50000, 100000].map((nominal) {
                          if (nominal < widget.totalAmount) return const SizedBox.shrink();
                          final isSelected = _cashReceived == nominal.toDouble();
                          return ActionChip(
                            label: Text(_currency.format(nominal)),
                            backgroundColor: isSelected
                                ? AppColors.accent.withValues(alpha: 0.25)
                                : AppColors.card,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.accent : AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onPressed: () {
                              setState(() {
                                _cashReceived = nominal.toDouble();
                                _cashController.text = nominal.toString();
                              });
                            },
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kembalian:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        Text(
                          _currency.format(_changeAmount),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _changeAmount > 0 ? AppColors.accent : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Tampilan QRIS Dummy
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.qr_code_2_rounded, color: Colors.black, size: 48),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'QRIS Dinamis / Statis UMKM',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Pelanggan scan barcode QRIS menggunakan m-Banking / E-Wallet.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total Bayar: ${_currency.format(widget.totalAmount)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Gojek-Style Slide to Pay Button
            SlideToPayButton(
              onConfirmed: _handleSettle,
              label: 'Geser untuk Melunasi ($_paymentMethod)',
              completedLabel: 'Melunasi Transaksi...',
              activeColor: _paymentMethod == 'QRIS' ? const Color(0xFF10B981) : AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }
}
