# DepotKu 📱💧
Aplikasi Manajemen Operasional Depot Air Minum — dibuat dengan Flutter & SQLite

## 📌 Fitur Utama
- ✅ **Dashboard Beranda**  
  Pantau stok air yang tersedia dan pendapatan harian, mingguan, serta bulanan.
- ➕ **Tambah Transaksi**  
  Input pelanggan, pilih produk & jumlah, simpan transaksi dan stok akan terupdate otomatis.
- 📊 **Data Transaksi**  
  Lihat riwayat transaksi, filter berdasarkan tanggal, dan hapus jika diperlukan.
- 🛍 **Produk**  
  Lihat daftar produk dan ubah harga produk dengan mudah.
- 🏪 **Stok**  
  Kelola stok bahan baku seperti air, galon kosong, tutup botol, dan tisu.

## 🧱 Struktur Proyek
lib/
├── db/
│   └── database\_helper.dart
├── models/
│   ├── customer.dart
│   ├── product.dart
│   ├── stock\_item.dart
│   ├── transaction.dart
│   └── transaction\_item.dart
├── screens/
│   ├── home\_page.dart
│   ├── add\_transaction\_page.dart
│   ├── data\_page.dart
│   ├── product\_page.dart
│   └── stock\_page.dart
├── widgets/
│   └── navbar.dart
└── main.dart

## 🛠 Teknologi yang Digunakan
- **Flutter** (Framework UI)
- **Dart** (Bahasa Pemrograman)
- **SQLite** via plugin [`sqflite`](https://pub.dev/packages/sqflite)
- **intl** (Library untuk format tanggal)

## 🚀 Cara Menjalankan
1. Clone repositori ini:
git clone https://github.com/athaya/depotku_app.git

2. Masuk ke direktori proyek dan jalankan:

flutter pub get
flutter run

3. Aplikasi akan berjalan di emulator atau perangkat Android.

## 📝 Catatan
- Aplikasi ini bersifat **offline** dan menyimpan data lokal menggunakan SQLite.
- Cocok untuk UMKM khususnya depot air minum isi ulang.
- Dibuat untuk keperluan tugas akhir mata kuliah Pemrograman Mobile.

## 👨‍🏫 Pengembang
- Muhammad Athaya Febryanda — D3 Teknik Informatika, Politeknik Negeri Pontianak

## 📄 Lisensi
Proyek ini dibuat untuk tujuan pendidikan dan non-komersial.