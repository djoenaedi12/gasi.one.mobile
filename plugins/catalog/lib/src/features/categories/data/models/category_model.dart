import 'package:gasione_plugin_catalog/src/features/categories/domain/entities/category.dart';

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id == null) {
      throw const FormatException('Category id is required.');
    }

    return CategoryModel(
      id: id.toString(),
      code: json['code'] is String ? json['code'] as String : '',
      name: json['name'] is String ? json['name'] as String : '',
      description: json['description'] is String
          ? json['description'] as String
          : '',
    );
  }

  final String id;
  final String code;
  final String name;
  final String description;

  Category toEntity() {
    return Category(id: id, code: code, name: name, description: description);
  }
}

class CategoryPayload {
  const CategoryPayload({
    required this.code,
    required this.name,
    required this.description,
  });

  factory CategoryPayload.fromDraft(CategoryDraft draft) {
    return CategoryPayload(
      code: draft.code,
      name: draft.name,
      description: draft.description,
    );
  }

  final String code;
  final String name;
  final String description;

  Map<String, Object?> toJson() => {
    'code': code,
    'name': name,
    'description': description,
  };
}
