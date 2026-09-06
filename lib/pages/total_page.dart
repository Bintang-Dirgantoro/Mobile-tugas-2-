import 'package:flutter/material.dart';

import 'package:mobile_tugas2/theme/app_colors.dart';

class TotalPage extends StatefulWidget {
  const TotalPage({super.key});

  @override
  State<TotalPage> createState() => _TotalPageState();
}

class _TotalPageState extends State<TotalPage> {
  // ===== STATE: 4 input, masing-masing PUNYA controller sendiri =====
  final TextEditingController _controller1 = TextEditingController();
  final TextEditingController _controller2 = TextEditingController();
  final TextEditingController _controller3 = TextEditingController();
  final TextEditingController _controller4 = TextEditingController();
  String _result = '';

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    _controller4.dispose();
    super.dispose();
  }

    // ===== HELPER: pabrik TextField angka =====
  Widget _numberField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jumlah Total'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            // ===== HEADER (pola sama seperti 2 halaman sebelumnya) =====
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accent),
              ),
              child: const Icon(
                Icons.functions,
                color: AppColors.accent,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),

            // ===== 4 INPUT =====
            _numberField('Angka 1', _controller1),
            const SizedBox(height: 12),
            _numberField('Angka 2', _controller2),
            const SizedBox(height: 12),
            _numberField('Angka 3', _controller3),
            const SizedBox(height: 12),
            _numberField('Angka 4', _controller4),
            const SizedBox(height: 24),

            // ===== TOMBOL =====
            ElevatedButton(
              onPressed: _calculateTotal,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Hitung Total',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 24),

            // ===== HASIL =====
            if (_result.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  _result,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

    // ===== LOGIKA JUMLAH TOTAL =====
  void _calculateTotal() {
    // Kumpulkan 4 controller ke dalam satu List
    final controllers = [
      _controller1,
      _controller2,
      _controller3,
      _controller4,
    ];

    int total = 0;
    for (final controller in controllers) {
      final number = int.tryParse(controller.text.trim());
      if (number == null) {
        setState(() {
          _result = 'Semua kolom harus diisi angka valid!';
        });
        return; // berhenti di kolom pertama yang tidak valid
      }
      total += number;
    }

    setState(() {
      _result = 'Total: $total';
    });
  }
}