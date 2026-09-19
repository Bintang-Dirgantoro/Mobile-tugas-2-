import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ==========================================
// 1. MODEL PRODUK (MASTER MENU)
// ==========================================

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

// ==========================================
// 2. MODEL TRANSAKSI PENJUALAN
// ==========================================

/// Item detail dalam transaksi penjualan
class TransactionItem {
  final String productId;
  final String productName;
  final int quantity;
  final double purchasePrice;
  final double sellingPrice;
  final double subtotal;

  TransactionItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'subtotal': subtotal,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      productId: map['product_id'] ?? '',
      productName: map['product_name'] ?? '',
      quantity: (map['quantity'] is num) ? (map['quantity'] as num).toInt() : 1,
      purchasePrice: (map['purchase_price'] is num) ? (map['purchase_price'] as num).toDouble() : 0.0,
      sellingPrice: (map['selling_price'] is num) ? (map['selling_price'] as num).toDouble() : 0.0,
      subtotal: (map['subtotal'] is num) ? (map['subtotal'] as num).toDouble() : 0.0,
    );
  }
}

/// Dokumen Transaksi Penjualan Lengkap
class TransactionModel {
  final String id;
  final String transactionCode;
  final DateTime createdAt;
  final double totalAmount;
  final double totalCost;
  final int totalItems;
  final List<TransactionItem> items;
  final String userId;

  TransactionModel({
    required this.id,
    required this.transactionCode,
    required this.createdAt,
    required this.totalAmount,
    required this.totalCost,
    required this.totalItems,
    required this.items,
    required this.userId,
  });

  double get profit => totalAmount - totalCost;

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawItems = data['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((item) => TransactionItem.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();

    return TransactionModel(
      id: doc.id,
      transactionCode: data['transaction_code'] ?? '#TRX-000',
      createdAt: (data['created_at'] is Timestamp)
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      totalAmount: (data['total_amount'] is num)
          ? (data['total_amount'] as num).toDouble()
          : 0.0,
      totalCost: (data['total_cost'] is num)
          ? (data['total_cost'] as num).toDouble()
          : 0.0,
      totalItems: (data['total_items'] is num)
          ? (data['total_items'] as num).toInt()
          : 0,
      items: items,
      userId: data['user_id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'transaction_code': transactionCode,
      'created_at': Timestamp.fromDate(createdAt),
      'total_amount': totalAmount,
      'total_cost': totalCost,
      'total_items': totalItems,
      'items': items.map((e) => e.toMap()).toList(),
      'user_id': userId,
    };
  }
}

// ==========================================
// 3. MODEL MUTASI STOK (INVENTORY MOVEMENT)
// ==========================================

/// Model Riwayat Pergerakan Stok
class InventoryMovement {
  final String id;
  final String productId;
  final String productName;
  final String type; // 'IN' atau 'OUT'
  final int quantity;
  final String reason; // 'Penjualan', 'Restock', 'Produk Rusak', 'Kedaluwarsa', 'Penyesuaian'
  final DateTime createdAt;
  final String userId;

  InventoryMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.reason,
    required this.createdAt,
    required this.userId,
  });

  factory InventoryMovement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return InventoryMovement(
      id: doc.id,
      productId: data['product_id'] ?? '',
      productName: data['product_name'] ?? '',
      type: data['type'] ?? 'OUT',
      quantity: (data['quantity'] is num) ? (data['quantity'] as num).toInt() : 0,
      reason: data['reason'] ?? 'Penjualan',
      createdAt: (data['created_at'] is Timestamp)
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      userId: data['user_id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'product_name': productName,
      'type': type,
      'quantity': quantity,
      'reason': reason,
      'created_at': Timestamp.fromDate(createdAt),
      'user_id': userId,
    };
  }
}

// ==========================================
// 4. SERVICE LAYER CLOUD FIRESTORE
// ==========================================

/// Service untuk Operasi Cloud Firestore (Produk, Transaksi, dan Mutasi Stok)
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionProducts = 'products';
  final String _collectionTransactions = 'transactions';
  final String _collectionMovements = 'inventory_movements';

  /// Mendapatkan ID user saat ini (jika login)
  String get _currentUserId =>
      FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

  // ----------------------------------------------------
  // A. OPERASI MASTER PRODUK (CRUD)
  // ----------------------------------------------------

  /// Stream data master produk secara realtime
  Stream<List<ProductItem>> getProductsStream() {
    return _db
        .collection(_collectionProducts)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ProductItem.fromFirestore(doc)).toList();
    });
  }

  /// Tambah data master produk baru
  Future<void> addProduct({
    required String name,
    required String category,
    required double purchasePrice,
    required double sellingPrice,
    required int stock,
  }) async {
    try {
      final docRef = await _db.collection(_collectionProducts).add({
        'name': name.trim(),
        'category': category.trim(),
        'purchase_price': purchasePrice,
        'selling_price': sellingPrice,
        'stock': stock,
        'created_at': FieldValue.serverTimestamp(),
        'user_id': _currentUserId,
      });

      // Jika stok awal > 0, catat sebagai mutasi stok masuk awal
      if (stock > 0) {
        await _db.collection(_collectionMovements).add({
          'product_id': docRef.id,
          'product_name': name.trim(),
          'type': 'IN',
          'quantity': stock,
          'reason': 'Stok Awal Produk',
          'created_at': FieldValue.serverTimestamp(),
          'user_id': _currentUserId,
        });
      }
    } catch (e) {
      throw Exception('Gagal menambahkan produk: $e');
    }
  }

  /// Perbarui data master produk
  Future<void> updateProduct({
    required String id,
    required String name,
    required String category,
    required double purchasePrice,
    required double sellingPrice,
    required int stock,
  }) async {
    try {
      await _db.collection(_collectionProducts).doc(id).update({
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

  /// Hapus data master produk
  Future<void> deleteProduct(String id) async {
    try {
      await _db.collection(_collectionProducts).doc(id).delete();
    } catch (e) {
      throw Exception('Gagal menghapus produk: $e');
    }
  }

  // ----------------------------------------------------
  // B. OPERASI TRANSAKSI PENJUALAN (SALES)
  // ----------------------------------------------------

  /// Eksekusi transaksi penjualan secara atomik:
  /// 1. Cek ketersediaan stok setiap produk.
  /// 2. Kurangi stok produk.
  /// 3. Simpan dokumen transaksi.
  /// 4. Catat mutasi stok keluar (type: OUT, reason: Penjualan).
  Future<String> createSaleTransaction(List<TransactionItem> items) async {
    if (items.isEmpty) {
      throw Exception('Keranjang transaksi tidak boleh kosong!');
    }

    final code = '#TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    final nowTimestamp = FieldValue.serverTimestamp();

    double totalAmount = 0.0;
    double totalCost = 0.0;
    int totalItems = 0;

    for (final it in items) {
      totalAmount += it.subtotal;
      totalCost += (it.purchasePrice * it.quantity);
      totalItems += it.quantity;
    }

    try {
      await _db.runTransaction((transaction) async {
        // 1. Baca semua dokumen produk untuk validasi stok
        final Map<String, DocumentSnapshot> productSnapshots = {};
        for (final it in items) {
          final docRef = _db.collection(_collectionProducts).doc(it.productId);
          final snap = await transaction.get(docRef);
          if (!snap.exists) {
            throw Exception('Produk "${it.productName}" sudah tidak ada di database!');
          }
          productSnapshots[it.productId] = snap;
        }

        // 2. Verifikasi stok setiap produk (TIDAK BOLEH NEGATIF)
        for (final it in items) {
          final snap = productSnapshots[it.productId]!;
          final data = snap.data() as Map<String, dynamic>? ?? {};
          final currentStock = (data['stock'] is num) ? (data['stock'] as num).toInt() : 0;

          if (currentStock < it.quantity) {
            throw Exception(
              'Stok "${it.productName}" tidak mencukupi!\n(Sisa stok: $currentStock unit, diminta: ${it.quantity} unit)',
            );
          }
        }

        // 3. Kurangi stok produk secara atomik
        for (final it in items) {
          final docRef = _db.collection(_collectionProducts).doc(it.productId);
          final snap = productSnapshots[it.productId]!;
          final data = snap.data() as Map<String, dynamic>? ?? {};
          final currentStock = (data['stock'] is num) ? (data['stock'] as num).toInt() : 0;

          transaction.update(docRef, {
            'stock': currentStock - it.quantity,
            'updated_at': nowTimestamp,
          });
        }

        // 4. Simpan dokumen transaksi penjualan
        final trxDocRef = _db.collection(_collectionTransactions).doc();
        transaction.set(trxDocRef, {
          'transaction_code': code,
          'created_at': nowTimestamp,
          'total_amount': totalAmount,
          'total_cost': totalCost,
          'total_items': totalItems,
          'items': items.map((e) => e.toMap()).toList(),
          'user_id': _currentUserId,
        });

        // 5. Catat riwayat mutasi stok untuk setiap produk
        for (final it in items) {
          final movDocRef = _db.collection(_collectionMovements).doc();
          transaction.set(movDocRef, {
            'product_id': it.productId,
            'product_name': it.productName,
            'type': 'OUT',
            'quantity': it.quantity,
            'reason': 'Penjualan $code',
            'created_at': nowTimestamp,
            'user_id': _currentUserId,
          });
        }
      });

      return code;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Stream daftar riwayat transaksi penjualan (dengan filter tanggal opsional)
  Stream<List<TransactionModel>> getTransactionsStream({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _db
        .collection(_collectionTransactions)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();

      if (startDate != null || endDate != null) {
        return list.where((trx) {
          if (startDate != null && trx.createdAt.isBefore(startDate)) {
            return false;
          }
          if (endDate != null && trx.createdAt.isAfter(endDate)) {
            return false;
          }
          return true;
        }).toList();
      }

      return list;
    });
  }

  // ----------------------------------------------------
  // C. OPERASI MUTASI INVENTARIS & PENYESUAIAN STOK
  // ----------------------------------------------------

  /// Penyesuaian stok secara manual:
  /// - type: 'IN' (Restock / Tambah Stok)
  /// - type: 'OUT' (Produk Rusak, Kedaluwarsa, Penyesuaian)
  Future<void> adjustStock({
    required String productId,
    required String productName,
    required String type, // 'IN' atau 'OUT'
    required int quantity,
    required String reason,
  }) async {
    if (quantity <= 0) {
      throw Exception('Jumlah kuantitas harus lebih dari 0!');
    }

    final docRef = _db.collection(_collectionProducts).doc(productId);
    final nowTimestamp = FieldValue.serverTimestamp();

    try {
      await _db.runTransaction((transaction) async {
        final snap = await transaction.get(docRef);
        if (!snap.exists) {
          throw Exception('Produk tidak ditemukan!');
        }

        final data = snap.data() ?? {};
        final currentStock = (data['stock'] is num) ? (data['stock'] as num).toInt() : 0;

        if (type == 'OUT' && currentStock < quantity) {
          throw Exception(
            'Stok tidak mencukupi untuk dikeluarkan!\n(Sisa stok saat ini: $currentStock unit)',
          );
        }

        final newStock = type == 'IN' ? currentStock + quantity : currentStock - quantity;

        transaction.update(docRef, {
          'stock': newStock,
          'updated_at': nowTimestamp,
        });

        final movDocRef = _db.collection(_collectionMovements).doc();
        transaction.set(movDocRef, {
          'product_id': productId,
          'product_name': productName,
          'type': type,
          'quantity': quantity,
          'reason': reason.trim(),
          'created_at': nowTimestamp,
          'user_id': _currentUserId,
        });
      });
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Stream riwayat mutasi stok
  Stream<List<InventoryMovement>> getInventoryMovementsStream({String? productId}) {
    return _db
        .collection(_collectionMovements)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => InventoryMovement.fromFirestore(doc)).toList();
      if (productId != null && productId.isNotEmpty) {
        return list.where((m) => m.productId == productId).toList();
      }
      return list;
    });
  }
}
