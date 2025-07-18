class Product {
  final int? id;
  final String name;
  final int price;
  final String unit;
  final int quantity;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.unit, 
    required this.quantity,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'price': price,
        'unit': unit,
      };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'],
        name: map['name'],
        price: map['price'],
        unit: map['unit'], 
        quantity: map['quantity'],
      );
}
