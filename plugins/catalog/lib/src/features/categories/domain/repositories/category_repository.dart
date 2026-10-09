import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_plugin_catalog/src/features/categories/domain/entities/category.dart';

abstract interface class CategoryRepository
    implements
        BaseCrudRepository<
          Category,
          String,
          QueryRequest,
          QueryRequest,
          PageResult<Category>,
          CategoryDraft,
          CategoryDraft
        > {}
