class Response<T>{
  bool success = false;
  String message = "";
  T? data;

  Response();

  fromJson(dynamic json, T data) {
    if (json == null) return null;
    this.success = json['success'];
    this.message = json['message'];
    this.data = data;
  }

  setData(dynamic data) {
    this.data = data;
  }

}