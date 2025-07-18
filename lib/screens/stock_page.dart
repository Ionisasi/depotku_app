import 'package:flutter/material.dart';
import '../models/stock_item.dart';
import '../db/database_helper.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  List<StockItem> stockItems = [];

  @override
  void initState() {
    super.initState();
    _loadStockItems();
  }

  Future<void> _loadStockItems() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('stock_items');
    setState(() {
      stockItems = result.map((e) => StockItem.fromMap(e)).toList();
    });
  }

  Future<void> _editStockItem(StockItem item) async {
    final controller = TextEditingController(text: item.quantity.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Stok: ${item.name}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Jumlah Stok Baru'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final newQty = int.tryParse(controller.text) ?? item.quantity;
              final db = await DatabaseHelper.instance.database;
              await db.update(
                'stock_items',
                {'quantity': newQty},
                where: 'id = ?',
                whereArgs: [item.id],
              );
              Navigator.pop(context);
              await _loadStockItems();
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
      appBar: AppBar(title: const Text('Stok Barang')),
      body: ListView.builder(
        itemCount: stockItems.length,
        itemBuilder: (_, index) {
          final item = stockItems[index];
          return ListTile(
            title: Text(item.name),
            subtitle: Text('Jumlah: ${item.quantity} ${item.unit}'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editStockItem(item),
            ),
          );
        },
      ),
    );
  }
}
