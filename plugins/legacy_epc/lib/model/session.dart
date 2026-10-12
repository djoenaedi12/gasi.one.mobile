class Session {

  String accessToken;
  String refreshToken;
  String tokenType;
  String scope;
  String? jti;
  String username;
  String? deviceToken;

  Session(
    this.accessToken,
    this.refreshToken,
    this.tokenType,
    this.scope,
    this.jti,
    this.username,
    this.deviceToken
  );

  static Session? fromJson(dynamic json) {
    if (json == null) return null;
    return Session(
      json['access_token'],
      json['refresh_token'],
      json['token_type'],
      json['scope'],
      json['jti'],
      json['username'],
      json['device_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "access_token": accessToken,
      "refresh_token": refreshToken,
      "token_type": tokenType,
      "scope": scope,
      "jti": jti,
      "username": username,
      "device_token": deviceToken
    };
  }
  
}