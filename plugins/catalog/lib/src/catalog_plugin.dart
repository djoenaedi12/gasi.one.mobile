import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_plugin_catalog/src/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:gasione_plugin_catalog/src/features/categories/data/repositories/category_repository_impl.dart';
import 'package:gasione_plugin_catalog/src/features/categories/domain/repositories/category_repository.dart';
import 'package:gasione_plugin_catalog/src/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:gasione_plugin_catalog/src/features/categories/presentation/pages/category_list_page.dart';
import 'package:gasione_plugin_catalog/src/features/categories/presentation/picker/category_picker.dart';
import 'package:gasione_plugin_catalog/src/features/products/data/datasources/product_remote_data_source.dart';
import 'package:gasione_plugin_catalog/src/features/products/data/repositories/product_repository_impl.dart';
import 'package:gasione_plugin_catalog/src/features/products/domain/repositories/product_repository.dart';
import 'package:gasione_plugin_catalog/src/features/products/presentation/cubits/products_cubit.dart';
import 'package:gasione_plugin_catalog/src/features/products/presentation/pages/product_list_page.dart';
import 'package:gasione_plugin_catalog/src/localization/l10n/catalog_localizations.dart';

abstract final class CatalogRoutes {
  static const products = '/products';
  static const categories = '/categories';
}

final class CatalogPlugin implements AppPlugin, PickerContributor {
  CatalogPlugin({
    required ApiClient apiClient,
    this.reloadProductsAfterMutation = true,
  }) : _productRepository = ProductRepositoryImpl(
         ProductRemoteDataSource(apiClient),
       ),
       _categoryRepository = CategoryRepositoryImpl(
         CategoryRemoteDataSource(apiClient),
       );

  CatalogPlugin.fromRepositories({
    required this._productRepository,
    required this._categoryRepository,
    this.reloadProductsAfterMutation = true,
  });

  final ProductRepository _productRepository;
  final CategoryRepository _categoryRepository;
  final bool reloadProductsAfterMutation;

  @override
  String get code => 'catalog';

  @override
  List<LocalizationsDelegate<dynamic>> get localizationsDelegates => [
    CatalogLocalizations.delegate,
  ];

  @override
  List<Locale> get supportedLocales => CatalogLocalizations.supportedLocales;

  @override
  List<PickerDefinitionBase> get pickers => [
    PickerDefinition<PickerValue>(
      key: CatalogPickerKeys.category,
      pageBuilder: (context, request) =>
          CategoryPickerPage(repository: _categoryRepository, request: request),
    ),
  ];

  @override
  List<PluginMenuItem> get menus => [
    PluginMenuItem(
      route: CatalogRoutes.products,
      icon: Icons.inventory_2_outlined,
      titleBuilder: (context) => CatalogLocalizations.of(context).products,
    ),
    PluginMenuItem(
      route: CatalogRoutes.categories,
      icon: Icons.category_outlined,
      titleBuilder: (context) => CatalogLocalizations.of(context).categories,
    ),
  ];

  @override
  List<PluginRoute> get routes => [
    PluginRoute(
      path: CatalogRoutes.products,
      builder: (context, state) => BlocProvider(
        create: (_) => ProductsCubit(
          _productRepository,
          reloadAfterMutation: reloadProductsAfterMutation,
        )..load(),
        child: const ProductListPage(),
      ),
    ),
    PluginRoute(
      path: CatalogRoutes.categories,
      builder: (context, state) => BlocProvider(
        create: (_) => CategoriesCubit(_categoryRepository)..load(),
        child: const CategoryListPage(),
      ),
    ),
  ];
}
