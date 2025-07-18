import 'package:flutter/material.dart';
import '../models/product.dart';
import '../db/database_helper.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('products');
    setState(() {
      products = result.map((e) => Product.fromMap(e)).toList();
    });
  }

  Future<void> _editProductPrice(Product product) async {
    final controller = TextEditingController(text: product.price.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Harga: ${product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Harga Baru'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPrice = int.tryParse(controller.text) ?? product.price;
              final db = await DatabaseHelper.instance.database;
              await db.update(
                'products',
                {'price': newPrice},
                where: 'id = ?',
                whereArgs: [product.id],
              );
              Navigator.pop(context);
              _loadProducts();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produk')),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (_, index) {
          final p = products[index];
          return ListTile(
            title: Text(p.name),
            subtitle: Text('Rp${p.price} / ${p.unit}'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editProductPrice(p),
            ),
          );
        },
      ),
    );
  }
}
