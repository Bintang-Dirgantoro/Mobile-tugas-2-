import 'package:cloud_firestore/cloud_firestore.dart';

/// Model Riwayat Pergerakan Stok (Inventory Movement Audit Log)
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
