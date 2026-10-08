import 'package:gasione_core_api/src/result/result.dart';

/// Domain-facing read contract mirroring the backend BaseReadController.
///
/// Query and page types remain generic so non-standard providers are not
/// coupled to the application's page-based REST contract.
abstract interface class BaseReadRepository<
  Entity,
  Id,
  Query,
  PageQuery,
  PageResult
> {
  Future<Result<Entity>> getById(Id id);

  Future<Result<Entity?>> queryOne(Query query);

  Future<Result<List<Entity>>> queryList(Query query);

  Future<Result<PageResult>> queryPage(PageQuery query);
}
