import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_plugin_catalog/src/features/categories/data/models/category_model.dart';

class CategoryRemoteDataSource
    extends
        BaseCrudRemoteDataSource<
          CategoryModel,
          String,
          CategoryPayload,
          CategoryPayload
        > {
  CategoryRemoteDataSource(ApiClient apiClient)
    : super(
        apiClient: apiClient,
        basePath: '/categories',
        modelFromJson: CategoryModel.fromJson,
        createToJson: (payload) => payload.toJson(),
        updateToJson: (payload) => payload.toJson(),
      );
}
