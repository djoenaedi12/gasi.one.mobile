import 'package:flutter/material.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';
import 'package:gasione_plugin_catalog/src/localization/l10n/catalog_localizations.dart';
import 'package:gasione_plugin_catalog/src/features/products/domain/entities/product.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.enabled,
    super.key,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final localizations = CatalogLocalizations.of(context);
    final coreLocalizations = AppLocalizations.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            _ProductImage(url: product.thumbnailUrl),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    variant: AppTextVariant.title,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  AppText(
                    product.category,
                    variant: AppTextVariant.bodySmall,
                    tone: AppTextTone.muted,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      AppText(
                        '\$${product.price.toStringAsFixed(2)}',
                        variant: AppTextVariant.label,
                        tone: AppTextTone.primary,
                      ),
                      AppText(
                        localizations.stockValue(product.stock),
                        variant: AppTextVariant.bodySmall,
                        tone: AppTextTone.muted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: enabled ? onEdit : null,
              tooltip: coreLocalizations.edit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: enabled ? onDelete : null,
              tooltip: coreLocalizations.delete,
              color: Theme.of(context).colorScheme.error,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.inventory_2_outlined)),
    );

    return SizedBox.square(
      dimension: 72,
      child: url.isEmpty
          ? placeholder
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }
}
