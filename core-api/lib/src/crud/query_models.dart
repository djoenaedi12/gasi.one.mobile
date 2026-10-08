enum FilterOperator {
  equals('EQUALS', requiresValue: true),
  notEquals('NOT_EQUALS', requiresValue: true),
  greaterThan('GREATER_THAN', requiresValue: true),
  greaterThanOrEquals('GREATER_THAN_OR_EQUALS', requiresValue: true),
  lessThan('LESS_THAN', requiresValue: true),
  lessThanOrEquals('LESS_THAN_OR_EQUALS', requiresValue: true),
  like('LIKE', requiresValue: true),
  inList('IN', requiresValue: true),
  isNull('IS_NULL', requiresValue: false),
  isNotNull('IS_NOT_NULL', requiresValue: false);

  const FilterOperator(this.wireValue, {required this.requiresValue});

  final String wireValue;
  final bool requiresValue;
}

sealed class GenericFilter {
  const GenericFilter();

  Map<String, dynamic> toJson();
}

final class SimpleFilter extends GenericFilter {
  const SimpleFilter({required this.field, required this.operator, this.value})
    : assert(field != ''),
      assert(
        operator == FilterOperator.isNull ||
            operator == FilterOperator.isNotNull ||
            value != null,
        'This filter operator requires a value.',
      );

  final String field;
  final FilterOperator operator;
  final Object? value;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'simple',
    'field': field,
    'operator': operator.wireValue,
    if (operator.requiresValue) 'value': _encodeValue(value),
  };
}

final class AndFilter extends GenericFilter {
  const AndFilter(this.filters);

  final List<GenericFilter> filters;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'and',
    'filters': filters.map((filter) => filter.toJson()).toList(),
  };
}

final class OrFilter extends GenericFilter {
  const OrFilter(this.filters);

  final List<GenericFilter> filters;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'or',
    'filters': filters.map((filter) => filter.toJson()).toList(),
  };
}

enum SortDirection {
  asc('ASC'),
  desc('DESC');

  const SortDirection(this.wireValue);

  final String wireValue;
}

class SortOrder {
  const SortOrder({required this.field, required this.direction})
    : assert(field != '');

  const SortOrder.asc(String field)
    : this(field: field, direction: SortDirection.asc);

  const SortOrder.desc(String field)
    : this(field: field, direction: SortDirection.desc);

  final String field;
  final SortDirection direction;

  Map<String, dynamic> toJson() => {
    'field': field,
    'direction': direction.wireValue,
  };
}

class QueryRequest {
  const QueryRequest({
    this.filter,
    this.sorts = const [],
    this.fields = const [],
    this.page = defaultPage,
    this.size = defaultSize,
  });

  static const defaultPage = 0;
  static const defaultSize = 10;
  static const maxSize = 100;

  final GenericFilter? filter;
  final List<SortOrder> sorts;
  final List<String> fields;
  final int page;
  final int size;

  int get normalizedPage => page < defaultPage ? defaultPage : page;
  int get normalizedSize => size <= 0
      ? defaultSize
      : size > maxSize
      ? maxSize
      : size;

  QueryRequest copyWith({
    GenericFilter? filter,
    List<SortOrder>? sorts,
    List<String>? fields,
    int? page,
    int? size,
  }) {
    return QueryRequest(
      filter: filter ?? this.filter,
      sorts: sorts ?? this.sorts,
      fields: fields ?? this.fields,
      page: page ?? this.page,
      size: size ?? this.size,
    );
  }

  QueryRequest nextPage() => copyWith(page: normalizedPage + 1);

  Map<String, dynamic> toJson() => {
    if (filter != null) 'filter': filter!.toJson(),
    if (sorts.isNotEmpty) 'sorts': sorts.map((sort) => sort.toJson()).toList(),
    if (fields.isNotEmpty) 'fields': fields,
    'page': normalizedPage,
    'size': normalizedSize,
  };
}

Object? _encodeValue(Object? value) {
  return switch (value) {
    DateTime dateTime => dateTime.toIso8601String(),
    Iterable<Object?> values => values.map(_encodeValue).toList(),
    Map<Object?, Object?> values => {
      for (final entry in values.entries)
        entry.key.toString(): _encodeValue(entry.value),
    },
    _ => value,
  };
}
