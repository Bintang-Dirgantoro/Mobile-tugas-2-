import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';

/// Halaman Form Tambah & Edit Produk UMKM (Cloud Firestore)
/// 
/// Catatan Validasi & Limitasi Tipe Data:
/// 1. Nama Produk: Maksimal 60 karakter untuk mencegah teks merusak tampilan UI.
/// 2. Harga Modal & Jual: Tipe `double` (desimal) dengan batas maksimal Rp 999 Miliar.
///    - Diberikan peringatan jika harga jual lebih kecil dari modal (potensi rugi).
/// 3. Stok Barang: Tipe `int` (bilangan bulat) dengan batasan 0 s/d 1.000.000 unit.
/// 4. Error handling jaringan & izin Firebase ditangani dalam blok `try-catch`.
class CrudFormPage extends StatefulWidget {
  final ProductItem? product; // null jika mode Tambah, berisi data jika Edit

  const CrudFormPage({super.key, this.product});

  @override
  State<CrudFormPage> createState() => _CrudFormPageState();
}

class _CrudFormPageState extends State<CrudFormPage> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  late TextEditingController _nameController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _stockController;

  String _selectedCategory = 'Makanan';
  final List<String> _categories = [
    'Makanan',
    'Minuman',
    'Pakaian',
    'Jasa',
    'Elektronik',
    'Kerajinan',
    'Lainnya'
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _purchasePriceController = TextEditingController(
        text: p != null ? p.purchasePrice.toStringAsFixed(0) : '');
    _sellingPriceController = TextEditingController(
        text: p != null ? p.sellingPrice.toStringAsFixed(0) : '');
    _stockController = TextEditingController(
        text: p != null ? p.stock.toString() : '');
    if (p != null && _categories.contains(p.category)) {
      _selectedCategory = p.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  double? _parseSafeDouble(String text) {
    final sanitized = text.trim().replaceAll(',', '.');
    return double.tryParse(sanitized);
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final purchasePrice = _parseSafeDouble(_purchasePriceController.text) ?? 0.0;
    final sellingPrice = _parseSafeDouble(_sellingPriceController.text) ?? 0.0;
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;

    // Logika bisnis peringatan rugi
    if (sellingPrice < purchasePrice) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Peringatan Harga Jual', style: TextStyle(color: AppColors.warning)),
          content: const Text(
            'Harga jual lebih rendah daripada harga modal (potensi rugi). Apakah Anda yakin ingin melanjutkan?',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Perbaiki', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
              child: const Text('Tetap Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.product == null) {
        // Mode Tambah
        await _firestoreService.addProduct(
          name: name,
          category: _selectedCategory,
          purchasePrice: purchasePrice,
          sellingPrice: sellingPrice,
          stock: stock,
        );
      } else {
        // Mode Edit
        await _firestoreService.updateProduct(
          id: widget.product!.id,
          name: name,
          category: _selectedCategory,
          purchasePrice: purchasePrice,
          sellingPrice: sellingPrice,
          stock: stock,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.product == null
              ? 'Produk berhasil ditambahkan ke database!'
              : 'Data produk berhasil diperbarui!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk Baru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. NAMA PRODUK
              TextFormField(
                controller: _nameController,
                maxLength: 60,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nama Produk / Jasa *',
                  hintText: 'Contoh: Kopi Susu Gula Aren',
                  prefixIcon: const Icon(Icons.inventory_2_outlined, color: AppColors.accent),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  counterStyle: const TextStyle(color: AppColors.textSecondary),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama produk tidak boleh kosong';
                  }
                  if (val.trim().length < 3) {
                    return 'Nama produk minimal 3 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // 2. KATEGORI PRODUK
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                dropdownColor: AppColors.card,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Kategori Produk',
                  prefixIcon: const Icon(Icons.category_outlined, color: AppColors.accent),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 16),

              // 3. HARGA MODAL (BELI)
              TextFormField(
                controller: _purchasePriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Harga Modal / Beli (Rp) *',
                  hintText: 'Contoh: 12000',
                  prefixIcon: const Icon(Icons.shopping_cart_outlined, color: AppColors.accent),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Harga modal wajib diisi';
                  }
                  final parsed = _parseSafeDouble(val);
                  if (parsed == null) return 'Gunakan angka yang valid';
                  if (parsed < 0) return 'Harga modal tidak boleh negatif';
                  if (parsed > 999999999999) return 'Maksimal Rp 999 Miliar';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 4. HARGA JUAL
              TextFormField(
                controller: _sellingPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Harga Jual ke Konsumen (Rp) *',
                  hintText: 'Contoh: 18000',
                  prefixIcon: const Icon(Icons.sell_outlined, color: AppColors.accent),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Harga jual wajib diisi';
                  }
                  final parsed = _parseSafeDouble(val);
                  if (parsed == null) return 'Gunakan angka yang valid';
                  if (parsed <= 0) return 'Harga jual harus lebih dari 0';
                  if (parsed > 999999999999) return 'Maksimal Rp 999 Miliar';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 5. STOK BARANG
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Jumlah Stok (Unit) *',
                  hintText: 'Contoh: 50',
                  prefixIcon: const Icon(Icons.numbers_outlined, color: AppColors.accent),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Jumlah stok wajib diisi';
                  }
                  final parsed = int.tryParse(val.trim());
                  if (parsed == null) return 'Stok harus berupa bilangan bulat';
                  if (parsed < 0) return 'Stok tidak boleh bernilai negatif';
                  if (parsed > 1000000) return 'Maksimal stok 1.000.000 unit';
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // TOMBOL SIMPAN
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isEdit ? 'Perbarui Data Produk' : 'Simpan Produk Baru',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
