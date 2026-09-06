import 'package:flutter/material.dart';

import 'group_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tugas Mobile 2')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Menu Utama',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GroupPage()),
                );
              },
              child: const Text('Data Kelompok'),
            ),

            ElevatedButton(onPressed: () {}, child: const Text('Penjumlahan')),

            ElevatedButton(onPressed: () {}, child: const Text('Pengurangan')),

            ElevatedButton(onPressed: () {}, child: const Text('Perkalian')),

            ElevatedButton(onPressed: () {}, child: const Text('Pembagian')),

            ElevatedButton(
              onPressed: () {},
              child: const Text('Ganjil / Genap'),
            ),

            ElevatedButton(onPressed: () {}, child: const Text('Total Nilai')),
          ],
        ),
      ),
    );
  }
}
