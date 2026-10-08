// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProductModel', json, ($checkedConvert) {
      final val = ProductModel(
        id: $checkedConvert('id', (v) => (v as num?)?.toInt() ?? 0),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        description: $checkedConvert('description', (v) => v as String? ?? ''),
        category: $checkedConvert(
          'category',
          (v) => v as String? ?? 'uncategorized',
        ),
        price: $checkedConvert('price', (v) => (v as num?)?.toDouble() ?? 0),
        stock: $checkedConvert('stock', (v) => (v as num?)?.toInt() ?? 0),
        thumbnail: $checkedConvert('thumbnail', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'category': instance.category,
      'price': instance.price,
      'stock': instance.stock,
      'thumbnail': instance.thumbnail,
    };

ProductListResponseModel _$ProductListResponseModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ProductListResponseModel', json, ($checkedConvert) {
  final val = ProductListResponseModel(
    products: $checkedConvert(
      'products',
      (v) => (v as List<dynamic>)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    total: $checkedConvert('total', (v) => (v as num?)?.toInt() ?? 0),
    skip: $checkedConvert('skip', (v) => (v as num?)?.toInt() ?? 0),
    limit: $checkedConvert('limit', (v) => (v as num?)?.toInt() ?? 0),
  );
  return val;
});

Map<String, dynamic> _$ProductListResponseModelToJson(
  ProductListResponseModel instance,
) => <String, dynamic>{
  'products': instance.products,
  'total': instance.total,
  'skip': instance.skip,
  'limit': instance.limit,
};
