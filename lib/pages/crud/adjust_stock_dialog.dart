import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';

/// Dialog Penyesuaian Stok (Stok Masuk / Stok Keluar Non-Penjualan)
class AdjustStockDialog extends StatefulWidget {
  final ProductItem product;
  final VoidCallback? onSuccess;

  const AdjustStockDialog({
    super.key,
    required this.product,
    this.onSuccess,
  });

  static Future<void> show(BuildContext context, ProductItem product, {VoidCallback? onSuccess}) {
    return showDialog(
      context: context,
      builder: (ctx) => AdjustStockDialog(product: product, onSuccess: onSuccess),
    );
  }

  @override
  State<AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends State<AdjustStockDialog> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _qtyController = TextEditingController();

  String _type = 'IN'; // 'IN' atau 'OUT'
  String _reason = 'Restock / Kulakan Baru';
  bool _isLoading = false;

  final List<String> _inReasons = [
    'Restock / Kulakan Baru',
    'Bonus Supplier',
    'Koreksi Stok Tambah',
    'Lainnya',
  ];

  final List<String> _outReasons = [
    'Produk Rusak',
    'Kedaluwarsa (Expired)',
    'Konsumsi Sendiri / Kru',
    'Koreksi Stok Kurang',
    'Lainnya',
  ];

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final qty = int.tryParse(_qtyController.text.trim());
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan jumlah kuantitas yang valid (angka > 0)!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_type == 'OUT' && qty > widget.product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stok tidak mencukupi!\nSisa stok saat ini hanya ${widget.product.stock} unit.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firestoreService.adjustStock(
        productId: widget.product.id,
        productName: widget.product.name,
        type: _type,
        quantity: qty,
        reason: _reason,
      );

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _type == 'IN'
                ? 'Berhasil menambah stok "${widget.product.name}" (+$qty unit)'
                : 'Berhasil mencatat stok keluar "${widget.product.name}" (-$qty unit)',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      widget.onSuccess?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyesuaikan stok: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reasons = _type == 'IN' ? _inReasons : _outReasons;
    if (!reasons.contains(_reason)) {
      _reason = reasons.first;
    }

    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            _type == 'IN' ? Icons.add_circle_outline : Icons.remove_circle_outline,
            color: _type == 'IN' ? AppColors.success : AppColors.danger,
          ),
          const SizedBox(width: 8),
          const Text('Atur Stok Inventaris', style: TextStyle(fontSize: 16, color: AppColors.textPrimary)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.product.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Stok saat ini: ${widget.product.stock} unit',
              style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Pilihan Tipe Mutasi
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Stok Masuk (+)')),
                    selected: _type == 'IN',
                    selectedColor: AppColors.success.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: _type == 'IN' ? AppColors.success : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _type = 'IN');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Stok Keluar (-)')),
                    selected: _type == 'OUT',
                    selectedColor: AppColors.danger.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: _type == 'OUT' ? AppColors.danger : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _type = 'OUT');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Input Jumlah Kuantitas
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Jumlah Kuantitas (Unit)',
                hintText: 'Contoh: 10',
                prefixIcon: const Icon(Icons.numbers, color: AppColors.accent),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 14),

            // Dropdown Alasan Mutasi
            DropdownButtonFormField<String>(
              initialValue: _reason,
              dropdownColor: AppColors.card,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Alasan Mutasi',
                prefixIcon: const Icon(Icons.description_outlined, color: AppColors.accent),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _reason = val);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: _type == 'IN' ? AppColors.success : AppColors.danger,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Simpan Mutasi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
