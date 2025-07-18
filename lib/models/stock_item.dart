class StockItem {
  final int? id;
  final String name;
  final int quantity;
  final String unit;

  StockItem({
    this.id,
    required this.name,
    required this.quantity,
    required this.unit,
  });

  factory StockItem.fromMap(Map<String, dynamic> map) {
    return StockItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      quantity: map['quantity'] as int,
      unit: map['unit'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
    };
  }
}
