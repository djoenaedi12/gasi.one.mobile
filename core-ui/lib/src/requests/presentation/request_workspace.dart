import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gasione_core_api/gasione_core_api.dart';

import '../../design_system/patterns/app_empty_view.dart';
import '../../design_system/patterns/app_error_view.dart';
import '../application/request_list_controller.dart';
import '../application/request_selection_controller.dart';
import '../localization/request_localizations.dart';
import 'request_components.dart';

/// Features compose concrete cards and modal content through builders.
class RequestWorkspace<T> extends StatefulWidget {
  const RequestWorkspace({
    super.key,
    required this.title,
    required this.context,
    required this.submission,
    required this.approval,
    required this.cardBuilder,
    required this.idOf,
    this.selection,
    this.filterBuilder,
    this.sortBuilder,
    this.summaryBuilder,
    this.onOpen,
    this.actionsBuilder,
  });
  final String title;
  final BusinessContextProvider context;
  final RequestListController<T> submission;
  final RequestListController<T> approval;
  final RequestSelectionController<T>? selection;
  final int Function(T) idOf;
  final Widget Function(BuildContext, T, RequestMode) cardBuilder;
  final Widget Function(BuildContext, RequestMode, RequestQuery)? filterBuilder;
  final Widget Function(BuildContext, RequestMode, RequestQuery)? sortBuilder;
  final Widget Function(BuildContext, T, RequestMode)? summaryBuilder;
  final void Function(T, RequestMode)? onOpen;
  final List<Widget> Function(BuildContext, RequestMode)? actionsBuilder;
  @override
  State<RequestWorkspace<T>> createState() => _RequestWorkspaceState<T>();
}

class _RequestWorkspaceState<T> extends State<RequestWorkspace<T>>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _search = TextEditingController();
  Timer? _debounce;
  StreamSubscription<ActiveBusinessContext?>? _context;
  String? _session;
  int _index = 0;
  RequestMode get _mode => RequestMode.values[_index];
  RequestListController<T> get _current =>
      _index == 0 ? widget.submission : widget.approval;
  @override
  void initState() {
    super.initState();
    _search.text = widget.submission.query.search;
    _tabs = TabController(length: 2, vsync: this)..addListener(_tabChanged);
    widget.submission.addListener(_changed);
    widget.approval.addListener(_changed);
    widget.selection?.addListener(_changed);
    _session = widget.context.activeContext?.sessionId;
    _context = widget.context.contextChanges.listen(_contextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _session == null) return;
      if (!widget.submission.initialized) {
        unawaited(widget.submission.refresh());
      }
      if (!widget.approval.initialized) unawaited(widget.approval.refresh());
    });
  }

  void _contextChanged(ActiveBusinessContext? value) {
    if (!mounted || value?.sessionId == _session) return;
    _session = value?.sessionId;
    _debounce?.cancel();
    _search.clear();
    widget.selection?.clear();
    widget.submission.clear();
    widget.approval.clear();
    if (value != null) {
      unawaited(widget.submission.refresh());
      unawaited(widget.approval.refresh());
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _tabChanged() {
    if (_index == _tabs.index) return;
    _debounce?.cancel();
    widget.selection?.done();
    setState(() {
      _index = _tabs.index;
      _search.text = _current.query.search;
    });
  }

  void _searchChanged(String text) {
    _debounce?.cancel();
    widget.selection?.done();
    final controller = _current;
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) unawaited(controller.setQuery(search: text));
    });
  }

  Future<void> _filter() async {
    final controller = _current;
    final builder = widget.filterBuilder!;
    final result = await showRequestModal<Map<String, Object?>>(
      context,
      builder: (context) =>
          builder(context, controller.query.mode, controller.query),
    );
    if (!mounted || result == null) return;
    widget.selection?.done();
    await controller.setQuery(filters: result);
  }

  Future<void> _sort() async {
    final controller = _current;
    final builder = widget.sortBuilder!;
    final result = await showRequestModal<List<String>>(
      context,
      builder: (context) =>
          builder(context, controller.query.mode, controller.query),
    );
    if (!mounted || result == null) return;
    widget.selection?.done();
    await controller.setQuery(sort: result);
  }

  Future<void> _open(T item, RequestMode mode) async {
    final summary = widget.summaryBuilder;
    if (summary != null) {
      await showRequestModal<void>(
        context,
        builder: (context) => summary(context, item, mode),
      );
    } else {
      widget.onOpen?.call(item, mode);
    }
  }

  Future<void> _bulk(WorkflowAction action) async {
    final selection = widget.selection!;
    final strings = RequestLocalizations.of(context);
    final remark = await showRequestRemarkDialog(
      context,
      title: action == WorkflowAction.approve
          ? strings.approve
          : strings.reject,
    );
    if (!mounted || remark == null) return;
    final result = await selection.run(action, remark: remark);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          strings.bulkResult(result.succeeded.length, result.failures.length),
        ),
      ),
    );
    if (result.succeeded.isNotEmpty) await widget.approval.refresh();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    unawaited(_context?.cancel());
    _tabs.removeListener(_tabChanged);
    _tabs.dispose();
    _search.dispose();
    widget.submission.removeListener(_changed);
    widget.approval.removeListener(_changed);
    widget.selection?.removeListener(_changed);
    // Controllers are supplied and owned by the feature; keep their retained state.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = RequestLocalizations.of(context);
    final selection = widget.selection;
    final selecting =
        _mode == RequestMode.approval && selection?.selecting == true;
    final busy = selection?.busy == true;
    return PopScope(
      canPop: !selecting && !busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) selection?.done();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            selecting
                ? strings.selected(selection!.selectedIds.length)
                : widget.title,
          ),
          leading: selecting
              ? IconButton(
                  onPressed: busy ? null : selection!.done,
                  icon: const Icon(Icons.close),
                  tooltip: strings.done,
                )
              : null,
          actions: selecting
              ? [
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => selection!.selectAll(widget.approval.items),
                    child: Text(strings.selectAll),
                  ),
                ]
              : widget.actionsBuilder?.call(context, _mode),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: IgnorePointer(
              ignoring: busy,
              child: TabBar(
                controller: _tabs,
                tabs: [
                  Tab(text: strings.submission),
                  Tab(text: strings.approval),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      enabled: !busy,
                      decoration: InputDecoration(
                        labelText: strings.search,
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: _searchChanged,
                    ),
                  ),
                  if (widget.filterBuilder != null)
                    IconButton(
                      onPressed: busy ? null : _filter,
                      icon: const Icon(Icons.filter_list),
                      tooltip: strings.filter,
                    ),
                  if (widget.sortBuilder != null)
                    IconButton(
                      onPressed: busy ? null : _sort,
                      icon: const Icon(Icons.sort),
                      tooltip: strings.sort,
                    ),
                ],
              ),
            ),
            if (busy) const LinearProgressIndicator(),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                physics: busy ? const NeverScrollableScrollPhysics() : null,
                children: [
                  _list(widget.submission, RequestMode.submission),
                  _list(widget.approval, RequestMode.approval),
                ],
              ),
            ),
            if (selecting)
              SafeArea(
                top: false,
                child: Wrap(
                  spacing: 12,
                  children: [
                    TextButton(
                      onPressed: busy || selection!.selectedIds.isEmpty
                          ? null
                          : () => _bulk(WorkflowAction.reject),
                      child: Text(strings.reject),
                    ),
                    FilledButton(
                      onPressed: busy || selection!.selectedIds.isEmpty
                          ? null
                          : () => _bulk(WorkflowAction.approve),
                      child: Text(strings.approve),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _list(RequestListController<T> controller, RequestMode mode) {
    final strings = RequestLocalizations.of(context);
    final selection = mode == RequestMode.approval ? widget.selection : null;
    return RefreshIndicator(
      onRefresh: () async {
        if (selection?.busy == true) return;
        selection?.done();
        await controller.refresh();
      },
      child: ListView(
        key: PageStorageKey(mode),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (controller.loading && controller.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!controller.loading &&
              controller.failure == null &&
              controller.items.isEmpty)
            AppEmptyView(title: strings.empty, message: ''),
          for (final item in controller.items)
            InkWell(
              onLongPress: selection == null || selection.busy
                  ? null
                  : () => selection.toggle(item),
              onTap: selection?.selecting == true
                  ? () => selection!.toggle(item)
                  : () => _open(item, mode),
              child: Row(
                children: [
                  if (selection?.selecting == true)
                    Checkbox(
                      value: selection!.selectedIds.contains(widget.idOf(item)),
                      onChanged: selection.busy || !selection.canSelect(item)
                          ? null
                          : (_) => selection.toggle(item),
                    ),
                  Expanded(child: widget.cardBuilder(context, item, mode)),
                ],
              ),
            ),
          if (controller.failure != null)
            AppErrorView(
              message: strings.failed,
              actionLabel: strings.retry,
              onAction: () => controller.items.isEmpty
                  ? controller.refresh()
                  : controller.nextPage(),
            ),
          if (controller.items.isNotEmpty &&
              controller.hasNext &&
              controller.failure == null)
            TextButton(
              onPressed: controller.loading ? null : controller.nextPage,
              child: controller.loading
                  ? const CircularProgressIndicator()
                  : Text(strings.loadMore),
            ),
        ],
      ),
    );
  }
}
