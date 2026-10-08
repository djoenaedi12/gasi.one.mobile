import 'package:flutter/material.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';
import 'package:gasione_plugin_catalog/src/features/categories/domain/entities/category.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    required this.category,
    required this.enabled,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Category category;
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.category_outlined,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(category.name, variant: AppTextVariant.title),
                  const SizedBox(height: AppSpacing.xxs),
                  AppText(
                    category.code,
                    variant: AppTextVariant.label,
                    tone: AppTextTone.primary,
                  ),
                  if (category.description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      category.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      variant: AppTextVariant.bodySmall,
                      tone: AppTextTone.muted,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: enabled ? onEdit : null,
              tooltip: localizations.edit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: enabled ? onDelete : null,
              tooltip: localizations.delete,
              color: colors.error,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}
