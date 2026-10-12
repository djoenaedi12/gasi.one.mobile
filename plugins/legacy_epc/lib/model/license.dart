class License {
  
  String license;
  String expiryDate;
  List<String> modules;
  String companyCode;
  String hostName;

  License(
    this.license,
    this.expiryDate,
    this.modules,
    this.companyCode,
    this.hostName,
  );

  static License? fromJson(dynamic json) {
    if (json == null) return null;

    List<String> modules = [];
    for (var i = 0; i < json['modules'].length; i++) {
      if(json['modules'][i] == null || json['modules'][i] == "") continue;
      modules.add(json['modules'][i]);
    }
    return License(
      json['license'],
      json['expiry_date'],
      modules,
      json['company_code'],
      json['host_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "license": license,
      "expiry_date": expiryDate,
      "modules": modules,
      "company_code": companyCode,
      "host_name": hostName,
    };
  }  
}