import 'package:gasione_plugin_catalog/src/features/products/domain/entities/product.dart';
import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

@JsonSerializable(checked: true)
class ProductModel {
  const ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.stock,
    required this.thumbnail,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return _$ProductModelFromJson(json);
  }

  @JsonKey(defaultValue: 0)
  final int id;

  @JsonKey(defaultValue: '')
  final String title;

  @JsonKey(defaultValue: '')
  final String description;

  @JsonKey(defaultValue: 'uncategorized')
  final String category;

  @JsonKey(defaultValue: 0)
  final double price;

  @JsonKey(defaultValue: 0)
  final int stock;

  @JsonKey(defaultValue: '')
  final String thumbnail;

  Product toEntity() {
    return Product(
      id: id,
      title: title,
      description: description,
      category: category,
      price: price,
      stock: stock,
      thumbnailUrl: thumbnail,
    );
  }

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}

@JsonSerializable(checked: true)
class ProductListResponseModel {
  const ProductListResponseModel({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory ProductListResponseModel.fromJson(Map<String, dynamic> json) {
    return _$ProductListResponseModelFromJson(json);
  }

  final List<ProductModel> products;

  @JsonKey(defaultValue: 0)
  final int total;

  @JsonKey(defaultValue: 0)
  final int skip;

  @JsonKey(defaultValue: 0)
  final int limit;

  Map<String, dynamic> toJson() => _$ProductListResponseModelToJson(this);
}
