/// Provider-agnostic read contract mirroring the backend BaseReadController.
///
/// The standard REST implementation uses `QueryRequest` and `PageResult`,
/// while alternative providers may supply different query/page types.
abstract interface class BaseReadDataSource<
  Model,
  Id,
  QueryPayload,
  PageQueryPayload,
  PageResponse
> {
  /// Maps to `GET /{id}`.
  Future<Model> getById(Id id);

  /// Maps to `POST /query/one`.
  Future<Model?> queryOne(QueryPayload query);

  /// Maps to `POST /query/list`.
  Future<List<Model>> queryList(QueryPayload query);

  /// Maps to `POST /query/page`.
  Future<PageResponse> queryPage(PageQueryPayload query);
}
