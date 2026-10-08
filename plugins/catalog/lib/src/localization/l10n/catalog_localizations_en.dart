// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'catalog_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class CatalogLocalizationsEn extends CatalogLocalizations {
  CatalogLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get products => 'Products';

  @override
  String get noProducts => 'No products yet';

  @override
  String get noProductsDescription => 'Add your first product to get started.';

  @override
  String get addProduct => 'Add product';

  @override
  String get editProduct => 'Edit product';

  @override
  String get productAdded => 'Product added.';

  @override
  String get productUpdated => 'Product updated.';

  @override
  String get productDeleted => 'Product deleted.';

  @override
  String get deleteProductQuestion => 'Delete product?';

  @override
  String deleteProductConfirmation(String title) {
    return 'Delete \"$title\" from this list?';
  }

  @override
  String get category => 'Category';

  @override
  String get price => 'Price';

  @override
  String get stock => 'Stock';

  @override
  String stockValue(int stock) {
    return 'Stock: $stock';
  }

  @override
  String get backToProducts => 'Back to products';

  @override
  String get categories => 'Categories';

  @override
  String get noCategories => 'No categories yet';

  @override
  String get noCategoriesDescription =>
      'Add your first category to get started.';

  @override
  String get addCategory => 'Add category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get categoryAdded => 'Category added.';

  @override
  String get categoryUpdated => 'Category updated.';

  @override
  String get categoryDeleted => 'Category deleted.';

  @override
  String get deleteCategoryQuestion => 'Delete category?';

  @override
  String deleteCategoryConfirmation(String name) {
    return 'Delete \"$name\" from this list?';
  }

  @override
  String get backToCategories => 'Back to categories';

  @override
  String get selectCategory => 'Select category';

  @override
  String get noCategoriesAvailable => 'No categories are available to select.';

  @override
  String get validPrice => 'Enter a valid price.';

  @override
  String get validStock => 'Enter a valid stock amount.';
}
