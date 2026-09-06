import 'package:flutter/material.dart';

import '../services/auth_services.dart';

import 'login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tugas Mobile 2'),
        actions: [
          IconButton(
            onPressed: () async {
              await authService.logout();

              if (!context.mounted) return;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
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
              onPressed: () {},
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
