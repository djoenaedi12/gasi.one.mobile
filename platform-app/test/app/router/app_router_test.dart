import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione/app/home/home_page.dart';
import 'package:gasione/app/localization/locale_cubit.dart';
import 'package:gasione/app/plugin_registry.dart';
import 'package:gasione/app/router/app_router.dart';
import 'package:gasione/app/router/pages/unknown_route_page.dart';
import 'package:gasione/app/theme/theme_cubit.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';
import 'package:gasione_plugin_auth/gasione_plugin_auth.dart';
import 'package:gasione_plugin_catalog/gasione_plugin_catalog.dart';

import '../../helpers/memory_preferences_storage.dart';

void main() {
  testWidgets('redirects routes when authentication changes', (tester) async {
    final authRepository = _FakeAuthRepository();
    final authPlugin = AuthPlugin.fromRepository(authRepository);
    final authCubit = authPlugin.authCubit;
    final pluginRegistry = PluginRegistry([
      CatalogPlugin.fromRepositories(
        productRepository: _FakeProductRepository(),
        categoryRepository: _FakeCategoryRepository(),
      ),
    ]);
    final router = AppRouter(
      authPlugin: authPlugin,
      pluginRegistry: pluginRegistry,
    );
    final preferences = MemoryPreferencesStorage();
    addTearDown(router.dispose);
    addTearDown(authCubit.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authCubit),
          BlocProvider(create: (_) => ThemeCubit(preferences)),
          BlocProvider(create: (_) => LocaleCubit(preferences)),
        ],
        child: MaterialApp.router(
          localizationsDelegates: [
            ...AppLocalizations.localizationsDelegates,
            ...authPlugin.localizationsDelegates,
            ...pluginRegistry.localizationsDelegates,
          ],
          supportedLocales: {
            ...AppLocalizations.supportedLocales,
            ...authPlugin.supportedLocales,
            ...pluginRegistry.supportedLocales,
          }.toList(),
          routerConfig: router.router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);

    authCubit.signedIn(_user);
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    expect(find.byIcon(Icons.category_outlined), findsOneWidget);

    router.router.go(CatalogRoutes.products);
    await tester.pumpAndSettle();

    expect(find.byType(ProductListPage), findsOneWidget);

    router.router.go(CatalogRoutes.categories);
    await tester.pumpAndSettle();

    expect(find.byType(CategoryListPage), findsOneWidget);

    pluginRegistry.activate(const []);
    router.router.go(CatalogRoutes.products);
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(ProductListPage), findsNothing);

    router.router.go('/missing');
    await tester.pumpAndSettle();

    expect(find.byType(UnknownRoutePage), findsOneWidget);

    await authCubit.logout();
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });
}

const _user = AuthUser(
  id: 1,
  username: 'emilys',
  email: 'emily@example.com',
  firstName: 'Emily',
  lastName: 'Johnson',
  imageUrl: '',
);

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<Result<AuthUser?>> restoreSession() async => const Success(null);

  @override
  Future<Result<AuthUser>> login({
    required String username,
    required String password,
  }) {
    return Future.value(const Success(_user));
  }

  @override
  Future<Result<void>> logout() async => const Success(null);
}

class _FakeProductRepository implements ProductRepository {
  @override
  Future<Result<PaginatedPage<Product>>> getProducts({
    required int limit,
    required int skip,
  }) async {
    return Success(
      PaginatedPage(items: const [], total: 0, offset: skip, limit: limit),
    );
  }

  @override
  Future<Result<Product>> addProduct(ProductDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Product>> updateProduct(int id, ProductDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> deleteProduct(int id) {
    throw UnimplementedError();
  }
}

class _FakeCategoryRepository implements CategoryRepository {
  @override
  Future<Result<PageResult<Category>>> queryPage(QueryRequest query) async {
    return Success(
      PageResult(
        content: const [],
        page: query.normalizedPage,
        size: query.normalizedSize,
        totalElements: 0,
        totalPages: 0,
      ),
    );
  }

  @override
  Future<Result<Category>> create(CategoryDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> delete(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Category>> getById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<Category>>> queryList(QueryRequest query) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Category?>> queryOne(QueryRequest query) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Category>> update(String id, CategoryDraft draft) {
    throw UnimplementedError();
  }
}
