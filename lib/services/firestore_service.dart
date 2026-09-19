import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/menu_presets.dart';

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

/// Hasil kembalian pembuatan transaksi baru
class CreateTransactionResult {
  final String id;
  final String code;
  final double totalAmount;
  final double totalCost;
  final int totalItems;

  CreateTransactionResult({
    required this.id,
    required this.code,
    required this.totalAmount,
    required this.totalCost,
    required this.totalItems,
  });
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
  final String status; // 'MENUNGGU_PEMBAYARAN' atau 'LUNAS'
  final String customerName; // '[Dine In] Meja 1' atau '[Take Away] Antrean #01'
  final String orderType; // 'DINE_IN' atau 'TAKE_AWAY'
  final String tableNumber; // 'Meja 1' (jika Dine In)
  final String queueNumber; // '01' (jika Take Away)
  final String? paymentMethod; // 'Tunai' atau 'QRIS'
  final DateTime? paidAt;

  TransactionModel({
    required this.id,
    required this.transactionCode,
    required this.createdAt,
    required this.totalAmount,
    required this.totalCost,
    required this.totalItems,
    required this.items,
    required this.userId,
    this.status = 'MENUNGGU_PEMBAYARAN',
    this.customerName = 'Pelanggan (Anonymous)',
    this.orderType = 'DINE_IN',
    this.tableNumber = '',
    this.queueNumber = '',
    this.paymentMethod,
    this.paidAt,
  });

  bool get isPaid => status == 'LUNAS';
  bool get isPending => status == 'MENUNGGU_PEMBAYARAN';
  bool get isDineIn => orderType == 'DINE_IN';
  bool get isTakeAway => orderType == 'TAKE_AWAY';

  String get orderTypeLabel => isTakeAway ? 'Take Away (Bungkus)' : 'Dine In (Makan di Sini)';

  String get displayIdentifier {
    if (isTakeAway && queueNumber.isNotEmpty) {
      return 'Antrean #$queueNumber';
    } else if (isDineIn && tableNumber.isNotEmpty) {
      return tableNumber;
    }
    return customerName;
  }

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
      status: data['status'] ?? 'MENUNGGU_PEMBAYARAN',
      customerName: data['customer_name'] ?? 'Pelanggan (Anonymous)',
      orderType: data['order_type'] ?? 'DINE_IN',
      tableNumber: data['table_number'] ?? '',
      queueNumber: data['queue_number'] ?? '',
      paymentMethod: data['payment_method'],
      paidAt: (data['paid_at'] is Timestamp)
          ? (data['paid_at'] as Timestamp).toDate()
          : null,
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
      'status': status,
      'customer_name': customerName,
      'order_type': orderType,
      'table_number': tableNumber,
      'queue_number': queueNumber,
      'payment_method': paymentMethod,
      'paid_at': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
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

  /// Muat seluruh paket menu preset ke Firestore secara batch (cepat, instan & atomik)
  Future<int> importPresetMenu(List<PresetMenuItem> presetItems) async {
    try {
      final batch = _db.batch();
      final now = FieldValue.serverTimestamp();

      for (final it in presetItems) {
        final productDocRef = _db.collection(_collectionProducts).doc();
        batch.set(productDocRef, {
          'name': it.name.trim(),
          'category': it.category.trim(),
          'purchase_price': it.purchasePrice,
          'selling_price': it.sellingPrice,
          'stock': it.stock,
          'created_at': now,
          'user_id': _currentUserId,
        });

        if (it.stock > 0) {
          final movDocRef = _db.collection(_collectionMovements).doc();
          batch.set(movDocRef, {
            'product_id': productDocRef.id,
            'product_name': it.name.trim(),
            'type': 'IN',
            'quantity': it.stock,
            'reason': 'Template Menu Awal',
            'created_at': now,
            'user_id': _currentUserId,
          });
        }
      }

      await batch.commit();
      return presetItems.length;
    } catch (e) {
      throw Exception('Gagal memuat template menu: $e');
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

  /// Eksekusi transaksi penjualan baru oleh kasir:
  /// - Jika status == 'LUNAS': Stok langsung dipotong secara atomik & mutasi dicatat.
  /// - Jika status == 'MENUNGGU_PEMBAYARAN' (Stash): Stok TIDAK dipotong karena belum dibayar.
  Future<CreateTransactionResult> createSaleTransaction(
    List<TransactionItem> items, {
    String customerName = 'Pelanggan (Anonymous)',
    String orderType = 'DINE_IN',
    String tableNumber = '',
    String queueNumber = '',
    String status = 'LUNAS', // Default alur utama: langsung lunas
    String? paymentMethod,
  }) async {
    if (items.isEmpty) {
      throw Exception('Keranjang transaksi tidak boleh kosong!');
    }

    final code = '#TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    final nowTimestamp = FieldValue.serverTimestamp();
    final isSettled = status == 'LUNAS';

    double totalAmount = 0.0;
    double totalCost = 0.0;
    int totalItems = 0;

    for (final it in items) {
      totalAmount += it.subtotal;
      totalCost += (it.purchasePrice * it.quantity);
      totalItems += it.quantity;
    }

    try {
      final trxDocRef = _db.collection(_collectionTransactions).doc();

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

        // 2. Verifikasi ketersediaan stok
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

        // 3. LOGIKA STOK: HANYA POTONG STOK JIKA TRANSAKSI SUDAH LUNAS (DIBAYAR)
        // Jika status MENUNGGU_PEMBAYARAN (Stash), STOK TIDAK DIPOTONG!
        if (isSettled) {
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

          // Catat riwayat mutasi stok keluar (OUT)
          for (final it in items) {
            final movDocRef = _db.collection(_collectionMovements).doc();
            transaction.set(movDocRef, {
              'product_id': it.productId,
              'product_name': it.productName,
              'type': 'OUT',
              'quantity': it.quantity,
              'reason': 'Penjualan $code ($orderType)',
              'created_at': nowTimestamp,
              'user_id': _currentUserId,
            });
          }
        }

        // 4. Simpan dokumen transaksi penjualan
        transaction.set(trxDocRef, {
          'transaction_code': code,
          'created_at': nowTimestamp,
          'total_amount': totalAmount,
          'total_cost': totalCost,
          'total_items': totalItems,
          'items': items.map((e) => e.toMap()).toList(),
          'user_id': _currentUserId,
          'status': status,
          'customer_name': customerName,
          'order_type': orderType,
          'table_number': tableNumber,
          'queue_number': queueNumber,
          'payment_method': paymentMethod,
          'paid_at': isSettled ? nowTimestamp : null,
        });
      });

      return CreateTransactionResult(
        id: trxDocRef.id,
        code: code,
        totalAmount: totalAmount,
        totalCost: totalCost,
        totalItems: totalItems,
      );
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Pelunasan transaksi kasir yang tertahan (Stash):
  /// 1. Cek ketersediaan stok produk di database secara atomik.
  /// 2. POTONG STOK SEKARANG (karena pembayaran baru diterima).
  /// 3. Catat mutasi stok keluar (type: OUT).
  /// 4. Update status transaksi menjadi 'LUNAS'.
  Future<void> settleTransaction({
    required String transactionId,
    required String paymentMethod, // 'Tunai' atau 'QRIS'
  }) async {
    try {
      final trxRef = _db.collection(_collectionTransactions).doc(transactionId);
      final nowTimestamp = FieldValue.serverTimestamp();

      await _db.runTransaction((transaction) async {
        final trxSnap = await transaction.get(trxRef);
        if (!trxSnap.exists) {
          throw Exception('Dokumen transaksi tidak ditemukan!');
        }

        final trxData = trxSnap.data() ?? {};
        if (trxData['status'] == 'LUNAS') {
          // Sudah lunas sebelumnya, tidak perlu potong lagi
          return;
        }

        final rawItems = trxData['items'] as List<dynamic>? ?? [];
        final items = rawItems
            .map((item) => TransactionItem.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList();
        final code = trxData['transaction_code'] ?? '#TRX';
        final orderType = trxData['order_type'] ?? 'DINE_IN';

        // 1. Baca semua produk untuk cek stok
        final Map<String, DocumentSnapshot> productSnapshots = {};
        for (final it in items) {
          final docRef = _db.collection(_collectionProducts).doc(it.productId);
          final snap = await transaction.get(docRef);
          if (!snap.exists) {
            throw Exception('Produk "${it.productName}" sudah tidak ada di database!');
          }
          productSnapshots[it.productId] = snap;
        }

        // 2. Verifikasi stok mencukupi
        for (final it in items) {
          final snap = productSnapshots[it.productId]!;
          final data = snap.data() as Map<String, dynamic>? ?? {};
          final currentStock = (data['stock'] is num) ? (data['stock'] as num).toInt() : 0;

          if (currentStock < it.quantity) {
            throw Exception(
              'Stok "${it.productName}" tidak mencukupi untuk pelunasan!\n(Sisa stok: $currentStock unit, diminta: ${it.quantity} unit)',
            );
          }
        }

        // 3. POTONG STOK SEKARANG (karena transaksi sudah lunas dibayar)
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

        // 4. Catat mutasi stok keluar (type: OUT)
        for (final it in items) {
          final movDocRef = _db.collection(_collectionMovements).doc();
          transaction.set(movDocRef, {
            'product_id': it.productId,
            'product_name': it.productName,
            'type': 'OUT',
            'quantity': it.quantity,
            'reason': 'Pelunasan Stash $code ($orderType)',
            'created_at': nowTimestamp,
            'user_id': _currentUserId,
          });
        }

        // 5. Update status transaksi menjadi LUNAS
        transaction.update(trxRef, {
          'status': 'LUNAS',
          'payment_method': paymentMethod,
          'paid_at': nowTimestamp,
        });
      });
    } catch (e) {
      throw Exception('Gagal melakukan pelunasan transaksi: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  /// Batalkan pesanan tertahan (Stash).
  /// Karena saat di-stash stok BELUM dipotong, pembatalan pesanan ini
  /// tidak perlu mengembalikan stok (stok tetap aman).
  Future<void> cancelStashedTransaction(String transactionId) async {
    try {
      await _db.collection(_collectionTransactions).doc(transactionId).delete();
    } catch (e) {
      throw Exception('Gagal membatalkan transaksi tertahan: $e');
    }
  }

  /// Mendapatkan nomor antrean berikutnya untuk hari ini (format '01', '02', dst.)
  Future<String> getNextQueueNumber() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final snap = await _db
          .collection(_collectionTransactions)
          .where('user_id', isEqualTo: _currentUserId)
          .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      final count = snap.docs.length + 1;
      return count.toString().padLeft(2, '0');
    } catch (_) {
      final fallback = (DateTime.now().minute + 1).toString().padLeft(2, '0');
      return fallback;
    }
  }

  /// Stream transaksi khusus yang masih berstatus 'MENUNGGU_PEMBAYARAN' (antrean kasir)
  Stream<List<TransactionModel>> getPendingTransactionsStream() {
    return _db
        .collection(_collectionTransactions)
        .where('status', isEqualTo: 'MENUNGGU_PEMBAYARAN')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
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
