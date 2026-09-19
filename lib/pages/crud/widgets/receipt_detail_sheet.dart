import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction_model.dart';
import '../../../theme/app_colors.dart';

/// Modal Lembar Struk / Detail Transaksi Kasir
class ReceiptDetailSheet extends StatelessWidget {
  final TransactionModel trx;
  final VoidCallback? onPayPressed;

  const ReceiptDetailSheet({
    super.key,
    required this.trx,
    this.onPayPressed,
  });

  static void show(
    BuildContext context, {
    required TransactionModel trx,
    VoidCallback? onPayPressed,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ReceiptDetailSheet(
        trx: trx,
        onPayPressed: () {
          Navigator.pop(ctx);
          onPayPressed?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

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
                    '${trx.transactionCode} • ${dateFormat.format(trx.createdAt)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status Badge & Metode Pembayaran
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
                              '${currency.format(it.sellingPrice)} × ${it.quantity} unit',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        currency.format(it.subtotal),
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
                currency.format(trx.totalAmount),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.success),
              ),
            ],
          ),

          if (trx.isPending && onPayPressed != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onPayPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: const Text(
                  'Bayar',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
