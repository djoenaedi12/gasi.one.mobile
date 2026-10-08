import 'package:gasione_core_api/src/crud/base_read_repository.dart';
import 'package:gasione_core_api/src/result/result.dart';

/// Domain-facing CRUD contract mirroring the backend BaseController.
abstract interface class BaseCrudRepository<
  Entity,
  Id,
  Query,
  PageQuery,
  PageResult,
  CreateDraft,
  UpdateDraft
>
    implements BaseReadRepository<Entity, Id, Query, PageQuery, PageResult> {
  Future<Result<Entity>> create(CreateDraft draft);

  Future<Result<Entity>> update(Id id, UpdateDraft draft);

  Future<Result<void>> delete(Id id);
}
