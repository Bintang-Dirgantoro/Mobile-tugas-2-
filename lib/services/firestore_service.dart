import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../data/menu_presets.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../models/inventory_movement_model.dart';

// Re-export models for convenient global access and 100% backward compatibility
export '../models/product_model.dart';
export '../models/transaction_model.dart';
export '../models/inventory_movement_model.dart';

// ==========================================
// SERVICE LAYER CLOUD FIRESTORE
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

  /// Reset database Firestore:
  /// - Menghapus seluruh transaksi
  /// - Menghapus seluruh riwayat mutasi stok
  /// - Menghapus seluruh master produk
  /// - Jika [reseedWithPresets] true, mengisi ulang dengan template MenuPresets segar
  /// CATATAN: Firebase Authentication TIDAK disentuh sama sekali (akun tetap aman).
  Future<void> resetFirestoreDatabase({bool reseedWithPresets = true}) async {
    try {
      Future<void> safeDeleteCollection(String collectionName) async {
        try {
          final snap = await _db.collection(collectionName).get();
          if (snap.docs.isEmpty) return;

          for (final doc in snap.docs) {
            try {
              await doc.reference.delete();
            } catch (err) {
              debugPrint('Lewati dokumen ${doc.id} di $collectionName: $err');
            }
          }
        } catch (e) {
          debugPrint('Gagal membaca koleksi $collectionName: $e');
        }
      }

      // 1. Hapus transaksi penjualan kasir (paling penting agar antrean reset ke 01)
      await safeDeleteCollection(_collectionTransactions);

      // 2. Hapus master produk lama
      await safeDeleteCollection(_collectionProducts);

      // 3. Bersihkan log mutasi stok jika ada izin
      await safeDeleteCollection(_collectionMovements);

      // 4. Muat ulang katalog starter menu segar
      if (reseedWithPresets && MenuPresets.items.isNotEmpty) {
        await importPresetMenu(MenuPresets.items);
      }
    } catch (e) {
      throw Exception('Gagal mereset Firestore: $e');
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

  /// Generate nomor transaksi dengan format: KYN-DDMMYY-XXX (contoh: KYN-190926-001)
  Future<String> generateTransactionCode() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final dd = now.day.toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final yy = (now.year % 100).toString().padLeft(2, '0');
    final datePrefix = 'KYN-$dd$mm$yy';

    try {
      QuerySnapshot<Map<String, dynamic>> snap;
      try {
        snap = await _db
            .collection(_collectionTransactions)
            .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .get();
      } catch (_) {
        snap = await _db.collection(_collectionTransactions).get();
      }

      int count = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final createdAt = (data['created_at'] is Timestamp)
            ? (data['created_at'] as Timestamp).toDate()
            : null;

        final isToday = createdAt != null &&
            createdAt.year == now.year &&
            createdAt.month == now.month &&
            createdAt.day == now.day;

        if (isToday) {
          count++;
        }
      }

      final inc = (count + 1).toString().padLeft(3, '0');
      return '$datePrefix-$inc';
    } catch (_) {
      return '$datePrefix-001';
    }
  }

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

    final code = await generateTransactionCode();
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
  /// Mendapatkan nomor antrean berikutnya untuk hari ini (format '01', '02', dst.)
  Future<String> getNextQueueNumber() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      QuerySnapshot<Map<String, dynamic>> snap;
      try {
        snap = await _db
            .collection(_collectionTransactions)
            .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .get();
      } catch (_) {
        // Fallback jika query index Firestore bermasalah, ambil seluruh transaksi dan filter di memori
        snap = await _db.collection(_collectionTransactions).get();
      }

      int count = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final createdAt = (data['created_at'] is Timestamp)
            ? (data['created_at'] as Timestamp).toDate()
            : null;

        final isToday = createdAt != null &&
            createdAt.year == now.year &&
            createdAt.month == now.month &&
            createdAt.day == now.day;

        if (isToday) {
          count++;
        }
      }
      return (count + 1).toString().padLeft(2, '0');
    } catch (_) {
      // Fallback aman: selalu mulai dari '01'
      return '01';
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
