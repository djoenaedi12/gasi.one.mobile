import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';
import 'package:gasione_plugin_catalog/src/features/products/domain/entities/product.dart';
import 'package:gasione_plugin_catalog/src/features/products/presentation/cubits/products_cubit.dart';
import 'package:gasione_plugin_catalog/src/features/products/presentation/cubits/products_state.dart';
import 'package:gasione_plugin_catalog/src/features/products/presentation/pages/product_form_page.dart';
import 'package:gasione_plugin_catalog/src/features/products/presentation/widgets/product_card.dart';
import 'package:gasione_plugin_catalog/src/features/products/presentation/widgets/product_list_skeleton.dart';
import 'package:gasione_plugin_catalog/src/localization/l10n/catalog_localizations.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
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
    unawaited(context.read<ProductsCubit>().loadMore());
  }

  Future<void> _showProductForm([Product? product]) async {
    final cubit = context.read<ProductsCubit>();
    final localizations = CatalogLocalizations.of(context);
    final coreLocalizations = AppLocalizations.of(context);
    final pickerLauncher = context.read<PickerLauncher>();

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProductFormPage(
          product: product,
          pickerLauncher: pickerLauncher,
          onSubmit: (draft) async {
            final success = product == null
                ? await cubit.add(draft)
                : await cubit.update(product, draft);
            final message = success
                ? (product == null
                      ? localizations.productAdded
                      : localizations.productUpdated)
                : (cubit.state.error?.localizedMessage(coreLocalizations) ??
                      coreLocalizations.operationFailed);

            return ProductSubmissionResult(
              success: success,
              message: message,
              failure: success ? null : cubit.state.error,
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Product product) async {
    final localizations = CatalogLocalizations.of(context);
    final coreLocalizations = AppLocalizations.of(context);
    final cubit = context.read<ProductsCubit>();
    final result = await AppConfirmDialog.showAsync(
      context,
      title: localizations.deleteProductQuestion,
      message: localizations.deleteProductConfirmation(product.title),
      cancelLabel: coreLocalizations.cancel,
      confirmLabel: coreLocalizations.delete,
      destructive: true,
      onConfirm: () => cubit.delete(product),
    );
    if (result == null || !mounted) {
      return;
    }

    await _showResult(
      success: result,
      successMessage: localizations.productDeleted,
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
        : (context.read<ProductsCubit>().state.error?.localizedMessage(
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
          primaryActionLabel: localizations.backToProducts,
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
      appBar: AppBar(title: Text(localizations.products)),
      body: BlocBuilder<ProductsCubit, ProductsState>(
        builder: (context, state) {
          if (state.isLoading && state.products.isEmpty) {
            return const ProductListSkeleton();
          }

          if (state.error != null && state.products.isEmpty) {
            return AppErrorView(
              message: state.error!.localizedMessage(coreLocalizations),
              actionLabel: coreLocalizations.retry,
              onAction: context.read<ProductsCubit>().load,
            );
          }

          if (state.products.isEmpty) {
            return AppEmptyView(
              title: localizations.noProducts,
              message: localizations.noProductsDescription,
              actionLabel: localizations.addProduct,
              onAction: _showProductForm,
            );
          }

          final showPaginationFooter =
              state.isLoadingMore || state.loadMoreError != null;

          return Column(
            children: [
              if (state.isMutating) const LinearProgressIndicator(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: context.read<ProductsCubit>().load,
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount:
                        state.products.length + (showPaginationFooter ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      if (index == state.products.length) {
                        return _PaginationFooter(
                          errorMessage: state.loadMoreError?.localizedMessage(
                            coreLocalizations,
                          ),
                          retryLabel: coreLocalizations.retry,
                          onRetry: context.read<ProductsCubit>().retryLoadMore,
                        );
                      }
                      final product = state.products[index];
                      return ProductCard(
                        product: product,
                        enabled: !state.isBusy,
                        onEdit: () => _showProductForm(product),
                        onDelete: () => _confirmDelete(product),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: BlocSelector<ProductsCubit, ProductsState, bool>(
        selector: (state) => state.isBusy,
        builder: (context, isBusy) {
          return FloatingActionButton.extended(
            onPressed: isBusy ? null : _showProductForm,
            icon: const Icon(Icons.add),
            label: Text(localizations.addProduct),
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
