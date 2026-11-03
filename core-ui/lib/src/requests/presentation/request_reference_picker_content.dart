import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gasione_core_api/gasione_core_api.dart';

import '../../design_system/components/buttons/app_button.dart';
import '../../design_system/patterns/app_empty_view.dart';
import '../../design_system/patterns/app_error_view.dart';
import '../../localization/failure_localization.dart';
import '../../localization/l10n/app_localizations.dart';
import '../application/request_list_controller.dart';
import '../localization/request_localizations.dart';

/// Reusable reference search and selection with no Scaffold or navigation.
/// Supply bounded height (for example Expanded in a page or picker sheet).
class RequestReferencePickerContent extends StatefulWidget {
  const RequestReferencePickerContent({
    super.key,
    required this.onSelected,
    required this.repository,
    required this.kind,
    this.filters = const {},
    this.isEligible,
  });
  final ValueChanged<RequestReference> onSelected;
  final RequestReferenceRepository repository;
  final RequestReferenceKind kind;
  final Map<String, Object?> filters;
  final bool Function(RequestReference)? isEligible;
  @override
  State<RequestReferencePickerContent> createState() =>
      _RequestReferencePickerContentState();
}

class _RequestReferencePickerContentState
    extends State<RequestReferencePickerContent> {
  late final RequestListController<RequestReference> _list;
  Timer? _searchDebounce;
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
    _searchDebounce?.cancel();
    _list.dispose();
    super.dispose();
  }

  void _searchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) unawaited(_list.setQuery(search: value));
    });
  }

  void _searchSubmitted(String value) {
    _searchDebounce?.cancel();
    unawaited(_list.setQuery(search: value));
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextField(
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          labelText: RequestLocalizations.of(context).search,
        ),
        onChanged: _searchChanged,
        onSubmitted: _searchSubmitted,
      ),
      Expanded(
        child: ListenableBuilder(
          listenable: _list,
          builder: (context, _) {
            final strings = RequestLocalizations.of(context);
            return ListView.builder(
              itemCount: _list.items.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    children: [
                      if (_list.loading) const LinearProgressIndicator(),
                      if (!_list.loading &&
                          _list.failure == null &&
                          _list.items.isEmpty)
                        AppEmptyView(title: strings.empty, message: ''),
                    ],
                  );
                }
                if (index <= _list.items.length) {
                  final item = _list.items[index - 1];
                  return ListTile(
                    title: Text(item.label),
                    subtitle: item.code == null ? null : Text(item.code!),
                    enabled:
                        item.eligible &&
                        (widget.isEligible?.call(item) ?? true),
                    onTap: () => widget.onSelected(item),
                  );
                }
                return Column(
                  children: [
                    if (_list.failure != null)
                      AppErrorView(
                        message: _list.failure!.localizedMessage(
                          AppLocalizations.of(context),
                        ),
                        actionLabel: strings.retry,
                        onAction: () => _list.items.isEmpty
                            ? _list.refresh()
                            : _list.nextPage(),
                      ),
                    if (_list.hasNext &&
                        !_list.loading &&
                        _list.failure == null)
                      AppButton.ghost(
                        label: strings.loadMore,
                        onPressed: _list.nextPage,
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    ],
  );
}
