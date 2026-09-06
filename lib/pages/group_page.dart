import 'package:flutter/material.dart';

class GroupPage extends StatelessWidget {
  const GroupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Kelompok')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: CircleAvatar(child: Text('1')),
            title: Text('Michael Aldo Tri Cahya'),
            subtitle: Text('NIM: 124230124'),
          ),
          Divider(),

          ListTile(
            leading: CircleAvatar(child: Text('2')),
            title: Text('Bintang Dirgantoro Gien'),
            subtitle: Text('NIM: 124240088'),
          ),
          Divider(),

          ListTile(
            leading: CircleAvatar(child: Text('3')),
            title: Text('Pinto Mande Mantofani'),
            subtitle: Text('NIM: 124240118'),
          ),
        ],
      ),
    );
  }
}
