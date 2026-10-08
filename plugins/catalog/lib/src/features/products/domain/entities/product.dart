class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.stock,
    required this.thumbnailUrl,
  });

  final int id;
  final String title;
  final String description;
  final String category;
  final double price;
  final int stock;
  final String thumbnailUrl;
}

class ProductDraft {
  const ProductDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.stock,
  });

  factory ProductDraft.fromProduct(Product product) {
    return ProductDraft(
      title: product.title,
      description: product.description,
      category: product.category,
      price: product.price,
      stock: product.stock,
    );
  }

  final String title;
  final String description;
  final String category;
  final double price;
  final int stock;
}
