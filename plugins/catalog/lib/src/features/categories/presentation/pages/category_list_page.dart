import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';
import 'package:gasione_plugin_catalog/src/features/categories/domain/entities/category.dart';
import 'package:gasione_plugin_catalog/src/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:gasione_plugin_catalog/src/features/categories/presentation/pages/category_form_page.dart';
import 'package:gasione_plugin_catalog/src/features/categories/presentation/widgets/category_card.dart';
import 'package:gasione_plugin_catalog/src/features/categories/presentation/widgets/category_list_skeleton.dart';
import 'package:gasione_plugin_catalog/src/localization/l10n/catalog_localizations.dart';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({super.key});

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  static const _loadMoreThreshold = 400.0;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter >= _loadMoreThreshold) {
      return;
    }
    unawaited(context.read<CategoriesCubit>().loadMore());
  }

  Future<void> _showCategoryForm([Category? category]) async {
    final cubit = context.read<CategoriesCubit>();
    final localizations = CatalogLocalizations.of(context);
    final coreLocalizations = AppLocalizations.of(context);

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CategoryFormPage(
          category: category,
          onSubmit: (draft) async {
            final success = category == null
                ? await cubit.create(draft)
                : await cubit.update(category, draft);
            final message = success
                ? (category == null
                      ? localizations.categoryAdded
                      : localizations.categoryUpdated)
                : (cubit.state.error?.localizedMessage(coreLocalizations) ??
                      coreLocalizations.operationFailed);

            return CategorySubmissionResult(
              success: success,
              message: message,
              failure: success ? null : cubit.state.error,
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Category category) async {
    final localizations = CatalogLocalizations.of(context);
    final coreLocalizations = AppLocalizations.of(context);
    final cubit = context.read<CategoriesCubit>();
    final success = await AppConfirmDialog.showAsync(
      context,
      title: localizations.deleteCategoryQuestion,
      message: localizations.deleteCategoryConfirmation(category.name),
      cancelLabel: coreLocalizations.cancel,
      confirmLabel: coreLocalizations.delete,
      destructive: true,
      onConfirm: () => cubit.delete(category),
    );
    if (success == null || !mounted) {
      return;
    }

    await _showResult(
      success: success,
      successMessage: localizations.categoryDeleted,
    );
  }

  Future<void> _showResult({
    required bool success,
    required String successMessage,
  }) async {
    final localizations = CatalogLocalizations.of(context);
    final coreLocalizations = AppLocalizations.of(context);
    final message = success
        ? successMessage
        : (context.read<CategoriesCubit>().state.error?.localizedMessage(
                coreLocalizations,
              ) ??
              coreLocalizations.operationFailed);

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (resultContext) => AppResultPage(
          status: success ? AppResultStatus.success : AppResultStatus.failure,
          title: success
              ? coreLocalizations.operationSuccessful
              : coreLocalizations.operationFailed,
          message: message,
          primaryActionLabel: localizations.backToCategories,
          onPrimaryAction: () => Navigator.of(resultContext).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = CatalogLocalizations.of(context);
    final coreLocalizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.categories)),
      body:
          BlocBuilder<
            CategoriesCubit,
            PaginatedCrudState<Category, QueryRequest>
          >(
            builder: (context, state) {
              if (state.isLoading && state.items.isEmpty) {
                return const CategoryListSkeleton();
              }

              if (state.error != null && state.items.isEmpty) {
                return AppErrorView(
                  message: state.error!.localizedMessage(coreLocalizations),
                  actionLabel: coreLocalizations.retry,
                  onAction: context.read<CategoriesCubit>().load,
                );
              }

              if (state.items.isEmpty) {
                return AppEmptyView(
                  title: localizations.noCategories,
                  message: localizations.noCategoriesDescription,
                  actionLabel: localizations.addCategory,
                  onAction: _showCategoryForm,
                );
              }

              final showFooter =
                  state.isLoadingMore || state.loadMoreError != null;

              return Column(
                children: [
                  if (state.isMutating) const LinearProgressIndicator(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: context.read<CategoriesCubit>().load,
                      child: ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: state.items.length + (showFooter ? 1 : 0),
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          if (index == state.items.length) {
                            return _PaginationFooter(
                              errorMessage: state.loadMoreError
                                  ?.localizedMessage(coreLocalizations),
                              retryLabel: coreLocalizations.retry,
                              onRetry: context
                                  .read<CategoriesCubit>()
                                  .retryLoadMore,
                            );
                          }

                          final category = state.items[index];
                          return CategoryCard(
                            category: category,
                            enabled: !state.isBusy,
                            onEdit: () => _showCategoryForm(category),
                            onDelete: () => _confirmDelete(category),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      floatingActionButton:
          BlocSelector<
            CategoriesCubit,
            PaginatedCrudState<Category, QueryRequest>,
            bool
          >(
            selector: (state) => state.isBusy,
            builder: (context, isBusy) {
              return FloatingActionButton.extended(
                onPressed: isBusy ? null : _showCategoryForm,
                icon: const Icon(Icons.add),
                label: Text(localizations.addCategory),
              );
            },
          ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.errorMessage,
    required this.retryLabel,
    required this.onRetry,
  });

  final String? errorMessage;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (errorMessage == null) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        children: [
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}
