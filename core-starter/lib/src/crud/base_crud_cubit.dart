import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_starter/src/crud/paginated_crud_cubit.dart';
import 'package:gasione_core_starter/src/crud/paginated_crud_state.dart';

/// Convenience Cubit for the standard BaseController query/page contract.
class BaseCrudCubit<Entity, Id, CreateDraft, UpdateDraft>
    extends
        PaginatedCrudCubit<
          Entity,
          Id,
          QueryRequest,
          QueryRequest,
          PageResult<Entity>,
          CreateDraft,
          UpdateDraft
        > {
  BaseCrudCubit({
    required super.repository,
    required QueryRequest initialQuery,
    required super.idOf,
  }) : super(
         initialPageQuery: initialQuery,
         mapPage: (result) => CrudPageData(
           items: result.content,
           total: result.totalElements,
           nextPageQuery: result.hasNext
               ? initialQuery.copyWith(page: result.page + 1)
               : null,
         ),
       );
}
