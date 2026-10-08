class Category {
  const Category({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
  });

  final String id;
  final String code;
  final String name;
  final String description;
}

class CategoryDraft {
  const CategoryDraft({
    required this.code,
    required this.name,
    required this.description,
  });

  factory CategoryDraft.fromCategory(Category category) {
    return CategoryDraft(
      code: category.code,
      name: category.name,
      description: category.description,
    );
  }

  final String code;
  final String name;
  final String description;
}
