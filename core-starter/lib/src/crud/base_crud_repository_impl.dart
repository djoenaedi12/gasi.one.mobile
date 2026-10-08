import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_starter/src/result/result_guard.dart';

/// Maps a standard CRUD data source into domain entities and typed results.
class BaseCrudRepositoryImpl<
  Model,
  Entity,
  Id,
  CreateDraft,
  UpdateDraft,
  CreatePayload,
  UpdatePayload
>
    implements
        BaseCrudRepository<
          Entity,
          Id,
          QueryRequest,
          QueryRequest,
          PageResult<Entity>,
          CreateDraft,
          UpdateDraft
        > {
  const BaseCrudRepositoryImpl({
    required this.dataSource,
    required this.toEntity,
    required this.toCreatePayload,
    required this.toUpdatePayload,
  });

  final BaseCrudDataSource<
    Model,
    Id,
    QueryRequest,
    QueryRequest,
    PageResult<Model>,
    CreatePayload,
    UpdatePayload
  >
  dataSource;
  final Entity Function(Model model) toEntity;
  final CreatePayload Function(CreateDraft draft) toCreatePayload;
  final UpdatePayload Function(UpdateDraft draft) toUpdatePayload;

  @override
  Future<Result<Entity>> getById(Id id) {
    return guardResult(() async => toEntity(await dataSource.getById(id)));
  }

  @override
  Future<Result<Entity?>> queryOne(QueryRequest query) {
    return guardResult(() async {
      final model = await dataSource.queryOne(query);
      return model == null ? null : toEntity(model);
    });
  }

  @override
  Future<Result<List<Entity>>> queryList(QueryRequest query) {
    return guardResult(() async {
      final models = await dataSource.queryList(query);
      return models.map(toEntity).toList(growable: false);
    });
  }

  @override
  Future<Result<PageResult<Entity>>> queryPage(QueryRequest query) {
    return guardResult(() async {
      final result = await dataSource.queryPage(query);
      return result.map(toEntity);
    });
  }

  @override
  Future<Result<Entity>> create(CreateDraft draft) {
    return guardResult(() async {
      final model = await dataSource.create(toCreatePayload(draft));
      return toEntity(model);
    });
  }

  @override
  Future<Result<Entity>> update(Id id, UpdateDraft draft) {
    return guardResult(() async {
      final model = await dataSource.update(id, toUpdatePayload(draft));
      return toEntity(model);
    });
  }

  @override
  Future<Result<void>> delete(Id id) {
    return guardResult(() => dataSource.delete(id));
  }
}
