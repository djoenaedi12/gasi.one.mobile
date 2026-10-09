import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart'
    show PaginatedCrudState, PaginatedCrudStatus;
import 'package:gasione_plugin_catalog/src/features/categories/domain/entities/category.dart';
import 'package:gasione_plugin_catalog/src/features/categories/domain/repositories/category_repository.dart';

/// A read-only picker has its own orchestration rather than inheriting CRUD.
class CategoryPickerCubit
    extends Cubit<PaginatedCrudState<Category, QueryRequest>> {
  CategoryPickerCubit(this._repository) : super(PaginatedCrudState.initial());

  final CategoryRepository _repository;
  Timer? _debounce;
  String _searchTerm = '';
  int _generation = 0;

  void search(String term) {
    if (isClosed || term.trim() == _searchTerm) return;
    _searchTerm = term.trim();
    ++_generation;
    _debounce?.cancel();
    emit(PaginatedCrudState(status: PaginatedCrudStatus.loading));
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(load()),
    );
  }

  Future<void> load() async {
    if (isClosed) return;
    _debounce?.cancel();
    final generation = ++_generation;
    final query = QueryRequest(
      filter: _searchTerm.isEmpty
          ? null
          : OrFilter([
              SimpleFilter(
                field: 'code',
                operator: FilterOperator.like,
                value: '%$_searchTerm%',
              ),
              SimpleFilter(
                field: 'name',
                operator: FilterOperator.like,
                value: '%$_searchTerm%',
              ),
            ]),
      sorts: const [SortOrder.asc('code'), SortOrder.asc('id')],
      fields: const ['id', 'code', 'name', 'description'],
      size: 20,
    );
    emit(PaginatedCrudState(status: PaginatedCrudStatus.loading));
    final result = await _repository.queryPage(query);
    if (isClosed || generation != _generation) return;
    switch (result) {
      case Success(:final data):
        emit(_pageState(data, query));
      case FailureResult(:final failure):
        emit(
          PaginatedCrudState(
            status: PaginatedCrudStatus.failure,
            error: failure,
          ),
        );
    }
  }

  Future<void> loadMore({bool retry = false}) async {
    if (isClosed || state.isBusy || (state.loadMoreError != null && !retry)) {
      return;
    }
    final current = state;
    final query = current.nextPageQuery;
    if (query == null) return;
    final generation = _generation;
    emit(
      PaginatedCrudState(
        status: PaginatedCrudStatus.loadingMore,
        items: current.items,
        nextPageQuery: query,
        total: current.total,
      ),
    );
    final result = await _repository.queryPage(query);
    if (isClosed || generation != _generation) return;
    switch (result) {
      case Success(:final data):
        emit(_pageState(data, query, previous: current.items));
      case FailureResult(:final failure):
        emit(
          PaginatedCrudState(
            status: PaginatedCrudStatus.ready,
            items: current.items,
            nextPageQuery: query,
            total: current.total,
            loadMoreError: failure,
          ),
        );
    }
  }

  PaginatedCrudState<Category, QueryRequest> _pageState(
    PageResult<Category> page,
    QueryRequest query, {
    List<Category> previous = const [],
  }) {
    final ids = previous.map((category) => category.id).toSet();
    return PaginatedCrudState(
      status: PaginatedCrudStatus.ready,
      items: [
        ...previous,
        for (final category in page.content)
          if (ids.add(category.id)) category,
      ],
      nextPageQuery: page.hasNext ? query.copyWith(page: page.page + 1) : null,
      total: page.totalElements,
    );
  }

  @override
  Future<void> close() {
    ++_generation;
    _debounce?.cancel();
    return super.close();
  }
}
