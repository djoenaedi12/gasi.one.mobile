final class BusinessLicense {
  BusinessLicense({
    required this.value,
    required this.expiryDate,
    required List<String> modules,
    required this.companyCode,
    required this.hostName,
  }) : modules = List.unmodifiable(modules);

  final String value;
  final String expiryDate;
  final List<String> modules;
  final String companyCode;
  final String hostName;
}
