class TransactionItem {
  final int? id;
  final int transactionId;
  final int productId;
  final int quantity;
  final int price;

  TransactionItem({
    this.id,
    required this.transactionId,
    required this.productId,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'transaction_id': transactionId,
        'product_id': productId,
        'quantity': quantity,
        'price': price,
      };

  factory TransactionItem.fromMap(Map<String, dynamic> map) => TransactionItem(
        id: map['id'],
        transactionId: map['transaction_id'],
        productId: map['product_id'],
        quantity: map['quantity'],
        price: map['price'],
      );
}
