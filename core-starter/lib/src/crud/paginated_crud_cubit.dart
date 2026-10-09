import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_starter/src/crud/paginated_crud_state.dart';
import 'package:gasione_core_starter/src/errors/error_reporter.dart';

typedef CrudPageMapper<Entity, PageQuery, Response> =
    CrudPageData<Entity, PageQuery> Function(Response result);

/// Generic CRUD orchestration for backends that expose paginated list data.
///
/// Feature Cubits may extend this class and provide their repository, initial
/// query, entity identity selector, and page-response mapper. Features with a
/// different contract remain free to use their own Cubit implementation.
class PaginatedCrudCubit<
  Entity,
  Id,
  Query,
  PageQuery,
  PageResponse,
  CreateDraft,
  UpdateDraft
>
    extends Cubit<PaginatedCrudState<Entity, PageQuery>> {
  PaginatedCrudCubit({
    required this.repository,
    required this.initialPageQuery,
    required this.idOf,
    required this.mapPage,
    this.reloadAfterMutation = true,
  }) : super(PaginatedCrudState.initial());

  final BaseCrudRepository<
    Entity,
    Id,
    Query,
    PageQuery,
    PageResponse,
    CreateDraft,
    UpdateDraft
  >
  repository;
  final PageQuery initialPageQuery;
  final Id Function(Entity entity) idOf;
  final CrudPageMapper<Entity, PageQuery, PageResponse> mapPage;

  /// Disable only for APIs that simulate mutations without persisting them.
  final bool reloadAfterMutation;
  int _generation = 0;

  Future<void> load() async {
    if (isClosed || state.isMutating) {
      return;
    }

    final generation = ++_generation;
    final current = state;
    emit(
      PaginatedCrudState(
        status: PaginatedCrudStatus.loading,
        items: current.items,
        nextPageQuery: current.nextPageQuery,
        total: current.total,
      ),
    );

    final result = await repository.queryPage(initialPageQuery);
    if (isClosed || generation != _generation) return;
    switch (result) {
      case Success(:final data):
        _emitFirstPage(data, current);
      case FailureResult(:final failure):
        emit(
          PaginatedCrudState(
            status: PaginatedCrudStatus.failure,
            items: current.items,
            nextPageQuery: current.nextPageQuery,
            total: current.total,
            error: failure,
          ),
        );
    }
  }

  Future<void> loadMore() => _loadMore();

  Future<void> retryLoadMore() => _loadMore(retry: true);

  Future<void> _loadMore({bool retry = false}) async {
    final pageQuery = state.nextPageQuery;
    if (isClosed ||
        state.isBusy ||
        pageQuery == null ||
        (state.loadMoreError != null && !retry)) {
      return;
    }

    final current = state;
    emit(
      PaginatedCrudState(
        status: PaginatedCrudStatus.loadingMore,
        items: current.items,
        nextPageQuery: current.nextPageQuery,
        total: current.total,
      ),
    );

    final generation = _generation;
    final result = await repository.queryPage(pageQuery);
    if (isClosed || generation != _generation) return;
    switch (result) {
      case Success(:final data):
        _emitNextPage(data, current);
      case FailureResult(:final failure):
        emit(
          PaginatedCrudState(
            status: PaginatedCrudStatus.ready,
            items: current.items,
            nextPageQuery: current.nextPageQuery,
            total: current.total,
            loadMoreError: failure,
          ),
        );
    }
  }

  Future<bool> create(CreateDraft draft) async {
    if (isClosed || state.isBusy) {
      return false;
    }

    final current = state;
    _emitMutating(current);
    final result = await repository.create(draft);
    if (isClosed) return result is Success;
    switch (result) {
      case Success(:final data):
        if (reloadAfterMutation) {
          await _reloadAfterMutation();
          return true;
        }
        emit(
          PaginatedCrudState(
            status: PaginatedCrudStatus.ready,
            items: [data, ...current.items],
            nextPageQuery: current.nextPageQuery,
            total: current.total == null ? null : current.total! + 1,
          ),
        );
        return true;
      case FailureResult(:final failure):
        _emitMutationFailure(current, failure);
        return false;
    }
  }

  Future<bool> update(Entity entity, UpdateDraft draft) async {
    if (isClosed || state.isBusy) {
      return false;
    }

    final current = state;
    final id = idOf(entity);
    _emitMutating(current);
    final result = await repository.update(id, draft);
    if (isClosed) return result is Success;
    switch (result) {
      case Success(:final data):
        if (reloadAfterMutation) {
          await _reloadAfterMutation();
          return true;
        }
        emit(
          PaginatedCrudState(
            status: PaginatedCrudStatus.ready,
            items: [
              for (final item in current.items)
                if (idOf(item) == id) data else item,
            ],
            nextPageQuery: current.nextPageQuery,
            total: current.total,
          ),
        );
        return true;
      case FailureResult(:final failure):
        _emitMutationFailure(current, failure);
        return false;
    }
  }

  Future<bool> delete(Entity entity) async {
    if (isClosed || state.isBusy) {
      return false;
    }

    final current = state;
    final id = idOf(entity);
    _emitMutating(current);
    final result = await repository.delete(id);
    if (isClosed) return result is Success;
    switch (result) {
      case Success():
        if (reloadAfterMutation) {
          await _reloadAfterMutation();
          return true;
        }
        emit(
          PaginatedCrudState(
            status: PaginatedCrudStatus.ready,
            items: current.items.where((item) => idOf(item) != id).toList(),
            nextPageQuery: current.nextPageQuery,
            total: current.total == null
                ? null
                : current.total! > 0
                ? current.total! - 1
                : 0,
          ),
        );
        return true;
      case FailureResult(:final failure):
        _emitMutationFailure(current, failure);
        return false;
    }
  }

  /// Mutation success remains success even if refreshing the list fails.
  /// In that case, discard the obsolete paging cursor and offer a fresh retry.
  Future<void> _reloadAfterMutation() async {
    final result = await repository.queryPage(initialPageQuery);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        _emitFirstPage(data, PaginatedCrudState.initial());
      case FailureResult(:final failure):
        emit(
          PaginatedCrudState(
            status: PaginatedCrudStatus.failure,
            error: failure,
          ),
        );
    }
  }

  void _emitFirstPage(
    PageResponse result,
    PaginatedCrudState<Entity, PageQuery> previous,
  ) {
    try {
      final page = mapPage(result);
      emit(
        PaginatedCrudState(
          status: PaginatedCrudStatus.ready,
          items: page.items,
          nextPageQuery: page.nextPageQuery,
          total: page.total,
        ),
      );
    } on Object catch (error, stackTrace) {
      reportUnexpectedError(error, stackTrace);
      emit(
        PaginatedCrudState(
          status: PaginatedCrudStatus.failure,
          items: previous.items,
          nextPageQuery: previous.nextPageQuery,
          total: previous.total,
          error: const InvalidResponseFailure(),
        ),
      );
    }
  }

  void _emitNextPage(
    PageResponse result,
    PaginatedCrudState<Entity, PageQuery> previous,
  ) {
    try {
      final page = mapPage(result);
      final ids = previous.items.map(idOf).toSet();
      emit(
        PaginatedCrudState(
          status: PaginatedCrudStatus.ready,
          items: [
            ...previous.items,
            for (final item in page.items)
              if (ids.add(idOf(item))) item,
          ],
          nextPageQuery: page.nextPageQuery,
          total: page.total ?? previous.total,
        ),
      );
    } on Object catch (error, stackTrace) {
      reportUnexpectedError(error, stackTrace);
      emit(
        PaginatedCrudState(
          status: PaginatedCrudStatus.ready,
          items: previous.items,
          nextPageQuery: previous.nextPageQuery,
          total: previous.total,
          loadMoreError: const InvalidResponseFailure(),
        ),
      );
    }
  }

  void _emitMutating(PaginatedCrudState<Entity, PageQuery> current) {
    emit(
      PaginatedCrudState(
        status: PaginatedCrudStatus.mutating,
        items: current.items,
        nextPageQuery: current.nextPageQuery,
        total: current.total,
      ),
    );
  }

  void _emitMutationFailure(
    PaginatedCrudState<Entity, PageQuery> previous,
    Failure failure,
  ) {
    emit(
      PaginatedCrudState(
        status: PaginatedCrudStatus.failure,
        items: previous.items,
        nextPageQuery: previous.nextPageQuery,
        total: previous.total,
        error: failure,
      ),
    );
  }
}
