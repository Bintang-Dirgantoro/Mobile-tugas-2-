import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import 'time_filter_helper.dart';
import 'payment_bottom_sheet.dart';

/// Tampilan Riwayat Transaksi (Konsep Aplikasi Bank dengan Dimensi Waktu & Status Pelunasan)
class HistoryView extends StatefulWidget {
  final TimeFilterPeriod selectedPeriod;
  final DateTimeRange? customRange;
  final Function(TimeFilterPeriod, DateTimeRange?) onPeriodChanged;

  const HistoryView({
    super.key,
    required this.selectedPeriod,
    required this.customRange,
    required this.onPeriodChanged,
  });

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final FirestoreService _firestoreService = FirestoreService();

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final DateFormat _dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
  final DateFormat _timeFormat = DateFormat('HH:mm', 'id_ID');
  final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

  void _showTransactionDetail(TransactionModel trx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                        trx.transactionCode,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accent),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _dateTimeFormat.format(trx.createdAt),
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

              // Status Badge & Metode Bayar
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
                'Daftar Menu yang Dipesan:',
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
                  const Text('Total Penjualan:', style: TextStyle(color: AppColors.textSecondary)),
                  Text(
                    _currency.format(trx.totalAmount),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.success),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Estimasi Laba Bersih:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text(
                    '+${_currency.format(trx.profit)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.accent),
                  ),
                ],
              ),

              // Jika belum lunas, berikan tombol untuk pelunasan langsung via Gojek Slide
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
                        onSettled: () {
                          setState(() {});
                        },
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
                      'Lunasi Transaksi Ini (QRIS / Tunai)',
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
    final range = TimeFilterHelper.getRange(widget.selectedPeriod, widget.customRange);

    return Column(
      children: [
        TimeFilterHelper.buildFilterBar(
          context: context,
          selectedPeriod: widget.selectedPeriod,
          customRange: widget.customRange,
          onPeriodChanged: widget.onPeriodChanged,
        ),
        Expanded(
          child: StreamBuilder<List<TransactionModel>>(
            stream: _firestoreService.getTransactionsStream(
              startDate: range.start,
              endDate: range.end,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.accent));
              }

              final transactions = snapshot.data ?? [];

              if (transactions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      const Text(
                        'Belum ada transaksi pada periode ini',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ubah pilihan filter tanggal di atas',
                        style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final trx = transactions[index];
                  final snippet = trx.items.map((i) => '${i.productName} ×${i.quantity}').join(', ');
                  final isPaid = trx.isPaid;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isPaid ? AppColors.border : AppColors.warning.withValues(alpha: 0.6),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showTransactionDetail(trx),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: (isPaid ? AppColors.success : AppColors.warning).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPaid ? Icons.arrow_downward : Icons.hourglass_top_rounded,
                                color: isPaid ? AppColors.success : AppColors.warning,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            trx.transactionCode,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (isPaid ? AppColors.success : AppColors.warning).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isPaid ? (trx.paymentMethod ?? 'LUNAS') : 'BELUM LUNAS',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: isPaid ? AppColors.success : AppColors.warning,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        _timeFormat.format(trx.createdAt),
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    snippet,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _dateFormat.format(trx.createdAt),
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                      Text(
                                        _currency.format(trx.totalAmount),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isPaid ? AppColors.success : AppColors.warning,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
