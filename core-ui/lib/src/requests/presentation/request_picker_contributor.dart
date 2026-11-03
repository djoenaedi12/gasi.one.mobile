import 'package:gasione_core_api/gasione_core_api.dart';

import '../localization/request_localizations.dart';
import 'request_file_picker.dart';
import 'request_reference_picker.dart';

/// Shared request pickers, independent of any business plugin. Features pass
/// their filters through PickerRequest.arguments and own action eligibility.
final class RequestPickerContributor implements PickerContributor {
  const RequestPickerContributor(this.references);

  final RequestReferenceRepository references;

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
}
