import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_plugin_catalog/src/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:gasione_plugin_catalog/src/features/categories/data/models/category_model.dart';
import 'package:gasione_plugin_catalog/src/features/categories/domain/entities/category.dart';
import 'package:gasione_plugin_catalog/src/features/categories/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl
    extends
        BaseCrudRepositoryImpl<
          CategoryModel,
          Category,
          String,
          CategoryDraft,
          CategoryDraft,
          CategoryPayload,
          CategoryPayload
        >
    implements CategoryRepository {
  CategoryRepositoryImpl(CategoryRemoteDataSource dataSource)
    : super(
        dataSource: dataSource,
        toEntity: (model) => model.toEntity(),
        toCreatePayload: CategoryPayload.fromDraft,
        toUpdatePayload: CategoryPayload.fromDraft,
      );
}
