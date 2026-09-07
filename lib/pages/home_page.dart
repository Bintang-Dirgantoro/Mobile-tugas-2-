import 'package:flutter/material.dart';

import '../menubagi.dart';
import '../menukali.dart';
import '../menukurang.dart';
import '../menutambah.dart';
import '../services/auth_services.dart';
import 'group_page.dart';
import 'login_page.dart';
import 'odd_even_page.dart';
import 'total_page.dart';

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
      body: SingleChildScrollView(
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

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MenuTambah()),
                );
              },
              child: const Text('Penjumlahan'),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MenuKurang()),
                );
              },
              child: const Text('Pengurangan'),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MenuKali()),
                );
              },
              child: const Text('Perkalian'),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MenuBagi()),
                );
              },
              child: const Text('Pembagian'),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OddEvenPage()),
                );
              },
              child: const Text('Ganjil / Genap'),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TotalPage()),
                );
              },
              child: const Text('Total Nilai'),
            ),
          ],
        ),
      ),
    );
  }
}

