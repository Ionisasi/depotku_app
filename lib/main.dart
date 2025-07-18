import 'package:flutter/material.dart';
import 'package:depotku_app/db/database_helper.dart';
import 'screens/home_page.dart';
import 'screens/data_page.dart';
import 'screens/product_page.dart';
import 'screens/stock_page.dart';
import 'screens/add_transaction_page.dart';
import 'widgets/navbar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manajemen Depot Air',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue, // warna AppBar
          foregroundColor: Colors.white, // warna teks & ikon
        ),
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: Color.fromRGBO(0, 180, 216, 1),
        ),

      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),           // index 0
    DataPage(),           // index 1
    AddTransactionPage(), // index 2
    ProductPage(),        // index 3
    StockPage(),          // index 4
  ];

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Navbar(
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}
