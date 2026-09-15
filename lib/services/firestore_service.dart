import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Model Produk UMKM
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

/// Service untuk Operasi Cloud Firestore
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'products';

  /// Mendapatkan ID user saat ini (jika login)
  String get _currentUserId =>
      FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

  /// Stream data produk secara realtime
  Stream<List<ProductItem>> getProductsStream() {
    return _db
        .collection(_collection)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ProductItem.fromFirestore(doc)).toList();
    });
  }

  /// Tambah data produk baru
  Future<void> addProduct({
    required String name,
    required String category,
    required double purchasePrice,
    required double sellingPrice,
    required int stock,
  }) async {
    try {
      await _db.collection(_collection).add({
        'name': name.trim(),
        'category': category.trim(),
        'purchase_price': purchasePrice,
        'selling_price': sellingPrice,
        'stock': stock,
        'created_at': FieldValue.serverTimestamp(),
        'user_id': _currentUserId,
      });
    } catch (e) {
      throw Exception('Gagal menambahkan produk: $e');
    }
  }

  /// Perbarui data produk
  Future<void> updateProduct({
    required String id,
    required String name,
    required String category,
    required double purchasePrice,
    required double sellingPrice,
    required int stock,
  }) async {
    try {
      await _db.collection(_collection).doc(id).update({
        'name': name.trim(),
        'category': category.trim(),
        'purchase_price': purchasePrice,
        'selling_price': sellingPrice,
        'stock': stock,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal memperbarui produk: $e');
    }
  }

  /// Hapus data produk
  Future<void> deleteProduct(String id) async {
    try {
      await _db.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Gagal menghapus produk: $e');
    }
  }
}
