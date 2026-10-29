import 'package:flutter/foundation.dart';
import 'package:gasione_core_api/gasione_core_api.dart';

/// Bulk orchestration uses existing single-request APIs. Successful rows are
/// removed from selection, so retry only processes failures.
final class RequestSelectionController<T> extends ChangeNotifier {
  RequestSelectionController({
    required this.idOf,
    required this.canSelect,
    required this.canExecute,
    required this.execute,
  });
  final int Function(T) idOf;
  final bool Function(T) canSelect;
  final bool Function(T, WorkflowAction) canExecute;
  final Future<Result<void>> Function(T, WorkflowAction, String) execute;
  final Map<int, T> _selected = {};
  Set<int> get selectedIds => Set.unmodifiable(_selected.keys);
  bool selecting = false;
  bool get busy => _pending != null;
  Future<BulkActionResult>? _pending;
  bool _disposed = false;
  int _generation = 0;
  void toggle(T item) {
    if (_disposed || busy || !canSelect(item)) return;
    selecting = true;
    final id = idOf(item);
    if (_selected.containsKey(id)) {
      _selected.remove(id);
    } else {
      _selected[id] = item;
    }
    notifyListeners();
  }

  void selectAll(Iterable<T> items) {
    if (_disposed || busy) return;
    selecting = true;
    for (final item in items.where(canSelect)) {
      _selected[idOf(item)] = item;
    }
    notifyListeners();
  }

  void done() {
    if (_disposed || busy) return;
    clear();
  }

  void clear() {
    if (_disposed) return;
    _generation++;
    _selected.clear();
    selecting = false;
    notifyListeners();
  }

  Future<BulkActionResult> run(WorkflowAction action, {String remark = ''}) {
    final pending = _pending;
    if (pending != null) return pending;
    if (action != WorkflowAction.approve && action != WorkflowAction.reject) {
      throw ArgumentError('Bulk supports approval and rejection only.');
    }
    final generation = _generation;
    final snapshot = Map<int, T>.of(_selected);
    final future = Future<BulkActionResult>(() async {
      final succeeded = <int>{};
      final failures = <int, Failure>{};
      for (final entry in snapshot.entries) {
        if (_disposed || generation != _generation) break;
        if (!canExecute(entry.value, action)) {
          failures[entry.key] = const ForbiddenFailure();
          continue;
        }
        Result<void> result;
        try {
          result = await execute(entry.value, action, remark);
        } catch (_) {
          result = const FailureResult(UnknownFailure());
        }
        if (_disposed || generation != _generation) break;
        switch (result) {
          case Success<void>():
            succeeded.add(entry.key);
            _selected.remove(entry.key);
          case FailureResult<void>(:final failure):
            failures[entry.key] = failure;
        }
      }
      return BulkActionResult(succeeded: succeeded, failures: failures);
    });
    _pending = future.whenComplete(() {
      _pending = null;
      if (!_disposed) {
        if (_selected.isEmpty) selecting = false;
        notifyListeners();
      }
    });
    notifyListeners();
    return _pending!;
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
