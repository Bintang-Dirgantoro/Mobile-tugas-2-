/// Model item untuk template menu cepat
class PresetMenuItem {
  final String name;
  final String category;
  final double purchasePrice;
  final double sellingPrice;
  final int stock;

  const PresetMenuItem({
    required this.name,
    required this.category,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stock,
  });
}

/// ============================================================================
/// FILE TEMPLATE MENU PRESET (BISA KAMU EDIT SENDIRI DENGAN MUDAH!)
/// ============================================================================
/// Kamu bisa bebas mengubah:
/// 1. `templateName` : Nama paket template (misal: 'Menu Warmindo Jogja', 'Warkop Kekinian')
/// 2. `items` : Tambah, ubah, atau hapus menu sesuai kebutuhan testing/demo kamu.
/// ============================================================================
class MenuPresets {
  /// Nama Template (akan muncul pada tombol di aplikasi)
  static const String templateName = 'Menu Warmindo & Warkop';

  /// Daftar Menu Default
  /// Silakan ubah nama, kategori, harga, atau stok di bawah ini:
  static const List<PresetMenuItem> items = [
    PresetMenuItem(
      name: 'Indomie Goreng Original',
      category: 'Makanan',
      purchasePrice: 3500,
      sellingPrice: 8000,
      stock: 30,
    ),
    PresetMenuItem(
      name: 'Indomie Goreng Dobel Telur',
      category: 'Makanan',
      purchasePrice: 6500,
      sellingPrice: 13000,
      stock: 20,
    ),
    PresetMenuItem(
      name: 'Indomie Kuah Soto Spesial',
      category: 'Makanan',
      purchasePrice: 3500,
      sellingPrice: 8000,
      stock: 25,
    ),
    PresetMenuItem(
      name: 'Magelangan Warmindo (Nasi + Mie)',
      category: 'Makanan',
      purchasePrice: 7000,
      sellingPrice: 14000,
      stock: 15,
    ),
    PresetMenuItem(
      name: 'Es Teh Manis Jumbo',
      category: 'Minuman',
      purchasePrice: 1500,
      sellingPrice: 4000,
      stock: 50,
    ),
    PresetMenuItem(
      name: 'Nutrisari Jeruk Dingin',
      category: 'Minuman',
      purchasePrice: 2000,
      sellingPrice: 5000,
      stock: 40,
    ),
    PresetMenuItem(
      name: 'Kopi Hitam Panas (Warkop)',
      category: 'Minuman',
      purchasePrice: 2000,
      sellingPrice: 4000,
      stock: 30,
    ),
    PresetMenuItem(
      name: 'Gorengan Bakwan / Tempe (Isi 3)',
      category: 'Makanan',
      purchasePrice: 1500,
      sellingPrice: 3000,
      stock: 40,
    ),
  ];
}
