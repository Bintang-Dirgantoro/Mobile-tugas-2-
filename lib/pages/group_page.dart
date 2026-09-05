import 'package:flutter/material.dart';

class GroupPage extends StatelessWidget {
  const GroupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Kelompok'),
        backgroundColor: Colors.blue,
      ),
      body: const Column(
        children: [
          SizedBox(height: 24),
          Text(
            'Kelompok 03',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('P')),
              title: Text('Pinto Mande Mantofani'),
              subtitle: Text('124240118'),
            ),
          ),
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('B')),
              title: Text('Bintang'),
              subtitle: Text('124240XXX'),
            ),
          ),
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('M')),
              title: Text('Michael Aldo Tri Cahya'),
              subtitle: Text('124230124'),
            ),
          ),
        ],
      ),
    );
  }
}