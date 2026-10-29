import 'package:flutter/material.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

import '../application/request_list_controller.dart';
import '../localization/request_localizations.dart';

/// Generic picker over the typed reference contract. The feature supplies its
/// own eligibility policy and filters without importing legacy models.
class RequestReferencePicker extends StatefulWidget {
  const RequestReferencePicker({
    super.key,
    required this.title,
    required this.repository,
    required this.kind,
    this.filters = const {},
    this.isEligible,
  });
  final String title;
  final RequestReferenceRepository repository;
  final RequestReferenceKind kind;
  final Map<String, Object?> filters;
  final bool Function(RequestReference)? isEligible;
  @override
  State<RequestReferencePicker> createState() => _RequestReferencePickerState();
}

class _RequestReferencePickerState extends State<RequestReferencePicker> {
  late final RequestListController<RequestReference> _list;
  @override
  void initState() {
    super.initState();
    _list = RequestListController(
      mode: RequestMode.submission,
      load: (query) => widget.repository.list(
        widget.kind,
        search: query.search,
        page: query.page,
        size: query.size,
        filters: widget.filters,
      ),
    );
    _list.refresh();
  }

  @override
  void dispose() {
    _list.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: RequestLocalizations.of(context).search,
          ),
          onChanged: (value) => _list.setQuery(search: value),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: _list,
            builder: (context, _) {
              final strings = RequestLocalizations.of(context);
              return ListView(
                children: [
                  if (_list.loading) const LinearProgressIndicator(),
                  if (!_list.loading &&
                      _list.failure == null &&
                      _list.items.isEmpty)
                    AppEmptyView(title: strings.empty, message: ''),
                  for (final item in _list.items)
                    ListTile(
                      title: Text(item.label),
                      subtitle: item.code == null ? null : Text(item.code!),
                      enabled:
                          item.eligible &&
                          (widget.isEligible?.call(item) ?? true),
                      onTap: () => Navigator.pop(context, item),
                    ),
                  if (_list.failure != null)
                    AppErrorView(
                      message: strings.failed,
                      actionLabel: strings.retry,
                      onAction: () => _list.items.isEmpty
                          ? _list.refresh()
                          : _list.nextPage(),
                    ),
                  if (_list.hasNext && !_list.loading && _list.failure == null)
                    TextButton(
                      onPressed: _list.nextPage,
                      child: Text(strings.loadMore),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}
