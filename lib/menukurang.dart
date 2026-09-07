import 'package:flutter/material.dart';

class MenuKurang extends StatefulWidget {
  const MenuKurang({super.key});

  @override
  State<MenuKurang> createState() => _MenuKurangState();
}

class _MenuKurangState extends State<MenuKurang> {
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

    int total = angka1 - angka2;

    setState(() {
      hasil = 'Hasil = $total';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengurangan'),
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