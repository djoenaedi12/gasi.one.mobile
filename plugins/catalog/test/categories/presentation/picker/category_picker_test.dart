import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';
import 'package:gasione_plugin_catalog/src/features/categories/domain/entities/category.dart';
import 'package:gasione_plugin_catalog/src/features/categories/domain/repositories/category_repository.dart';
import 'package:gasione_plugin_catalog/src/features/categories/presentation/picker/category_picker.dart';

void main() {
  testWidgets('opens as a page and returns the selected category', (
    tester,
  ) async {
    PickerValue? selected;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                selected = await Navigator.of(context).push<PickerValue>(
                  MaterialPageRoute(
                    builder: (_) => CategoryPickerPage(
                      repository: _CategoryRepository(),
                      request: const PickerRequest(),
                    ),
                  ),
                );
              },
              child: const Text('Open category picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open category picker'));
    await tester.pumpAndSettle();

    expect(find.text('Select category'), findsOneWidget);
    expect(find.text('Office'), findsOneWidget);
    expect(find.text('Travel'), findsOneWidget);

    await tester.tap(find.text('Office'));
    await tester.pumpAndSettle();

    expect(selected?.id, 'office');
    expect(selected?.label, 'Office');
  });
}

class _CategoryRepository implements CategoryRepository {
  static const _categories = [
    Category(
      id: 'office',
      code: 'OFFICE',
      name: 'Office',
      description: 'Office expenses',
    ),
    Category(
      id: 'travel',
      code: 'TRAVEL',
      name: 'Travel',
      description: 'Travel expenses',
    ),
  ];

  @override
  Future<Result<List<Category>>> queryList(QueryRequest query) async {
    return const Success(_categories);
  }

  @override
  Future<Result<Category>> create(CategoryDraft draft) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> delete(String id) => throw UnimplementedError();

  @override
  Future<Result<Category>> getById(String id) => throw UnimplementedError();

  @override
  Future<Result<PageResult<Category>>> queryPage(QueryRequest query) =>
      throw UnimplementedError();

  @override
  Future<Result<Category?>> queryOne(QueryRequest query) =>
      throw UnimplementedError();

  @override
  Future<Result<Category>> update(String id, CategoryDraft draft) =>
      throw UnimplementedError();
}
