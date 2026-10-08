import 'package:flutter/material.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';
import 'package:gasione_plugin_catalog/src/features/products/domain/entities/product.dart';
import 'package:gasione_plugin_catalog/src/features/products/presentation/widgets/product_card.dart';

class ProductListSkeleton extends StatelessWidget {
  const ProductListSkeleton({super.key});

  static const _placeholder = Product(
    id: 0,
    title: 'Loading product title',
    description: 'Loading product description',
    category: 'loading-category',
    price: 99.99,
    stock: 10,
    thumbnailUrl: '',
  );

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.sm),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xxs),
        itemBuilder: (_, _) => ProductCard(
          product: _placeholder,
          enabled: false,
          onEdit: _noop,
          onDelete: _noop,
        ),
      ),
    );
  }

  static void _noop() {}
}
