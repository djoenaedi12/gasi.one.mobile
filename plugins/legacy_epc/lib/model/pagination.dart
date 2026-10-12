class Pagination<T> {
  int totalPages = 0;
  int totalElements = 0;
  int size = 10;
  int number = 0;
  List<T> content = [];

  add(T entity) {
    content.add(entity);
  }

  fromJson(dynamic json) {
    if (json == null) return null;
    this.totalPages = json['total_pages'];
    this.totalElements = json['total_elements'];
    this.size = json['size'];
    this.number = json['number'];
  }
}