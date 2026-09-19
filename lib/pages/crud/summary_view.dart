import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import 'time_filter_helper.dart';

/// Tampilan Ringkasan Penjualan (Sales Summary berdasarkan Dimensi Waktu)
class SummaryView extends StatelessWidget {
  final TimeFilterPeriod selectedPeriod;
  final DateTimeRange? customRange;
  final Function(TimeFilterPeriod, DateTimeRange?) onPeriodChanged;

  const SummaryView({
    super.key,
    required this.selectedPeriod,
    required this.customRange,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final NumberFormat currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final range = TimeFilterHelper.getRange(selectedPeriod, customRange);

    return Column(
      children: [
        TimeFilterHelper.buildFilterBar(
          context: context,
          selectedPeriod: selectedPeriod,
          customRange: customRange,
          onPeriodChanged: onPeriodChanged,
        ),
        Expanded(
          child: StreamBuilder<List<TransactionModel>>(
            stream: firestoreService.getTransactionsStream(
              startDate: range.start,
              endDate: range.end,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.accent));
              }

              final transactions = snapshot.data ?? [];

              double totalRevenue = 0.0;
              double totalEstimatedProfit = 0.0;
              int totalSoldItems = 0;
              final Map<String, int> productSalesCount = {};

              for (final t in transactions) {
                totalRevenue += t.totalAmount;
                totalEstimatedProfit += t.profit;
                totalSoldItems += t.totalItems;

                for (final it in t.items) {
                  productSalesCount[it.productName] = (productSalesCount[it.productName] ?? 0) + it.quantity;
                }
              }

              final sortedProducts = productSalesCount.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Periode
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.analytics_outlined, size: 18, color: AppColors.accent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Laporan Penjualan: ${TimeFilterHelper.getLabel(selectedPeriod, customRange)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Grid Metrik Ringkasan
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Total Penjualan',
                            value: currency.format(totalRevenue),
                            icon: Icons.monetization_on_outlined,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Estimasi Laba',
                            value: currency.format(totalEstimatedProfit),
                            icon: Icons.trending_up,
                            color: const Color(0xFF38BDF8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Jumlah Transaksi',
                            value: '${transactions.length} struk',
                            icon: Icons.receipt_long,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Produk Terjual',
                            value: '$totalSoldItems item',
                            icon: Icons.inventory_2_outlined,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Daftar Menu Paling Laris
                    const Text(
                      'Peringkat Menu Paling Laku:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),

                    if (sortedProducts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Text(
                            'Belum ada transaksi pada periode ini',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sortedProducts.length,
                          separatorBuilder: (context, index) => const Divider(color: AppColors.border, height: 1),
                          itemBuilder: (context, index) {
                            final entry = sortedProducts[index];
                            final rank = index + 1;

                            return ListTile(
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: rank <= 3
                                    ? AppColors.accent.withValues(alpha: 0.2)
                                    : AppColors.background,
                                child: Text(
                                  '$rank',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: rank <= 3 ? AppColors.accent : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              trailing: Text(
                                '${entry.value} porsi/item',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
