import 'package:flutter/material.dart';

class MenuTambah extends StatefulWidget {
  const MenuTambah({super.key});

  @override
  State<MenuTambah> createState() => _MenuTambahState();
}

class _MenuTambahState extends State<MenuTambah> {
  final TextEditingController angka1Controller = TextEditingController();
  final TextEditingController angka2Controller = TextEditingController();

  String hasil = '';

  void hitung() {
    int? angka1 = int.tryParse(angka1Controller.text);
    int? angka2 = int.tryParse(angka2Controller.text);

    if (angka1 == null || angka2 == null) {
      setState(() {
        hasil = 'Masukkan angka yang valid';
      });
      return;
    }

    int total = angka1 + angka2;

    setState(() {
      hasil = 'Hasil = $total';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penjumlahan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: angka1Controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Angka 1',
              ),
            ),
            TextField(
              controller: angka2Controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Angka 2',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: hitung,
              child: const Text('HITUNG'),
            ),
            const SizedBox(height: 20),
            Text(hasil),
          ],
        ),
      ),
    );
  }
}