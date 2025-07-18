import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int totalLiter = 0;
  int totalToday = 0;
  int totalWeek = 0;
  int totalMonth = 0;
  Map<String, int> productSales = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final db = await DatabaseHelper.instance.database;

    // 1. Total stok air
    final water = await db.query('stock_items', where: 'name = ?', whereArgs: ['Air']);
    if (water.isNotEmpty) {
      totalLiter = water.first['quantity'] as int;
    }


    // 2. Total pendapatan
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd');

    final today = formatter.format(now);
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    final todayTrans = await db.rawQuery(
      "SELECT SUM(total_amount) as total FROM transactions WHERE date = ?",
      [today],
    );
    final weekTrans = await db.rawQuery(
      "SELECT SUM(total_amount) as total FROM transactions WHERE date >= ?",
      [formatter.format(monday)],
    );
    final monthTrans = await db.rawQuery(
      "SELECT SUM(total_amount) as total FROM transactions WHERE date >= ?",
      [formatter.format(firstDayOfMonth)],
    );

    totalToday = todayTrans.first['total'] != null ? todayTrans.first['total'] as int : 0;
    totalWeek = weekTrans.first['total'] != null ? weekTrans.first['total'] as int : 0;
    totalMonth = monthTrans.first['total'] != null ? monthTrans.first['total'] as int : 0;

    // 3. Total produk terjual
    final productSalesResult = await db.rawQuery('''
      SELECT p.name, SUM(ti.quantity) as total
      FROM transaction_items ti
      JOIN products p ON p.id = ti.product_id
      GROUP BY ti.product_id
    ''');

    productSales = {
      for (var row in productSalesResult) row['name'] as String: row['total'] as int
    };

    setState(() {});
  }

  Widget _infoCard(String title, String value, Color color) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        tileColor: color.withValues(alpha: 0.1),
        title: Text(title),
        trailing: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Beranda')),
      body: ListView(
        padding: EdgeInsets.all(8),
        children: [
          _infoCard('Total Stok Air (Liter)', '$totalLiter L', Colors.blue),
          _infoCard('Pendapatan Hari Ini', 'Rp$totalToday', Colors.green),
          _infoCard('Pendapatan Minggu Ini', 'Rp$totalWeek', Colors.green),
          _infoCard('Pendapatan Bulan Ini', 'Rp$totalMonth', Colors.green),
          Divider(),
          Text('Produk Terjual:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ...productSales.entries.map((e) => ListTile(
                title: Text(e.key),
                trailing: Text('${e.value} unit'),
              )),
        ],
      ),
    );
  }
}
