import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_plugin_catalog/src/features/categories/domain/entities/category.dart';
import 'package:gasione_plugin_catalog/src/features/categories/domain/repositories/category_repository.dart';

class CategoriesCubit
    extends BaseCrudCubit<Category, String, CategoryDraft, CategoryDraft> {
  CategoriesCubit(CategoryRepository repository)
    : super(
        repository: repository,
        initialQuery: const QueryRequest(
          sorts: [SortOrder.asc('code')],
          fields: ['id', 'code', 'name', 'description'],
        ),
        idOf: (category) => category.id,
      );
}
