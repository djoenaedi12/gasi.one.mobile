import 'package:flutter/material.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';
import 'package:gasione_plugin_catalog/src/features/categories/domain/entities/category.dart';
import 'package:gasione_plugin_catalog/src/features/categories/domain/repositories/category_repository.dart';
import 'package:gasione_plugin_catalog/src/localization/l10n/catalog_localizations.dart';

abstract final class CatalogPickerKeys {
  static const category = PickerKey<PickerValue>('catalog.category');
}

class CategoryPickerPage extends StatefulWidget {
  const CategoryPickerPage({
    required this.repository,
    required this.request,
    super.key,
  });

  final CategoryRepository repository;
  final PickerRequest<PickerValue> request;

  @override
  State<CategoryPickerPage> createState() => _CategoryPickerPageState();
}

class _CategoryPickerPageState extends State<CategoryPickerPage> {
  late Future<Result<List<Category>>> _categories;
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _categories = _loadCategories();
  }

  Future<Result<List<Category>>> _loadCategories() {
    return widget.repository.queryList(
      const QueryRequest(
        sorts: [SortOrder.asc('code')],
        fields: ['id', 'code', 'name', 'description'],
      ),
    );
  }

  void _retry() {
    setState(() => _categories = _loadCategories());
  }

  @override
  Widget build(BuildContext context) {
    final localizations = CatalogLocalizations.of(context);
    final coreLocalizations = AppLocalizations.of(context);
    final initialId = widget.request.initialValue?.id.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.request.title ?? localizations.selectCategory),
      ),
      body: FutureBuilder<Result<List<Category>>>(
        future: _categories,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final result = snapshot.data;
          if (result == null) {
            return AppErrorView(
              message: coreLocalizations.unknownError,
              actionLabel: coreLocalizations.retry,
              onAction: _retry,
            );
          }

          return switch (result) {
            FailureResult(:final failure) => AppErrorView(
              message: failure.localizedMessage(coreLocalizations),
              actionLabel: coreLocalizations.retry,
              onAction: _retry,
            ),
            Success(:final data) => _CategoryPickerContent(
              categories: data,
              initialId: initialId,
              searchTerm: _searchTerm,
              onSearchChanged: (value) {
                setState(() => _searchTerm = value.trim().toLowerCase());
              },
              onSelected: (category) {
                Navigator.of(context).pop(
                  PickerValue(
                    id: category.id,
                    label: category.name,
                    metadata: {'code': category.code},
                  ),
                );
              },
            ),
          };
        },
      ),
    );
  }
}

class _CategoryPickerContent extends StatelessWidget {
  const _CategoryPickerContent({
    required this.categories,
    required this.initialId,
    required this.searchTerm,
    required this.onSearchChanged,
    required this.onSelected,
  });

  final List<Category> categories;
  final String? initialId;
  final String searchTerm;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<Category> onSelected;

  @override
  Widget build(BuildContext context) {
    final localizations = CatalogLocalizations.of(context);
    final coreLocalizations = AppLocalizations.of(context);
    final filteredCategories = [
      for (final category in categories)
        if (searchTerm.isEmpty ||
            category.name.toLowerCase().contains(searchTerm) ||
            category.code.toLowerCase().contains(searchTerm))
          category,
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: TextField(
            autofocus: true,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: coreLocalizations.search,
              prefixIcon: const Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: filteredCategories.isEmpty
              ? AppEmptyView(
                  title: localizations.noCategories,
                  message: localizations.noCategoriesAvailable,
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  itemCount: filteredCategories.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final category = filteredCategories[index];
                    final isSelected = category.id == initialId;
                    return ListTile(
                      title: Text(category.name),
                      subtitle: Text(category.code),
                      trailing: isSelected ? const Icon(Icons.check) : null,
                      onTap: () => onSelected(category),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
