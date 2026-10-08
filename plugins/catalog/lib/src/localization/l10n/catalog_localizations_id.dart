// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'catalog_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class CatalogLocalizationsId extends CatalogLocalizations {
  CatalogLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get products => 'Produk';

  @override
  String get noProducts => 'Belum ada produk';

  @override
  String get noProductsDescription => 'Tambahkan produk pertama untuk memulai.';

  @override
  String get addProduct => 'Tambah produk';

  @override
  String get editProduct => 'Ubah produk';

  @override
  String get productAdded => 'Produk berhasil ditambahkan.';

  @override
  String get productUpdated => 'Produk berhasil diperbarui.';

  @override
  String get productDeleted => 'Produk berhasil dihapus.';

  @override
  String get deleteProductQuestion => 'Hapus produk?';

  @override
  String deleteProductConfirmation(String title) {
    return 'Hapus \"$title\" dari daftar ini?';
  }

  @override
  String get category => 'Kategori';

  @override
  String get price => 'Harga';

  @override
  String get stock => 'Stok';

  @override
  String stockValue(int stock) {
    return 'Stok: $stock';
  }

  @override
  String get backToProducts => 'Kembali ke produk';

  @override
  String get categories => 'Kategori';

  @override
  String get noCategories => 'Belum ada kategori';

  @override
  String get noCategoriesDescription =>
      'Tambahkan kategori pertama untuk memulai.';

  @override
  String get addCategory => 'Tambah kategori';

  @override
  String get editCategory => 'Ubah kategori';

  @override
  String get categoryAdded => 'Kategori berhasil ditambahkan.';

  @override
  String get categoryUpdated => 'Kategori berhasil diperbarui.';

  @override
  String get categoryDeleted => 'Kategori berhasil dihapus.';

  @override
  String get deleteCategoryQuestion => 'Hapus kategori?';

  @override
  String deleteCategoryConfirmation(String name) {
    return 'Hapus \"$name\" dari daftar ini?';
  }

  @override
  String get backToCategories => 'Kembali ke kategori';

  @override
  String get selectCategory => 'Pilih kategori';

  @override
  String get noCategoriesAvailable => 'Tidak ada kategori yang dapat dipilih.';

  @override
  String get validPrice => 'Masukkan harga yang valid.';

  @override
  String get validStock => 'Masukkan jumlah stok yang valid.';
}
