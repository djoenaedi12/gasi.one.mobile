import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_plugin_catalog/src/features/products/data/models/product_model.dart';

void main() {
  test('converts product JSON to a domain entity', () {
    final model = ProductModel.fromJson({
      'id': 1,
      'title': 'Test product',
      'description': 'Description',
      'category': 'test',
      'price': 12.5,
      'stock': 4,
      'thumbnail': 'https://example.com/product.png',
    });

    final product = model.toEntity();

    expect(product.id, 1);
    expect(product.title, 'Test product');
    expect(product.price, 12.5);
  });

  test(
    'uses safe defaults for fields omitted by simulated create responses',
    () {
      final model = ProductModel.fromJson({
        'id': 195,
        'title': 'Created product',
      });

      expect(model.description, isEmpty);
      expect(model.category, 'uncategorized');
      expect(model.price, 0);
      expect(model.thumbnail, isEmpty);
    },
  );

  test('parses product pagination metadata', () {
    final response = ProductListResponseModel.fromJson({
      'products': <Map<String, Object?>>[],
      'total': 194,
      'skip': 10,
      'limit': 10,
    });

    expect(response.products, isEmpty);
    expect(response.total, 194);
    expect(response.skip, 10);
    expect(response.limit, 10);
  });
}
