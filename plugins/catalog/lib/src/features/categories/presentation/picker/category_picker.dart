import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart'
    show PaginatedCrudState;
import 'package:gasione_core_ui/gasione_core_ui.dart';
import 'package:gasione_plugin_catalog/src/features/categories/domain/entities/category.dart';
import 'package:gasione_plugin_catalog/src/features/categories/domain/repositories/category_repository.dart';
import 'package:gasione_plugin_catalog/src/features/categories/presentation/picker/category_picker_cubit.dart';
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
  late final CategoryPickerCubit _cubit;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cubit = CategoryPickerCubit(widget.repository)..load();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 400) {
      unawaited(_cubit.loadMore());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = CatalogLocalizations.of(context);
    final core = AppLocalizations.of(context);
    final initialId = widget.request.initialValue?.id.toString();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.request.title ?? localizations.selectCategory),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              autofocus: true,
              onChanged: _cubit.search,
              decoration: InputDecoration(
                hintText: core.search,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child:
                BlocBuilder<
                  CategoryPickerCubit,
                  PaginatedCrudState<Category, QueryRequest>
                >(
                  bloc: _cubit,
                  builder: (context, state) {
                    if (state.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.error != null) {
                      return AppErrorView(
                        message: state.error!.localizedMessage(core),
                        actionLabel: core.retry,
                        onAction: _cubit.load,
                      );
                    }
                    if (state.items.isEmpty) {
                      return AppEmptyView(
                        title: localizations.noCategories,
                        message: localizations.noCategoriesAvailable,
                      );
                    }
                    final showFooter =
                        state.hasMore ||
                        state.isLoadingMore ||
                        state.loadMoreError != null;
                    return ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      itemCount: state.items.length + (showFooter ? 1 : 0),
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        if (index == state.items.length) {
                          if (state.isLoadingMore) {
                            return const Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return Column(
                            children: [
                              if (state.loadMoreError != null)
                                Text(
                                  state.loadMoreError!.localizedMessage(core),
                                ),
                              TextButton(
                                onPressed: () => _cubit.loadMore(retry: true),
                                child: Text(
                                  state.loadMoreError != null
                                      ? core.retry
                                      : core.loadMore,
                                ),
                              ),
                            ],
                          );
                        }
                        final category = state.items[index];
                        return ListTile(
                          title: Text(category.name),
                          subtitle: Text(category.code),
                          trailing: category.id == initialId
                              ? const Icon(Icons.check)
                              : null,
                          onTap: () => Navigator.of(context).pop(
                            PickerValue(
                              id: category.id,
                              label: category.name,
                              metadata: {'code': category.code},
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
