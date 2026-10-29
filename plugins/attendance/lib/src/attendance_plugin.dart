import 'package:flutter/widgets.dart';
import 'package:gasione_core_api/gasione_core_api.dart';

import 'foundation/data/api_request_services.dart';
import 'foundation/data/request_api.dart';
import 'foundation/localization/request_localizations.dart';
import 'foundation/presentation/request_file_picker.dart';
import 'foundation/presentation/request_reference_picker.dart';

/// Registers infrastructure only. CRs supply complete feature routes for cutover.
final class AttendancePlugin
    implements AppPlugin, PageRouteContributor, PickerContributor {
  AttendancePlugin({
    required this.context,
    required RequestApi api,
    this.pageRoutes = const [],
  }) : references = ApiRequestReferenceRepository(api),
       attachments = ApiRequestAttachmentRepository(api),
       customFields = ApiRequestCustomFieldRepository(api),
       workflowReferences = ApiWorkflowReferenceRepository(api);
  final BusinessContextProvider context;
  final RequestReferenceRepository references;
  final AttachmentRepository attachments;
  final CustomFieldRepository customFields;
  final WorkflowReferenceRepository workflowReferences;
  @override
  List<PickerDefinitionBase> get pickers => [
    PickerDefinition(
      key: RequestPickerKeys.attachment,
      pageBuilder: (context, request) => RequestFilePicker(
        title: request.title ?? RequestLocalizations.of(context).chooseFile,
      ),
    ),
    for (final entry in {
      RequestPickerKeys.employee: RequestReferenceKind.employee,
      RequestPickerKeys.subordinate: RequestReferenceKind.subordinate,
      RequestPickerKeys.workingLocation: RequestReferenceKind.workingLocation,
      RequestPickerKeys.shift: RequestReferenceKind.shift,
    }.entries)
      PickerDefinition(
        key: entry.key,
        pageBuilder: (context, request) => RequestReferencePicker(
          title: request.title ?? RequestLocalizations.of(context).search,
          repository: references,
          kind: entry.value,
          filters: request.arguments,
        ),
      ),
  ];
  @override
  final List<PluginPageRoute> pageRoutes;
  @override
  String get code => 'attendance';
  @override
  List<PluginRoute> get routes => const [];
  @override
  List<PluginMenuItem> get menus => const [];
  @override
  List<LocalizationsDelegate<dynamic>> get localizationsDelegates => const [
    RequestLocalizations.delegate,
  ];
  @override
  List<Locale> get supportedLocales => const [Locale('en'), Locale('id')];
}
