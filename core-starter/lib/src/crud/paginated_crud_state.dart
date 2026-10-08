import 'package:gasione_core_api/gasione_core_api.dart';

enum PaginatedCrudStatus {
  initial,
  loading,
  ready,
  loadingMore,
  mutating,
  failure,
}

/// Backend-independent page data consumed by [PaginatedCrudCubit].
///
/// Supplying [nextPageQuery] means another page is available. Its concrete
/// type may represent an offset, a page number, a cursor, or another backend
/// paging contract.
class CrudPageData<Entity, PageQuery> {
  CrudPageData({required List<Entity> items, this.nextPageQuery, this.total})
    : items = List.unmodifiable(items);

  final List<Entity> items;
  final PageQuery? nextPageQuery;
  final int? total;
}

class PaginatedCrudState<Entity, PageQuery> {
  PaginatedCrudState({
    required this.status,
    List<Entity> items = const [],
    this.nextPageQuery,
    this.total,
    this.error,
    this.loadMoreError,
  }) : items = List.unmodifiable(items);

  factory PaginatedCrudState.initial() {
    return PaginatedCrudState(status: PaginatedCrudStatus.initial);
  }

  final PaginatedCrudStatus status;
  final List<Entity> items;
  final PageQuery? nextPageQuery;
  final int? total;
  final Failure? error;
  final Failure? loadMoreError;

  bool get isLoading => status == PaginatedCrudStatus.loading;
  bool get isLoadingMore => status == PaginatedCrudStatus.loadingMore;
  bool get isMutating => status == PaginatedCrudStatus.mutating;
  bool get isBusy => isLoading || isLoadingMore || isMutating;
  bool get hasMore => nextPageQuery != null;
}
