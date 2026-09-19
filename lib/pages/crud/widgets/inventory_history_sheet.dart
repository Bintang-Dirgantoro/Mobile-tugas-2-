import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/firestore_service.dart';
import '../../../theme/app_colors.dart';

/// Modal Audit Trail & Riwayat Mutasi Stok
class InventoryHistorySheet extends StatelessWidget {
  const InventoryHistorySheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const InventoryHistorySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.swap_vert, color: AppColors.accent),
                      SizedBox(width: 8),
                      Text(
                        'Log Riwayat Mutasi Stok',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Audit trail perubahan stok masuk (IN) dan keluar (OUT)',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              const Divider(color: AppColors.border, height: 1),
              Expanded(
                child: StreamBuilder<List<InventoryMovement>>(
                  stream: firestoreService.getInventoryMovementsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                    }
                    final list = snapshot.data ?? [];
                    if (list.isEmpty) {
                      return const Center(
                        child: Text('Belum ada riwayat mutasi stok tercatat', style: TextStyle(color: AppColors.textSecondary)),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: list.length,
                      separatorBuilder: (context, index) => const Divider(color: AppColors.border, height: 1),
                      itemBuilder: (context, index) {
                        final mov = list[index];
                        final isIN = mov.type == 'IN';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: (isIN ? AppColors.success : AppColors.danger).withValues(alpha: 0.15),
                            child: Icon(
                              isIN ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isIN ? AppColors.success : AppColors.danger,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            mov.productName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                          ),
                          subtitle: Text(
                            '${mov.reason} • ${dateTimeFormat.format(mov.createdAt)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          trailing: Text(
                            isIN ? '+${mov.quantity}' : '-${mov.quantity}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isIN ? AppColors.success : AppColors.danger,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
