/// Integration surface for the EPC pages that have not yet been migrated.
/// TRANSITION[LEGACY-EPC]: retire this entry and the package only after every
/// page, route, and business-startup consumer has a replacement.
/// Removal map: docs/migration-cleanup.md in the workspace root.
library;

export 'src/legacy_epc_module.dart';
export 'src/legacy_business_context_bridge.dart';
export 'src/legacy_routes.dart';
export 'src/legacy_auth_transport.dart';
