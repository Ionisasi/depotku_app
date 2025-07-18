class DepotTransaction {
  final int? id;
  final int? customerId;
  final String date;
  final int totalAmount;

  DepotTransaction({
    this.id,
    this.customerId,
    required this.date,
    required this.totalAmount,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'customer_id': customerId,
        'date': date,
        'total_amount': totalAmount,
      };

  factory DepotTransaction.fromMap(Map<String, dynamic> map) =>
      DepotTransaction(
        id: map['id'],
        customerId: map['customer_id'],
        date: map['date'],
        totalAmount: map['total_amount'],
      );
}
