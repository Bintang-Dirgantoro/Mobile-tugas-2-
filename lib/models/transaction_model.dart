import 'package:cloud_firestore/cloud_firestore.dart';

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

  String get orderTypeLabel => isTakeAway ? 'Bungkus' : 'Makan di Sini';

  String get displayIdentifier {
    if (queueNumber.isNotEmpty) {
      return 'Antrean #$queueNumber';
    } else if (tableNumber.isNotEmpty) {
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
      transactionCode: data['transaction_code'] ?? 'KYN-000000-000',
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
