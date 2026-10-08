import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_starter/src/network/api_client.dart';
import 'package:gasione_core_starter/src/network/api_exception.dart';
import 'package:gasione_core_starter/src/network/api_response.dart';

typedef JsonObjectParser<T> = T Function(Map<String, dynamic> json);
typedef JsonObjectEncoder<T> = Map<String, Object?> Function(T value);

/// Standard REST implementation matching BaseReadController/BaseController.
///
/// Feature data sources can extend this class and only provide their base path,
/// JSON model parser, and create/update payload encoders.
class BaseCrudRemoteDataSource<Model, Id, CreatePayload, UpdatePayload>
    implements
        BaseCrudDataSource<
          Model,
          Id,
          QueryRequest,
          QueryRequest,
          PageResult<Model>,
          CreatePayload,
          UpdatePayload
        > {
  BaseCrudRemoteDataSource({
    required this.apiClient,
    required String basePath,
    required this.modelFromJson,
    required this.createToJson,
    required this.updateToJson,
    String Function(Id id)? idToPath,
  }) : _basePath = _normalizeBasePath(basePath),
       _idToPath = idToPath ?? ((id) => Uri.encodeComponent(id.toString()));

  final ApiClient apiClient;
  final String _basePath;
  final JsonObjectParser<Model> modelFromJson;
  final JsonObjectEncoder<CreatePayload> createToJson;
  final JsonObjectEncoder<UpdatePayload> updateToJson;
  final String Function(Id id) _idToPath;

  @override
  Future<Model> getById(Id id) async {
    final json = await apiClient.getJson('$_basePath/${_idToPath(id)}');
    return _objectEnvelope(json).requireData();
  }

  @override
  Future<Model?> queryOne(QueryRequest query) async {
    final json = await apiClient.postJson(
      '$_basePath/query/one',
      data: query.toJson(),
    );
    return _objectEnvelope(json).data;
  }

  @override
  Future<List<Model>> queryList(QueryRequest query) async {
    final json = await apiClient.postJson(
      '$_basePath/query/list',
      data: query.toJson(),
    );
    return ApiResponse<List<Model>>.fromJson(json, _parseList).requireData();
  }

  @override
  Future<PageResult<Model>> queryPage(QueryRequest query) async {
    final json = await apiClient.postJson(
      '$_basePath/query/page',
      data: query.toJson(),
    );
    return ApiResponse<PageResult<Model>>.fromJson(
      json,
      (data) => PageResult.fromJson(_asJsonObject(data), modelFromJson),
    ).requireData();
  }

  @override
  Future<Model> create(CreatePayload payload) async {
    final json = await apiClient.postJson(
      _basePath,
      data: createToJson(payload),
    );
    return _objectEnvelope(json).requireData();
  }

  @override
  Future<Model> update(Id id, UpdatePayload payload) async {
    final json = await apiClient.putJson(
      '$_basePath/${_idToPath(id)}',
      data: updateToJson(payload),
    );
    return _objectEnvelope(json).requireData();
  }

  @override
  Future<void> delete(Id id) async {
    final json = await apiClient.deleteJson('$_basePath/${_idToPath(id)}');
    ApiResponse<void>.fromJson(json, (_) {});
  }

  ApiResponse<Model> _objectEnvelope(Map<String, dynamic> json) {
    return ApiResponse<Model>.fromJson(
      json,
      (data) => modelFromJson(_asJsonObject(data)),
    );
  }

  List<Model> _parseList(Object? data) {
    if (data is! List) {
      throw const ApiException(
        ApiExceptionType.invalidResponse,
        message: 'Expected a response data array.',
      );
    }
    return [for (final item in data) modelFromJson(_asJsonObject(item))];
  }

  static Map<String, dynamic> _asJsonObject(Object? data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw const ApiException(
      ApiExceptionType.invalidResponse,
      message: 'Expected a response data object.',
    );
  }

  static String _normalizeBasePath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(path, 'basePath', 'Must not be empty.');
    }
    final withLeadingSlash = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return withLeadingSlash.endsWith('/')
        ? withLeadingSlash.substring(0, withLeadingSlash.length - 1)
        : withLeadingSlash;
  }
}
