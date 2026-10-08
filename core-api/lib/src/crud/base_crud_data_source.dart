import 'package:gasione_core_api/src/crud/base_read_data_source.dart';

/// CRUD extension of [BaseReadDataSource], mirroring the backend
/// BaseController contract.
abstract interface class BaseCrudDataSource<
  Model,
  Id,
  QueryPayload,
  PageQueryPayload,
  PageResponse,
  CreatePayload,
  UpdatePayload
>
    implements
        BaseReadDataSource<
          Model,
          Id,
          QueryPayload,
          PageQueryPayload,
          PageResponse
        > {
  /// Maps to `POST /`.
  Future<Model> create(CreatePayload payload);

  /// Maps to `PUT /{id}`.
  Future<Model> update(Id id, UpdatePayload payload);

  /// Maps to `DELETE /{id}`.
  Future<void> delete(Id id);
}
