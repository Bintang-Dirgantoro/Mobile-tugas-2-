import 'package:flutter/material.dart';

import 'package:mobile_tugas2/theme/app_colors.dart';

class OddEvenPage extends StatefulWidget {
  const OddEvenPage({super.key});

  @override
  State<OddEvenPage> createState() => _OddEvenPageState();
}

class _OddEvenPageState extends State<OddEvenPage> {
  // ===== STATE: data yang bisa berubah =====
  final TextEditingController _controller = TextEditingController();
  String _result = '';

    // ===== LOGIKA CEK GANJIL/GENAP =====
  void _checkOddEven() {
    final input = _controller.text.trim();
    final number = int.tryParse(input);

    // Input kosong / bukan angka
    if (number == null) {
      setState(() {
        _result = 'Masukkan angka yang valid!';
      });
      return;
    }

    // Inti logika: modulo 2
    setState(() {
      if (number % 2 == 0) {
        _result = '$number adalah bilangan GENAP';
      } else {
        _result = '$number adalah bilangan GANJIL';
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ganjil / Genap'),
      ),
            body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            // ===== HEADER =====
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accent),
              ),
              child: const Icon(
                Icons.percent,
                color: AppColors.accent,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),

            // ===== INPUT ANGKA =====
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Masukkan Angka',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ===== TOMBOL CEK =====
            ElevatedButton(
              onPressed: _checkOddEven,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Cek Ganjil / Genap',
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
}