import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_plugin_catalog/src/features/categories/data/models/category_model.dart';
import 'package:gasione_plugin_catalog/src/features/categories/domain/entities/category.dart';

void main() {
  test('maps API JSON to a category entity', () {
    final model = CategoryModel.fromJson({
      'id': 12,
      'code': 'OFFICE',
      'name': 'Office supplies',
      'description': 'Items used at the office',
    });

    final entity = model.toEntity();

    expect(entity.id, '12');
    expect(entity.code, 'OFFICE');
    expect(entity.name, 'Office supplies');
    expect(entity.description, 'Items used at the office');
  });

  test('maps a category draft to the create and update request body', () {
    const draft = CategoryDraft(
      code: 'FOOD',
      name: 'Food',
      description: 'Consumable products',
    );

    expect(CategoryPayload.fromDraft(draft).toJson(), {
      'code': 'FOOD',
      'name': 'Food',
      'description': 'Consumable products',
    });
  });
}
