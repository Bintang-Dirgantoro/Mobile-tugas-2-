import 'package:cloud_firestore/cloud_firestore.dart';

/// Model Produk UMKM (Master Menu)
class ProductItem {
  final String id;
  final String name;
  final String category;
  final double purchasePrice; // Harga Beli (Modal)
  final double sellingPrice;  // Harga Jual
  final int stock;            // Stok barang
  final DateTime createdAt;
  final String userId;

  ProductItem({
    required this.id,
    required this.name,
    required this.category,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stock,
    required this.createdAt,
    required this.userId,
  });

  /// Hitung potensi keuntungan per unit
  double get profitPerUnit => sellingPrice - purchasePrice;

  /// Hitung persentase margin keuntungan
  double get marginPercentage {
    if (sellingPrice <= 0) return 0.0;
    return (profitPerUnit / sellingPrice) * 100;
  }

  /// Konversi dari Document Snapshot Firestore
  factory ProductItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProductItem(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? 'Umum',
      purchasePrice: (data['purchase_price'] is num)
          ? (data['purchase_price'] as num).toDouble()
          : 0.0,
      sellingPrice: (data['selling_price'] is num)
          ? (data['selling_price'] as num).toDouble()
          : 0.0,
      stock: (data['stock'] is num) ? (data['stock'] as num).toInt() : 0,
      createdAt: (data['created_at'] is Timestamp)
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      userId: data['user_id'] ?? '',
    );
  }

  /// Konversi ke Map untuk disimpan ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'stock': stock,
      'created_at': Timestamp.fromDate(createdAt),
      'user_id': userId,
    };
  }
}
