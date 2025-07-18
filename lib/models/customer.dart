class Customer {
  final int? id;
  final String name;
  final String? phone;

  Customer({
    this.id,
    required this.name,
    this.phone,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
      };

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'],
        name: map['name'],
        phone: map['phone'],
      );
}
