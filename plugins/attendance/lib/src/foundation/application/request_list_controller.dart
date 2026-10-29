import 'package:flutter/foundation.dart';
import 'package:gasione_core_api/gasione_core_api.dart';

/// One instance per workspace mode retains search/filter/sort and loaded pages.
final class RequestListController<T> extends ChangeNotifier {
  RequestListController({required this.load, required RequestMode mode})
    : query = RequestQuery(mode: mode);
  final Future<Result<PageResult<T>>> Function(RequestQuery) load;
  RequestQuery query;
  List<T> _items = const [];
  List<T> get items => _items;
  bool loading = false;
  bool hasNext = true;
  bool initialized = false;
  Failure? failure;
  int _generation = 0;
  int _nextPage = 0;
  bool _disposed = false;

  Future<void> refresh() => _fetch(reset: true);
  Future<void> nextPage() async {
    if (loading || !hasNext) return;
    await _fetch(reset: false);
  }

  Future<void> setQuery({
    String? search,
    Map<String, Object?>? filters,
    List<String>? sort,
  }) {
    query = query.copyWith(
      search: search,
      filters: filters,
      sort: sort,
      page: 0,
    );
    return refresh();
  }

  Future<void> _fetch({required bool reset}) async {
    if (_disposed) return;
    final generation = ++_generation;
    loading = true;
    failure = null;
    if (reset) {
      _items = List<T>.unmodifiable([]);
      _nextPage = 0;
      hasNext = true;
    }
    notifyListeners();
    Result<PageResult<T>> result;
    try {
      result = await load(query.copyWith(page: _nextPage));
    } catch (_) {
      result = const FailureResult(UnknownFailure());
    }
    if (_disposed || generation != _generation) return;
    loading = false;
    initialized = true;
    switch (result) {
      case Success<PageResult<T>>(:final data):
        _items = List.unmodifiable([..._items, ...data.content]);
        _nextPage = data.page + 1;
        hasNext = data.hasNext;
      case FailureResult<PageResult<T>>(:final failure):
        this.failure = failure;
    }
    notifyListeners();
  }

  /// Clears sensitive rows immediately when the host changes company/session.
  void clear() {
    if (_disposed) return;
    _generation++;
    _items = List<T>.unmodifiable([]);
    loading = false;
    initialized = false;
    hasNext = true;
    failure = null;
    _nextPage = 0;
    query = RequestQuery(mode: query.mode, size: query.size);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
