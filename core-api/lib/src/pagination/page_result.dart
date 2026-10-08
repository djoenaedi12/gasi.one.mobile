class PageResult<T> {
  PageResult({
    required List<T> content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  }) : content = List.unmodifiable(content);

  factory PageResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) itemFromJson,
  ) {
    try {
      final rawContent = json['content'];
      if (rawContent is! List) {
        throw const FormatException('Expected a content array.');
      }

      return PageResult(
        content: [
          for (final item in rawContent)
            if (item is Map)
              itemFromJson(Map<String, dynamic>.from(item))
            else
              throw const FormatException('Expected a content object.'),
        ],
        page: _integer(json, 'page'),
        size: _integer(json, 'size'),
        totalElements: _integer(json, 'totalElements'),
        totalPages: _integer(json, 'totalPages'),
      );
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Invalid page response.', error);
    }
  }

  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  bool get hasNext => page < totalPages - 1;
  bool get hasPrevious => page > 0;

  PageResult<R> map<R>(R Function(T item) transform) {
    return PageResult(
      content: content.map(transform).toList(growable: false),
      page: page,
      size: size,
      totalElements: totalElements,
      totalPages: totalPages,
    );
  }

  static int _integer(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! num) {
      throw FormatException('Expected an integer $key value.');
    }
    return value.toInt();
  }
}
