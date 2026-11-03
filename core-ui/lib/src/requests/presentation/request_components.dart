import 'package:flutter/material.dart';
import 'package:gasione_core_api/gasione_core_api.dart';

import '../../design_system/components/buttons/app_button.dart';
import '../../design_system/components/typography/app_text.dart';
import '../../design_system/foundations/app_spacing.dart';
import '../../localization/failure_localization.dart';
import '../../localization/l10n/app_localizations.dart';
import '../localization/request_localizations.dart';

Future<T?> showRequestModal<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(child: builder(context)),
  ),
);

Future<String?> showRequestRemarkDialog(
  BuildContext context, {
  required String title,
}) async {
  final strings = RequestLocalizations.of(context);
  final controller = TextEditingController();
  try {
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: strings.remark),
          maxLines: 3,
        ),
        actions: [
          AppButton.ghost(
            label: strings.cancel,
            onPressed: () => Navigator.pop(context),
          ),
          AppButton.primary(
            label: title,
            onPressed: () => Navigator.pop(context, controller.text),
          ),
        ],
      ),
    );
  } finally {
    controller.dispose();
  }
}

class RequestStatusBadge extends StatelessWidget {
  const RequestStatusBadge({super.key, required this.status});
  final WorkflowStatus status;
  @override
  Widget build(BuildContext context) => Chip(
    label: Text(RequestLocalizations.of(context).status(status.wireValue)),
  );
}

class RequestEmployeeHeader extends StatelessWidget {
  const RequestEmployeeHeader({
    super.key,
    required this.employee,
    this.trailing,
  });
  final EmployeeIdentity employee;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.person_outline),
    title: Text(employee.name),
    subtitle: employee.number == null ? null : Text(employee.number!),
    trailing: trailing,
  );
}

class RequestMetadataView extends StatelessWidget {
  const RequestMetadataView({super.key, required this.metadata});
  final RequestMetadata metadata;
  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(metadata.number),
    subtitle: metadata.createdAt == null
        ? null
        : Text(
            MaterialLocalizations.of(context)
                .formatMediumDate(metadata.createdAt!),
          ),
    trailing: RequestStatusBadge(status: metadata.status),
  );
}

class RequestApprovalProgress extends StatelessWidget {
  const RequestApprovalProgress({super.key, required this.history});
  final List<WorkflowHistoryEntry> history;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final entry in history)
        ListTile(
          leading: const Icon(Icons.check_circle_outline),
          title: Text(
            RequestLocalizations.of(context)
                .status(entry.status?.wireValue ?? 'PENDING'),
          ),
          subtitle: Text(
            [
              if (entry.executor != null) entry.executor!.name,
              if (entry.remark?.isNotEmpty == true) entry.remark!,
            ].join('\n'),
          ),
        ),
    ],
  );
}

class RequestDetailScaffold extends StatelessWidget {
  const RequestDetailScaffold({
    super.key,
    required this.title,
    required this.sections,
    this.metadata,
    this.employee,
    this.history = const [],
    this.actions = const [],
  });
  final String title;
  final RequestMetadata? metadata;
  final EmployeeIdentity? employee;
  final List<Widget> sections;
  final List<WorkflowHistoryEntry> history;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(
      children: [
        if (employee != null) RequestEmployeeHeader(employee: employee!),
        if (metadata != null) RequestMetadataView(metadata: metadata!),
        ...sections,
        if (history.isNotEmpty) RequestApprovalProgress(history: history),
      ],
    ),
    bottomNavigationBar: actions.isEmpty
        ? null
        : SafeArea(child: Wrap(children: actions)),
  );
}

class RequestFormScaffold extends StatefulWidget {
  const RequestFormScaffold({
    super.key,
    required this.title,
    required this.sections,
    required this.onSave,
    this.actions = const [WorkflowAction.draft, WorkflowAction.submit],
  });
  final String title;
  final List<Widget> sections;
  final List<WorkflowAction> actions;
  final Future<Result<void>> Function(WorkflowAction) onSave;
  @override
  State<RequestFormScaffold> createState() => _RequestFormScaffoldState();
}

class _RequestFormScaffoldState extends State<RequestFormScaffold> {
  final _form = GlobalKey<FormState>();
  bool _busy = false;
  Failure? _failure;
  Future<void> _save(WorkflowAction action) async {
    if (_busy || !_form.currentState!.validate()) return;
    _form.currentState!.save();
    setState(() {
      _busy = true;
      _failure = null;
    });
    Result<void> result;
    try {
      result = await widget.onSave(action);
    } catch (_) {
      result = const FailureResult(UnknownFailure());
    }
    if (!mounted) return;
    switch (result) {
      case Success<void>():
        Navigator.pop(context, true);
      case FailureResult<void>(:final failure):
        setState(() {
          _busy = false;
          _failure = failure is CancelledFailure ? null : failure;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = RequestLocalizations.of(context);
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (_busy) const LinearProgressIndicator(),
              if (_failure != null)
                AppText(
                  _failure!.localizedMessage(AppLocalizations.of(context)),
                  tone: AppTextTone.error,
                ),
              IgnorePointer(
                ignoring: _busy,
                child: Column(children: widget.sections),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final action in widget.actions)
                AppButton.primary(
                  onPressed: _busy ? null : () => _save(action),
                  label: strings.status(
                    action == WorkflowAction.draft ? 'DRAFTED' : 'SUBMITTED',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
