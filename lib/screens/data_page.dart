import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';

class DataPage extends StatefulWidget {
  const DataPage({super.key});
  
  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  DateTimeRange? _selectedRange;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions({DateTimeRange? range}) async {
    final db = await DatabaseHelper.instance.database;
    final formatter = DateFormat('yyyy-MM-dd');

    String query = '''
      SELECT t.id, t.date, t.total_amount, c.name as customer_name
      FROM transactions t
      LEFT JOIN customers c ON c.id = t.customer_id
    ''';

    List<String> whereArgs = [];

    if (range != null) {
      final from = formatter.format(range.start);
      final to = formatter.format(range.end);
      query += ' WHERE t.date BETWEEN ? AND ?';
      whereArgs = [from, to];
    }

    query += ' ORDER BY t.date DESC';

    final result = await db.rawQuery(query, whereArgs);
    setState(() {
      _transactions = result;
    });
  }

  Future<void> _pickDateRange() async {
    DateTime now = DateTime.now();
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => _selectedRange = picked);
      _loadTransactions(range: picked);
    }
  }

  Future<void> _confirmDelete(int trxId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Hapus Transaksi'),
        content: Text('Yakin ingin menghapus transaksi ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('Hapus')),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteTransaction(trxId);
      _loadTransactions(range: _selectedRange);
    }
  }

  Future<void> _deleteTransaction(int trxId) async {
    final db = await DatabaseHelper.instance.database;

    final items = await db.rawQuery('''
      SELECT ti.quantity, p.name
      FROM transaction_items ti
      JOIN products p ON p.id = ti.product_id
      WHERE ti.transaction_id = ?
    ''', [trxId]);

    for (var item in items) {
      final qty = item['quantity'] as int;
      final name = item['name'] as String;

      if (name == 'Isi Ulang Galon 19L') {
        await db.rawUpdate('UPDATE stock_items SET quantity = quantity + ? WHERE name = ?', [qty, 'Tutup Botol']);
        await db.rawUpdate('UPDATE stock_items SET quantity = quantity + ? WHERE name = ?', [qty * 19, 'Air']);
      } else if (name == 'Galon Isi 19L') {
        await db.rawUpdate('UPDATE stock_items SET quantity = quantity + ? WHERE name = ?', [qty, 'Galon Kosong 19L']);
        await db.rawUpdate('UPDATE stock_items SET quantity = quantity + ? WHERE name = ?', [qty, 'Tutup Botol']);
        await db.rawUpdate('UPDATE stock_items SET quantity = quantity + ? WHERE name = ?', [qty, 'Tisu']);
        await db.rawUpdate('UPDATE stock_items SET quantity = quantity + ? WHERE name = ?', [qty * 19, 'Air']);
      } else if (name == 'Galon Kosong 19L') {
        await db.rawUpdate('UPDATE stock_items SET quantity = quantity + ? WHERE name = ?', [qty, 'Galon Kosong 19L']);
      }
    }

    await db.delete('transaction_items', where: 'transaction_id = ?', whereArgs: [trxId]);
    await db.delete('transactions', where: 'id = ?', whereArgs: [trxId]);
  }


  Future<void> _showTransactionDetail(int trxId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('''
      SELECT p.name, ti.quantity, ti.price
      FROM transaction_items ti
      JOIN products p ON p.id = ti.product_id
      WHERE ti.transaction_id = ?
    ''', [trxId]);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Detail Transaksi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: result.map((item) {
            return ListTile(
              title: Text(item['name'] as String),
              subtitle: Text('${item['quantity']} x Rp${item['price']}'),
              trailing: Text('Rp${(item['quantity'] as int) * (item['price'] as int)}'),
            );
          }).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Tutup')),
        ],
      ),
    );
  }

  Widget _transactionCard(Map<String, dynamic> trx) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: ListTile(
        title: Text('Rp${trx['total_amount']} - ${trx['customer_name'] ?? 'Umum'}'),
        subtitle: Text('Tanggal: ${trx['date']}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'detail') _showTransactionDetail(trx['id']);
            if (value == 'hapus') _confirmDelete(trx['id']);
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'detail', child: Text('Detail')),
            PopupMenuItem(value: 'hapus', child: Text('Hapus')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rangeText = _selectedRange != null
        ? '${DateFormat.yMMMd().format(_selectedRange!.start)} - ${DateFormat.yMMMd().format(_selectedRange!.end)}'
        : 'Semua Tanggal';

    return Scaffold(
      appBar: AppBar(
        title: Text('Data Penjualan'),
        actions: [
          IconButton(onPressed: _pickDateRange, icon: Icon(Icons.filter_alt)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Icon(Icons.date_range),
                SizedBox(width: 8),
                Text(rangeText, style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: _transactions.isEmpty
                ? Center(child: Text('Tidak ada data transaksi.'))
                : ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (_, index) => _transactionCard(_transactions[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
