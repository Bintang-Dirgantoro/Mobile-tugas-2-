import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';

/// Halaman Komputasi Finansial & Bisnis UMKM
/// 
/// Catatan Error Handling & Tipe Data:
/// 1. Menggunakan tipe data `double` karena perhitungan keuangan, persentase, dan pajak
///    seringkali melibatkan bilangan desimal / koma.
/// 2. Parsing input fleksibel: mengganti tanda koma (',') menjadi titik ('.') agar input
///    angka desimal gaya Indonesia (contoh: 12,5) tetap terbaca dengan benar.
/// 3. Batasan Nilai (Limits):
///    - Nominal uang dibatasi maksimal Rp 999.999.999.999 (999 Miliar) untuk mencegah overflow.
///    - Persentase dibatasi antara 0% s/d 100%.
///    - Angka negatif tidak diperbolehkan.
/// 4. Proteksi Pembagian Nol (Zero Division Guard):
///    - Menghindari error `Infinity` / `NaN` saat pembagi bernilai 0 pada perhitungan margin & markup.
class ComputationPage extends StatefulWidget {
  const ComputationPage({super.key});

  @override
  State<ComputationPage> createState() => _ComputationPageState();
}

class _ComputationPageState extends State<ComputationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Formatter mata uang Rupiah
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Formatter desimal persentase
  final NumberFormat _percentFormat = NumberFormat.decimalPattern('id_ID');

  // Batas maksimal input keuangan (999 Miliar)
  static const double _maxAllowedAmount = 999999999999.0;

  // Controllers Tab 1: Margin & Markup
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String? _marginError;
  Map<String, String>? _marginResult;

  // Controllers Tab 2: Diskon Bertingkat
  final TextEditingController _originalPriceController = TextEditingController();
  final TextEditingController _discount1Controller = TextEditingController();
  final TextEditingController _discount2Controller = TextEditingController();
  String? _discountError;
  Map<String, String>? _discountResult;

  // Controllers Tab 3: Pajak UMKM
  final TextEditingController _revenueController = TextEditingController();
  double _taxRate = 0.5; // Default 0.5% (PPh Final UMKM)
  String? _taxError;
  Map<String, String>? _taxResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _costController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _discount1Controller.dispose();
    _discount2Controller.dispose();
    _revenueController.dispose();
    super.dispose();
  }

  /// Helper untuk parsing input desimal secara aman
  double? _parseSafeDouble(String text) {
    if (text.trim().isEmpty) return null;
    // Ganti koma dengan titik agar valid untuk double.tryParse
    final sanitized = text.trim().replaceAll(',', '.');
    return double.tryParse(sanitized);
  }

  // ==========================================
  // 1. LOGIKA KOMPUTASI MARGIN & MARKUP
  // ==========================================
  void _calculateMargin() {
    setState(() {
      _marginError = null;
      _marginResult = null;
    });

    final cost = _parseSafeDouble(_costController.text);
    final price = _parseSafeDouble(_priceController.text);

    // Validasi input
    if (cost == null || price == null) {
      setState(() => _marginError = 'Semua kolom wajib diisi dengan angka valid!');
      return;
    }
    if (cost < 0 || price < 0) {
      setState(() => _marginError = 'Nominal tidak boleh bernilai negatif!');
      return;
    }
    if (cost > _maxAllowedAmount || price > _maxAllowedAmount) {
      setState(() => _marginError = 'Nominal melebihi batas wajar (Maks 999 Miliar)!');
      return;
    }

    final profit = price - cost;

    // Proteksi pembagian dengan nol
    final marginPercent = (price > 0) ? (profit / price) * 100 : 0.0;
    final markupPercent = (cost > 0) ? (profit / cost) * 100 : 0.0;

    setState(() {
      _marginResult = {
        'profit': _currencyFormat.format(profit),
        'margin': '${_percentFormat.format(marginPercent)}%',
        'markup': '${_percentFormat.format(markupPercent)}%',
        'status': profit >= 0 ? 'UNTUNG' : 'RUGI',
      };
    });
  }

  // ==========================================
  // 2. LOGIKA DISKON BERTINGKAT (Promo UMKM)
  // ==========================================
  void _calculateDiscount() {
    setState(() {
      _discountError = null;
      _discountResult = null;
    });

    final originalPrice = _parseSafeDouble(_originalPriceController.text);
    final disc1 = _parseSafeDouble(_discount1Controller.text) ?? 0.0;
    final disc2 = _parseSafeDouble(_discount2Controller.text) ?? 0.0;

    if (originalPrice == null) {
      setState(() => _discountError = 'Harga awal wajib diisi angka valid!');
      return;
    }
    if (originalPrice <= 0) {
      setState(() => _discountError = 'Harga awal harus lebih besar dari 0!');
      return;
    }
    if (originalPrice > _maxAllowedAmount) {
      setState(() => _discountError = 'Harga melebihi batas wajar!');
      return;
    }
    if (disc1 < 0 || disc1 > 100 || disc2 < 0 || disc2 > 100) {
      setState(() => _discountError = 'Persentase diskon harus di antara 0% s/d 100%!');
      return;
    }

    // Perhitungan diskon beruntun
    final afterDisc1 = originalPrice - (originalPrice * (disc1 / 100));
    final finalPrice = afterDisc1 - (afterDisc1 * (disc2 / 100));
    final totalSavings = originalPrice - finalPrice;
    final effectiveDiscount = (totalSavings / originalPrice) * 100;

    setState(() {
      _discountResult = {
        'finalPrice': _currencyFormat.format(finalPrice),
        'savings': _currencyFormat.format(totalSavings),
        'effectiveDisc': '${_percentFormat.format(effectiveDiscount)}%',
      };
    });
  }

  // ==========================================
  // 3. LOGIKA PAJAK UMKM (PPh Final & PPN)
  // ==========================================
  void _calculateTax() {
    setState(() {
      _taxError = null;
      _taxResult = null;
    });

    final revenue = _parseSafeDouble(_revenueController.text);

    if (revenue == null) {
      setState(() => _taxError = 'Omzet/Penjualan wajib diisi angka valid!');
      return;
    }
    if (revenue < 0) {
      setState(() => _taxError = 'Omzet tidak boleh bernilai negatif!');
      return;
    }
    if (revenue > _maxAllowedAmount) {
      setState(() => _taxError = 'Nominal melebihi batas sistem!');
      return;
    }

    final taxAmount = revenue * (_taxRate / 100);
    final netRevenue = revenue - taxAmount;

    setState(() {
      _taxResult = {
        'tax': _currencyFormat.format(taxAmount),
        'netRevenue': _currencyFormat.format(netRevenue),
        'rate': '$_taxRate%',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Komputasi Finansial UMKM'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.show_chart), text: 'Margin/Laba'),
            Tab(icon: Icon(Icons.discount), text: 'Diskon'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Pajak UMKM'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMarginTab(),
          _buildDiscountTab(),
          _buildTaxTab(),
        ],
      ),
    );
  }

  Widget _buildMarginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _infoCard('Kalkulator Laba Bersih & Margin',
              'Hitung keuntungan, persentase margin penjualan, dan markup harga modal.'),
          const SizedBox(height: 16),
          _customTextField(
            controller: _costController,
            label: 'Harga Modal / Beli (Rp)',
            hint: 'Contoh: 50000',
            icon: Icons.shopping_bag_outlined,
          ),
          const SizedBox(height: 12),
          _customTextField(
            controller: _priceController,
            label: 'Harga Jual (Rp)',
            hint: 'Contoh: 75000',
            icon: Icons.sell_outlined,
          ),
          const SizedBox(height: 16),
          if (_marginError != null) _errorCard(_marginError!),
          ElevatedButton(
            onPressed: _calculateMargin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hitung Margin & Laba', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (_marginResult != null) ...[
            const SizedBox(height: 20),
            _resultCard([
              _resultRow('Status Usaha:', _marginResult!['status']!,
                  color: _marginResult!['status'] == 'UNTUNG' ? AppColors.success : AppColors.danger),
              _resultRow('Laba Bersih per Unit:', _marginResult!['profit']!),
              _resultRow('Margin Keuntungan:', _marginResult!['margin']!),
              _resultRow('Markup Modal:', _marginResult!['markup']!),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildDiscountTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _infoCard('Kalkulator Diskon Promo Bertingkat',
              'Hitung harga promo seperti diskon 50% + 20% secara presisi tanpa salah kalkulasi.'),
          const SizedBox(height: 16),
          _customTextField(
            controller: _originalPriceController,
            label: 'Harga Awal Produk (Rp)',
            hint: 'Contoh: 100000',
            icon: Icons.price_change_outlined,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _customTextField(
                  controller: _discount1Controller,
                  label: 'Diskon 1 (%)',
                  hint: 'Contoh: 50',
                  icon: Icons.percent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _customTextField(
                  controller: _discount2Controller,
                  label: 'Diskon 2 (%) - Opsional',
                  hint: 'Contoh: 20',
                  icon: Icons.percent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_discountError != null) _errorCard(_discountError!),
          ElevatedButton(
            onPressed: _calculateDiscount,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hitung Harga Akhir', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (_discountResult != null) ...[
            const SizedBox(height: 20),
            _resultCard([
              _resultRow('Harga Akhir Konsumen:', _discountResult!['finalPrice']!,
                  color: AppColors.success, isLarge: true),
              _resultRow('Total Potongan Diskon:', _discountResult!['savings']!),
              _resultRow('Diskon Efektif Riil:', _discountResult!['effectiveDisc']!),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildTaxTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _infoCard('Kalkulator Pajak UMKM',
              'Perhitungan PPh Final UMKM (0.5% sesuai PP 23) atau PPN (11%) untuk pelaporan bisnis.'),
          const SizedBox(height: 16),
          _customTextField(
            controller: _revenueController,
            label: 'Total Omzet / Pendapatan Bruto (Rp)',
            hint: 'Contoh: 25000000',
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 14),
          const Text('Pilih Tarif Pajak:', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('PPh Final 0.5%'),
                  selected: _taxRate == 0.5,
                  selectedColor: AppColors.accent,
                  onSelected: (selected) {
                    if (selected) setState(() => _taxRate = 0.5);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('PPN 11%'),
                  selected: _taxRate == 11.0,
                  selectedColor: AppColors.accent,
                  onSelected: (selected) {
                    if (selected) setState(() => _taxRate = 11.0);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_taxError != null) _errorCard(_taxError!),
          ElevatedButton(
            onPressed: _calculateTax,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hitung Pajak Terutang', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (_taxResult != null) ...[
            const SizedBox(height: 20),
            _resultCard([
              _resultRow('Tarif Pajak Dipilih:', _taxResult!['rate']!),
              _resultRow('Pajak yang Harus Disetor:', _taxResult!['tax']!,
                  color: AppColors.warning, isLarge: true),
              _resultRow('Pendapatan Bersih (Net):', _taxResult!['netRevenue']!),
            ]),
          ],
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _customTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.accent, size: 20),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
    );
  }

  Widget _infoCard(String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 6),
          Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _errorCard(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _resultCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _resultRow(String label, String value, {Color? color, bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: isLarge ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
