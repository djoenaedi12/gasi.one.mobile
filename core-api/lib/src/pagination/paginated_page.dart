/// A single page returned by an offset-based paginated data source.
class PaginatedPage<T> {
  PaginatedPage({
    required List<T> items,
    required this.total,
    required this.offset,
    required this.limit,
  }) : items = List.unmodifiable(items);

  final List<T> items;
  final int total;
  final int offset;
  final int limit;

  int get nextOffset => offset + items.length;
  bool get hasMore => items.isNotEmpty && nextOffset < total;
}
