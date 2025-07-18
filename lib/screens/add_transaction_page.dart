import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../main.dart';
import '../db/database_helper.dart';
import '../models/product.dart';
import '../models/customer.dart'; // pastikan ini ada

class AddTransactionPage extends StatefulWidget {
  final int? transactionId;
  const AddTransactionPage({this.transactionId, super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _customerController = TextEditingController();
  List<Customer> _customerList = [];
  List<Product> _productList = [];
  Map<String, int> _stockMap = {};
  final List<Map<String, dynamic>> _selectedItems = [];
  int totalAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.transactionId != null) {
      _loadExistingTransaction(widget.transactionId!);
    }
  }

  Future<void> _loadData() async {
    final db = await DatabaseHelper.instance.database;
    final productResult = await db.query('products');
    final stockResult = await db.query('stock_items');
    final customerResult = await db.query('customers');

    setState(() {
      _productList = productResult.map((e) => Product.fromMap(e)).toList();
      _customerList = customerResult.map((e) => Customer.fromMap(e)).toList();
      _stockMap = {
        for (var s in stockResult) s['name'] as String: s['quantity'] as int
      };
    });
  }

  Future<void> _loadExistingTransaction(int trxId) async {
    final db = await DatabaseHelper.instance.database;

    final trx = await db.query('transactions', where: 'id = ?', whereArgs: [trxId]);
    if (trx.isNotEmpty) {
      final customerId = trx.first['customer_id'];
      final customer = await db.query('customers', where: 'id = ?', whereArgs: [customerId]);
      if (customer.isNotEmpty) {
        final c = Customer.fromMap(customer.first);
        _customerController.text = c.name;
      }
      totalAmount = trx.first['total_amount'] as int;
    }

    final items = await db.rawQuery('''
      SELECT ti.*, p.name, p.price, p.unit FROM transaction_items ti
      JOIN products p ON p.id = ti.product_id
      WHERE ti.transaction_id = ?
    ''', [trxId]);

    for (var item in items) {
      final product = Product(
        id: item['product_id'] as int,
        name: item['name'] as String,
        price: item['price'] as int,
        unit: item['unit'] as String,
        quantity: 0,
      );
      final qty = item['quantity'] as int;

      await _tambahStokSesuaiProduk(db, product.name, qty);

      _selectedItems.add({
        'product': product,
        'quantity': qty,
        'subtotal': product.price * qty,
      });
    }

    await _loadData();
  }

  void _addOrEditProduct(Product product, {bool isEdit = false, int editIndex = -1}) {
    final controller = TextEditingController(
      text: isEdit ? _selectedItems[editIndex]['quantity'].toString() : '',
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${isEdit ? "Edit" : "Tambah"}: ${product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Jumlah'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(controller.text) ?? 0;
              if (qty > 0) {
                setState(() {
                  if (isEdit) {
                    final oldQty = _selectedItems[editIndex]['quantity'];
                    final oldSubtotal = _selectedItems[editIndex]['subtotal'];
                    final priceDiff = (qty - oldQty) * product.price;
                    _selectedItems[editIndex]['quantity'] = qty;
                    _selectedItems[editIndex]['subtotal'] = oldSubtotal + priceDiff;
                    totalAmount += priceDiff as int;
                  } else {
                    _selectedItems.add({
                      'product': product,
                      'quantity': qty,
                      'subtotal': product.price * qty,
                    });
                    totalAmount += product.price * qty;
                  }
                });
              }
              Navigator.pop(context);
            },
            child: Text(isEdit ? 'Simpan' : 'Tambah'),
          ),
        ],
      ),
    );
  }

  Future<void> _tambahStokItem(Database db, String name, int jumlah) async {
    final result = await db.query('stock_items', where: 'name = ?', whereArgs: [name]);
    if (result.isNotEmpty) {
      final currentQty = result.first['quantity'] as int;
      await db.update('stock_items', {'quantity': currentQty + jumlah}, where: 'name = ?', whereArgs: [name]);
    }
  }

  Future<void> _kurangiStokItem(Database db, String name, int jumlah) async {
    final result = await db.query('stock_items', where: 'name = ?', whereArgs: [name]);
    if (result.isNotEmpty) {
      final currentQty = result.first['quantity'] as int;
      if (currentQty >= jumlah) {
        await db.update('stock_items', {'quantity': currentQty - jumlah}, where: 'name = ?', whereArgs: [name]);
      } else {
        throw Exception('Stok "$name" tidak mencukupi (tersisa $currentQty, butuh $jumlah).');
      }
    } else {
      throw Exception('Item "$name" tidak ditemukan di stok.');
    }
  }

  Future<void> _tambahStokSesuaiProduk(Database db, String name, int qty) async {
    if (name == 'Isi Ulang Galon 19L') {
      await _tambahStokItem(db, 'Tutup Botol', qty);
      await _tambahStokItem(db, 'Air', qty * 19);
    } else if (name == 'Galon Isi 19L') {
      await _tambahStokItem(db, 'Galon Kosong 19L', qty);
      await _tambahStokItem(db, 'Tutup Botol', qty);
      await _tambahStokItem(db, 'Tisu', qty);
      await _tambahStokItem(db, 'Air', qty * 19);
    } else if (name == 'Galon Kosong 19L') {
      await _tambahStokItem(db, 'Galon Kosong 19L', qty);
    }
  }

  int _hitungStokTersedia(String productName) {
    if (productName == 'Isi Ulang Galon 19L') {
      final tutup = _stockMap['Tutup Botol'] ?? 0;
      final air = (_stockMap['Air'] ?? 0) ~/ 19;
      return tutup < air ? tutup : air;
    } else if (productName == 'Galon Isi 19L') {
      final galon = _stockMap['Galon Kosong 19L'] ?? 0;
      final tutup = _stockMap['Tutup Botol'] ?? 0;
      final tisu = _stockMap['Tisu'] ?? 0;
      final air = (_stockMap['Air'] ?? 0) ~/ 19;
      return [galon, tutup, tisu, air].reduce((a, b) => a < b ? a : b);
    } else if (productName == 'Galon Kosong 19L') {
      return _stockMap['Galon Kosong 19L'] ?? 0;
    }
    return 9999;
  }

  Future<void> _saveTransaction() async {
    if (_selectedItems.isEmpty || _customerController.text.trim().isEmpty) return;

    final db = await DatabaseHelper.instance.database;
    final customerName = _customerController.text.trim();

    if (widget.transactionId != null) {
      final oldItems = await db.rawQuery('''
        SELECT ti.quantity, p.name
        FROM transaction_items ti
        JOIN products p ON p.id = ti.product_id
        WHERE ti.transaction_id = ?
      ''', [widget.transactionId]);

      for (var item in oldItems) {
        await _tambahStokSesuaiProduk(db, item['name'] as String, item['quantity'] as int);
      }
    }

    int customerId;
    final existingCustomer = await db.query('customers', where: 'name = ?', whereArgs: [customerName]);
    if (existingCustomer.isEmpty) {
      customerId = await db.insert('customers', {'name': customerName});
    } else {
      customerId = existingCustomer.first['id'] as int;
    }

    final now = DateFormat('yyyy-MM-dd').format(DateTime.now());
    int trxId;

    if (widget.transactionId == null) {
      trxId = await db.insert('transactions', {
        'customer_id': customerId,
        'date': now,
        'total_amount': totalAmount,
      });
    } else {
      trxId = widget.transactionId!;
      await db.update('transactions', {
        'customer_id': customerId,
        'date': now,
        'total_amount': totalAmount,
      }, where: 'id = ?', whereArgs: [trxId]);
      await db.delete('transaction_items', where: 'transaction_id = ?', whereArgs: [trxId]);
    }

    try {
      for (var item in _selectedItems) {
        final product = item['product'] as Product;
        final qty = item['quantity'] as int;
        final name = product.name;

        // validasi stok
        if (name == 'Isi Ulang Galon 19L') {
          if ((_stockMap['Tutup Botol'] ?? 0) < qty) throw 'Stok "Tutup Botol" tidak mencukupi';
          if ((_stockMap['Air'] ?? 0) < qty * 19) throw 'Stok "Air" tidak mencukupi';
        } else if (name == 'Galon Isi 19L') {
          if ((_stockMap['Galon Kosong 19L'] ?? 0) < qty) throw 'Stok "Galon Kosong 19L" tidak mencukupi';
          if ((_stockMap['Tutup Botol'] ?? 0) < qty) throw 'Stok "Tutup Botol" tidak mencukupi';
          if ((_stockMap['Tisu'] ?? 0) < qty) throw 'Stok "Tisu" tidak mencukupi';
          if ((_stockMap['Air'] ?? 0) < qty * 19) throw 'Stok "Air" tidak mencukupi';
        } else if (name == 'Galon Kosong 19L') {
          if ((_stockMap['Galon Kosong 19L'] ?? 0) < qty) throw 'Stok tidak cukup';
        }

        await db.insert('transaction_items', {
          'transaction_id': trxId,
          'product_id': product.id,
          'quantity': qty,
          'price': product.price,
        });

        // kurangi stok
        if (name == 'Isi Ulang Galon 19L') {
          await _kurangiStokItem(db, 'Tutup Botol', qty);
          await _kurangiStokItem(db, 'Air', qty * 19);
        } else if (name == 'Galon Isi 19L') {
          await _kurangiStokItem(db, 'Galon Kosong 19L', qty);
          await _kurangiStokItem(db, 'Tutup Botol', qty);
          await _kurangiStokItem(db, 'Tisu', qty);
          await _kurangiStokItem(db, 'Air', qty * 19);
        } else if (name == 'Galon Kosong 19L') {
          await _kurangiStokItem(db, 'Galon Kosong 19L', qty);
        }
      }

      if (context.mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainPage()));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi berhasil disimpan.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
        );
      }
      if (widget.transactionId == null) {
        await db.delete('transactions', where: 'id = ?', whereArgs: [trxId]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.transactionId == null ? 'Tambah Transaksi' : 'Edit Transaksi')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Autocomplete<Customer>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                // Tampilkan semua jika kosong atau ketik sebagian
                if (textEditingValue.text == '') {
                  return _customerList;
                }
                return _customerList.where((Customer customer) =>
                    customer.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              displayStringForOption: (Customer customer) => customer.name,
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                // Hubungkan controller yang dipakai sistem autocomplete dengan controller utama
                textEditingController.text = _customerController.text;
                textEditingController.selection = _customerController.selection;

                // Update _customerController setiap user mengetik
                textEditingController.addListener(() {
                  _customerController.value = textEditingController.value;
                });

                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: const InputDecoration(labelText: 'Nama Pelanggan'),
                  onTap: () {
                    // Trigger dropdown dengan memaksa rebuild agar options muncul saat tap
                    if (textEditingController.text == '') {
                      textEditingController.text = ' ';
                      textEditingController.selection = TextSelection.collapsed(offset: 1);
                      Future.delayed(Duration.zero, () {
                        textEditingController.clear();
                      });
                    }
                  },
                );
              },
              onSelected: (Customer selection) {
                _customerController.text = selection.name;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Product>(
              items: _productList.map((p) {
                final stokTersisa = _hitungStokTersedia(p.name);
                return DropdownMenuItem(
                  value: p,
                  child: Text('${p.name} (Stok: $stokTersisa)'),
                );
              }).toList(),
              onChanged: (product) {
                if (product != null) _addOrEditProduct(product);
              },
              decoration: const InputDecoration(labelText: 'Pilih Produk'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _selectedItems.length,
                itemBuilder: (_, index) {
                  final item = _selectedItems[index];
                  final product = item['product'] as Product;
                  return ListTile(
                    title: Text(product.name),
                    subtitle: Text('${item['quantity']} x Rp${product.price}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _addOrEditProduct(product, isEdit: true, editIndex: index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              totalAmount -= item['subtotal'] as int;
                              _selectedItems.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Text('Total: Rp$totalAmount', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _saveTransaction,
              icon: const Icon(Icons.save),
              label: const Text('Simpan Transaksi'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            )
          ],
        ),
      ),
    );
  }
}
