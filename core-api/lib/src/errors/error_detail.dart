class ErrorDetail {
  const ErrorDetail({required this.code, required this.message, this.field});

  factory ErrorDetail.fromJson(Map<String, dynamic> json) {
    return ErrorDetail(
      code: json['code'] is String ? json['code'] as String : '',
      field: json['field'] is String ? json['field'] as String : null,
      message: json['message'] is String ? json['message'] as String : '',
    );
  }

  final String code;
  final String? field;
  final String message;

  Map<String, dynamic> toJson() => {
    'code': code,
    if (field != null) 'field': field,
    'message': message,
  };
}
