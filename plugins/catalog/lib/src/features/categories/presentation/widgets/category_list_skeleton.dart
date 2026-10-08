import 'package:flutter/material.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';
import 'package:gasione_plugin_catalog/src/features/categories/domain/entities/category.dart';
import 'package:gasione_plugin_catalog/src/features/categories/presentation/widgets/category_card.dart';

class CategoryListSkeleton extends StatelessWidget {
  const CategoryListSkeleton({super.key});

  static const _placeholder = Category(
    id: '0',
    code: 'CATEGORY-CODE',
    name: 'Loading category name',
    description: 'Loading category description',
  );

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, _) => CategoryCard(
          category: _placeholder,
          enabled: false,
          onEdit: _noop,
          onDelete: _noop,
        ),
      ),
    );
  }

  static void _noop() {}
}
