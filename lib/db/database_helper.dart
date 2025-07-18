import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('depot.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Produk
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price INTEGER NOT NULL,
        unit TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Stok Barang
    await db.execute('''
      CREATE TABLE stock_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit TEXT NOT NULL
      )
    ''');

    // Pelanggan
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    // Transaksi
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        date TEXT NOT NULL,
        total_amount INTEGER NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    // Item Transaksi
    await db.execute('''
      CREATE TABLE transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        price INTEGER NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    await db.insert('products', {
      'name': 'Isi Ulang Galon 19L',
      'price': 8000,
      'unit': 'galon',
      'quantity': 0,
    });
    await db.insert('products', {
      'name': 'Galon Kosong 19L',
      'price': 15000,
      'unit': 'pcs',
      'quantity': 0,
    });
    await db.insert('products', {
      'name': 'Galon Isi 19L',
      'price': 23000,
      'unit': 'galon',
      'quantity': 0,
    });

    await db.insert('stock_items', {
      'name': 'Air',
      'quantity': 1000,
      'unit': 'L',
    });
    await db.insert('stock_items', {
      'name': 'Galon Kosong 19L',
      'quantity': 10,
      'unit': 'pcs',
    });
    await db.insert('stock_items', {
      'name': 'Tutup Botol',
      'quantity': 50,
      'unit': 'pcs',
    });
    await db.insert('stock_items', {
      'name': 'Tisu',
      'quantity': 50,
      'unit': 'pcs',
    });
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
